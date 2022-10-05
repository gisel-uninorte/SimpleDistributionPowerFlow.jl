# This file is part of SimpleDistributionPowerFlow.jl package
# It is MIT licensed
# Copyright (c) 2022 Gustavo Espitia, Cesar Orozco, Maria Calle, Universidad del Norte
# Terms of license are in https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/LICENSE

"""
    gridtopology(;kwargs...)

A `function` that discover the network topology by analizing the input data. 

It presents two topology graphs: one based on raw input data (input topology), and other (working topology) 
based on specific characteristics such as distributed loads and open or closed switches. The working topology
is the topology used by `powerflow()` function.
    
Data is input via `.cvs` files with minimum specification, there is not need to indicate midpoints for distributed loads, 
`gridtopology()` automatically creates dummy buses in the middle of line segments to simulate distributed loads.

Even it can display the topology graph without x,y bus position information.

# Keyword arguments
```jldoctest
    input::String=""
    output::String=""
    display_topology::Bool=false
    graph_title::String=""
    marker_size::Float64=1.5
    timestamp::Bool=false
```

# Data files

Following files must be in the input directory:
```jldoctest
    substation.csv
    line_segments.csv
    line_configurations.csv
```
Following files must be in the input directory if needed:
```jldoctest
    transformers.csv
    regulators.csv
    switches.csv
    distributed_loads.csv
```

Following file is optional: `bus_coords.csv`
    
There are other files required by `powerflow()` function but they are not required by `gridtopology()` operation.

# Notes
Use `input="somewhere"` to specify the directory where input files are. If the directory does not exists `gridtopology()` 
warns it and stop execution.

Use `output="somewhere"` to specify the directory where input results will be written. If the directory does not exists 
it will be created by `gridtopology()`.

By default `gridtopology()` does not show the topology graph in computer screen, in order to automatically display it
`gridtopology(display_topology=true)` is needed.

You can change some graphics attributes such as the graph title, marker size and timestamp. Keyword arguments must be separated by commas.

# Example:
```jldoctest
gridtopology(input="examples/ieee-34", output="results", display_topology=true, graph_title="ieee 34 node test feeder", marker_size=12, timestamp=true)
```
Here `gridtopology()` discover the topology of the network specified by configuration files located in relative directory examples/ieee-34.
Two png image files will be saved in the directory named results, their filenames will have a sufix with the date-hour-minute of creation.
Topology images will also be displayed on screen with the specified title. The bus indicator circle marker will have a relative size of 12. 
"""
function gridtopology(; caller="user", input="", output="", display_topology=false, graph_title="",  marker_size=1.5, timestamp=false)
    #generated variables
    global output_dir
    global working_segments
    global working_buses
    global auxiliar_buses
    global auxiliar_segments
    global adj_mat

    #Check for caller
    if !(caller in ["user", "powerflow"])
        println("Option caller not permitted")
        return
    end

    #Checking Directories
    directory = input
    type = "input"
    input_dir,err_msg = directory_check(directory, type)
    if !(err_msg == "")
        if caller == "user"
            return ("Execution aborted, $(err_msg)")
            
        else return err_msg
        end
    end
    directory = output
    type = "output" 
    output_dir,err_msg = directory_check(directory, type)

    #Reading input files
    err_msg = read_input_files(input_dir, caller)
    if !(err_msg == "")
        if caller == "user"
            println("Execution aborted, $(err_msg)")
            return
        else return err_msg
        end
    end

    #Identify buses from input line segments
    input_buses = select(unique(input_segments,:bus2),2 => :id)
    append!(input_buses,filter(row -> !(row.id in input_buses.id), select(unique(input_segments,:bus1),1 => :id)))

    #Identify adjacencies between input buses
    adj_mat = adjacency_matrix(input_buses, input_segments)

    #Generate input topology graph
    grid = graph_topology("input", input_buses, input_segments, adj_mat, graph_title, marker_size) 

    #Save and display input graph topology
    report_topology(grid, "input", output_dir, display_topology, timestamp) 

    #Defining working topology
    working_segments = [input_segments DataFrame(zeros(Int8,nrow(input_segments),1),[:check])]
    if has_switch
        for m = 1:nrow(working_segments)
            for n = 1:nrow(switches)
                if working_segments[m,:config] == switches[n,:config]
                    if !(switches[n,:state] == "CLOSED")
                        working_segments[m,:check] = 1
                    end
                end
            end
        end
        working_segments = filter(row -> !(row.check == 1), working_segments)
    end

    #filtering out disconnected input segments 
    working_buses = select(substation,:bus => :id)
    increase_working_buses_monitor = nrow(working_buses)
    for n = 1:nrow(working_segments)
        append!(working_buses,select(filter(row -> row.bus1 in working_buses[n,:id] && !(row.bus2 in working_buses.id), working_segments), :bus2 => :id))
        if nrow(working_buses) > increase_working_buses_monitor
            increase_working_buses_monitor += 1
        else break
        end
    end

    #Verifing topology changes by switches
    if has_switch
        if !(nrow(working_buses) == nrow(input_buses))
            # Permuting secuence between :bus1 and :bus2 for segments with changing topology
            buses_differences = nrow(input_buses) - nrow(working_buses)
            for n = 1:buses_differences
                tmp=select(filter(row -> row.bus2 in working_buses.id && !(row.bus1 in working_buses.id), working_segments),[:bus1,:bus2])
                if nrow(tmp) > 0
                    push!(working_buses,[tmp[1,1]])
                    for m = 1:nrow(working_segments)
                        if working_segments[m,:bus1] == tmp[1,:bus1] && working_segments[m,:bus2] == tmp[1,:bus2]
                            working_segments[m,:bus1] = tmp[1,:bus2]
                            working_segments[m,:bus2] = tmp[1,:bus1]
                        end
                    end
                end
            end
        end
    end
    
    #pruning out disconnected working segments
    for m = 1:nrow(working_segments)
        if !(working_segments[m,:bus1] in working_buses.id) 
            working_segments[m,:check] = 1
        end
    end
    working_segments = filter(row -> !(row.check == 1), working_segments)
    working_segments = select!(working_segments, Not(:check))

    #Check for loops
    if nrow(working_segments) - nrow(working_buses) + 1 > 0
        err_msg = "Topology has a loop, this version only works with radial topologies. See result in $(output_dir)."
        return err_msg
    end

    #Adding auxiliar buses for distributed loads
    if has_distributed_load
        working_segments[!,:length] = convert.(Float64, working_segments[!,:length])
        dist_load_segments = similar(working_segments,0)
        auxiliar_buses = DataFrame(bus1 = Int64[], bus2 = Int64[], busx = Int64[])
        next_bus_id = maximum(working_buses[:,:id]) + 1
        for m = 1:nrow(distributed_loads)
            append!(dist_load_segments, filter(row -> row.bus1 == distributed_loads[m,:bus1] && row.bus2 == distributed_loads[m,:bus2], working_segments))
        end
        for m = 1:nrow(dist_load_segments)
            working_segments = filter(row -> !(row.bus1 == dist_load_segments[m,:bus1] && row.bus2 == dist_load_segments[m,:bus2]), working_segments)
        end
        for m = 1:nrow(dist_load_segments)
            length_1 = dist_load_segments[m,:length]*1/2
            length_2 = dist_load_segments[m,:length]*1/2
            start_bus = dist_load_segments[m,:bus1]
            end_bus = dist_load_segments[m,:bus2]
            end_bus = dist_load_segments[m,:bus2]
            unit = dist_load_segments[m,:unit]
            conf =  dist_load_segments[m,:config]
            push!(working_segments, [start_bus next_bus_id length_1 unit conf])
            push!(working_segments, [next_bus_id end_bus length_2 unit conf])
            push!(auxiliar_buses, [start_bus end_bus next_bus_id])
            next_bus_id += 1
        end

        tmp = select(auxiliar_buses, :busx => :id)
        append!(working_buses,tmp)

        if has_bus_coords
            no_coords = filter(row -> !(row.id in bus_coords.bus), working_buses)
            for n = 1:nrow(no_coords)
                pre = filter(row -> row.bus2 == no_coords[n,:id], working_segments)[1,:bus1]
                post = filter(row -> row.bus1 == no_coords[n,:id], working_segments)[1,:bus2]
                pre_coords = filter(row -> row.bus == pre, bus_coords)
                post_coords = filter(row -> row.bus == post, bus_coords)
                if pre_coords[1,:x] == post_coords[1,:x]
                    new_y =  (pre_coords[1,:y] + post_coords[1,:y])/2
                    push!(bus_coords, [no_coords[n,:id] pre_coords[1,:x] new_y])
                elseif pre_coords[1,:y] == post_coords[1,:y]
                    new_x =  (pre_coords[1,:x] + post_coords[1,:x])/2
                    push!(bus_coords, [no_coords[n,:id] new_x pre_coords[1,:y]])
                else 
                    new_y =  (pre_coords[1,:y] + post_coords[1,:y])/2
                    new_x =  (pre_coords[1,:x] + post_coords[1,:x])/2
                    push!(bus_coords, [no_coords[n,:id] new_x new_y])
                end
            end
        end
    end
    
    #Identify adjacencies between working buses
    adj_mat = adjacency_matrix(working_buses, working_segments)

    #Generate working topology graph
    grid = graph_topology("working", working_buses, working_segments, adj_mat, graph_title, marker_size) 

    #Save and display input graph topology
    report_topology(grid, "working", output_dir, display_topology, timestamp) 

    #Function exit modes by caller type
    if caller == "user"
        return println("Execution finished, see results in $(output_dir).")
    else return err_msg
    end

