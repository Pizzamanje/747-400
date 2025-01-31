--[[
*****************************************************************************************
* Program Script Name	:	B747.40.engines
* Author Name			:	Jim Gregory
*
*   Revisions:
*   -- DATE --	--- REV NO ---		--- DESCRIPTION ---
*   2016-04-26	0.01a				Start of Dev
*
*
*
*
*****************************************************************************************
*        COPYRIGHT � 2016 JIM GREGORY / LAMINAR RESEARCH - ALL RIGHTS RESERVED	        *
*****************************************************************************************
--]]


--*************************************************************************************--
--** 					              XLUA GLOBALS              				     **--
--*************************************************************************************--

--[[

SIM_PERIOD - this contains the duration of the current frame in seconds (so it is alway a
fraction).  Use this to normalize rates,  e.g. to add 3 units of fuel per second in a
per-frame callback you’d do fuel = fuel + 3 * SIM_PERIOD.

IN_REPLAY - evaluates to 0 if replay is off, 1 if replay mode is on

--]]


--*************************************************************************************--
--** 					               CONSTANTS                    				 **--
--*************************************************************************************--

--NUM_THRUST_LEVERS = 5




--*************************************************************************************--
--** 					            GLOBAL VARIABLES                				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 					            LOCAL VARIABLES                 				 **--
--*************************************************************************************--
function deferred_command(name,desc,realFunc)
	return replace_command(name,realFunc)
end
--replace deferred_dataref
function deferred_dataref(name,nilType,callFunction)
  if callFunction~=nil then
    print("WARN:" .. name .. " is trying to wrap a function to a dataref -> use xlua")
    end
    return find_dataref(name)
end
local B747_hold_rev_on_engine		= {0, 0, 0, 0}
local B747_hold_rev_on_all			= 0

--local B747_igniter_status = {0, 0, 0, 0}
local B747_ignition_startup_flag = {1, 1, 1, 1}

math.randomseed(os.time())
local B747_eng1oilStart = math.random(28, 31) * 1.18
local B747_eng2oilStart = math.random(28, 31) * 1.18
local B747_eng3oilStart = math.random(28, 31) * 1.18
local B747_eng4oilStart = math.random(28, 31) * 1.18
local B747_eng1startupOilTxfr = math.random(7, 11) + (math.random()*0.10)
local B747_eng2startupOilTxfr = math.random(7, 11) + (math.random()*0.10)
local B747_eng3startupOilTxfr = math.random(7, 11) + (math.random()*0.10)
local B747_eng4startupOilTxfr = math.random(7, 11) + (math.random()*0.10)

local B747_eng1oilPressVariance = math.random(1, 6) + (math.random()*0.10)
local B747_eng2oilPressVariance = math.random(1, 6) + (math.random()*0.10)
local B747_eng3oilPressVariance = math.random(1, 6) + (math.random()*0.10)
local B747_eng4oilPressVariance = math.random(1, 6) + (math.random()*0.10)

local B747_eng1oilTempVariance = math.random(1, 10) + (math.random()*0.10)
local B747_eng2oilTempVariance = math.random(1, 10) + (math.random()*0.10)
local B747_eng3oilTempVariance = math.random(1, 10) + (math.random()*0.10)
local B747_eng4oilTempVariance = math.random(1, 10) + (math.random()*0.10)

local B747_ref_thr_limit_mode = "NONE"
local B747_ref_thr_limit = {
    ["NONE"]    = 0.00,
    ["TO"]      = 1.40,
    ["TO1"]     = 1.00,
    ["TO2"]     = 1.00,
    ["D-TO"]    = 1.00,
    ["D-TO1"]   = 1.00,
    ["D-TO2"]   = 1.00,
    ["CLB"]     = 1.00,
    ["CLB1"]    = 1.00,
    ["CLB2"]    = 1.00,
    ["CRZ"]     = 1.00,
    ["CON"]     = 1.00,
    ["GA"]      = 1.00
}


--*************************************************************************************--
--** 				              FIND X-PLANE DATAREFS              		    	 **--
--*************************************************************************************--

simDR_startup_running           = find_dataref("sim/operation/prefs/startup_running")
simDR_all_wheels_on_ground      = find_dataref("sim/flightmodel/failures/onground_all")

simDR_thrust_rev_deploy_ratio   = find_dataref("sim/flightmodel2/engines/thrust_reverser_deploy_ratio")

simDR_autothrottle_on           = find_dataref("sim/cockpit2/autopilot/autothrottle_on")

simDR_prop_mode                 = find_dataref("sim/cockpit2/engine/actuators/prop_mode")

simDR_engine_throttle_jet       = find_dataref("sim/cockpit2/engine/actuators/throttle_jet_rev_ratio")
simDR_engine_throttle_jet_all   = find_dataref("sim/cockpit2/engine/actuators/throttle_jet_rev_ratio_all")

simDR_hydraulic_sys_press_01    = find_dataref("sim/operation/failures/hydraulic_pressure_ratio")
simDR_hydraulic_sys_press_02    = find_dataref("sim/operation/failures/hydraulic_pressure_ratio2")

simDR_engine_nacelle_heat_on    = find_dataref("sim/cockpit2/ice/ice_inlet_heat_on_per_engine")
simDR_engine_starter_status     = find_dataref("sim/cockpit2/engine/actuators/ignition_key")				-- CHANGE TO STARTER IS RUNNING  ??
simDR_engine_auto_ignite_on     = find_dataref("sim/cockpit2/engine/actuators/auto_ignite_on")
simDR_engine_igniter_on         = find_dataref("sim/cockpit2/annunciators/igniter_on")
simDR_engine_N1_pct             = find_dataref("sim/cockpit2/engine/indicators/N1_percent")
simDR_engine_N2_pct             = find_dataref("sim/cockpit2/engine/indicators/N2_percent")
simDR_engine_epr_ratio          = find_dataref("sim/cockpit2/engine/indicators/EPR_ratio")
simDR_engine_EGT_degC           = find_dataref("sim/cockpit2/engine/indicators/EGT_deg_C")
simDR_engine_fuel_mix_ratio     = find_dataref("sim/cockpit2/engine/actuators/mixture_ratio")
simDR_engine_oil_pressure       = find_dataref("sim/cockpit2/engine/indicators/oil_pressure_psi")
simDR_engine_oil_temp           = find_dataref("sim/cockpit2/engine/indicators/oil_temperature_deg_C")
simDR_engine_oil_qty_ratio      = find_dataref("sim/cockpit2/engine/indicators/oil_quantity_ratio")

simDR_flap_deploy_ratio         = find_dataref("sim/flightmodel2/controls/flap_handle_deploy_ratio")

simDR_engine_running            = find_dataref("sim/flightmodel/engine/ENGN_running")

simDR_thrust_rev_fail_01        = find_dataref("sim/operation/failures/rel_revers0")
simDR_thrust_rev_fail_02        = find_dataref("sim/operation/failures/rel_revers1")
simDR_thrust_rev_fail_03        = find_dataref("sim/operation/failures/rel_revers2")
simDR_thrust_rev_fail_04        = find_dataref("sim/operation/failures/rel_revers3")

