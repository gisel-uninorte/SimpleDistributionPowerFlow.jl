# IEEE 34-Bus Test Feeder

This directory has the configuration files for the Standard IEEE 34 Node Test Feeder which has the following topology:
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_34_bus_std_test_feeder.png" alt="Standard IEEE 34-Bus Test Feeder Topology">

Original test case can be downloaded from https://cmte.ieee.org/pes-testfeeders/wp-content/uploads/sites/167/2017/08/feeder34.zip

The `using` command is only needed once per Julia sesion:
```julia
julia> using  SimpleDistributionPowerFlow
julia> gridtopology(input="examples/ieee-34", output="results", graph_title="IEEE 34 Node Test Feeder")
julia> powerflow(input="examples/ieee-34", output="results", graph_title="IEEE 34 Node Test Feeder")
```

<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_34_bus_example_input_topology.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_34_bus_example_working_topology.png"</td>
  </tr>
</table>

In this example a bus and a regulator were added in configuration files to model the voltage rise in bus 800. 

In the working topology several buses were automatically added to model the distributed loads.

More explanations on specific command arguments can be found in [ieee-4](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/tree/main/examples/ieee-4) example. 

## For Distributed Generation
To execute powerflow with DG you can follow the explanation given in [ieee-13](https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/tree/main/examples/ieee-13) example.


