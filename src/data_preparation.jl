# This file is part of SimpleDistributionPowerFlow.jl package
# It is MIT licensed
# Copyright (c) 2022 Gustavo Espitia, Cesar Orozco, Maria Calle, Universidad del Norte
# Terms of license are in https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/LICENSE

function data_preparation()
    #Global variables
    global ELN
    global D
    global ELL
    global working_buses
    global line_configs
    global lines
    global transformers
    global gen_lines_mat
    global z_line
    global y_line
    global loads
    global Vbus1
    global Vbus2
    global Ibus1
    global Ibus2
    global vnom
    global x_seq_df
    global x_seq
    global as = 1exp(deg2rad(120)im)
    global As = [1 1 1; 1 as^2 as; 1 as as^2]
    
    global has_distributed_gen
    global has_pq_distributed_gen = false
    global pq_distributed_gen = DataFrame()
    global has_pqv_distributed_gen = false
    global pqv_distributed_gen = DataFrame()
    global has_pi_distributed_gen = false
    global pi_distributed_gen = DataFrame()
    global generation_register = DataFrame()

    working_lines()
    
    err_msg = ""
 
    ell = substation[1,:kv]*1000 #circuit's nominal line-to-line voltage
    eln = ell/sqrt(3) #circuit's nominal line-to-neutral voltage
    ELN = [eln; eln*exp(deg2rad(-120)im); eln*exp(deg2rad(120)im)] #circuit's nominal line-to-neutral complex voltages matrix
    D = [1 -1 0; 0 1 -1; -1 0 1] #matrix to convert phase to line complex voltages
    ELL = D*ELN #circuit's nominal line-to-line complex voltages matrix

    #adding base voltages to working buses dataframe
    working_buses = [working_buses DataFrame(zeros(nrow(working_buses),1),[:v_base])]
    for n = 1:nrow(working_buses)
        if !(working_buses[n,:trf] == nothing)
            for t = 1:nrow(transformers)
                if  working_buses[n,:trf] == transformers[t,:config]
                    working_buses[n,:v_base] = transformers[t,:kv_low]*1000/sqrt(3)
                end
            end
        else
            working_buses[n,:v_base] = eln
        end
    end
    
    #constructing working line configurations dataframe
    line_configs = select(line_configurations, [:config, :unit])
    line_configs.zaa = line_configurations.raa + line_configurations.xaa*1im
    line_configs.zab = line_configurations.rab + line_configurations.xab*1im
    line_configs.zac = line_configurations.rac + line_configurations.xac*1im
    line_configs.zbb = line_configurations.rbb + line_configurations.xbb*1im
    line_configs.zbc = line_configurations.rbc + line_configurations.xbc*1im
    line_configs.zcc = line_configurations.rcc + line_configurations.xcc*1im
    line_configs = [line_configs line_configurations[:, 14:end].*1im]

    #preparing data for working lines dataframe
    lines = [lines DataFrame(Matrix{Union{String, Nothing}}(nothing, nrow(working_segments),1),[:phases])]
    lines = [lines DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),12),[:Zaa,:Zab,:Zac,:Zbb,:Zbc,:Zcc,:Baa,:Bab,:Bac,:Bbb,:Bbc,:Bcc])]

    if has_transformer
        transformers[!,:Zt] = (transformers[!,:kv_low].^2)/transformers[!,:kva]*(transformers[!,:rpu]+transformers[!,:xpu]*1im).*1000
    end

    #impedance matrices construction
    for m = 1:nrow(lines)
        #line impedance matrix construction
        if lines[m,:type] == 1 
            for k = 1:nrow(line_configs)
                if line_configs[k,:config] == lines[m,:config] 
                    if lines[m,:unit] == "ft" && line_configs[k,:unit] == "mi"; factor = 1/5280
                    elseif lines[m,:unit] == "m" && line_configs[k,:unit] == "km"; factor = 1/1000
                    elseif lines[m,:unit] == "m" && line_configs[k,:unit] == "mi"; factor = 1/1609.344
                    elseif lines[m,:unit] == "ft" && line_configs[k,:unit] == "km"; factor = 1/3280.8399
                    end
                    lines[m,:Zaa] = line_configs[k,:zaa]*lines[m,:length]*factor
                    lines[m,:Zab] = line_configs[k,:zab]*lines[m,:length]*factor
                    lines[m,:Zac] = line_configs[k,:zac]*lines[m,:length]*factor
                    lines[m,:Zbb] = line_configs[k,:zbb]*lines[m,:length]*factor
                    lines[m,:Zbc] = line_configs[k,:zbc]*lines[m,:length]*factor
                    lines[m,:Zcc] = line_configs[k,:zcc]*lines[m,:length]*factor
                    lines[m,:Baa] = line_configs[k,:baa]*lines[m,:length]*factor*(1e-6)
                    lines[m,:Bab] = line_configs[k,:bab]*lines[m,:length]*factor*(1e-6)
                    lines[m,:Bac] = line_configs[k,:bac]*lines[m,:length]*factor*(1e-6)
                    lines[m,:Bbb] = line_configs[k,:bbb]*lines[m,:length]*factor*(1e-6)
                    lines[m,:Bbc] = line_configs[k,:bbc]*lines[m,:length]*factor*(1e-6)
                    lines[m,:Bcc] = line_configs[k,:bcc]*lines[m,:length]*factor*(1e-6)

                    if lines[m,:Zaa] == 0 && lines[m,:Zbb] == 0 && !(lines[m,:Zcc] == 0)
                        lines[m,:phases] = "c"
                    end
                    if lines[m,:Zaa] == 0 && !(lines[m,:Zbb] == 0) && lines[m,:Zcc] == 0
                        lines[m,:phases] = "b"
                    end
                    if !(lines[m,:Zaa] == 0) && lines[m,:Zbb] == 0 && lines[m,:Zcc] == 0
                        lines[m,:phases] = "a"
                    end
                    if !(lines[m,:Zaa] == 0) && !(lines[m,:Zbb] == 0) && lines[m,:Zcc] == 0
                        lines[m,:phases] = "ab"
                    end
                    if !(lines[m,:Zaa] == 0) && lines[m,:Zbb] == 0 && !(lines[m,:Zcc] == 0)
                        lines[m,:phases] = "ac"
                    end
                    if lines[m,:Zaa] == 0 && !(lines[m,:Zbb] == 0) && !(lines[m,:Zcc] == 0)
                        lines[m,:phases] = "bc"
                    end
                    if !(lines[m,:Zaa] == 0) && !(lines[m,:Zbb] == 0) && !(lines[m,:Zcc] == 0)
                        lines[m,:phases] = "abc"
                    end
                end
            end
        end
        
        #transformer impedance matrix construction
        if lines[m,:type] == 2
            transformer = filter(row -> row.config == lines[m,:config], transformers) 
            lines[m,:Zaa] = transformer[1,:Zt]
            lines[m,:Zab] = 0
            lines[m,:Zac] = 0
            lines[m,:Zbb] = transformer[1,:Zt]
            lines[m,:Zbc] = 0
            lines[m,:Zcc] = transformer[1,:Zt]
            lines[m,:Baa] = 0
            lines[m,:Bab] = 0
            lines[m,:Bac] = 0
            lines[m,:Bbb] = 0
            lines[m,:Bbc] = 0
            lines[m,:Bcc] = 0
            lines[m,:phases] = transformer[1,:phases]
        end
        
        #switch impedance matrix construction
        if lines[m,:type] == 3 
            switch = filter(row -> row.config == lines[m,:config], switches)
            if switch[1,:state] == "CLOSED"
                lines[m,:Zaa] = switch[1,:resistance]
                lines[m,:Zbb] = switch[1,:resistance]
                lines[m,:Zcc] = switch[1,:resistance]
            else
                lines[m,:Zaa] = Inf
                lines[m,:Zbb] = Inf
                lines[m,:Zcc] = Inf
            end
            lines[m,:Zab] = 0
            lines[m,:Zac] = 0
            lines[m,:Zbc] = 0
            lines[m,:Baa] = 0
            lines[m,:Bab] = 0
            lines[m,:Bac] = 0
            lines[m,:Bbb] = 0
            lines[m,:Bbc] = 0
            lines[m,:Bcc] = 0
            lines[m,:phases] = switch[1,:phases]
        end
        
        #regulator impedance matrix construction
        if lines[m,:type] == 4 
            regulator = filter(row -> row.config == lines[m,:config], regulators)
            lines[m,:Zaa] = 0
            lines[m,:Zab] = 0
            lines[m,:Zac] = 0
            lines[m,:Zbb] = 0
            lines[m,:Zbc] = 0
            lines[m,:Zcc] = 0
            lines[m,:Baa] = 0
            lines[m,:Bab] = 0
            lines[m,:Bac] = 0
            lines[m,:Bbb] = 0
            lines[m,:Bbc] = 0
            lines[m,:Bcc] = 0
            lines[m,:phases] = regulator[1,:phases]
        end
    end

    #generalized matrix construction (kersting 4ed, ch. 6) 
    gen_lines_mat = select(lines, [:bus1,:bus2])
    gen_lines_mat = [gen_lines_mat DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),9),[:a_1_1,:a_1_2,:a_1_3,:a_2_1,:a_2_2,:a_2_3,:a_3_1,:a_3_2,:a_3_3,])]
    gen_lines_mat = [gen_lines_mat DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),9),[:b_1_1,:b_1_2,:b_1_3,:b_2_1,:b_2_2,:b_2_3,:b_3_1,:b_3_2,:b_3_3,])]
    gen_lines_mat = [gen_lines_mat DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),9),[:c_1_1,:c_1_2,:c_1_3,:c_2_1,:c_2_2,:c_2_3,:c_3_1,:c_3_2,:c_3_3,])]
    gen_lines_mat = [gen_lines_mat DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),9),[:d_1_1,:d_1_2,:d_1_3,:d_2_1,:d_2_2,:d_2_3,:d_3_1,:d_3_2,:d_3_3,])]
    gen_lines_mat = [gen_lines_mat DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),9),[:A_1_1,:A_1_2,:A_1_3,:A_2_1,:A_2_2,:A_2_3,:A_3_1,:A_3_2,:A_3_3,])]
    gen_lines_mat = [gen_lines_mat DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),9),[:B_1_1,:B_1_2,:B_1_3,:B_2_1,:B_2_2,:B_2_3,:B_3_1,:B_3_2,:B_3_3,])]
    
    z_line=Matrix{Union{Nothing, Complex}}(nothing, 3, 3)
    y_line=Matrix{Union{Nothing, Complex}}(nothing, 3, 3)

    U = [1 0 0; 0 1 0; 0 0 1] #unit matrix

    for m = 1:nrow(lines)
        z_line[1,1] = lines[m,:Zaa]
        z_line[1,2] = lines[m,:Zab]
        z_line[1,3] = lines[m,:Zac]
        z_line[2,1] = lines[m,:Zab]
        z_line[2,2] = lines[m,:Zbb]
        z_line[2,3] = lines[m,:Zbc]
        z_line[3,1] = lines[m,:Zac]
        z_line[3,2] = lines[m,:Zbc]
        z_line[3,3] = lines[m,:Zcc]

        y_line[1,1] = lines[m,:Baa]
        y_line[1,2] = lines[m,:Bab]
        y_line[1,3] = lines[m,:Bac]
        y_line[2,1] = lines[m,:Bab]
        y_line[2,2] = lines[m,:Bbb]
        y_line[2,3] = lines[m,:Bbc]
        y_line[3,1] = lines[m,:Bac]
        y_line[3,2] = lines[m,:Bbc]
        y_line[3,3] = lines[m,:Bcc]

        #line or switch segments
        if lines[m,:type] == 1 || lines[m,:type] == 3
            a = U + 0.5*z_line*y_line
            b = z_line
            c = y_line + 0.25*y_line*z_line*y_line
            d = U + 0.5*y_line*z_line
            A = a^-1
            B = A*b
        end

        #transformer segments
        if lines[m,:type] == 2 
            transformer = filter(row -> row.config == lines[m,:config], transformers)
            if (transformer[1,:conn_high] == "GRY" && transformer[1,:conn_low] == "GRY") ||  (transformer[1,:conn_high] == "D" && transformer[1,:conn_low] == "D")  #grounded_wye-grounded_wye or delta-delta transformer
                nt = transformer[1,:kv_high]/transformer[1,:kv_low]
                a = [nt 0 0; 0 nt 0; 0 0 nt]
                b = a*transformer[1,:Zt]
                c = [0 0 0; 0 0 0; 0 0 0]
                d = (1/nt)*[1 0 0; 0 1 0; 0 0 1]
                A = d
                B = [transformer[1,:Zt] 0 0; 0 transformer[1,:Zt] 0; 0 0 transformer[1,:Zt]]
            elseif transformer[1,:conn_high] == "D" && transformer[1,:conn_low] == "GRY" #delta-grounded_wye transformer
                nt = sqrt(3)*transformer[1,:kv_high]/transformer[1,:kv_low]
                a = (-nt/3)*[0 2 1; 1 0 2; 2 1 0]
                b = a*transformer[1,:Zt]
                c = [0 0 0; 0 0 0; 0 0 0]
                d = (1/nt)*[1 -1 0; 0 1 -1; -1 0 1]                
                A = (1/nt)*[1 0 -1; -1 1 0; 0 -1 1]
                B = [transformer[1,:Zt] 0 0; 0 transformer[1,:Zt] 0; 0 0 transformer[1,:Zt]]
            elseif transformer[1,:conn_high] == "Y" && transformer[1,:conn_low] == "D" #ungrounded_wye-delta transformer
                nt = (transformer[1,:kv_high]/sqrt(3))/transformer[1,:kv_low]
                a = nt*[1 -1 0; 0 1 -1; -1 0 1]
                b = (nt)*[1 -1 0; 1 2 0; -2 -1 0]*transformer[1,:Zt]
                c = [0 0 0; 0 0 0; 0 0 0]     
                d = (1/(3*nt))*[1 -1 0; 1 2 0; -2 -1 0]           
                A = (1/(3*nt))*[2 1 0; 0 2 1; 1 0 2]
                B = [transformer[1,:Zt] 0 0; 0 transformer[1,:Zt] 0; -transformer[1,:Zt] -transformer[1,:Zt] 0]
            else err_msg = "revise transformers.csv file, currently this package only works with GrY-GrY, Y-D, D-GrY and D-D three-phase step-down transformer configurations."
                return err_msg
            end
        end

        #regulator segments
        if lines[m,:type] == 4 
            regulator = filter(row -> row.config == lines[m,:config], regulators)
            if regulator[1,:mode] == "MANUAL"
                a = [1/(1 + 0.00625*regulator[1,:tap_1]) 0 0; 0 1/(1 + 0.00625*regulator[1,:tap_2]) 0; 0 0 1/(1 + 0.00625*regulator[1,:tap_3])]
                b = zeros(3,3)
                c = zeros(3,3)
                d = [(1 + 0.00625*regulator[1,:tap_1]) 0 0; 0 (1 + 0.00625*regulator[1,:tap_2]) 0; 0 0 (1 + 0.00625*regulator[1,:tap_3])]
                A = d
                B = zeros(3,3)
            end
        end

        gen_lines_mat[m,:a_1_1] = a[1,1]
        gen_lines_mat[m,:a_1_2] = a[1,2]
        gen_lines_mat[m,:a_1_3] = a[1,3]
        gen_lines_mat[m,:a_2_1] = a[2,1]
        gen_lines_mat[m,:a_2_2] = a[2,2]
        gen_lines_mat[m,:a_2_3] = a[2,3]
        gen_lines_mat[m,:a_3_1] = a[3,1]
        gen_lines_mat[m,:a_3_2] = a[3,2]
        gen_lines_mat[m,:a_3_3] = a[3,3]

        gen_lines_mat[m,:b_1_1] = b[1,1]
        gen_lines_mat[m,:b_1_2] = b[1,2]
        gen_lines_mat[m,:b_1_3] = b[1,3]
        gen_lines_mat[m,:b_2_1] = b[2,1]
        gen_lines_mat[m,:b_2_2] = b[2,2]
        gen_lines_mat[m,:b_2_3] = b[2,3]
        gen_lines_mat[m,:b_3_1] = b[3,1]
        gen_lines_mat[m,:b_3_2] = b[3,2]
        gen_lines_mat[m,:b_3_3] = b[3,3]

        gen_lines_mat[m,:c_1_1] = c[1,1]
        gen_lines_mat[m,:c_1_2] = c[1,2]
        gen_lines_mat[m,:c_1_3] = c[1,3]
        gen_lines_mat[m,:c_2_1] = c[2,1]
        gen_lines_mat[m,:c_2_2] = c[2,2]
        gen_lines_mat[m,:c_2_3] = c[2,3]
        gen_lines_mat[m,:c_3_1] = c[3,1]
        gen_lines_mat[m,:c_3_2] = c[3,2]
        gen_lines_mat[m,:c_3_3] = c[3,3]

        gen_lines_mat[m,:d_1_1] = d[1,1]
        gen_lines_mat[m,:d_1_2] = d[1,2]
        gen_lines_mat[m,:d_1_3] = d[1,3]
        gen_lines_mat[m,:d_2_1] = d[2,1]
        gen_lines_mat[m,:d_2_2] = d[2,2]
        gen_lines_mat[m,:d_2_3] = d[2,3]
        gen_lines_mat[m,:d_3_1] = d[3,1]
        gen_lines_mat[m,:d_3_2] = d[3,2]
        gen_lines_mat[m,:d_3_3] = d[3,3]

        gen_lines_mat[m,:A_1_1] = A[1,1]
        gen_lines_mat[m,:A_1_2] = A[1,2]
        gen_lines_mat[m,:A_1_3] = A[1,3]
        gen_lines_mat[m,:A_2_1] = A[2,1]
        gen_lines_mat[m,:A_2_2] = A[2,2]
        gen_lines_mat[m,:A_2_3] = A[2,3]
        gen_lines_mat[m,:A_3_1] = A[3,1]
        gen_lines_mat[m,:A_3_2] = A[3,2]
        gen_lines_mat[m,:A_3_3] = A[3,3]

        gen_lines_mat[m,:B_1_1] = B[1,1]
        gen_lines_mat[m,:B_1_2] = B[1,2]
        gen_lines_mat[m,:B_1_3] = B[1,3]
        gen_lines_mat[m,:B_2_1] = B[2,1]
        gen_lines_mat[m,:B_2_2] = B[2,2]
        gen_lines_mat[m,:B_2_3] = B[2,3]
        gen_lines_mat[m,:B_3_1] = B[3,1]
        gen_lines_mat[m,:B_3_2] = B[3,2]
        gen_lines_mat[m,:B_3_3] = B[3,3]
    end


    #Constructing loads dataframe
    loads = DataFrame(bus=Int[], conn=String[], type=String[])
    loads = [loads DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(loads),3),[:ph_1,:ph_2,:ph_3])]

    #adding spot loads
    for k = 1:nrow(spot_loads)
        for n = 1:nrow(working_buses)
            if spot_loads[k,:bus] == working_buses[n,:id]
                push!(loads,(spot_loads[k,:bus],spot_loads[k,:conn],spot_loads[k,:type],
                (spot_loads[k,:kw_ph1]+spot_loads[k,:kvar_ph1]*1im)*1000,
                (spot_loads[k,:kw_ph2]+spot_loads[k,:kvar_ph2]*1im)*1000,
                (spot_loads[k,:kw_ph3]+spot_loads[k,:kvar_ph3]*1im)*1000))
            end
        end
    end

    #adding distributed loads
    if has_distributed_load
        for k = 1:nrow(distributed_loads)
            start_bus = filter(row -> row.bus2 == distributed_loads[k,:bus2], working_segments)[1,:bus1]
            push!(loads,(start_bus,distributed_loads[k,:conn],distributed_loads[k,:type],
                (distributed_loads[k,:kw_ph1]+distributed_loads[k,:kvar_ph1]*1im)*1000,
                (distributed_loads[k,:kw_ph2]+distributed_loads[k,:kvar_ph2]*1im)*1000,
                (distributed_loads[k,:kw_ph3]+distributed_loads[k,:kvar_ph3]*1im)*1000))
        end
    end

    #adding capacitors as negative reactive loads
    for k = 1:nrow(input_capacitors)
        for n = 1:nrow(working_buses)
            if input_capacitors[k,:bus] == working_buses[n,:id]
                push!(loads,(input_capacitors[k,:bus],"Y","Z",
                -input_capacitors[k,:kvar_ph1]*1000im,-input_capacitors[k,:kvar_ph2]*1000im,-input_capacitors[k,:kvar_ph3]*1000im))
            end
        end
    end

    #Identifying distributed generation
    if has_distributed_gen
        generation_register = DataFrame(bus=Int64[], mode=String[], conn=String[], kw_ph1=Float64[], kvar_ph1=Float64[], kw_ph2=Float64[], kvar_ph2=Float64[], kw_ph3=Float64[], kvar_ph3=Float64[], max_diff=Float64[])

        #cheking PQ Distributed Generation registers
        pq_distributed_gen = filter(row -> row.mode == "PQ",distributed_gen)
        if !(nrow(pq_distributed_gen) == nrow(dropmissing(dropmissing(pq_distributed_gen,:kw_set),:kvar_set)))
            println("PQ distributed generation with missing values, it will be ignored.")
            dropmissing!(dropmissing!(pq_distributed_gen,:kw_set),:kvar_set)
        end
        if nrow(filter(row -> !(row.bus in working_buses[!,:id]), pq_distributed_gen)) > 0
            println("PQ distributed generation at non-existent bus, it will be ignored.")
            pq_distributed_gen = filter(row -> row.bus in working_buses[!,:id], pq_distributed_gen)            
        end
        if !(nrow(pq_distributed_gen) == 0)    
            for n = 1:nrow(pq_distributed_gen)
                s_phase =  (pq_distributed_gen[n,:kw_set] + pq_distributed_gen[n,:kvar_set]*1im)*1000/3
                push!(loads,(pq_distributed_gen[n,:bus], pq_distributed_gen[n,:conn], pq_distributed_gen[n,:mode],
                                -s_phase, -s_phase, -s_phase))
                push!(generation_register, (pq_distributed_gen[n,:bus], pq_distributed_gen[n,:mode], pq_distributed_gen[n,:conn],
                                            pq_distributed_gen[n,:kw_set]/3, pq_distributed_gen[n,:kvar_set]/3,
                                            pq_distributed_gen[n,:kw_set]/3, pq_distributed_gen[n,:kvar_set]/3,
                                            pq_distributed_gen[n,:kw_set]/3, pq_distributed_gen[n,:kvar_set]/3, 0))
            end
            has_pq_distributed_gen = true
        end

        #cheking PQV Distributed Generation registers
        pqv_distributed_gen = filter(row -> row.mode == "PQV",distributed_gen)
        if !(nrow(pqv_distributed_gen) == nrow(dropmissing(dropmissing(dropmissing(dropmissing(dropmissing(pqv_distributed_gen,:kw_set),:kv_set),:kvar_min),:kvar_max),:xd)))
            println("PQV distributed generation register with missing values, it will be ignored.")
            dropmissing!(dropmissing!(dropmissing!(dropmissing!(dropmissing!(pqv_distributed_gen,:kw_set),:kv_set),:kvar_min),:kvar_max),:xd)
        end
        if nrow(filter(row -> !(row.bus in working_buses[!,:id]), pqv_distributed_gen)) > 0
            println("PQV distributed generation at non-existent bus, it will be ignored.")
            pqv_distributed_gen = filter(row -> row.bus in working_buses[!,:id], pqv_distributed_gen)
        end  
        if !(nrow(pqv_distributed_gen) == 0) 
            for n = 1:nrow(pqv_distributed_gen)
                p_phase = pqv_distributed_gen[n,:kw_set]*1000/3
                q_phase = (pqv_distributed_gen[n,:kvar_min] + pqv_distributed_gen[n,:kvar_max])*1000/6 #initial VAr setting: average between kvar_max and kvar_min
                s_phase =  (p_phase + q_phase*1im)
                push!(loads,(pqv_distributed_gen[n,:bus],pqv_distributed_gen[n,:conn],pqv_distributed_gen[n,:mode],
                                -s_phase, -s_phase, -s_phase))
                push!(generation_register, (pqv_distributed_gen[n,:bus], pqv_distributed_gen[n,:mode], pqv_distributed_gen[n,:conn],
                                            pqv_distributed_gen[n,:kw_set]/3, (pqv_distributed_gen[n,:kvar_min] + pqv_distributed_gen[n,:kvar_max])/3,
                                            pqv_distributed_gen[n,:kw_set]/3, (pqv_distributed_gen[n,:kvar_min] + pqv_distributed_gen[n,:kvar_max])/3,
                                            pqv_distributed_gen[n,:kw_set]/3, (pqv_distributed_gen[n,:kvar_min] + pqv_distributed_gen[n,:kvar_max])/3, 0))
            end
            select!(pqv_distributed_gen,[:bus, :conn, :mode, :kw_set, :kv_set, :kvar_min, :kvar_max, :xd])
            pqv_distributed_gen = [pqv_distributed_gen DataFrame(zeros(nrow(pqv_distributed_gen),4),[:v_ph1,:v_ph2,:v_ph3,:max_diff])]
            pqv_distributed_gen = [pqv_distributed_gen DataFrame(zeros(nrow(pqv_distributed_gen),6),[:w_ph1 ,:w_ph2,:w_ph3,:var_ph1,:var_ph2,:var_ph3])]
            has_pqv_distributed_gen = true
        end
        
        #cheking PI Distributed Generation registers
        pi_distributed_gen = filter(row -> row.mode == "PI",distributed_gen)
        if !(nrow(pi_distributed_gen) == nrow(dropmissing(dropmissing(dropmissing(dropmissing(pi_distributed_gen,:kw_set),:amp_set),:kvar_min),:kvar_max)))
            println("PI distributed generation register with missing values, it will be ignored.")
            dropmissing!(dropmissing!(dropmissing!(dropmissing!(pi_distributed_gen,:kw_set),:amp_set),:kvar_min),:kvar_max)
        end
        if nrow(filter(row -> !(row.bus in working_buses[!,:id]), pi_distributed_gen)) > 0
            println("PI distributed generation at non-existent bus, it will be ignored.")
            pi_distributed_gen = filter(row -> row.bus in working_buses[!,:id], pi_distributed_gen)
        end  
        if !(nrow(pi_distributed_gen) == 0) 
            for n = 1:nrow(pi_distributed_gen)
                p_phase = pi_distributed_gen[n,:kw_set]*1000/3
                q_phase = (pi_distributed_gen[n,:kvar_min] + pi_distributed_gen[n,:kvar_max])*1000/6 #initial VAr setting: average between kvar_max and kvar_min
                s_phase =  (p_phase + q_phase*1im)
                push!(loads,(pi_distributed_gen[n,:bus],pi_distributed_gen[n,:conn],pi_distributed_gen[n,:mode],
                                -s_phase, -s_phase, -s_phase))
                push!(generation_register, (pi_distributed_gen[n,:bus], pi_distributed_gen[n,:mode], pi_distributed_gen[n,:conn],
                                            pi_distributed_gen[n,:kw_set]/3, (pi_distributed_gen[n,:kvar_min] + pi_distributed_gen[n,:kvar_max])/3,
                                            pi_distributed_gen[n,:kw_set]/3, (pi_distributed_gen[n,:kvar_min] + pi_distributed_gen[n,:kvar_max])/3,
                                            pi_distributed_gen[n,:kw_set]/3, (pi_distributed_gen[n,:kvar_min] + pi_distributed_gen[n,:kvar_max])/3, 0))
            end
            select!(pi_distributed_gen,[:bus, :conn, :mode, :kw_set, :amp_set, :kvar_min, :kvar_max])
            pi_distributed_gen = [pi_distributed_gen DataFrame(zeros(nrow(pi_distributed_gen),4),[:v_ph1,:v_ph2,:v_ph3,:max_diff])]
            pi_distributed_gen = [pi_distributed_gen DataFrame(zeros(nrow(pi_distributed_gen),6),[:w_ph1 ,:w_ph2,:w_ph3,:var_ph1,:var_ph2,:var_ph3])]
            has_pi_distributed_gen = true
        end

        #checking dg
        if !(has_pq_distributed_gen || has_pqv_distributed_gen || has_pi_distributed_gen)
            has_distributed_gen = false   
        end
    end

    #adding columns to loads dataframe for constants
    loads = [loads DataFrame(Matrix{Union{Complex,Nothing}}(nothing,nrow(loads),3),[:k_1,:k_2,:k_3])]

    #calculate constants for constant Z and I load types
    for k = 1:nrow(loads)
        if loads[k,:type] == "Z" || loads[k,:type] == "I"
            for n = 1:nrow(working_buses)
                if working_buses[n,:id] == loads[k,:bus]
                    if loads[k,:conn] == "Y"
                        vnom = working_buses[n,:v_base]
                    end
                    if loads[k,:conn] == "D"
                        vnom = working_buses[n,:v_base]*sqrt(3)
                    end
                end
            end
            if loads[k,:type] == "Z"
                if loads[k,:ph_1] == 0
                    loads[k,:k_1] = 0
                else
                    loads[k,:k_1] = (vnom^2/abs(loads[k,:ph_1]))*exp(angle(loads[k,:ph_1])im) #Z ph1
                end
                if loads[k,:ph_2] == 0 
                    loads[k,:k_2] = 0
                else
                    loads[k,:k_2] = (vnom^2/abs(loads[k,:ph_2]))*exp(angle(loads[k,:ph_2])im) #Z ph2
                end
                if loads[k,:ph_3] == 0 
                    loads[k,:k_3] = 0
                else
                    loads[k,:k_3] = (vnom^2/abs(loads[k,:ph_3]))*exp(angle(loads[k,:ph_3])im) #Z ph3
                end
            end
            if loads[k,:type] == "I"
                if loads[k,:ph_1] == 0
                    loads[k,:k_1] = 0
                else
                    loads[k,:k_1] = abs(loads[k,:ph_1])/vnom #Amp ph1
                end
                if loads[k,:ph_2] == 0 
                    loads[k,:k_2] = 0
                else
                    loads[k,:k_2] = abs(loads[k,:ph_2])/vnom #Amp ph2
                end
                if loads[k,:ph_3] == 0 
                    loads[k,:k_3] = 0
                else
                    loads[k,:k_3] = abs(loads[k,:ph_3])/vnom #Amp ph3
                end
            end
        end
    end
    working_buses = [working_buses DataFrame(zeros(Int8,nrow(working_buses),1),[:process])]
    working_buses = [working_buses DataFrame(Matrix{Union{String, Nothing}}(nothing, nrow(working_buses),1),[:phases])]
    working_buses = [working_buses DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(working_buses),3),[:v_ph1,:v_ph2,:v_ph3])]

    sort!(working_buses,:number, rev=true)
   
    working_buses = [working_buses DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(working_buses),3),[:ibus_1,:ibus_2,:ibus_3])]
    lines = [lines DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lines),3),[:ibus1_1,:ibus1_2,:ibus1_3])]    

    for n = 1:nrow(working_buses)
        working_buses[n,:ibus_1] = 0
        working_buses[n,:ibus_2] = 0
        working_buses[n,:ibus_3] = 0
    end
    for m = 1:nrow(lines)
        lines[m,:ibus1_1] = 0
        lines[m,:ibus1_2] = 0
        lines[m,:ibus1_3] = 0
    end
 
    #temporal containers for bus voltage and current 
    Vbus1 = Complex{Float64}[0;0;0]
    Vbus2 = Complex{Float64}[0;0;0]
    Ibus1 = Complex{Float64}[0;0;0]
    Ibus2 = Complex{Float64}[0;0;0]

    return err_msg

