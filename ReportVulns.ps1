#Remove any DVD from client
$drv = (psdrive | where{$_.Free -eq 0})
if($drv.free -eq "0" -and $_.name -ne "C")
    {
    Write-Host "Eject DVD and try again"
    }
 
#Confirm for elevated admin
    if (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
    Write-Host "An elevated administrator account is required to run this script." -BackgroundColor Red
    }
else
{
    #Enable detection of PowerShell or ISE, enable to run from both
    #Script name has been defined and must be saved as that name.
    $VulnReport = "C:\VulnReport"
    if($psise -ne $null)
    {
        $ISEPath = $psise.CurrentFile.FullPath
        $ISEWork = $ISEPath.TrimEnd(".ReportVulns.ps1")
        New-Item -Path C:\VulnReport -ItemType Directory -Force
        $VulnReport = "C:\VulnReport"
    }
    else
    {
        $PSWork = split-path -parent $MyInvocation.MyCommand.Path
        New-Item -Path C:\VulnReport -ItemType Directory -Force
    }


function reports
{

<#
.Synopsis

.DESCRIPTION
   
  
.VERSION

211219.1 - Released to Github
211221.1 - Added Security Options
211222.1 - Changed f$Rep.Replace  | Out-File $Report to Foreach {$_ -replace "",""}
211222.2 - Added Warning to be RED with a replace and set-content
211223.1 - Added -postContent with explanations
211223.2 - Bitlocker fixed null response
211229.1 - Added explanations and changed colour.

#> 

################################################
#################  BITLOCKER  ##################
################################################

    #Bitlocker Details
    $fragBitLocker=@()
    $getBit = Get-BitLockerVolume -MountPoint C: | Select-Object * -ErrorAction SilentlyContinue
    $GetTPM = Get-Tpm -ErrorAction SilentlyContinue

    $BitMP = $getBit.MountPoint
    $BitEM = $getBit.EncryptionMethod
    $BitKP = $getBit.KeyProtector -Replace("{","") -replace("}","")
    $bitKPJ = $BitKP[0] +","+ $BitKP[1]+","+ $BitKP[2]
    $bitVS = $getBit.VolumeStatus
    $bitPS = $getBit.ProtectionStatus

    #TPM Details
    $TPMPres = $GetTPM.TpmPresent
    $TPMEn = $GetTPM.TpmEnabled
    $TPMVer = $GetTPM.ManufacturerVersion
    $TPMSpec = wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get specversion 
    $TPMSpecVer = $TPMSpec[2]

    if ($bitVS -eq "FullyEncrypted"){

    $newObjBit = New-Object psObject
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name MountPoint -Value $BitMP
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name EncryptionMethod -Value $BitEM
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name KeyProtector  -Value $BitKPJ
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name VolumeStatus -Value $bitVS
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name TPMPresent -Value $TPMPres
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name TPMEnabled  -Value $TPMEn
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name TPMManufacVersion -Value $TPMVer
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name TPMSpecVersion -Value $TPMSpecVer
    $fragBitLocker += $newObjBit
    }
    ELse
    { 
    $BitDisabled = "Warning - Bitlocker is disabled Warning"
    $newObjBit = New-Object psObject
    Add-Member -InputObject $newObjBit -Type NoteProperty -Name BitLockerDisabled -Value $BitDisabled
    $fragBitLocker += $newObjBit
    }

################################################
################  OS DETAILS  ##################
################################################

    #OS Details
    $hn = Get-CimInstance -ClassName win32_computersystem 
    $OS = Get-CimInstance -ClassName win32_operatingsystem
    $bios = Get-CimInstance -ClassName win32_bios
    $cpu = Get-CimInstance -ClassName win32_processor

################################################
##############  ACCOUNT DETAILS  ###############
################################################
    #Pasword Policy
    cd c:\
    $getPWPol = & net accounts
    $PassPol=@()
        foreach ($PWPol in $getPWPol)
        {

        $PWName = $PWPol.split(":")[0]
        $PWSet = $PWPol.split(":")[1]

        $newObjPassPol = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjPassPol -Type NoteProperty -Name PasswordPolicy -Value $PWName
        Add-Member -InputObject $newObjPassPol -Type NoteProperty -Name Value -Value $PWSet
        $PassPol += $newObjPassPol
        }

        #Accounts
        $getAcc = Get-LocalUser
        $AccountDetails=@()
        foreach ($AccName in $getAcc.name)
        {
        $accounts = Get-LocalUser $AccName
 
         $accName = $accounts.name
         $accEnabled = $accounts.Enabled
         $accLastLogon = $accounts.LastLogon
         $accLastPass = $accounts.PasswordLastSet
         $accPassExpired = $accounts.PasswordExpires
         $accSource = $accounts.PrincipalSource

        $newObjAccount = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjAccount -Type NoteProperty -Name AccountName -Value $accName
        Add-Member -InputObject $newObjAccount -Type NoteProperty -Name IsAccountEnabled -Value $accEnabled
        Add-Member -InputObject $newObjAccount -Type NoteProperty -Name AccountLastLogon -Value $accLastLogon
        Add-Member -InputObject $newObjAccount -Type NoteProperty -Name AccountLastPassChange -Value $accLastPass
        Add-Member -InputObject $newObjAccount -Type NoteProperty -Name AccountExpiresOn -Value $accPassExpired
        Add-Member -InputObject $newObjAccount -Type NoteProperty -Name AccountSource -Value $accSource
        $AccountDetails += $newObjAccount
        }

#Group Members
#Cant remove "," as looping the Split breaks HTML import...back to drawing board - to fix
        $getLGrp = Get-LocalGroup 
        $GroupDetails=@()
        foreach ($LGpItem in $getLGrp)
        {
        $grpName = $LGpItem.Name 
        $grpMember = Get-LocalGroupMember -Group $LGpItem.ToString()
        $grpMemSplit = $grpMember -split(",") -replace("{","") -replace("}","")
        $grpMemAdd = $grpMemSplit[0] +","+ $grpMemSplit[1]  +","+ $grpMemSplit[2]+","+ $grpMemSplit[3]+","+ $grpMemSplit[4]
        if ($grpMember -ne $null)
            {
            $newObjGroup = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjGroup -Type NoteProperty -Name GroupName -Value $grpName
            Add-Member -InputObject $newObjGroup -Type NoteProperty -Name GroupMembers -Value  $grpMemAdd
            $GroupDetails += $newObjGroup
            }
        }

################################################
##############  WINDOWS UPDATES  ###############
################################################
    $HotFix=@()
    $getHF = Get-HotFix   | Select-Object HotFixID,InstalledOn,Caption 

    foreach ($hfitem in $getHF)
    {
        $hfid = $hfitem.hotfixid
        $hfdate = $hfitem.installedon
        $hfurl = $hfitem.caption

        $newObjHF = New-Object psObject
        Add-Member -InputObject $newObjHF -Type NoteProperty -Name HotFixID -Value $hfid
        Add-Member -InputObject $newObjHF -Type NoteProperty -Name InstalledOn -Value ($hfdate).Date.ToString("dd-MM-yyyy")
        Add-Member -InputObject $newObjHF -Type NoteProperty -Name Caption -Value $hfurl 
        $HotFix += $newObjHF
    }

################################################
##############  INSTALLED APPS  ################
################################################

    $getUnin = Get-ChildItem  "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"
    $UninChild = $getUnin.Name.Replace("HKEY_LOCAL_MACHINE","HKLM:")
    $InstallApps =@()
    foreach ( $uninItem in  $UninChild)
    {
        $getUninItem = Get-ItemProperty $uninItem
        $UninDisN = $getUninItem.DisplayName -replace "$null",""
        $UninDisVer = $getUninItem.DisplayVersion -replace "$null",""
        $UninPub = $getUninItem.Publisher -replace "$null",""
        $UninDate = $getUninItem.InstallDate -replace "$null",""
        $newObjInstApps = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name Publisher -Value  $UninPub 
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name DisplayName -Value  $UninDisN
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name DisplayVersion -Value  $UninDisVer
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name InstallDate -Value   $UninDate
        $InstallApps += $newObjInstApps
    }
       
################################################
################  MSINFO32  #####################
################################################

    #Virtualization - msinfo32
    $VulnReport = "C:\VulnReport"
    $OutFunc = "MSInfo" 
                
    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
        if ($tpSec10 -eq $false)
        {
        New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
        }
    $msinfoPath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.txt"
    $msinfoPathcsv = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.csv"
    $msinfoPathXml = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.xml"

    & cmd /c msinfo32 /nfo "C:\VulnReport\output\$OutFunc\" /report $msinfoPath
    $getMsinfo = Get-Content $msinfoPath | select -First 50

    Set-Content -Path $msinfoPathcsv -Value 'Virtualization;On\Off'
    ($getMsinfo | Select-String "Secure Boot") -replace "off",";off" -replace "on",";on" |Out-File $msinfoPathcsv -Append
    ($getMsinfo | Select-String "Kernel DMA Protection") -replace "off",";off" -replace "on",";on" -replace "i;on","ion" |Out-File $msinfoPathcsv -Append
    ($getMsinfo | Select-String "Required Security Properties") -replace "ies	Ba","ies;	Ba" |Out-File $msinfoPathcsv -Append
    ($getMsinfo | Select-String "Available Security Properties") -replace "ies	Ba","ies;	Ba" |Out-File $msinfoPathcsv -Append 
    ($getMsinfo | Select-String "Services Configured") -replace "gured	Credenti","gured;	Credenti" |Out-File $msinfoPathcsv -Append
    ($getMsinfo | Select-String "Services Running") -replace "gured	Credenti","gured;	Credenti" |Out-File $msinfoPathcsv -Append
    ($getMsinfo | Select-String "Device Encryption Support") -replace "pport	Meet","pport;	Meet" |Out-File $msinfoPathcsv -Append

    Import-Csv $msinfoPathcsv -Delimiter ";" | Export-Clixml $msinfoPathXml
    $MsinfoClixml = Import-Clixml $msinfoPathXml 

    Get-Content $msinfoPathXml 

################################################
#############  MISC REG SETTINGS  ##############
################################################

#LSA
    $getLSA = Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\lsa\' 
    $getLSAPPL =  $getLSA.GetValue("RunAsPPL")

    $fragLSAPPL =@()

        if ($getLSAPPL -eq "1")
        {
        $lsaSet = "LSA is enabled the RunAsPPL is set to $getLSAPPL" 
        $lsaReg = "HKLM:\SYSTEM\CurrentControlSet\Control\lsa\"
        $lsaCom = "Win10 and above Credential Guard should be used for Domain joined clients"
        }
        else
        {
        $lsaSet = "Warning - LSA is disabled  set RunAsPPL to 1 Warning" 
        $lsaReg = "HKLM:\SYSTEM\CurrentControlSet\Control\lsa\"
        $lsaCom = "Required for Win8.1 and below"
        }

    $newObjLSA = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjLSA -Type NoteProperty -Name LSASetting -Value  $lsaSet
    Add-Member -InputObject $newObjLSA -Type NoteProperty -Name LSARegValue -Value $lsaReg 
    Add-Member -InputObject $newObjLSA -Type NoteProperty -Name LSAComment -Value $lsaCom
    $fragLSAPPL += $newObjLSA
        
#DLL Safe Search
    $getDLL = Get-Item 'HKLM:\System\CurrentControlSet\Control\Session Manager'
    $getDLLSafe =  $getDLL.GetValue("SafeDLLSearchMode")

    $fragDLLSafe =@()
        if ($getDLLSafe -eq "1")
        {
        $dllSet = " DLLSafeSearch is enabled the SafeDLLSearchMode is set to $getDLLSafe" 
        $dllReg = "HKLM:\System\CurrentControlSet\Control\Session Manager"
        $dllCom = "Protects against DLL search order hijacking"
        }
        else
        {
        $dllSet = "Warning - DLLSafeSearch is disabled set SafeDLLSearchMode to 1 Warning" 
        $dllReg = "HKLM:\System\CurrentControlSet\Control\Session Manager"
        $dllCom = "Protects against DLL search order hijacking"
        }

    $newObjDLLSafe = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjDLLSafe -Type NoteProperty -Name DLLSafeSetting -Value  $dllSet
    Add-Member -InputObject $newObjDLLSafe -Type NoteProperty -Name DLLSafeValue -Value $dllReg 
    Add-Member -InputObject $newObjDLLSafe -Type NoteProperty -Name DLLSafeComment -Value $dllCom
    $fragDLLSafe += $newObjDLLSafe


#Code Integrity
    $getCode = Get-Item 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
    $getCode =  $getCode.GetValue("Enabled")

    $fragCode =@()
        if ($getCode -eq "1")
        {
        $CodeSet = "Hypervisor Enforced Code Integrity is enabled" 
        $CodeReg = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
        $CodeCom = "Protects against credential theft"
        }
        else
        {
        $CodeSet = "Warning - Hypervisor Enforced Code Integrity is disabled set Enabled to 1 Warning" 
        $CodeReg = "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
        #$CodeCom = "Protects against credential theft"
        }

    $newObjCode = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjCode -Type NoteProperty -Name CodeSetting -Value  $CodeSet
    Add-Member -InputObject $newObjCode -Type NoteProperty -Name CodeValue -Value $CodeReg 
    #Add-Member -InputObject $newObjCode -Type NoteProperty -Name CodeComment -Value $CodeCom
    $fragCode += $newObjCode

#InstallElevated
   $getPCInstaller = Get-Item HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue
   $getUserInstaller = Get-Item HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue
   $PCElevate =  $getUserInstaller.GetValue("AlwaysInstallElevated")
   $UserElevate = $getPCInstaller.GetValue("AlwaysInstallElevated")

    $fragPCElevate =@()
        if ($PCElevate -eq "1")
                {
        $ElevateSet = "Warning - Client setting Always Install Elevate is enabled Warning" 
        $ElevateReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
        }
        else
        {
        $ElevateSet = "Client setting  Always Install Elevate is disabled" 
        $ElevateReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Installer"
        }

    $newObjElevate = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateSetting -Value  $ElevateSet
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateRegistry -Value $ElevateReg
    $fragPCElevate += $newObjElevate 

        if ($UserElevate -eq "1")
        {
        $ElevateSet = "Warning - User setting Always Install Elevate is enabled Warning" 
        $ElevateReg = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer"
        }
        else
        {
        $ElevateSet = "User setting Always Install Elevate is disabled" 
        $ElevateReg = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Installer"
        }
       
    $newObjElevate = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateSetting -Value  $ElevateSet
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateRegistry -Value $ElevateReg
    $fragPCElevate += $newObjElevate 

 #AutoLogon Details in REG inc password   
    $getAutoLogon = Get-Item  "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    $AutoLogonDefUser =  $getAutoLogon.GetValue("DefaultUserName")
    $AutoLogonDefPass =  $getAutoLogon.GetValue("DefaultPassword ") 

    $fragAutoLogon =@()

        if ($AutoLogonDefPass  -ne "$null")
        {
        $AutoLPass = "There is no Default Password set for AutoLogon" 
        $AutoLUser = "There is no Default User set for AutoLogon" 
        $AutoLReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon"
        }
        else
        {
        $AutoLPass = "Warning - AutoLogon default password is set with a vaule of $AutoLogonDefPass Warning" 
        $AutoLUser = "Warning - AutoLogon Default User is set with a vaule of $AutoLogonDefUser Warning" 
        $AutoLReg = "HKLM:\SOFTWARE\Microsoft\Windows NT\Currentversion\Winlogon"
        }

    $newObjAutoLogon = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjAutoLogon -Type NoteProperty -Name AutoLogonUsername -Value $AutoLUser
    Add-Member -InputObject $newObjAutoLogon -Type NoteProperty -Name AutoLogonPassword -Value  $AutoLPass
    Add-Member -InputObject $newObjAutoLogon -Type NoteProperty -Name AutoLogonRegistry -Value $AutoLReg
    $fragAutoLogon += $newObjAutoLogon
        
################################################
#########  LEGACY NETWORK PROTOCOLS  ##########
################################################
#Legacy Network
$VulnReport = "C:\VulnReport"
$OutFunc = "llmnr" 
    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
    New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }
    $llnmrpath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.log"
   
$fragLegNIC=@()
    #llmnr = 0 is disabled
    cd HKLM:
    $getllmnrGPO = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
    $enllmnrGpo = $getllmnrgpo.EnableMulticast

        if ($enllmnrGpo -eq "0" -or $enllmnrReg -eq "0")
        {
        $legProt = "LLMNR (Responder) is disabled GPO = $enllmnrGpo" 
        $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient.EnableMulticast"
        }
        else
        {
        $legProt = "Warning - LLMNR (Responder) is Enabled Warning" 
        $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient.EnableMulticast"
        }
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        $fragLegNIC += $newObjLegNIC


    #NetBIOS over TCP/IP (NetBT) queries = 0 is disabled
    cd HKLM:
    $getNetBTGPO = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
    $enNetBTGPO = $getNetBTGPO.QueryNetBTFQDN

        if ($enNetBTGPO -eq "0")
        {
        $legProt = "NetBios is disabled the Registry = $enNetBTGPO" 
        $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient.QueryNetBTFQDN"
        }
        else
        {
        $legProt = "Warning - NetBios is enabled Warning" 
        $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient.QueryNetBTFQDN"
        $legValue = $enNetBTGPO
        $legWarn = "Incorrect"
        }
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        $fragLegNIC += $newObjLegNIC
    

    #ipv6 0xff (255)
    cd HKLM:
    $getIpv6 = get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -ErrorAction SilentlyContinue
    $getIpv6Int = $getIpv6.DisabledComponents
        if ($getIpv6Int -eq "255")
        {
        $legProt = "IPv6 is disabled the Registry = $getIpv6Int" 
        $legReg = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters.DisabledComponents"
        }
        else
        {
        $legProt = "Warning - IPv6 is enabled Warning" 
        $legReg = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters.DisabledComponents"
        }
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        $fragLegNIC += $newObjLegNIC


    #Report on LMHosts file = 1
    cd HKLM:
    $getLMHostsReg = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters" -ErrorAction SilentlyContinue
    $enLMHostsReg =  $getLMHostsReg.EnableLMHosts
        if ($enLMHostsReg -eq "1")
        {
        $legProt = "LMHosts is disabled the Registry = $enLMHostsReg" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.EnableLMHosts"
        }
        else
        {
        $legProt = "Warning - Disable LMHosts Warning" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.EnableLMHosts"
        }
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        $fragLegNIC += $newObjLegNIC


    #NetBios Node Type set to 2 - Only Reg Setting
    cd HKLM:
    $getNetBtNodeReg = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters" -ErrorAction SilentlyContinue
    $enNetBTReg = $getNetBtNodeReg.NodeType
       if ($enNetBTReg -eq "2")
        {
        $legProt = "NetBios is set to $enLMHostsReg in the Registry" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.NodeType"
        }
        else
        {
        $legProt = "Warning - NetBios Node Type is set to $enNetBTReg, its incorrect and should be set to 2 Warning"
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.NodeType"
        }
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        $fragLegNIC += $newObjLegNIC

    #disable netbios
    cd HKLM:
    $getNetBiosInt = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces" -ErrorAction SilentlyContinue
    foreach ($inter in $getNetBiosInt )
        {
        $getNetNiosReg = Get-ItemProperty $inter.Name
        $NetBiosValue = $getNetNiosReg.NetbiosOptions
        $NetBiosPath = $getNetNiosReg.PSChildName
        $NEtBiosPara = $NetBiosPath,$NetBiosValue
            if ($enNetBTReg -eq "0")
            {
            $legProt = "NetBios is set to $enLMHostsReg in the Registry" 
            $legReg = "HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces.$NetBiosPath"
            }
            else
            {
            $legProt = "Warning - NetBios is set to $enNetBTReg, its incorrect and should be set to 2 Warning"
            $legReg = "HKLM:\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces.$NetBiosPath"
            }
            $newObjLegNIC = New-Object psObject
            Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
            Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
            $fragLegNIC += $newObjLegNIC
          }

     cd HKLM:
    $getPeer = Get-ItemProperty  "HKLM:\Software\policies\Microsoft\Peernet" -ErrorAction SilentlyContinue
    $getPeerDis = $getPeer.Disabled
       if ($getPeerDis -eq "0")
        {
        $legProt = "Peer to Peer is set to $getPeerDis and disabled" 
        $legReg = "HKLM:\Software\policies\Microsoft\Peernet"
        }
        else
        {
        $legProt = "Warning - Peer to Peer is enabled Warning"
        $legReg = "HKLM:\Software\policies\Microsoft\Peernet"
        }
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        $fragLegNIC += $newObjLegNIC

    
    #Enable Font Providers
     cd HKLM:
    $getFont = Get-ItemProperty  "HKLM:\Software\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue
    $getFontPr = $getFont.EnableFontProviders
       if ( $getFontPr -eq "0")
        {
        $legProt = "Enable Font Providers is set to  $getFontPr disabled" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\System"
        }
        else
        {
        $legProt = "Warning - Enable Font Providers is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\System"
        }
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        $fragLegNIC += $newObjLegNIC

    #LLTD
    $getNetLLTDInt = Get-item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD" -ErrorAction SilentlyContinue

    $getLTDIO =  $getNetLLTDInt.GetValue("EnableLLTDIO")
    $getRspndr = $getNetLLTDInt.GetValue("EnableRspndr")
    $getOnDomain =  $getNetLLTDInt.GetValue("AllowLLTDIOOnDomain")
    $getPublicNet = $getNetLLTDInt.GetValue("AllowLLTDIOOnPublicNet")
    $getRspOnDomain = $getNetLLTDInt.GetValue("AllowRspndrOnDomain")
    $getRspPublicNet = $getNetLLTDInt.GetValue("AllowRspndrOnPublicNet")
    $getLLnPrivateNet = $getNetLLTDInt.GetValue("ProhibitLLTDIOOnPrivateNet") 
    $getRspPrivateNet = $getNetLLTDInt.GetValue("ProhibitRspndrOnPrivateNet")

    #EnableLLTDIO
    if ($getLTDIO -eq "0")
    {
       $legProt = "EnableLLTDIO is set to $getLTDIO in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    else
    {
       $legProt = "Warning - EnableLLTDIO is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC


    #EnableRspndr
    if ($getRspndr -eq "0")
    {
       $legProt = "EnableRspndr is set to $getRspndr in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
     }
    else
    {
       $legProt = "Warning - EnableRspndr is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC


    #AllowLLTDIOOnDomain
    if ($getOnDomain -eq "0")
    {
       $legProt = "AllowLLTDIOOnDomain is set to $getOnDomain in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    else
    {
       $legProt = "Warning - AllowLLTDIOOnDomain is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC
    

    #AllowLLTDIOOnPublicNet
    if ($getPublicNet -eq "0")
    {
       $legProt = "AllowLLTDIOOnPublicNet is set to $getPublicNet in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    else
    {
       $legProt = "Warning - AllowLLTDIOOnPublicNet is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC
    
   
    #AllowRspndrOnDomain  
    if ($getRspOnDomain -eq "0")
    {
       $legProt = "AllowRspndrOnDomain is set to $getRspOnDomain in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    else
    {
       $legProt = "Warning - AllowRspndrOnDomain is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC

    #AllowRspndrOnPublicNet    
    if ($getRspPublicNet -eq "0")
    {
       $legProt = "AllowRspndrOnPublicNet is set to $getRspPublicNet in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    else
    {
       $legProt = "Warning - AllowRspndrOnPublicNet is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC
   
   
    #ProhibitLLTDIOOnPrivateNe
    if ($getLLnPrivateNet -eq "1")
    {
       $legProt = "ProhibitLLTDIOOnPrivateNet is set to $getLLnPrivateNet in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    else
    {
       $legProt = "Warning - ProhibitLLTDIOOnPrivateNet is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC

   
    #ProhibitRspndrOnPrivateNet      $getRspPrivateNet = $getNetLLTDInt.GetValue("ProhibitRspndrOnPrivateNet")
    if ($getRspPrivateNet -eq "1")
    {
       $legProt = "ProhibitLLTDIOOnPrivateNet is set to $getRspPrivateNet in the Registry" 
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    else
    {
       $legProt = "Warning - ProhibitLLTDIOOnPrivateNet is enabled Warning"
       $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LLTD"
    }
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    $fragLegNIC += $newObjLegNIC
  
################################################
############  SECURITY OPTIONS  ################
################################################ 
    $fragSecOptions=@()
    $secOpTitle1 = "Domain member: Digitally encrypt or sign secure channel data (always)" # = 1
    $getSecOp1 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters'
    $getSecOp1res = $getSecOp1.getvalue("RequireSignOrSeal")

        if ($getSecOp1res -eq "1")
        {
        $SecOptName = "$secOpTitle1 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle1 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions 


    $secOpTitle2 = "Microsoft network client: Digitally sign communications (always)" # = 1
    $getSecOp2 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
    $getSecOp2res = $getSecOp2.getvalue("RequireSecuritySignature")

        if ($getSecOp2res -eq "1")
        {
        $SecOptName = "$secOpTitle2 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle2 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions 


    $secOpTitle3 = "Microsoft network server: Digitally sign communications (always)" # = 1
    $getSecOp3 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
    $getSecOp3res = $getSecOp3.getvalue("RequireSecuritySignature")

        if ($getSecOp3res -eq "1")
        {
        $SecOptName = "$secOpTitle3 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle3 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions 


    $secOpTitle4 = "Microsoft network client: Send unencrypted password to connect to third-party SMB servers" #  = 0
    $getSecOp4 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters'
    $getSecOp4res = $getSecOp4.getvalue("EnablePlainTextPassword")

        if ($getSecOp4res -eq "0")
        {
        $SecOptName = "$secOpTitle4 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle4 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions 


    $secOpTitle5 = "Network security: Do not store LAN Manager hash value on next password change" #  = 1
    $getSecOp5 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\'
    $getSecOp5res = $getSecOp5.getvalue("NoLmHash")

        if ($getSecOp5res -eq "1")
        {
        $SecOptName = "$secOpTitle5 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle5 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions


    $secOpTitle6 = "Network security: LAN Manager authentication level (Send NTLMv2 response only\refuse LM & NTLM)" #  = 5
    $getSecOp6 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\'
    $getSecOp6res = $getSecOp6.getvalue("lmcompatibilitylevel")

        if ($getSecOp6res -eq "5")
        {
        $SecOptName = "$secOpTitle6 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle6 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions


    $secOpTitle7 = "Network access: Do not allow anonymous enumeration of SAM accounts" #  = 1
    $getSecOp7 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\'
    $getSecOp7res = $getSecOp7.getvalue("restrictanonymoussam")

        if ($getSecOp7res -eq "1")
        {
        $SecOptName = "$secOpTitle7 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle7 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions


    $secOpTitle8 = "Network access: Do not allow anonymous enumeration of SAM accounts and shares" #  = 1
    $getSecOp8 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\'
    $getSecOp8res = $getSecOp8.getvalue("restrictanonymous")

        if ($getSecOp8res -eq "1")
        {
        $SecOptName = "$secOpTitle8 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle8 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions

    $secOpTitle9 = "Network access: Let Everyone permissions apply to anonymous users" # = 0
    $getSecOp9 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\'
    $getSecOp9res = $getSecOp9.getvalue("everyoneincludesanonymous")

        if ($getSecOp9res -eq "0")
        {
        $SecOptName = "$secOpTitle9 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle9 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions

    $secOpTitle10 = "Network security: LDAP client signing requirements" # = 2 Required
    $getSecOp10 = get-item 'HKLM:\SYSTEM\CurrentControlSet\Services\NTDS\parameters'
    $getSecOp10res = $getSecOp10.getvalue("ldapserverintegrity")

        if ($getSecOp9res -eq "2")
        {
        $SecOptName = "$secOpTitle10 - Enabled"
        }
        else
        {
        $SecOptName = "Warning - $secOpTitle10 - Disabled Warning"
        }
        $newObjSecOptions = New-Object psObject
        Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
        $fragSecOptions +=  $newObjSecOptions


#Network access: Restrict anonymous access to Named Pipes and Shares
#Network security: Do not store LAN Manager hash value on next password change


################################################
############  FIREWALL DETAILS  ################
################################################                
    #Firewall Enabled \ Disabled

    $getFWProf = Get-NetFirewallProfile -PolicyStore activestore
    $fragFWProfile=@()
    Foreach ( $fwRule in $getFWProf){

    $fwProfileNa = $fwRule.Name
    $fwProfileEn = $fwRule.Enabled
    $fwProfileIn = $fwRule.DefaultInboundAction 
    $fwProfileOut = $fwRule.DefaultOutboundAction 
     
     $newObjFWProf = New-Object psObject
     Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Name -Value $fwProfileNa
     Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Enabled -Value $fwProfileEn
     Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Inbound -Value $fwProfileIn
     Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Outbound -Value $fwProfileOut
     $fragFWProfile += $newObjFWProf 
    }

    #Firewall Rules
    $VulnReport = "C:\VulnReport"
    $OutFunc = "firewall" 
                
    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
    New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }
    $fwpath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.log"
    $fwpathcsv = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.csv"
    $fwpathxml = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.xml"

    [System.Text.StringBuilder]$fwtxt = New-Object System.Text.StringBuilder

   $getFw = Get-NetFirewallRule | 
   Select-Object Displayname,ID,Enabled,Direction,Action,Status  | 
   where {$_.enabled -eq "true"} | 
   Sort-Object direction -Descending
   foreach($fw in $getFw)
        {
        $fwID = $fw.ID
        $fwAddFilter = Get-NetFirewallAddressFilter | where {$_.InstanceID -eq $fwID}
        $fwPrtFilter = Get-NetFirewallPortFilter | where {$_.InstanceID -eq $fwID}
        $fwAppFilter = Get-NetFirewallApplicationFilter | where {$_.InstanceID -eq $fwID}
        $fwtxt.Append($fw.DisplayName)
        $fwtxt.Append(", ")
        $fwtxt.Append($fw.Direction)
        $fwtxt.Append(", ")
        $fwtxt.Append($fwPrtFilter.Protocol)
        $fwtxt.Append(", ")
        $fwtxt.Append($fwAddFilter.LocalIP)
        $fwtxt.Append(", ")
        $fwtxt.Append($fwID.RemoteIP)
        $fwtxt.Append(", ")
        $fwtxt.Append($fwPrtFilter.LocalPort)
        $fwtxt.Append(", ")
        $fwtxt.Append($fwPrtFilter.RemotePort)
        $fwtxt.Append(", ")
        $fwtxt.Append($fwAppFilter.Program)
        $fwtxt.AppendLine()

    Set-Content -Path $fwpath -Value 'DisplayName,Direction,Protocol,LocalIP,LocalPort,RemoteIP,RemotePort,Program'
    }
    Add-Content -Path $fwpath -Value $fwtxt
    # $fwtxt = $null
    Get-Content $fwpath | Out-File $fwpathcsv
    $fwCSV = Import-Csv $fwpathcsv -Delimiter "," | Export-Clixml $fwpathxml
    $fragFW = Import-Clixml $fwpathxml


################################################
############  UNQUOTED PATHS  ##################
################################################
    #Unquoted paths   
    $VulnReport = "C:\VulnReport"
    $OutFunc = "UnQuoted" 
                
    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
    New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }
    $qpath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.log"
 
    #Unquoted paths
    $vulnSvc = gwmi win32_service | foreach{$_} | 
    where {($_.pathname -ne $null) -and ($_.pathname.trim() -ne "")} | 
    where {-not $_.pathname.startswith("`"")} | 
    where {($_.pathname.substring(0, $_.pathname.indexof(".exe") + 4 )) -match ".* .*" }
    $fragUnQuoted=@()
    foreach ($unQSvc in $vulnSvc)
    {
    $svc = $unQSvc.name
    $SvcReg = Get-ItemProperty HKLM:\SYSTEM\CurrentControlSet\Services\$svc
    if ($SvcReg.imagePath -like "*.exe*")
    {
    $SvcRegSp =  $SvcReg.imagePath -split ".exe"
    $SvcRegSp0 = $SvcRegSp[0]
    $SvcRegSp1 = $SvcRegSp[1]
    $image = "`"$SvcRegSp0" + ".exe`""+  " " + $SvcRegSp1
    $SvcReg |Select-Object PSChildName,ImagePath  | out-file $qpath -Append
                
    $newObjSvc = New-Object psObject
    Add-Member -InputObject $newObjSvc -Type NoteProperty -Name ServiceName -Value $SvcReg.PSChildName
    Add-Member -InputObject $newObjSvc -Type NoteProperty -Name Path -Value $SvcReg.ImagePath 
    $fragUnQuoted += $newObjSvc
    }
    if ($SvcReg.imagePath -like "*.sys*")
    {
    $SvcRegSp =  $SvcReg.imagePath -split ".sys"
    $SvcRegSp0 = $SvcRegSp[0]
    $SvcRegSp1 = $SvcRegSp[1]
    $image = "`"$SvcRegSp0" + ".sys`""+   " $SvcRegSp1"
    $SvcReg |Select-Object PSChildName,ImagePath  | out-file $qpath -Append
                       
    $newObjSvc = New-Object psObject
    Add-Member -InputObject $newObjSvc -Type NoteProperty -Name ServiceName -Value $SvcReg.PSChildName
    Add-Member -InputObject $newObjSvc -Type NoteProperty -Name Path -Value $SvcReg.ImagePath 
    $fragUnQuoted += $newObjSvc
    }
    if ($SvcReg.imagePath -like "*.exe") 
    {
    $image = $SvcReg.ImagePath
    $SvcReg |Select-Object PSChildName,ImagePath  | out-file $qpath -Append
    $newObjSvc = New-Object psObject
    Add-Member -InputObject $newObjSvc -Type NoteProperty -Name ServiceName -Value $SvcReg.PSChildName
    Add-Member -InputObject $newObjSvc -Type NoteProperty -Name Path -Value $SvcReg.ImagePath 
    $fragUnQuoted += $newObjSvc
    }
    }

################################################
############  WRITEABLE FILES  #################
################################################

    $VulnReport = "C:\VulnReport"
    $OutFunc = "WriteableFiles"  

    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
    New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $hpath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.log"

    $hfiles =  Get-ChildItem C:\  | where {$_.Name -eq "PerfLogs" -or ` 
    $_.Name -eq "Program Files" -or `
    $_.Name -eq "Program Files (x86)"} # -or `
       # $_.Name -eq "Windows"}

    $filehash = @()
    foreach ($hfile in $hfiles.fullname)
        {
            $subfl = Get-ChildItem -Path $hfile -force -Recurse -Include *.exe, *.dll
            $filehash+=$subfl
            $filehash 
        }
    foreach ($cfile in $filehash.fullname)
        {
        $cfileAcl = Get-Acl $cfile -ErrorAction SilentlyContinue
        if ($cfileAcl | where {$_.accesstostring -like "*Users Allow  Write*" -or $_.accesstostring -like "*Users Allow  Modify*" -or $_.accesstostring -like "*Users Allow  FullControl*"})
            {
                $cfile | Out-File $hpath -Append
            }
            if ($cfileAcl | where {$_.accesstostring -like "*Everyone Allow  Write*" -or $_.accesstostring -like "*Everyone Allow  Modify*" -or $_.accesstostring -like "*Everyone Allow  FullControl*"})
            {
                $cfile | Out-File $hpath -Append
            }
            if ($cfileAcl | where {$_.accesstostring -like "*Authenticated Users Allow  Write*" -or $_.accesstostring -like "*Authenticated Users Allow  Modify*" -or $_.accesstostring -like "*Authenticated Users Allow  FullControl*"})
            {
                $cfile | Out-File $hpath -Append
            }
        }
        $wFileDetails = Get-Content  $hpath #|  where {$_ -ne ""} |select -skip 3

        #Declares correctly formated hash for OS Information 
        $fragwFile =@()
        foreach ($wFileItems in $wFileDetails)
            {
            $newObjwFile = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjwFile -Type NoteProperty -Name WriteableFiles -Value $wFileItems
            $fragwFile += $newObjwFile
            }

################################################
#########  WRITEABLE REGISTRY HIVES  ###########
################################################

    $VulnReport = "C:\VulnReport"
    $OutFunc = "WriteableReg"  

    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $rpath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.log"

    #Registry Permissions
    $HKLMSvc = 'HKLM:\SYSTEM\CurrentControlSet\Services'
    $HKLMSoft = 'HKLM:\Software'
    $HKLMCheck = $HKLMSoft,$HKLMSvc

    Foreach ($key in $HKLMCheck) 
        {
            #Get a list of key names and make a variable
            cd hklm:
            $SvcPath = Get-childItem $key -Recurse -Depth 1 | where {$_.Name -notlike "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\*"}
            #Update HKEY_Local.... to HKLM:
            $RegList = $SvcPath.name.replace("HKEY_LOCAL_MACHINE","HKLM:")
            Foreach ($regPath in $RegList)
        {
    $acl = Get-Acl $regPath
    $acc = $acl.AccessToString
    Write-Output  $regPath
    foreach ($ac in $acc)
    {
    if ($ac | Select-String -SimpleMatch "BUILTIN\Users Allow  FullControl")
        {
            $regPath | Out-File $rpath -Append
        } 

    if ($ac | Select-String -SimpleMatch "NT AUTHORITY\Authenticated Users Allow  FullControl")
        {
            $regPath | Out-File $rpath -Append
        }
    if ($ac | Select-String -SimpleMatch "Everyone Allow  FullControl")
         {
            $regPath | Out-File $rpath -Append
         }
    }
  }
    $regDetails = Get-Content  $rpath #|  where {$_ -ne ""} |select -skip 3

    $fragReg =@()
    foreach ($regItems in $regDetails)
        {
        $newObjReg = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjReg -Type NoteProperty -Name RegWeakness -Value $regItems
        $fragReg += $newObjReg
        }
}

################################################
#############  WRITEABLE FOLDERS  ##############
############  NON SYSTEM FOLDERS  ##############
################################################

    $VulnReport = "C:\VulnReport"
    $OutFunc = "WriteableFolders"  

    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }
    $fpath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.log"
    
    #Additional Folders off the root of C: that are not system
    $hfolders =  Get-ChildItem c:\  | where {$_.Name -ne "PerfLogs" -and ` 
    $_.Name -ne "Program Files" -and `
    $_.Name -ne "Program Files (x86)" -and `
    $_.Name -ne "Users" -and `
    $_.Name -ne "Windows"}

    $foldhash = @()
    foreach ($hfold in $hfolders.fullname)
        {
            $subfl = Get-ChildItem -Path $hfold -Directory -Recurse -Force
            $foldhash+=$hfolders
            $foldhash+=$subfl
        }
    foreach ($cfold in $foldhash.fullname)
    {
    $cfoldAcl = Get-Acl $cfold -ErrorAction SilentlyContinue
    if ($cfoldAcl | where {$_.accesstostring -like "*Users Allow  Write*" -or $_.accesstostring -like "*Users Allow  Modify*" -or $_.accesstostring -like "*Users Allow  FullControl*"})
        {
            $cfold | Out-File $fpath -Append
       }
     if ($cfoldAcl | where {$_.accesstostring -like "*Everyone Allow  Write*" -or $_.accesstostring -like "*Everyone Allow  Modify*" -or $_.accesstostring -like "*Everyone Allow  FullControl*"})
        {
            $cfold | Out-File $fpath -Append
        }
     if ($cfoldAcl | where {$_.accesstostring -like "*Authenticated Users Allow  Write*" -or $_.accesstostring -like "*Authenticated Users Allow  Modify*" -or $_.accesstostring -like "*Authenticated Users Allow  FullControl*"})
        {
            $cfold | Out-File $fpath -Append
        } 

        get-content $fpath | Sort-Object -Unique | set-Content $fpath 

        #Get content and remove the first 3 lines
        $wFolderDetails = Get-Content  $fpath #|  where {$_ -ne ""} |select -skip 3

        #Declares correctly formated hash for OS Information 
        $fragwFold =@()
        foreach ($wFoldItems in $wFolderDetails)
            {
            $newObjwFold = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjwFold -Type NoteProperty -Name FolderWeakness -Value $wFoldItems
            $fragwFold += $newObjwFold
            }
    }  
 
################################################
#############  WRITEABLE FOLDERS  ##############
###############  SYSTEM FOLDERS  ###############
################################################
    
    $VulnReport = "C:\VulnReport"
    $OutFunc = "SystemFolders"  

    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }
    $sysPath = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.log"
    
    $sysfolders =  Get-ChildItem C:\  | where {$_.Name -eq "PerfLogs" -or ` 
    $_.Name -eq "Program Files" -or `
    $_.Name -eq "Program Files (x86)"} # -or `
    #$_.Name -eq "Windows"}
    $sysfoldhash = @()
    foreach ($sysfold in $sysfolders.fullname)
        {
            $subsysfl = Get-ChildItem -Path $sysfold -Directory -Recurse -Force
            $sysfoldhash+=$subsysfl
        }
    foreach ($syfold in $sysfoldhash.fullname)
        {
            $syfoldAcl = Get-Acl $syfold -ErrorAction SilentlyContinue
            if ($syfoldAcl | where {$_.accesstostring -like "*Users Allow  Write*" -or $_.accesstostring -like "*Users Allow  Modify*" -or $_.accesstostring -like "*Users Allow  FullControl*"})
            {
                $syfold | Out-File $sysPath -Append
            }
         if ($syfoldAcl | where {$_.accesstostring -like "*Everyone Allow  Write*" -or $_.accesstostring -like "*Everyone Allow  Modify*" -or $_.accesstostring -like "*Everyone Allow  FullControl*"})
            {
                $syfold | Out-File $sysPath -Append
            }
            if ($syfoldAcl | where {$_.accesstostring -like "*Authenticated Users Allow  Write*" -or $_.accesstostring -like "*Authenticated Users Allow  Modify*" -or $_.accesstostring -like "*Authenticated Users Allow  FullControl*"})
            {
                $syfold | Out-File $sysPath -Append
            }

        get-content $sysPath | Sort-Object -Unique | set-Content $sysPath 

        #Get content and remove the first 3 lines
        $sysFolderDetails = Get-Content  $sysPath #|  where {$_ -ne ""} |select -skip 3

        #Declares correctly formated hash for OS Information 
        $fragsysFold =@()
        foreach ($sysFoldItems in $sysFolderDetails)
            {
            $newObjsysFold = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjsysFold -Type NoteProperty -Name FolderWeakness -Value $sysFoldItems
            $fragsysFold += $newObjsysFold
            }
        }

################################################
############  EMBEDDED PASSWORDS  ##############
################################################  

#Passwords in Processes
    $getPSPass = gwmi win32_process | Select-Object Caption, Description,CommandLine | where {$_.commandline -like "*pass*" -or $_.commandline -like "*credential*" -or $_.commandline -like "*username*"  }

    $fragPSPass =@()
        foreach ($PStems in $getPSPass)
        {
        $PSCap = $PStems.Caption
        $PSDes = $PStems.Description
        $PSCom = $PStems.CommandLine

        $newObjPSPass = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjPSPass -Type NoteProperty -Name ProcessCaption -Value  $PSCap
        Add-Member -InputObject $newObjPSPass -Type NoteProperty -Name ProcessDescription -Value  $PSDes
        Add-Member -InputObject $newObjPSPass -Type NoteProperty -Name ProcessCommandLine -Value  $PSCom
        $fragPSPass += $newObjPSPass
        }


#passwords embedded in files
#findstrg /si password *.txt - alt
    $getUserFolder = Get-ChildItem -Path "C:\Users\","C:\ProgramData\","C:\Windows\System32\Tasks\" -Recurse -Force -ErrorAction SilentlyContinue | 
    where {$_.Extension -eq ".txt"  -or $_.Extension -eq ".ini"} #-or $_.Extension -eq ".xml" }  #xml increase output, breaks report

    $passwordExcluded = $getUserFolder | where {$_.DirectoryName -notlike "*Packages*" -and $_.DirectoryName -notlike "*Containers\BaseImages*"}
    $fragFilePass=@()
    foreach ($PassFile in $passwordExcluded)
    {
    $SelectPassword  = Get-Content $PassFile.FullName |  Select-String -Pattern password, credential
 
    if ($SelectPassword -like "*password*")
        {
        $newObjFilePass = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjFilePass -Type NoteProperty -Name FilesContainingPassword -Value  $PassFile.FullName 
        $fragFilePass += $newObjFilePass
        }
    }

     
################################################
##########  HTML GENERATION  ###################
################################################

#B87333 = copper
#250F00 = root beer
#181818 = alt background 
#4682B4 = Blue dark pastel
#FF4040 = Red pastel
#DBDBDB = grey
#766A6A = Dark Grey with hint of beige
#A88F7E = mouse
#<font color="red"> <font>

#HTML GENERATOR CSS
 $style = @"
    <Style>
    body
    {
        background-color:#250F00; 
        color:#B87333;
        font-size:100%;
        font-family:helvetica;
        margin:0,0,10px,0; 
        word-break:normal; 
        word-wrap:break-word
    }
    table
    {
        border-width: 1px;
        padding: 7px;
        border-style: solid;
        border-color:#B87333;
        border-collapse:collapse;
        width:auto
    }
    h1
    {
        background-color:#250F00; 
        color:#B87333;
        font-size:150%;
        font-family:helvetica;
        margin:0,0,10px,0;
        word-break:normal; 
        word-wrap:break-word
    }
    h2
    {
        background-color:#250F00; 
        color:#B87333;
        font-size:120%;
        font-family:helvetica;
        margin:0,0,10px,0; 
        word-break:normal; 
        word-wrap:break-word
    }
    h3
    {
        background-color:#250F00; 
        color:#B87333;
        font-size:100%;
        font-family:helvetica;
        margin:0,0,10px,0; 
        word-break:normal; 
        word-wrap:break-word;
        font-weight: normal;
        width:auto
    }
        h4
    {
        background-color:#250F00; 
        color:#766A6A ;
        font-size:90%;
        font-family:helvetica;
        margin:0,0,10px,0; 
        word-break:normal; 
        word-wrap:break-word;
        font-weight: normal
    }
    th
    {
        border-width: 1px;
        padding: 7px;
        border-style: solid;
        border-color:#B87333;
        background-color:#250F00
    }
    td
    {
        border-width: 1px;
        padding:7px;
        border-style: solid; 
        border-style: #B87333
    }
    tr:nth-child(odd) 
    {
        background-color:#250F00;
    }
    tr:nth-child(even) 
    {
        background-color:#181818;
    }

    </Style>
"@
 
    $VulnReport = "C:\VulnReport"
    $OutFunc = "SystemReport"  
    $tpSec10 = Test-Path "C:\VulnReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\VulnReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $working = "C:\VulnReport\output\$OutFunc\"
    $Report = "C:\VulnReport\output\$OutFunc\" + "$OutFunc.html"

################################################
##########  HELPS AND DESCRIPTIONS  ############
################################################

$Intro = "Thanks for using the vulnerability report written by Tenaka.net, please show your support and visit my site, its non-profit and Ad free. Any issues with the reports accuracy please do let me know and I'll get it fixed asap. The results in this report are a guide and not a guarantee that the tested system is not without further defect or vulnerability. 
The tests focus on known and common issues with Windows that can be exploited by an attacker. Each section contains a small snippet to provide some context, follow the links for furhter detail."

$Intro2 = "The results in this report are a guide and not a guarantee that the tested system is not without further defect or vulnerability. 
The tests focus on known and common issues with Windows that can be exploited by an attacker. Each section contains a small snippet to provide some context, follow the links for furhter detail."

$Finish = "This script has been provided by Tenaka.net, if its beneficial, please provide feedback and any additional feature requests gratefully received. "

$descripBitlocker = "TPM and Bitlocker protect against offline attack from usb and mounting the local Windows system then accessing the local data. 'TPM and Pin' enhances Bitlocker by preventing LPC Bus (Low Pin Count) bypasses of Bitlocker with TPM. Further reading can be found @ https://www.tenaka.net/bitlocker"

$descripVirt = "Secure Boot is a security standard to ensure only trusted OEM software is allowed at boot. At startup the UEFi and boot software's digital signatures are validated preventing rootkits More on Secure Boot can be found here @ https://media.defense.gov/2020/Sep/15/2002497594/-1/-1/0/CTR-UEFI-SECURE-BOOT-CUSTOMIZATION-20200915.PDF/CTR-UEFI-SECURE-BOOT-CUSTOMIZATION-20200915.PDF"

$descripVirt2 = "Virtualization-based security (VBS), isolates core system resources to create secure regions of memory. Enabling VBS allows for Hypervisor-Enforced Code Integrity (HVCI), Device Guard and Credential Guard. Further reading can be found @ https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-vbs and https://www.tenaka.net/deviceguard-vs-rce and https://www.tenaka.net/pass-the-hash "

$descripSecOptions = "Prevent credential relay with Impacket and Man in the Middle by Digitally Signing for SMB and LDAP connections enforcement. Further reading can be found @ https://www.tenaka.net/smb-relay-attack"

$descripLSA = "Enabling RunAsPPL for LSA Protection allows only digitally signed binaries to load as a protected process preventing credential theft and access by code injection and memory access by processes that aren’t signed. Further reading can be found @ https://docs.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection"

$descripDLL = "When applications do not fully qualify the DLL path and instead allow searching the default behaviour if for the ‘Current Working Directory’ called 2nd in the list of directories. This allows an easy route to calling malicious DLL’s. Setting ‘DLL Safe Search’ mitigates the risk by moving CWD to later in the search order. Further reading can be found @ https://docs.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order"

$descripHyper = "Hypervisor Enforced Code Integrity prevents the loading of unsigned kernel-mode drivers and system binaries from being loaded into system memory. Further reading can be found @  https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity"

$descripElev = "Auto Elevate User is a setting that elevates users allowing them to install software without being an administrator. "

$descripFilePw = "Files that contain password or credentials"

$descripAutoLogon = "MECM\SCCM\MDT could leave Autologon credentials including a clear text password in the Registry."

$descripUnquoted = "The Unquoted paths vulnerability is when a Windows Service's 'Path to Executable' contains spaces and not wrapped in double quotes providing a route to System. Further reading can be found @ https://www.tenaka.net/unquotedpaths"

$descripProcPw = "Processes that contain credentials to authenticate and access applications. Launching Task Manager, Details and add ‘Command line’ to the view."

$descripLegacyNet = "LLMNR and other legacy network protocols can be used to steal password hashes. Further reading can be found @https://www.tenaka.net/responder"

$descripRegPer ="Weak Registry permissions allowing users to change the path to launch malicious software @ https://www.tenaka.net/unquotedpaths"

$descripSysFold = "System default folders. Weak folder permissions allowing users to swap out a file for a malicious file. Search does not include C:\Windows\ due to the time required. Further reading can be found @ https://www.tenaka.net/unquotedpaths"

$descripNonFold = "A vulnerability exists when enterprise software has been installed on the root of C:\. The default permissions allow a user to replace approved software binaries with malicious binaries. Further reading can be found @ https://www.tenaka.net/unquotedpaths"

$descripFile = "System files that allowing users to write can be swapped out for malicious software binaries. Further reading can be found @ https://www.tenaka.net/unquotedpaths"

$descripFirewalls = "Firewalls should always block inbound and exceptions should be to a named IP and Port. Further reading can be found @ https://www.tenaka.net/whyhbfirewallsneeded" 



################################################
################  FRAGMENTS  ###################
################################################
  
    #Top and Tail
    $FragDescrip1 =  $Descrip1 | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:helvetica;>$Intro</span></h3>" | Out-String
    $FragDescrip2 =  $Descrip2 | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:helvetica;>$Intro2</span></h3>" | Out-String
    $FragDescripFin =  $DescripFin | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:helvetica;>$Finish</span></h3>" | Out-String
    
    $Frag_descripVirt2 = ConvertTo-Html -as table -Fragment -PostContent "<h4>$descripVirt2</h4>" | Out-String
    
        
    #Host details    
    $fragHost = $hn | ConvertTo-Html -As List -Property Name,Domain,Model -fragment -PreContent "<h2><span style='color:#4682B4'>Host Details</span></h2>"  | Out-String
    $fragOS = $OS | ConvertTo-Html -As List -property Caption,Version,OSArchitecture,InstallDate -fragment -PreContent "<h2><span style='color:#4682B4'>Windows Details</span></h2>" | Out-String
    $FragAccountDetails = $AccountDetails  | ConvertTo-Html -As Table -fragment -PreContent "<h2><span style='color:#4682B4'>Account Details</span></h2>" | Out-String
    $FragGroupDetails =  $GroupDetails  | ConvertTo-Html -As Table -fragment -PreContent "<h2><span style='color:#4682B4'>Group Members</span></h2>" | Out-String
    $FragPassPol = $PassPol | Select-Object -SkipLast 3 | ConvertTo-Html -As Table -fragment -PreContent "<h2><span style='color:#4682B4'>Password Policy</span></h2>" | Out-String
    $fragInstaApps  =  $InstallApps | Sort-Object publisher,displayname -Unique  | ConvertTo-Html -As Table  -fragment -PreContent "<h2><span style='color:#4682B4'>Installed Applications</span></h2>" | Out-String
    $fragHotFix = $HotFix | ConvertTo-Html -As Table -property HotFixID,InstalledOn,Caption -fragment -PreContent "<h2><span style='color:#4682B4'>Installed Updates</span></h2>" | Out-String
    $fragBios = $bios | ConvertTo-Html -As List -property Name,Manufacturer,SerialNumber,SMBIOSBIOSVersion,ReleaseDate -fragment -PreContent "<h2><span style='color:#4682B4'>Bios Details</span></h2>" | Out-String
    $fragCpu = $cpu | ConvertTo-Html -As List -property Name,MaxClockSpeed,NumberOfCores,ThreadCount -fragment -PreContent "<h2><span style='color:#4682B4'>Processor Details</span></h2>" | Out-String

    #Security Review
    $frag_BitLocker = $fragBitLocker  | ConvertTo-Html -As List -fragment -PreContent "<h2><span style='color:#4682B4'>Bitlocker and TPM Details</span></h2>" -PostContent "<h4>$descripBitlocker</h4>" | Out-String
    $frag_Msinfo =  $MsinfoClixml | ConvertTo-Html -As Table -fragment -PreContent "<h2><span style='color:#4682B4'>Virtualization and Secure Boot Details</span></h2>" -PostContent "<h4>$descripVirt</h4>"  | Out-String
    
    $frag_LSAPPL = $fragLSAPPL  | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>LSA Protection for Stored Credentials</span></h2>" -PostContent "<h4>$descripLSA</h4>" | Out-String
    $frag_DLLSafe  =  $fragDLLSafe   | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>DLL Safe Search Order</span></h2>"  -PostContent "<h4>$descripDLL</h4>"| Out-String
    $frag_Code  =  $fragCode   | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Hypervisor Enforced Code Integrity</span></h2>" -PostContent "<h4>$descripHyper</h4>" | Out-String
    $frag_PCElevate  =  $fragPCElevate   | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Automatically Elevates User Installing Software</span></h2>"  -PostContent "<h4>$descripElev</h4>"| Out-String
    $frag_FilePass  =  $fragFilePass   | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Files that Contain the word PASSWORD</span></h2>" -PostContent "<h4>$descripFilePw</h4>" | Out-String
    $frag_AutoLogon  =  $fragAutoLogon   | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>AutoLogon Credentials in Registry</span></h2>"  -PostContent "<h4>$descripAutoLogon</h4>"| Out-String
    $frag_UnQu = $fragUnQuoted  | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Vectors that Allow UnQuoted Paths Attack</span></h2>" -PostContent "<h4>$DescripUnquoted</h4>" | Out-String
    $frag_LegNIC = $fragLegNIC | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Attacks Against Network Protocols</span></h2>" -PostContent "<h4>$DescripLegacyNet</h4>" | Out-String
    $frag_SysRegPerms = $fragReg | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Registry Permissions Allowing User Access - Security Risk if Exist</span></h2>" -PostContent "<h4>$descripRegPer</h4>" | Out-String
    $frag_PSPass = $fragPSPass | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Processes where CommandLine contains a Password</span></h2>" -PostContent "<h4>$Finish</h4>" | Out-String
    $frag_SecOptions = $fragSecOptions | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Security Options</span></h2>" -PostContent "<h4>$descripSecOptions</h4>" | Out-String
    $frag_wFolders = $fragwFold | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Non System Folders that are Writeable - User Created Folders Off Root of C: are Fine</span></h2>" -PostContent "<h4>$descripNonFold</h4>"| Out-String
    $frag_SysFolders = $fragsysFold | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>System Default Folders that are Writeable - Security Risk if Exist</span></h2>"  -PostContent "<h4>$descripSysFold</h4>"| Out-String
    $frag_wFile =  $fragwFile | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>System Files that are Writeable - Security Risk if Exist</span></h2>" -PostContent "<h4>$descripFile</h4>" | Out-String
    $frag_FWProf =   $fragFWProfile | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Firewall Profile</span></h2>"  -PostContent "<h4>$DescripFirewalls</h4>"| Out-String
    $frag_FW =  $fragFW | ConvertTo-Html -as Table -Fragment -PreContent "<h2><span style='color:#4682B4'>Enabled Firewall Rules</span></h2>" | Out-String
    
################################################
############  CREATE HTML REPORT  ##############
################################################

    ConvertTo-Html -Head $style -Body "<h1 align=center style='text-align:center'><span style='color:#4682B4;'>TENAKA.NET</span><h1>", 
    $fragDescrip1, 
    $fraghost, 
    $fragOS, 
    $FragAccountDetails,
    $FragGroupDetails,
    $FragPassPol,
    $fragInstaApps,
    $fragHotFix,
    $fragbios, 
    $fragcpu, 
    $frag_BitLocker, 
    $frag_Msinfo,
    $Frag_descripVirt2,
    $frag_Code,
    $frag_SecOptions,
    $frag_LSAPPL,
    $frag_DLLSafe,
    $frag_PCElevate,
    $frag_FilePass,
    $frag_AutoLogon,
    $frag_UnQu, 
    $frag_PSPass,
    $frag_LegNIC,
    $frag_SysRegPerms,
    $frag_SysFolders,
    $frag_wFolders,
    $frag_wFile,
    $frag_FWProf,
    $frag_FW,
    $FragDescripFin  | out-file $Report

    Get-Content $Report | 
    foreach {$_ -replace "<tr><th>*</th></tr>",""} | 
    foreach {$_ -replace "<tr><td> </td></tr>",""} |
    foreach {$_ -replace "<td>Warning","<td><font color=#FF4040>Warning"} | 
    foreach {$_ -replace "Warning</td>","<font></td>"} | Set-Content C:\VulnReport\FinshedReport.htm -Force
   
    }
}

reports

<#
Stuff to Fix.....

$ExecutionContext.SessionState.LanguageMode -eq "ConstrainedLanguage"
uac? - too many keys 
AutoPlay
Password in Registry - slow to get back results
Proxy password reg key
Null message warning that security is missing
Folder weakness of Windows is slow....
Add date and time to report name
Credential Guard
set warning for secure boot
Expand on explanations - currently of use to non-techies

#>




