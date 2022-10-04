# SimpleDistributionPowerFlow.jl
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/SimpleDistributionPowerFlow_logo.png" align="left" width="200" alt="SimpleDistributionPowerFlow.jl logo">

SimpleDistributionPowerFlow.jl is a Julia language package for steady-state radial distribution systems powerflow analysis focused on usage simplicity with reliable and fast results.

The data entry is made with standard definition csv files, does not require learning specific configuration commands, and for the execution provides two methods, one for discover the grid topology and other for the powerflow analysis itself.

It identifies some input situations such as distributed loads, isolated segments, open/closed switches and works automatically according such situations, adding auxiliar buses, purging segments and/or reordering buses.

Grid topology is identified based on input line segments, transformers and switches information and the graph is plotting even without bus_coords file or with missing bus location information.

It implements standard forward-backward sweeps procedure with the generalized matrices proposed by W.H. Kersting in Distribution System Modeling and Analysis.


## Installation
```julia
julia> using Pkg
julia> Pkg.add(CSV, DataFrames, Plots, GraphRecipes)
julia> Pkg.add(url="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl")
```
