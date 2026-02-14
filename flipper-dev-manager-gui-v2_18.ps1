#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Flipper Zero Development Manager - GUI Edition (Improved)
.DESCRIPTION
    A graphical interface for managing Flipper Zero development environment setup and app compilation
.NOTES
    Must be run as Administrator
.VERSION
    1.0.0.0
#>

# PS2EXE Compiler Settings
#ps2exe: -title "Flipper Zero Development Manager"
#ps2exe: -description "GUI tool for Flipper Zero app development with WSL"
#ps2exe: -company "Flipper Dev Tools"
#ps2exe: -product "Flipper Zero Development Manager"
#ps2exe: -copyright "2026"
#ps2exe: -version "1.0.0.0"
#ps2exe: -iconFile ""
#ps2exe: -requireAdmin

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Add Windows API functions to hide/show console window
Add-Type -Name Window -Namespace Console -MemberDefinition '
[DllImport("Kernel32.dll")]
public static extern IntPtr GetConsoleWindow();

[DllImport("user32.dll")]
public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'

# Hide the PowerShell console window
$consolePtr = [Console.Window]::GetConsoleWindow()
[Console.Window]::ShowWindow($consolePtr, 0) | Out-Null

# Dark Mode Color Scheme
$darkBg = [System.Drawing.Color]::FromArgb(30, 30, 30)
$darkControlBg = [System.Drawing.Color]::FromArgb(45, 45, 48)
$darkText = [System.Drawing.Color]::FromArgb(220, 220, 220)
$darkBorder = [System.Drawing.Color]::FromArgb(63, 63, 70)
$accentOrange = [System.Drawing.Color]::FromArgb(255, 140, 0)
$accentGreen = [System.Drawing.Color]::FromArgb(76, 175, 80)
$accentBlue = [System.Drawing.Color]::FromArgb(33, 150, 243)

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Flipper Zero Development Manager"
$form.Size = New-Object System.Drawing.Size(800, 650)
$form.MinimumSize = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = $darkBg

# Title Label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(740, 40)
$titleLabel.Text = "Flipper Zero Development Manager"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $accentOrange
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$titleLabel.Anchor = "Top,Left,Right"
$form.Controls.Add($titleLabel)

# Subtitle Label
$subtitleLabel = New-Object System.Windows.Forms.Label
$subtitleLabel.Location = New-Object System.Drawing.Point(20, 65)
$subtitleLabel.Size = New-Object System.Drawing.Size(740, 20)
$subtitleLabel.Text = "Manage your WSL environment and compile Flipper apps"
$subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$subtitleLabel.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$subtitleLabel.BackColor = [System.Drawing.Color]::Transparent
$subtitleLabel.Anchor = "Top,Left,Right"
$form.Controls.Add($subtitleLabel)

# Separator Line
$separator1 = New-Object System.Windows.Forms.Label
$separator1.Location = New-Object System.Drawing.Point(20, 90)
$separator1.Size = New-Object System.Drawing.Size(740, 2)
$separator1.BackColor = $darkBorder
$separator1.Anchor = "Top,Left,Right"
$form.Controls.Add($separator1)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 320)
$progressBar.Size = New-Object System.Drawing.Size(740, 25)
$progressBar.Style = "Marquee"
$progressBar.MarqueeAnimationSpeed = 30
$progressBar.Visible = $false
$progressBar.Anchor = "Top,Left,Right"
$form.Controls.Add($progressBar)

# Output Label
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Location = New-Object System.Drawing.Point(20, 355)
$outputLabel.Size = New-Object System.Drawing.Size(740, 25)
$outputLabel.Text = "Output Console:"
$outputLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$outputLabel.ForeColor = $darkText
$outputLabel.BackColor = [System.Drawing.Color]::Transparent
$outputLabel.Anchor = "Top,Left,Right"
$form.Controls.Add($outputLabel)

# Output TextBox (Console-like output)
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(20, 385)
$outputBox.Size = New-Object System.Drawing.Size(740, 180)
$outputBox.Multiline = $true
$outputBox.ScrollBars = "Vertical"
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::FromArgb(20, 20, 20)
$outputBox.ForeColor = [System.Drawing.Color]::FromArgb(0, 255, 100)
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.BorderStyle = "FixedSingle"
$outputBox.Anchor = "Top,Bottom,Left,Right"
$form.Controls.Add($outputBox)

