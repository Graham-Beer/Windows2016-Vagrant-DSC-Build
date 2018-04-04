# -*- mode: ruby -*-
# vi: set ft=ruby :

  # Set variables  
  Node = "DSCPSCore6"
  MOFfolder = "C:\\tmp\\MOF"
  CopySource = "D:\\VagrantDemo\\DSC\\SourceFiles"
  CopyDestination = "C:\\tmp\\SourceFiles"

Vagrant.configure("2") do |config|
  config.vm.box = "gusztavvargadr/w16s"
  config.vm.communicator = "winrm"
  
  # Set vagrant machine name
  config.vm.hostname = Node

  # Configure network
  config.vm.network "forwarded_port", host: 33389, guest: 3389
  config.vm.network "forwarded_port", host: 8080, guest: 80
  config.vm.network "forwarded_port", host: 4443, guest: 443
 
  # Perform file copy from Local machine to Vagrant box
  config.vm.provision "file", 
    source: CopySource,
    destination: CopyDestination
  
  # Create MOF   
  config.vm.provision "shell", 
    path: 'D:\VagrantDemo\DSC\Config\PS6TestServer.ps1',
    args: [Node, MOFfolder]
  
  # Invoke MOF file  
  config.vm.provision "shell",
    inline: "Start-DSCConfiguration -Path $Args[0] -Force -Wait -Verbose", 
    args: [MOFfolder]
  end
