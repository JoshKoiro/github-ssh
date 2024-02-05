# github-ssh
A script to be able to configure Linux systems with Github using SSH authentication.

By default, linux systems are not able to utilize private github repos due to the authentication requirements of Github. This script automates the process of setting up an ssh key on the linux system using the methodology described here: https://gist.github.com/xirixiz/b6b0c6f4917ce17a90e00f9b60566278. Thanks to https://github.com/xirixiz for giving me the outline for configuration.

## Installation
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
## Usage


