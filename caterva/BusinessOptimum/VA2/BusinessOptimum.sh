#!/bin/bash
### BEGIN INFO
# Provides: Business Optimization
#
# chargeStandbyThreshold_hyst:		Charging routine will stop, when "chargeStandbyThreshold_hyst" has been reached
# dischargeStandbyThreshold:		Discharging immediately, when "dischargeStandbyThreshold" exceeded
# dischargeStandbyThreshold_delay:	Discharging only, when "dischargeStandbyThreshold_delay" has been exceeded > "counter_standby_to_discharge_max"
# dischargeStandbyThreshold_hyst:	Discharging routine will stop, when "dischargeStandbyThreshold_hyst" has been reached
# Charching until "SoC_max" reached; sets "ChargedFlag", which ensures that until reaching "SoC_charge" only discharge is possible
#
# Log: /home/admin/bin/BusinessOptimum.log
# Standby is forced due to file '/home/admin/registry/noPVBuffering'
# /home/admin/registry/chargeStandbyThreshold   		- not existing or standard value: 400.00
# /home/admin/registry/dischargeStandbyThreshold 		- not existing or standard value: 300.00
#
# Status  ---  cat /home/admin/registry/noPVBuffering   - not existing: PVBuffering / existing: noPVBuffering
#              cat /var/log/ChargedFlag					- '0' charge/discharge possible
#														- '1' discharge only
#														- "-1" force charching
#
#              Balancing								- '0' Balancing not active (Standard-Balancing)
#														- '1' Balancing active (Standard-Balancing)
#
## set Module-Balancing/Cell-Balancing based on existing file content
# touch /var/log/ModuleBalancing
# touch /var/log/CellBalancing
#
# System_Running=$(swarmBcSend "LLN0.Mod.stVal")
# System_Initialization=$(swarmBcSend "LLN0.Init.stVal")
# U_cell_minV=$(swarmBcSend "MBMS1.MinV.mag.f")
# U_cell_maxV=$(swarmBcSend "MBMS1.MaxV.mag.f")
# BMU_current_max=$(swarmBcSend "MBMS1.MaxA.mag.f")
# BMU_current_min=$(swarmBcSend "MBMS1.MaxA.mag.f")
#
# SoC_int=$(swarmBcSend "MBMS1.SocDC.stVal")
# CPOL1_Mod=$(swarmBcSend "CPOL1.Mod.stVal")
# PVandHH=$(swarmBcSend "MMXU4.TotW.mag.f")
# Inv_Request=$(swarmBcSend "ZINV1.TotW.mxVal.f")
## activate device:
# swarmBcSend "LLN0.Mod.ctlVal=1" > /dev/null
# System_Activated=$(swarmBcSend "LLN0.Mod.ctlVal")
# Inverter Loading
# swarmBcSend "CPOL1.Wchrg.setMag.f=1000"				# 1000W
# swarmBcSend "CPOL1.OffsetDuration.setVal=3000"		# 3000s
# date +%s												# Determine current time
# swarmBcSend "CPOL1.OffsetStart.setVal=1604344838" 	# Start

# Siegfried Quinger - VA20_2021-01-03_18.00
### END INFO


