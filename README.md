# github-ssh
A script to be able to configure Linux systems with Github using SSH authentication.

By default, linux systems are not able to utilize private Github repos due to the authentication requirements of Github. This script automates the process of setting up an ssh key on the linux system using the methodology described here: https://gist.github.com/xirixiz/b6b0c6f4917ce17a90e00f9b60566278. Thanks to https://github.com/xirixiz for giving me the outline for configuration.

This script is capable of performing the following tasks (verifying with the user which of these processes to execute)

- Create a new public and private ssh key
- modify the .bashrc file to automatically start the ssh-agent and add the ssh key to the agent to use when connecting to Github.

**Note**, that the script will provide you with the public key to be able to copy to Github. In order for proper connection to Github, you must follow the prompts of the script to copy the public key that is created and add a new SSH key to your Github account. Follow the instructions at this link to create new SSH keys on Github. https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account

## Installation
The standard installation will run the script one time without saving any files on your system. This script does all of the necessary modifications to the system to allow for seamless SSH connections to Github.
```
/bin/bash -c "$(curl -fsSL https://raw.Githubusercontent.com/JoshKoiro/github-ssh/main/config.sh)"
```
## Notes

After installing the changes to the .bashrc file if you use `source ~/.bashrc` at any point during the session, it will create an additional `ssh-agent` process that will not be deleted when the session ends. In order to fix this, anytime you need to refresh the session make sure to kill the existing processes.
```
# Kill existing processes
pkill ssh-agent

# reload .bashrc
source ~/.bashrc
```

This will prevent the accumulation of dangling processes.
