# This file is part of SimpleDistributionPowerFlow.jl package
# It is MIT licensed
# Copyright (c) 2022 Gustavo Espitia, Cesar Orozco, Maria Calle, Universidad del Norte
# Terms of license are in https://github.com/gisel-uninorte/SimpleDistributionPowerFlow.jl/blob/main/LICENSE

using Test, SimpleDistributionPowerFlow

#input directory validation
@test powerflow(input="non_existent_directory") == "Execution aborted, non_existent_directory is not a valid directory"
@test gridtopology(input="non_existent_directory") == "Execution aborted, non_existent_directory is not a valid directory"