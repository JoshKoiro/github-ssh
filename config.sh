#!/bin/bash
# Color Definitions based on the numerical value used in the tput command
SUCCESS=14
ERROR=9
INFO=5
QUESTION=3

# Function to set colors in the script
color() {
	tput setaf $1
	echo -e $2
	tput sgr0
}

setColor() {
	tput setaf $1
}

resetColor() {
	tput sgr0
}

color ${INFO} "Killing all existing ssh-agent processses...\n"
pkill ssh-agent
color 5 "\nThis script will walk you through the process of setting up Github authentication on your system using ssh.\n\n"

setColor ${QUESTION}
read -p "Would you like to create a new key? (y/n) " newKey
resetColor
if [ "$newKey" == "y" ]; then
	color ${INFO} "\nCreating new key...\n"
	setColor ${QUESTION}
	read -p "Please enter your email address that is associated with your Github account: " email
	echo -e '\n'
	read -p "Please enter the name of the key you would like to create (i.e. github): " keyName
	color ${INFO}
	ssh-keygen -t rsa -b 4096 -C $email -f ${HOME}"/.ssh/"${keyName}
	resetColor
elif [ "$newKey" == "n" ]; then
	color ${INFO} "\nNo new keys created..."
else
	color ${ERROR} "\nInvalid data received. Please type y or n in prompt."
	exit 1
fi

echo -e "\n"
ls ~/.ssh
echo -e "\n"
setColor ${QUESTION}
read -p "Above is the available keys generated on the system. Please type the name of the one created for Github: " authFile
resetColor
echo -e "\n"
color ${SUCCESS} "Below is your public key. Please copy this entirety of the contents below to enter on Github when you create the ssh key.\n"

cat ~/.ssh/$authFile.pub

echo -e "\n"
setColor ${QUESTION}
read -p "Would you like to start ssh-keygen on login? (y/n) " startup
resetColor
echo -e "\n"

if [ "$startup" == "y" ]; then
	color ${INFO} "\nCreating .bashrc.backup..."
	cp ~/.bashrc ~/.bashrc.bak
	color ${INFO} "\nAdding ssh-agent to .bashrc file...\n"
	setColor ${INFO}
	echo "echo ssh-agent starting..." >>~/.bashrc
	echo 'eval $(ssh-agent)' >>~/.bashrc
	color ${INFO} "Starting ssh-agent...\n"
	eval $(ssh-agent)
	resetColor
	setColor ${QUESTION}
	read -p "would you like to automatically add your key to ssh on login? (y/n) " startupKey
	resetColor
	echo -e "\n"

	if [ "$startup" == "y" ]; then
		color ${INFO} "\nAdding add-key command to .bashrc file...\n"
		setColor ${INFO}
		echo "ssh-add ~/.ssh/${authFile}" >>~/.bashrc
		color ${INFO} "Adding key to ssh-agent...\n"
		ssh-add ~/.ssh/${authFile}
		resetColor
	elif [ "$newKey" == "n" ]; then
		color ${INFO} "\nSkipping adding keys to startup...You will have to use ssh-add <key-filepath> manually on each login."
	else
		color ${ERROR} "Invalid data received. Please type y or n in prompt."
		exit 1
	fi

elif [ "$newKey" == "n" ]; then
	color ${INFO} "\nSkipping adding ssh-keygen to startup..."
else
	color ${ERROR} "Invalid data received. Please type y or n in prompt."
	exit 1
fi

echo "trap 'ssh-agent -k' EXIT" >>~/.bashrc
color ${INFO} "Testing connection....\n"
ssh -T git@github.com
# Adding these to the end of the script to reload a fresh
# version of bash with the changes in our configuration
color ${INFO} "\nPlease refresh your shell by running source ~/.bashrc\n"
