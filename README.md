# Flipper App Builder 🐬
An easy to use application that allows you install and manage WSL with all required tools to compile your Flipper Zero apps. 

The application has two versions that can be used, a .ps1 (PowerShell) and .exe (GUI) version.

<br>

## How to launch the app

To launch the app via command line in powershell, first navigate to the file location:
```bash
cd C:\Path\To\Your\Saved\File
```

Then run the script:
```bash
./flipper-dev-manager-gui-v2_18.ps1
```
<br>

**OR**

<br>
The compiler can be launched with the flipper-dev-manager-gui-v2_18.exe portable app that's available in the repo. 

<br><br><br>
### If you prefer compiling the .ps1 script into a .exe app yourself, you can use the PS2EXE script of Ingo Karstein with GUI support. The GUI output and input is activated with one switch, real windows executables are generated. Compiles only Powershell 5.x compatible scripts. With optional graphical front end Win-PS2EXE.
<br><br>
## Install PS2EXE:

1. Open PowerShell as admin
2. Run the following command to install the module:
```bash
Install-Module ps2exe
```
3. When prompted, press 'A' or 'Y' to install.
  
4. Compile the app via command line:
```bash
Invoke-ps2exe -inputFile "C:\Path\To\flipper-dev-manager-gui-v2.ps1" -outputFile "C:\Save\Location\Of\FlipperDevManager.exe" -requireAdmin -noConsole -title "Flipper Zero Development Manager" -version "1.0.0.0"
```

<br>
The graphical front end of PS2EXE can be launched with:

```bash
Win-PS2EXE
```

<br>

### Notes for using the GUI version of PS2EXE*
* The Source file will be the location of the .ps1 file.
* The Target file will be the folder where you want the .exe saved.
* You can choose to add a .ico (Icon) file if  you want to. 
* The rest of the fields doesn't need to filled in. 

<br><br>

# How to use the Flipper App Builder 
After the app is launched, there will be 3 options:
1. Initial setup - This will install WSL 2. You can choose a Linux distro that you want to use (Kali-Linux was used to test and run the app)
2. Update and Upgrade your WSL distro - Useful if you want to quickly update & upgrade your Linux distro.
3. Compile Flipper App - This will allow you to open the location of the Flipper app that you want to compile.

<br>

## Initial Setup
The initial setup allows you to install one of the follpwing distros:
* Ubuntu
* Ubuntu 24.04
* Debian
* Kali-Linux

Once you select your preferred distro, the script runs 

```bash
sudo apt update && sudo apt upgrade -y
```
to update and upgrade all installed packages.
This will also install the development dependencies 
| Package | Description |
|---------|-------------|
| git | Version control system |
| python3 | Python programming language |
| python3-pip | Python package installer |
| pipx | Tool for installing Python applications in isolated environments |

## **Note*** During the installation, you might get prompted to enter the password that you set for your WSL distro to install the dependencies.

The ufbt (Micro Flipper Build Tool) will be installed next (This is the core tool for compiling Flipper Zero applications)

```bash
pipx install ufbt
ufbt update
```

<br>

## Update/Upgrade WSL distribution
This option will perform maintenance on your existing WSL distro
| Command | Description |
|---------|-------------|
| sudo apt update | Refreshes the list of available packages |
| sudo apt upgrade -y | Upgrade all installed packages |
| sudo apt autoremove -y | Removes unused/orphaned packages |
| sudo apt autoclean | Cleans up old package files |

<br>

## Compile Flipper App
This option will compile the selected Flipper Zero app and open the location of the .fap file. 
When clicked, it will allow you to open the location/folder of the application that you want to compile. 

Once the app has finished compiling you can choose to open the location of the .fap file. The location of the file will also be shown in the Output Console.

