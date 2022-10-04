
function forward_backward_sweep(tolerance,max_iterations)
    max_error = 1
    iter_number = 0
    err_msg =""
    while max_error > tolerance
        iter_number += 1
        
        forwardsweep()
        backwardsweep()

        #global working_buses
        substation_phase_voltages = [last(working_buses).v_ph1; last(working_buses).v_ph2; last(working_buses).v_ph3]
        substation_line_voltages = D*substation_phase_voltages

        global ELL
        substation_voltage_error_1 = abs((abs(ELL[1]) - abs(substation_line_voltages[1]))/abs(ELL[1]))
        substation_voltage_error_2 = abs((abs(ELL[2]) - abs(substation_line_voltages[2]))/abs(ELL[2]))
        substation_voltage_error_3 = abs((abs(ELL[3]) - abs(substation_line_voltages[3]))/abs(ELL[3]))

        max_error = max(substation_voltage_error_1,substation_voltage_error_2,substation_voltage_error_3)

        #println("FBS iteration = $(iter_number)")
        #println("FBS max_error = $(max_error)")


        if iter_number == max_iterations
            err_msg = "Program halted, maximun number of forward-backward iteration reached ($(max_iterations))"
            break
        end
    end
    return err_msg,iter_number
end

function forwardsweep()
    A = Complex{Float64}[0 0 0; 0 0 0; 0 0 0]
    B = Complex{Float64}[0 0 0; 0 0 0; 0 0 0]

    #Asignacion de tensiones nominales al nodo inicial
    for n = 1:nrow(working_buses)
        if working_buses[n,:type]== 1 #Nodo inicial
            working_buses[n,:v_ph1] = ELN[1,1]
            working_buses[n,:v_ph2] = ELN[2,1]
            working_buses[n,:v_ph3] = ELN[3,1]
            working_buses[n,:process] = 1
        end
    end

    #Calcula las tensiones de los nodos siguientes
    for n = nrow(working_buses):-1:1
        for m = 1:nrow(gen_lines_mat)
            if gen_lines_mat[m,:bus1] == working_buses[n,:id]
               for n2 = nrow(working_buses):-1:1
                    if working_buses[n2,:id] == gen_lines_mat[m,:bus2]
                            A[1,1] = gen_lines_mat[m,:A_1_1]
                            A[1,2] = gen_lines_mat[m,:A_1_2]
                            A[1,3] = gen_lines_mat[m,:A_1_3]
                            A[2,1] = gen_lines_mat[m,:A_2_1]
                            A[2,2] = gen_lines_mat[m,:A_2_2]
                            A[2,3] = gen_lines_mat[m,:A_2_3]
                            A[3,1] = gen_lines_mat[m,:A_3_1]
                            A[3,2] = gen_lines_mat[m,:A_3_2]
                            A[3,3] = gen_lines_mat[m,:A_3_3]

                            B[1,1] = gen_lines_mat[m,:B_1_1]
                            B[1,2] = gen_lines_mat[m,:B_1_2]
                            B[1,3] = gen_lines_mat[m,:B_1_3]
                            B[2,1] = gen_lines_mat[m,:B_2_1]
                            B[2,2] = gen_lines_mat[m,:B_2_2]
                            B[2,3] = gen_lines_mat[m,:B_2_3]
                            B[3,1] = gen_lines_mat[m,:B_3_1]
                            B[3,2] = gen_lines_mat[m,:B_3_2]
                            B[3,3] = gen_lines_mat[m,:B_3_3]

                            Vbus1[1,1] = working_buses[n,:v_ph1]
                            Vbus1[2,1] = working_buses[n,:v_ph2]
                            Vbus1[3,1] = working_buses[n,:v_ph3]

                            Ibus2[1,1] = working_buses[n2,:ibus_1]
                            Ibus2[2,1] = working_buses[n2,:ibus_2]
                            Ibus2[3,1] = working_buses[n2,:ibus_3]

                            Vbus2 = A*Vbus1 - B*Ibus2 #tension nodo b del segmento de linea

                            #guardando las tensiones de nodos
                            working_buses[n2,:v_ph1] = Vbus2[1,1]
                            working_buses[n2,:v_ph2] = Vbus2[2,1]
                            working_buses[n2,:v_ph3] = Vbus2[3,1]
                            working_buses[n2,:process] = 1
                    end
                end
            end
        end
    end
end

