# IEEE 13-Bus Test Feeder

This directory has the configuration files for the Standard IEEE 13 Node Test Feeder which has the following topology:
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_std_test_feeder.png" alt="Standard IEEE 13-Bus Test Feeder Topology">

Original test case can be downloaded from https://cmte.ieee.org/pes-testfeeders/wp-content/uploads/sites/167/2017/08/feeder13.zip

The `using` command is only needed once per Julia sesion:
```julia
julia> using  SimpleDistributionPowerFlow
julia> gridtopology(input="examples/ieee-13", output="results", graph_title="IEEE 13 Node Test Feeder")
julia> powerflow(input="examples/ieee-13", output="results", graph_title="IEEE 13 Node Test Feeder")
```

<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_example_input_topology.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_example_working_topology.png"</td>
  </tr>
</table>

In this example there is a bus_coords.csv file for this reason the relative location of the buses in the graph are maintained.

In the working topology a bus was added to model the distributed load between buses 632 and 671. This auxiliar bus will be deleted after powerflow execution and before the results were printed.

More explanations on specific command arguments can be found in [ieee-4](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/tree/main/examples/ieee-4) example. 

## For Distributed Generation
To execute powerflow with DG you only need to change the name of the first file to distributed_generation.csv (eliminating the first underscore sign in the example file).

The example has different DG at buses 634 (PQ), 671 (PQV) and 675 (PI), connected in wye or delta. The following table shows the required values for the specific DG mode. Value of xd is in ohm.

bus | conn | mode | kw_set | kvar_set | kv_set | amp_set | kvar_min | kvar_max | xd
--- | ---  | ---  | ---    | ---      | ---    | ---     | ---      | ---      | ---
634 | Y  | PQ  | 210    | 90      | ---    | ---     | ---      | ---      | ---
671 | Y  | PQV  | 900    | ---      | 4.992   | ---     | -1000      | 1000      | 7.68
675 | D  | PI  | 150   | ---      | ---    | 22     | 0     | 180     | ---


