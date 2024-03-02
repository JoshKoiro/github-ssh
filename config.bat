@echo off
setlocal


echo This script will walk you through the process of setting up Github authentication on your system using ssh.
echo.

:: Ensure the .ssh directory exists
if not exist "%USERPROFILE%\.ssh\" mkdir "%USERPROFILE%\.ssh"

echo %USERPROFILE%\.ssh\

set /p newKey="Would you like to create a new key? (y/n) "
if "%newKey%"=="y" (
    echo.
    echo Creating new key...
    set /p email="Please enter your email address that is associated with your Github account: " 
    set /p keyName="Please enter the name of the key you would like to create (i.e., github): "
    echo `ssh-keygen -o -t rsa -C "%email%" -f "`%USERPROFILE%`\.ssh\`%keyName%"`
    ssh-keygen -o -t rsa -C "%email%" -f "`%USERPROFILE%`\.ssh\`%keyName%"
) else if "%newKey%"=="n" (
    echo.
    echo No new keys created...
) else (
    echo.
    echo Invalid data received. Please type y or n in prompt.
    exit /b 1
)

echo
cd "%USERPROFILE%\.ssh"
dir
echo.

set /p authFile="Above is the available keys generated on the system. Please type the name of the one created for Github: "
echo
echo Below is your public key. Please copy this entirety of the contents below to enter on Github when you create the ssh key.
echo

type "%authFile%.pub"

echo.
echo Press Enter to continue...
pause >nul

echo

:: No need to change back to the original directory since setlocal/endlocal encapsulates environment changes
echo Testing connection....
ssh -T git@github.com

endlocal