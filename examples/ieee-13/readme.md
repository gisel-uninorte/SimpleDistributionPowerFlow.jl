# IEEE 13-Bus Test Feeder Cases

This directory has the configuration files for the Standard IEEE 13 Node Test Feeder Cases which have the following topology:
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_std_test_feeder.png" alt="Standard IEEE 13-Bus Test Feeder Topology">

Original test case can be downloaded from https://cmte.ieee.org/pes-testfeeders/wp-content/uploads/sites/167/2017/08/feeder13.zip

The following explanation suppose that SimpleDistributionPowerFlow.jl package is already installed and you had executed the following command:
```julia
julia> using  SimpleDistributionPowerFlow
```

If configuration files are in your current directory, you only need to execute `gridtopology()` for topology discovery or `powerflow()` for the powerflow evaluation.

If you want to maintain the input and output files in different locations, you can specify it by means of absolute or relative paths, such as:
```julia
julia> gridtopology(input="examples/ieee-13", output="results")
julia> powerflow(input="examples/ieee-13", output="results")
```

If you are using Windows you must add an escape character in the path string:
```julia
julia> gridtopology(input="examples\\ieee-13", output="results")
julia> powerflow(input="examples\\ieee-13", output="results")
```

You can aggregate a title to the topology graph, per example:
```julia
julia> gridtopology(input="examples/ieee-13", output="results", graph_title="IEEE 13 Node Test Feeder")
julia> powerflow(input="examples/ieee-13", output="results", graph_title="IEEE 13 Node Test Feeder")
```

By default, SimpleDistributionPowerFlow does not display the topology on the screen, although the graphics are saved in png files. If you want to get the image on the screen after the execution of the command, you have to specify it:
```julia
julia> gridtopology(input="examples/ieee-13", output="results", graph_title="IEEE 13 Node Test Feeder", display_topology=true)
julia> powerflow(input="examples/ieee-13", output="results", graph_title="IEEE 13 Node Test Feeder", display_topology=true)
```

SimpleDistributionPowerFlow.jl always generates two topologies: one based on input data (_input topology_) and another after checking the input topology (_working topology_).
In this example **there is a bus_coords.csv file** for this reason the relative location of the buses in the graph are the same.

<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_example_input_topology.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_13_bus_example_working_topology.png"</td>
  </tr>
</table>

In the working topology a bus was added for distributed load between buses 632 and 671. This auxiliar bus will be deleted after powerflow execution and before the results were printed.

By default output files are overwritten, if you want to maintain output files for different executions you can add a timestamp to files with following command:
```julia
julia> powerflow(input="examples/ieee-13", output="results", timestamp=true)
```
