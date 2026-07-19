# Intro

This is primarily the area where I will document work and all the core functioning of the src before its cleaned up in proper documentation. It helps me personally to have a central place for info. Once the project reaches a beta state, I will distribute all this data to the correct chapter inside the documentation.

---

# Info refrence


## Domain Objects

### Material

Defines properties shared by particles.

- density: Float64, kg/m^3
- youngs_modulus: Float64, Pa
- poisson_ratio: Float64
- friction_coefficient: Float64
- specific_heat: Float64, J/(kg K)
- conductivity: Float64, W/(m K)

---

### Particle (mutable)

Represents one spherical particle. Force and torque accumulators are mutable `StaticArrays.MVector` for in-place updates. Kinematic vectors remain immutable `SVector` for stack allocation.

- id: Int, unique identifier
- material: Material, reference to shared material
- radius: Float64, particle radius
- mass: Float64, particle mass, derived from material.density and radius
- moment_of_inertia: Float64, (2/5) m r^2 for a solid sphere
- position: SVector{3,Float64}, center of mass
- velocity: SVector{3,Float64}, translational velocity
- angular_velocity: SVector{3,Float64}, rotational velocity
- force: MVector{3,Float64}, accumulated force this timestep, mutable
- torque: MVector{3,Float64}, accumulated torque this timestep, mutable
- temperature: Float64, current temperature, K, mutable
- heat_capacity: Float64, mass * material.specific_heat, J/K

---

### AbstractBoundary

Abstract supertype for domain boundaries. All boundaries must implement:

`distance_and_normal(b::AbstractBoundary, point::SVector{3,Float64})` -> `(Float64, SVector{3,Float64})`

Returns signed distance (negative means point is outside the domain) and outward unit normal.

Wall (concrete subtype of AbstractBoundary)

#### Infinite plane.

- normal: SVector{3,Float64}, outward unit normal (points away from the domain)
- point: SVector{3,Float64}, any point on the plane

---

### Contact (ephemeral)

A overlap between two bodies. Created inside the timestep, used by the force computation, discarded. No sentinel values; uses typed IDs.

- body1: ParticleID, first particle identifier
- body2: Union{ParticleID, WallID}, second body (particle or wall)
- overlap: Float64, penetration depth, positive = overlapping
- normal: SVector{3,Float64}, contact normal (points from body2 to body1)
- contact_point: SVector{3,Float64}, point of contact in world coordinates
- branch1: SVector{3,Float64}, vector from particle1 center to contact point
- branch2: SVector{3,Float64}, vector from body2 (if particle) center to contact point, zero if wall

ParticleID and WallID are simple structs holding an Int.

#### PersistentContactHistory

Stores data that must persist across time steps for each contact pair. Keyed by a tuple (ParticleID.id, body_id) where body_id is either a particle id or a wall index.

- tangential_displacement: MVector{3,Float64}, accumulated tangential slip, mutable

The System maintains a dictionary `contact_history::Dict{Tuple{Int,Int}, PersistentContactHistory}` .

---

### System (parametric on all model types)

Top-level container. Type parameters guarantee monomorphized dispatch, removing dynamic dispatch in the inner loops.

- particles: Vector{Particle}
- boundaries: Vector{AbstractBoundary} (replaces walls, supports multiple geometry types)
- contacts: Vector{Contact}, per-timestep contact list, reset each step
- contact_history: Dict{Tuple{Int,Int}, PersistentContactHistory}, persistent friction state
- contact_model: C <: AbstractContactModel
- thermal_model: Th <: AbstractThermalModel
- integrator: I <: AbstractIntegrator
- neighbor_search: N <: AbstractNeighborSearch
- thermal_integrator: TI <: AbstractThermalIntegrator 
- body_force: either a function or an AbstractBodyForce (new, replaces scalar gravity)
- energy: Union{Nothing, EnergyTracker}, optional energy tracking 
- dt: Float64, time step size
- time: Float64, current simulation time

Constructor infers type parameters from the supplied model instances.

---

## Abstract Interfaces


### AbstractContactModel

Must implement normal and tangential force laws for particle-particle and particle-boundary contacts.

- normal_force(model, p1::Particle, p2::Particle, overlap, overlap_dot) -> Float64
- tangential_force(model, p1::Particle, p2::Particle, contact, history::PersistentContactHistory) -> SVector{3,Float64}
- normal_force(model, p::Particle, boundary::AbstractBoundary, overlap, overlap_dot) -> Float64
- tangential_force(model, p::Particle, boundary::AbstractBoundary, contact, history::PersistentContactHistory) -> SVector{3,Float64}

