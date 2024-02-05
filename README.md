# github-ssh
A script to be able to configure Linux systems with Github using SSH authentication.

By default, linux systems are not able to utilize private github repos due to the authentication requirements of Github. This script automates the process of setting up an ssh key on the linux system using the methodology described here: https://gist.github.com/xirixiz/b6b0c6f4917ce17a90e00f9b60566278. Thanks to https://github.com/xirixiz for giving me the outline for configuration.

This script is capable of performing the following tasks (verifying with the user which of these processes to execute)

- Create a new public and private ssh key
- modify the .bashrc file to automatically start the ssh-agent and add the ssh key to the agent to use when connecting to github.

## Standard installation
The standard installation will run the script one time without saving any files on your system. This script does all of the necessary modifications to the system to allow for seamless SSH connections to Github.
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/JoshKoiro/github-ssh/main/config.sh)"
```

## Installation using wget
in order to install the script, you may use the wget package.
```
sudo apt install wget
```
After installation, run the following command to download the script.
```
wget https://raw.githubusercontent.com/JoshKoiro/github-ssh/main/config.sh
```
Once the download is complete, make the script executable using chmod:
```
chmod +x config.sh
```

Finally, run the script to configure the system.
```
./config.sh
```