end

function working_lines()
    #Global variables
    global lines
    global working_buses
    
    #=  add :type column to input line segments DataFrame
        line types: 1-->line, 2-->transformer, 3-->switches, 4--> regulators
        phases: "a", "b", "c", "ab", "ac", "bc", "abc"
    =#
    lines = [working_segments DataFrame(zeros(nrow(working_segments),1),[:type])]

    for m = 1:nrow(lines)
        if lines[m,:config] in line_configurations[:,:config]
            lines[m,:type] = 1 #line segment
        end
        if has_transformer
            if lines[m,:config] in transformers[:,:config]
                lines[m,:type] = 2 #inline transformer
            end
        end
        if has_switch
            if lines[m,:config] in switches[:,:config]
                lines[m,:type] = 3 #switched connection
            end
        end
        if has_regulator
            if lines[m,:config] in regulators[:,:config]
                lines[m,:type] = 4 #regulator
            end
        end
    end

    working_buses = [working_buses DataFrame(zeros(Int64,nrow(working_buses),2),[:type, :number])]

    downward_buses = sum(adj_mat,dims=2)
    #upward_buses = sum(adj_mat,dims=1)
    for n = 1:nrow(working_buses)
        if downward_buses[n,1] == 0
            working_buses[n,:type] = 5 #ending bus
        elseif downward_buses[n,1] > 1
            working_buses[n,:type] = 2 #bifurcation bus
        end
    end
    
    for n = 1:nrow(working_buses)
        if downward_buses[n,1] == 1
            next_bus = filter(row -> row.bus1 == working_buses[n,:id], working_segments)[1,:bus2]
            if filter(row -> row.id == next_bus, working_buses)[1,:type] == 5
                working_buses[n,:type] = 4 #next-to-end sequential bus
            else working_buses[n,:type] = 3 #intermediate sequential bus
            end
        end
    end
    
    for n = 1:nrow(working_buses)
        if working_buses[n,:id] == substation[1,:bus]
            working_buses[n,:type] = 1 #subestation bus
        end
   end

   sort!(working_buses,:type,rev=false)

   for n = 1:nrow(working_buses)
        if working_buses[n,:type] == 1 || working_buses[n,:type] == 4 || working_buses[n,:type] == 5
            working_buses[n,:number] = n
        end
    end

    initial_buses = nrow(filter(row -> (row.type == 1),  working_buses))
    bifurcation_buses = nrow(filter(row -> (row.type == 2),  working_buses))
    intermediate_buses = nrow(filter(row -> (row.type == 3),  working_buses))
    next_to_end_buses = nrow(filter(row -> (row.type == 4),  working_buses))
    end_buses = nrow(filter(row -> (row.type == 5),  working_buses))
 
    k = nrow(working_buses) - end_buses - next_to_end_buses
    
    #intermediate and bifurcation buses enumeration
    if bifurcation_buses > 0
        for p = 1:bifurcation_buses
            for q = 1:next_to_end_buses
                for n1 = 1:nrow(working_buses)
                    if working_buses[n1,:type] == 3
                        if working_buses[n1,:number] == 0
                            for m = 1:nrow(working_segments)
                                if working_segments[m,:bus1] == working_buses[n1,:id]
                                    for n2 = 1:nrow(working_buses)
                                        if working_buses[n2,:id] == working_segments[m,:bus2]
                                            if !(working_buses[n2,:number] == 0)
                                                working_buses[n1,:number] = k
                                                k = k-1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            for n1 = 1:nrow(working_buses)
                waiting = 0
                if working_buses[n1,:type] == 2
                    if working_buses[n1,:number] == 0
                        for m = 1:nrow(working_segments)
                            if working_segments[m,:bus1] == working_buses[n1,:id]
                                for n2 = 1:nrow(working_buses)
                                    if working_buses[n2,:id] == working_segments[m,:bus2]
                                        if working_buses[n2,:number] == 0
                                            waiting = 1
                                        end
                                    end
                                end
                            end
                        end
                        if waiting == 0
                            working_buses[n1,:number] = k
                            k = k - 1
                        end
                    end
                end
            end
        end
    else 
        for n1 = 1:nrow(working_buses)
            if working_buses[n1,:type] == 3
                for m = 1:nrow(working_segments)
                    if working_segments[m,:bus1] == working_buses[n1,:id]
                        for n2 = 1:nrow(working_buses)
                            if working_buses[n2,:id] == working_segments[m,:bus2]
                                if !(working_buses[n2,:number] == 0)
                                    working_buses[n1,:number] = working_buses[n2,:number] -1
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    unnumbered_buses = filter(row -> row.type == 3 && row.number == 0, working_buses)

    while nrow(unnumbered_buses) > 0
        for n = 1:nrow(working_buses)
            if working_buses[n,:number] == 0
                precedent = (filter(row -> row.bus2 == working_buses[n,:id], working_segments))[1,:bus1]
                number = (filter(row -> row.id == precedent, working_buses))[1,:number]
                if number > 0
                    working_buses[n,:number] = number + 1
                end
            end
        end
        unnumbered_buses = filter(row -> row.type == 3 && row.number == 0, working_buses)
    end
    sort!(working_buses,:number,rev=false)

    #marking of buses downstream of transformers
    working_buses[!,:trf] = Vector{Union{String, Nothing}}(nothing, nrow(working_buses))
 
    for t = 1:nrow(transformers)
        for m = 1:nrow(working_segments)
            if working_segments[m,:config] == transformers[t,:config]
                for n = 1:nrow(working_buses)
                    if working_buses[n,:id] == working_segments[m,:bus2]
                        working_buses[n,:trf] = transformers[t,:config]
                    end
                end
            end
        end
    end
 
    for n1 = 1:nrow(working_buses)
        if !(working_buses[n1,:trf] == nothing) && !(working_buses[n1,:type] == 5)
            for m = 1:nrow(working_segments)
                if working_segments[m,:bus1] == working_buses[n1,:id]
                    for n2 = 1:nrow(working_buses)
                        if working_buses[n2,:id] == working_segments[m,:bus2]
                            working_buses[n2,:trf] = working_buses[n1,:trf]
                        end
                    end
                end
            end
        end
    end 
end