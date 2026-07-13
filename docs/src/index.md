# Acqua Calda

A thermally coupled Discrete Element Method library for granular materials.

## Overview

Acqua Calda simulates heat transfer in granular materials using the Discrete
Element Method (DEM). It models mechanical contacts, particle-particle and
particle-wall heat conduction, frictional heating, and energy conservation.

The library is made for operation with interfaces for custom contact
models, thermal solvers, and I/O backends.

## Status

Acqua Calda is in early development. APIs are unstable and features are
incomplete. See the [Changelog](https://github.com/Sardiniangale/AquaCalda.jl/blob/main/CHANGELOG.md)
for version history.

## Features

- Hertz-Mindlin and linear spring-dashpot contact models
- Particle-particle and particle-wall heat conduction
- Frictional heating with energy conservation
- Extensible contact model and thermal solver interfaces
- GPU acceleration via [CUDA.jl](https://github.com/JuliaGPU/CUDA.jl) (this is one of the final additions, so don't expect it soon)
- Modular RNG options

## Installation

```julia
import Pkg
Pkg.add("AcquaCalda")
```

## Quick start

```julia
using AcquaCalda

# coming soon
```

## License

Acqua Calda is released under the [MIT License](https://github.com/Sardiniangale/AquaCalda.jl/blob/main/LICENSE).
