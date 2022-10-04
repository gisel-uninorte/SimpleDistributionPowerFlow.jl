function directory_check(dir,type)    
    err_msg = ""
    if type == "input"
        if !(dir == "") 
            if ispath(dir)
                if !isabspath(dir)
                    dir = joinpath(pwd(),dir)
                end
            else 
                err_msg="$(dir) is not a valid directory"
            end
        else
            dir = pwd()
        end
    elseif type == "output"
        if !(dir == "") 
            if ispath(dir)
                if !isabspath(dir)
                    dir = joinpath(pwd(),dir)
                end
            else mkpath(dir)
                dir = joinpath(pwd(),dir)
            end
        else dir = pwd()
        end
    end
    return dir,err_msg
end

function read_input_files(input_directory, caller)
    #generated variables
    global bus_coords
    global distributed_gen
    global distributed_loads
    global has_bus_coords = false
    global has_capacitor = false
    global has_distributed_gen = false
    global has_distributed_load = false
    global has_regulator = false
    global has_switch = false
    global has_transformer = false 
    global input_capacitors
    global input_segments
    global line_configurations
    global regulators
    global spot_loads
    global substation
    global switches
    global transformers
    
    err_msg = ""
    accepted = DataFrame(unit = ["ft", "mi", "m", "km"])

    #Reading substation parameters from substation.csv file    
    substation, err_msg = read_file(input_directory,"substation.csv")
    if err_msg == "no file"
        err_msg = "there is not 'substation.csv' file in $(input_directory)"
        return err_msg
    elseif err_msg == "empty file"
        err_msg = "'substation.csv' file is empty"
        return err_msg
    elseif !(names(substation) == ["bus","kva","kv"])
        err_msg = "check for column names in 'substation.csv' file"
        return err_msg
    end

    #Reading line segments from line_segments.csv file
    input_segments, err_msg = read_file(input_directory,"line_segments.csv")
    if err_msg == "no file"
        err_msg = "there is not 'line_segments.csv' file in $(input_directory)"
        return err_msg
    elseif err_msg == "empty file"
        err_msg = "'line_segments.csv' file is empty"
        return err_msg
    elseif !(names(input_segments) == ["bus1","bus2","length","unit","config"])
        err_msg = "check for column names in 'line_segments.csv' file"
        return err_msg
    elseif nrow(filter(row -> !(row.unit in accepted.unit), input_segments)) > 0
        err_msg = "check for units in 'line_segments.csv' file (only ft, mi, m and km are accepted units)"
        return err_msg
    end
    if !(nrow(input_segments) == nrow(unique(select(input_segments, [:bus1, :bus2]))))
        err_msg = "check for duplicated links in 'line_segments.csv' file"
        return err_msg
    end
    input_segments[!,:config] = string.(input_segments[!,:config]) #set :config column eltype to string
    input_segments.config = uppercase.(input_segments.config)

    #Reading line configurations from line_configurations.csv file
    line_configurations, err_msg = read_file(input_directory,"line_configurations.csv")
    if err_msg == "no file"
        err_msg = "there is not 'line_configurations.csv' file in $(input_directory)"
        return err_msg
    elseif err_msg == "empty file"
        err_msg = "'line_configurations.csv' file is empty"
        return err_msg
    elseif !(names(line_configurations) == ["config","unit","raa","xaa","rab","xab","rac","xac","rbb","xbb","rbc","xbc","rcc","xcc","baa","bab","bac","bbb","bbc","bcc"])
        err_msg = "check for column names in 'line_configurations.csv' file"
        return err_msg
    elseif nrow(filter(row -> !(row.unit in accepted.unit), line_configurations)) > 0
        err_msg = "check for units in 'line_configurations.csv' file (only ft, mi, m and km are accepted units)"
        return err_msg
    end
    if !(nrow(line_configurations) == nrow(unique(select(line_configurations, [:config]))))
        err_msg = "check for duplicated configuration code in 'line_configurations.csv' file"
        return err_msg
    end
    line_configurations[!,:config] = string.(line_configurations[!,:config]) #set :config column eltype to string
    line_configurations.config = uppercase.(line_configurations.config)

    #Reading transformers data from transformers.csv file
    transformers, err_msg = read_file(input_directory,"transformers.csv")
    if err_msg == ""
        if !(names(transformers) == ["config","kva","phases","conn_high","conn_low","kv_high","kv_low","rpu","xpu"])
            err_msg = "check for column names in 'transformers.csv' file"
            return err_msg
        else
            transformers[!,:config] = string.(transformers[!,:config]) #set :config column eltype to string
            transformers.config = uppercase.(transformers.config)
            if !(nrow(transformers) == nrow(unique(select(transformers, [:config]))))
                err_msg = "check for duplicated configuration code in 'transformers.csv' file"
                return err_msg
            end 
            transformers.conn_high = uppercase.(transformers.conn_high)
            transformers.conn_low = uppercase.(transformers.conn_low)
            has_transformer = true
        end     
    end 

    #Reading switches data from switches.csv file
    switches, err_msg = read_file(input_directory,"switches.csv")
    if err_msg == ""
        if !(names(switches) ==  ["config","phases","state","resistance"])
            err_msg = "check for column names in 'switches.csv' file"
            return err_msg
        else
            switches[!,:config] = string.(switches[!,:config]) #set :config column eltype to string
            switches.config = uppercase.(switches.config)
            if !(nrow(switches) == nrow(unique(select(switches, [:config]))))
                err_msg = "check for duplicated configuration code in 'switches.csv' file"
                return err_msg
            end 
            switches.state = uppercase.(switches.state)
            has_switch = true
        end     
    end 

    #Reading regulators data from regulators.csv file
    regulators, err_msg = read_file(input_directory,"regulators.csv")
    if err_msg == ""
        if !(names(regulators) == ["config","phases","mode","tap_1","tap_2","tap_3"])
            err_msg = "check for column names in 'regulators.csv' file."
            return err_msg
        else
            regulators[!,:config] = string.(regulators[!,:config]) #set :config column eltype to string
            regulators.config = uppercase.(regulators.config)
            if !(nrow(regulators) == nrow(unique(select(regulators, [:config]))))
                err_msg = "check for duplicated configuration code in 'switches.csv' file"
                return err_msg
            end 
            regulators.mode = uppercase.(regulators.mode)
            has_regulator = true
        end     
    end 

    #Reading bus coords data from bus_coords.csv file
    bus_coords, err_msg = read_file(input_directory,"bus_coords.csv")
    if err_msg == ""
        if !(names(bus_coords) == ["bus","x","y"])
            err_msg = "check for column names in 'bus_coords.csv' file. Following without bus coordinates."
            println(err_msg)
        else
            if !(nrow(bus_coords) == nrow(unique(select(bus_coords, [:bus]))))
                err_msg = "check for duplicated bus name in 'bus_coords.csv' file. Following without bus coordinates."
                println(err_msg)
            end 
        end
    end
    if err_msg == ""   
        has_bus_coords = true
    end

    #Identifying input segments types other than line type 
    without_config = filter(row ->!(row.config in line_configurations.config), input_segments)
    if !(nrow(without_config) == 0)
        if has_transformer == true
            without_config = filter(row -> !(row.config in transformers.config), without_config)
        end
    end
    if !(nrow(without_config) == 0)
        if has_switch == true
            without_config = filter(row -> !(row.config in switches.config), without_config)
        end
    end
    if !(nrow(without_config) == 0)
        if has_regulator == true
            without_config = filter(row -> !(row.config in regulators.config), without_config)
        end
    end
    if !(nrow(without_config) == 0)
        err_msg = "check for $(without_config[:,:config]) code(s) in 'line_segments', 'line_configurations', 'transformers', 'switches' or 'regulators' .csv files in $(input_directory)"
        return err_msg
    end
   
    #Reading distributed load
    distributed_loads, err_msg = read_file(input_directory,"distributed_loads.csv")
    if err_msg == ""
        if !(names(distributed_loads) == ["bus1","bus2","conn","type","kw_ph1","kvar_ph1","kw_ph2","kvar_ph2","kw_ph3","kvar_ph3"])
            err_msg = "check for column names in 'distributed_loads.csv' file"
            return err_msg
        else has_distributed_load = true
        end
    else 
        println("no distributed loads")
        err_msg = ""
    end 

    if caller == "powerflow"
        #Reading spot load data
        spot_loads, err_msg = read_file(input_directory,"spot_loads.csv")
        if err_msg == "no file"
            err_msg = "there is not 'spot_loads.csv' file in $(input_directory)"
            return err_msg
        elseif err_msg == "empty file"
            err_msg = "'spot_loads.csv' file is empty"
            return err_msg
        elseif !(names(spot_loads) == ["bus","conn","type","kw_ph1","kvar_ph1","kw_ph2","kvar_ph2","kw_ph3","kvar_ph3"])
            err_msg = "check for column names in 'spot_loads.csv' file"
            return err_msg
        end
        #Reading capacitor data
        input_capacitors, err_msg = read_file(input_directory,"capacitors.csv")
        if err_msg == ""
            if !(names(input_capacitors) == ["bus","kvar_ph1","kvar_ph2","kvar_ph3"])
                err_msg = "check for column names in 'capacitors.csv' file"
                return err_msg
            else has_capacitor = true
            end
        else 
            println("no capacitors")
            err_msg = ""
        end 
        
        #Reading distributed generation data
        distributed_gen, err_msg = read_file(input_directory,"distributed_generation.csv")
        if err_msg == ""
            if !(names(distributed_gen) == ["bus","conn","mode","kw_set","kvar_set","kv_set","i_set","kvar_min","kvar_max","xd"])
                err_msg = "check for column names in 'distributed_generation.csv' file"
                return err_msg
            else
                distributed_gen.mode = uppercase.(distributed_gen.mode)
                modes = filter(row -> !(row.mode in("PQ","WPQ","PQV","PV","PI")),distributed_gen)
                if !(nrow(modes) == 0)
                    err_msg = "modes of Distributed Generation accepted: PQ (traditional constant watt-var), wPQ (weighted PQ), PQV (volt dependant var PQ), PV (volt-var control), PI (constant watt-ampere)"
                    return err_msg
                end
            end
            if !(nrow(distributed_gen) == nrow(dropmissing(dropmissing(dropmissing(distributed_gen,:bus),:conn),:mode)))
                println("Distributed generation registers with missing values will be ignored.")
                dropmissing!(dropmissing!(dropmissing!(distributed_gen,:bus),:conn),:mode)
            end
            if !(nrow(distributed_gen) == 0)
                has_distributed_gen = true
            else
                println("no distributed generation")
                err_msg = ""
            end            
        else 
            println("no distributed generation")
            err_msg = ""
        end 
    end
    return err_msg
end

function read_file(input_directory, filename)
    err_msg = ""
    input_file = joinpath(input_directory,filename)
    if isfile(input_file)
        df = CSV.read(input_file, DataFrame)
        if nrow(df) == 0
            err_msg = "empty file"
        end
    else
        df = DataFrame()
        err_msg = "no file"
    end
    return df, err_msg
end