simDR_autopilot_TOGA_vert_status = find_dataref("sim/cockpit2/autopilot/TOGA_status")





--*************************************************************************************--
--** 				              FIND CUSTOM DATAREFS             			    	 **--
--*************************************************************************************--

B747DR_button_switch_position               = find_dataref("laminar/B747/button_switch/position")
B747DR_toggle_switch_position               = find_dataref("laminar/B747/toggle_switch/position")

B747DR_fuel_control_toggle_switch_pos       = find_dataref("laminar/B747/fuel/fuel_control/toggle_sw_pos")

B747DR_bleedAir_engine1_start_valve_pos     = find_dataref("laminar/B747/air/engine1/bleed_start_valve_pos")
B747DR_bleedAir_engine2_start_valve_pos     = find_dataref("laminar/B747/air/engine2/bleed_start_valve_pos")
B747DR_bleedAir_engine3_start_valve_pos     = find_dataref("laminar/B747/air/engine3/bleed_start_valve_pos")
B747DR_bleedAir_engine4_start_valve_pos     = find_dataref("laminar/B747/air/engine4/bleed_start_valve_pos")

B747DR_engine01_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine01/ext_switch/pos_disch")
B747DR_engine02_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine02/ext_switch/pos_disch")
B747DR_engine03_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine03/ext_switch/pos_disch")
B747DR_engine04_fire_ext_switch_pos_disch   = find_dataref("laminar/B747/fire/engine04/ext_switch/pos_disch")

B747DR_CAS_caution_status                   = find_dataref("laminar/B747/CAS/caution_status")
B747DR_CAS_advisory_status                  = find_dataref("laminar/B747/CAS/advisory_status")
B747DR_CAS_memo_status                      = find_dataref("laminar/B747/CAS/memo_status")





--*************************************************************************************--
--** 				               FIND X-PLANE COMMANDS                   	    	 **--
--*************************************************************************************--

simCMD_igniter_on_1         = find_command("sim/igniters/igniter_contin_on_1")
simCMD_igniter_on_2         = find_command("sim/igniters/igniter_contin_on_2")
simCMD_igniter_on_3         = find_command("sim/igniters/igniter_contin_on_3")
simCMD_igniter_on_4         = find_command("sim/igniters/igniter_contin_on_4")

simCMD_igniter_off_1        = find_command("sim/igniters/igniter_contin_off_1")
simCMD_igniter_off_2        = find_command("sim/igniters/igniter_contin_off_2")
simCMD_igniter_off_3        = find_command("sim/igniters/igniter_contin_off_3")
simCMD_igniter_off_4        = find_command("sim/igniters/igniter_contin_off_4")

simCMD_starter_on_1         = find_command("sim/starters/engage_starter_1")
simCMD_starter_on_2         = find_command("sim/starters/engage_starter_2")
simCMD_starter_on_3         = find_command("sim/starters/engage_starter_3")
simCMD_starter_on_4         = find_command("sim/starters/engage_starter_4")

simCMD_starter_off_1        = find_command("sim/starters/shut_down_1")
simCMD_starter_off_2        = find_command("sim/starters/shut_down_2")
simCMD_starter_off_3        = find_command("sim/starters/shut_down_3")
simCMD_starter_off_4        = find_command("sim/starters/shut_down_4")






--*************************************************************************************--
--** 				               FIND CUSTOM COMMANDS              			     **--
--*************************************************************************************--

B747CMD_engine_start_switch1        = find_command("laminar/B747/toggle_switch/engine_start1")
B747CMD_engine_start_switch2        = find_command("laminar/B747/toggle_switch/engine_start2")
B747CMD_engine_start_switch3        = find_command("laminar/B747/toggle_switch/engine_start3")
B747CMD_engine_start_switch4        = find_command("laminar/B747/toggle_switch/engine_start4")

B747CMD_engine_start_switch1_off    = find_command("laminar/B747/toggle_switch/engine_start1_off")
B747CMD_engine_start_switch2_off    = find_command("laminar/B747/toggle_switch/engine_start2_off")
B747CMD_engine_start_switch3_off    = find_command("laminar/B747/toggle_switch/engine_start3_off")
B747CMD_engine_start_switch4_off    = find_command("laminar/B747/toggle_switch/engine_start4_off")





--*************************************************************************************--
--** 				       READ-WRITE CUSTOM DATAREF HANDLERS     	        	     **--
--*************************************************************************************--




--*************************************************************************************--
--** 				              CUSTOM COMMAND HANDLERS            			     **--
--*************************************************************************************--

function B747_thrust_rev_toggle_1_CMDhandler(phase, duration)
	if phase == 0 then
			
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS USER TOGGLING "REVERSE" MODE WHEN ANY THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
			
			if simDR_engine_throttle_jet[0] > 0.0 then									-- IS ENGINE 1 THROTTLE LEVER IN "THRUST" MODE
				-- FORCE  PROP MODE TO "NORMAL"
				simDR_prop_mode[0] = 1																									
				
			elseif simDR_engine_throttle_jet[0] < 0.0 then								-- IS ENGINE 1 THROTTLE LEVER IN "REFVERSE" MODE	
				-- FORCE  PROP MODE TO "REVERSE"										
				simDR_prop_mode[0] = 3																									
				
			else																		-- ENGINE 1 THROTTLE IS AT IDLE, OK TO TOGGLE PROP MODE FOR ALL ENGINES
				-- TOGGLE PROP MODE
				simDR_prop_mode[0] = 4 - simDR_prop_mode[0]															
			end
				    	
		end					
	end		
end	

function B747_thrust_rev_toggle_2_CMDhandler(phase, duration)
	if phase == 0 then
			
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS USER TOGGLING "REVERSE" MODE WHEN ENGINE 1 THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
			
			if simDR_engine_throttle_jet[1] > 0.0 then									-- IS ENGINE 2 THROTTLE LEVER IN "THRUST" MODE
				-- FORCE  PROP MODE TO "NORMAL"
				simDR_prop_mode[1] = 1																									
				
			elseif simDR_engine_throttle_jet[1] < 0.0 then								-- IS ENGINE 2 THROTTLE LEVER IN "REFVERSE" MODE	
				-- FORCE  PROP MODE TO "REVERSE"										
				simDR_prop_mode[1] = 3																									
				
			else																		-- ENGINE 2 THROTTLE IS AT IDLE, OK TO TOGGLE PROP MODE FOR ALL ENGINES
				-- TOGGLE PROP MODE
				simDR_prop_mode[1] = 4 - simDR_prop_mode[1]															
			end
				    	
		end					
	end		
end	

