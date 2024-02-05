#!/bin/bash

echo -e "\nThis script will walk you through the process of setting up Github authentication on your system using ssh.\n\n"

read -p "Would you like to create a new key? (y/n)" newKey

if [ "$newKey" == "y" ]; then
	echo -e "\nCreating new key...\n"
	read -p "Please enter your email address that is associated with your Github account: " email
	ssh-keygen -t rsa -b 4096 -C $email
elif [ "$newKey" == "n" ]; then
	echo -e "\n\nNo new keys created..."
else
	echo -e "Invalid data received. Please type y or n in prompt."
	exit 1
fi

echo -e "\n"
ls ~/.ssh
echo -e "\n"
read -p "Above is the available keys generated on the system. Please type the name of the one created for Github: " authFile

echo -e "\nBelow is your public key. Please copy this entirety of the contents below to enter on Github when you create the ssh key.\n"

cat ~/.ssh/$authFile

echo -e "\n"

read -p "Would you like to start ssh-keygen on login? (y/n) " startup
echo -e "\n"

if [ "$startup" == "y" ]; then
	echo -e "\nAdding ssh-keygen to .bashrc file...\n"
	echo "echo ssh-agent started..." >>~/.bashrc
	echo "eval $(ssh-agent -s)" >>~/.bashrc
	read -p "would you like to automatically add your key to ssh on login? (y/n) " startupKey
	echo -e "\n"

	if [ "$startup" == "y" ]; then
		echo -e "\nAdding add-key command to .bashrc file...\n"
		echo "ssh-add ~/.ssh/${authFile}"
	elif [ "$newKey" == "n" ]; then
		echo -e "\nSkipping adding keys to startup...You will have to use ssh-add <key-filepath> manually on each login."
	else
		echo -e "Invalid data received. Please type y or n in prompt."
		exit 1
	fi

elif [ "$newKey" == "n" ]; then
	echo -e "\nSkipping adding ssh-keygen to startup..."
else
	echo -e "Invalid data received. Please type y or n in prompt."
	exit 1
fi

echo -e "\nTesting connection....\n"
ssh -T git@github.com

echo -e "Reloading .bashrc..."

source ~/.bashrc
