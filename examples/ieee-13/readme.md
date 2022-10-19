# IEEE 13-Bus Test Feeder

This directory has the configuration files for the Standard IEEE 13 Node Test Feeder which has the following topology:
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_std_test_feeder.png" alt="Standard IEEE 13-Bus Test Feeder Topology">

Original test case can be downloaded from https://cmte.ieee.org/pes-testfeeders/wp-content/uploads/sites/167/2017/08/feeder13.zip

The `using` command is only needed once per Julia sesion:
```julia
julia> using  SimpleDistributionPowerFlow
julia> gridtopology(input="examples/ieee-13", output="results", graph_title="IEEE 13 Node Test Feeder")
julia> powerflow(input="examples/ieee-13", output="results", save_topology=true, graph_title="IEEE 13 Node Test Feeder")
```

<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_example_input_topology.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_example_working_topology.png"</td>
  </tr>
</table>

In this example bus 60 was added to connect the regulator between bus 650 and the line connecting to bus 632. 

There is a bus_coords.csv file in input directory for this reason the relative location of the buses in topology graphs are maintained.

For working topology a bus was added automatically to model the distributed load between buses 632 and 671. This auxiliar bus will be deleted automatically after powerflow execution and before the results were printed.

More explanations on specific command arguments can be found in [ieee-4](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/tree/main/examples/ieee-4) example. 