function B747_thrust_rev_toggle_3_CMDhandler(phase, duration)
	if phase == 0 then
			
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS USER TOGGLING "REVERSE" MODE WHEN ENGINE 2 THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
			
			if simDR_engine_throttle_jet[2] > 0.0 then									-- IS ENGINE 3 THROTTLE LEVER IN "THRUST" MODE
				-- FORCE  PROP MODE TO "NORMAL"
				simDR_prop_mode[2] = 1																									
				
			elseif simDR_engine_throttle_jet[2] < 0.0 then								-- IS ENGINE 3 THROTTLE LEVER IN "REFVERSE" MODE	
				-- FORCE  PROP MODE TO "REVERSE"										
				simDR_prop_mode[2] = 3																									
				
			else																		-- ENGINE 3 THROTTLE IS AT IDLE, OK TO TOGGLE PROP MODE FOR ALL ENGINES
				-- TOGGLE PROP MODE
				simDR_prop_mode[2] = 4 - simDR_prop_mode[2]															
			end
				    	
		end					
	end		
end

function B747_thrust_rev_toggle_4_CMDhandler(phase, duration)
	if phase == 0 then
			
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS USER TOGGLING "REVERSE" MODE WHEN ENGINE 3 THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
			
			if simDR_engine_throttle_jet[3] > 0.0 then									-- IS ENGINE 4 THROTTLE LEVER IN "THRUST" MODE
				-- FORCE  PROP MODE TO "NORMAL"
				simDR_prop_mode[3] = 1																									
				
			elseif simDR_engine_throttle_jet[3] < 0.0 then								-- IS ENGINE 4 THROTTLE LEVER IN "REFVERSE" MODE	
				-- FORCE  PROP MODE TO "REVERSE"										
				simDR_prop_mode[3] = 3																									
				
			else																		-- ENGINE 4 THROTTLE IS AT IDLE, OK TO TOGGLE PROP MODE FOR ALL ENGINES
				-- TOGGLE PROP MODE
				simDR_prop_mode[3] = 4 - simDR_prop_mode[1]															
			end
				    	
		end					
	end		
end

function B747_thrust_rev_toggle_all_CMDhandler(phase, duration)
	if phase == 0 then
		
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS USER TOGGLING "REVERSE" MODE WHEN ENGINE 4 THROTTLE LEVER IS NOT AT IDLE
		
		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
			
			if simDR_engine_throttle_jet_all > 0.0 then									-- IS ANY THROTTLE LEVER IN "THRUST" MODE
				-- FORCE  PROP MODE TO "NORMAL"
				simDR_prop_mode[0] = 1													
				simDR_prop_mode[1] = 1													
				simDR_prop_mode[2] = 1													
				simDR_prop_mode[3] = 1													
				
			elseif simDR_engine_throttle_jet_all < 0.0 then								-- IS ANY THROTTLE LEVER IN "REFVERSE" MODE	
				-- FORCE  PROP MODE TO "REVERSE"										
				simDR_prop_mode[0] = 3													
				simDR_prop_mode[1] = 3													
				simDR_prop_mode[2] = 3													
				simDR_prop_mode[3] = 3													
				
			else																		-- ALL THROTTLES ARE AT IDLE, OK TO TOGGLE PROP MODE FOR ALL ENGINES
				-- TOGGLE PROP MODE
				simDR_prop_mode[0] = 4 - simDR_prop_mode[0]								
				simDR_prop_mode[1] = 4 - simDR_prop_mode[1]								
				simDR_prop_mode[2] = 4 - simDR_prop_mode[2]								
				simDR_prop_mode[3] = 4 - simDR_prop_mode[3]								
			end	 
			   	
		end 	
	end	
end	






function B747_thrust_rev_hold_max_1_CMDhandler(phase, duration)

    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 1 THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
				
			if simDR_engine_throttle_jet[0] < 0.05										-- THRUST LEVER MUST BE IN IDLE POSITION
				--and simDR_engine_throttle_jet[0] > -0.05	
			then
				simDR_prop_mode[0] = 3														
				simDR_engine_throttle_jet[0] = -1.0
				B747_hold_rev_on_engine[0] = 1
			end
			
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[0] == 1 then
			simDR_prop_mode[0] = 1														
			simDR_engine_throttle_jet[0] = 0.0
			B747_hold_rev_on_engine[0] = 0
		end
					
    end
    
end

function B747_thrust_rev_hold_max_2_CMDhandler(phase, duration)

    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 2 THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
				
			if simDR_engine_throttle_jet[1] < 0.05										-- THRUST LEVER MUST BE IN IDLE POSITION
				--and simDR_engine_throttle_jet[1] > -0.05	
			then
				simDR_prop_mode[1] = 3														
				simDR_engine_throttle_jet[1] = -1.0
				B747_hold_rev_on_engine[1] = 1
			end
			
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[1] == 1 then
			simDR_prop_mode[1] = 1														
			simDR_engine_throttle_jet[1] = 0.0
			B747_hold_rev_on_engine[1] = 0
		end
					
    end
    
end

function B747_thrust_rev_hold_max_3_CMDhandler(phase, duration)

    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 3 THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
				
			if simDR_engine_throttle_jet[2] < 0.05										-- THRUST LEVER MUST BE IN IDLE POSITION
				--and simDR_engine_throttle_jet[2] > -0.05	
			then
				simDR_prop_mode[2] = 3														
				simDR_engine_throttle_jet[2] = -1.0
				B747_hold_rev_on_engine[2] = 1
			end
			
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[2] == 1 then
			simDR_prop_mode[2] = 1														
			simDR_engine_throttle_jet[2] = 0.0
			B747_hold_rev_on_engine[2] = 0
		end
					
    end
    
end

function B747_thrust_rev_hold_max_4_CMDhandler(phase, duration)
    
    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ENGINE 4 THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
				
			if simDR_engine_throttle_jet[3] < 0.05										-- THRUST LEVER MUST BE IN IDLE POSITION
				--and simDR_engine_throttle_jet[3] > -0.05	
			then
				simDR_prop_mode[3] = 3														
				simDR_engine_throttle_jet[3] = -1.0
				B747_hold_rev_on_engine[3] = 1
			end
			
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_engine[3] == 1 then
			simDR_prop_mode[3] = 1														
			simDR_engine_throttle_jet[3] = 0.0
			B747_hold_rev_on_engine[3] = 0
		end
					
    end
    
end

function B747_thrust_rev_hold_max_all_CMDhandler(phase, duration)
	
    if phase < 2 then
	    
		-- AIRCRAFT MUST BE ON THE GROUND
		-- PREVENTS "REVERSE" MODE WHEN ANY THROTTLE LEVER IS NOT AT IDLE

		if simDR_all_wheels_on_ground == 1 then											-- AIRCRAFT IS ON THE GRUOND
				
			if simDR_engine_throttle_jet_all <= 0.0										-- THRUST LEVERS MUST BE IN IDLE (OR REVERSE) POSITION
				--and simDR_engine_throttle_jet_all > -0.05	
			then
				simDR_prop_mode[0] = 3													
				simDR_prop_mode[1] = 3													
				simDR_prop_mode[2] = 3													
				simDR_prop_mode[3] = 3		
				simDR_engine_throttle_jet_all = -1.0
				B747_hold_rev_on_all = 1
			end
			
		end	
		
	end		
	
	if phase == 2 then
		
		if B747_hold_rev_on_all == 1 then
			simDR_prop_mode[0] = 1													
			simDR_prop_mode[1] = 1													
			simDR_prop_mode[2] = 1													
			simDR_prop_mode[3] = 1		
			simDR_engine_throttle_jet_all = 0.0
			B747_hold_rev_on_all = 0
		end
					
    end
    