# Function to write to output box
function Write-Output {
    param([string]$Message)
    $form.Invoke([Action]{
        $outputBox.AppendText("$Message`r`n")
        $outputBox.SelectionStart = $outputBox.TextLength
        $outputBox.ScrollToCaret()
    })
}

# Function to show/hide progress bar
function Set-ProgressBar {
    param([bool]$Visible)
    $form.Invoke([Action]{
        $progressBar.Visible = $Visible
    })
}

# Function to enable/disable buttons
function Set-ButtonsEnabled {
    param([bool]$Enabled)
    $form.Invoke([Action]{
        $installButton.Enabled = $Enabled
        $updateButton.Enabled = $Enabled
        $compileButton.Enabled = $Enabled
    })
}

# Function to check if WSL is installed
function Test-WSLInstalled {
    try {
        $wslVersion = wsl --version 2>$null
        return $true
    }
    catch {
        return $false
    }
}

# Function to check if a distro is installed
function Test-WSLDistroInstalled {
    param([string]$DistroName)
    $distros = wsl -l -q
    return $distros -contains $DistroName
}

# Function to get installed distro
function Get-InstalledDistro {
    try {
        # Get all distros and clean up the output
        $allDistros = wsl -l -q
        
        # Filter for common Linux distros and clean whitespace/null chars
        $distros = $allDistros | Where-Object { 
            $cleaned = $_ -replace '\x00', '' -replace '[\r\n]', ''
            $cleaned = $cleaned.Trim()
            $cleaned -match "Ubuntu|Debian|kali"
        }
        
        if ($distros) {
            # Clean and return the first match
            $distroName = $distros[0] -replace '\x00', '' -replace '[\r\n]', ''
            return $distroName.Trim()
        }
    }
    catch { }
    return $null
}

# Function to run command asynchronously
function Start-AsyncCommand {
    param(
        [ScriptBlock]$ScriptBlock,
        [Object[]]$ArgumentList
    )
    
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.ApartmentState = "STA"
    $runspace.ThreadOptions = "ReuseThread"
    $runspace.Open()
    
    # Share form and functions with runspace
    $runspace.SessionStateProxy.SetVariable("form", $form)
    $runspace.SessionStateProxy.SetVariable("outputBox", $outputBox)
    $runspace.SessionStateProxy.SetVariable("progressBar", $progressBar)
    $runspace.SessionStateProxy.SetVariable("installButton", $installButton)
    $runspace.SessionStateProxy.SetVariable("updateButton", $updateButton)
    $runspace.SessionStateProxy.SetVariable("compileButton", $compileButton)
    $runspace.SessionStateProxy.SetVariable("darkBg", $darkBg)
    $runspace.SessionStateProxy.SetVariable("darkControlBg", $darkControlBg)
    $runspace.SessionStateProxy.SetVariable("darkText", $darkText)
    $runspace.SessionStateProxy.SetVariable("darkBorder", $darkBorder)
    $runspace.SessionStateProxy.SetVariable("accentOrange", $accentOrange)
    $runspace.SessionStateProxy.SetVariable("accentGreen", $accentGreen)
    $runspace.SessionStateProxy.SetVariable("accentBlue", $accentBlue)
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    $powershell.AddScript({
        function Write-Output {
            param([string]$Message)
            $form.Invoke([Action]{
                $outputBox.AppendText("$Message`r`n")
                $outputBox.SelectionStart = $outputBox.TextLength
                $outputBox.ScrollToCaret()
            })
        }
        
        function Set-ProgressBar {
            param([bool]$Visible)
            $form.Invoke([Action]{
                $progressBar.Visible = $Visible
            })
        }
        
        function Set-ButtonsEnabled {
            param([bool]$Enabled)
            $form.Invoke([Action]{
                $installButton.Enabled = $Enabled
                $updateButton.Enabled = $Enabled
                $compileButton.Enabled = $Enabled
            })
        }
    }).AddScript($ScriptBlock) | Out-Null
    
    # Add arguments if provided
    if ($ArgumentList) {
        foreach ($arg in $ArgumentList) {
            $powershell.AddArgument($arg) | Out-Null
        }
    }
    
    $handle = $powershell.BeginInvoke()
    
    return @{
        PowerShell = $powershell
        Handle = $handle
        Runspace = $runspace
    }
}

# ============================================
# BUTTON 1: Initial Installation
# ============================================

