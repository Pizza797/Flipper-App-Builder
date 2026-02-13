# Flipper App Builder
An easy to use application that allows you install and manage WSL with all required tools to compile your Flipper Zero apps. 

The application has two versions that can be used, a .ps1 (PowerShell) and .exe (GUI) version.

## How to use

To launch the app via command line in powershell, first navigate to the file location:
```bash
cd C:\Path\To\Your\Saved\File
```

Then run the app:
```bash
./flipper-dev-manager-gui-v2_18.ps1
```

OR

You can use the .exe version by downloading the portable app. 


### If you want to compile the .ps1 script into a .exe app, you can use PS2EXE of Ingo Karstein with GUI support. The GUI output and input is activated with one switch, real windows executables are generated. Compiles only Powershell 5.x compatible scripts. With optional graphical front end Win-PS2EXE.

## Install PS2EXE:

1. Open PowerShell as admin
2. Run the following command to install the module:
```bash
Install-Module ps2exe
```
3. Compile the app via command line:
```bash
Invoke-ps2exe -inputFile "C:\Path\To\flipper-dev-manager-gui-v2.ps1" -outputFile "C:\Save\Location\Of\FlipperDevManager.exe" -requireAdmin -noConsole -title "Flipper Zero Development Manager" -version "1.0.0.0"
```


You can also launch the graphical front end of PS2EXE with:
```bash
Win-PS2EXE
```
### When using the GUI version*
* The Sourch file will be the .ps1 file.
* The Target file will be the folder where you want the .exe saved.
* You can choose to add a .ico (Icon) file if  you want to. 
* The rest of the fields doesn't need to filled in. 