end












function B747_engine_TOGA_power_CMDhandler(phase, duration) 				
	if phase == 0 then
        if B747DR_toggle_switch_position[29] == 1 then
            if simDR_autopilot_TOGA_vert_status == 2 then
	            if B747DR_engine_TOGA_mode == 0 then
                	simDR_engine_throttle_input[0] = 0.95
                	simDR_engine_throttle_input[1] = 0.95
                	simDR_engine_throttle_input[2] = 0.95
                	simDR_engine_throttle_input[3] = 0.95
					B747DR_engine_TOGA_mode = 1
				end	
            end
        end		
	end	
end





function B747_ai_engines_quick_start_CMDhandler(phase, duration)
    if phase == 0 then
	  	B747_set_engines_all_modes()
	  	B747_set_engines_CD()
	  	B747_set_engines_ER()
	  	B747_set_engines_all_modes2()
	end    	
end	





--*************************************************************************************--
--** 				        CREATE READ-ONLY CUSTOM DATAREFS               	         **--
--*************************************************************************************--

B747DR_thrust_mnp_show				= deferred_dataref("laminar/B747/engine/thrust_mnp_show", "array[4)")
B747DR_thrust_mnp_show_all			= deferred_dataref("laminar/B747/engine/thrust_mnp_show_all", "number")

B747DR_reverse_mnp_show				= deferred_dataref("laminar/B747/engine/rev_mnp_show", "array[4)")
B747DR_reverse_mnp_show_all			= deferred_dataref("laminar/B747/engine/rev_mnp_show_all", "number")

B747DR_engine_fuel_valve_pos        = deferred_dataref("laminar/B747/engines/fuel_valve_pos", "array[4)")
B747DR_EICAS2_fuel_on_ind_status    = deferred_dataref("laminar/B747/engines/fuel_on_indicator_status", "array[4)")
B747DR_EICAS2_oil_press_status      = deferred_dataref("laminar/B747/engines/EICAS2_oil_press_status", "array[4)")
B747DR_EICAS2_engine_vibration      = deferred_dataref("laminar/B747/engines/vibration", "array[4)")
B747DR_engine_oil_press_psi         = deferred_dataref("laminar/B747/engines/oil_press_psi", "array[4)")
B747DR_engine_oil_temp_degC         = deferred_dataref("laminar/B747/engines/oil_temp_degC", "array[4)")
B747DR_engine_oil_qty_liters        = deferred_dataref("laminar/B747/engines/oil_qty_liters", "array[4)")
B747DR_EPR_max_limit                = deferred_dataref("laminar/B747/engines/EPR/max_limit", "array[4)")
B747DR_EGT_amber_inhibit            = deferred_dataref("laminar/B747/engines/EGT/amber_inhibit", "array[4)")
B747DR_EGT_amber_on                 = deferred_dataref("laminar/B747/engines/EGT/amber_on", "array[4)")
B747DR_EGT_white_on                 = deferred_dataref("laminar/B747/engines/EGT/white_on", "array[4)")

B747DR_init_engines_CD              = deferred_dataref("laminar/B747/engines/init_CD", "number")

B747DR_engine_TOGA_mode             = deferred_dataref("laminar/B747/engines/TOGA_mode", "number")

B747DR_ref_thr_limit_mode           = deferred_dataref("laminar/B747/engines/ref_thr_limit_mode", "string")




--*************************************************************************************--
--** 				       CREATE READ-WRITE CUSTOM DATAREFS                         **--
--*************************************************************************************--



--*************************************************************************************--
--** 				              CREATE CUSTOM COMMANDS              			     **--
--*************************************************************************************--



--*************************************************************************************--
--** 				             REPLACE X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--

B747CMD_thrust_rev_toggle_1      	= replace_command("sim/engines/thrust_reverse_toggle_1", B747_thrust_rev_toggle_1_CMDhandler)
B747CMD_thrust_rev_toggle_2      	= replace_command("sim/engines/thrust_reverse_toggle_2", B747_thrust_rev_toggle_2_CMDhandler)
B747CMD_thrust_rev_toggle_3      	= replace_command("sim/engines/thrust_reverse_toggle_3", B747_thrust_rev_toggle_3_CMDhandler)
B747CMD_thrust_rev_toggle_4     	= replace_command("sim/engines/thrust_reverse_toggle_4", B747_thrust_rev_toggle_4_CMDhandler)

B747CMD_thrust_rev_toggle_all		= replace_command("sim/engines/thrust_reverse_toggle", B747_thrust_rev_toggle_all_CMDhandler)



B747CMD_thrust_rev_hold_1_max    	= replace_command("sim/engines/thrust_reverse_hold_1", B747_thrust_rev_hold_max_1_CMDhandler)
B747CMD_thrust_rev_hold_2_max    	= replace_command("sim/engines/thrust_reverse_hold_2", B747_thrust_rev_hold_max_2_CMDhandler)
B747CMD_thrust_rev_hold_3_max    	= replace_command("sim/engines/thrust_reverse_hold_3", B747_thrust_rev_hold_max_3_CMDhandler)
B747CMD_thrust_rev_hold_4_max    	= replace_command("sim/engines/thrust_reverse_hold_4", B747_thrust_rev_hold_max_4_CMDhandler)

B747CMD_thrust_rev_hold_max_all     = replace_command("sim/engines/thrust_reverse_hold", B747_thrust_rev_hold_max_all_CMDhandler)



B747CMD_TOGA_power					= replace_command("sim/engines/TOGA_power", B747_engine_TOGA_power_CMDhandler)		


-- AI
B747CMD_ai_engines_quick_start		= deferred_command("laminar/B747/ai/engines_quick_start", "number", B747_ai_engines_quick_start_CMDhandler)



--*************************************************************************************--
--** 				              WRAP X-PLANE COMMANDS                  	    	 **--
--*************************************************************************************--




--*************************************************************************************--
--** 					            OBJECT CONSTRUCTORS         		    		 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                   CREATE OBJECTS               				 **--
--*************************************************************************************--



--*************************************************************************************--
--** 				                  SYSTEM FUNCTIONS           	    			 **--
--*************************************************************************************--

----- TERNARY CONDITIONAL ---------------------------------------------------------------
function B747_ternary(condition, ifTrue, ifFalse)
    if condition then return ifTrue else return ifFalse end
end





----- RESCALE FLOAT AND CLAMP TO OUTER LIMITS -------------------------------------------
function B747_rescale(in1, out1, in2, out2, x)

    if x < in1 then return out1 end
    if x > in2 then return out2 end
    return out1 + (out2 - out1) * (x - in1) / (in2 - in1)

end