$installButton = New-Object System.Windows.Forms.Button
$installButton.Location = New-Object System.Drawing.Point(20, 110)
$installButton.Size = New-Object System.Drawing.Size(740, 60)
$installButton.Text = "1. Initial Setup - Install WSL, Linux Distro & ufbt"
$installButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$installButton.BackColor = $accentGreen
$installButton.ForeColor = [System.Drawing.Color]::White
$installButton.FlatStyle = "Flat"
$installButton.FlatAppearance.BorderSize = 0
$installButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(90, 185, 94)
$installButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$installButton.Anchor = "Top,Left,Right"

$installButton.Add_Click({
    $outputBox.Clear()
    Set-ButtonsEnabled $false
    Set-ProgressBar $true
    
    $asyncJob = Start-AsyncCommand -ScriptBlock {
        Write-Output "=========================================="
        Write-Output "Starting Initial Setup Process..."
        Write-Output "=========================================="
        
        # Check WSL
        Write-Output "`n[Step 1/6] Checking WSL installation..."
        
        $wslInstalled = $false
        try {
            $wslVersion = wsl --version 2>$null
            $wslInstalled = $true
        }
        catch {
            $wslInstalled = $false
        }
        
        if (-not $wslInstalled) {
            Write-Output "WSL not found. Installing WSL..."
            $process = Start-Process -FilePath "wsl" -ArgumentList "--install --no-distribution" -NoNewWindow -PassThru -Wait
            Write-Output "`nWSL installed! Please RESTART your computer and run this tool again."
            
            $form.Invoke([Action]{
                [System.Windows.Forms.MessageBox]::Show(
                    "WSL has been installed successfully!`n`nPlease RESTART your computer and run this tool again to continue setup.",
                    "Restart Required",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            })
            
            Set-ProgressBar $false
            Set-ButtonsEnabled $true
            return
        }
        else {
            Write-Output "WSL is already installed."
        }
        
        # Choose distro
        Write-Output "`n[Step 2/6] Setting up Linux distribution..."
        
        $selectedDistro = $null
        $distroName = $null
        $distroCommand = $null
        
        $form.Invoke([Action]{
            $distroForm = New-Object System.Windows.Forms.Form
            $distroForm.Text = "Select Linux Distribution"
            $distroForm.Size = New-Object System.Drawing.Size(400, 250)
            $distroForm.StartPosition = "CenterParent"
            $distroForm.FormBorderStyle = "FixedDialog"
            $distroForm.MaximizeBox = $false
            $distroForm.MinimizeBox = $false
            $distroForm.BackColor = $darkBg
            
            $distroLabel = New-Object System.Windows.Forms.Label
            $distroLabel.Location = New-Object System.Drawing.Point(20, 20)
            $distroLabel.Size = New-Object System.Drawing.Size(350, 20)
            $distroLabel.Text = "Choose a Linux distribution to install:"
            $distroLabel.ForeColor = $darkText
            $distroLabel.BackColor = [System.Drawing.Color]::Transparent
            $distroForm.Controls.Add($distroLabel)
            
            $distroListBox = New-Object System.Windows.Forms.ListBox
            $distroListBox.Location = New-Object System.Drawing.Point(20, 50)
            $distroListBox.Size = New-Object System.Drawing.Size(350, 100)
            $distroListBox.BackColor = $darkControlBg
            $distroListBox.ForeColor = $darkText
            $distroListBox.BorderStyle = "FixedSingle"
            $distroListBox.Items.AddRange(@(
                "Ubuntu (Recommended)",
                "Ubuntu-24.04",
                "Debian",
                "Kali-Linux"
            ))
            $distroListBox.SelectedIndex = 0
            $distroForm.Controls.Add($distroListBox)
            
            $distroOkButton = New-Object System.Windows.Forms.Button
            $distroOkButton.Location = New-Object System.Drawing.Point(150, 160)
            $distroOkButton.Size = New-Object System.Drawing.Size(100, 30)
            $distroOkButton.Text = "OK"
            $distroOkButton.BackColor = $accentGreen
            $distroOkButton.ForeColor = [System.Drawing.Color]::White
            $distroOkButton.FlatStyle = "Flat"
            $distroOkButton.FlatAppearance.BorderSize = 0
            $distroOkButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $distroForm.Controls.Add($distroOkButton)
            $distroForm.AcceptButton = $distroOkButton
            
            $result = $distroForm.ShowDialog()
            
            if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                $selectedIndex = $distroListBox.SelectedIndex
                
                $distroMap = @{
                    0 = @{ Name = "Ubuntu"; Command = "Ubuntu" }
                    1 = @{ Name = "Ubuntu-24.04"; Command = "Ubuntu-24.04" }
                    2 = @{ Name = "Debian"; Command = "Debian" }
                    3 = @{ Name = "kali-linux"; Command = "kali-linux" }
                }
                
                $script:selectedDistro = $distroMap[$selectedIndex]
                $script:distroName = $selectedDistro.Name
                $script:distroCommand = $selectedDistro.Command
            }
        })
        
        if (-not $distroName) {
            Write-Output "Installation cancelled."
            Set-ProgressBar $false
            Set-ButtonsEnabled $true
            return
        }
        
        Write-Output "Selected: $distroName"
        
        # Check if already installed
        $distros = wsl -l -q
        $alreadyInstalled = $distros -contains $distroName
        
        if ($alreadyInstalled) {
            Write-Output "$distroName is already installed."
            
            $useExisting = $false
            $form.Invoke([Action]{
                $reinstallResult = [System.Windows.Forms.MessageBox]::Show(
                    "$distroName is already installed. Do you want to use the existing installation?",
                    "Existing Installation Found",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Question
                )
                
                $script:useExisting = ($reinstallResult -eq [System.Windows.Forms.DialogResult]::Yes)
            })
            
            if (-not $useExisting) {
                Write-Output "Please manually uninstall using: wsl --unregister $distroName"
                Set-ProgressBar $false
                Set-ButtonsEnabled $true
                return
            }
        }
        else {
            Write-Output "Installing $distroName..."
            Write-Output "A new window will open - please complete the setup there."
            
            $process = Start-Process -FilePath "wsl" -ArgumentList "--install -d $distroCommand" -PassThru -Wait
            Write-Output "$distroName installed successfully!"
            
            $form.Invoke([Action]{
                [System.Windows.Forms.MessageBox]::Show(
                    "Please complete the user setup in the WSL window that opened, then click OK to continue.",
                    "WSL Setup",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
            })
        }
        
        # Step 3: Update and upgrade
        Write-Output "`n[Step 3/6] Updating Linux distribution..."
        Write-Output "This may take a few minutes..."
        Write-Output "A terminal window will open for you to enter your password."
        
        $updateCommands = @"
echo '==> Updating package lists...'
sudo apt update
echo '==> Upgrading packages...'
sudo apt upgrade -y
echo '==> Update complete!'
echo 'Press any key to close this window...'
read -n 1
"@
        
        # Show the terminal window so user can interact
        $process = Start-Process -FilePath "wsl" -ArgumentList "-d $distroName bash -c `"$updateCommands`"" -Wait -PassThru
        
        Write-Output "Update complete!"
        
        # Step 4: Install dependencies
        Write-Output "`n[Step 4/6] Installing required dependencies..."
        Write-Output "A terminal window will open for package installation."
        
        $installDepsCommands = @"
echo '==> Installing git, python3, and pipx...'
sudo apt install -y git python3 python3-pip pipx
echo '==> Setting up pipx path...'
pipx ensurepath
echo '==> Dependencies installed!'
echo 'Press any key to close this window...'
read -n 1
"@
        
        $process = Start-Process -FilePath "wsl" -ArgumentList "-d $distroName bash -c `"$installDepsCommands`"" -Wait -PassThru
        
        Write-Output "Dependencies installed!"
        
        # Step 5: Install ufbt
        Write-Output "`n[Step 5/6] Installing ufbt..."
        Write-Output "This will download the Flipper SDK (may take a few minutes)..."
        Write-Output "A terminal window will open to show progress."
        
        $installUfbtCommands = @"
echo '==> Installing ufbt via pipx...'
export PATH=`$PATH:`$HOME/.local/bin
pipx install ufbt
echo '==> Updating ufbt and downloading SDK...'
`$HOME/.local/bin/ufbt update
echo '==> ufbt installed successfully!'
echo 'Press any key to close this window...'
read -n 1
"@
        
        $process = Start-Process -FilePath "wsl" -ArgumentList "-d $distroName bash -c `"$installUfbtCommands`"" -Wait -PassThru
        
        Write-Output "ufbt installed successfully!"
        
        # Step 6: Install usbipd
        Write-Output "`n[Step 6/6] Installing usbipd for USB device access..."
        
        $usbipdInstalled = $false
        try {
            $usbipd = Get-Command usbipd -ErrorAction Stop
            $usbipdInstalled = $true
        }
        catch {
            $usbipdInstalled = $false
        }
        
        if ($usbipdInstalled) {
            Write-Output "usbipd is already installed."
        }
        else {
            Write-Output "Installing usbipd via winget..."
            $process = Start-Process -FilePath "winget" -ArgumentList "install --id dorssel.usbipd-win --accept-source-agreements --accept-package-agreements" -NoNewWindow -Wait -PassThru
        }
        
        $installUsbipd = @"
echo '==> Installing usbipd tools in WSL...'
sudo apt install -y linux-tools-generic hwdata
sudo update-alternatives --install /usr/local/bin/usbip usbip /usr/lib/linux-tools/*-generic/usbip 20
echo '==> usbipd tools installed!'
echo 'Press any key to close this window...'
read -n 1
"@
        
        $process = Start-Process -FilePath "wsl" -ArgumentList "-d $distroName bash -c `"$installUsbipd`"" -Wait -PassThru
        
        Write-Output "usbipd tools installed!"
        
        Write-Output "`n=========================================="
        Write-Output "Setup Complete!"
        Write-Output "=========================================="
        Write-Output "You can now use the compile button to build your Flipper apps!"
        
        $form.Invoke([Action]{
            [System.Windows.Forms.MessageBox]::Show(
                "Setup completed successfully!`n`nYou can now use the 'Compile Flipper App' button to build your applications.",
                "Setup Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        })
        
        Set-ProgressBar $false
        Set-ButtonsEnabled $true
    }
})

$form.Controls.Add($installButton)

# ============================================
# BUTTON 2: Update & Upgrade WSL
# ============================================

$updateButton = New-Object System.Windows.Forms.Button
$updateButton.Location = New-Object System.Drawing.Point(20, 180)
$updateButton.Size = New-Object System.Drawing.Size(740, 60)
$updateButton.Text = "2. Update & Upgrade WSL Distribution"
$updateButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$updateButton.BackColor = $accentBlue
$updateButton.ForeColor = [System.Drawing.Color]::White
$updateButton.FlatStyle = "Flat"
$updateButton.FlatAppearance.BorderSize = 0
$updateButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(50, 160, 253)
$updateButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$updateButton.Anchor = "Top,Left,Right"

$updateButton.Add_Click({
    $outputBox.Clear()
    Set-ButtonsEnabled $false
    Set-ProgressBar $true
    
    $asyncJob = Start-AsyncCommand -ScriptBlock {
        Write-Output "=========================================="
        Write-Output "Updating WSL Distribution..."
        Write-Output "=========================================="
        
        Write-Output "`nDetecting WSL distributions..."
        $allDistros = wsl -l -q
        $allDistros | ForEach-Object { 
            $cleaned = $_ -replace '\x00', '' -replace '[\r\n]', ''
            if ($cleaned.Trim()) {
                Write-Output "  Found: $($cleaned.Trim())"
            }
        }
        
        # Get all distros and clean up the output
        $distros = $allDistros | Where-Object { 
            $cleaned = $_ -replace '\x00', '' -replace '[\r\n]', ''
            $cleaned = $cleaned.Trim()
            $cleaned -match "Ubuntu|Debian|kali"
        }
        
        $distroName = if ($distros) { 
            $cleaned = $distros[0] -replace '\x00', '' -replace '[\r\n]', ''
            $cleaned.Trim() 
        } else { 
            $null 
        }
        
        if (-not $distroName) {
            Write-Output "`nERROR: No compatible WSL distribution found."
            Write-Output "Looking for: Ubuntu, Debian, or Kali-Linux"
            
            $form.Invoke([Action]{
                [System.Windows.Forms.MessageBox]::Show(
                    "No WSL distribution found!`n`nPlease run the Initial Setup first.",
                    "Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            })
            
            Set-ProgressBar $false
            Set-ButtonsEnabled $true
            return
        }
        
        Write-Output "Using distribution: $distroName"
        Write-Output "`nUpdating packages..."
        Write-Output "A terminal window will open for you to enter your password."
        Write-Output "This may take a few minutes..."
        
        $updateCommands = @"
echo '==> Updating package lists...'
sudo apt update
echo '==> Upgrading packages...'
sudo apt upgrade -y
echo '==> Cleaning up...'
sudo apt autoremove -y
sudo apt autoclean
echo '==> Update complete!'
echo 'Press any key to close this window...'
read -n 1
"@
        
        $process = Start-Process -FilePath "wsl" -ArgumentList "-d $distroName bash -c `"$updateCommands`"" -Wait -PassThru
        
        Write-Output "`n=========================================="
        Write-Output "Update Complete!"
        Write-Output "=========================================="
        
        $form.Invoke([Action]{
            [System.Windows.Forms.MessageBox]::Show(
                "WSL distribution updated successfully!",
                "Update Complete",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )
        })
        
        Set-ProgressBar $false
        Set-ButtonsEnabled $true
    }
})

$form.Controls.Add($updateButton)

# ============================================
# BUTTON 3: Compile Flipper App
# ============================================

$compileButton = New-Object System.Windows.Forms.Button
$compileButton.Location = New-Object System.Drawing.Point(20, 250)
$compileButton.Size = New-Object System.Drawing.Size(740, 60)
$compileButton.Text = "3. Compile Flipper App"
$compileButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$compileButton.BackColor = $accentOrange
$compileButton.ForeColor = [System.Drawing.Color]::White
$compileButton.FlatStyle = "Flat"
$compileButton.FlatAppearance.BorderSize = 0
$compileButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(255, 160, 30)
$compileButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$compileButton.Anchor = "Top,Left,Right"

$compileButton.Add_Click({
    $outputBox.Clear()
    
    # Check if distro is installed
    Write-Output "Detecting WSL distributions..."
    $allDistros = wsl -l -q
    Write-Output "All installed WSL distros:"
    $allDistros | ForEach-Object { 
        $cleaned = $_ -replace '\x00', '' -replace '[\r\n]', ''
        if ($cleaned.Trim()) {
            Write-Output "  - $($cleaned.Trim())"
        }
    }
    
    $distroName = Get-InstalledDistro
    
    if (-not $distroName) {
        Write-Output "`nERROR: No compatible WSL distribution found."
        Write-Output "Looking for: Ubuntu, Debian, or Kali-Linux"
        Write-Output "Please run Initial Setup first or install one of these distributions."
        [System.Windows.Forms.MessageBox]::Show(
            "No compatible WSL distribution found!`n`nLooking for: Ubuntu, Debian, or Kali-Linux`n`nPlease run the Initial Setup first.",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }
    
    Write-Output "`nUsing distribution: $distroName"
    
    # Use Shell.Application for better folder browsing
    $shell = New-Object -ComObject Shell.Application
    $folder = $shell.BrowseForFolder(0, "Select the folder containing your Flipper app (with application.fam file)", 0, "E:\")
    
    if ($null -eq $folder) {
        Write-Output "Folder selection cancelled."
        return
    }
    
    $selectedPath = $folder.Self.Path
    Write-Output "Selected folder: $selectedPath"
    
    # Verify application.fam exists
    $famPath = Join-Path $selectedPath "application.fam"
    if (-not (Test-Path $famPath)) {
        Write-Output "ERROR: application.fam not found in selected folder!"
        Write-Output "Looking for: $famPath"
        [System.Windows.Forms.MessageBox]::Show(
            "The selected folder does not contain an application.fam file!`n`nPlease select a valid Flipper app folder.`n`nLooking for: $famPath",
            "Invalid Folder",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return
    }
    
    Write-Output "Found application.fam: $famPath"
    
    Set-ButtonsEnabled $false
    Set-ProgressBar $true
    
    # Store values before async operation
    $pathToCompile = $selectedPath
    $distroToUse = $distroName
    
    $asyncJob = Start-AsyncCommand -ScriptBlock {
        param($selectedPath, $distroName)
        
        Write-Output "=========================================="
        Write-Output "Compile Flipper App"
        Write-Output "=========================================="
        Write-Output "Using distribution: $distroName`n"
        Write-Output "Selected folder: $selectedPath"
        
        # Convert Windows path to WSL path - compatible with PS2EXE
        $wslPath = $selectedPath -replace '\\', '/'
        # Extract drive letter and convert to lowercase
        if ($wslPath -match '^([A-Z]):') {
            $driveLetter = $matches[1].ToLower()
            $wslPath = $wslPath -replace '^[A-Z]:', "/mnt/$driveLetter"
        }
        
        Write-Output "WSL path: $wslPath"
        
        Write-Output "`nStarting compilation...`n"
        
        # Create the compile script with proper escaping - using single quote here-string
        $compileScriptContent = @'
#!/bin/bash
cd "WSLPATH_PLACEHOLDER" || {
    echo "ERROR: Could not change to directory: WSLPATH_PLACEHOLDER"
    exit 1
}

export PATH=$PATH:$HOME/.local/bin

echo "=========================================="
echo "Current directory: $(pwd)"
echo "Checking for application.fam..."
if [ -f "application.fam" ]; then
    echo "✓ application.fam found!"
else
    echo "✗ ERROR: application.fam not found in current directory!"
    ls -la
    exit 1
fi

echo ""
echo "Checking ufbt..."
if command -v ufbt >/dev/null 2>&1; then
    echo "✓ ufbt is available"
    ufbt --version 2>/dev/null || echo "  (version info not available)"
else
    echo "✗ ERROR: ufbt not found in PATH!"
    echo "PATH: $PATH"
    exit 1
fi

echo ""
echo "=========================================="
echo "Building Flipper app..."
echo "=========================================="
ufbt

BUILD_EXIT_CODE=$?

echo ""
echo "=========================================="
if [ $BUILD_EXIT_CODE -eq 0 ]; then
    echo "✓ Build completed successfully!"
    echo ""
    echo "Compiled files:"
    find . -name '*.fap' -type f 2>/dev/null || echo "No .fap files found"
else
    echo "✗ Build failed with exit code: $BUILD_EXIT_CODE"
fi
echo "=========================================="
echo ""
echo "Press Enter to close this window..."
read

exit $BUILD_EXIT_CODE
'@
        
        # Replace the placeholder with actual WSL path
        $compileScriptContent = $compileScriptContent -replace 'WSLPATH_PLACEHOLDER', $wslPath
        
        # Save to a temporary file on the Windows side first
        $windowsTempScript = [System.IO.Path]::GetTempFileName()
        $windowsTempScriptSh = $windowsTempScript + ".sh"
        
        # Remove the original .tmp file and use .sh extension
        Remove-Item -Path $windowsTempScript -ErrorAction SilentlyContinue
        
        $compileScriptContent | Out-File -FilePath $windowsTempScriptSh -Encoding UTF8
        
        # Convert Windows path to WSL path for the temp file - PS2EXE compatible
        $windowsTempScriptWSL = $windowsTempScriptSh -replace '\\', '/'
        # Extract drive letter and convert to lowercase
        if ($windowsTempScriptWSL -match '^([A-Z]):') {
            $driveLetter = $matches[1].ToLower()
            $windowsTempScriptWSL = $windowsTempScriptWSL -replace '^[A-Z]:', "/mnt/$driveLetter"
        }
        
        Write-Output "Build script created at: $windowsTempScriptSh"
        Write-Output "WSL path: $windowsTempScriptWSL"
        Write-Output "Compiling... A terminal window will open to show build progress."
        Write-Output "=========================================="
        
        # Verify the script file exists
        if (-not (Test-Path $windowsTempScriptSh)) {
            Write-Output "ERROR: Failed to create script file!"
            Set-ProgressBar $false
            Set-ButtonsEnabled $true
            return
        }
        
        # Run the script directly from the Windows temp location
        try {
            $process = Start-Process -FilePath "wsl.exe" -ArgumentList "-d",$distroName,"bash",$windowsTempScriptWSL -Wait -PassThru
            Write-Output "Process exit code: $($process.ExitCode)"
        }
        catch {
            Write-Output "ERROR: Failed to start WSL process"
            Write-Output "Error: $($_.Exception.Message)"
            
            $form.Invoke([Action]{
                [System.Windows.Forms.MessageBox]::Show(
                    "Failed to start WSL!`n`nError: $($_.Exception.Message)",
                    "Process Error",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            })
        }
        
        # Clean up the temp script
        Start-Sleep -Seconds 1
        Remove-Item -Path $windowsTempScriptSh -ErrorAction SilentlyContinue
        
        # Check if compilation succeeded
        if ($process.ExitCode -ne 0) {
            Write-Output "`n=========================================="
            Write-Output "Compilation Failed!"
            Write-Output "=========================================="
            Write-Output "Exit code: $($process.ExitCode)"
            Write-Output "Please check the terminal window for error details."
            
            $form.Invoke([Action]{
                [System.Windows.Forms.MessageBox]::Show(
                    "Compilation failed with exit code: $($process.ExitCode)`n`nPlease check the terminal window for error details.",
                    "Compilation Failed",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Error
                )
            })
            
            Set-ProgressBar $false
            Set-ButtonsEnabled $true
            return
        }
        
        Write-Output "`nCompilation completed successfully!"
        
        Write-Output "=========================================="
        Write-Output "`nSearching for compiled .fap file..."
        
        # Give the file system a moment to sync
        Start-Sleep -Seconds 2
        
        # Try multiple methods to find the .fap file
        # Method 1: Search using PowerShell (most reliable for Windows paths)
        Write-Output "Searching with PowerShell..."
        $fapFilePS = Get-ChildItem -Path $selectedPath -Filter "*.fap" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($fapFilePS) {
            Write-Output "PowerShell found: $($fapFilePS.FullName)"
        } else {
            Write-Output "PowerShell search: No .fap file found"
        }
        
        # Method 2: Check common build directories
        $commonPaths = @(
            (Join-Path $selectedPath "dist"),
            (Join-Path $selectedPath "build"),
            (Join-Path $selectedPath ".fbt"),
            $selectedPath
        )
        
        $fullFapPath = $null
        
        foreach ($path in $commonPaths) {
            if (Test-Path $path) {
                Write-Output "Checking: $path"
                $fapInPath = Get-ChildItem -Path $path -Filter "*.fap" -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($fapInPath) {
                    $fullFapPath = $fapInPath.FullName
                    Write-Output "Found .fap file in: $path"
                    break
                }
            }
        }
        
        # Method 3: Try WSL search as backup
        if (-not $fullFapPath) {
            Write-Output "Trying WSL search..."
            $findFapCommand = "cd `"$wslPath`" && find . -name '*.fap' -type f 2>/dev/null | head -1"
            $fapFileWSL = wsl -d $distroName bash -c $findFapCommand 2>&1
            
            if ($fapFileWSL -and $fapFileWSL.Trim() -ne "") {
                $fapFile = $fapFileWSL.Trim()
                $fullFapPath = Join-Path $selectedPath ($fapFile -replace '^\./','')
                Write-Output "WSL found: $fullFapPath"
            }
        }
        
        # Use PowerShell result if we still don't have a path
        if (-not $fullFapPath -and $fapFilePS) {
            $fullFapPath = $fapFilePS.FullName
        }
        
        # Verify the file actually exists
        if ($fullFapPath -and (Test-Path $fullFapPath)) {
            Write-Output "`n=========================================="
            Write-Output "Compilation Successful!"
            Write-Output "=========================================="
            Write-Output ".fap file location:"
            Write-Output $fullFapPath
            
            # Get file size and modification time
            $fileInfo = Get-Item $fullFapPath
            Write-Output "File size: $([math]::Round($fileInfo.Length / 1KB, 2)) KB"
            Write-Output "Modified: $($fileInfo.LastWriteTime)"
            Write-Output "=========================================="
            
            # Show success dialog with option to open folder
            $fapPathForDialog = $fullFapPath
            $form.Invoke([Action]{
                $dialogResult = [System.Windows.Forms.MessageBox]::Show(
                    "Compilation successful!`n`n.fap file saved to:`n$fapPathForDialog`n`nWould you like to open the folder?",
                    "Compilation Complete",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                )
                
                if ($dialogResult -eq [System.Windows.Forms.DialogResult]::Yes) {
                    $folderPath = Split-Path $fapPathForDialog -Parent
                    Start-Process explorer.exe -ArgumentList "/select,`"$fapPathForDialog`""
                }
            })
        }
        else {
            Write-Output "`nWARNING: .fap file not found. Check the output above for errors."
            
            $form.Invoke([Action]{
                [System.Windows.Forms.MessageBox]::Show(
                    "Compilation may have failed.`n`nPlease check the output log for errors.",
                    "Warning",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                )
            })
        }
        
        Set-ProgressBar $false
        Set-ButtonsEnabled $true
    } -ArgumentList @($pathToCompile, $distroToUse)
})

$form.Controls.Add($compileButton)

# Close Button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Location = New-Object System.Drawing.Point(340, 575)
$closeButton.Size = New-Object System.Drawing.Size(120, 35)
$closeButton.Text = "Close"
$closeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$closeButton.BackColor = $darkControlBg
$closeButton.ForeColor = $darkText
$closeButton.FlatStyle = "Flat"
$closeButton.FlatAppearance.BorderColor = $darkBorder
$closeButton.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(60, 60, 65)
$closeButton.Anchor = "Bottom"
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# Add FormClosing event to restore console when GUI closes
$form.Add_FormClosing({
    # Show the PowerShell console window again
    [Console.Window]::ShowWindow($consolePtr, 5) | Out-Null
})

# Initial welcome message
$outputBox.AppendText("Welcome to Flipper Zero Development Manager!`r`n")
$outputBox.AppendText("========================================`r`n")
$outputBox.AppendText("Select an option above to get started.`r`n")
$outputBox.AppendText("========================================`r`n")

# Show the form
[void]$form.ShowDialog()