Built-in implementations: LinearSpringDashpot, HertzMindlin. The Hertz-Mindlin model uses particle material properties (Young's modulus, Poisson ratio) and handles mixed materials via effective modulus.

---

### AbstractIntegrator

Must implement:

- step!(system, integrator, dt)

Updates positions, velocities, and angular velocities of all particles in-place. Built-in: VelocityVerlet.

---

### AbstractNeighborSearch

Must implement:

- update!(system, neighbor_search)

This rebuilds the neighbor list, runs narrow-phase detection, populates system.contacts, and updates system.contact_history (creates new history entries for new contacts, prunes stale ones). Built-in implementations: BruteForce (O(N^2) for testing and stupidity), CellList (O(N) for monodisperse, O(N log N) for polydisperse, production-ready).

---

### AbstractThermalModel

Must implement:

- heat_flux(model, p1::Particle, p2::Particle, contact) -> Float64
- heat_flux(model, p::Particle, boundary::AbstractBoundary, contact) -> Float64

Returns the heat flow rate (W) across the contact. Built-in: FourierContact (conductance based on contact area and harmonic mean of conductivities).

---

### AbstractThermalIntegrator 

Handles the thermal time integration, potentially with sub-stepping for stability. Must implement:

- integrate_heat!(system, integrator, dt)

Updates particle temperatures based on the thermal fluxes computed during the mechanical step. Built-in: ForwardEulerThermal (simple explicit step, dt can be sub-cycled automatically), ImplicitMidpointThermal.

---

### AbstractBodyForce

If not using a simple function for body forces, the interface is:

- apply_body_force!(system, body_force::AbstractBodyForce)

Built-in: Gravity, storing a 3D gravitational acceleration vector.

---

## Computational Flow (run! loop)

tex
```
run!(sys, t_end)
    while sys.time < t_end:
        1. reset_forces!(sys)
           Zero force and torque MVector accumulators for all particles.
        2. update!(sys.neighbor_search)
           Broad phase -> narrow phase -> populate sys.contacts.
           Also updates sys.contact_history: for each contact pair, retrieve or create
           a PersistentContactHistory and copy in tangential displacement if needed.
        3. compute_mechanical_forces!(sys)
           Iterate over sys.contacts. For each contact:
             - Extract particle(s) and boundary if applicable.
             - Compute normal_force and tangential_force using sys.contact_model.
             - The tangential force routine reads/writes the corresponding
               PersistentContactHistory entry.
             - Accumulate forces and torques on the involved particle(s) via mutable MVectors.
        4. apply_body_forces!(sys)
           For each particle p, add sys.body_force(p) to p.force. For simple gravity,
           this adds mass * [0,0,-9.81].
        5. step!(sys, sys.integrator)
           Update positions, velocities, angular velocities based on accumulated forces.
        6. integrate_heat!(sys, sys.thermal_integrator)
           Compute heat fluxes using sys.thermal_model for all contacts (reusing sys.contacts).
           Then update temperatures via the thermal integrator (may sub-step to ensure stability).
        7. (optional) update_energy!(sys.energy)
           If EnergyTracker is present, compute kinetic, potential, elastic, thermal energy
           and log totals.
        8. sys.time += sys.dt
    return sys
```

All subroutines dispatch on the concrete types stored in sys fields, ensuring zero dynamic dispatch.

---

## Public API

```
Construction:
  material = Material(density=2500, youngs_modulus=1e7, poisson_ratio=0.25,
                      friction_coefficient=0.5, specific_heat=800, conductivity=2.0)
  p = Particle(id=1, material=material, radius=0.01,
               position=[0,0,0], velocity=[0,0,0], temperature=300)
  floor = Wall(normal=[0,0,1], point=[0,0,0])
  sys = System(particles=[p], boundaries=[floor],
               contact_model=HertzMindlin(),
               thermal_model=FourierContact(),
               integrator=VelocityVerlet(),
               neighbor_search=CellList(bounds),
               thermal_integrator=ForwardEulerThermal(),
               body_force=Gravity([0,0,-9.81]),
               dt=1e-6)
  run!(sys, 1.0; callback = every(100) do s
      println("t = ", s.time, " T = ", s.particles[1].temperature)
  end)

Accessing state:
  sys.particles[i].position, sys.particles[i].temperature, etc.
  sys.contacts gives the current time step's contacts (read-only).

Extension (user writes):
  struct MyCohesiveModel <: AcquaCalda.AbstractContactModel
      cohesion::Float64
  end
  function AcquaCalda.normal_force(m::MyCohesiveModel, p1, p2, overlap, overlap_dot)
      # cohesive force law
  end
  sys = System(...; contact_model=MyCohesiveModel(1e6))
```
---

## Correctness Requirements

- Energy conserved for elastic collision: two-particle head-on collision, KE before equals KE after.
- Momentum conserved: two-particle off-center collision.
- Particle-wall collision time: drop particle on wall, contact duration matches sqrt(2h/g).
- Tangential displacement accumulation: sliding test verifies persistent history.
- Thermal equilibration: two particles at different temperatures converge to weighted average.
- Frictional heat equals mechanical work: sliding along wall, mechanical energy loss equals thermal energy gain.
- Multi-material contacts: test with different materials.
- Extension interface: custom AbstractContactModel is dispatched correctly.
- No allocations in run! loop: @allocations = 0 for a 100-particle system over 1000 steps.
- Thermal sub-stepping stability: large thermal conductivity does not cause instability.

---

## Performance Targets

- 10^4 particles on 1 CPU core: real-time factor less than 1 (1 s simulated in under 1 s wall clock).
- 10^5 particles on 1 CPU core: real-time factor less than 10.
- No dynamic dispatch in inner loops: @code_warntype shows all concrete types, enabled by parametric System.
- Contact detection: O(N) via cell list for monodisperse, O(N log N) for polydisperse (polydisperse-aware implementation from start).
- StructArrays optional for particle storage (future) to improve cache performance.

---

## Planned src layout
```
src/
  AcquaCalda.jl         [Module file & exports]
  types/
    Material.jl
    Particle.jl
    Boundary.jl             [AbstractBoundary, Wall, distance_and_normal]
    Contact.jl                 [Contact, ParticleID, WallID, PersistentContactHistory]
    System.jl                 [Parametric System struct]
  contact/
    AbstractContactModel.jl    [Abstract type and method signatures]
    LinearSpringDashpot.jl
    HertzMindlin.jl
  integrator/
    AbstractIntegrator.jl
    VelocityVerlet.jl
  neighbor/
    AbstractNeighborSearch.jl
    BruteForce.jl
    CellList.jl                [Polydisperse-aware]
  thermal/
    AbstractThermalModel.jl
    FourierContact.jl
    AbstractThermalIntegrator.jl
    ForwardEulerThermal.jl
  forces/
    body_force.jl           [Gravity, generic function]
  energy/
    EnergyTracker.jl
  run.jl                  [run!, reset_forces!, compute_mechanical_forces!, and others as mentioned above]
  callbacks.jl             [ every, callback infrastructure]
```
# Basic writing standards to follow

These are primarily just for me to follow since I often forget and I lose all the benifits of using julia

### Type stability

Rule: Run `@code_warntype` on every function you export. If anything is type-unstable, fix it before committing.
(I will add examples soonish)

### Concrete fields

Rule: Every struct field must be concrete. If it can't, make it a type parameter instead. The exception is `Vector{Particle}`. Vector is concrete and 'Particle' is as well.

### No allocate in inner loops

Rule: Use SA[...] and @SVector from StaticArrays for constants. Use MVector inside functions if you need mutation. You must never call SVector(...) or zeros(3) inside a loop over particles.

### Dot-broadcasting & fuse

Dot-broadcasting is really fast but its important to know when to use fuse as well.

Rule: Chain operations with dots when they are element-wise. The compiler fuses them into a single pass. But for small vectors like 3 elements, just write the loop.

### Mutable structs, only for state

Rule: Particle is mutable (state evolves). Contact, Wall, System config are immutable. If you can reconstruct it cheaper than mutating it, make it immutable.

### Float64 is the goat

Rule: Start with Float64. Add the type parameter {T} only when you have a working Float64 codebase and a concrete need for Float32. Parametric types complicate the dispatch matrix for zero benefit (I could be wrong in specific case like gpu but for now I will stick with this).

### No global mutable state 

Rule: All module-level const values must be immutable (numbers, strings, tuples, SA[...]). Never use a mutable container as a global constant. The compiler assumes const values don't change, if they do, you get wrong results.

### Functions

Rule: The body of src/ contains zero bare code. Everything is inside a function. The module top-level only has include, using, export, and const definitions. Functions are the unit of compilation in Julia, bare statements are lost optimization.

### Benchmark

Rule: Never optimize something you haven't profiled. Julia's @profview and @btime are your first tools. Optimizing without a profile is the same as gambling.