----- PROP MODE -------------------------------------------------------------------------
function B747_prop_mode()

    -- Mode 0 is feathered, 1 is normal, 2 is in beta, and reverse (prop or jet) is mode 3

    --simDR_prop_mode[0] = B747_ternary(((B747DR_thrust_rev_lever_pos[0] > 0.45) and (simDR_hydraulic_sys_press_01 > 1000.0)), 3, 1)
    --simDR_prop_mode[1] = B747_ternary(((B747DR_thrust_rev_lever_pos[1] > 0.45) and (simDR_hydraulic_sys_press_02 > 1000.0)), 3, 1)
    --simDR_prop_mode[2] = B747_ternary(((B747DR_thrust_rev_lever_pos[2] > 0.45) and (simDR_hydraulic_sys_press_02 > 1000.0)), 3, 1)
    --simDR_prop_mode[3] = B747_ternary(((B747DR_thrust_rev_lever_pos[3] > 0.45) and (simDR_hydraulic_sys_press_01 > 1000.0)), 3, 1)
    

    
    -- AIRCRAFT IS "ON THE GROUND" 
	if simDR_all_wheels_on_ground == 0 then		
	    
	    -- FORCE PROP MODE TO NORMAL MODE TO PREVENT USER 
	    -- ENGAGING "REVERSE MODE WHILE IN FLIGHT

	  	for i = 0, 3 do
		    simDR_prop_mode[0] = 1
		    simDR_prop_mode[1] = 1
		    simDR_prop_mode[2] = 1
		    simDR_prop_mode[3] = 1	
		end 		
		
	end
	
end	

			

	
function B747_set_tq_levers_mnp_show()
	
	
	-- THRUST LEVER MANIPULATOR HIDE/SHOW
	B747DR_thrust_mnp_show[0]	= B747_ternary(simDR_engine_throttle_jet[0] < 0.0, 0, 1)
	B747DR_thrust_mnp_show[1]	= B747_ternary(simDR_engine_throttle_jet[1] < 0.0, 0, 1)
	B747DR_thrust_mnp_show[2]	= B747_ternary(simDR_engine_throttle_jet[2] < 0.0, 0, 1)
	B747DR_thrust_mnp_show[3]	= B747_ternary(simDR_engine_throttle_jet[3] < 0.0, 0, 1)
	
	B747DR_thrust_mnp_show_all	= B747_ternary(simDR_engine_throttle_jet_all < 0.0, 0, 1)
	
	
	
	-- REVERSE LEVER MANIPULATOR HIDE/SHOW
	B747DR_reverse_mnp_show[0] 	= B747_ternary(simDR_engine_throttle_jet[0] > 0.0, 0, 1)
	B747DR_reverse_mnp_show[1] 	= B747_ternary(simDR_engine_throttle_jet[1] > 0.0, 0, 1)
	B747DR_reverse_mnp_show[2] 	= B747_ternary(simDR_engine_throttle_jet[2] > 0.0, 0, 1)
	B747DR_reverse_mnp_show[3] 	= B747_ternary(simDR_engine_throttle_jet[3] > 0.0, 0, 1)
	
	B747DR_reverse_mnp_show_all	= B747_ternary(simDR_engine_throttle_jet_all > 0.0, 0, 1)

		    	 	 
end














----- EGT INIDICATOR --------------------------------------------------------------------
local EGT_start_limit       = 535.0                                                     -- RED
local EGT_continuous_limit  = 629.0                                                     -- AMBER
local EGT_max_limit         = 654.0                                                     -- REDLINE
local EGT_check_inhibit     = {1, 1, 1, 1}
local EGT_amber_inhibit     = {0, 0, 0, 0}

function B747_EGT01_5min_inhibit_canx()
    EGT_amber_inhibit[1] = 0
end
function B747_EGT01_10min_inhibit_canx()
    EGT_amber_inhibit[1] = 0
end
function B747_EGT02_5min_inhibit_canx()
    EGT_amber_inhibit[2] = 0
end
function B747_EGT02_10min_inhibit_canx()
    EGT_amber_inhibit[2] = 0
end
function B747_EGT03_5min_inhibit_canx()
    EGT_amber_inhibit[3] = 0
end
function B747_EGT03_10min_inhibit_canx()
    EGT_amber_inhibit[3] = 0
end
function B747_EGT04_5min_inhibit_canx()
    EGT_amber_inhibit[4] = 0
end
function B747_EGT04_10min_inhibit_canx()
    EGT_amber_inhibit[4] = 0
end

