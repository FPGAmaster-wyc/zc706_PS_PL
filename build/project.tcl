# Product Version: Vivado v2019.2 (64-bit)

set projName zc706_board
set part xc7z045ffg900-2
set top soc_wrapper	

proc run_create {} {
    global projName
    global part
    global top

    set outputDir ./$projName			

    file mkdir $outputDir

    create_project $projName $outputDir -part $part -force		

    set projDir [get_property directory [current_project]]

    add_files -fileset [current_fileset] -force -norecurse {
        ../src/axi_hp_wr.v
        ../src/axi_lite_to_mm.v
        ../src/regfile.v
        ../src/soc_wrapper.v
        ../src/uart_rx.v
        ../src/uart_tx.v
        ../src/WIDTH8to32.v
        ../src/WIDTH32to8.v
    }
	


    add_files -fileset [current_fileset -constrset] -force -norecurse {
        ../src/top.xdc
    }
	
	update_ip_catalog

    source {../bd/soc.tcl}


    set_property top $top [current_fileset]
    set_property generic DEBUG=TRUE [current_fileset]

    set_property AUTO_INCREMENTAL_CHECKPOINT 1 [current_run -implementation]

    update_compile_order
}

proc run_build {} {         
    upgrade_ip [get_ips]

    # Synthesis
    launch_runs -jobs 12 [current_run -synthesis]
    wait_on_run [current_run -synthesis]

    # Implementation
    launch_runs -jobs 12 [current_run -implementation] -to_step write_bitstream
    wait_on_run [current_run -implementation]
}