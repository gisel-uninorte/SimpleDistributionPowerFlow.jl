# IEEE 4-Bus Test Feeder Cases

This directory has the configuration files for the Standard IEEE 4 Node Test Feeder Cases which have the following topology:
<img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_4_bus_std_test_feeder.png" alt="Standard IEEE 4-Bus Test Feeder Topology">

Original test case can be downloaded from https://cmte.ieee.org/pes-testfeeders/wp-content/uploads/sites/167/2017/08/feeder4.zip

The following explanation suppose that SimpleDistributionPowerFlow.jl package is already installed and you had executed the following command:
```julia
julia> using  SimpleDistributionPowerFlow
```

If configuration files are in your current directory, you only need to execute `gridtopology()` for topology discovery or `powerflow()` for the powerflow evaluation.

If you want to maintain the input and output files in different locations, you can specify it by means of absolute or relative paths, such as:
```julia
julia> gridtopology(input="examples/ieee-4", output="results")
julia> powerflow(input="examples/ieee-4", output="results")
```

If you are using Windows you must add an escape character in the path string:
```julia
julia> gridtopology(input="examples\\ieee-4", output="results")
julia> powerflow(input="examples\\ieee-4", output="results")
```

You can aggregate a title to the topology graph, per example:
```julia
julia> gridtopology(input="examples/ieee-4", output="results", graph_title="IEEE 4 Node Test Feeder")
julia> powerflow(input="examples/ieee-4", output="results", graph_title="IEEE 4 Node Test Feeder")
```

By default, SimpleDistributionPowerFlow does not display the topology on the screen, although the graphics are saved in png files. If you want to get the image on the screen after the execution of the command, you have to specify it:
```julia
julia> gridtopology(input="examples/ieee-4", output="results", graph_title="IEEE 4 Node Test Feeder", display_topology=true)
julia> powerflow(input="examples/ieee-4", output="results", graph_title="IEEE 4 Node Test Feeder", display_topology=true)
```

SimpleDistributionPowerFlow.jl always generates two topologies: one based on input data (_input topology_) and another after checking the input topology (_working topology_).
In this example *there is no bus_coords.csv file* for this reason the relative location of the buses in the graph are different while the topology is the same.

<table>
  <tr>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_4_bus_example_input_topology.png"</td>
    <td><img src="https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/images/ieee_4_bus_example_working_topology.png"</td>
  </tr>
</table>

The text between buses 2 and 3 in above gaphics depends on codename of the transformer in _line_segments.csv_ and _transformers.csv_ configuration files. In this case the transformer with connection grY-grY was used.

By default output files are overwritten, if you want to maintain output files for different executions you can add a timestamp to files with following command:
```julia
julia> powerflow(input="examples/ieee-4", output="results", timestamp=true)
```
