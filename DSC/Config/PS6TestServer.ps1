Configuration PS6TestServer {
    param (
        [ValidateNotNullOrEmpty()]
        [string]$Node,    

        [string]$MOFfolder
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration 
      
    Node $Node {
        
        File DSCLogFolder {
            Type            = 'Directory'
            DestinationPath = 'C:\Tmp\DSClogs'
            Ensure          = "Present"
        }  

        Package PSCore {    
            Ensure    = "Present"
            Name      = "PowerShell 6-x64"
            Path      = "$Env:SystemDrive\tmp\SourceFiles\PowerShell-6.1.0-preview.1-win-x64.msi"
            ProductId = "A16A59B1-5DB1-44FC-BD40-E684B43B3A8E"
            LogPath   = "C:\Tmp\DSClogs\PS6.log"
        }

        Log AfterPSCoreInstall {
            Message   = "Finished Installing PowerShell Core 6 resource with ID PSCore"
            DependsOn = "[Package]PSCore"
        }
    
        Script InstallOpenSSH {
            GetScript  = {
                $folderSize = Get-ChildItem -Path 'C:\Program Files\OpenSSH\OpenSSH-Win64' | 
                    Measure-Object -property Length -sum | 
                    Select-Object Sum     
                    
                # return true or false
                return @{ Result = ($folderSize.Sum -eq '7390211') }                   
            }
            SetScript  = {
                param(
                    [string] $From = "C:\Tmp\SourceFiles\OpenSSH-Win64.zip",
                    [string] $To = "C:\Program Files\OpenSSH\",
                    [string] $Installer = "C:\Program Files\OpenSSH\OpenSSH-Win64\install-sshd.ps1"
                )

                if (Test-Path $From) {
                    # Load assembly name to perform unzip    
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    # Unzip file to directory
                    [System.IO.Compression.ZipFile]::ExtractToDirectory($From, $To)

                    # Run install
                    & $Installer
                }
            }
            TestScript = {
                # The Test function needs to return True if the system is already in the desired state
                $testpath = Test-Path "$Env:SystemDrive\Program Files\OpenSSH\OpenSSH-Win64" 
            
                if ($testpath) {
                    $count = (Get-ChildItem -Path "$Env:SystemDrive\Program Files\OpenSSH\OpenSSH-Win64").count
                    if ($count -eq 18) { 
                        return $true 
                    }
                } 
                else { 
                    return $false 
                }
            }
        }

        Log AfterInstallOpenSSH {
            Message   = "Finished Installing Open SSH resource with ID InstallOpenSSH"
            DependsOn = "[Script]InstallOpenSSH"
        }
    }
}
# For Vagrant output
Write-Host "MySite DSC Config :: Node=$($args[0]), MOFfolder=$($args[1])"
# Call the configuration to generate MOF file
PS6TestServer -Node $args[0] -OutputPath $args[1]