#-------------------------------------------------------------------------------------------------------------------
version="VA20_2021-01-03_18.00"
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
_LOGDIR_=/home/admin/bin
_LOGFILENAME_=BusinessOptimum.log
_LOGFILE_=${_LOGDIR_}/${_LOGFILENAME_}
_BO_ConfigDIR_=/home/admin/bin
_BO_ConfigFILENAME_=BusinessOptimum.config
_BO_ConfigFILE_=${_BO_ConfigDIR_}/${_BO_ConfigFILENAME_}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
#
# F  U  N  C  T  I  O  N  S 	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#	#
#
#-------------------------------------------------------------------------------------------------------------------
# function_Print_Battery_Status_1338
# Display / Print Battery Status
#-------------------------------------------------------------------------------------------------------------------
function function_Print_Battery_Status_1338 ()
 {
	echo "" >> ${_LOGFILE_}
	(echo "mod";sleep 0.3;echo "exit";) | netcat localhost 1338 >> /tmp/swarm-battery-cmd.tmp
	tail -n 29 /tmp/swarm-battery-cmd.tmp > /tmp/swarm-battery-cmd_tail.tmp
	head -n 24 /tmp/swarm-battery-cmd_tail.tmp >> ${_LOGFILE_}
	echo "" >> ${_LOGFILE_}
 }
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Print_nohup
# Display / Print nohup.out
#-------------------------------------------------------------------------------------------------------------------
function function_Print_nohup ()
 {
	echo ------------------------------------------------------------------------ >> ${_LOGFILE_}
	echo "Inhalt von nohup.out:" >> ${_LOGFILE_}
	cat /home/admin/bin/nohup.out >> ${_LOGFILE_}
	echo ------------------------------------------------------------------------ >> ${_LOGFILE_}
	rm -f /home/admin/bin/nohup.out
	touch /home/admin/bin/nohup.out
 }
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_exit_and_start
# Record System Status in log-File prior to restarting, force restart of BusinessOptimum
#-------------------------------------------------------------------------------------------------------------------
function function_exit_and_start ()
{
echo "" >> ${_LOGFILE_}
echo $(date +"%Y-%m-%d %T") '||' System nicht mehr betriebsbereit >> ${_LOGFILE_}
echo ------------------------------------------------------------------------------------------------ >> ${_LOGFILE_}
System_Initialization=$(swarmBcSend "LLN0.Init.stVal")
echo Systemzustandsabfrage 'LLN0.Init.stVal'... '"'$System_Initialization'"' >> ${_LOGFILE_}
System_Running=$(swarmBcSend "LLN0.Mod.stVal")
echo Systembetriebsabfrage 'LLN0.Mod.stVal'... '"'$System_Running'"' >> ${_LOGFILE_}

# Display / Print nohup.out
function_Print_nohup

echo $(date +"%Y-%m-%d %T") '||' System nicht mehr betriebsbereit - Abbruch >> ${_LOGFILE_}
echo ------------------------------------------------------------------------------------------------ >> ${_LOGFILE_}

# Restart only when BusinessOptimumStarter is not configured: Status: "0"
if [[ $BusinessOptimum_BOS == "0" ]]; then
	echo $(date +"%Y-%m-%d %T") '||' BusinessOptimum wird neu gestartet >> ${_LOGFILE_}
	echo "" >> ${_LOGFILE_}

	# Re-Start BusinessOptimum
	nohup /home/admin/bin/BusinessOptimum.sh &
fi
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Kill_processes
# Kill processes
#-------------------------------------------------------------------------------------------------------------------
function function_Kill_processes ()
 {
	echo "" >> ${_LOGFILE_}
	top -b -n 1 | grep load >> ${_LOGFILE_}
	top -b -n 1 | grep agetty >> ${_LOGFILE_}
	top -b -n 1 | grep monitor.sh >> ${_LOGFILE_}
	top -b -n 1 | grep swarmcomm.sh >> ${_LOGFILE_}
	p1=$(pidof -x agetty)
	sudo pkill -SIGTERM agetty
	p2=$(pidof -x agetty)
	#echo $(date +"%Y-%m-%d %T") '||' agetty aktuell: $p1 '(PIDs)' '||' killed '||' agetty neu: $p2 '(PIDs)' >> ${_LOGFILE_}
	sudo pkill -SIGTERM swarmcomm.sh
 }
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Timer_Minute
# Monitor time to initate certain functions (every minute)
#-------------------------------------------------------------------------------------------------------------------
function function_Timer_Minute ()
{
	Timer_M_increment_int=0
	if [ $Status_Timer_M_ini_int -eq 1 ]; then
		# Timer_M --- Monitor time to initate certain functions (every minute)
		if ( [ $(date +%S) -ge 00 ] && [ $(date +%S) -le 15 ] && [ $Status_Timer_M_int -eq 0 ] && [ $Timer_M_increment_int -eq 0 ] ); then
			Timer_M_increment_int=$(awk '{print $1}' <<<"${Timer_M_increment_int}")
			Status_Timer_M_int=1
		fi
		if ( [ $(date +%S) -ge 16 ] && [ $Status_Timer_M_int -eq 1 ] ); then
			Timer_M_increment_int=0
			Status_Timer_M_int=0
			Status_Timer_M_activated_int=0
		fi
	fi
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Timer_Hour
# Monitor time to initate certain functions (every hour)
#-------------------------------------------------------------------------------------------------------------------
function function_Timer_Hour ()
{
	if [ $Status_Timer_H_ini_int -eq 1 ]; then
		# Timer_H --- Monitor time to initate certain functions (every hour)
		if ( [ $(date +%M) -eq 00 ] && [ $Status_Timer_H_int -eq 0 ] ); then
			Status_Timer_H_int=1
		fi
		if ( [ $(date +%M) -eq 01 ] && [ $Status_Timer_H_int -eq 1 ] ); then
			Status_Timer_H_int=0
			Status_Timer_H_activated_int=0
		fi
	fi
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_CPOL_Reset
# CPOL: set back to normal operations
#-------------------------------------------------------------------------------------------------------------------
function function_CPOL_Reset ()
{
	swarmBcSend "CPOL1.Wchrg.setMag.f=0" > /dev/null
	swarmBcSend "CPOL1.OffsetDuration.setVal=1422692866" > /dev/null
	swarmBcSend "CPOL1.OffsetStart.setVal=0" > /dev/null
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Read__Cell_Voltage
# Read cell voltage min/max
#-------------------------------------------------------------------------------------------------------------------
function function_Read__Cell_Voltage ()
{
	U_cell_minV=$(swarmBcSend "MBMS1.MinV.mag.f")
	U_cell_maxV=$(swarmBcSend "MBMS1.MaxV.mag.f")
	# Convert floating/text to integer
	printf -v U_cell_minV_int %.0f $U_cell_minV
	printf -v U_cell_maxV_int %.0f $U_cell_maxV
	U_cell_diff_V_int=$(awk '{print $1-$2}' <<<"${U_cell_maxV_int} ${U_cell_minV_int}")
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Read__BMU_Current_SoC_Capa
# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
#-------------------------------------------------------------------------------------------------------------------
function function_Read__BMU_Current_SoC_Capa ()
{
	# Determine actual current of BMU
	BMU_current_max=$(swarmBcSend "MBMS1.MaxA.mag.f")
	# Convert text to float
	printf -v BMU_current_max_float %.3f $BMU_current_max
	BMU_current_max=$(awk '{print ($1*1000)}' <<<"${BMU_current_max_float}")
	# Convert floating/text to integer
	printf -v BMU_current_max_int %.0f $BMU_current_max

	# Read status of individual modules
	(echo "mod";sleep 0.3;echo "exit";) | netcat localhost 1338 >> /tmp/swarm-battery-cmd.tmp
	tail -n 15 /tmp/swarm-battery-cmd.tmp | grep "soc" > /tmp/swarm-battery-cmd_tail.tmp
	SoC_module_BMU=$(awk -F " " '{print $3}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_1=$(awk -F " " '{print $4}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_2=$(awk -F " " '{print $5}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_3=$(awk -F " " '{print $6}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_4=$(awk -F " " '{print $7}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_5=$(awk -F " " '{print $8}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_6=$(awk -F " " '{print $9}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_7=$(awk -F " " '{print $10}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_8=$(awk -F " " '{print $11}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_9=$(awk -F " " '{print $12}'    /tmp/swarm-battery-cmd_tail.tmp)
	SoC_module_10=$(awk -F " " '{print $13}'    /tmp/swarm-battery-cmd_tail.tmp)

	# Convert floating/text to integer
	printf -v SoC_module_BMU_int %.0f $SoC_module_BMU
	printf -v SoC_module_1_int %.0f $SoC_module_1
	printf -v SoC_module_2_int %.0f $SoC_module_2
	printf -v SoC_module_3_int %.0f $SoC_module_3
	printf -v SoC_module_4_int %.0f $SoC_module_4
	printf -v SoC_module_5_int %.0f $SoC_module_5
	printf -v SoC_module_6_int %.0f $SoC_module_6
	printf -v SoC_module_7_int %.0f $SoC_module_7
	printf -v SoC_module_8_int %.0f $SoC_module_8
	printf -v SoC_module_9_int %.0f $SoC_module_9
	printf -v SoC_module_10_int %.0f $SoC_module_10

	#Determine the SoC difference of the individual modules
	SoC_module_min_int=$SoC_module_BMU_int
	SoC_module_max_int=$SoC_module_1_int
	if [ $SoC_module_2_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_2_int; fi
	if [ $SoC_module_3_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_3_int; fi
	if [ $SoC_module_4_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_4_int; fi
	if [ $SoC_module_5_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_5_int; fi
	if [ $SoC_module_6_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_6_int; fi
	if [ $SoC_module_7_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_7_int; fi
	if [ $SoC_module_8_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_8_int; fi
	if [ $SoC_module_9_int -gt $SoC_module_max_int ]; then	SoC_module_max_int=$SoC_module_9_int; fi
	if [ $SoC_module_10_int -gt $SoC_module_max_int ]; then SoC_module_max_int=$SoC_module_10_int; fi
	SoC_module_diff=$(awk '{print ($1-$2)/10}' <<<"${SoC_module_max_int} ${SoC_module_min_int}")
	# Convert floating/text to integer
	printf -v SoC_module_diff_int %.0f $SoC_module_diff

	#Determine remaining and full capacity of BMU
	tail -n 15 /tmp/swarm-battery-cmd.tmp | grep "rem" > /tmp/swarm-battery-cmd_tail.tmp
	rem_capa_module_BMU=$(awk -F " " '{print $4}'    /tmp/swarm-battery-cmd_tail.tmp)
	tail -n 15 /tmp/swarm-battery-cmd.tmp | grep "full" > /tmp/swarm-battery-cmd_tail.tmp
	full_capa_module_BMU=$(awk -F " " '{print $4}'    /tmp/swarm-battery-cmd_tail.tmp)
	# Convert floating/text to integer
	printf -v rem_capa_module_BMU_int %.0f $rem_capa_module_BMU
	printf -v full_capa_module_BMU_int %.0f $full_capa_module_BMU

	capa_module_100=$(awk '{print (100*$1/$2)}' <<<"${rem_capa_module_BMU_int} ${full_capa_module_BMU_int}")
	# Convert floating/text to integer
	printf -v capa_module_100_int %.0f $capa_module_100
	capa_module_100_int_low_int=$(awk '{print ($1-1)}' <<<"${capa_module_100_int}")

	# Determine remaining capacity for charging sequences
	time_remaining_int=$(awk '{print ($1-$2)}' <<<"${time_limit_int} ${time_current_sec_epoch_int}")
	capacity_remaining_int=$(awk '{print ($1-$2)}' <<<"${full_capa_module_BMU_minus_int} ${rem_capa_module_BMU_int}")

	echo ""  >> ${_LOGFILE_}
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Read__Logs_Time_PVHH_INV_SoC
# Read time, PVandHH, INV, SoC (invoice and battery log)
#-------------------------------------------------------------------------------------------------------------------
function function_Read__Logs_Time_PVHH_INV_SoC ()
{
	# Save last line of invoiceLog --- Read data from invoiceLog: PV, HH, SoC
	# Note: Only 1 reading is difficult, as value may vary a bit, therefore average of 3 readings
	# 1st reading of invoiceLog 
	tail -3 /var/log/invoiceLog.csv | grep -v "^#" | grep "20" | tail -1 > /var/log/invoiceLog_tail_1.csv
	time=$(awk -F ";" '{print $2}'  /var/log/invoiceLog_tail_1.csv)
	PV_1=$(awk -F ";" '{print $14}' /var/log/invoiceLog_tail_1.csv)
	HH_1=$(awk -F ";" '{print $15}' /var/log/invoiceLog_tail_1.csv)
	sleep 0.35
	# 2nd reading of invoiceLog 
	tail -3 /var/log/invoiceLog.csv | grep -v "^#" | grep "20" | tail -1 > /var/log/invoiceLog_tail_2.csv
	PV_2=$(awk -F ";" '{print $14}'    /var/log/invoiceLog_tail_2.csv)
	HH_2=$(awk -F ";" '{print $15}'    /var/log/invoiceLog_tail_2.csv)
	sleep 0.35
	# 3rd reading of invoiceLog 
	tail -3 /var/log/invoiceLog.csv | grep -v "^#" | grep "20" | tail -1 > /var/log/invoiceLog_tail_3.csv
	PV_3=$(awk -F ";" '{print $14}'    /var/log/invoiceLog_tail_3.csv)
	HH_3=$(awk -F ";" '{print $15}'    /var/log/invoiceLog_tail_3.csv)
	# Convert floating/text to integer
	printf -v HH_1_int %.0f $HH_1
	printf -v HH_2_int %.0f $HH_2
	printf -v HH_3_int %.0f $HH_3
	printf -v PV_1_int %.0f $PV_1
	printf -v PV_2_int %.0f $PV_2
	printf -v PV_3_int %.0f $PV_3

	# Combine both PV and HH data to a complete set considerung +/- of Power "HH: +; PV: -"; calculate average of three measurements
	PVandHH_1=$(awk '{print $1-$2}' <<<"${HH_1_int} ${PV_1_int}")
	# Convert floating/text to integer
	printf -v PVandHH_1_int %.0f $PVandHH_1
	PVandHH_2=$(awk '{print $1-$2}' <<<"${HH_2_int} ${PV_2_int}")
	# Convert floating/text to integer
	printf -v PVandHH_2_int %.0f $PVandHH_2
	PVandHH_3=$(awk '{print $1-$2}' <<<"${HH_3_int} ${PV_3_int}")
	# Convert floating/text to integer
	printf -v PVandHH_3_int %.0f $PVandHH_3
	PVandHH=$(awk '{print ($1+$2+$3)/3}' <<<"${PVandHH_1_int} ${PVandHH_2_int} ${PVandHH_3_int}")
	# Convert floating/text to integer
	printf -v PVandHH_int %.0f $PVandHH

	# Save last line of batteryLog --- Read data from batteryLog: CPOL1_Mod, Inv_Request, SoC
	tail -3 /var/log/batteryLog.csv | grep -v "^#" | grep "20" | tail -1 > /var/log/batteryLog_tail.csv
	CPOL1_Mod=$(awk -F ";" '{print $25}'   /var/log/batteryLog_tail.csv)
	Inv_Request=$(awk -F ";" '{print $30}' /var/log/batteryLog_tail.csv)
	SoC=$(awk -F ";" '{print $6}'  /var/log/batteryLog_tail.csv)
	# Convert floating/text to integer
	printf -v SoC_int %.0f $SoC
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Check_Inverter_ON
# Check status of inverter, - if not ON ("1") within 60s force shutdown
#-------------------------------------------------------------------------------------------------------------------
function function_Check_Inverter_ON ()
{
	if [[ $CPOL1_Mod != "1" ]]; then
		# activate device, if not yet activated: swarmBcSend "LLN0.Mod.ctlVal=1" > /dev/null
		System_Activated=$(swarmBcSend "LLN0.Mod.ctlVal")
		if [[ $System_Activated != "1" ]]; then
			# activate system
			swarmBcSend "LLN0.Mod.ctlVal=1" > /dev/null
			echo $(date +"%Y-%m-%d %T") '||' System activated >> ${_LOGFILE_}
			sleep 30
		fi
		echo $(date +"%Y-%m-%d %T") '||' 60s warten, damit sich der Umrichter aktivieren kann bzw noch aktiviert >> ${_LOGFILE_}
		sleep 60
		CPOL1_Mod=$(swarmBcSend "CPOL1.Mod.stVal")
		if [[ $CPOL1_Mod != "1" ]]; then
			echo $(date +"%Y-%m-%d %T") '||' System - shutdown --- System war nicht aktivierbar >> ${_LOGFILE_}
			sudo shutdown -r now
			echo $(date +"%Y-%m-%d %T") '||' '"shutdown -r now"' nicht möglich, deswegen wird forcierter Reboot eingeleitet  >> ${_LOGFILE_}
			sudo reboot -f
		fi
	fi
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Check_Inverter_ON_charge_60_loops
# Check status of inverter, - if not ON ("1") after 60 loops force shutdown (4min ... 6min)
#-------------------------------------------------------------------------------------------------------------------
function function_Check_Inverter_ON_charge_60_loops ()
{
	if ( [[ $CPOL1_Mod != "1" ]] && [ $loop_inverter_charge_int -lt 60 ] ); then
	    loop_inverter_charge_int=$(awk '{print $1+1}' <<<"${loop_inverter_charge_int}")
		#SQ# echo $(date +"%Y-%m-%d %T") '||' $loop_inverter_charge_int von 60 Loops bis zum shutdown >> ${_LOGFILE_}
	fi
	if ( [[ $CPOL1_Mod != "1" ]] && [ $loop_inverter_charge_int -ge 60 ] ); then
		# echo $(date +"%Y-%m-%d %T") '||' $loop_inverter_charge_int von 60 Loops bis zum shutdown >> ${_LOGFILE_}
		echo $(date +"%Y-%m-%d %T") '||' System - shutdown --- EINSPEICHERN nicht mehr möglich seit für min. 4 min '(60 loops)'  >> ${_LOGFILE_}
		sudo shutdown -r now
		echo $(date +"%Y-%m-%d %T") '||' '"shutdown -r now"' nicht möglich, deswegen wird forcierter Reboot eingeleitet  >> ${_LOGFILE_}
		sudo reboot -f
	fi
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Check_Inverter_ON_discharge_60_loops
# Check status of inverter, - if not ON ("1") after 60 loops force shutdown (4min ... 6min)
#-------------------------------------------------------------------------------------------------------------------
function function_Check_Inverter_ON_discharge_60_loops ()
{
	if ( [[ $CPOL1_Mod != "1" ]] && [ $loop_inverter_discharge_int -lt 60 ] ); then
	    loop_inverter_discharge_int=$(awk '{print $1+1}' <<<"${loop_inverter_discharge_int}")
		#SQ# echo $(date +"%Y-%m-%d %T") '||' $loop_inverter_discharge_int von 60 Loops bis zum shutdown >> ${_LOGFILE_}
	fi
	if ( [[ $CPOL1_Mod != "1" ]] && [ $loop_inverter_discharge_int -ge 60 ] ); then
		# echo $(date +"%Y-%m-%d %T") '||' $loop_inverter_discharge_int von 60 Loops bis zum shutdown >> ${_LOGFILE_}
		echo $(date +"%Y-%m-%d %T") '||' System - shutdown --- AUSSPEICHERN nicht mehr möglich seit min. 4 min '(60 loops)'  >> ${_LOGFILE_}
		sudo shutdown -r now
		echo $(date +"%Y-%m-%d %T") '||' '"shutdown -r now"' nicht möglich, deswegen wird forcierter Reboot eingeleitet  >> ${_LOGFILE_}
		sudo reboot -f
	fi
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Verify_Configuration
# Verify Configuration File and advice on changes
#-------------------------------------------------------------------------------------------------------------------
function function_Verify_Configuration ()
{
	error_int=0
	if [ $chargeStandbyThreshold_hyst_int -gt -400 ]; then
		echo P_in_W_chargeStandbyThreshold_hyst: max: '-400' '||' aktuell: $chargeStandbyThreshold_hyst_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $chargeStandbyThreshold_int -ge $chargeStandbyThreshold_hyst_int ]; then
		echo P_in_W_chargeStandbyThreshold: '<' $chargeStandbyThreshold_hyst_int '||' aktuell: $chargeStandbyThreshold_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $dischargeStandbyThreshold_hyst_int -lt 300 ]; then
		echo P_in_W_dischargeStandbyThreshold_hyst: min: 300 '||' aktuell: $dischargeStandbyThreshold_hyst_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $dischargeStandbyThreshold_delay_int -le $dischargeStandbyThreshold_hyst_int ]; then
		echo P_in_W_dischargeStandbyThreshold_delay: '>' $dischargeStandbyThreshold_hyst_int '||' aktuell: $dischargeStandbyThreshold_delay_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $dischargeStandbyThreshold_int -le $dischargeStandbyThreshold_delay_int ]; then
		echo P_in_W_dischargeStandbyThreshold_delay: '>' $dischargeStandbyThreshold_delay_int '||' aktuell: $dischargeStandbyThreshold_int >> ${_LOGFILE_}
		error_int=1
	fi

	if [ $SoC_max_config_int -gt 90 ]; then
		echo SoC_max: max: 90 '||' aktuell: $SoC_max_config_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $SoC_charge_config_int -ge $SoC_max_config_int ]; then
		echo SoC_charge: '<' $SoC_max_config_int '||' aktuell: $SoC_charge_config_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $SoC_discharge_int -ge $SoC_charge_config_int ]; then
		echo SoC_discharge: *<* $SoC_charge_config_int '||' aktuell: $SoC_discharge_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $SoC_discharge_int -lt 20 ]; then
		echo SoC_discharge: '≥' 20 '||' aktuell: $SoC_discharge_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $SoC_min_int -ge $SoC_discharge_int ]; then
		echo SoC_min: '<' $SoC_discharge_int '||' aktuell: $SoC_min_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $SoC_min_int -lt 10 ]; then
		echo SoC_min: '≥' 10 '||' aktuell: $SoC_min_int >> ${_LOGFILE_}
		error_int=1
	fi
	if [ $SoC_err_int -ne 0 ]; then
		echo SoC_err: gleich: 0 '||' aktuell: $SoC_err_int >> ${_LOGFILE_}
		error_int=1
	fi

	if ( [ $counter_increment_int -lt 3 ] || [ $counter_increment_int -gt 6 ] ); then
		echo counter_increment_int: 3 ... 6 '||' aktuell: $counter_increment_int >> ${_LOGFILE_}
		error_int=1
	fi
	if ( [ $loop_delay_int -lt 0 ] || [ $loop_delay_int -gt 30 ] ); then
		echo loop_delay_int: 0 ... 30 '||' aktuell: $loop_delay_int >> ${_LOGFILE_}
		error_int=1
	fi

	if [ $counter_discharge_to_standby_max -lt $counter_increment_total_int ]; then
		echo counter_discharge_to_standby_max: '≥' $counter_increment_total_int  '||' aktuell: $counter_discharge_to_standby_max >> ${_LOGFILE_}
		error_int=1
	fi

	if [ $counter_standby_to_discharge_max_int -lt $counter_increment_total_int ]; then
		echo counter_standby_to_discharge_max_int: '≥' $counter_increment_total_int  '||' aktuell: $counter_standby_to_discharge_max_int >> ${_LOGFILE_}
		error_int=1
	fi

	if [[ $system_initialization_req != "1112" ]]; then
		if [[ $system_initialization_req != "112" ]]; then
			echo System_Initialization: 1112 oder 112 '||' aktuell: $system_initialization_req >> ${_LOGFILE_}
			error_int=1
		fi
	fi

	if [[ $ECS3_configuration != "PVHH" ]]; then
		echo ECS3 Configuration: PVHH '||' aktuell: $ECS3_configuration >> ${_LOGFILE_}
			error_int=1
	fi
	if [[ $BusinessOptimum_BOS != "0" ]]; then
		if [[ $BusinessOptimum_BOS != "1" ]]; then
			echo BusinessOptimum_BOS: 0 oder 1 '||' aktuell: $BusinessOptimum_BOS >> ${_LOGFILE_}
			error_int=1
		fi
	fi

	if [ $error_int -eq 1 ]; then
		echo Konfiguration muss verändert werden - Programm wird abgebrochen >> ${_LOGFILE_}
		exit
	fi
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Print_Configuration
# Log configuration data in BusinessOptimum.log
#-------------------------------------------------------------------------------------------------------------------
function function_Print_Configuration ()
{
	SystemSerial=$(cat /home/admin/registry/out/serial)
	echo "" >> ${_LOGFILE_}
	echo BusinessOptimum: $version >> ${_LOGFILE_}
	echo $(date +"%Y-%m-%d %T") "(NO WARRANTY)" >> ${_LOGFILE_}
	echo "" >> ${_LOGFILE_}
	echo Configuration of $SystemSerial: >> ${_LOGFILE_}
	echo ------------------------------- >> ${_LOGFILE_}
	echo "P_in_W_chargeStandbyThreshold:         " $chargeStandbyThreshold W >> ${_LOGFILE_}
	echo "P_in_W_chargeStandbyThreshold_hyst:    " $chargeStandbyThreshold_hyst W >> ${_LOGFILE_}
	echo "P_in_W_dischargeStandbyThreshold:       " $dischargeStandbyThreshold W >> ${_LOGFILE_}
	echo "P_in_W_dischargeStandbyThreshold_delay: " $dischargeStandbyThreshold_delay s >> ${_LOGFILE_}
	echo "P_in_W_dischargeStandbyThreshold_hyst:  " $dischargeStandbyThreshold_hyst s >> ${_LOGFILE_}
	echo "SoC_max:                                " $SoC_max_config_int % >> ${_LOGFILE_}
	echo "SoC_charge:                             " $SoC_charge_config_int % >> ${_LOGFILE_}
	echo "SoC_discharge:                          " $SoC_discharge_int % >> ${_LOGFILE_}
	echo "SoC_min:                                " $SoC_min_int % >> ${_LOGFILE_}
	echo "SoC_err:                                " $SoC_err_int % >> ${_LOGFILE_}
	echo "counter_discharge_to_standby_max:       " $counter_discharge_to_standby_max_int s >> ${_LOGFILE_}
	echo "counter_standby_to_discharge_max:       " $counter_standby_to_discharge_max_int s >> ${_LOGFILE_}
	echo "counter_increment:                      " $counter_increment_int s per loop without additional delay >> ${_LOGFILE_}
	echo "loop_delay:                             " $loop_delay_int s '('additional delay until rescan')' >> ${_LOGFILE_}
	echo "counter_increment_total:                " $counter_increment_total_int s '('complete loop time, rescan every $counter_increment_total_int s')' >> ${_LOGFILE_}
	echo "system_initialization:                  " $system_initialization_req >> ${_LOGFILE_}
	echo "ECS3_configuration:                     " $ECS3_configuration >> ${_LOGFILE_}
	echo "BusinessOptimum:                        " $BusinessOptimum_BOS '(' 0: stand-alone // 1: BusinessOptimumStarter necessary ')' >> ${_LOGFILE_}
	echo "" >> ${_LOGFILE_}
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Read_Configuration
# Read configuration data of BusinessOptimum.config
#-------------------------------------------------------------------------------------------------------------------
function function_Read_Configuration ()
{
	# Read variabels from BusinessOptimum.config
	tail -1 ${_BO_ConfigFILE_} > /tmp/BusinessOptimum.tmp
	chargeStandbyThreshold=$(awk -F ";" '{print $1}'  /tmp/BusinessOptimum.tmp)
	chargeStandbyThreshold_hyst=$(awk -F ";" '{print $2}'  /tmp/BusinessOptimum.tmp)
	dischargeStandbyThreshold=$(awk -F ";" '{print $3}'  /tmp/BusinessOptimum.tmp)
	dischargeStandbyThreshold_delay=$(awk -F ";" '{print $4}'  /tmp/BusinessOptimum.tmp)
	dischargeStandbyThreshold_hyst=$(awk -F ";" '{print $5}'  /tmp/BusinessOptimum.tmp)
	SoC_max_config=$(awk -F ";" '{print $6}'  /tmp/BusinessOptimum.tmp)
	SoC_charge_config=$(awk -F ";" '{print $7}'  /tmp/BusinessOptimum.tmp)
	SoC_discharge=$(awk -F ";" '{print $8}'  /tmp/BusinessOptimum.tmp)
	SoC_min=$(awk -F ";" '{print $9}'  /tmp/BusinessOptimum.tmp)
	SoC_err=$(awk -F ";" '{print $10}' /tmp/BusinessOptimum.tmp)
	counter_discharge_to_standby_max=$(awk -F ";" '{print $11}' /tmp/BusinessOptimum.tmp)
	counter_standby_to_discharge_max=$(awk -F ";" '{print $12}' /tmp/BusinessOptimum.tmp)
	counter_increment=$(awk -F ";" '{print $13}' /tmp/BusinessOptimum.tmp)
	loop_delay=$(awk -F ";" '{print $14}' /tmp/BusinessOptimum.tmp)
	system_initialization_req=$(awk -F ";" '{print $15}' /tmp/BusinessOptimum.tmp)
	ECS3_configuration=$(awk -F ";" '{print $16}' /tmp/BusinessOptimum.tmp)
	BusinessOptimum_BOS=$(awk -F ";" '{print $17}' /tmp/BusinessOptimum.tmp)

	# Convert floating/text to integer
	printf -v chargeStandbyThreshold_int %.0f $chargeStandbyThreshold
	printf -v chargeStandbyThreshold_hyst_int %.0f $chargeStandbyThreshold_hyst
	printf -v dischargeStandbyThreshold_int %.0f $dischargeStandbyThreshold
	printf -v dischargeStandbyThreshold_delay_int %.0f $dischargeStandbyThreshold_delay
	printf -v dischargeStandbyThreshold_hyst_int %.0f $dischargeStandbyThreshold_hyst
	printf -v SoC_max_config_int %.0f $SoC_max_config
	printf -v SoC_charge_config_int %.0f $SoC_charge_config
	printf -v SoC_discharge_int %.0f $SoC_discharge
	printf -v SoC_min_int %.0f $SoC_min
	printf -v SoC_err_int %.0f $SoC_err
	printf -v counter_discharge_to_standby_max_int %.0f $counter_discharge_to_standby_max
	printf -v counter_standby_to_discharge_max_int %.0f $counter_standby_to_discharge_max
	printf -v counter_increment_int %.0f $counter_increment
	printf -v loop_delay_int %.0f $loop_delay
	# Set the timer/counter based on execution time of loop and requested delay (loop_delay)
	counter_increment_total_int=$(awk '{print $1+$2}' <<<"${counter_increment_int} ${loop_delay_int}")
}
#-------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------------------------------------------------
# function_Compare_Configuration
# Update Configuration when BusinessOptimum.config was changed
#-------------------------------------------------------------------------------------------------------------------
function function_Compare_Configuration ()
{
	if ( ! cmp -s ${_BO_ConfigFILE_} /tmp/BusinessOptimum.config ); then
		# Copy BusinessOptimum.config to temp file for comparison of changes
		cp -f ${_BO_ConfigFILE_} /tmp/BusinessOptimum.config
		# Read configuration data of BusinessOptimum.config
		function_Read_Configuration
		echo "" >> ${_LOGFILE_}
		echo ------------------------------------------------------------------------ >> ${_LOGFILE_}
		echo $(date +"%Y-%m-%d %T") '|' "Update der Konfiguration" >> ${_LOGFILE_}
		echo ------------------------------------------------------------------------ >> ${_LOGFILE_}
		# Log configuration data in BusinessOptimum.log
		function_Print_Configuration
		# Verify Configuration File and advice on changes
		function_Verify_Configuration
		# Copy BusinessOptimum.config to Pi
		tail -40 /tmp/BusinessOptimum.config | grep -v "FHEM" > /tmp/BusinessOptimum_FHEM.config
		sshpass -p pi scp -o StrictHostKeyChecking=no /tmp/BusinessOptimum_FHEM.config fhem@192.168.0.50:/opt/fhem/log/BusinessOptimum.config
	fi
}
#-------------------------------------------------------------------------------------------------------------------



#-------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------
# Array of System Serialnumbers
#-------------------------------------------------------------------------------------------------------------------
SystemSerial_array=( SN000044 SN000068 SN000135 SN000168 SN000173 SN000187 SN000198 SN000230 SN000245 )
#-------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------


#===================================================================================================================
#===================================================================================================================
#===================================================================================================================
sleep 5
echo ==================================================================================================================================================== >> ${_LOGFILE_}
# Display / Print nohup.out
function_Print_nohup

SystemSerial=$(cat /home/admin/registry/out/serial)
MatchSystemSerial=0
# echo $SystemSerial >> ${_LOGFILE_}
for i in "${SystemSerial_array[@]}"; do 
	# echo "$i" >> ${_LOGFILE_}
	if  [[ $SystemSerial == $i ]]; then
		MatchSystemSerial_int=1
	fi
done
# echo $MatchSystemSerial >> ${_LOGFILE_}
if [ $MatchSystemSerial_int -eq	0 ]; then
	echo $SystemSerial ist nicht Teil der Testphase >> ${_LOGFILE_}
	rm -f ${_LOGFILE_}
	rm -f /home/admin/bin/BusinessOptimum.sh
	exit
fi
#===================================================================================================================
#===================================================================================================================
#===================================================================================================================
#===================================================================================================================

# Start loadTools to ensure that exported variabels are supported
source /home/admin/bin/loadTools

# Remove temporarily established file of BusinessOptimum
rm -f /tmp/BusinessOptimum.tmp
rm -f /tmp/balanceBatteryModules.tmp
rm -f /tmp/swarm-battery-cmd.tmp
rm -f /tmp/swarm-battery-cmd_tail.tmp
rm -f /tmp/BusinessOptimum_config.tmp
rm -f /tmp/BusinessOptimum_config_tail.tmp
rm -f /tmp/BusinessOptimum.config
# Remove any files hindering to execute BusinessLogic
rm -f /home/admin/registry/businessLogic
rm -f /home/admin/registry/chargeStandbyThreshold
rm -f /home/admin/registry/dischargeStandbyThreshold


# Read configuration data of BusinessOptimum.config
function_Read_Configuration


# Initialize Status
counter_discharge_to_standby_int=0	# pre-set value for counter_discharge_to_standby
counter_standby_to_discharge_int=0	# pre-set value for counter_standby_to_discharge
counter_SoC_err_int=0				# pre-set value for counter_SoC_err:				Counts sequeneces of censecutive lines with SoC_err
counter_int=0						# pre-set value for counter:						System-Status Counter
counter_forced_charging_int=0		# pre-set value for counter_forced_charging:		Counts events of performed << forced charging >> routines
Balancing_int=0						# pre-set value for Balancing: 						'0' Balancing not active // '1' Balancing active
ForcedCharging_int=0				# pre-set value for ForcedCharging: 				'0' ForcedCharging not active // '1' ForcedCharging active
System_Running="0"					# pre-set value for System_Running:					'0' System not runing // '1' System running
system_running_req="1"				# pre-set value for normal systems running			# when initalization "112" is used, this will be switched to "9"
Status_Timer_M_int=1  				# pre-set value for Status_Timer_M:					'0' Timer_M sequence deactivated  // '1' Timer_M sequence activated
Status_Timer_M_activated_int=0		# pre-set value for Status_Timer_M_activated:		'0' Status_Timer_M_activated recently NOT activated  // '1' Status_Timer_M_activated recently activated
Status_Timer_M_ini_int=0			# pre-set value for Status_Timer_M_ini:				'0' executes related functions which would be exeuted if Timer_M active
Status_Timer_H_int=1  				# pre-set value for Status_Timer_H:					'0' Timer_H sequence deactivated  // '1' Timer_H sequence activated
Status_Timer_H_activated_int=0		# pre-set value for Status_Timer_H_activated:		'0' Status_Timer_H_activated recently NOT activated  // '1' Status_Timer_H_activated recently activated
Status_Timer_H_ini_int=0			# pre-set value for Status_Timer_H_ini:				'0' executes related functions which would be exeuted if Timer_H active
SoC_module_diff_int=999				# pre-set value for SoC_module_diff:				to display "xxx" if Gen1 system is detected
capa_module_100_int=999				# pre-set value for capa_module_100_int:			to display "xxx" if Gen1 system is detected
U_cell_minV_int=0					# pre-set value for U_cell_minV:					min Voltage of BMU cell
U_cell_maxV_int=0					# pre-set value for U_cell_maxV:					max Voltage of BMU cell
U_cell_diff_V_int=0					# pre-set value for U_cell_diff_V:					difference Voltage of BMU cell
start_up__count_int=500				# start-up__time									during this period system should be up and running
loop_inverter_charge_int=0		    # pre-set value for loop_inverter_scharge			0 set when initially noPVBufferingis removed, counts for charge issues
loop_inverter_discharge_int=0		# pre-set value for loop_inverter_discharge			0 set when initially noPVBufferingis removed, counts for discharge issues
GRID_watchdog__charge_int=0			# pre-set value for GRID_watchdog__charge			0 (CPOL1.OffsetStart will be set to current time); 1 (during specified time CPOL1.OffsetStart will be kept)


if [ -f /home/admin/registry/out/bmmType ]; then
		bmmType=$(cat /home/admin/registry/out/bmmType)
	else
		bmmType="unknown"
fi

if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
		U_cell_minV_min_forced_enable_int=2900	# set-value for U_cell_minV_int:					Threshold when forced charging needed
		U_cell_minV_min_forced_disable_int=3000	# set-value for U_cell_minV_int:					Threshold when forced charging is disabled
	else # Data for SAFT Batteries to be adjusted
		U_cell_minV_min_forced_enable_int=0		# set-value for U_cell_minV_int:					Threshold when forced charging needed
		U_cell_minV_min_forced_disable_int=0	# set-value for U_cell_minV_int:					Threshold when forced charging is disabled
		#U_cell_minV_min_forced_enable_int=3400	# set-value for U_cell_minV_int:					Threshold when forced charging needed
		#U_cell_minV_min_forced_disable_int=3450	# set-value for U_cell_minV_int:					Threshold when forced charging is disabled
fi


# Initialize "/var/log/ChargedFlag" depending on current SoC
# Save last line of batteryLog --- Read data from batteryLog: SoC
tail -3 /var/log/batteryLog.csv | grep -v "^#" | grep "20" | tail -1 > /var/log/batteryLog_tail.csv
SoC=$(awk -F ";" '{print $6}'  /var/log/batteryLog_tail.csv)
# Convert floating/text to integer
printf -v SoC_int %.0f $SoC
# preset based on SoC
if [ $SoC_int -lt $SoC_discharge_int ]; then
		echo "-1" > /var/log/ChargedFlag      ## discharging disabled / charching enabled
	elif  [ $SoC_int -gt $SoC_charge_config_int ] ; then
		echo "1" > /var/log/ChargedFlag       ## discharging enabled / charching disabled
	else
		echo "0" > /var/log/ChargedFlag       ## discharging enabled / charching enabled
fi
# set Chargedflag based on existing file content
ChargedFlag=$(cat /var/log/ChargedFlag) 


# Log configuration data in BusinessOptimum.log
function_Print_Configuration

# Read Gen2 configuration
if [ -f /home/admin/registry/out/gen2 ]; then
		echo "System:                                  Gen2" >> ${_LOGFILE_}
	else
		echo "System:                                  Gen1" >> ${_LOGFILE_}
fi
echo "BMMType:                                " $bmmType >> ${_LOGFILE_}
echo "" >> ${_LOGFILE_}

# Verify Configuration File and advice on changes
function_Verify_Configuration


# Change system_running_req when system does not maintain communication with swarm
if [[ $system_initialization_req == "112" ]]; then
	system_running_req="9"
fi

# Start functions of BusinessOptimum only when System is available/active
System_Initialization=$(swarmBcSend "LLN0.Init.stVal")
echo Systemzustandsabfrage 'LLN0.Init.stVal'... '"'$System_Initialization'"' >> ${_LOGFILE_}
while ( ( [[ $System_Initialization != $system_initialization_req ]] || [ -z "$System_Initialization" ] ) && ( [ $counter_int -le $start_up__count_int ] ) ); do
        if ( [[ $System_Initialization != $system_initialization_req ]] || [ -z "$System_Initialization" ] ); then
			echo $(date +"%Y-%m-%d %T") '||' System noch nicht betriebsbereit  '('$counter_int'/'$start_up__count_int')' '||' '['$system_initialization_req':'$System_Initialization']' >> ${_LOGFILE_}
			counter_int=$(awk '{print ($1+5)}' <<<"${counter_int}")
			sleep 5
		fi
		System_Initialization=$(swarmBcSend ""LLN0.Init.stVal"")
done
echo '->' Systemzustandsabfrage 'LLN0.Init.stVal'... '"'$System_Initialization'"' >> ${_LOGFILE_}
if [ $counter_int -ge $start_up__count_int ]; then
	echo $(date +"%Y-%m-%d %T") '||' System - shutdown >> ${_LOGFILE_}
	sleep 10
	sudo shutdown -r now
	sudo reboot -f
fi

counter_int=0
System_Activated=$(swarmBcSend "LLN0.Mod.ctlVal")
echo Systemaktivierungsabfrage 'LLN0.Mod.ctlVal'... '"'$System_Activated'"' >> ${_LOGFILE_}
while ( [[ $System_Activated != "1" ]] && [ $counter_int -le $start_up__count_int ] ); do
        if [[ $System_Activated != "1" ]]; then
			echo $(date +"%Y-%m-%d %T") '||' System noch nicht aktiviert  '('$counter_int'/'$start_up__count_int')' '||' '[''1:'$$System_Activated']' >> ${_LOGFILE_}
			counter_int=$(awk '{print ($1+5)}' <<<"${counter_int}")
			sleep 5
		fi
		System_Activated=$(swarmBcSend "LLN0.Mod.ctlVal")
done
echo '->' Systemaktivierungsabfrage 'LLN0.Mod.ctlVal'... '"'$System_Activated'"' >> ${_LOGFILE_}
if [ $counter_int -ge $start_up__count_int ]; then
	echo $(date +"%Y-%m-%d %T") '||' System - shutdown >> ${_LOGFILE_}
	sleep 10
	sudo shutdown -r now
	sudo reboot -f
fi

counter_int=0
System_Running=$(swarmBcSend "LLN0.Mod.stVal")
echo Systembetriebsabfrage 'LLN0.Mod.stVal'... '"'$System_Running'"' >> ${_LOGFILE_}
while ( [[ $System_Running != $system_running_req ]] && [ $counter_int -le $start_up__count_int ] ); do
        if [[ $System_Running != $system_running_req ]]; then
			echo $(date +"%Y-%m-%d %T") '||' System noch nicht betriebsbereit  '('$counter_int'/'$start_up__count_int')' '||' '['$system_running_req':'$System_Running']' >> ${_LOGFILE_}
			counter_int=$(awk '{print ($1+5)}' <<<"${counter_int}")
			sleep 5
		fi
		System_Running=$(swarmBcSend "LLN0.Mod.stVal")
done
echo '->' Systembetriebsabfrage 'LLN0.Mod.stVal'... '"'$System_Running'"' >> ${_LOGFILE_}
if [ $counter_int -ge $start_up__count_int ]; then
	echo $(date +"%Y-%m-%d %T") '||' System - shutdown >> ${_LOGFILE_}
	sleep 10
	sudo shutdown -r now
	sudo reboot -f
fi
echo System betriebsbereit und aktiviert >> ${_LOGFILE_}


# CPOL: set back to normal operations
function_CPOL_Reset



# Display / Print Battery Status
if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
	echo "" >> ${_LOGFILE_}
	echo Aktueller Status Batteriemodule >> ${_LOGFILE_}
	echo ------------------------------- >> ${_LOGFILE_}
	function_Print_Battery_Status_1338
fi


# Copy BusinessOptimum.config to temp file for comparison of changes
cp -f ${_BO_ConfigFILE_} /tmp/BusinessOptimum.config

# Copy BusinessOptimum.config to Pi
tail -40 /tmp/BusinessOptimum.config | grep -v "FHEM" > /tmp/BusinessOptimum_FHEM.config
sshpass -p pi scp -o StrictHostKeyChecking=no /tmp/BusinessOptimum_FHEM.config fhem@192.168.0.50:/opt/fhem/log/BusinessOptimum.config





#===================================================================================================================
#==== MAIN ROUTINE =================================================================================================
#===================================================================================================================
while ( [[ $System_Initialization == $system_initialization_req ]] && [[ $System_Running == $system_running_req ]] ); do

	# Verify if ModuleBalancing shall be started
	if [ -f /var/log/ModuleBalancing ]; then
		counter_forced_charging_int=3 					# set counter to 3, whereas ModuleBalancing will be started
	fi
	# Verify if CellBalancing shall be started
	if [ -f /var/log/CellBalancing ]; then
		CellBalancing_int=1
	fi


	# Monitor time to initate certain functions (every Monday at 00:00) - back-up BusinessOptimum.log and start with new BusinessOptimum-old.log
	if ( [ $(date +%u) -eq 1 ] && [ $(date +%H) -eq 0 ] && [ $(date +%M) -eq 0 ] && [ $(date +%S) -le 30 ] ); then
		rm -f /home/admin/log/BusinessOptimum-old.log
		cp -f ${_LOGFILE_} /home/admin/log/BusinessOptimum-old.log
		rm -f ${_LOGFILE_}

		# Log configuration data in new BusinessOptimum.log
		function_Print_Configuration

		# Wait until safely files are copied and removed
		sleep 30
	fi


	# Correct original settings of SoC_max and SoC_charge considering the disbalance of the modules (SoC_module_diff)
	if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
		SoC_max_int=$(awk '{print $1-$2}' <<<"${SoC_max_config_int} ${SoC_module_diff_int}")
		SoC_charge_int=$(awk '{print $1-$2}' <<<"${SoC_charge_config_int} ${SoC_module_diff_int}")
	fi


	# Monitor time to initate certain functions (every hour)
	function_Timer_Hour

	# Kill processes every hour
	if ( [ $Status_Timer_H_int -eq 1 ] && [ $Status_Timer_H_activated_int -eq 0 ] ); then
		# Kill processes
		function_Kill_processes

		Status_Timer_H_activated_int=1
		if [ $Status_Timer_H_ini_int -eq 0 ]; then
			Status_Timer_H_ini_int=1
			Status_Timer_H_int=0
			Status_Timer_H_activated_int=0
		fi
	fi


	# Monitor time to initate certain functions (every minute) 
	function_Timer_Minute

	# Monitor changes on .config / Display "BMU_current_max / Capacity and SoC of all modules" and "check on bigger SoC changes every minute"
	if ( [ $Status_Timer_M_int -eq 1 ] && [ $Status_Timer_M_activated_int -eq 0 ] ); then
		# Update Configuration when BusinessOptimum.config was changed
		function_Compare_Configuration

		# Scan of System Status
		System_Initialization=$(swarmBcSend "LLN0.Init.stVal")
		System_Running=$(swarmBcSend "LLN0.Mod.stVal")

		# Verify if System is still activated, if not, - force shutdown
		System_Activated=$(swarmBcSend "LLN0.Mod.ctlVal")
		if [[ $System_Activated != "1" ]]; then
			echo $(date +"%Y-%m-%d %T") '||' System - shutdown  - Status activation: $System_Activated anstelle von "1" >> ${_LOGFILE_}
			sudo shutdown -r now
			sudo reboot -f
		fi


		# Read cell voltage min/max
		function_Read__Cell_Voltage

		if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
			# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
			function_Read__BMU_Current_SoC_Capa
			echo '                    ||' BMU-SoC: $SoC_module_BMU '|' $SoC_module_1_int $SoC_module_2_int $SoC_module_3_int $SoC_module_4_int $SoC_module_5_int $SoC_module_6_int $SoC_module_7_int $SoC_module_8_int $SoC_module_9_int $SoC_module_10_int '||' BMU_Kapazität: $rem_capa_module_BMU_int mAh '(' $full_capa_module_BMU_int mAh ') ||' Zell-Spannung: $U_cell_minV_int mV '|' BMU-Strom: $BMU_current_max_int mA >> ${_LOGFILE_}
		fi
		# Identify SoC-Sprünge when comparing with the actual capacity
		if [ $SoC_int -lt $capa_module_100_int_low_int ]; then
		     echo SoC-Sprung: SoC: $SoC_int % '|' SoC_Δ: $SoC_module_diff_int % '|' Capacity: $capa_module_100_int_low_int % >> ${_LOGFILE_}
		fi

		Status_Timer_M_activated_int=1
		if [ $Status_Timer_M_ini_int -eq 0 ]; then
			Status_Timer_M_ini_int=1
			Status_Timer_M_int=0
			Status_Timer_M_activated_int=0
		fi
	fi


	#============================================================================================================================
	#============================================================================================================================
	# X  # Balancing of Modules when SoC Difference ≥ 8 && ≤ 15 AND Saturday AND ≥ 10:00 && < 16:00 AND SoC ≥ 60 && SoC ≤ 90
	#    # Balancing of Modules when SoC Difference ≥ 11 && ≤ 15 AND ≥ 10:00 && < 16:00 AND SoC ≥ 60 && SoC ≤ 90
	#    # Balancing of Modules when SoC Difference ≥ 16 && ≤ 35 AND ≥ 10:00 && < 16:00 AND SoC ≥ 50 && SoC ≤ 90
	#    # Balancing of Modules when SoC Difference ≥ 36 && ≤ 60 AND ≥ 10:00 && < 16:00 AND SoC ≥ 25 && SoC ≤ 90
	#    # Balancing of Modules when counter_forced_charging ≥ 3 (or file /var/log/ModuleBalancing available) AND SoC ≤ 90
	#=================================================== ONLY FOR GEN 2 =========================================================
	#============================================================================================================================
	if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
		if ( ( [ $SoC_module_diff_int -ge 8 ] && [ $SoC_module_diff_int -le 15 ] && [ $(date +%u) -eq 6 ] && [ $(date +%H) -ge 10 ] && [ $(date +%H) -lt 16 ] && [ $SoC_int -ge 60 ] && [ $SoC_int -le 90 ] ) || ( [ $SoC_module_diff_int -ge 11 ] && [ $SoC_module_diff_int -le 15 ] && [ $(date +%H) -ge 10 ] && [ $(date +%H) -lt 16 ] && [ $SoC_int -ge 60 ] && [ $SoC_int -le 90 ] ) || ( [ $SoC_module_diff_int -ge 16 ] && [ $SoC_module_diff_int -le 35 ] && [ $(date +%H) -ge 10 ] && [ $(date +%H) -lt 16 ] && [ $SoC_int -ge 50 ] && [ $SoC_int -le 90 ] ) || ( [ $SoC_module_diff_int -ge 36 ] && [ $SoC_module_diff_int -le 60 ] && [ $(date +%H) -ge 10 ] && [ $(date +%H) -lt 16 ] && [ $SoC_int -ge 25 ] && [ $SoC_int -le 90 ] ) || ( [ $counter_forced_charging_int -ge 3 ] && [ $SoC_int -le 90 ] ) ); then
			ModuleBalancing_int=0	# Reset ModuleBalancing, - depening on SoC_module_diff certain power ranges will be enabled for charging
			# Display / Print Battery Status
			echo "" >> ${_LOGFILE_}
			echo Aktueller Status Batteriemodule vor dem Start von Module-Balancing >> ${_LOGFILE_}
			echo ------------------------------------------------------------------ >> ${_LOGFILE_}
			function_Print_Battery_Status_1338

			# Due to safety reasons in case charging would not start: Avoid discharging
			touch /home/admin/registry/noPVBuffering

			# Start Balancing of Modules, and only when system is working/running
			System_Running=$(swarmBcSend "LLN0.Mod.stVal")
			if [[ $System_Running != $system_running_req ]]; then
				echo System ist NICHT betriebsbereit, Module-Balancing wird nicht gestartet  >> ${_LOGFILE_}
				echo ----------------------------------------------------------------------  >> ${_LOGFILE_}
				# Record System Status in log-File prior to restarting, force restart of BusinessOptimum
				function_exit_and_start
			else
				echo System ist betriebsbereit, Module-Balancing wird gestartet >> ${_LOGFILE_}
				echo '----------------------------------------------------------' >> ${_LOGFILE_}
				CPOL1_OffsetDuration_setVal_int=1000		#Preset OffsetDuration: 1000s only, safety aspects
				CPOL1_offset_time_int=$(date +%s)
				CPOL1_OffsetStart_setVal_int=$CPOL1_offset_time_int
			fi

			if ( [ $SoC_module_diff_int -ge 0 ] && [ $SoC_module_diff_int -le 5 ]  ); then		# when requested due to 3x forced chargding or ModuleBalancing
				ModuleBalancing_int=1
			fi
			if ( [ $SoC_module_diff_int -gt 5 ] && [ $SoC_module_diff_int -le 15 ]  ); then
				ModuleBalancing_int=1
			fi
			if ( [ $SoC_module_diff_int -gt 15 ] && [ $SoC_module_diff_int -le 25 ]  ); then
				ModuleBalancing_int=2
			fi
			if ( [ $SoC_module_diff_int -gt 25 ] && [ $SoC_module_diff_int -le 35 ]  ); then
				ModuleBalancing_int=3
			fi
			if ( [ $SoC_module_diff_int -gt 35 ] && [ $SoC_module_diff_int -le 100 ]  ); then
				ModuleBalancing_int=4
			fi


			# Module-Balancing - Phase 1 - 99%
			#####################################################################################################################
			while [ $SoC_int -lt 99 ]; do

					# Read cell voltage min/max
					function_Read__Cell_Voltage

					# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
					function_Read__BMU_Current_SoC_Capa

					# Read time, PVandHH, INV, SoC (invoice and battery log)
					function_Read__Logs_Time_PVHH_INV_SoC

					echo '                    ||' BMU-SoC: $SoC_module_BMU '|' $SoC_module_1_int $SoC_module_2_int $SoC_module_3_int $SoC_module_4_int $SoC_module_5_int $SoC_module_6_int $SoC_module_7_int $SoC_module_8_int $SoC_module_9_int $SoC_module_10_int '||' BMU_Kapazität: $rem_capa_module_BMU_int mAh '(' $full_capa_module_BMU_int mAh ') ||' Zell-Spannung: $U_cell_minV_int mV '|' BMU-Strom: $BMU_current_max_int mA  >> ${_LOGFILE_}

					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' X '|' Module-Balancing $ModuleBalancing_int '(1)' >> ${_LOGFILE_}

					sleep 1


					# Power Determination depending on SoC
						#-------------------------------------------------------------------------------------------
						if [ $ModuleBalancing_int -eq 1 ]; then		# 5% .... 15%
							if [ $SoC_int -lt 80 ]; then
								CPOL1_Wchrg_setMag_f_int=7000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
							if ( [ $SoC_int -ge 80 ] && [ $SoC_int -lt 85 ] ); then
								CPOL1_Wchrg_setMag_f_int=6000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
						fi
						#-------------------------------------------------------------------------------------------
						if [ $ModuleBalancing_int -eq 2 ]; then		# 15% .... 25%
							if [ $SoC_int -lt 75 ]; then
								CPOL1_Wchrg_setMag_f_int=6000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
							if ( [ $SoC_int -ge 75 ] && [ $SoC_int -lt 85 ] ); then
								CPOL1_Wchrg_setMag_f_int=5000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
						fi
						#-------------------------------------------------------------------------------------------
						if [ $ModuleBalancing_int -eq 3 ]; then		# 25% .... 35%
							if [ $SoC_int -lt 75 ]; then
								CPOL1_Wchrg_setMag_f_int=5000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
							if ( [ $SoC_int -ge 75 ] && [ $SoC_int -lt 85 ] ); then
								CPOL1_Wchrg_setMag_f_int=5000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
						fi
						#-------------------------------------------------------------------------------------------
						if [ $ModuleBalancing_int -eq 4 ]; then		# 35% .... 100%
							if [ $SoC_int -lt 75 ]; then
								CPOL1_Wchrg_setMag_f_int=4000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
							if ( [ $SoC_int -ge 75 ] && [ $SoC_int -lt 95 ] ); then
								CPOL1_Wchrg_setMag_f_int=3000
								CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
							fi
						fi
						#-------------------------------------------------------------------------------------------

					if ( [ $SoC_int -ge 85 ] && [ $SoC_int -lt 90 ] ); then
						CPOL1_Wchrg_setMag_f_int=5000
						CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
					fi
					if ( [ $SoC_int -ge 90 ] && [ $SoC_int -lt 95 ] ); then
						CPOL1_Wchrg_setMag_f_int=4000
						CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
					fi
					if ( [ $SoC_int -ge 95 ] && [ $SoC_int -lt 99 ] ); then
						CPOL1_Wchrg_setMag_f_int=3000
						CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
					fi
					if ( [ $SoC_int -ge 99 ] && [ $SoC_int -le 100 ] ); then
						CPOL1_Wchrg_setMag_f_int=2500
						CPOL1_Wchrg_setMag_f_int=$(awk '{print $1+$2}' <<<"${CPOL1_Wchrg_setMag_f_int} ${SoC_int}")
					fi

					CPOL1_OffsetDuration_setVal_int=$(awk '{print $1+20}' <<<"${CPOL1_OffsetDuration_setVal_int}")      #expected 20s for a loop
					swarmBcSend "CPOL1.Wchrg.setMag.f=$CPOL1_Wchrg_setMag_f_int" > /dev/null
					swarmBcSend "CPOL1.OffsetDuration.setVal=$CPOL1_OffsetDuration_setVal_int" > /dev/null
					swarmBcSend "CPOL1.OffsetStart.setVal=$CPOL1_OffsetStart_setVal_int" > /dev/null

					# Check status of inverter, - if not ON ("1") within 60s force shutdown
					function_Check_Inverter_ON

			done

			# Display / Print Battery Status
			echo "" >> ${_LOGFILE_}
			echo Aktueller Status Batteriemodule, nachdem ein SoC von '99%' erreicht wurde >> ${_LOGFILE_}
			echo ----------------------------------------------------------------------- >> ${_LOGFILE_}
			function_Print_Battery_Status_1338

			# full_capa_module_BMU_int: -10, - considering that SoC is not 100.
			full_capa_module_BMU_minus_int=$(awk '{print $1-10}' <<<"${full_capa_module_BMU_int}")


			# Module-Balancing - Phase 2 - Kapazität
			#####################################################################################################################
			echo Module-Balancing 1500 W für 3600 sec '(60min)' oder bis max. $full_capa_module_BMU_minus_int mAh ..... >> ${_LOGFILE_}
			echo '--------------------------------------------------------------------------' >> ${_LOGFILE_}
			time_current_original_sec_epoch_int=$(date +%s)
			time_current_sec_epoch_int=$(date +%s)
			time_offset_sec_int=3600
			time_limit_int=$(awk '{print ($1+$2)}' <<<"${time_current_original_sec_epoch_int} ${time_offset_sec_int}")

			CPOL1_Wchrg_setMag_f_int=1500							# Power
			CPOL1_offset_time_int=$(date +%s)						# new starting point for Inverter
			CPOL1_OffsetDuration_setVal_int=$time_offset_sec_int		# Preset OffsetDuration
			CPOL1_OffsetStart_setVal_int=$CPOL1_offset_time_int

			swarmBcSend "CPOL1.Wchrg.setMag.f=$CPOL1_Wchrg_setMag_f_int" > /dev/null
			swarmBcSend "CPOL1.OffsetDuration.setVal=$CPOL1_OffsetDuration_setVal_int" > /dev/null
			swarmBcSend "CPOL1.OffsetStart.setVal=$CPOL1_OffsetStart_setVal_int" > /dev/null

			while ( [ $time_current_sec_epoch_int -le $time_limit_int ] && [ $rem_capa_module_BMU_int -lt $full_capa_module_BMU_minus_int ] ); do

					# Read cell voltage min/max
					function_Read__Cell_Voltage

					# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
					function_Read__BMU_Current_SoC_Capa

					# Read time, PVandHH, INV, SoC (invoice and battery log)
					function_Read__Logs_Time_PVHH_INV_SoC

					echo '                    ||' BMU-SoC: $SoC_module_BMU '|' $SoC_module_1_int $SoC_module_2_int $SoC_module_3_int $SoC_module_4_int $SoC_module_5_int $SoC_module_6_int $SoC_module_7_int $SoC_module_8_int $SoC_module_9_int $SoC_module_10_int '||' BMU_Kapazität: $rem_capa_module_BMU_int mAh '(' $full_capa_module_BMU_int mAh ') ||' Zell-Spannung: $U_cell_minV_int mV '|' BMU-Strom: $BMU_current_max_int mA '|' noch max. $time_remaining_int sec >> ${_LOGFILE_}

					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' X '|' Module-Balancing '(2)' >> ${_LOGFILE_}

					sleep 1
					time_current_sec_epoch_int=$(date +%s)

					# Check status of inverter, - if not ON ("1") within 60s force shutdown
					function_Check_Inverter_ON

			done

			# Display / Print Battery Status
			echo "" >> ${_LOGFILE_}
			echo Aktueller Status Batteriemodule, nachdem die volle BMU Kapazität erreicht wurde >> ${_LOGFILE_}
			echo ------------------------------------------------------------------------------- >> ${_LOGFILE_}
			function_Print_Battery_Status_1338


			# Module-Balancing - Phase 3 - Strom
			#####################################################################################################################
			echo "" >> ${_LOGFILE_}
			echo Module-Balancing 1500 W für 7200 sec '(120min)' oder bis Strom $BMU_current_max_int'mA' kleiner als -500mA ist ..... >> ${_LOGFILE_}
			echo '-------------------------------------------------------------------------------------------------' >> ${_LOGFILE_}
			time_current_original_sec_epoch_int=$(date +%s)
			time_current_sec_epoch_int=$(date +%s)
			time_offset_sec_int=7200
			time_limit_int=$(awk '{print ($1+$2)}' <<<"${time_current_original_sec_epoch_int} ${time_offset_sec_int}")

			CPOL1_Wchrg_setMag_f_int=1500							# Power
			CPOL1_offset_time_int=$(date +%s)						# new starting point for Inverter
			CPOL1_OffsetDuration_setVal_int=$time_offset_sec_int		# Preset OffsetDuration
			CPOL1_OffsetStart_setVal_int=$CPOL1_offset_time_int

			swarmBcSend "CPOL1.Wchrg.setMag.f=$CPOL1_Wchrg_setMag_f_int" > /dev/null
			swarmBcSend "CPOL1.OffsetDuration.setVal=$CPOL1_OffsetDuration_setVal_int" > /dev/null
			swarmBcSend "CPOL1.OffsetStart.setVal=$CPOL1_OffsetStart_setVal_int" > /dev/null

			while ( [ $time_current_sec_epoch_int -le $time_limit_int ] && [ $BMU_current_max_int -gt -500 ] ); do

					# Read cell voltage min/max
					function_Read__Cell_Voltage

					# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
					function_Read__BMU_Current_SoC_Capa

					# Read time, PVandHH, INV, SoC (invoice and battery log)
					function_Read__Logs_Time_PVHH_INV_SoC

					echo '                    ||' BMU-SoC: $SoC_module_BMU '|' $SoC_module_1_int $SoC_module_2_int $SoC_module_3_int $SoC_module_4_int $SoC_module_5_int $SoC_module_6_int $SoC_module_7_int $SoC_module_8_int $SoC_module_9_int $SoC_module_10_int '||' BMU_Kapazität: $rem_capa_module_BMU_int mAh '(' $full_capa_module_BMU_int mAh ') ||' Zell-Spannung: $U_cell_minV_int mV '|' BMU-Strom: $BMU_current_max_int mA '|' noch max. $time_remaining_int sec >> ${_LOGFILE_}

					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' X '|' Module-Balancing '(3)' >> ${_LOGFILE_}

					sleep 1
					time_current_sec_epoch_int=$(date +%s)

					# Check status of inverter, - if not ON ("1") within 30s force shutdown
					function_Check_Inverter_ON

			done

			# Display / Print Battery Status
			echo "" >> ${_LOGFILE_}
			echo Aktueller Status Batteriemodule, nachdem der Strom kleiner als '-500mA' war >> ${_LOGFILE_}
			echo ------------------------------------------------------------------------- >> ${_LOGFILE_}
			function_Print_Battery_Status_1338


			# Module-Balancing - Phase 4 - Zeit
			#####################################################################################################################
			echo "" >> ${_LOGFILE_}
			echo Finales Module-Balancing 1500 W für 3600 sec '(60min)' >> ${_LOGFILE_}
			echo '------------------------------------------------------' >> ${_LOGFILE_}
			time_current_original_sec_epoch_int=$(date +%s)
			time_current_sec_epoch_int=$(date +%s)
			time_offset_sec_int=3600
			time_limit_int=$(awk '{print ($1+$2)}' <<<"${time_current_original_sec_epoch_int} ${time_offset_sec_int}")

			CPOL1_Wchrg_setMag_f_int=1500							# Power
			CPOL1_offset_time_int=$(date +%s)						# new starting point for Inverter
			CPOL1_OffsetDuration_setVal_int=$time_offset_sec_int		# Preset OffsetDuration
			CPOL1_OffsetStart_setVal_int=$CPOL1_offset_time_int

			swarmBcSend "CPOL1.Wchrg.setMag.f=$CPOL1_Wchrg_setMag_f_int" > /dev/null
			swarmBcSend "CPOL1.OffsetDuration.setVal=$CPOL1_OffsetDuration_setVal_int" > /dev/null
			swarmBcSend "CPOL1.OffsetStart.setVal=$CPOL1_OffsetStart_setVal_int" > /dev/null

			while [ $time_current_sec_epoch_int -le $time_limit_int ]; do

					# Read cell voltage min/max
					function_Read__Cell_Voltage

					# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
					function_Read__BMU_Current_SoC_Capa

					# Read time, PVandHH, INV, SoC (invoice and battery log)
					function_Read__Logs_Time_PVHH_INV_SoC

					echo '                    ||' BMU-SoC: $SoC_module_BMU '|' $SoC_module_1_int $SoC_module_2_int $SoC_module_3_int $SoC_module_4_int $SoC_module_5_int $SoC_module_6_int $SoC_module_7_int $SoC_module_8_int $SoC_module_9_int $SoC_module_10_int '||' BMU_Kapazität: $rem_capa_module_BMU_int mAh '(' $full_capa_module_BMU_int mAh ') ||' Zell-Spannung: $U_cell_minV_int mV '|' BMU-Strom: $BMU_current_max_int mA '|' noch max. $time_remaining_int sec >> ${_LOGFILE_}

					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' X '|' Module-Balancing '(4)' >> ${_LOGFILE_}

					sleep 1
					time_current_sec_epoch_int=$(date +%s)

					# Check status of inverter, - if not ON ("1") within 30s force shutdown
					function_Check_Inverter_ON

			done


			# Display / Print Battery Status
			echo "" >> ${_LOGFILE_}
			echo "" >> ${_LOGFILE_}
			echo Aktueller Status Batteriemodule, nach finalem Module-Balancing '(nach einer weiteren Stunde)' >> ${_LOGFILE_}
			echo ------------------------------------------------------------------------------------------- >> ${_LOGFILE_}
			function_Print_Battery_Status_1338

			# Module-Balancing - Abschluss
			#####################################################################################################################
			echo '----------------------------------------------------------------------' >> ${_LOGFILE_}
			#echo Module-Balancing abgeschlossen - warte 30 min wegen internem Balancing  >> ${_LOGFILE_}
			echo '----------------------------------------------------------------------' >> ${_LOGFILE_}

			# Set Power to 0W
			swarmBcSend "CPOL1.Wchrg.setMag.f=0" > /dev/null
			sleep 0 #SQ# sleep 1800

			# Display / Print Battery Status
			echo "" >> ${_LOGFILE_}
			#echo Aktueller Status Batteriemodule nach Module-Balancing, und Wartezeit von 30min >> ${_LOGFILE_}
			echo ------------------------------------------------------------------------------ >> ${_LOGFILE_}
			function_Print_Battery_Status_1338



			# CPOL: set back to normal operations
			function_CPOL_Reset



			## enable normal charging/discharing
			echo "0" > /var/log/ChargedFlag

			# force reading of U_V and SoC
			#Status_Timer_M_ini_int=0
			Status_Timer_M_int=1
			Status_Timer_M_activated_int=0
			Status_Timer_H_ini_int=1
			Status_Timer_H_int=0
			Status_Timer_H_activated_int=0

			# reset counter for forced charging when balancing has been completed
			counter_forced_charging_int=0
			rm -f /var/log/ModuleBalancing

		fi
	fi
	#====================================================================================================================
	# End of  Balancing of Modules
	#====================================================================================================================


	#====================================================================================================================
	#====================================================================================================================
	# Y  # Balancing of Cells when Cell Voltage Difference ≥ 35mV AND ≥ 10:00 && < 16:00 AND SoC ≥ 50 && SoC ≤ 90 
	#    # Balancing of Cells when CellBalancing=1 (File /var/log/CellBalancing available)
	#====================================================================================================================
	#====================================================================================================================
	if ( [[ $bmmType == "sony" ]] || [[ $bmmType == "Synerion48EGen3_ESSG2" ]] ); then
		if ( [ $U_cell_diff_V_int -ge 35 ] && [ $(date +%H) -ge 10 ] && [ $(date +%H) -lt 16 ] && [ $SoC_int -ge 50 ] && [ $SoC_int -le 90 ] || ( [ $CellBalancing_int -ge 1 ] ) ); then
			# Start Balancing of Cells, only when system is working/running
			System_Running=$(swarmBcSend "LLN0.Mod.stVal")
			if [[ $System_Running != $system_running_req ]]; then
				echo System ist NICHT betriebsbereit, Cell-Balancing wird nicht gestartet  >> ${_LOGFILE_}
				echo --------------------------------------------------------------------  >> ${_LOGFILE_}
				# Record System Status in log-File prior to restarting, force restart of BusinessOptimum
				function_exit_and_start
			else
				echo "" >> ${_LOGFILE_}
				echo System ist betriebsbereit, Cell-Balancing wird gestartet >> ${_LOGFILE_}
				echo -------------------------------------------------------- >> ${_LOGFILE_}
				Balancing_int=1
				swarmBcBalanceBatteryModules <<< j > /dev/null
				pid=$!
				time=$(date +%T)
				echo $(date +"%Y-%m-%d %T") '|' Cell-Balancing Funktion aufgerufen '('PID=$pid')' >> ${_LOGFILE_}
				sleep 50
				Status_Timer_M_activated_int=0
				# Display / Print Battery Status
				if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
					echo "" >> ${_LOGFILE_}
					echo Aktueller Status Batteriemodule >> ${_LOGFILE_}
					echo ------------------------------- >> ${_LOGFILE_}
					function_Print_Battery_Status_1338
				fi
			fi
		fi
	fi

	#Verify if Balancing is still active
	while [ $Balancing_int -eq 1 ] ; do
		rm -f /tmp/balanceBatteryModules.tmp
		ps $pid | grep $pid > /tmp/balanceBatteryModules.tmp
		if [ ! -s /tmp/balanceBatteryModules.tmp ]; then
		    Balancing_int=0
			time=$(date +%T)
			echo $(date +"%Y-%m-%d %T") '|' Balancing Funktion deaktiviert >> ${_LOGFILE_}
		fi
		time=$(date +%T)

		# Read time, PVandHH, INV, SoC (invoice and battery log)
		function_Read__Logs_Time_PVHH_INV_SoC

		# Read cell voltage min/max
		function_Read__Cell_Voltage

		if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
			# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
			function_Read__BMU_Current_SoC_Capa
			echo '                    ||' BMU-SoC: $SoC_module_BMU '|' $SoC_module_1_int $SoC_module_2_int $SoC_module_3_int $SoC_module_4_int $SoC_module_5_int $SoC_module_6_int $SoC_module_7_int $SoC_module_8_int $SoC_module_9_int $SoC_module_10_int '||' BMU_Kapazität: $rem_capa_module_BMU_int mAh '(' $full_capa_module_BMU_int mAh ') ||' Zell-Spannung: $U_cell_minV_int mV '|' BMU-Strom: $BMU_current_max_int mA  >> ${_LOGFILE_}
		fi

		echo $(date +"%Y-%m-%d %T") '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' Y '|' Cell-Balancing '('PID=$pid')' >> ${_LOGFILE_}

		sleep 60

		Status_Timer_H_ini_int=1
		Status_Timer_H_int=0
		Status_Timer_H_activated_int=0

		# reset counter for forced charging when balancing has been completed
		counter_forced_charging_int=0
		rm -f  /var/log/CellBalancing

	done
	#====================================================================================================================
	# End of  Balancing of Cells
	#====================================================================================================================


	#####################################################################################################################
	#====================================================================================================================
	# Sequences of normal operations if module-balancing and cell-balancing is not needed.
	#====================================================================================================================
	#####################################################################################################################

	# Verify if "/home/admin/registry/noPVBuffering" exists
	if [ ! -f /home/admin/registry/noPVBuffering ]; then
			# File does NOT exist
			Status="PVBuffering"
		else
			Status="noPVBuffering"
	fi


	# Read time, PVandHH, INV, SoC (invoice and battery log)
	function_Read__Logs_Time_PVHH_INV_SoC



	# From time to time observed 0 SoC, therefore that will be ignored by avoiding that status and ending the loop of that 'while' operation
	if ( [ $SoC_int -le $SoC_err_int ] && [ $counter_SoC_err_int -lt 10 ] ); then
			counter_SoC_err_int=$(awk '{print $1+1}' <<<"${counter_SoC_err_int}")
			echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|'   '|' SoC observed with '≤' $SoC_err_int %: $counter_SoC_err_int'/'10 >> ${_LOGFILE_}
			continue
		else
			counter_SoC_err_int=0
	fi


	# Set/Reset ChargedFlag: 1 '(fully charged -> no charging possible)' -> 0 '(partially charged -> charging possible)'
	# 						-1 '(empty -> charging is forced)'
	if [ $SoC_int -ge $SoC_max_int ]; then
			echo "1" > /var/log/ChargedFlag      ## stop charging
		elif ( [ $SoC_int -le $SoC_charge_int ] && [ $SoC_int -ge $SoC_discharge_int ] && [[ $ChargedFlag == "1" ]] ); then
			echo "0" > /var/log/ChargedFlag      ## enable charging/discharing
		elif ( [ $SoC_int -le $SoC_charge_int ] && [ $SoC_int -ge $SoC_discharge_int ] && [[ $ChargedFlag == "-1" ]] ); then
			echo "0" > /var/log/ChargedFlag      ## enable charging/discharing
		elif [ $SoC_int -le $SoC_min_int ] ; then
			echo "-1" > /var/log/ChargedFlag     ## enable forced charging
	fi

    # set Chargedflag based on existing file content (changed conditions of previous settings)
    ChargedFlag=$(cat /var/log/ChargedFlag) 


	#====================================================================================================================
	#====================================================================================================================
	# Z  # ChargedFlag = -1 (Battery empty): NACHLADEN (FORCED CHARGING) < SoC_discharge ODER < U_cell_minV_min_forced_enable
	#====================================================================================================================
	#====================================================================================================================


	if ( ( [[ $ChargedFlag == "-1" ]] && [ $PVandHH_int -gt $chargeStandbyThreshold_hyst_int ] ) || [ $U_cell_minV_int -le $U_cell_minV_min_forced_enable_int ] ); then
		# Display / Print Battery Status
		if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
			echo "" >> ${_LOGFILE_}
			echo Aktueller Status Batteriemodule: SoC $SoC_int % '<' $SoC_discharge_int % '('Initialisierungsphase')' >> ${_LOGFILE_}
			echo Aktueller Status Batteriemodule: SoC $SoC_int % '≤' $SoC_min_int % bzw. Zell-Spannung zu niedrig $U_cell_minV_int mV '≤' $U_cell_minV_min_forced_enable_int mV ? >> ${_LOGFILE_}
			echo -------------------------------------------------------------------------------------------------- >> ${_LOGFILE_}
			function_Print_Battery_Status_1338
		fi

		# Due to safety reasons in case charging would not start: Avoid discharging
		touch /home/admin/registry/noPVBuffering

		# Start charging the battery only up to SoC_discharge, and when available
		System_Running=$(swarmBcSend "LLN0.Mod.stVal")
        if [[ $System_Running != $system_running_req ]]; then
			echo System ist NICHT betriebsbereit, Laden wird nicht gestartet  >> ${_LOGFILE_}
		    echo ----------------------------------------------------------- >> ${_LOGFILE_}
			# Record System Status in log-File prior to restarting, force restart of BusinessOptimum
			function_exit_and_start
		 else
			echo System ist betriebsbereit, Nachladen wird gestartet - min. 10 min  >> ${_LOGFILE_}
		    echo ---------------------------------------------------------------- >> ${_LOGFILE_}
			# set charge command
			swarmBcSend "CPOL1.Wchrg.setMag.f=5555" > /dev/null
			swarmBcSend "CPOL1.OffsetDuration.setVal=3600" > /dev/null			# max. 1 hour
			swarmBcSend "CPOL1.OffsetStart.setVal=$(date +%s)" > /dev/null
			ForcedCharging_int=1
		fi

		time_current_original_sec_epoch_int=$(date +%s)
		time_current_sec_epoch_int=$(date +%s)
		time_offset_sec_int=600 # 10min
		time_limit_int=$(awk '{print ($1+$2)}' <<<"${time_current_original_sec_epoch_int} ${time_offset_sec_int}")

		while ( [ $SoC_int -lt $SoC_discharge_int ] || [ $U_cell_minV_int -le $U_cell_minV_min_forced_disable_int ] || [ $time_current_sec_epoch_int -le $time_limit_int ] ); do
		    # Monitor time to initate certain functions (every minute)
			function_Timer_Minute

			# Read cell voltage min/max, BMU_current_max and SoC of all modules (SoC/capacity for Gen2 only)
			if ( [ $Status_Timer_M_int -eq 1 ] && [ $Status_Timer_M_activated_int -eq 0 ] ); then

				# Read cell voltage min/max
				function_Read__Cell_Voltage

				if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
					# Read BMU_current_max / Capacity and SoC of all modules (for Gen2 only)
					function_Read__BMU_Current_SoC_Capa
					echo '                    ||' BMU-SoC: $SoC_module_BMU '|' $SoC_module_1_int $SoC_module_2_int $SoC_module_3_int $SoC_module_4_int $SoC_module_5_int $SoC_module_6_int $SoC_module_7_int $SoC_module_8_int $SoC_module_9_int $SoC_module_10_int '||' BMU_Kapazität: $rem_capa_module_BMU_int mAh '(' $full_capa_module_BMU_int mAh ') ||' Zell-Spannung: $U_cell_minV_int mV '|' BMU-Strom: $BMU_current_max_int mA  >> ${_LOGFILE_}
				fi

				Status_Timer_M_activated_int=1

				if [ $Status_Timer_M_ini_int -eq 0 ]; then
					Status_Timer_M_ini_int=1
					Status_Timer_M_int=0
					Status_Timer_M_activated_int=0
				fi
			fi

			# Read time, PVandHH, INV, SoC (invoice and battery log)
			function_Read__Logs_Time_PVHH_INV_SoC	

			echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' Z '|' Nachladen >> ${_LOGFILE_}
		    sleep 1
			time_current_sec_epoch_int=$(date +%s)

			# Check status of inverter, - if not ON ("1") within 30s force shutdown
			function_Check_Inverter_ON

		done


		if [ $ForcedCharging_int -eq 1 ]; then
			echo Nachladen abgeschlossen >> ${_LOGFILE_}
			echo ----------------------- >> ${_LOGFILE_}


			# CPOL: set back to normal operations
			function_CPOL_Reset


			ForcedCharging_int=0

			# Display / Print Battery Status
			if ( [ -f /home/admin/registry/out/gen2 ] && [[ $bmmType == "sony" ]] ); then
				echo "" >> ${_LOGFILE_}
				echo Aktueller Status Batteriemodule: SoC $SoC_int % '≥' $SoC_discharge_int % bzw. Zell-Spannung $U_cell_minV_int mV '>' $U_cell_minV_min_forced_disable_int mV >> ${_LOGFILE_}
				echo ------------------------------------------------------------------------------------- >> ${_LOGFILE_}
				function_Print_Battery_Status_1338
			fi

			## enable normal charging/discharing
			echo "0" > /var/log/ChargedFlag

			# Count events of forced charching
			counter_forced_charging_int=$(awk '{print $1+1}' <<<"${counter_forced_charging_int}")

		fi

	#====================================================================================================================
	# A1 # PVandHH ≥ dischargeStandbyThreshold_int  AND SoC > SoC_discharge: AUSSPEICHERN (Discharge)
	#====================================================================================================================
	elif ( [ $PVandHH_int -ge $dischargeStandbyThreshold_int ] && [ $SoC_int -gt $SoC_discharge_int ] ); then
		if [[ $Status == "noPVBuffering" ]]; then
				rm -f /home/admin/registry/noPVBuffering
				loop_inverter_discharge_int=0
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' A1 '|' AUSSPEICHERN - rm noPVBuffering >> ${_LOGFILE_}
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' A1 '|' AUSSPEICHERN >> ${_LOGFILE_}
				# Check status of inverter, - if not ON ("1") after 10 loops force shutdown
				function_Check_Inverter_ON_discharge_60_loops
		fi

		counter_discharge_to_standby_int=0
		counter_standby_to_discharge_int=0


	#====================================================================================================================
	# A2 # PVandHH ≥ dischargeStandbyThreshold_int  AND SoC ≤ SoC_discharge: STANDBY (Sleep)
	#====================================================================================================================
	elif ( [ $PVandHH_int -ge $dischargeStandbyThreshold_int ] && [ $SoC_int -le $SoC_discharge_int ] ); then
		if [[ $Status == "PVBuffering" ]]; then
				touch /home/admin/registry/noPVBuffering
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' A2 '|' STANDBY '(Sleep):' SoC≤$SoC_discharge_int% - touch noPVBuffering >> ${_LOGFILE_}
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' A2 '|' STANDBY '(Sleep):' SoC≤$SoC_discharge_int% >> ${_LOGFILE_}
		fi

		counter_discharge_to_standby_int=0
		counter_standby_to_discharge_int=0

	#====================================================================================================================
	# B1 # PVandHH ≥ dischargeStandbyThreshold_delay_int  AND SoC > SoC_discharge: AUSSPEICHERN nach Delay (Discharge)
	#====================================================================================================================
	elif ( [ $PVandHH_int -ge $dischargeStandbyThreshold_delay_int ] && [ $SoC_int -gt $SoC_discharge_int ] ); then
		if [[ $Status == "noPVBuffering" ]]; then
				if [ $counter_standby_to_discharge_int -ge $counter_standby_to_discharge_max_int ]; then
						rm -f /home/admin/registry/noPVBuffering
						loop_inverter_discharge_int=0
						echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' B1 '|' AUSSPEICHERN - rm noPVBuffering >> ${_LOGFILE_}
					else
						counter_standby_to_discharge_int=$(awk '{print $1+$2}' <<<"${counter_standby_to_discharge_int} ${counter_increment_total_int}")
						echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' B1 '|' STANDBY - Wartezeit vor AUSSPEICHERN: '('$counter_standby_to_discharge_int'/'$counter_standby_to_discharge_max_int')sec' >> ${_LOGFILE_}
				fi
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' B1 '|' AUSSPEICHERN >> ${_LOGFILE_}
				# Check status of inverter, - if not ON ("1") after 10 loops force shutdown
				function_Check_Inverter_ON_discharge_60_loops

				counter_standby_to_discharge_int=0
		fi

		counter_discharge_to_standby_int=0

	#====================================================================================================================
	# B2 # PVandHH ≥ dischargeStandbyThreshold_delay_int  AND SoC ≤ SoC_discharge: STANDBY (Sleep)
	#====================================================================================================================
	elif ( [ $PVandHH_int -ge $dischargeStandbyThreshold_delay_int ] && [ $SoC_int -le $SoC_discharge_int ] ); then
		if [[ $Status == "PVBuffering" ]]; then
				touch /home/admin/registry/noPVBuffering
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' B2 '|' STANDBY '(Sleep):' SoC≤$SoC_discharge_int% - touch noPVBuffering >> ${_LOGFILE_}
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' B2 '|' STANDBY '(Sleep):' SoC≤$SoC_discharge_int% >> ${_LOGFILE_}
		fi

        counter_discharge_to_standby_int=0
        counter_standby_to_discharge_int=0

	#====================================================================================================================
	# C1 # PVandHH ≥ dischargeStandbyThreshold_hyst_int  AND SoC > SoC_discharge: AUSSPEICHERN-Hysterse (Discharge)
	#====================================================================================================================
	elif ( [ $PVandHH_int -ge $dischargeStandbyThreshold_hyst_int ] && [ $SoC_int -gt $SoC_discharge_int ] ); then
		if [[ $CPOL1_Mod == "1" ]]; then
				# Inverter ON, - continue charging within the hysteresis
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' C1 '|' AUSSPEICHERN >> ${_LOGFILE_}
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' C1 '|' STANDBY >> ${_LOGFILE_}
		fi

		counter_discharge_to_standby_int=0
		counter_standby_to_discharge_int=0


	#====================================================================================================================
	# C2 # PVandHH ≥ dischargeStandbyThreshold_hyst_int  AND SoC ≤ SoC_discharge: STANDBY (Sleep)
	#====================================================================================================================
	elif ( [ $PVandHH_int -ge $dischargeStandbyThreshold_hyst_int ] && [ $SoC_int -le $SoC_discharge_int ] ); then
     	if [[ $Status == "PVBuffering" ]]; then
				touch /home/admin/registry/noPVBuffering
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' C2 '|' STANDBY '(Sleep):' SoC≤$SoC_discharge_int% - touch noPVBuffering >> ${_LOGFILE_}
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' C2 '|' STANDBY '(Sleep):' SoC≤$SoC_discharge_int% >> ${_LOGFILE_}
	    fi

        counter_discharge_to_standby_int=0
        counter_standby_to_discharge_int=0


	#====================================================================================================================
	# D1 # PVandHH > 0: STANDBY
	#====================================================================================================================
	elif [ $PVandHH_int -gt 0 ]; then
		if [[ $Status == "PVBuffering" ]]; then
				if [ $counter_discharge_to_standby_int -ge $counter_discharge_to_standby_max_int ]; then
					touch /home/admin/registry/noPVBuffering
					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' D1 '|' STANDBY - touch noPVBuffering >> ${_LOGFILE_}
				else
					counter_discharge_to_standby_int=$(awk '{print $1+$2}' <<<"${counter_discharge_to_standby_int} ${counter_increment_total_int}")
					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' D1 '|' AUSSPEICHERN - Nachlaufzeit vor STANDBY: '('$counter_discharge_to_standby_int'/'$counter_discharge_to_standby_max_int')sec' >> ${_LOGFILE_}
				fi
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' D1 '|' STANDBY >> ${_LOGFILE_}
		fi

		counter_standby_to_discharge_int=0


	#====================================================================================================================
	# D2 # PVandHH > chargeStandbyThreshold_hyst_int: STANDBY
	#====================================================================================================================
	elif [ $PVandHH_int -gt $chargeStandbyThreshold_hyst_int ]; then
		if [[ $Status == "PVBuffering" ]]; then
				if [ $counter_discharge_to_standby_int -ge $counter_discharge_to_standby_max_int ]; then
					touch /home/admin/registry/noPVBuffering
					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' D2 '|' STANDBY - touch noPVBuffering >> ${_LOGFILE_}
				else
					counter_discharge_to_standby_int=$(awk '{print $1+$2}' <<<"${counter_discharge_to_standby_int} ${counter_increment_total_int}")
					echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' D2 '|' EINSPEICHERN - Nachlaufzeit vor STANDBY: '('$counter_discharge_to_standby_int'/'$counter_discharge_to_standby_max_int')sec' >> ${_LOGFILE_}
				fi
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' D2 '|' STANDBY >> ${_LOGFILE_}
		fi

		counter_standby_to_discharge_int=0

	#====================================================================================================================
	# E  # PVandHH > chargeStandbyThreshold_int: EINSPEICHERN-Hysterse (Charge)
	#====================================================================================================================
	elif [ $PVandHH_int -gt $chargeStandbyThreshold_int ]; then
		if [[ $CPOL1_Mod == "1" ]]; then
				if [[ $ChargedFlag == "1" ]]; then
						if [[ $Status == "PVBuffering" ]]; then
								touch /home/admin/registry/noPVBuffering
								echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' E  '|' STANDBY - touch noPVBuffering >> ${_LOGFILE_}
							else
								echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' E  '|' STANDBY >> ${_LOGFILE_}
						fi
					else
						echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' E  '|' EINSPEICHERN >> ${_LOGFILE_}
				fi
			else
				echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' E  '|' STANDBY >> ${_LOGFILE_}
		fi

		counter_discharge_to_standby_int=0
		counter_standby_to_discharge_int=0
   	#====================================================================================================================

   else
	#====================================================================================================================
	# F # PVandHH ≤ chargeStandbyThreshold_int: EINSPEICHERN (CHARGE)
	#====================================================================================================================
		if ( [[ $ChargedFlag == "-1" ]] || [[ $ChargedFlag == "0" ]] ); then
				if [[ $Status == "noPVBuffering" ]]; then
						rm -f /home/admin/registry/noPVBuffering
						loop_inverter_charge_int=0
						echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' F  '|' EINSPEICHERN - rm noPVBuffering >> ${_LOGFILE_}
					else
						echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' F  '|' EINSPEICHERN >> ${_LOGFILE_}
				fi
			else
			# disable additional charging when reached the max value 'ChargedFlag'
				if [[ $Status == "PVBuffering" ]]; then
						touch /home/admin/registry/noPVBuffering
						echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' F  '|' STANDBY - touch noPVBuffering >> ${_LOGFILE_}
					else
						echo $time '||' Cell_Δ: $U_cell_diff_V_int mV '|' SoC_Δ: $SoC_module_diff_int % '|' PVundHH: $PVandHH_int W '|' Capa_% $capa_module_100_int % '|' SoC: $SoC_int % '|' ChargedFlag: $ChargedFlag '|' INV: $CPOL1_Mod '|' INV: $Inv_Request W '|' F  '|' STANDBY >> ${_LOGFILE_}
				fi
		fi

		counter_discharge_to_standby_int=0
		counter_standby_to_discharge_int=0

fi


sleep $loop_delay_int


done

# Record System Status in log-File prior to restarting, force restart of BusinessOptimum
function_exit_and_start
