# Intro

This is primarily the area where I will document work and all the core functioning of the src before its cleaned up in proper documentation. It helps me personally to have a central place for info. Once the project reaches a beta state, I will distribute all this data to the correct chapter inside the documentation.

---

# Info refrence


## Domain objects

### Particle


Represents one spherical particle. All vector quantities are 3D, immutable, stack-allocated via StaticArrays.SVector{3}.

- position: SVector{3,Float64}, center of mass
- velocity: SVector{3,Float64}, translational velocity
- angular_velocity: SVector{3,Float64}, rotational velocity
- force: SVector{3,Float64}, accumulated force this timestep
- torque: SVector{3,Float64}, accumulated torque this timestep
- radius: Float64, particle radius
- mass: Float64, particle mass
- moment_of_inertia: Float64, 2/5 m r² for a solid sphere
- temperature: Float64, current temperature K
- heat_capacity: Float64, specific heat × mass J/K
- conductivity: Float64, thermal conductivity W/(m·K)
- id: Int, unique identifier

### Wall

An infinite plane.

- normal: SVector{3,Float64}, outward unit normal (points away from the domain)
- point: SVector{3,Float64}, any point on the plane

### Contact

A detected overlap between two bodies. Created inside the timestep, consumed by the force computation, discarded.

- i: Int, first particle index
- j: Int, second particle index (or -1 for wall)
- overlap: Float64, positive = overlapping
- normal: SVector{3,Float64}, contact normal (points from j to i)
- contact_point: SVector{3,Float64}, point of contact in world coordinates
- branch_i: SVector{3,Float64}, vector from particle i center to contact point
- tangential_displacement: SVector{3,Float64}, accumulated tangential slip (mutable, tracked across timesteps)

### System

Top-level container. Owns all data.

- particles: Vector{Particle}
- walls: Vector{Wall}
- contacts: Vector{Contact}, per-timestep contact list
- contact_model: AbstractContactModel
- thermal_model: AbstractThermalModel
- integrator: AbstractIntegrator, time integrator
- neighbor_search: AbstractNeighborSearch
- gravity: Float64, gravitational acceleration (positive downward along z)
- dt: Float64, time step size
- time: Float64, current simulation time



## Abstract interfaces




## Computational flow



## Performance targets


---

# Basic writing standards to follow

These are primarily just for me to follow since I often forget and I lose all the benifits of using julia

### Type stability

Rule: Run '@code_warntype' on every function you export. If anything is type-unstable, fix it before committing.
(I will add examples soonish)

### Concrete fields

Rule: Every struct field must be concrete. If it can't, make it a type parameter instead. The exception is 'Vector{Particle}'. 'Vector' is concrete and 'Particle' is as well.

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