function B747_EGT_indicator()

    -- GET NUMBER OF RUNNING ENGINES
    local num_eng_running = 0
    for i = 0, 3 do
        if simDR_engine_running[i] == 1 then
            num_eng_running = num_eng_running + 1
        end
    end

    -- ----------------------------------------------------------------------------------
    -- ENGINE #1
    -- ----------------------------------------------------------------------------------
    if simDR_engine_EGT_degC[0] <= EGT_continuous_limit then
        EGT_amber_inhibit[1] = 0
        EGT_check_inhibit[1] = 1
        if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == true then
            stop_timer(B747_EGT01_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == true then
            stop_timer(B747_EGT01_10min_inhibit_canx)
        end

    elseif simDR_engine_EGT_degC[0] > EGT_continuous_limit
        and simDR_engine_EGT_degC[0] <= EGT_max_limit
        and EGT_check_inhibit[1] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[1] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT01_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT01_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT01_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT01_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[1] = 0
            if is_timer_scheduled(B747_EGT01_5min_inhibit_canx) == true then
                stop_timer(B747_EGT01_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT01_10min_inhibit_canx) == true then
                stop_timer(B747_EGT01_10min_inhibit_canx)
            end

        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[0] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if simDR_engine_EGT_degC[0] > EGT_continuous_limit
        and simDR_engine_EGT_degC[0] <= EGT_max_limit
        and EGT_amber_inhibit[1] == 0
    then
        B747DR_EGT_amber_on[0] = 1
    else
        B747DR_EGT_amber_on[0] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (simDR_engine_EGT_degC[0] <= EGT_continuous_limit)
        or
        ((simDR_engine_EGT_degC[0] > EGT_continuous_limit) and (simDR_engine_EGT_degC[0] <= EGT_max_limit) and (EGT_amber_inhibit[1] == 1))
    then
        B747DR_EGT_white_on[0] = 1
    else
        B747DR_EGT_white_on[0] = 0
    end




    -- ----------------------------------------------------------------------------------
    -- ENGINE #2
    -- ----------------------------------------------------------------------------------
    if simDR_engine_EGT_degC[1] <= EGT_continuous_limit then
        EGT_amber_inhibit[2] = 0
        EGT_check_inhibit[2] = 1
        if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == true then
            stop_timer(B747_EGT02_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == true then
            stop_timer(B747_EGT02_10min_inhibit_canx)
        end

    elseif simDR_engine_EGT_degC[1] > EGT_continuous_limit
        and simDR_engine_EGT_degC[1] <= EGT_max_limit
        and EGT_check_inhibit[2] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[2] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT02_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT02_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT02_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT02_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[2] = 0
            if is_timer_scheduled(B747_EGT02_5min_inhibit_canx) == true then
                stop_timer(B747_EGT02_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT02_10min_inhibit_canx) == true then
                stop_timer(B747_EGT02_10min_inhibit_canx)
            end

        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[1] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if simDR_engine_EGT_degC[1] > EGT_continuous_limit
        and simDR_engine_EGT_degC[1] <= EGT_max_limit
        and EGT_amber_inhibit[2] == 0
    then
        B747DR_EGT_amber_on[1] = 1
    else
        B747DR_EGT_amber_on[1] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (simDR_engine_EGT_degC[1] <= EGT_continuous_limit)
        or ((simDR_engine_EGT_degC[1] > EGT_continuous_limit) and (simDR_engine_EGT_degC[1] <= EGT_max_limit) and (EGT_amber_inhibit[2] == 1))
    then
        B747DR_EGT_white_on[1] = 1
    else
        B747DR_EGT_white_on[1] = 0
    end


    -- ----------------------------------------------------------------------------------
    -- ENGINE #3
    -- ----------------------------------------------------------------------------------
    if simDR_engine_EGT_degC[2] <= EGT_continuous_limit then
        EGT_amber_inhibit[3] = 0
        EGT_check_inhibit[3] = 1
        if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == true then
            stop_timer(B747_EGT03_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == true then
            stop_timer(B747_EGT03_10min_inhibit_canx)
        end

    elseif simDR_engine_EGT_degC[2] > EGT_continuous_limit
        and simDR_engine_EGT_degC[2] <= EGT_max_limit
        and EGT_check_inhibit[3] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[3] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT03_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT03_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT03_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT03_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[3] = 0
            if is_timer_scheduled(B747_EGT03_5min_inhibit_canx) == true then
                stop_timer(B747_EGT03_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT03_10min_inhibit_canx) == true then
                stop_timer(B747_EGT03_10min_inhibit_canx)
            end

        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[2] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if simDR_engine_EGT_degC[2] > EGT_continuous_limit
        and simDR_engine_EGT_degC[2] <= EGT_max_limit
        and EGT_amber_inhibit[3] == 0
    then
        B747DR_EGT_amber_on[2] = 1
    else
        B747DR_EGT_amber_on[2] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (simDR_engine_EGT_degC[2] <= EGT_continuous_limit)
        or ((simDR_engine_EGT_degC[2] > EGT_continuous_limit) and (simDR_engine_EGT_degC[2] <= EGT_max_limit) and (EGT_amber_inhibit[3] == 1))
    then
        B747DR_EGT_white_on[2] = 1
    else
        B747DR_EGT_white_on[2] = 0
    end


    -- ----------------------------------------------------------------------------------
    -- ENGINE #4
    -- ----------------------------------------------------------------------------------
    if simDR_engine_EGT_degC[3] <= EGT_continuous_limit then
        EGT_amber_inhibit[4] = 0
        EGT_check_inhibit[4] = 1
        if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == true then
            stop_timer(B747_EGT04_5min_inhibit_canx)
        end
        if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == true then
            stop_timer(B747_EGT04_10min_inhibit_canx)
        end
    
    elseif simDR_engine_EGT_degC[3] > EGT_continuous_limit
        and simDR_engine_EGT_degC[3] <= EGT_max_limit
        and EGT_check_inhibit[4] == 1
    then
        if B747DR_engine_TOGA_mode == 1 then
            EGT_amber_inhibit[4] = 1                                                    -- INHIBIT DISPLAY OF AMBER INDICATORS
            if num_eng_running > 3 then
                if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == true then
                    stop_timer(B747_EGT04_10min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == false then
                    run_after_time(B747_EGT04_5min_inhibit_canx, 300.0)
                end
            else
                if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == true then
                    stop_timer(B747_EGT04_5min_inhibit_canx)
                end
                if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == false then
                    run_after_time(B747_EGT04_10min_inhibit_canx, 600.0)
                end
            end
        else
            EGT_amber_inhibit[4] = 0
            if is_timer_scheduled(B747_EGT04_5min_inhibit_canx) == true then
                stop_timer(B747_EGT04_5min_inhibit_canx)
            end
            if is_timer_scheduled(B747_EGT04_10min_inhibit_canx) == true then
                stop_timer(B747_EGT04_10min_inhibit_canx)
            end
    
        end
    end


    -- SHOW/HIDE LIMIT MARKER
    B747DR_EGT_amber_inhibit[3] = B747DR_engine_TOGA_mode


    -- SET AMBER HIDE/SHOW
    if simDR_engine_EGT_degC[3] > EGT_continuous_limit
        and simDR_engine_EGT_degC[3] <= EGT_max_limit
        and EGT_amber_inhibit[4] == 0
    then
        B747DR_EGT_amber_on[3] = 1
    else
        B747DR_EGT_amber_on[3] = 0
    end


    -- SET WHITE HIDE/SHOW
    if (simDR_engine_EGT_degC[3] <= EGT_continuous_limit)
        or ((simDR_engine_EGT_degC[3] > EGT_continuous_limit) and (simDR_engine_EGT_degC[3] <= EGT_max_limit) and (EGT_amber_inhibit[4] == 1))
    then
        B747DR_EGT_white_on[3] = 1
    else
        B747DR_EGT_white_on[3] = 0
    end

end







----- N2 FUEL-ON INDICATOR --------------------------------------------------------------
function B747_secondary_EICAS2_fuel_on_status()

    B747DR_EICAS2_fuel_on_ind_status[0] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[0] < 0.05), 1, 0)
    B747DR_EICAS2_fuel_on_ind_status[1] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[1] < 0.05), 1, 0)
    B747DR_EICAS2_fuel_on_ind_status[2] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[2] < 0.05), 1, 0)
    B747DR_EICAS2_fuel_on_ind_status[3] = B747_ternary((B747DR_fuel_control_toggle_switch_pos[3] < 0.05), 1, 0)
    
end




----- ENGINE OIL PRESSURE SECONDARY EICAS DISPLAY ---------------------------------------
function B747_secondary_EICAS2_oil_press_status()

    B747DR_engine_oil_press_psi[0] = simDR_engine_oil_pressure[0] + B747_rescale(0.0, 0.0, 100.0, B747_eng1oilPressVariance, simDR_engine_N1_pct[0])
    B747DR_engine_oil_press_psi[1] = simDR_engine_oil_pressure[1] + B747_rescale(0.0, 0.0, 100.0, B747_eng2oilPressVariance, simDR_engine_N1_pct[1])
    B747DR_engine_oil_press_psi[2] = simDR_engine_oil_pressure[2] + B747_rescale(0.0, 0.0, 100.0, B747_eng3oilPressVariance, simDR_engine_N1_pct[2])
    B747DR_engine_oil_press_psi[3] = simDR_engine_oil_pressure[3] + B747_rescale(0.0, 0.0, 100.0, B747_eng4oilPressVariance, simDR_engine_N1_pct[3])

    for i = 0, 3 do
        B747DR_EICAS2_oil_press_status[i] = 0
        if B747DR_engine_oil_press_psi[i] < 70.0                                            -- PRESURE IS BELOW MINIMUM
            and (simDR_engine_starter_status[i] == 0                                        -- ENGINE STARTER IS NOT ENGAGED
                or B747DR_fuel_control_toggle_switch_pos[i] > 0.95)                         -- ENGINE IS NOT SHUTDOWN
        then
            B747DR_EICAS2_oil_press_status[i] = 1                                           -- SHOW REDLINE OBJECTS
        end
    end

