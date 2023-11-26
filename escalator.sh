#!/bin/bash

# Reset
NO_COLOR='\033[0m'       # Text Reset

# Regular Colors
RED='\033[0;31m'          # Red
GREEN='\033[0;32m'        # Green
YELLOW='\033[0;33m'       # Yellow



check_git_creds () {

	echo ""
	echo -e "${YELLOW}[*] Looking for credentials stored in git config files...${NO_COLOR}"
	echo ""

	readarray -t repos <<< "$(find / -type d -name ".git" 2>/dev/null -exec dirname {} \;)"

	echo "	Found ${#repos[@]} Git repos. Checking for creds in .git/config files..."
	echo""

	for repo in "${repos[@]}"
	do
		git_config_path=${repo}"/.git/config"
		possible_creds=$(cat "$git_config_path" | grep -iwoE '(http|https)://[a-z0-9._%+-]+:[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}' 2>/dev/null)
		if [[ -n "$possible_creds" ]]
		then
		    	echo -e "	${GREEN}Possible credentials found!!${NO_COLOR}"
			echo ""
			echo "	$git_config_path:"
		    	username=$(echo "$possible_creds" | awk -F'[:/@]' '{print $4}')
		    	password=$(echo "$possible_creds" | awk -F'[:/@]' '{print $5}')
		    	echo -e "	Username:	${GREEN}$username${NO_COLOR}"
		    	echo -e "	Password:	${GREEN}$password${NO_COLOR}"
		    	echo ""
		fi
	done

}


check_sudo_commands () {

	if [[ $user_pass -ne 1 ]]
	then
		echo ""
		echo -e "${RED}[!] Flag '-p' not provided. Skipping allowed sudo commands check...${NO_COLOR}"
		echo ""
		return 1
	fi

	echo ""
	echo -e "${YELLOW}[*] Checking for allowed sudo commands...${NO_COLOR}"
	echo ""

	permissions=$(sudo -l | grep -A 9999 -E 'User .* may run the following commands.*:' | tail -n +2)
	if [[ -z "$permissions" ]]
	then
		echo "	User $(whoami) seems not to have any sudo capabilities..."
	else
		echo "	User $(whoami) has the following sudo capabilities:"
		echo -e "	${GREEN}$permissions${NO_COLOR}"
	fi

}


while getopts "hp" option; do
	case $option in
		h)
			echo ""
			echo "This script will test for several common Linux priv escalation techniques."
			echo ""
			echo "Options:"
			echo "-p: To indicate you know your current user's password. It is required to test for allowed sudo commands"
			echo ""
			exit
			;;
		p)
			user_pass=1
			;;
	esac
done


check_sudo_commands
check_git_creds
