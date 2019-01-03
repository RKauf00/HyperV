
#########################################################
###########                                   ###########
##########      For example purposes only      ##########
###########                                   ###########
#########################################################

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
Name:          newVM.ps1

Description:   Create and configure new virtual machine:
 
                 1. Creates New VM
                 2. Creates New VHD
                 3. Attaches VHD
                 4. Sets DVD ISO Path

Environment:   On-prem Hyper-V

Tested OS:     Windows Server 2016

Usage:         .\newVM.ps1 `
                   -Name <VMName> `
                   -Memory <#GB> `
                   -Location <VM Directory Path> `
                   -VSwitch01 <Virtual VSwitch Name> `
                   -ISOPath <Path to ISO> `
                   -VHDSize_OS <##GB> `
                   -VHDLocation_OS <VHD Directory Path> `
                   -VHDSize_Data <##GB> `
                   -VHDLocation_Data <VHD Directory Path>
                   
Example:       .\newVM.ps1 `
                   -Name 'MyNewVM' `
                   -Memory 8GB `
                   -Location "$((Get-VMHost).VirtualMachinePath)" `
                   -VSwitch01 'MyVNetVSwitch' `
                   -ISOPath 'C:\Temp\MyISO.iso' `
                   -VHDSize_OS 80GB `
                   -VHDLocation_OS "$((Get-VMHost).VirtualHardDiskPath)" `
                   -VHDSize_Data 100GB `
                   -VHDLocation_Data "$((Get-VMHost).VirtualHardDiskPath)"
 
Dependancies:  None

Deploys:       Single VM with one OS VHD and one Data VHD and 1-3 virtual networks

Note:          1. Can add 1, 2, or 3 virtual switches. 1 is required, 
                  2 and 3 are optional
               
               2. Generation 2 and VHDX values are hard coded

Date:          01/03/2019
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>

  ####################################################
  ###                                              ###
  ###                  Disclaimer                  ###
  ###                                              ###
  ###      This script is for example purposes     ###
  ###         only. Use only as a reference.       ###
  ###                                              ###
  ####################################################

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
    START EXAMPLE
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Param Values  --                                                                                                                                                                                                                                                                                                                                                                                                                                                                  #>

    Param
    (
        [Parameter(Mandatory=$TRUE)]
        [STRING] $Name,

        [Parameter(Mandatory=$TRUE)]
        [INT64] $Memory,

        [Parameter(Mandatory=$TRUE)]
        [STRING] $Location,

        [Parameter(Mandatory=$TRUE)]
        [STRING] $ISOPath,

        [Parameter(Mandatory=$TRUE)]
        [INT64] $VHDSize_OS,

        [Parameter(Mandatory=$TRUE)]
        [STRING] $VHDLocation_OS,

        [Parameter(Mandatory=$FALSE)]
        [INT64] $VHDSize_Data,

        [Parameter(Mandatory=$FALSE)]
        [STRING] $VHDLocation_Data,

        [Parameter(Mandatory=$TRUE)]
        [STRING] $VSwitch01,

        [Parameter(Mandatory=$FALSE)]
        [STRING] $VSwitch02,

        [Parameter(Mandatory=$FALSE)]
        [STRING] $VSwitch03
    )

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  VM Directory Check  --                                                                                                                                                                                                                                                                                                                                                                                                                                                            #>

    if (!(Test-Path $Location)) {  New-Item -Path $Location -ItemType Directory  }

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  VHD Directory Check  --                                                                                                                                                                                                                                                                                                                                                                                                                                                           #>

    if (!(Test-Path $VHDLocation_OS)) {  New-Item -Path $VHDLocation_OS -ItemType Directory  }

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  OS Disk Existance Check  --                                                                                                                                                                                                                                                                                                                                                                                                                                                       #>

    $Disk_OS = "$($VHDLocation_OS)\$($Name)_OS.vhdx"

    Remove-Variable VHDCheck -ErrorAction SilentlyContinue
    Get-VHD -Path $Disk_OS -ErrorVariable VHDCheck -ErrorAction SilentlyContinue | Out-Null
    if ((Get-Variable VHDCheck).Value -NotLike "*not an existing virtual*") {  'Break on VHD path check; disk already exists'  ;  Break  }
    Remove-Variable VHDCheck -ErrorAction SilentlyContinue

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Data Disk Existance Check  --                                                                                                                                                                                                                                                                                                                                                                                                                                                       #>

    if ($VHDLocation_Data -and $VHDSize_Data)
    {
        $Disk_Data = "$($VHDLocation_Data)\$($Name)_Data.vhdx"

        Remove-Variable VHDCheck -ErrorAction SilentlyContinue
        Get-VHD -Path $Disk_Data -ErrorVariable VHDCheck -ErrorAction SilentlyContinue | Out-Null
        if ((Get-Variable VHDCheck).Value -NotLike "*not an existing virtual*") {  'Break on VHD path check; disk already exists'  ;  Break  }
        Remove-Variable VHDCheck -ErrorAction SilentlyContinue
    }

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Virtual Machine Name Check  --                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>

    Remove-Variable VMCheck -ErrorAction SilentlyContinue
    Get-VM -Name $Name -OutVariable VMCheck -ErrorAction SilentlyContinue | Out-Null
    if (($VMCheck).Name -eq $Name) { 'Break on VM check; VM name in use'  ;  Break  }
    Remove-Variable VMCheck -ErrorAction SilentlyContinue

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Create Virtual Machine  --                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>

    New-VM `
        -Name $Name `
        -Path $Location `
        -Generation 2

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Create and Attach New OS VHDX  --                                                                                                                                                                                                                                                                                                                                                                                                                                                            #>
    
    New-VHD `
        -Path $Disk_OS `
        -SizeBytes $VHDSize_OS `
        -Dynamic

    Add-VMHardDiskDrive `
        -VMName $Name `
        -Path $Disk_OS

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    <#
  --  Create and Attach New Data VHDX  --                                                                                                                                                                                                                                                                                                                                                                                                                                                            #>

    if ($VHDLocation_Data -and $VHDSize_Data)
    {
    
        New-VHD `
            -Path $Disk_Data `
            -SizeBytes $VHDSize_Data `
            -Dynamic

        Add-VMHardDiskDrive `
            -VMName $Name `
            -Path $Disk_Data

    }

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Set DVD ISO Path  --                                                                                                                                                                                                                                                                                                                                                                                                                                                              #>

    Add-VMDvdDrive `
        -VMName $Name `
        -Path $ISOPath

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Set VM Memory  --                                                                                                                                                                                                                                                                                                                                                                                                                                                                 #>

    Get-VM $Name | Set-VMMemory -StartupBytes $Memory

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Set Virtual VSwitch 01  --                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>

    Connect-VMNetworkAdapter `
        -VMName $Name `
        -SwitchName $VSwitch01

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Set Virtual VSwitch 02  --                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>

    if (($VSwitch02 -ne '') -and ($VSwitch02 -ne $NULL))
    {
        Add-VMNetworkAdapter `
            -VMName $Name `
            -SwitchName $VSwitch02
    }

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
  --  Set Virtual VSwitch 03  --                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>

    if (($VSwitch03 -ne '') -and ($VSwitch03 -ne $NULL))
    {
        Add-VMNetworkAdapter `
            -VMName $Name `
            -SwitchName $VSwitch03
    }

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
   END EXAMPLE
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>

#########################################################
###########                                   ###########
##########      For example purposes only      ##########
###########                                   ###########
#########################################################

#########################################################
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        <#
   Disclaimer: 
    The sample scripts are not supported under 
    any Microsoft standard support program or 
    service. The sample scripts are provided AS IS 
    without warranty of any kind. Microsoft further 
    disclaims all implied warranties including, 
    without limitation, any implied warranties of 
    merchantability or of fitness for a particular 
    purpose. The entire risk arising out of the use 
    or performance of the sample scripts and 
    documentation remains with you. In no event 
    shall Microsoft, its authors, or anyone else 
    involved in the creation, production, or delivery 
    of the scripts be liable for any damages whatsoever 
    (including, without limitation, damages for loss of 
    business profits, business interruption, loss of 
    business information, or other pecuniary loss) 
    arising out of the use of or inability to use the 
    sample scripts or documentation, even if Microsoft 
    has been advised of the possibility of such damages.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        #>
#########################################################