end

function adjacency_matrix(buses, segments)
    #building adjacency matrix
    sort!(buses)
    adj_mat = zeros(Int,nrow(buses),nrow(buses)) #busesxbuses square matrix 

    for m = 1:nrow(segments)
        for i = 1:nrow(buses)
            for j = 1:nrow(buses)
                if buses[i,:id] == segments[m,:bus1]
                    if buses[j,:id] == segments[m,:bus2]
                        adj_mat[i,j] = 1
                    end
                end
            end
        end
    end

    if has_switch
        swt_segments = filter(row -> !(row.config in line_configurations.config) && row.config in switches.config, segments)
        for m = 1:nrow(swt_segments)
            for i = 1:nrow(buses)
                for j = 1:nrow(buses)
                    if buses[i,:id] == swt_segments[m,:bus1] && buses[j,:id] == swt_segments[m,:bus2]
                        swt_state = select(filter(row -> row.config == swt_segments[m,:config], switches), [:state])[1,1]
                        if !(swt_state == "CLOSED")
                            adj_mat[i,j] = 0
                        end
                    end
                end
            end
        end
    end

    return adj_mat
end

function graph_topology(graph_type, buses, segments, adj_mat, graph_title, marker_size)
    #Global variables
    global bus_coords
    global has_bus_coords

    label_texts = Dict()

    if has_transformer
        trf_segments = filter(row -> !(row.config in line_configurations.config) && row.config in transformers.config, segments)
        for m = 1:nrow(trf_segments)
            for i = 1:nrow(buses)
                for j = 1:nrow(buses)
                    if buses[i,:id] == trf_segments[m,:bus1] && buses[j,:id] == trf_segments[m,:bus2]
                        label_texts[(i,j)] = trf_segments[m,:config]
                    end
                end
            end
        end
    end

    if has_switch
        swt_segments = filter(row -> !(row.config in line_configurations.config) && row.config in switches.config, segments)
        for m = 1:nrow(swt_segments)
            for i = 1:nrow(buses)
                for j = 1:nrow(buses)
                    if buses[i,:id] == swt_segments[m,:bus1] && buses[j,:id] == swt_segments[m,:bus2]
                        label_texts[(i,j)] = swt_segments[m,:config]
                    end
                end
            end
        end
    end
    
    if has_regulator
        reg_segments = filter(row -> !(row.config in line_configurations.config) && row.config in regulators.config, segments)
        for m = 1:nrow(reg_segments)
            for i = 1:nrow(buses)
                for j = 1:nrow(buses)
                    if buses[i,:id] == reg_segments[m,:bus1] && buses[j,:id] == reg_segments[m,:bus2]
                        label_texts[(i,j)] = reg_segments[m,:config]
                    end
                end
            end
        end
    end

    if graph_type == "input"
        graph_title = graph_title*" (input topology)"
    else graph_title = graph_title*" (working topology)"
    end

    if has_bus_coords
        bus_coords = filter(row -> row.bus in buses.id, bus_coords) 
        if !(nrow(bus_coords) == nrow(buses))
            println("Check for missing or duplicated bus name in bus_coords.csv file")
            println("Proceeding without bus_coords info")
            has_bus_coords = false
        end
    end

    if has_bus_coords
        sort!(bus_coords)
        x_pos = select(bus_coords, :x)[:,1]
        y_pos = select(bus_coords, :y)[:,1]
        grid_topology = graphplot(adj_mat,
                        names=Matrix(select(buses,:id)),
                        x=x_pos,
                        y=y_pos,
                        edgelabel = label_texts,
                        method=:tree,
                        curves=false,
                        markershape =:circle,
                        markercolor = :lightblue,
                        markersize = marker_size,
                        markerstrokewidth=0,
                        size=(1200,600),
                        axis_buffer=0.1,
                        title = graph_title)
    else
        grid_topology = graphplot(adj_mat,
                        names=Matrix(select(buses,:id)),
                        edgelabel = label_texts,
                        method=:tree,
                        curves=false,
                        markershape =:circle,
                        markercolor = :lightblue,
                        markersize = 0.15,
                        markerstrokewidth=0,
                        size=(1200,600),
                        axis_buffer=0.1,
                        title = graph_title)
    end

    x_lim = round(xlims(grid_topology)[1],digits=1)
    y_lim = round(ylims(grid_topology)[1],digits=1)
    #grid_topology = annotate!(x_lim,y_lim,text.(Dates.now(), 6, :left))
    grid_topology = annotate!(x_lim,y_lim,text.("Generated by SimpleDistributionPowerFlow.jl", 6, :left))

    return grid_topology
end

function report_topology(grid_topology, graph_type, output_dir, display_topology, timestamp)
    if display_topology
        display(grid_topology)
    end

    if timestamp
        date = Dates.format(now(),"yyyymmdd-HHMM")
        if graph_type == "input"
            graph_file=joinpath(output_dir,"sdpf_input_topology_"*date*".png") 
        else graph_file=joinpath(output_dir,"sdpf_working_topology_"*date*".png") 
        end
    else 
        if graph_type == "input"
            graph_file=joinpath(output_dir,"sdpf_input_topology.png") 
        else graph_file=joinpath(output_dir,"sdpf_working_topology.png") 
        end
    end
    savefig(graph_file)    
end