end






---- ENGINE OIL TEMPERATURE -------------------------------------------------------------
function B747_engine_oil_temp()

    B747DR_engine_oil_temp_degC[0] = simDR_engine_oil_temp[0] + B747_rescale(0.0, 0.0, 100.0, B747_eng1oilTempVariance, simDR_engine_N1_pct[0])
    B747DR_engine_oil_temp_degC[1] = simDR_engine_oil_temp[1] + B747_rescale(0.0, 0.0, 100.0, B747_eng2oilTempVariance, simDR_engine_N1_pct[1])
    B747DR_engine_oil_temp_degC[2] = simDR_engine_oil_temp[2] + B747_rescale(0.0, 0.0, 100.0, B747_eng3oilTempVariance, simDR_engine_N1_pct[2])
    B747DR_engine_oil_temp_degC[3] = simDR_engine_oil_temp[3] + B747_rescale(0.0, 0.0, 100.0, B747_eng4oilTempVariance, simDR_engine_N1_pct[3])

end





----- ENGINE VIBRATION ------------------------------------------------------------------
local int, frac = math.modf(os.clock())
local seed = math.random(1, frac*1000.0)
math.randomseed(seed)
local B747_engine1_maxVib = math.min(1.3, math.random(0, 1) + math.random())
local B747_engine2_maxVib = math.min(1.5, math.random(0, 3) + math.random())
local B747_engine3_maxVib = math.min(1.4, math.random(0, 2) + math.random())
local B747_engine4_maxVib = math.min(1.6, math.random(0, 3) + math.random())
function B747_secondary_EICAS2_engine_vibration()

    B747DR_EICAS2_engine_vibration[0] = B747_rescale(0.0, 0.0, 100.0, B747_engine1_maxVib, simDR_engine_N2_pct[0])
    B747DR_EICAS2_engine_vibration[1] = B747_rescale(0.0, 0.0, 100.0, B747_engine2_maxVib, simDR_engine_N2_pct[1])
    B747DR_EICAS2_engine_vibration[2] = B747_rescale(0.0, 0.0, 100.0, B747_engine3_maxVib, simDR_engine_N2_pct[2])
    B747DR_EICAS2_engine_vibration[3] = B747_rescale(0.0, 0.0, 100.0, B747_engine4_maxVib, simDR_engine_N2_pct[3])

end







----- ENGINE OIL QUANTITY ---------------------------------------------------------------
function B747_engine_oil_qty()

    B747DR_engine_oil_qty_liters[0] = math.max(0, (B747_eng1oilStart - (B747_eng1startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, simDR_engine_N1_pct[0]))) * simDR_engine_oil_qty_ratio[0])
    B747DR_engine_oil_qty_liters[1] = math.max(0, (B747_eng2oilStart - (B747_eng2startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, simDR_engine_N1_pct[1]))) * simDR_engine_oil_qty_ratio[0])
    B747DR_engine_oil_qty_liters[2] = math.max(0, (B747_eng3oilStart - (B747_eng3startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, simDR_engine_N1_pct[2]))) * simDR_engine_oil_qty_ratio[0])
    B747DR_engine_oil_qty_liters[3] = math.max(0, (B747_eng4oilStart - (B747_eng4startupOilTxfr * B747_rescale(0.0, 0.0, 15.0, 1.0, simDR_engine_N1_pct[3]))) * simDR_engine_oil_qty_ratio[0])

end




----- EPR -------------------------------------------------------------------------------
function B747_EPR()

    B747_ref_thr_limit_mode = "NONE"

    -- SET EPR MAX LIMIT
    for i = 0, 3 do
        B747DR_EPR_max_limit[i] = 2.0
    end

--[[
    -- TOGA
    if B747DR_engine_TOGA_mode == 1 then
        B747_ref_thr_limit_mode = "TO"
    end
--]]
end




----- THRUST LIMIT MODE -----------------------------------------------------------------
function B747_thrust_limit_mode_label()

    if B747_ref_thr_limit_mode == "NONE" then
        B747DR_ref_thr_limit_mode = ""
    else
        B747DR_ref_thr_limit_mode = B747_ref_thr_limit_mode
    end

end








----- STARTUP IGNITION ------------------------------------------------------------------
function B747_startup_ignition()

    -- IGNITION IS REQUIRED FOR STARTUP WITH ENGINES RUNNING
    -- IF USER SHUTS DOWN AN ENGINE THEY WILL NEED TO MANUALLY RE-START OR RE-LOAD THE SIM
    for i = 0, 3 do
        if simDR_engine_N2_pct[i] < 55.0                                            -- N2 is less than 55.0 %
            and B747_ignition_startup_flag[i+1] == 1                                -- ALLOWS ONLY ONE (1)) AUTO-IGNITE AT SIM LOAD
        then
            simDR_engine_auto_ignite_on[i] = 1                                      -- TURN ON AUTO-IGNITE
        else                                                                        -- ENGINE HAS STARTED
            if simDR_engine_auto_ignite_on[i] == 1 then
                simDR_engine_auto_ignite_on[i] = 0                                  -- TURN AUTO-IGNITE OFF
                B747_ignition_startup_flag[i+1] = 0                                 -- SET FLAG TO PREVENT FUTURE AUTO-IGNITE
            end
        end
    end

end





