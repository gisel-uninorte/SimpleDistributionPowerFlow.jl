using Test, SimpleDistributionPowerFlow

#input directory validation
@test powerflow(input="non_existent_directory") == "Execution aborted, non_existent_directory is not a valid directory"
@test gridtopology(input="non_existent_directory") == "Execution aborted, non_existent_directory is not a valid directory"