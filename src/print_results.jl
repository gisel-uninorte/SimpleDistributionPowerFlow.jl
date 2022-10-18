# This file is part of SimpleDistributionPowerFlow.jl package
# It is MIT licensed
# Copyright (c) 2022 Gustavo Espitia, Cesar Orozco, Maria Calle, Universidad del Norte
# Terms of license are in https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/LICENSE

function results(display_summary,timestamp)
    #Global variables
    global working_buses
    global auxiliar_buses

    #adding phase info to working_buses
    for n = 1:nrow(working_buses)
        if !(working_buses[n,:number] == 1)
            for m = 1:nrow(lines)
                if lines[m,:bus2] == working_buses[n,:id]
                    working_buses[n,:phases] = lines[m,:phases]
                end
            end
        else working_buses[n,:phases] = "abc"
        end
    end
    if has_distributed_load
        auxiliar_buses.phases = missings(String, nrow(auxiliar_buses))
        for n = 1:nrow(auxiliar_buses)
            auxiliar_buses[n,:phases] = filter(row -> row.id == auxiliar_buses[n,:busx] ,working_buses)[1,:phases]
        end
    end
    
    #preparing volts report
    volts = select(working_buses, :id, :number)
    volts_phases = [volts DataFrame(Matrix{Union{Float64, Nothing}}(nothing, nrow(volts),6),[:volt_A,:deg_A,:volt_B,:deg_B,:volt_C,:deg_C])]
    volts_pu = [volts DataFrame(Matrix{Union{Float64, Nothing}}(nothing, nrow(volts),6),[:volt_A,:deg_A,:volt_B,:deg_B,:volt_C,:deg_C])]
    for n = 1:nrow(volts_phases)
        if working_buses[n,:phases] == "a"
            volts_phases[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1]),digits=1)
            volts_phases[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
            volts_pu[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
        elseif working_buses[n,:phases] == "b"
            volts_phases[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2]),digits=1)
            volts_phases[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
            volts_pu[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
        elseif working_buses[n,:phases] == "c"
            volts_phases[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3]),digits=1)
            volts_phases[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2)
            volts_pu[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2)
        elseif working_buses[n,:phases] == "ab"
            volts_phases[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1]),digits=1)
            volts_phases[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2]),digits=1)
            volts_phases[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
            volts_phases[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
            volts_pu[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
            volts_pu[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
        elseif working_buses[n,:phases] == "bc"
            volts_phases[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2]),digits=1)
            volts_phases[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3]),digits=1)
            volts_phases[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
            volts_phases[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2)
            volts_pu[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
            volts_pu[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2)
        elseif working_buses[n,:phases] == "ac"
            volts_phases[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1]),digits=1)
            volts_phases[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3]),digits=1)
            volts_phases[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
            volts_phases[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2)
            volts_pu[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
            volts_pu[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2)
        elseif working_buses[n,:phases] == "abc"
            volts_phases[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1]),digits=1)
            volts_phases[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2]),digits=1)
            volts_phases[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3]),digits=1)
            volts_phases[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
            volts_phases[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
            volts_phases[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2) 
            volts_pu[n, :volt_A] = round.(abs.(working_buses[n, :v_ph1])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :volt_B] = round.(abs.(working_buses[n, :v_ph2])/working_buses[n, :v_base],digits=5)
            volts_pu[n, :volt_C] = round.(abs.(working_buses[n, :v_ph3])/working_buses[n, :v_base],digits=5)    
            volts_pu[n, :deg_A] = round.(rad2deg.(angle.(working_buses[n, :v_ph1])),digits=2)
            volts_pu[n, :deg_B] = round.(rad2deg.(angle.(working_buses[n, :v_ph2])),digits=2)
            volts_pu[n, :deg_C] = round.(rad2deg.(angle.(working_buses[n, :v_ph3])),digits=2)            
        end
    end
    select!(volts_phases,Not(:number))
    sort!(volts_phases,:id)

    select!(volts_pu,Not(:number))
    sort!(volts_pu,:id)

    ext_v_pu = DataFrame(max=0.0, bus_max=0, min=2.0, bus_min=0)
    for n = 1:nrow(volts_pu)
        if !(isnothing(volts_pu[n, :volt_A]))
            if volts_pu[n, :volt_A] > ext_v_pu[1, :max]
                ext_v_pu[1, :max] = volts_pu[n, :volt_A]
                ext_v_pu[1, :bus_max] = volts_pu[n, :id]              
            end
            if volts_pu[n, :volt_A] < ext_v_pu[1, :min]
                ext_v_pu[1, :min] = volts_pu[n, :volt_A]
                ext_v_pu[1, :bus_min] = volts_pu[n, :id]            
            end
        end
        if !(isnothing(volts_pu[n, :volt_B]))
            if volts_pu[n, :volt_B] > ext_v_pu[1, :max]
                ext_v_pu[1, :max] = volts_pu[n, :volt_B]
                ext_v_pu[1, :bus_max] = volts_pu[n, :id]              
            end
            if volts_pu[n, :volt_B] < ext_v_pu[1, :min]
                ext_v_pu[1, :min] = volts_pu[n, :volt_B]
                ext_v_pu[1, :bus_min] = volts_pu[n, :id]            
            end
        end
        if !(isnothing(volts_pu[n, :volt_C]))
            if volts_pu[n, :volt_C] > ext_v_pu[1, :max]
                ext_v_pu[1, :max] = volts_pu[n, :volt_C]
                ext_v_pu[1, :bus_max] = volts_pu[n, :id]              
            end
            if volts_pu[n, :volt_C] < ext_v_pu[1, :min]
                ext_v_pu[1, :min] = volts_pu[n, :volt_C]
                ext_v_pu[1, :bus_min] = volts_pu[n, :id]            
            end
        end
    end    
    
    volts_lines = [volts DataFrame(Matrix{Union{Float64, Nothing}}(nothing, nrow(volts),6),[:volt_AB,:deg_AB,:volt_BC,:deg_BC,:volt_CA,:deg_CA])]
    for n = 1:nrow(volts_lines)
        if working_buses[n,:phases] == "ab"
            volts_lines[n, :volt_AB] = round.(abs.(working_buses[n, :v_ph1] - working_buses[n, :v_ph2]),digits=1)
            volts_lines[n, :deg_AB] = round.(rad2deg.(angle.(working_buses[n, :v_ph1] - working_buses[n, :v_ph2])),digits=2)
        elseif working_buses[n,:phases] == "bc"
            volts_lines[n, :volt_BC] = round.(abs.(working_buses[n, :v_ph2] - working_buses[n, :v_ph3]),digits=1)
            volts_lines[n, :deg_BC] = round.(rad2deg.(angle.(working_buses[n, :v_ph2] - working_buses[n, :v_ph3])),digits=2)
        elseif working_buses[n,:phases] == "ac"
            volts_lines[n, :volt_CA] = round.(abs.(working_buses[n, :v_ph3] - working_buses[n, :v_ph1]),digits=1)
            volts_lines[n, :deg_CA] = round.(rad2deg.(angle.(working_buses[n, :v_ph3] - working_buses[n, :v_ph1])),digits=2)
        elseif working_buses[n,:phases] == "abc"
            volts_lines[n, :volt_AB] = round.(abs.(working_buses[n, :v_ph1] - working_buses[n, :v_ph2]),digits=1)
            volts_lines[n, :volt_BC] = round.(abs.(working_buses[n, :v_ph2] - working_buses[n, :v_ph3]),digits=1)
            volts_lines[n, :volt_CA] = round.(abs.(working_buses[n, :v_ph3] - working_buses[n, :v_ph1]),digits=1)
            volts_lines[n, :deg_AB] = round.(rad2deg.(angle.(working_buses[n, :v_ph1] - working_buses[n, :v_ph2])),digits=2)
            volts_lines[n, :deg_BC] = round.(rad2deg.(angle.(working_buses[n, :v_ph2] - working_buses[n, :v_ph3])),digits=2)
            volts_lines[n, :deg_CA] = round.(rad2deg.(angle.(working_buses[n, :v_ph3] - working_buses[n, :v_ph1])),digits=2)
        end
    end
    sort!(volts_lines,:number)
    select!(volts_lines,Not(:number))

    lineflow=select(lines,:bus1,:bus2, :phases, :ibus1_1,:ibus1_2,:ibus1_3)
    rename!(lineflow, :bus1 => :from, :bus2 => :to, :ibus1_1 => :in_I_ph1, :ibus1_2 => :in_I_ph2, :ibus1_3 => :in_I_ph3)
    lineflow = [lineflow DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lineflow),3),[:out_I_ph1, :out_I_ph2, :out_I_ph3])]
    lineflow = [lineflow DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lineflow),3),[:in_S_ph1, :in_S_ph2, :in_S_ph3])]
    lineflow = [lineflow DataFrame(Matrix{Union{Complex, Nothing}}(nothing, nrow(lineflow),3),[:out_S_ph1, :out_S_ph2, :out_S_ph3])]

    for m = 1:nrow(lineflow)
        for n = 1:nrow(working_buses)
        if working_buses[n,:id] == lineflow[m,:to]
            lineflow[m,:out_I_ph1] = working_buses[n,:ibus_1]
            lineflow[m,:out_I_ph2] = working_buses[n,:ibus_2]
            lineflow[m,:out_I_ph3] = working_buses[n,:ibus_3]
            lineflow[m,:out_S_ph1] = working_buses[n,:v_ph1]*conj(lineflow[m,:out_I_ph1])
            lineflow[m,:out_S_ph2] = working_buses[n,:v_ph2]*conj(lineflow[m,:out_I_ph2])
            lineflow[m,:out_S_ph3] = working_buses[n,:v_ph3]*conj(lineflow[m,:out_I_ph3])
            end
        if working_buses[n,:id] == lineflow[m,:from]
            lineflow[m,:in_S_ph1] = working_buses[n,:v_ph1]*conj(lineflow[m,:in_I_ph1])
            lineflow[m,:in_S_ph2] = working_buses[n,:v_ph2]*conj(lineflow[m,:in_I_ph2])
            lineflow[m,:in_S_ph3] = working_buses[n,:v_ph3]*conj(lineflow[m,:in_I_ph3])
            end
        end
    end

    lineflow.ploss_ph1 = real.(lineflow.in_S_ph1) - real.(lineflow.out_S_ph1)
    lineflow.ploss_ph2 = real.(lineflow.in_S_ph2) - real.(lineflow.out_S_ph2)
    lineflow.ploss_ph3 = real.(lineflow.in_S_ph3) - real.(lineflow.out_S_ph3)
    lineflow.ploss_totals = round.(lineflow.ploss_ph1 .+ lineflow.ploss_ph2 .+ lineflow.ploss_ph3,digits=1)

    lineflow.qloss_ph1 = imag.(lineflow.in_S_ph1) - imag.(lineflow.out_S_ph1)
    lineflow.qloss_ph2 = imag.(lineflow.in_S_ph2) - imag.(lineflow.out_S_ph2)
    lineflow.qloss_ph3 = imag.(lineflow.in_S_ph3) - imag.(lineflow.out_S_ph3)
    lineflow.qloss_totals = round.(lineflow.qloss_ph1 .+ lineflow.qloss_ph2 .+ lineflow.qloss_ph3,digits=1)

    sort!(lineflow,[:from,:to])
    
    cflow = select(lineflow, :from, :to)
    cflow = [cflow DataFrame(Matrix{Union{Float64, Nothing}}(nothing, nrow(cflow),12),[:amp_in_I_ph1, :deg_in_I_ph1, :amp_in_I_ph2, :deg_in_I_ph2, :amp_in_I_ph3, :deg_in_I_ph3, :amp_out_I_ph1, :deg_out_I_ph1, :amp_out_I_ph2, :deg_out_I_ph2, :amp_out_I_ph3, :deg_out_I_ph3, ])]
    for m = 1:nrow(lineflow)
        if lineflow[m,:phases] == "a"
            cflow[m,:amp_in_I_ph1] = round.(abs.(lineflow[m,:in_I_ph1]),digits=2)
            cflow[m,:deg_in_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph1])),digits=2)
            cflow[m,:amp_out_I_ph1] = round.(abs.(lineflow[m,:out_I_ph1]),digits=2)
            cflow[m,:deg_out_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph1])),digits=2)
        elseif lineflow[m,:phases] == "b"
            cflow[m,:amp_in_I_ph2] = round.(abs.(lineflow[m,:in_I_ph2]),digits=2)
            cflow[m,:deg_in_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph2])),digits=2)
            cflow[m,:amp_out_I_ph2] = round.(abs.(lineflow[m,:out_I_ph2]),digits=2)
            cflow[m,:deg_out_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph2])),digits=2)
        elseif lineflow[m,:phases] == "c"
            cflow[m,:amp_in_I_ph3] = round.(abs.(lineflow[m,:in_I_ph3]),digits=2)
            cflow[m,:deg_in_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph3])),digits=2)
            cflow[m,:amp_out_I_ph3] = round.(abs.(lineflow[m,:out_I_ph3]),digits=2)
            cflow[m,:deg_out_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph3])),digits=2)
        elseif lineflow[m,:phases] == "ab"
            cflow[m,:amp_in_I_ph1] = round.(abs.(lineflow[m,:in_I_ph1]),digits=2)
            cflow[m,:deg_in_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph1])),digits=2)
            cflow[m,:amp_out_I_ph1] = round.(abs.(lineflow[m,:out_I_ph1]),digits=2)
            cflow[m,:deg_out_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph1])),digits=2)
            cflow[m,:amp_in_I_ph2] = round.(abs.(lineflow[m,:in_I_ph2]),digits=2)
            cflow[m,:deg_in_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph2])),digits=2)
            cflow[m,:amp_out_I_ph2] = round.(abs.(lineflow[m,:out_I_ph2]),digits=2)
            cflow[m,:deg_out_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph2])),digits=2)
        elseif lineflow[m,:phases] == "ac"
            cflow[m,:amp_in_I_ph1] = round.(abs.(lineflow[m,:in_I_ph1]),digits=2)
            cflow[m,:deg_in_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph1])),digits=2)
            cflow[m,:amp_out_I_ph1] = round.(abs.(lineflow[m,:out_I_ph1]),digits=2)
            cflow[m,:deg_out_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph1])),digits=2)
            cflow[m,:amp_in_I_ph3] = round.(abs.(lineflow[m,:in_I_ph3]),digits=2)
            cflow[m,:deg_in_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph3])),digits=2)
            cflow[m,:amp_out_I_ph3] = round.(abs.(lineflow[m,:out_I_ph3]),digits=2)
            cflow[m,:deg_out_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph3])),digits=2)
        elseif lineflow[m,:phases] == "bc"
            cflow[m,:amp_in_I_ph2] = round.(abs.(lineflow[m,:in_I_ph2]),digits=2)
            cflow[m,:deg_in_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph2])),digits=2)
            cflow[m,:amp_out_I_ph2] = round.(abs.(lineflow[m,:out_I_ph2]),digits=2)
            cflow[m,:deg_out_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph2])),digits=2)
            cflow[m,:amp_in_I_ph3] = round.(abs.(lineflow[m,:in_I_ph3]),digits=2)
            cflow[m,:deg_in_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph3])),digits=2)
            cflow[m,:amp_out_I_ph3] = round.(abs.(lineflow[m,:out_I_ph3]),digits=2)
            cflow[m,:deg_out_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph3])),digits=2)
        elseif lineflow[m,:phases] == "abc"
            cflow[m,:amp_in_I_ph1] = round.(abs.(lineflow[m,:in_I_ph1]),digits=2)
            cflow[m,:deg_in_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph1])),digits=2)
            cflow[m,:amp_out_I_ph1] = round.(abs.(lineflow[m,:out_I_ph1]),digits=2)
            cflow[m,:deg_out_I_ph1] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph1])),digits=2)
            cflow[m,:amp_in_I_ph2] = round.(abs.(lineflow[m,:in_I_ph2]),digits=2)
            cflow[m,:deg_in_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph2])),digits=2)
            cflow[m,:amp_out_I_ph2] = round.(abs.(lineflow[m,:out_I_ph2]),digits=2)
            cflow[m,:deg_out_I_ph2] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph2])),digits=2)
            cflow[m,:amp_in_I_ph3] = round.(abs.(lineflow[m,:in_I_ph3]),digits=2)
            cflow[m,:deg_in_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:in_I_ph3])),digits=2)
            cflow[m,:amp_out_I_ph3] = round.(abs.(lineflow[m,:out_I_ph3]),digits=2)
            cflow[m,:deg_out_I_ph3] = round.(rad2deg.(angle.(lineflow[m,:out_I_ph3])),digits=2)
        end
    end

    pflow = select(lineflow, :from, :to)
    pflow = [pflow DataFrame(Matrix{Union{Float64, Nothing}}(nothing, nrow(pflow),12),[:kW_in_ph1, :kVAr_in_ph1, :kW_in_ph2, :kVAr_in_ph2, :kW_in_ph3, :kVAr_in_ph3, :kW_out_ph1, :kVAr_out_ph1, :kW_out_ph2, :kVAr_out_ph2, :kW_out_ph3, :kVAr_out_ph3])]
    for m = 1:nrow(lineflow)
        if lineflow[m,:phases] == "a"
            pflow[m,:kW_in_ph1] = round.(real.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kW_out_ph1] = round.(real.(lineflow[m,:out_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_in_ph1] = round.(imag.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_out_ph1] = round.(imag.(lineflow[m,:out_S_ph1])/1000,digits=3)
        elseif lineflow[m,:phases] == "b"
            pflow[m,:kW_in_ph2] = round.(real.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kW_out_ph2] = round.(real.(lineflow[m,:out_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_in_ph2] = round.(imag.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_out_ph2] = round.(imag.(lineflow[m,:out_S_ph2])/1000,digits=3)
        elseif lineflow[m,:phases] == "c"
            pflow[m,:kW_in_ph3] = round.(real.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kW_out_ph3] = round.(real.(lineflow[m,:out_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_in_ph3] = round.(imag.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_out_ph3] = round.(imag.(lineflow[m,:out_S_ph3])/1000,digits=3)
        elseif lineflow[m,:phases] == "ab"
            pflow[m,:kW_in_ph1] = round.(real.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kW_out_ph1] = round.(real.(lineflow[m,:out_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_in_ph1] = round.(imag.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_out_ph1] = round.(imag.(lineflow[m,:out_S_ph1])/1000,digits=3)
            pflow[m,:kW_in_ph2] = round.(real.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kW_out_ph2] = round.(real.(lineflow[m,:out_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_in_ph2] = round.(imag.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_out_ph2] = round.(imag.(lineflow[m,:out_S_ph2])/1000,digits=3)
        elseif lineflow[m,:phases] == "ac"
            pflow[m,:kW_in_ph1] = round.(real.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kW_out_ph1] = round.(real.(lineflow[m,:out_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_in_ph1] = round.(imag.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_out_ph1] = round.(imag.(lineflow[m,:out_S_ph1])/1000,digits=3)
            pflow[m,:kW_in_ph3] = round.(real.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kW_out_ph3] = round.(real.(lineflow[m,:out_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_in_ph3] = round.(imag.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_out_ph3] = round.(imag.(lineflow[m,:out_S_ph3])/1000,digits=3)
        elseif lineflow[m,:phases] == "bc"
            pflow[m,:kW_in_ph2] = round.(real.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kW_out_ph2] = round.(real.(lineflow[m,:out_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_in_ph2] = round.(imag.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_out_ph2] = round.(imag.(lineflow[m,:out_S_ph2])/1000,digits=3)
            pflow[m,:kW_in_ph3] = round.(real.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kW_out_ph3] = round.(real.(lineflow[m,:out_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_in_ph3] = round.(imag.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_out_ph3] = round.(imag.(lineflow[m,:out_S_ph3])/1000,digits=3)
        elseif lineflow[m,:phases] == "abc"
            pflow[m,:kW_in_ph2] = round.(real.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kW_out_ph2] = round.(real.(lineflow[m,:out_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_in_ph2] = round.(imag.(lineflow[m,:in_S_ph2])/1000,digits=3)
            pflow[m,:kVAr_out_ph2] = round.(imag.(lineflow[m,:out_S_ph2])/1000,digits=3)
            pflow[m,:kW_in_ph3] = round.(real.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kW_out_ph3] = round.(real.(lineflow[m,:out_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_in_ph3] = round.(imag.(lineflow[m,:in_S_ph3])/1000,digits=3)
            pflow[m,:kVAr_out_ph3] = round.(imag.(lineflow[m,:out_S_ph3])/1000,digits=3)
            pflow[m,:kW_in_ph1] = round.(real.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kW_out_ph1] = round.(real.(lineflow[m,:out_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_in_ph1] = round.(imag.(lineflow[m,:in_S_ph1])/1000,digits=3)
            pflow[m,:kVAr_out_ph1] = round.(imag.(lineflow[m,:out_S_ph1])/1000,digits=3)
        end
    end

    losses = select(lineflow, :from, :to, :ploss_totals, :qloss_totals)
    losses = [losses DataFrame(Matrix{Union{Float64, Nothing}}(nothing, nrow(losses),6),[:ploss_ph1, :qloss_ph1, :ploss_ph2, :qloss_ph2, :ploss_ph3, :qloss_ph3])]
    column_reorder = [:from, :to, :ploss_ph1, :qloss_ph1, :ploss_ph2, :qloss_ph2, :ploss_ph3, :qloss_ph3, :ploss_totals, :qloss_totals]
    losses = losses[!,column_reorder]
    select!(losses, column_reorder)
    for m = 1:nrow(lineflow)
        if lineflow[m,:phases] == "a"
            losses[m,:ploss_ph1] = round(lineflow[m,:ploss_ph1], digits=1)
            losses[m,:qloss_ph1] = round(lineflow[m,:qloss_ph1], digits=1)
        elseif lineflow[m,:phases] == "b"
            losses[m,:ploss_ph2] = round(lineflow[m,:ploss_ph2], digits=1)
            losses[m,:qloss_ph2] = round(lineflow[m,:qloss_ph2], digits=1)
        elseif lineflow[m,:phases] == "c"
            losses[m,:ploss_ph3] = round(lineflow[m,:ploss_ph3], digits=1)
            losses[m,:qloss_ph3] = round(lineflow[m,:qloss_ph3], digits=1)
        elseif lineflow[m,:phases] == "ab"
            losses[m,:ploss_ph1] = round(lineflow[m,:ploss_ph1], digits=1)
            losses[m,:qloss_ph1] = round(lineflow[m,:qloss_ph1], digits=1)
            losses[m,:ploss_ph2] = round(lineflow[m,:ploss_ph2], digits=1)
            losses[m,:qloss_ph2] = round(lineflow[m,:qloss_ph2], digits=1)
        elseif lineflow[m,:phases] == "ac"
            losses[m,:ploss_ph1] = round(lineflow[m,:ploss_ph1], digits=1)
            losses[m,:qloss_ph1] = round(lineflow[m,:qloss_ph1], digits=1)
            losses[m,:ploss_ph3] = round(lineflow[m,:ploss_ph3], digits=1)
            losses[m,:qloss_ph3] = round(lineflow[m,:qloss_ph3], digits=1)
        elseif lineflow[m,:phases] == "bc"
            losses[m,:ploss_ph2] = round(lineflow[m,:ploss_ph2], digits=1)
            losses[m,:qloss_ph2] = round(lineflow[m,:qloss_ph2], digits=1)
            losses[m,:ploss_ph3] = round(lineflow[m,:ploss_ph3], digits=1)
            losses[m,:qloss_ph3] = round(lineflow[m,:qloss_ph3], digits=1)
        elseif lineflow[m,:phases] == "abc"
            losses[m,:ploss_ph1] = round(lineflow[m,:ploss_ph1], digits=1)
            losses[m,:qloss_ph1] = round(lineflow[m,:qloss_ph1], digits=1)
            losses[m,:ploss_ph2] = round(lineflow[m,:ploss_ph2], digits=1)
            losses[m,:qloss_ph2] = round(lineflow[m,:qloss_ph2], digits=1)
            losses[m,:ploss_ph3] = round(lineflow[m,:ploss_ph3], digits=1)
            losses[m,:qloss_ph3] = round(lineflow[m,:qloss_ph3], digits=1)
        end
    end

    total_input_power = select(pflow,[:from,:kW_in_ph1,:kW_in_ph2,:kW_in_ph3,:kVAr_in_ph1,:kVAr_in_ph2,:kVAr_in_ph3]) 
    total_input_power = filter(row -> row.from == substation[1,:bus], total_input_power)
    select!(total_input_power,Not(:from))
    total_input_power = round.(total_input_power, digits=3)

    total_plosses = round(sum(losses.ploss_totals)/1000,digits=3)
    total_qlosses = round(sum(losses.qloss_totals)/1000,digits=3)
    
    if has_distributed_load
        #filtering out auxiliar buses for voltage reports
        volts_phases = filter(row -> !(row.id in auxiliar_buses.busx), volts_phases)
        volts_pu = filter(row -> !(row.id in auxiliar_buses.busx), volts_pu)
        volts_lines = filter(row -> !(row.id in auxiliar_buses.busx), volts_lines)
        #sort!(volts_phases, :id)
        sort!(volts_lines, :id)

        #filtering out auxiliar lines for current report
        cflow_aux_in = select(cflow, :from, :to, :amp_in_I_ph1, :deg_in_I_ph1, :amp_in_I_ph2, :deg_in_I_ph2, :amp_in_I_ph3, :deg_in_I_ph3)
        cflow_aux_in = filter(row -> row.to in auxiliar_buses.busx, cflow_aux_in)
        rename!(cflow_aux_in, :to => :busx)
        cflow_aux_out = select(cflow, :from, :to, :amp_out_I_ph1, :deg_out_I_ph1, :amp_out_I_ph2, :deg_out_I_ph2, :amp_out_I_ph3, :deg_out_I_ph3)
        cflow_aux_out = filter(row -> row.from in auxiliar_buses.busx, cflow_aux_out)
        rename!(cflow_aux_out, :from => :busx )
        cflow_aux = innerjoin(cflow_aux_in, cflow_aux_out; on=:busx)
        cflow_aux = select(cflow_aux , Not(:busx))
        select!(cflow_aux, :from, :to, :amp_in_I_ph1, :deg_in_I_ph1, :amp_in_I_ph2, :deg_in_I_ph2, :amp_in_I_ph3, :deg_in_I_ph3, :amp_out_I_ph1,  :deg_out_I_ph1, :amp_out_I_ph2, :deg_out_I_ph2, :amp_out_I_ph3, :deg_out_I_ph3)  
        cflow = filter(row -> !(row.to in auxiliar_buses.busx), cflow)
        cflow = filter(row -> !(row.from in auxiliar_buses.busx), cflow)
        append!(cflow,cflow_aux)
        sort!(cflow, [:from, :to])

        #filtering out auxiliar lines for power flow report
        pflow_aux_in = select(pflow, :from,  :to,  :kW_in_ph1,  :kVAr_in_ph1,  :kW_in_ph2,  :kVAr_in_ph2,  :kW_in_ph3,  :kVAr_in_ph3)
        pflow_aux_in = filter(row -> row.to in auxiliar_buses.busx, pflow_aux_in)
        rename!(pflow_aux_in, :to => :busx)
        pflow_aux_out = select(pflow, :from,  :to,  :kW_out_ph1,  :kVAr_out_ph1,  :kW_out_ph2,  :kVAr_out_ph2,  :kW_out_ph3,  :kVAr_out_ph3)
        pflow_aux_out = filter(row -> row.from in auxiliar_buses.busx, pflow_aux_out)
        rename!(pflow_aux_out, :from => :busx)
        pflow_aux = innerjoin(pflow_aux_in, pflow_aux_out; on=:busx)
        pflow_aux = select(pflow_aux , Not(:busx))
        select!(pflow_aux, :from,  :to,  :kW_in_ph1,  :kVAr_in_ph1,  :kW_in_ph2,  :kVAr_in_ph2,  :kW_in_ph3,  :kVAr_in_ph3,  :kW_out_ph1,  :kVAr_out_ph1,  :kW_out_ph2,  :kVAr_out_ph2,  :kW_out_ph3,  :kVAr_out_ph3)
        pflow = filter(row -> !(row.to in auxiliar_buses.busx), pflow)
        pflow = filter(row -> !(row.from in auxiliar_buses.busx), pflow)
        append!(pflow,pflow_aux)
        sort!(pflow, [:from, :to])

        #filtering out auxiliar lines for losses report
        aux_losses_1 = filter(row -> row.from in auxiliar_buses.busx || row.to in auxiliar_buses.busx, losses)
        losses = filter(row -> !(row.to in auxiliar_buses.busx || row.from in auxiliar_buses.busx), losses)
        aux_losses_2 = similar(aux_losses_1,0)
        for m = 1:nrow(aux_losses_1)
            for n = 1:nrow(aux_losses_1)
                if aux_losses_1[m,:to] == aux_losses_1[n,:from]
                    phases = filter(row -> row.busx == aux_losses_1[m,:to], auxiliar_buses)
                    if !(nrow(phases) == 0)
                        phases = phases[1,:phases]
                        if phases == "a"
                            push!(aux_losses_2, [aux_losses_1[m,:from], aux_losses_1[n,:to], 
                            round(aux_losses_1[m,:ploss_ph1] + aux_losses_1[n,:ploss_ph1],digits=1),
                            round(aux_losses_1[m,:qloss_ph1] + aux_losses_1[n,:qloss_ph1],digits=1),
                            0,
                            0,
                            0,
                            0,
                            round(aux_losses_1[m,:ploss_totals] + aux_losses_1[n,:ploss_totals],digits=1),
                            round(aux_losses_1[m,:qloss_totals] + aux_losses_1[n,:qloss_totals],digits=1)])
                        elseif phases == "b"
                            push!(aux_losses_2, [aux_losses_1[m,:from], aux_losses_1[n,:to], 
                            0,
                            0,
                            round(aux_losses_1[m,:ploss_ph2] + aux_losses_1[n,:ploss_ph2],digits=1),
                            round(aux_losses_1[m,:qloss_ph2] + aux_losses_1[n,:qloss_ph2],digits=1),
                            0,
                            0,
                            round(aux_losses_1[m,:ploss_totals] + aux_losses_1[n,:ploss_totals],digits=1),
                            round(aux_losses_1[m,:qloss_totals] + aux_losses_1[n,:qloss_totals],digits=1)])
                        elseif phases == "c"
                            push!(aux_losses_2, [aux_losses_1[m,:from], aux_losses_1[n,:to], 
                            0,
                            0,
                            0,
                            0,
                            round(aux_losses_1[m,:ploss_ph3] + aux_losses_1[n,:ploss_ph3],digits=1),
                            round(aux_losses_1[m,:qloss_ph3] + aux_losses_1[n,:qloss_ph3],digits=1),
                            round(aux_losses_1[m,:ploss_totals] + aux_losses_1[n,:ploss_totals],digits=1),
                            round(aux_losses_1[m,:qloss_totals] + aux_losses_1[n,:qloss_totals],digits=1)])
                        elseif phases == "ab"
                            push!(aux_losses_2, [aux_losses_1[m,:from], aux_losses_1[n,:to], 
                            round(aux_losses_1[m,:ploss_ph1] + aux_losses_1[n,:ploss_ph1],digits=1),
                            round(aux_losses_1[m,:qloss_ph1] + aux_losses_1[n,:qloss_ph1],digits=1),
                            round(aux_losses_1[m,:ploss_ph2] + aux_losses_1[n,:ploss_ph2],digits=1),
                            round(aux_losses_1[m,:qloss_ph2] + aux_losses_1[n,:qloss_ph2],digits=1),
                            0,
                            0,
                            round(aux_losses_1[m,:ploss_totals] + aux_losses_1[n,:ploss_totals],digits=1),
                            round(aux_losses_1[m,:qloss_totals] + aux_losses_1[n,:qloss_totals],digits=1)])
                        elseif phases == "bc"
                            push!(aux_losses_2, [aux_losses_1[m,:from], aux_losses_1[n,:to], 
                            0,
                            0,
                            round(aux_losses_1[m,:ploss_ph2] + aux_losses_1[n,:ploss_ph2],digits=1),
                            round(aux_losses_1[m,:qloss_ph2] + aux_losses_1[n,:qloss_ph2],digits=1),
                            round(aux_losses_1[m,:ploss_ph3] + aux_losses_1[n,:ploss_ph3],digits=1),
                            round(aux_losses_1[m,:qloss_ph3] + aux_losses_1[n,:qloss_ph3],digits=1),
                            round(aux_losses_1[m,:ploss_totals] + aux_losses_1[n,:ploss_totals],digits=1),
                            round(aux_losses_1[m,:qloss_totals] + aux_losses_1[n,:qloss_totals],digits=1)])
                        elseif phases == "ac"
                            push!(aux_losses_2, [aux_losses_1[m,:from], aux_losses_1[n,:to], 
                            round(aux_losses_1[m,:ploss_ph1] + aux_losses_1[n,:ploss_ph1],digits=1),
                            round(aux_losses_1[m,:qloss_ph1] + aux_losses_1[n,:qloss_ph1],digits=1),
                            0,
                            0,
                            round(aux_losses_1[m,:ploss_ph3] + aux_losses_1[n,:ploss_ph3],digits=1),
                            round(aux_losses_1[m,:qloss_ph3] + aux_losses_1[n,:qloss_ph3],digits=1),
                            round(aux_losses_1[m,:ploss_totals] + aux_losses_1[n,:ploss_totals],digits=1),
                            round(aux_losses_1[m,:qloss_totals] + aux_losses_1[n,:qloss_totals],digits=1)])
                        elseif phases == "abc"
                            push!(aux_losses_2, [aux_losses_1[m,:from], aux_losses_1[n,:to], 
                            round(aux_losses_1[m,:ploss_ph1] + aux_losses_1[n,:ploss_ph1],digits=1),
                            round(aux_losses_1[m,:qloss_ph1] + aux_losses_1[n,:qloss_ph1],digits=1),
                            round(aux_losses_1[m,:ploss_ph2] + aux_losses_1[n,:ploss_ph2],digits=1),
                            round(aux_losses_1[m,:qloss_ph2] + aux_losses_1[n,:qloss_ph2],digits=1),
                            round(aux_losses_1[m,:ploss_ph3] + aux_losses_1[n,:ploss_ph3],digits=1),
                            round(aux_losses_1[m,:qloss_ph3] + aux_losses_1[n,:qloss_ph3],digits=1),
                            round(aux_losses_1[m,:ploss_totals] + aux_losses_1[n,:ploss_totals],digits=1),
                            round(aux_losses_1[m,:qloss_totals] + aux_losses_1[n,:qloss_totals],digits=1)])
                        end
                    end
                end
            end
        end
        append!(losses, aux_losses_2)
        sort!(losses, [:from, :to])
    end
    global generation_register
    if has_distributed_gen
        generation_register = select!(generation_register, Not(:max_diff))
        generation_register.kw_ph1 = round.(generation_register[!,:kw_ph1],digits=3)
        generation_register.kw_ph2 = round.(generation_register[!,:kw_ph2],digits=3)
        generation_register.kw_ph3 = round.(generation_register[!,:kw_ph3],digits=3)
        generation_register.kvar_ph1 = round.(generation_register[!,:kvar_ph1],digits=3)
        generation_register.kvar_ph2 = round.(generation_register[!,:kvar_ph2],digits=3)
        generation_register.kvar_ph3 = round.(generation_register[!,:kvar_ph3],digits=3)
    end

    if timestamp
        date = Dates.format(now(),"yyyymmdd-HHMM") 
        something.(volts_phases, missing) |> CSV.write(joinpath(output_dir,"sdpf_volts_phase-"*date*".csv"))
        something.(volts_pu, missing) |> CSV.write(joinpath(output_dir,"sdpf_volts_pu-"*date*".csv"))
        something.(volts_lines, missing) |> CSV.write(joinpath(output_dir,"sdpf_volts_line-"*date*".csv"))
        something.(cflow, missing) |> CSV.write(joinpath(output_dir,"sdpf_current_flow-"*date*".csv"))
        something.(pflow, missing) |> CSV.write(joinpath(output_dir,"sdpf_power_flow-"*date*".csv"))
        something.(total_input_power, missing) |> CSV.write(joinpath(output_dir,"sdpf_total_input_power-"*date*".csv"))
        something.(losses, missing) |> CSV.write(joinpath(output_dir,"sdpf_power_losses-"*date*".csv"))
        if has_distributed_gen
            something.(generation_register, missing) |> CSV.write(joinpath(output_dir,"sdpf_distributed_generation-"*date*".csv"))
        end   
    else
        something.(volts_phases, missing) |> CSV.write(joinpath(output_dir,"sdpf_volts_phase.csv"))
        something.(volts_pu, missing) |> CSV.write(joinpath(output_dir,"sdpf_volts_pu.csv"))
        something.(volts_lines, missing) |> CSV.write(joinpath(output_dir,"sdpf_volts_line.csv"))
        something.(cflow, missing) |> CSV.write(joinpath(output_dir,"sdpf_current_flow.csv"))
        something.(pflow, missing) |> CSV.write(joinpath(output_dir,"sdpf_power_flow.csv"))
        something.(total_input_power, missing) |> CSV.write(joinpath(output_dir,"sdpf_total_input_power.csv"))
        something.(losses, missing) |> CSV.write(joinpath(output_dir,"sdpf_power_losses.csv"))     
        if has_distributed_gen
            something.(generation_register, missing) |> CSV.write(joinpath(output_dir,"sdpf_distributed_generation.csv"))
        end   
    end
        
    if display_summary
        println("maximum voltage (pu): $(ext_v_pu[1,:max]) at bus $(ext_v_pu[1,:bus_max])")
        println("minimum voltage (pu): $(ext_v_pu[1,:min]) at bus $(ext_v_pu[1,:bus_min])")
        println("Total Input Active Power:  $(round(total_input_power[1,:kW_in_ph1]+total_input_power[1,:kW_in_ph2]+total_input_power[1,:kW_in_ph3],digits=3)) kW")
        println("Total Input Reactive Power:  $(round(total_input_power[1,:kVAr_in_ph1]+total_input_power[1,:kVAr_in_ph2]+total_input_power[1,:kVAr_in_ph3],digits=3)) kVAr") 
        println("Total Active Power Losses:  $(total_plosses) kW")
        println("Total Reactive Power Losses:  $(total_qlosses) kVAr \n")
        if has_distributed_gen
            println("Distributed Generation: $(generation_register) \n")
        end
    end
    print("Results in $(output_dir)")
    
end