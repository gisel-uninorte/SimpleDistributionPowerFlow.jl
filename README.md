# SimpleDistributionPowerFlow.jl
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/SimpleDistributionPowerFlow_logo.png" align="left" width="250" alt="SimpleDistributionPowerFlow.jl logo">

SimpleDistributionPowerFlow.jl is a Julia language package for steady-state unbalanced radial distribution systems powerflow analysis focused on usage simplicity with reliable and fast results.

The simplicity of the package is based on the data entry and package usage:

The data entry is made with standard definition csv files. It identifies some input situations such as distributed loads, isolated segments, open/closed switches and works automatically according to such situations, per example adding auxiliar buses, purging segments and/or reordering buses. It accept some types of distributed generation also.

Two commands are provided: `gridtopology()` for topology verification only, and `powerflow()` for voltages, currents, power and losses evaluation.

Grid topology is discovered based on input line segments, transformers and the switches states information, and the graph is plotting even without bus_coords file or with missing bus location information. Power flow evaluation takes in account the discovered topology, spot and distributed loads and distributed generation if any.

Results are saved in current directory by default or in the directory specified by _output_ argument.

## Installation
```julia
julia> using Pkg
julia> Pkg.add("SimpleDistributionPowerFlow")
```

## Configuration files

filename | type | column names | comments
--- | --- | --- | ---
line_segments.csv          | required | bus1,bus2,length,unit,config | bus1 and bus 2: Int, unit: String <br />(ft, mi, m, km only accepted)
line_configurations.csv    | required | config,unit,<br />raa,xaa,rab,xab,rac,xac,<br />rbb,xbb,rbc,xbc,<br />rcc,xcc,<br />baa,bab,bac,bbb,bbc,bcc | unit: String <br />represents ohm/unit or micro-siemens/unit <br />(ft, mi, m, km only accepted)
substation.csv             | required | bus,kva,kv | kv: line-to-line voltage in kilovolts
spot_loads.csv             | required | bus,conn,type,<br />kw_ph1,kvar_ph1,<br />kw_ph2,kvar_ph2,<br />kw_ph3,kvar_ph3 | conn: Y/D, type: PQ/Z/I, <br />ph1/2/3 represents A/B/C for Y connection, <br />and A-B/B-C/C-A for D connection
distributed_loads.csv      | optional | bus1,bus2,conn,type,<br />kw_ph1,kvar_ph1,<br />kw_ph2,kvar_ph2,<br />kw_ph3,kvar_ph3 | 
capacitors.csv             | optional | bus,kvar_ph1,kvar_ph2,kvar_ph3 |
transformers.csv           | optional | config,kva,phases,<br />conn_high,conn_low,<br />kv_high,kv_low,<br />rpu,xpu | currently only grY-grY, Y-D, D-grY and D-D three-phase step-down transformer configurations are accepted
switches.csv               | optional | config,phases,state,resistance | phases: abc, resistance in ohms
bus_coords.csv             | optional | bus,x_pos,y_pos |
regulators.csv             | optional | config,phases,mode,tap_1,tap_2,tap_3 | mode: manual only
distributed_generation.csv | optional | bus,conn,mode,kw_set,<br />kvar_set,kv_set,amp_set,<br />kvar_min,kvar_max,xd | bus, conn, mode and kw_set are mandatories, others params depends on distributed generation mode


## Usage
***To load the package***: `using SimpleDistributionPowerFlow`

***For grid's topology discovery only***: `gridtopology()`

options | purpose | default | examples
--- | --- | :-: | --- 
input = "String"  | input files location  | "" <br />(pwd) | _gridtopology(input = "examples/ieee-34")_
output = "String" | results files location |"" <br />(pwd) | _gridtopology(output = "results")_
display_topology = bool | display in screen the identified grid topology| false | _gridtopology(display_topology = true)_
timestamp = bool | add a timestamp to results file names  | false | _gridtopology(timestamp = true)_
graph_title = "String" | set a title in topology graph | "" (nothing)| _gridtopology(graph_title = "modified ieee-34 test feeder")_
marker_size = Float    | set the size of bus identifier in graph | 1.5 | _gridtopology(marker_size = 10)_

***For powerflow analysis***: `powerflow()`

options | purpose | default | examples
--- | --- | :---: | --- 
input = "String"   | input files location  | "" <br />(pwd) | _powerflow(input = "examples/ieee-34")_
output = "String"  | results files location |"" <br />(pwd) | _powerflow(output = "results")_
tolerance = Float  | maximum porcentual difference between calculated and nominal substation bus voltage  | 1e-6 | _powerflow(tolerance = 0.001)_
max_iteration = Int | maximum number of iteration before procedure halt | 30 | _powerflow(max_iteration = 100)_
display_results = bool | display in terminal bus voltage results | true | _powerflow(display_results = false)_
display_topology = bool | display in screen the identified grid topology | false | _powerflow(display_topology = true)_
timestamp = bol | add a timestamp to results file names | false | _powerflow(timestamp = true)_
graph_title = "String" | set a title in topology graph | "" (nothing)| _powerflow(graph_title = "modified ieee-34 test feeder")_
marker_size = Float    | set the size of bus identifier in graph | 1.5 | _powerflow(marker_size = 10)_


## Examples
Full configuration files for selected IEEE node test feeders are in [examples](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/examples/) section. 

***Special features***:
This package graphs the grid topology even if there is no `bus_coords.csv` file, it also calculates the graph in case of missing or duplicate bus information: 
<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_4_without_bus_coords_example.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/modified_ieee_13_without_bus_coords.png"</td>
  </tr>
</table>


If `line_segments.csv` file has isolated segments by open switch or by error, they are pruned before powerflow analysis. Two graph are generated: _input topology_ is the detected topology from input files, and _working topology_ is the corrected one): 
<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/modified_ieee_13_ex_1_input.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/modified_ieee_13_ex_1_working.png"</td>
  </tr>
</table>


If grid's topology is changed by opening and closing switches, the from-to buses relation in affected segments are adjusted before powerflow analysis. If a loop is detected, the procedure is halted (for now the package only works with radial topology).
<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/modified_ieee_13_ex_2.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/modified_ieee_13_ex_3.png"</td>
  </tr>
</table>


If there are distributed loads, auxiliar buses are added in the middle of segments (50% of lenght) with 100% of the load applied as spot load on them. These buses are retired and segments are restored after powerflow execution and before results are printed.
<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/modified_ieee_34_ex_1_input.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/modified_ieee_34_ex_1_working.png"</td>
  </tr>
</table>


## Minimun Dependency
Simplicity of [SimpleDistributionPowerFlow.jl](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl) is based also in its low dependency of other packages. 
It only relies in [DataFrames](https://github.com/JuliaData/DataFrames.jl), [Plots](https://github.com/JuliaPlots/Plots.jl), [GraphRecipes](https://github.com/JuliaPlots/GraphRecipes.jl) and [CSV](https://github.com/JuliaData/CSV.jl)


## Future Updates
- [ ] Regulators: different configurations and automatic tap operation (for now only works with 3-phase wye connection in manual mode).
- [ ] DERs: add more Distributed Generation modes, for now only works with PQ, PI and PQV (synchronous) DG.
- [ ] Transformers: add single-phase and open-delta transformers (for now only three-phase transformers are accepted)
- [ ] Isolated segments: for now isolated segments are pruned before powerflow analysis, in future releases they would be treated as islands

## Support
Contributions, issues, and feature requests are welcome! 

## License
See [license](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/LICENSE)
