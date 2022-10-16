# This file is part of SimpleDistributionPowerFlow.jl package
# It is MIT licensed
# Copyright (c) 2022 Gustavo Espitia, Cesar Orozco, Maria Calle, Universidad del Norte
# Terms of license are in https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/LICENSE

"""
    powerflow(;kwargs...)

A `function` to evaluate the voltage levels of a three-phase distribution network and the power 
flow in lines between buses based on grid infrastructure, loads and generation information.    

Data is input via `.cvs` files with minimum specification. There is not need to indicate midpoints for distributed 
loads, or sequential enumeration of buses, `powerflow()` leverages on `gridtopology()` to discover the 
network topology. It can evaluate bus voltages and reversing power flows due change in topology by
opening and closing switches.

# Keyword arguments
```jldoctest
    input::String=""
    output::String=""
    tolerance::Float64=1e6
    max_iterations::Int=30
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
    spot_loads.csv
```
Following files must be in the input directory if needed:
```jldoctest
    transformers.csv
    regulators.csv
    switches.csv
    capacitors.csv
    distributed_loads.csv
    distributed_generation.csv
```
    
Following file is optional: `bus_coords.csv`

# Notes

By default `powerflow()` reads input files from, and writes result files to the current directory.
Is user want to load files from other directory must specify with the input argument, also if he/she want
to save result files to other directory must be specified whith output argument.

By default a resume of total input and loss power, and the result of buses voltages 
are displayed in computer screen after execution, the other results are saved in .csv files
in output directory.

The result files can have a timestamp for sequencial analysis. 

Currently `powerflow()` only works with radial feeders, the user can change the state of 
switches in order to open loops if presented. 

The operational algorithm is based on forward-backward sweeps, with the generalized matrices
proposed by William H. Kersting in Distribution System Modeling and Analysis, 4th ed, Taylor & Francis Group 2017.
    
# Example:
```jldoctest
powerflow(input="examples/ieee-34", output="results", tolerance=1e-9, max_iterations=30, display_topology=true, 
          graph_title="ieee 34 node test feeder", marker_size=12, timestamp=true)
```
Here `powerflow()`, by internally calling `gridtopology()` function discovers the topology of the network specified 
and executes the forward and backward sweeps until the calculated substation voltage differs lower than 1e-9 from the original value or 30 iterations are reached.
"""
function powerflow(; input="", output="", 
                     tolerance=1e-6, max_iterations=30, 
                     display_results=true, timestamp=false,
                     display_topology=false, graph_title="",  marker_size=1.5, verbose=0)
    
    
    #Data input and discovery topology
    err_msg = gridtopology(caller="powerflow", input=input, output=output, timestamp=timestamp,
                           display_topology=display_topology, graph_title=graph_title, marker_size=marker_size, verbose=verbose)
    if !(err_msg == "")
        return ("Execution aborted, $(err_msg)")
        
    end
    
    #Data preparation
    err_msg = data_preparation()
    if !(err_msg == "")
        println("Execution aborted, $(err_msg)")
        return 
    end

    #powerflow procedure
    global outer_iteration = 0
    global inner_iteration
    max_diff = 1.0
    while   max_diff > tolerance
        
        #forward and backward procedure without DG and PQ DG only
        err_msg,inner_iteration = forward_backward_sweep(tolerance,max_iterations)
        if !(err_msg == "")
            println("Execution aborted, $(err_msg)")
            return 
        end

        #adjustment by distributed generation others than PQ - PQ DG was setup in data_preparation()
        if has_distributed_gen

            if has_pqv_distributed_gen

                #forward_backward_sweep results for buses with PQV DG
                volt_pqv_buses = select((filter(row -> row.id in(pqv_distributed_gen[!,:bus]), working_buses)), [:id, :v_ph1, :v_ph2, :v_ph3]) 

                #iteration for each PQV DG
                for n = 1:nrow(pqv_distributed_gen) 

                    #forward_backward_sweep results for buses with PQV DG
                    volt_pqv_buses = select((filter(row -> row.id in(pqv_distributed_gen[!,:bus]), working_buses)), [:id, :v_ph1, :v_ph2, :v_ph3]) 

                    for n = 1:nrow(pqv_distributed_gen)

                        #bus volts from outer iteration k-1 (old)
                        volt_pqv_old =[pqv_distributed_gen[n,:v_ph1], pqv_distributed_gen[n,:v_ph2], pqv_distributed_gen[n,:v_ph3]]

                        #bus volts from external iteration k (new)
                        volt_pqv_bus = filter(row -> row.id == pqv_distributed_gen[n,:bus], volt_pqv_buses)
                        volt_pqv_new = [abs(volt_pqv_bus[1,:v_ph1]), abs(volt_pqv_bus[1,:v_ph2]), abs(volt_pqv_bus[1,:v_ph3])]

                        v_set = pqv_distributed_gen[n,:kv_set]*1000/sqrt(3)
                        xd = pqv_distributed_gen[n,:xd]
                                
                        p_phase = pqv_distributed_gen[n,:kw_set]*1000/3
                        w_ph1 = p_phase
                        w_ph2 = p_phase
                        w_ph3 = p_phase
                        var_ph1 = sqrt((v_set*volt_pqv_new[1]/xd)^2 - p_phase^2) - volt_pqv_new[1]^2/xd
                        var_ph2 = sqrt((v_set*volt_pqv_new[2]/xd)^2 - p_phase^2) - volt_pqv_new[2]^2/xd
                        var_ph3 = sqrt((v_set*volt_pqv_new[3]/xd)^2 - p_phase^2) - volt_pqv_new[3]^2/xd

                        if var_ph1 < pqv_distributed_gen[n,:kvar_min]*1000/3   var_ph1 = pqv_distributed_gen[n,:kvar_min]*1000/3; end
                        if var_ph2 < pqv_distributed_gen[n,:kvar_min]*1000/3   var_ph2 = pqv_distributed_gen[n,:kvar_min]*1000/3; end
                        if var_ph3 < pqv_distributed_gen[n,:kvar_min]*1000/3   var_ph3 = pqv_distributed_gen[n,:kvar_min]*1000/3; end

                        if var_ph1 > pqv_distributed_gen[n,:kvar_max]*1000/3   var_ph1 = pqv_distributed_gen[n,:kvar_max]*1000/3; end
                        if var_ph2 > pqv_distributed_gen[n,:kvar_max]*1000/3   var_ph2 = pqv_distributed_gen[n,:kvar_max]*1000/3; end
                        if var_ph3 > pqv_distributed_gen[n,:kvar_max]*1000/3   var_ph3 = pqv_distributed_gen[n,:kvar_max]*1000/3; end

                        #eliminate row of distributed generation from loads dataframe
                        filter!(row -> !(row.bus == pqv_distributed_gen[n,:bus] && row.type == pqv_distributed_gen[n,:mode]),loads)

                        #add row of distributed generation to loads dataframe with new P and Q data
                        push!(loads,(pqv_distributed_gen[n,:bus],pqv_distributed_gen[n,:conn],pqv_distributed_gen[n,:mode],
                                    -(w_ph1 + var_ph1*1im), -(w_ph2 + var_ph2*1im), -(w_ph3 + var_ph3*1im), nothing, nothing, nothing)) 

                        #to follow voltage fixing between outer iterations
                        max_volt_diff = maximum(abs.((volt_pqv_old - volt_pqv_new)./volt_pqv_new))

                        #storing new values to be used as old ones in next outer iteration
                        pqv_distributed_gen[n,:v_ph1] = volt_pqv_new[1]
                        pqv_distributed_gen[n,:v_ph2] = volt_pqv_new[2]
                        pqv_distributed_gen[n,:v_ph3] = volt_pqv_new[3]
                        pqv_distributed_gen[n,:max_diff] = max_volt_diff
                        pqv_distributed_gen[n,:w_ph1] = w_ph1
                        pqv_distributed_gen[n,:w_ph2] = w_ph2
                        pqv_distributed_gen[n,:w_ph3] = w_ph3 
                        pqv_distributed_gen[n,:var_ph1] = var_ph1
                        pqv_distributed_gen[n,:var_ph2] = var_ph2
                        pqv_distributed_gen[n,:var_ph3] = var_ph3

                        filter!(row -> !(row.bus == pqv_distributed_gen[n,:bus]), generation_register)
                        push!(generation_register, (pqv_distributed_gen[n,:bus], pqv_distributed_gen[n,:mode], pqv_distributed_gen[n,:conn], 
                                            w_ph1/1000, var_ph1/1000, w_ph2/1000, var_ph2/1000, w_ph3/1000, var_ph3/1000, max_volt_diff))

                    end
                end

            end

            if has_pi_distributed_gen

                #forward_backward_sweep results for buses with PI DG
                volt_pi_buses = select((filter(row -> row.id in(pi_distributed_gen[!,:bus]), working_buses)), [:id, :v_ph1, :v_ph2, :v_ph3]) 
                for n = 1:nrow(pi_distributed_gen)
                    
                    #bus volts from outer iteration k-1 (old)
                    volt_pi_old =[pi_distributed_gen[n,:v_ph1], pi_distributed_gen[n,:v_ph2], pi_distributed_gen[n,:v_ph3]]

                    #bus volts from external iteration k (new)
                    volt_pi_bus = filter(row -> row.id == pi_distributed_gen[n,:bus], volt_pi_buses)
                    volt_pi_new = [abs(volt_pi_bus[1,:v_ph1]), abs(volt_pi_bus[1,:v_ph2]), abs(volt_pi_bus[1,:v_ph3])]

                    i_set = pi_distributed_gen[n,:amp_set]
                    p_ph = pi_distributed_gen[n,:kw_set]*1000/3
                    q_min = pi_distributed_gen[n,:kvar_min]*1000/3
                    q_max = pi_distributed_gen[n,:kvar_max]*1000/3

                    if pi_distributed_gen[n,:conn] == "Y"
                        v_ph1 = abs(volt_pi_bus[1,:v_ph1])
                        v_ph2 = abs(volt_pi_bus[1,:v_ph2])
                        v_ph3 = abs(volt_pi_bus[1,:v_ph3])
                        i_ph  = i_set                 
                    elseif pi_distributed_gen[n,:conn] == "D"
                        v_ph1 = abs(volt_pi_bus[1,:v_ph1] - volt_pi_bus[1,:v_ph2])
                        v_ph2 = abs(volt_pi_bus[1,:v_ph2] - volt_pi_bus[1,:v_ph3])
                        v_ph3 = abs(volt_pi_bus[1,:v_ph3] - volt_pi_bus[1,:v_ph1])
                        i_ph  = i_set/sqrt(3) 
                    end

                    if !((i_ph*v_ph1)^2 - p_ph^2 < 0)
                        q_ph1 = sqrt((i_ph*v_ph1)^2 - p_ph^2)
                    else q_ph1 = q_min
                    end
                    if !((i_ph*v_ph2)^2 - p_ph^2 < 0)
                        q_ph2 = sqrt((i_ph*v_ph2)^2 - p_ph^2)
                    else q_ph2 = q_min
                    end
                    if !((i_ph*v_ph3)^2 - p_ph^2 < 0)
                        q_ph3 = sqrt((i_ph*v_ph3)^2 - p_ph^2)
                    else q_ph3 = q_min
                    end
                    
                    if q_ph1 > q_max   q_ph1 = q_max; end
                    if q_ph2 > q_max   q_ph2 = q_max; end
                    if q_ph3 > q_max   q_ph2 = q_max; end


                    #eliminate row of distributed generation from loads dataframe
                    filter!(row -> !(row.bus == pi_distributed_gen[n,:bus] && row.type == pi_distributed_gen[n,:mode]),loads)

                    #add row of distributed generation to loads dataframe with new P and Q data
                    push!(loads,(pi_distributed_gen[n,:bus],pi_distributed_gen[n,:conn],pi_distributed_gen[n,:mode],
                                -(p_ph + q_ph1*1im), -(p_ph + q_ph2*1im), -(p_ph + q_ph3*1im), nothing, nothing, nothing))   
                    
                    
                    #to follow voltage fixing between outer iterations
                    max_volt_diff = maximum(abs.((volt_pi_old - volt_pi_new)./volt_pi_new))

                    #storing new values to be used as old ones in next outer iteration
                    pi_distributed_gen[n,:v_ph1] = volt_pi_new[1]
                    pi_distributed_gen[n,:v_ph2] = volt_pi_new[2]
                    pi_distributed_gen[n,:v_ph3] = volt_pi_new[3]
                    pi_distributed_gen[n,:max_diff] = max_volt_diff
                    pi_distributed_gen[n,:w_ph1] = p_ph
                    pi_distributed_gen[n,:w_ph2] = p_ph
                    pi_distributed_gen[n,:w_ph3] = p_ph
                    pi_distributed_gen[n,:var_ph1] = q_ph1
                    pi_distributed_gen[n,:var_ph2] = q_ph2
                    pi_distributed_gen[n,:var_ph3] = q_ph3

                    filter!(row -> !(row.bus == pi_distributed_gen[n,:bus]), generation_register)
                    push!(generation_register, (pi_distributed_gen[n,:bus], pi_distributed_gen[n,:mode], pi_distributed_gen[n,:conn], 
                                        p_ph/1000, q_ph1/1000, p_ph/1000, q_ph2/1000, p_ph/1000, q_ph3/1000, max_volt_diff))

                end
            end

            max_diff = maximum(generation_register[!,:max_diff])

        else max_diff = 0
        end
        
        outer_iteration += 1
    end

    #Results report
    if err_msg == ""
        if !(verbose == 0)
            println("Execution finished, $(outer_iteration) outer iterations, $(inner_iteration) inner iterations (for latest outer round), $(tolerance) tolerance")
        end
        #Write files with detailed powerflow results
        results(display_results,timestamp)
        else
        println("Execution aborted, $(err_msg)")
        return
    end

end
