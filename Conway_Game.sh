#!/bin/bash

#Author: Michał Węsiora
#Index : 193126
#Created On: 29.04.2023
#Last Modified On: 7.05.2023
#Version: 1.0

#Description: This program is a simulator for a Conway Game of Life

#Licensed under GPL (see /usr/share/common-licenses/GPL for more details
#or contact # the Free Software Fundation for a copy)



#main grid
declare -A GRID
#grid to store next state
declare -A NEXT_GRID
MAX_WIDTH=1000
MAX_HEIGHT=1000
ALIVE=1
DEAD=0
REFRESH_RATE=0.2

#Display help info
function help() {
	echo "
	Possible options :
	-h : display help
	-v : display app and author info
	
	Using app : first user has to type grid size, then set starting grid state, where each
	position is separated by comma. 0 means dead cell, 1 - alive. When the simulation starts, press any key to end"
}

#Display app and author info
function ver() {
	echo "
	Author: Michał Węsiora
	Index : 193126
	Created On: 29.04.2023
	Last Modified On: 7.05.2023
	Version: 1.0"
}

#Handling incorrect option
function bad_command() {
	echo "unknown command"
	exit 0
}

#Compute the next state of the grid
function next_state() {
    	for ((Y=1; Y<=GRID_HEIGHT; Y++)); do
        	for ((X=1; X<=GRID_WIDTH; X++)); do
			count_neighbors

            		if [[ ${GRID[$Y,$X]} -eq $DEAD && $COUNT -eq 3 ]]; then
                		NEXT_GRID[$Y,$X]=$ALIVE
			elif [[ ${GRID[$Y,$X]} -eq $ALIVE && ($COUNT -lt 2 || $COUNT -gt 3) ]]; then
                		NEXT_GRID[$Y,$X]=$DEAD
			else
				NEXT_GRID[$Y,$X]=${GRID[$Y,$X]}
            		fi
        	done
	done
}

#Count the number of live neighbors of current X,Y position
function count_neighbors() {	
	COUNT=0
    	for ((I=-1; I<=1; I++)); do
		if [[ $((Y+I)) -lt 1 || $((Y+I)) -gt $GRID_HEIGHT ]]; then
                	continue
            	fi

        	for ((J=-1; J<=1; J++)); do
			if [[ ($I -eq 0 && $J -eq 0) || $((X+J)) -lt 1 || $((X+J)) -gt $GRID_WIDTH ]]; then
                		continue
            		fi

            		if [[ ${GRID[$((Y+I)),$((X+J))]} -eq $ALIVE ]]; then
               			 COUNT=$((COUNT + 1))
            		fi
        	done
    	done
}

#Display the grid
function display_grid() {
    	local GRID_STR=""

    	for ((Y=1; Y<=GRID_HEIGHT; Y++)); do
		for ((X=1; X<=GRID_WIDTH; X++)); do
			if [[ ${GRID[$Y,$X]} -eq 1 ]]; then
                		GRID_STR="${GRID_STR}${GRID[$Y,$X]}"
			else
				GRID_STR="${GRID_STR} "
			fi
        	done

        	GRID_STR="${GRID_STR}\n"
    	done

    	echo -e "$GRID_STR"

	#Going back to top for the next display	
	for ((L=1; L<=$GRID_HEIGHT+1; L++)); do
		tput cuu1
	done
}

#Take from user starting grid state
function check_grid() {
	local GRID_STR=""

	for ((Y=1; Y<=GRID_HEIGHT; Y++)); do
		GRID_STR="${GRID_STR}$DEAD"
		for ((X=2; X<=GRID_WIDTH; X++)); do
			GRID_STR="${GRID_STR},$DEAD"
		done
		GRID_STR="${GRID_STR}\n"
	done

	#Display in zenity editable grid, TEXT_INFO stores text after pressing ok
	TEXT_INFO=`echo -e "$GRID_STR" | zenity --text-info --editable --font="monospace" --title="Grid state" --text="Set starting grid" --width=1024 --height=768`
	QUIT=$?

	#Check if input is correct
	#IFS is a field separator
	IFS=$'\n'
	I=1
	for LINE in $TEXT_INFO; do
    		IFS=$','
    		J=1
    		for VALUE in $LINE; do
        		if [[ $VALUE != "0" && $VALUE != "1" ]]; then
	    			CHECK="false"
        		fi
        		((J++))
    		done

		#After looping through line, J should equal GRID_WIDTH + 1
    		if [[ $J -ne $((GRID_WIDTH+1)) ]]; then
	    		CHECK="false"
    		fi
    		((I++))
	done

	#After looping through all lines, I should equal GRID_HEIGHT + 1
	if [[ $I -ne $((GRID_HEIGHT+1)) ]]; then
		CHECK="false"
	fi
}

#Assign correct grid into GRID table
function input_grid() {
	#IFS is a field separator
	IFS=$'\n'
	I=1
	for LINE in $TEXT_INFO; do
    		IFS=$','
    		J=1
    		for VALUE in $LINE; do
			GRID["$I,$J"]=$VALUE
        		((J++))
    		done
    	((I++))
	done
}

#Execute options
while getopts "hv" OPT; do
	case $OPT in
		h) help;;
		v) ver;;
		*) bad_command;;
	esac
	OPTION="true"
done

#If there were any options (as there are only options after each program ends) - end script
if [[ $OPTION == "true" ]]; then
	exit 0
fi

#Take user input
while [[ ($GRID_WIDTH -lt 1 || $GRID_WIDTH -gt $MAX_WIDTH) && $QUIT -ne 1 ]]; do
	GRID_WIDTH=`zenity --entry --title "Grid size" --text "Type width"`
	QUIT=$?
done

while [[ ($GRID_HEIGHT -lt 1 || $GRID_HEIGHT -gt $MAX_HEIGHT) && $QUIT -ne 1 ]]; do
	GRID_HEIGHT=`zenity --entry --title "Grid size" --text "Type height"`
	QUIT=$?
done

#Take starting grid state
CHECK="true"
if [[ $QUIT -ne 1 ]]; then
	check_grid
fi

while [[ $CHECK == "false" && $QUIT -ne 1 ]]; do
	CHECK="true"
	check_grid
done

if [[ $QUIT -eq 1 ]]; then
	exit 0
fi
QUIT=""

#Pass accepted grid
input_grid

#Main loop
while [[ $QUIT == "" ]]; do
	display_grid
	next_state

    	#Update the grid
    	for ((Y=1; Y<=GRID_HEIGHT; Y++)); do
        	for ((X=1; X<=GRID_WIDTH; X++)); do
            		GRID[$Y,$X]=${NEXT_GRID[$Y,$X]}
        	done
    	done

	read -t $REFRESH_RATE -n 1 QUIT
done

#Go down in lines after the end
echo -e "\033[${GRID_HEIGHT}B"