function backwardsweep()
    #Global variables
    global Iline
    global Iphase
    global working_buses
    global Vbus2
    global Ibus2
    global Vbus1
    global Ibus1


    a = Complex{Float64}[0 0 0; 0 0 0; 0 0 0]
    b = Complex{Float64}[0 0 0; 0 0 0; 0 0 0]
    c = Complex{Float64}[0 0 0; 0 0 0; 0 0 0]
    d = Complex{Float64}[0 0 0; 0 0 0; 0 0 0]

    Iline = Complex{Float64}[0;0;0]
    Iphase =  Complex{Float64}[0;0;0]
    DL = [1 0 -1; -1 1 0; 0 -1 1]

    #establece las corrientes en cero
    working_buses[:,:ibus_1] .= 0
    working_buses[:,:ibus_2] .= 0
    working_buses[:,:ibus_3] .= 0

    #Calculo de las corrientes propias de los nodos finales
    for n = 1:nrow(working_buses)
        if working_buses[n,:type] == 5
            for k = 1:nrow(loads)
                if loads[k,:bus] == working_buses[n,:id]
                    if loads[k,:conn] == "Y" #Estrella
                        if loads[k,:type] == "PQ" || loads[k,:type] == "WPQ" || loads[k,:type] == "PQV" || loads[k,:type] == "PI"
                            working_buses[n,:ibus_1] += conj(loads[k,:ph_1]./working_buses[n,:v_ph1])
                            working_buses[n,:ibus_2] += conj(loads[k,:ph_2]./working_buses[n,:v_ph2])
                            working_buses[n,:ibus_3] += conj(loads[k,:ph_3]./working_buses[n,:v_ph3])
                        end
                        if loads[k,:type] == "Z" #Zcte
                            if !(loads[k,:k_1] == 0)
                                working_buses[n,:ibus_1] +=  working_buses[n,:v_ph1]./loads[k,:k_1]
                            end
                            if !(loads[k,:k_2] == 0)
                                working_buses[n,:ibus_2] += working_buses[n,:v_ph2]./loads[k,:k_2]
                            end
                            if !(loads[k,:k_3] == 0)
                                working_buses[n,:ibus_3] += working_buses[n,:v_ph3]./loads[k,:k_3]
                            end
                        end
                        if loads[k,:type] == "I" #Icte
                            working_buses[n,:ibus_1] +=  abs(loads[k,:k_1])*exp((angle(working_buses[n,:v_ph1])-angle(loads[k,:ph_1]))im)
                            working_buses[n,:ibus_2] += abs(loads[k,:k_2])*exp((angle(working_buses[n,:v_ph2])-angle(loads[k,:ph_2]))im)
                            working_buses[n,:ibus_3] += abs(loads[k,:k_3])*exp((angle(working_buses[n,:v_ph3])-angle(loads[k,:ph_3]))im)
                        end
                    end
                    if loads[k,:conn] == "D" #Delta
                        if loads[k,:type] == "PQ" || loads[k,:type] == "WPQ" || loads[k,:type] == "PQV" || loads[k,:type] == "PI"
                            Iline[1,1] = conj(loads[k,:ph_1]/(working_buses[n,:v_ph1]-working_buses[n,:v_ph2]))
                            Iline[2,1] = conj(loads[k,:ph_2]/(working_buses[n,:v_ph2]-working_buses[n,:v_ph3]))
                            Iline[3,1] = conj(loads[k,:ph_3]/(working_buses[n,:v_ph3]-working_buses[n,:v_ph1]))
                        end
                        if loads[k,:type] == "Z" #Zcte
                            if !(loads[k,:k_1] == 0)
                                Iline[1,1] = (working_buses[n,:v_ph1]-working_buses[n,:v_ph2])./loads[k,:k_1]
                            end
                            if !(loads[k,:k_2] == 0)
                                Iline[2,1] = (working_buses[n,:v_ph2]-working_buses[n,:v_ph3])/loads[k,:k_2]
                            end
                            if !(loads[k,:k_3] == 0)
                                Iline[3,1] = (working_buses[n,:v_ph3]-working_buses[n,:v_ph1])./loads[k,:k_3]
                            end
                        end
                        if loads[k,:type] == "I" #Icte
                            Iline[1,1] = abs(loads[k,:k_1])exp((angle(working_buses[n,:v_ph1]-working_buses[n,:v_ph2])-angle(loads[k,:ph_1]))im)
                            Iline[2,1] = abs(loads[k,:k_2])exp((angle(working_buses[n,:v_ph2]-working_buses[n,:v_ph3])-angle(loads[k,:ph_2]))im)
                            Iline[3,1] = abs(loads[k,:k_3])exp((angle(working_buses[n,:v_ph3]-working_buses[n,:v_ph1])-angle(loads[k,:ph_3]))im)
                        end
                        Iphase = DL*Iline; #Kersting Eq. 9.15
                        working_buses[n,:ibus_1] +=  Iphase[1,1]
                        working_buses[n,:ibus_2] += Iphase[2,1]
                        working_buses[n,:ibus_3] += Iphase[3,1]
                    end
                end
            end
            working_buses[n,:process] = 2
        end
    end
    #Calcula las tensiones y corrientes de los nodos siguientes
    for n = 1:nrow(working_buses)
        if !(working_buses[n,:type] == 5)
            for m = 1:nrow(gen_lines_mat)
                if gen_lines_mat[m,:bus1] == working_buses[n,:id]
                    for n2 = 1:nrow(working_buses)
                        if working_buses[n2,:id] == gen_lines_mat[m,:bus2]
                            a[1,1] = gen_lines_mat[m,:a_1_1]
                            a[1,2] = gen_lines_mat[m,:a_1_2]
                            a[1,3] = gen_lines_mat[m,:a_1_3]
                            a[2,1] = gen_lines_mat[m,:a_2_1]
                            a[2,2] = gen_lines_mat[m,:a_2_2]
                            a[2,3] = gen_lines_mat[m,:a_2_3]
                            a[3,1] = gen_lines_mat[m,:a_3_1]
                            a[3,2] = gen_lines_mat[m,:a_3_2]
                            a[3,3] = gen_lines_mat[m,:a_3_3]

                            b[1,1] = gen_lines_mat[m,:b_1_1]
                            b[1,2] = gen_lines_mat[m,:b_1_2]
                            b[1,3] = gen_lines_mat[m,:b_1_3]
                            b[2,1] = gen_lines_mat[m,:b_2_1]
                            b[2,2] = gen_lines_mat[m,:b_2_2]
                            b[2,3] = gen_lines_mat[m,:b_2_3]
                            b[3,1] = gen_lines_mat[m,:b_3_1]
                            b[3,2] = gen_lines_mat[m,:b_3_2]
                            b[3,3] = gen_lines_mat[m,:b_3_3]

                            c[1,1] = gen_lines_mat[m,:c_1_1]
                            c[1,2] = gen_lines_mat[m,:c_1_2]
                            c[1,3] = gen_lines_mat[m,:c_1_3]
                            c[2,1] = gen_lines_mat[m,:c_2_1]
                            c[2,2] = gen_lines_mat[m,:c_2_2]
                            c[2,3] = gen_lines_mat[m,:c_2_3]
                            c[3,1] = gen_lines_mat[m,:c_3_1]
                            c[3,2] = gen_lines_mat[m,:c_3_2]
                            c[3,3] = gen_lines_mat[m,:c_3_3]

                            d[1,1] = gen_lines_mat[m,:d_1_1]
                            d[1,2] = gen_lines_mat[m,:d_1_2]
                            d[1,3] = gen_lines_mat[m,:d_1_3]
                            d[2,1] = gen_lines_mat[m,:d_2_1]
                            d[2,2] = gen_lines_mat[m,:d_2_2]
                            d[2,3] = gen_lines_mat[m,:d_2_3]
                            d[3,1] = gen_lines_mat[m,:d_3_1]
                            d[3,2] = gen_lines_mat[m,:d_3_2]
                            d[3,3] = gen_lines_mat[m,:d_3_3]
                            
                            Vbus2 = [working_buses[n2,:v_ph1]; working_buses[n2,:v_ph2]; working_buses[n2,:v_ph3]]
                            Ibus2 = [working_buses[n2,:ibus_1]; working_buses[n2,:ibus_2]; working_buses[n2,:ibus_3]]            

                            Vbus1 = a*Vbus2 + b*Ibus2 #tension nodo a del segmento de linea
                            Ibus1 = c*Vbus2 + d*Ibus2 #corriente entre el nodo a y el b

                            #guardando las tensiones de nodos
                            working_buses[n,:v_ph1] = Vbus1[1,1]
                            working_buses[n,:v_ph2] = Vbus1[2,1]
                            working_buses[n,:v_ph3] = Vbus1[3,1]

                            #sumando corrientes de linea en los nodos
                            working_buses[n,:ibus_1] +=  Ibus1[1,1]
                            working_buses[n,:ibus_2] += Ibus1[2,1]
                            working_buses[n,:ibus_3] += Ibus1[3,1]

                            #guardando las corrientes de linea
                            lines[m,:ibus1_1] =  Ibus1[1,1]
                            lines[m,:ibus1_2] =  Ibus1[2,1]
                            lines[m,:ibus1_3] =  Ibus1[3,1]

                            working_buses[n,:process] = 2
                        end
                    end
                end
            end
            #sumar corrientes propias de los nodos
            for k = 1:nrow(loads)
                if loads[k,:bus] == working_buses[n,:id]
                    if loads[k,:conn] == "Y" #Estrella_nominal
                        if loads[k,:type] == "PQ" || loads[k,:type] == "WPQ" || loads[k,:type] == "PQV" || loads[k,:type] == "PI"
                            working_buses[n,:ibus_1] +=  conj(loads[k,:ph_1]./working_buses[n,:v_ph1])
                            working_buses[n,:ibus_2] += conj(loads[k,:ph_2]./working_buses[n,:v_ph2])
                            working_buses[n,:ibus_3] += conj(loads[k,:ph_3]./working_buses[n,:v_ph3])
                        end
                        if loads[k,:type] == "Z" #Zcte
                            if !(loads[k,:k_1] == 0)
                                working_buses[n,:ibus_1] +=  working_buses[n,:v_ph1]./loads[k,:k_1]
                            end
                            if !(loads[k,:k_2] == 0)
                                working_buses[n,:ibus_2] += working_buses[n,:v_ph2]./loads[k,:k_2]
                            end
                            if !(loads[k,:k_3] == 0)
                                working_buses[n,:ibus_3] += working_buses[n,:v_ph3]./loads[k,:k_3]
                            end
                        end
                        if loads[k,:type] == "I" #Icte
                            working_buses[n,:ibus_1] +=  abs(loads[k,:k_1])exp((angle(working_buses[n,:v_ph1])-angle(loads[k,:ph_1]))im)
                            working_buses[n,:ibus_2] += abs(loads[k,:k_2])exp((angle(working_buses[n,:v_ph2])-angle(loads[k,:ph_2]))im)
                            working_buses[n,:ibus_3] += abs(loads[k,:k_3])exp((angle(working_buses[n,:v_ph3])-angle(loads[k,:ph_3]))im)
                        end
                    end
                    if loads[k,:conn] == "D" #Delta
                        if loads[k,:type] == "PQ" || loads[k,:type] == "WPQ" || loads[k,:type] == "PQV" || loads[k,:type] == "PI"
                            Iline[1,1] = conj(loads[k,:ph_1]/(working_buses[n,:v_ph1]-working_buses[n,:v_ph2]))
                            Iline[2,1] = conj(loads[k,:ph_2]/(working_buses[n,:v_ph2]-working_buses[n,:v_ph3]))
                            Iline[3,1] = conj(loads[k,:ph_3]/(working_buses[n,:v_ph3]-working_buses[n,:v_ph1]))
                        end
                        if loads[k,:type] == "Z" #Zcte
                            if !(loads[k,:k_1] == 0)
                                Iline[1,1] = (working_buses[n,:v_ph1]-working_buses[n,:v_ph2])./loads[k,:k_1]
                            end
                            if !(loads[k,:k_2] == 0)
                                Iline[2,1] = (working_buses[n,:v_ph2]-working_buses[n,:v_ph3])./loads[k,:k_2]
                            end
                            if !(loads[k,:k_3] == 0)
                                Iline[3,1] = (working_buses[n,:v_ph3]-working_buses[n,:v_ph1])./loads[k,:k_3]
                            end
                        end
                        if loads[k,:type] == "I" #Icte
                            Iline[1,1] = abs(loads[k,:k_1])exp((angle(working_buses[n,:v_ph1]-working_buses[n,:v_ph2])-angle(loads[k,:ph_1]))im)
                            Iline[2,1] = abs(loads[k,:k_2])exp((angle(working_buses[n,:v_ph2]-working_buses[n,:v_ph3])-angle(loads[k,:ph_2]))im)
                            Iline[3,1] = abs(loads[k,:k_3])exp((angle(working_buses[n,:v_ph3]-working_buses[n,:v_ph1])-angle(loads[k,:ph_3]))im)
                        end
                        Iphase = DL*Iline #Kersting Eq. 9.15

                        working_buses[n,:ibus_1] +=  Iphase[1,1]
                        working_buses[n,:ibus_2] += Iphase[2,1]
                        working_buses[n,:ibus_3] += Iphase[3,1]
                    end
                end
            end
        end
    end
end