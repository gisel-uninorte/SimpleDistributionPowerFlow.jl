# IEEE 123-Bus Test Feeder

This directory has the configuration files for the Standard IEEE 34 Node Test Feeder which has the following topology:
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_123_bus_std_test_feeder.png" alt="Standard IEEE 123-Bus Test Feeder Topology">

Original test case can be downloaded from https://cmte.ieee.org/pes-testfeeders/wp-content/uploads/sites/167/2017/08/feeder123.zip 

The `using` command is only needed once per Julia sesion:
```julia
julia> using  SimpleDistributionPowerFlow
julia> gridtopology(input="examples/ieee-123", output="results", graph_title="IEEE 123 Node Test Feeder", marker_size=10)
julia> powerflow(input="examples/ieee-123", output="results", graph_title="IEEE 123 Node Test Feeder", marker_size=10)
```

<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_123_bus_example_input_topology.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_123_bus_example_working_topology.png"</td>
  </tr>
</table>

In this some buses were added in configuration files to connect the voltage regulators. 

In the working topology several buses were automatically added to model the distributed loads., and buses 195, 251, 350 and 451 were automatically pruned because the associated switches are in open state.

More explanations on specific command arguments can be found in [ieee-4](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/tree/main/examples/ieee-4) example. 

## For Distributed Generation
To include DGs you can follow the explanation given in [ieee-13](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/tree/main/examples/ieee-13) example.


