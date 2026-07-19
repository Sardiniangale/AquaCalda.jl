# AquaCalda.jl (Hot Water)

Thermomechanical Discrete Element Method(DEM), in Julia


---

## Pre‑release Notice

AcquaCalda is in the early scaffolding stage.
APIs are unstable, core features are missing. THIS IS NOWHERE NEAR READY FOR USE so do not use please. This README will be updated as the package matures toward a first stable release.

---

## What will AcquaCalda become?

A thermally coupled Discrete Element Method library for granular materials.
Current plan to implement by release (in a couple of years)

- Mechanical contacts (Hertz‑Mindlin, linear spring‑dashpot and the sort)
- Particle‑particle and particle‑wall heat conduction
- Frictional heating and energy conservation
- Interface for custom contact models, thermal solvers, and I/O

The goal is a well‑tested, validated tool which is highly modular system that's relatively easy to modify for specific use cases.

---

## Installation (just a placeholder for now)

```julia
import Pkg
Pkg.add("AcquaCalda")
