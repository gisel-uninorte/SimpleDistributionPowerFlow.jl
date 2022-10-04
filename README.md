# SimpleDistributionPowerFlow.jl
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/SimpleDistributionPowerFlow_logo.png" align="left" width="250" alt="SimpleDistributionPowerFlow.jl logo">

SimpleDistributionPowerFlow.jl is a Julia language package for steady-state unbalanced radial distribution systems powerflow analysis focused on usage simplicity with reliable and fast results.

The data entry is made with standard definition csv files. It identifies some input situations such as distributed loads, isolated segments, open/closed switches and works automatically according to such situations, per example adding auxiliar buses, purging segments and/or reordering buses. It accept some types of distributed generation also.

Grid topology is identified based on input line segments, transformers and switches information and the graph is plotting even without bus_coords file or with missing bus location information.

Two commands are provided: `gridtopology()` to only topology verification, and `powerflow()` to evaluate voltages, currents, power and losses in circuit.


## Installation
```julia
julia> using Pkg
julia> Pkg.add(CSV, DataFrames, Plots, GraphRecipes)
julia> Pkg.add(url="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl")
```