----- EICAS MESSAGES --------------------------------------------------------------------
function B747_engines_EICAS_msg()


    -- ENG 1 SHUTDOWN
    B747DR_CAS_caution_status[23] = 0
    if B747DR_engine01_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[0] < 0.05
    then
        B747DR_CAS_caution_status[23] = 1
    end

    -- ENG 2 SHUTDOWN
    B747DR_CAS_caution_status[24] = 0
    if B747DR_engine02_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[1] < 0.05
    then
        B747DR_CAS_caution_status[24] = 1
    end

    -- ENG 3 SHUTDOWN
    B747DR_CAS_caution_status[25] = 0
    if B747DR_engine03_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[2] < 0.05
    then
        B747DR_CAS_caution_status[25] = 1
    end

    -- ENG 4 SHUTDOWN
    B747DR_CAS_caution_status[26] = 0
    if B747DR_engine04_fire_ext_switch_pos_disch > 0.95
        or B747DR_fuel_control_toggle_switch_pos[3] < 0.05
    then
        B747DR_CAS_caution_status[26] = 1
    end

    -- STARTER CUTOUT 1
    B747DR_CAS_caution_status[61] = 0
    if B747DR_bleedAir_engine1_start_valve_pos > 0.05
        and simDR_engine_N2_pct[0] > 50.0
    then
        B747DR_CAS_caution_status[61] = 1
    end

    -- STARTER CUTOUT 2
    B747DR_CAS_caution_status[62] = 0
    if B747DR_bleedAir_engine2_start_valve_pos > 0.05
        and simDR_engine_N2_pct[1] > 50.0
    then
        B747DR_CAS_caution_status[62] = 1
    end

    -- STARTER CUTOUT 3
    B747DR_CAS_caution_status[63] = 0
    if B747DR_bleedAir_engine3_start_valve_pos > 0.05
        and simDR_engine_N2_pct[2] > 50.0
    then
        B747DR_CAS_caution_status[63] = 1
    end

    -- STARTER CUTOUT 4
    B747DR_CAS_caution_status[64] = 0
    if B747DR_bleedAir_engine4_start_valve_pos > 0.05
        and simDR_engine_N2_pct[3] > 50.0
    then
        B747DR_CAS_caution_status[64] = 1
    end

    -- ENG 1 OIL TEMP
    B747DR_CAS_advisory_status[118] = 0
    if B747DR_engine_oil_temp_degC[0] > 160.0 then B747DR_CAS_advisory_status[118] = 1 end

    -- ENG 2 OIL TEMP
    B747DR_CAS_advisory_status[119] = 0
    if B747DR_engine_oil_temp_degC[1] > 160.0 then B747DR_CAS_advisory_status[119] = 1 end

    -- ENG 3 OIL TEMP
    B747DR_CAS_advisory_status[120] = 0
    if B747DR_engine_oil_temp_degC[2] > 160.0 then B747DR_CAS_advisory_status[120] = 1 end

    -- ENG 4 OIL TEMP
    B747DR_CAS_advisory_status[121] = 0
    if B747DR_engine_oil_temp_degC[3] > 160.0 then B747DR_CAS_advisory_status[121] = 1 end

    -- ENG 1 REVERSER
    B747DR_CAS_advisory_status[126] = 0
    if simDR_thrust_rev_fail_01 == 6 then B747DR_CAS_advisory_status[126] = 1 end

    -- ENG 2 REVERSER
    B747DR_CAS_advisory_status[127] = 0
    if simDR_thrust_rev_fail_02 == 6 then B747DR_CAS_advisory_status[127] = 1 end

    -- ENG 3 REVERSER
    B747DR_CAS_advisory_status[128] = 0
    if simDR_thrust_rev_fail_03 == 6 then B747DR_CAS_advisory_status[128] = 1 end

    -- ENG 4 REVERSER
    B747DR_CAS_advisory_status[129] = 0
    if simDR_thrust_rev_fail_04 == 6 then B747DR_CAS_advisory_status[129] = 1 end

    -- >ENG 1 RPM LIM
    B747DR_CAS_advisory_status[134] = 0
    if simDR_engine_N1_pct[0] >= 111.41 then B747DR_CAS_advisory_status[134] = 1 end

    -- >ENG 2 RPM LIM
    B747DR_CAS_advisory_status[135] = 0
    if simDR_engine_N1_pct[1] >= 111.41 then B747DR_CAS_advisory_status[135] = 1 end

    -- >ENG 3 RPM LIM
    B747DR_CAS_advisory_status[136] = 0
    if simDR_engine_N1_pct[2] >= 111.41 then B747DR_CAS_advisory_status[136] = 1 end

    -- >ENG 4 RPM LIM
    B747DR_CAS_advisory_status[137] = 0
    if simDR_engine_N1_pct[3] >= 111.41 then B747DR_CAS_advisory_status[137] = 1 end

    -- CON IGNITION ON
    B747DR_CAS_memo_status[8] = 0
    if B747DR_CAS_advisory_status[109] == 0 then
        if B747DR_button_switch_position[44] > 0.95 then B747DR_CAS_memo_status[8] = 1 end
    end

end








----- MONITOR AI FOR AUTO-BOARD CALL ----------------------------------------------------
function B747_engines_monitor_AI()

    if B747DR_init_engines_CD == 1 then
        B747_set_engines_all_modes()
        B747_set_engines_CD()
        B747_set_engines_all_modes2()
        B747DR_init_engines_CD = 2
    end

end





----- SET STATE FOR ALL MODES -----------------------------------------------------------
function B747_set_engines_all_modes()

	B747DR_init_engines_CD = 0

end





function B747_set_engines_all_modes2()
--[[
    for i = 0, 3 do
        B747_old_throttle_lever_input[i+1] = simDR_engine_throttle_input[i]
    end
--]]
end





----- SET STATE TO COLD & DARK ----------------------------------------------------------
function B747_set_engines_CD()

    B747DR_engine_fuel_valve_pos[0] = 0
    B747DR_engine_fuel_valve_pos[1] = 0
    B747DR_engine_fuel_valve_pos[2] = 0
    B747DR_engine_fuel_valve_pos[3] = 0


end





----- SET STATE TO ENGINES RUNNING ------------------------------------------------------
function B747_set_engines_ER()
	
    B747DR_engine_fuel_valve_pos[0] = 1
    B747DR_engine_fuel_valve_pos[1] = 1
    B747DR_engine_fuel_valve_pos[2] = 1
    B747DR_engine_fuel_valve_pos[3] = 1  

    B747_startup_ignition()
	
end








----- FLIGHT START ----------------------------------------------------------------------
function B747_flight_start_engines()

    -- ALL MODES ------------------------------------------------------------------------
	B747_set_engines_all_modes()



    -- COLD & DARK ----------------------------------------------------------------------
    if simDR_startup_running == 0 then

        B747_set_engines_CD()



    -- ENGINES RUNNING ------------------------------------------------------------------
    elseif simDR_startup_running == 1 then
	
		B747_set_engines_ER()


    end


    -- ALL MODES POST PROCESS -----------------------------------------------------------
    B747_set_engines_all_modes2()

end







--*************************************************************************************--
--** 				                  EVENT CALLBACKS           	    			 **--
--*************************************************************************************--

function aircraft_load() end

function aircraft_unload() end

function flight_start() 

    B747_flight_start_engines()

end

--function flight_crash() end

function before_physics()

    --B747_electronic_engine_control()

end

function after_physics()

    B747_startup_ignition()

    B747_prop_mode()
    
    B747_set_tq_levers_mnp_show()

    --B747_electronic_engine_control()

    B747_EGT_indicator()

    B747_engine_oil_qty()
    B747_engine_oil_temp()
    B747_secondary_EICAS2_fuel_on_status()
    B747_secondary_EICAS2_oil_press_status()
    B747_secondary_EICAS2_engine_vibration()

    B747_EPR() 
    B747_thrust_limit_mode_label()

    B747_engines_EICAS_msg()

    B747_engines_monitor_AI()
    
end

--function after_replay() end





--*************************************************************************************--
--** 				               SUB-MODULE PROCESSING       	        			 **--
--*************************************************************************************--

-- dofile("")



