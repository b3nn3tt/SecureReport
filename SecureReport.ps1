<#
Tenaka.net

.Synopsis
Check for common and known security vulnerabilities and create an html report based on the findings

.DESCRIPTION

The report is saved to C:\Securereport\FinishedReport.htm

Before everyone gets critical regarding the script formatting, some are due to how ConvertTo-HTML expects the data, most are to help those that aren't familiar with scripting. There is a conscious decision not to use aliases or abbreviations and where possible to create variables. 

#List of checks and balances:
Host Details, CPU, Bios, Windows Version
Accounts, Groups and Password Policy
Install Applications and installed Windows Updates
Virtualization, UEFI, Secure Boot, DMA, TPM and Bitlocker Settings
LSA, DLL Safe Search Order, Hypervisor Code Integrity
Autologon Credentials in the Registry
Unquoted paths
Processes that contain passwords in the command line
Enabled legacy Network protocols
Registry Keys with weak Permissions
System Folders with weak Permissions
Firewall settings and rules
Schedules Tasks
Files with hash mismatch
Driver Query for unsigned drivers
Shares and permissions

#TPM and Bitlocker
"TPM and Bitlocker protect against offline attack from usb and mounting the local Windows system then Accessing the local data. 'TPM and Pin' enhances Bitlocker by preventing LPC Bus (Low Pin Count) bypasses of Bitlocker with TPM.
Further information can be found @
https://www.tenaka.net/bitlocker

#Secure Boot
Secure Boot is a security standard to ensure only trusted OEM software is allowed at boot. At startup, the UEFi and boot software's digital signatures are validated preventing rootkits
More on Secure Boot can be found @
https://media.defense.gov/2020/Sep/15/2002497594/-1/-1/0/CTR-UEFI-SECURE-BOOT-CUSTOMIZATION-20200915.PDF/CTR-UEFI-SECURE-BOOT-CUSTOMIZATION-20200915.PDF

#VBS
Virtualization-based security (VBS), isolates core system resources to create secure regions of memory. Enabling VBS allows for Hypervisor-Enforced Code Integrity (HVCI), Device Guard and Credential Guard.
Further information can be found @
https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-vbs
https://www.tenaka.net/deviceguard-vs-rce
https://www.tenaka.net/pass-the-hash 
​
#Hypervisor Enforced Code Integrity
Hypervisor Enforced Code Integrity prevents the loading of unsigned kernel-mode drivers and system binaries from being loaded into system memory.
Further information can be found @  
https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity

#Security Options
Prevent credential relay with Impacket and Man in the Middle by Digitally Signing for SMB and LDAP connections enforcement.
Further information can be found @
https://www.tenaka.net/smb-relay-attack

#LSA
Enabling RunAsPPL for LSA Protection allows only digitally signed binaries to load as a protected process preventing credential theft and Access by code injection and memory Access by processes that aren't signed.
Further information can be found @ https://docs.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection

#DLL Safe Search
When applications do not fully qualify the DLL path and instead allow searching the default behaviour is for the 'Current Working Directory' to be called, then system paths. This allows an easy route to call malicious DLL's. Setting 'DLL Safe Search' mitigates the risk by moving CWD to later in the search order.
Further information can be found @
https://docs.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order

#DLL Hijacking (Permissions)
DLL Hijacking is when a malicious dll replaces a legitimate dll due to a path vulnerability. A program or service makes a call on that dll gaining the privileges of that program or service. Additionally missing dll's presents a risk where a malicious dll is dropped into a path where no current dll exists but the program or service is making a call to that non-existent dll.
This audit is reliant on programs being launched so that DLL's are loaded. Each process's loaded dll's are checked for permissions issues and whether they are signed.  
The DLL hijacking audit does not currently check for missing dll's being called. Process Monitor filtered for 'NAME NOT FOUND' and path ends with 'DLL' will.


#Automatically Elevate User
Auto Elevate User is a setting that elevates users allowing them to install software without being an administrator. 

#Password in Files
Searches the following locations:
C:\Users\
C:\ProgramData\
C:\Windows\System32\Tasks\
C:\Windows\Panther\
C:\Windows\system32\
C:\Windows\system32\sysprep

Searches the following file extensions:
txt, ini, .xml

For the following Words:
password, credential

Ignore these files as they contain the Word 'Password' by default:
C:\Windows\system32\NarratorControlTemplates.xml
C:\Windows\system32\DDFs\NGCProDDF_v1.2_final.xml
C:\Windows\system32\icsxml\ipcfg.xml
C:\Windows\system32\icsxml\pppcfg.xml
C:\Windows\system32\slmgr\0409\slmgr.ini
C:\Windows\system32\winrm\0409\winrm.ini

#Passwords in the Registry
Searches HKLM and HKCU for the Words 'password' and 'passwd', then displays the password value in the report. 
The search will work with VNC encrypted passwords stored in the registry, from Kali run the following command to decrypt

echo -n PasswordHere | xxd -r -p | openssl enc -des-cbc --nopad --nosalt -K e84ad660c4721ae0 -iv 0000000000000000 -d | hexdump -Cv

​
#Password embedded in Processes
Processes that contain credentials to authenticate and Access applications. Launching Task Manager, Details and add 'Command line' to the view.
​
#AutoLogon
Checks "HKLM:\Software\Microsoft\Windows NT\Currentversion\Winlogon" for any clear text credentials remaining from a MECM\SCCM\MDT deployment.

#Unquoted
The Unquoted Path vulnerability is when a Windows Service's 'Path to Executable' contains spaces and is not wrapped in double-quotes providing a route to System.
Further information can be found @
https://www.tenaka.net/unquotedpaths

#Legacy Network Protocols
LLMNR and other legacy network protocols can be used to steal password hashes.
Further information can be found @
https://www.tenaka.net/responder

#Permissions Weakness in Default System Directories - Write
System default Folders that allow a User the Write permissions. These can be abused by creating content in some of the allowable default locations. Prevent by applying Execution controls eg Applocker.

Searches:
C:\PerfLogs
C:\Program Files
C:\Program Files (x86)
C:\Windows

Expected folders that a user can Write to:
C:\Windows\System32\LogFiles\WMI
C:\Windows\System32\Microsoft\Crypto\RSA\MachineKeys
C:\Windows\System32\Tasks
C:\Windows\System32\Tasks\Microsoft\Windows\RemoteApp and Desktop Connections Update
C:\Windows\SysWOW64\Tasks
C:\Windows\SysWOW64\Tasks\Microsoft\Windows\RemoteApp and Desktop Connections Update
C:\Windows\tracing

Further information can be found @
https://www.tenaka.net/unquotedpaths
https://www.tenaka.net/applockergpo

#Permissions Weakness in Default System Directories - Create Files
System default Folders that allow a User the CreateFile permissions. These can be abused by creating content in some of the allowable default locations. Prevent by applying Execution controls eg Applocker.

Expected folders that a user can CreateFiles to:
C:\Windows\PLA\Reports
C:\Windows\PLA\Reports\en-GB
C:\Windows\PLA\Reports\en-US
C:\Windows\PLA\RulesC:\Windows\PLA\Rules\en-GB
C:\Windows\PLA\Rules\en-US
C:\Windows\PLA\Templates
C:\Windows\Registration\CRMLog
C:\Windows\System32\Com\dmp
C:\Windows\System32\spool\drivers\color
C:\Windows\System32\spool\PRINTERS
C:\Windows\System32\spool\SERVERS
C:\Windows\SysWOW64\Com\dmp
C:\Windows\SysWOW64\Tasks\Microsoft\Windows\PLA
C:\Windows\SysWOW64\Tasks\Microsoft\Windows\PLA\System
C:\Windows\TasksC:\Windows\Temp
C:\Windows\Temp\MsEdgeCrashpad
C:\Windows\Temp\MsEdgeCrashpad\reports

Further information can be found @
https://www.tenaka.net/unquotedpaths
https://www.tenaka.net/applockergpo

#Permissions weaknesses in Non-Default Directories
A vulnerability exists when enterprise software has been installed on the root of C:\. The default permissions allow a user to replace approved software binaries with malicious binaries.
Further information can be found @
https://www.tenaka.net/unquotedpaths

#Files that are Writeable
System files that allow users to write can be swapped out for malicious software binaries.

Further information can be found @
https://www.tenaka.net/unquotedpaths

#Firewalls
Firewalls should always block inbound and exceptions should be to a named IP and Port.

Further information can be found @
https://www.tenaka.net/whyhbfirewallsneeded

#Scheduled Tasks
Checks for Scheduled Tasks excluding any that reference System32 as a directory. 
These potential user-created tasks are checked for scripts and their directory permissions are validated. 
No user should be allowed to Access the script and make amendments, this is a privilege escalation route.

Checks for encoded scripts, PowerShell or exe's that make calls off box or run within Task Scheduler.

#Shares
Finds all shares and reports on share permissions
Does not show IPC$ and permissions due to Access issues.

#Driver Query Signing
All Drivers should be signed with a digital signature to verify the integrity of the packages. 64bit kernel Mode drivers must be signed without exception

#Authenticode Hash Mismatch
Checks that digitally signed files have a valid and trusted hash. If any Hash Mis-Matches then the file could have been altered
  
.VERSION
YYMMDD
211221.1 - Added Security Options
211222.1 - Changed f$.Replace  | Out-File $Report to Foreach {$_ -replace "",""}
211222.2 - Added Warning to be RED with a replace and set-content
211223.1 - Added -postContent with explanations
211223.2 - Bitlocker fixed null response
211229.1 - Added explanations and changed colour
211229.2 - Added .xml in Password in file search added further excluded directories due to the number of false-positive being returned
211230.1 - Restored search for folder weaknesses in C:\Windows
211230.2 - Added CreateFiles Audit - hashed out until testing is complete
220107.1 - Corrected Legacy Network Netbios, incorrectly showing a warning despite being the correct setting.
220107.2 - The report file name is dated
220120.1 - Office 2016 and older plus updates that create keys in Uninstall hive. 
           This is required to correctly report on legacy apps and to cover how MS is making reporting of installed updates really difficult.
220202.1 - Fixed issue with hardcode the name of the script during id of PS or ISE
220203.1 - Added error actions
220203.2 - Warning about errors generated during the report run.
220204.1 - Added Dark and Light colour themes.
220207.1 - Fixed VBS and MSInfo32 formatting issues. 
220208.1 - Added start and finish warning for each section to provide some feedback
220208.2 - Fixed the file\folder parsing loops, including processing that should have been completed after the loops had finished
220211.1 - Added Scheduled task audit looking for embedded code.
220211.2 - Added < hash hash > to comment out the folder audits.
220214.1 - Added Driver Query
220214.1 - Temporary fix to scheduled task where multiple triggers or action breaks the html output
220215.1 - Report on shares and their permissions
220216.1 - Fixed Schedule task reporting to show multiple arguments and actions 
220218.1 - Added Autenticode Signature Hash Mis-Match (Long running process, will be optional, unhash section to enable )
220222.1 - Embedded passwords reworked to be more efficient 
220224.1 - General cleanup of spacing and formatting purely aesthetic
220228.1 - Multi drive support for Folder and File permission and password audits
220411.1 - Added "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" to list x86 install applications
220604.1 - Added Root of drive for permission check Non System Folders
220604.2 - Added | where {$_.displayroot -notlike "*\\*"} to get drive letters and not mounted shares
220605.1 - Added loaded dll hijacking vulnerability scanner
220605.2 - Added READ-HOSTS to prompt to run slow processes.
220606.1 - Added DLL hijacking for dlls not signed and where the user can write.
220606.2 - Tidy up and formatting of script
220607.1 - Password within file search $fragFilePass=@() moved to outside loop as it was dropping previous drives and data
220708.1 - Added depth to Folder and File search to give option to speed up search
220708.2 - Moved DLL not signed and user Access, update to Folder search, not an option to run or not
220708.3 - Added filters to Folder and File search to skip winSXS and LCU folders, time consuming and pointless  - Improves preformance 
220708.4 - DLL not signed and user Access, wrong setting on filter and excluded the files I'm looking for.
220708.5 - Changed 'where' clause for excluding folder to $_.fullName -match
220708.6 - Added ProgramData to folder checks as performance will allow it
220708.7 - Added Windows directory to check for writeable files. 
220708.8 - Updated Authenticode to exclude winSxS and LCU directories - Improves preformance 
220708.9 - Default System Folder check was returning wrong data, updated the directory listing where statement
220709.1 - Added Credential Guard support
220709.2 - Added LAPS support
220711.1 - Added URA Support - uses SecEdit, extracts Rights Assignments and then maps GUID's to User or Group Name
220711.2 - Updated the description tags and added line separators <br>.
220712.1 - Updated the out-file format for the URA
220712.2 - Created if based on Folder audit, if not then the following vars wont be passed to the report, part of the prettification of the output
           $fragwFile           $frag_wFile           
           $fragReg             $frag_SysRegPerms     
           $fragwFold           $frag_wFolders        
           $fragsysFold         $frag_SysFolders      
           $fragcreateSysFold   $frag_CreateSysFold   
           $fragDllNotSigned    $frag_DllNotSigned    
           $fragAuthCodeSig     $frag_AuthCodeSig  
220712.3 - Added Grey Theme  
220713.1 - Added warning for Powershell verison 4 - Win8\2012\2012 R2 - The Get-childitem -depth is not supported - generates a sea of red. Script generates report minus the file,folder,reg audit data.         
220715.1 - Fixed issue with URA, Debug was missed off the list.  
220716.1 - Updated Reg Search from -notlike to match   
220718.1 - Added Filter to remove null content so its not displayed in the final report
220718.2 - Added Passwords embedded in the Registry  
220719.1 - Added ASR    
220719.2 - Added WDigest   
220720.1 - Added whoami groups 
220720.2 - Added whoami privs
220720.3 - Fixed issue with Host Details
220721.1 - Updated warning message to include URA
220721.2 - Updated local accounts to warn when enabled, Groups will warn on DA, EA and Schema Admin
220721.3 - Adding support for MS Recommended Sec settings
220722.1 - Adding support for MS Recommended Sec settings 
220723.1 - Adding support for MS Recommended Sec settings
220723.2 - Fixed misconfig in Security Options for 4 and 10. added Windows 2000 strong encryption
220723.3 - Added Kerberos encryption types to Security Options
220724.1 - Added mouse over for URA to show MS recommended settings
220724.1 - Fixed issues with URA
220725.1 - Added 255.255.255.255 wpad to legacy network protocols
220726.1 - Added further Security Options and GPO checked based on ms sec guide
220818.1 - Added MS Edge GPO check
220819.1 - Added Office 2016\365 GPO check
220820.1 - Updated URA to include GPO Path as a mouse over
220825.1 - Added DSQuery to search for accounts that dont pre-auth - Issue requires AD RSAT installed
220830.1 - Added Antivirus Audit - Uses known status codes to report on AV engine and definitions
220831.1 - Updated Get Shares to ignore error for IPC's lack of path and permissions
220901.1 - Added IPv4 and IPv6 Details
220901.2 - Added FSMO Roles
220907.1 - Added Priv Group - DA, EA and Schema
221024.1 - Passwords embedded in files has option as it can crash PowerShell on servers
221024.2 - Added warnings and color to unquoted paths, reg and file permission issues
221024.3 - swapped out get-wmi for cim-instance to support powershell 7
221025.1 - Fixed issue with Unquoted path and not finding .sys files that are unquoted
221025.1 - Added audit for installed Windows Features
221029.1 - Added Compliance Report showing overall status and areas of concern
221029.2 - Fixed issue where Defender cant be detected on Server OS - will assume if WMI fails that its not installed
221031.1 - Added Compliance Report showing overall status and areas of concern - Updated for hyperlinks
221101.1 - Updated Frag titles so reported compliance is an in page link to the reported issue. 
221102.1 - Replaced Net Group will ADSI LDAP for Domain Priv Group Membership - less text formating makes adsi more reliable.
221103.1 - Fixed issue with color schemes not applying swapped out if for ifelse
221106.1 - Firewall profile now warns on misconfiguration
221106.2 - Fixed issues with various links to with Summary
221106.3 - Removed the 'Warning' makes report look neater.
221106.4 - Removed <span style='color:$titleCol'>, not required as CSS applies colour schemes
221112.1 - Fixed issues with href a ID's - Summary links now work
221112.2 - Fixed issue with MSInfo and out-file added additional spaces which translated into spaces in the html output - Out-File $msinfoPathcsv -Encoding utf8 
221112.3 - Added Top to A href, summary links will return to top of page now.
221121.1 - Added Certificate Audit - There is a naughty list that requires key words being added eg a less that desirable company
221123.1 - Fixed issues with MS recommended settings
221129.1 - Added more OS GPO Recommended validation checks
221129.2 - Swapped out “ ” ’ for ' " " - some had sneaked in whilst prepping some settings in MS Word
221208.1 - Added test path and rename to random number for C:\SecureReport if exists
221208.2 - Updated and added further OS GPO settings testing for misconfigurations
221208.3 - Added further Legacy network checks
221210.1 - Updated list of MS Edge checks 
230626.1 - Added kernel-mode hardware-enforced stack protection
230717.1 - Updated look and feel, added fonts and font sizes vars for CSS
230718.1 - Added True and False, true is compliant, false missing a setting
230725.1 - Finised Report is named to hostname and date
230727.1 - Removed 'Warning -'
230802.1 - Certs now warns on Sha1
230802.1 - Updated Installed Apps to warn when installed date is more than 6 months. 
230803.1 - Updated BIOS to warn when installed date is more than 6 months. 
230805.1 - Updated looks and feel of report.
230805.2 - Updated Windows Updates to alert when they are more than 6 months out of date.
230807.1 - Report on supported CipherSuites - Needs explanation to be added
230807.2 - Thought it a good idea to audit services..... The number of active services is exponentially multiplying, the audit is available but not outputted in report unless required by adding the $frag_RunServices to the output sections - too much chaff
230808.1 - Based64 the Tenaka.net imaage and embedded into report 
        
        Convert image file to base64 for embedded picture in report
        Image is the title image on www.tenaka.net, if you wish to download image and confirm base64 and that it contains nothing malicious 

        [convert]::ToBase64String((get-content -path C:\Image\Image.png -Encoding Byte)) >> C:\image\base.txt

        [convert]::FromBase64String((get-content -path C:\Image\base.txt -Encoding Byte)) >> C:\image\Image.png   
230811.1 - Search Powershell History for passwords and usernames
230814.1 - Added Applocker Audit - Hash results show first hash only for each entry
230815.1 - Updated Get-NetfirewallRule from -all to  -PolicyStore activestore 
230816.1 - Added Details and Summary menu
230816.2 - reordered headings and grouping       
230816.3 - reordered compliance status, updated some compliances
230817.1 - Fixed inconsistencies with searching for passwords in the Registry - now also reports correctly the password in the report
230824.1 - Updated Fragments to weed out null fragments so they arent included in the finished report
230824.2 - created additional unfiltered report output as a backup and comparison to the filtered final report
230824.2 - Added final bit for Applocker auditing and showing enforcment mode
230824.3 - Fixed typo in Reg search for passwords
230901.1 - Added WDAC Policy and Enforcement checks
230905.1 - Updated filtering in Password Search in Registry - displays found password in the report also
230905.2 - Updates Installed Windows Features as MS have moved the goal posts and deprecated the dism command to list out packages
230905.3 - Broke Server and Client Features into differenct Fargs
230906.1 - Typo in the Autologon audit, removed the additional space that prevented it working. 
230906.1 - Update IPv4\6 Audits to cope with multiple active NIC's eg Hyper-V Server
230913.1 - Improved ASR reporting and fixed miss reporting when not set to 1 but not 0
230914.1 - Added Windows Patch version
230915.1 - Fixed excessive * char in report
230925.1 - Fixed sizing issues with html css settings 
#>

#Remove any DVD from client
$drv = (psdrive | where{$_.Free -eq 0})

if($drv.free -eq "0" -and $_.name -ne "C")
    {
        Write-Host "Eject DVD and try again"
    }
 
#Confirm for elevated admin
    if (-not([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    {
        Write-Host "An elevated administrator account is required to run this script." -ForegroundColor Red
    }
else
{
    #Enable detection of PowerShell or ISE, enable to run from both
    #Script name has been defined and must be saved as that name.
    $VulnReport = "C:\SecureReport"
    $ptRand = Get-Random -Minimum 100 -Maximum 999
    #$ptRand= (Get-Date).ToString('yy/MM/dd-hh:mm').Replace("/","").Replace(":","")

    if($psise -ne $null)
    {
        $ISEPath = $psise.CurrentFile.FullPath
        $ISEDisp = $psise.CurrentFile.DisplayName.Replace("*","")
        $ISEWork = $ISEPath.TrimEnd("$ISEDisp")

        $tpSecRrpt = test-path $VulnReport
        if ($tpSecRrpt -eq $true)
        {
            Rename-Item $VulnReport -NewName "$VulnReport$($ptRand)" -Force
            New-Item -Path C:\SecureReport -ItemType Directory -Force
        }
        else
        {
            New-Item -Path C:\SecureReport -ItemType Directory -Force
        }
    }
    else
    {
        $PSWork = split-path -parent $MyInvocation.MyCommand.Path
        
        $tpSecRrpt = test-path $VulnReport
        $tpSecRrpt = $VulnReport
        if ($tpSecRrpt -eq $true)
        {
            Rename-Item $VulnReport -NewName "$VulnReport$($ptRand)" -Force
            New-Item -Path C:\SecureReport -ItemType Directory -Force
        }
        else
        {
            New-Item -Path C:\SecureReport -ItemType Directory -Force
        }
    }

function reports
{
    $psver4 = $psversiontable.PSVersion 
    if ($psver4 -le "4.0")
    {
    write-host " " 
    Write-Host "PowerShell version 4 is installed (Windows8.1\Server 2012 R2), the Get-ChildItem -Depth is not supported, don't waste your time selecting audit Files, Folders and Registry for permissions issues" -ForegroundColor Red
    write-host " "
    }

    #Start Message
    Write-Host " "
    Write-Host "The report requires at least 30 minutes to run, depending on hardware and amount of data on the system, it could take much longer"  -ForegroundColor Yellow
    Write-Host " "
    Write-Host "Ignore any errors or red messages its due to Administrator being denied Access to parts of the file system." -ForegroundColor Yellow
    Write-Host " "
    Write-Host "Some audits take a long time to complete and do not output progress as this adds to the time taken." -ForegroundColor Yellow
    Write-Host " "
    Write-Host "READ ME - To audit for Dll Hijacking vulnerabilities applications and services must be active, launch programs before continuing." -ForegroundColor Yellow
    Write-Host " "

    $Scheme = Read-Host "Type either Tenaka, Dark, Grey or Light for choice of colour schemes" 
    write-host " "
    $folders = Read-Host "Long running audit - Do you want to audit Files, Folders and Registry for permissions issues....type `"Y`" to audit, any other key for no"

    if ($folders -eq "Y") {$depth = Read-Host "What depth do you wish the folders to be auditied, the higher the number the slower the audit, the default is 2, recommended is 4"}
    write-host " "
    $embeddedpw = Read-Host "Some systems whilst retrieving passwords from within files crash PowerShell....type `"Y`" to audit, any other key for no"
    write-host " "
    $authenticode = Read-Host "Long running audit - Do you want to check that digitally signed files are valid with a trusted hash....type `"Y`" to audit, any other key for no"

    #Summary Frag
    $fragSummary=@()

################################################
############  MDT BUILD DETAILS  ###############
################################################
    $fragMDTBuild =@()

    try {
        $mdtBuild = gwmi -Class microsoft_BDD_info
            $mdtID =  $mdtBuild.TaskSequenceID
            $mdtTS = $mdtBuild.TaskSequenceName
            $mdtVer = $mdtBuild.TaskSequenceVersion
            $mdtDate = $mdtBuild.DeploymentTimestamp.Split(".")[0] 
            $mdtActDate = [datetime]::ParseExact($mdtDate,'yyyyMMddHHmmss', $null)

        $newObjMDTBuild = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjMDTBuild -Type NoteProperty -Name TaskSequenceID -Value $mdtID
        Add-Member -InputObject $newObjMDTBuild -Type NoteProperty -Name TaskSequenceName -Value $mdtTS
        Add-Member -InputObject $newObjMDTBuild -Type NoteProperty -Name TaskSequenceVersion -Value $mdtVer
        Add-Member -InputObject $newObjMDTBuild -Type NoteProperty -Name DeploymentTime -Value $mdtActDate
        $fragMDTBuild += $newObjMDTBuild
    }catch{}

################################################
#################  BITLOCKER  ##################
################################################
Write-Host " "
Write-Host "Auditing Bitlocker" -foregroundColor Green
sleep 5

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
    $TPMSpec = wmic /namespace:\\root\cimv2\Security\microsofttpm path win32_tpm get specversion 
    $TPMSpecVer = $TPMSpec[2]

    if ($bitVS -eq "FullyEncrypted")
    {
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
    Else
    { 
        $BitDisabled = "Warning Bitlocker is disabled Warning"
        $newObjBit = New-Object psObject
        Add-Member -InputObject $newObjBit -Type NoteProperty -Name BitLockerDisabled -Value $BitDisabled
        $fragBitLocker += $newObjBit
    }
    
Write-Host " "
Write-Host "Completed Bitlocker Audit" -foregroundColor Green
################################################
################  OS DETAILS  ##################
################################################
Write-Host " "
Write-Host "Gathering Host and Account Details" -foregroundColor Green
sleep 5

    #OS Details
    $fragHost = Get-CimInstance -ClassName win32_computersystem 
    $OS = Get-CimInstance -ClassName win32_operatingsystem 
    $bios = Get-CimInstance -ClassName win32_bios | Select-Object Name,Manufacturer,SerialNumber,SMBIOSBIOSVersion,ReleaseDate
    $cpu = Get-CimInstance -ClassName win32_processor

    $fragPatchversion=@()
    #$OSBuildNumber = (Get-ItemProperty HKLM:\system\Software\Microsoft\BuildLayers\OSClient).buildnumber
    #$OSPatchNumber = (Get-ItemProperty HKLM:\system\Software\Microsoft\BuildLayers\OSClient).BuildQfe
    [string]$OSPatchversion = &cmd.exe /c ver.exe
    $OSPatchverSpace = [string]$OSPatchversion.Replace(" Microsoft","Microsoft")

    $newObjPatchversion = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjPatchversion -Type NoteProperty -Name WindowsPatchVersion -Value $OSPatchverSpace
    $fragPatchversion += $newObjPatchversion

    $BiosUEFI=@()

    $BiosName = $bios.Name
    $BiosManufacturer = $bios.Manufacturer
    $BiosSerial = $bios.SerialNumber
    $BiosSMBVersion = $bios.SMBIOSBIOSVersion
    $ReleaseDate = $bios.ReleaseDate

    $date180days = (Get-Date).AddDays(-180)

    if ($date180days -gt $ReleaseDate){$ReleaseDate = "Warning $($ReleaseDate) Warning"}

    $newObjBiosUEFI = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjBiosUEFI -Type NoteProperty -Name BiosName -Value $BiosName
    Add-Member -InputObject $newObjBiosUEFI -Type NoteProperty -Name BiosManufacturer -Value $BiosManufacturer
    Add-Member -InputObject $newObjBiosUEFI -Type NoteProperty -Name BiosSerial -Value $BiosSerial
    Add-Member -InputObject $newObjBiosUEFI -Type NoteProperty -Name BiosSMBVersion -Value $BiosSMBVersion
    Add-Member -InputObject $newObjBiosUEFI -Type NoteProperty -Name ReleaseDate -Value $ReleaseDate
    $BiosUEFI += $newObjBiosUEFI

################################################
##############  ACCOUNT DETAILS  ###############
################################################
#PasWord Policy
    cd C:\
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
            if ($accEnabled -eq $true)
            {
            $accEnabled = "Warning Enabled Warning"
            } 
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

################################################
#########  MEMBERS OF LOCAL GROUPS  ############
################################################
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
###############  LIST OF DCs  ##################
################################################
#Domain Info
#List of DC's
$fragDCList=@()
[string]$queryDC = netdom /query dc
$dcListQuery = $queryDC.Replace("The command completed successfully.","").Replace("List of domain controllers with accounts in the domain:","").Replace(" ",",").replace(",,","")
$fqdn = ((Get-CimInstance -ClassName win32_computersystem).Domain) + "."
$dcList = $dcListQuery.split(",") | sort 

    foreach ($dcs in $dcList)
    {
        $dcfqdn = $dcs + "." + $fqdn
        $newObjDCList = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjDCList -Type NoteProperty -Name DCList -Value $dcfqdn
        $fragDCList += $newObjDCList
    }

################################################
################  FSMO ROLES  ##################
################################################
    #FSMO Roles
    $fragFSMO=@()
    [string]$fsmolist = netdom /query fsmo
    $fsmoQuery = $fsmolist.Replace("The command completed successfully.","")

    $fsmoQry = $fsmoQuery.replace("master","master,").replace("PDC",",PDC,").Replace("Domain",",Domain").Replace("RID",",RID").Replace("Infra",",Infra").replace("manager","manager,")
    $fsmoSplit = $fsmoQry.Split(",").Trim()

    $schMasterRole = $fsmoSplit[0]
    $schMasterDC = $fsmoSplit[1]

    $DomMasterRole = $fsmoSplit[2]
    $DomMasterDC = $fsmoSplit[3]

    $PDCRole = $fsmoSplit[4]
    $PDCDC = $fsmoSplit[5]

    $RIDRole = $fsmoSplit[6]
    $RIDDC = $fsmoSplit[7]

    $InfraRole = $fsmoSplit[8]
    $InfraDC = $fsmoSplit[9]

    $newObjFsmo = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjFsmo -Type NoteProperty -Name $schMasterRole -Value $schMasterDC
    Add-Member -InputObject $newObjFsmo -Type NoteProperty -Name $DomMasterRole -Value $DomMasterDC
    Add-Member -InputObject $newObjFsmo -Type NoteProperty -Name $PDCRole -Value $PDCDC
    Add-Member -InputObject $newObjFsmo -Type NoteProperty -Name $RIDRole -Value $RIDDC
    Add-Member -InputObject $newObjFsmo -Type NoteProperty -Name $InfraRole -Value $InfraDC
    $fragFSMO += $newObjFsmo

################################################
#########  DOMAIN PRIV GROUPS ##################
################################################
    #Domain Priv Group members
    $Root = [ADSI]"LDAP://RootDSE"
    $rootdse = $Root.rootDomainNamingContext

    $adGroups = 
    "Administrators",
    "Backup Operators",
    "Server Operators",
    "Account Operators",
    "Guests",
    "Domain Admins",
    "Schema Admins",
    "Enterprise Admins",
    "DnsAdmins",
    "DHCP Administrators",
    "Domain Guests"

    $fragDomainGrps=@()

    foreach ($adGroup in $adGroups)
    {
        try
        {    
            $gpName = [ADSI]"LDAP://CN=$adGroup,CN=Users,$($rootdse)"
            $gpMembers = $gpName.Member    
            $ArgpMem=@()
            if($gpMembers -ne $null)
            {  
            foreach ($gpMem in $gpMembers)
                {
                $gpSting = $gpMem.ToString().split(",").replace("CN=","")[0]
                $ArgpMem += $gpSting
                }
                $joinMem = $ArgpMem -join ", "

                $newObjDomainGrps = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjDomainGrps -Type NoteProperty -Name GroupName -Value $adGroup
                Add-Member -InputObject $newObjDomainGrps -Type NoteProperty -Name GroupMembers -Value $joinMem 
                $fragDomainGrps += $newObjDomainGrps   
            }
        }
    finally
        {
            $gpName = [ADSI]"LDAP://CN=$adGroup,CN=builtin,$($rootdse)"
            $gpMembers = $gpName.Member   
            $ArgpMem=@()
                    if($gpMembers -ne $null)
            {  
            foreach ($gpMem in $gpMembers)
                {
                $gpSting = $gpMem.ToString().split(",").replace("CN=","")[0]
                $ArgpMem += $gpSting
                }
                $joinMem = $ArgpMem -join ", "

                $newObjDomainGrps = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjDomainGrps -Type NoteProperty -Name GroupName -Value $adGroup
                Add-Member -InputObject $newObjDomainGrps -Type NoteProperty -Name GroupMembers -Value $joinMem 
                $fragDomainGrps += $newObjDomainGrps   
            }
        }
    }

################################################
########  PRE-AUTHENTICATION  ##################
################################################
    #DSQUERY
    #Pre-Authenticaiton enabled
    #RSAT is requried
    $dsQuery = & dsquery.exe * -limit 0 -filter "&(objectclass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304)" -attr samaccountname, distinguishedName, userAccountControl | select -skip 1
    $fragPreAuth=@()

    foreach ($preAuth in $dsQuery)
        {
            $preAuth = $preAuth.trim("").Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
            $preAuthSam = "Warning " + $preAuth[0] + " warning" 
            $preAuthOu = "Warning " +$preAuth[1]  + " warning" 
            $preAuthUac = "Warning " +$preAuth[2]  + " warning" 

            $newObjPreAuth = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjPreAuth -Type NoteProperty -Name PreAuth-Account -Value $preAuthSam
            Add-Member -InputObject $newObjPreAuth -Type NoteProperty -Name PreAuth-OUPath -Value $preAuthOu
            Add-Member -InputObject $newObjPreAuth -Type NoteProperty -Name PreAuth-UACValue -Value $preAuthUac
            $fragPreAuth += $newObjPreAuth
        }

################################################
###### PASSWORDS THAT DONT EXPIRE ##############
################################################
    #Accounts that never Expire

    $dsQueryNexpires = & dsquery.exe * -filter "(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=65536))" -attr samaccountname, distinguishedName, userAccountControl | select -skip 1
    $fragNeverExpires=@()

    foreach ($NeverExpires in $dsQueryNexpires)
        {
            $NeverExpires = $NeverExpires.trim("").Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
            $NeverExpiresSam = "Warning " + $NeverExpires[0] + " warning" 
            $NeverExpiresOu = "Warning " +$NeverExpires[1]  + " warning" 
            $NeverExpiresUac = "Warning " +$NeverExpires[2]  + " warning" 

            $newObjNeverExpires = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjNeverExpires -Type NoteProperty -Name NeverExpires-Account -Value $NeverExpiresSam
            Add-Member -InputObject $newObjNeverExpires -Type NoteProperty -Name NeverExpires-OUPath -Value $NeverExpiresOu
            Add-Member -InputObject $newObjNeverExpires -Type NoteProperty -Name NeverExpires-UACValue -Value $NeverExpiresUac
            $fragNeverExpires += $newObjNeverExpires
        }

    Write-Host " "
    Write-Host "Completed Gathering Host and Account Details" -foregroundColor Green

################################################
#########  USER RIGHTS ASSIGNMENTS  ############
################################################
Write-Host " "
Write-Host "Starting User Rights Assignments" -foregroundColor Green
sleep 5

    $VulnReport = "C:\SecureReport"
    $OutFunc = "URA" 
                
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $secEditPath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.Inf"
    $secEditOutPath = "C:\SecureReport\output\$OutFunc\" + "URAOut.txt"
    $secEditImpPath = "C:\SecureReport\output\$OutFunc\" + "URAImport.txt"
    Set-Content -Path $secEditOutPath -Value " "
    Set-Content -Path $secEditImpPath -Value " "
    
    $hn = hostname

    $URALookup =[ordered]@{
        "Access Credential Manager as a trusted caller"="SeTrustedCredManAccessPrivilege","Access Credential Manager as a trusted caller | Set Blank"
        "Access this computer from the network" = "SeNetworkLogonRight","Access this computer from the network | Administrators, Remote Desktop Users"
        "Act as part of the operating system"="SeTcbPrivilege","Act as part of the operating system | Set Blank"
        "Add workstations to domain" = "SeMachineAccountPrivilege","Add workstations to domain"
        "Adjust memory quotas for a process" = "SeIncreaseQuotaPrivilege", "Adjust memory quotas for a process"
        "Allow log on locally" = "SeInteractiveLogonRight", "Allow log on locally | Administrators, Users | Administrators, Users" 
        "Allow log on through Remote Desktop Services"="SeRemoteInteractiveLogonRight","Allow log on through Remote Desktop Services"
        "Back up files and directories" = "SeBackupPrivilege", "Back up files and directories | Administrators"
        "Bypass traverse checking" = "SeChangeNotifyPrivilege", "Bypass traverse checking"
        "Change the system time" = "SeSystemtimePrivilege", "Change the system time"
        "Change the time zone" = "SeTimeZonePrivilege", "Change the time zone" 
        "Create a pagefile" = "SeCreatePagefilePrivilege", "Create a pagefile | Administrators"
        "Create a token object"="SeCreateTokenPrivilege","Create a token object | Set Blank"
        "Create global objects" = "SeCreateGlobalPrivilege", "Create global objects | Administrators,LOCAL SERVICE,NETWORK SERVICE,SERVICE"
        "Create permanent shared objects"="SeCreatePermanentPrivilege","Create permanent shared objects | Set Blank"
        "Create symbolic links" = "SeCreateSymbolicLinkPrivilege","Create symbolic links" 
        "Debug programs" = "SeDebugPrivilege", "Debug programs | Administrators (Prefer setting Blank)"
        "Deny Access to this computer from the network"   = "SeDenyNetworkLogonRight", "Deny Access to this computer from the network | NT AUTHORITY\Local Account" 
        "Deny log on as a batch job" = "SeDenyBatchLogonRight", "Deny log on as a batch job"
        "Deny log on as a service" = "SeDenyServiceLogonRight", "Deny log on as a service" 
        "Deny log on locally" = "SeDenyInteractiveLogonRight", "Deny log on locally" 
        "Deny log on through Remote Desktop Services" = "SeRemoteInteractiveLogonRight","Deny log on through Remote Desktop Services | NT AUTHORITY\Local Account" 
        "Enable computer and user accounts to be trusted for delegation"="SeEnableDelegationPrivilege","Enable computer and user accounts to be trusted for delegation | Set Blank"
        "Force shutdown from a remote system" = "SeRemoteShutdownPrivilege", "Force shutdown from a remote system | Administrators"
        "Generate security audits" = "SeAuditPrivilege", "Generate security audits" 
        "Impersonate a client after authentication" = "SeImpersonatePrivilege", "Impersonate a client after authentication | Administrators, LOCAL SERVICE, NETWORK SERVICE, SERVICE" 
        "Increase a process working set" = "SeIncreaseWorkingSetPrivilege","Increase a process working set" 
        "Increase scheduling priority" = "SeIncreaseBasePriorityPrivilege","Increase scheduling priority"
        "Load and unload device drivers" = "SeLoadDriverPrivilege", "Load and unload device drivers | Administrators"
        "Lock pages in memory"="SeLockMemoryPrivilege","Lock pages in memory | Set Blank"
        "Log on as a batch job" = "SeBatchLogonRight", "Log on as a batch job"
        "Log on as a service" = "SeServiceLogonRight", "Log on as a service" 
        "Manage auditing and security log" = "SeSecurityPrivilege", "Manage auditing and security log | Administrators"
        "Modify an object label"="SeRelabelPrivilege","Modify an object label"
        "Modify firmware environment values" = "SeSystemEnvironmentPrivilege","Modify firmware environment values | Administrators"  
        "Obtain an impersonation token for another user in the same session" = "SeDelegateSessionUserImpersonatePrivilege","Obtain an impersonation token for another user in the same session" 
        "Perform volume maintenance tasks" = "SeManageVolumePrivilege", "Perform volume maintenance tasks | Administrators"
        "Profile single process" = "SeProfileSingleProcessPrivilege", "Profile single process  | Administrators" 
        "Profile system performance" = "SeSystemProfilePrivilege", "Profile system performance"
        "Remove computer from docking station" = "SeUndockPrivilege","Remove computer from docking station" 
        "Replace a process level token" = "SeAssignPrimaryTokenPrivilege", "Replace a process level token" 
        "Restore files and directories" = "SeRestorePrivilege","Restore files and directories | Administrators" 
        "Shut down the system" = "SeShutdownPrivilege", "Shut down the system"
        "Synchronize directory service data"="SeSyncAgentPrivilege","Synchronize directory service data"
        "Take ownership of files or other objects" = "SeTakeOwnershipPrivilege", "Take ownership of files or other objects | Administrators"

        }

    $URACommonPath = "Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\User Rights Assingments\" 

    #Export Security Settings inc User Rights Assignments with secedit.exe
    secEdit.exe /export /cfg $secEditPath
   
   $URA = get-content -path  $secEditPath |  Select-String  -Pattern 'S-1'
   $fragURA=@()
   foreach ($uraLine in $URA)
   {
   $uraItem = $uraLine.ToString().split("*").split("=") #.replace(",","")
   #write-host $uraItem -ForegroundColor Yellow

        foreach ($uralookupName in $URALookup.Values)
        {
        $uraItemTrim = $uraItem[0].trim()
        $uralookupTrim = $uralookupName.trim()[0]

            if ($uralookuptrim -eq $uraItemTrim)
                {
                   $uraDescripName = $uralookupName.trim()[1].split("|")[0]
                   $uraMSRecom = $uralookupName[1].split("|")[1].trim()
                   #Write-Host $uraDescripName -ForegroundColor Cyan
                   
                   $URAGPOPath = $URACommonPath + $uraDescripName

                   Add-Content $secEditOutPath -Value " " -encoding UTF8

                   $uraDescripName + " " + "`(" +$uraItem.trim()[0] +"`)" | Out-File $secEditOutPath -Append -encoding UTF8
                   $uraDescripName = "<div title=$uraMSRecom>$uraDescripName"

                   $uraTrimDescrip = "<div title=$URAGPOPath>$uraItemTrim"
                }
        }
       
       $uraItemTrimStart = ($uraItem | where {$_ -like "S-1*"}).replace(",","")

       $objSid=@()
     
       set-content -Path $secEditImpPath -Value " "
       $NameURA=@()
       foreach($uraSidItems in $uraItemTrimStart)
       {
           $objSid = New-Object System.Security.Principal.SecurityIdentifier("$uraSidItems")
           $objUserName = $objSID.Translate( [System.Security.Principal.NTAccount])
           #Write-Host $objUserName.Value -ForegroundColor Magenta
       
           "   " + $objUserName.Value  | Out-File $secEditOutPath -Append  -encoding UTF8

           [string]$NameURA += $objUserName.Value + ", "
       }
            
       $newObjURA = New-Object -TypeName PSObject
       Add-Member -InputObject $newObjURA -Type NoteProperty -Name UserRightAssignment-Name -Value $uraDescripName
       Add-Member -InputObject $newObjURA -Type NoteProperty -Name UserRightAssignment-Priv -Value $uraTrimDescrip
       Add-Member -InputObject $newObjURA -Type NoteProperty -Name URA-GroupName -Value $NameURA
       $fragURA += $newObjURA
   }
    
Write-Host " "
Write-Host "Completed User Rights Assignments" -foregroundColor Green   

################################################
##############  WINDOWS UPDATES  ###############
################################################
Write-Host " "
Write-Host "Gathering Windows Update and Installed Application Information" -foregroundColor Green
sleep 5

$date180days = (Get-Date).AddDays(-180).toString("yyyyMMdd")

    $HotFix=@()
    $getHF = Get-HotFix -ErrorAction SilentlyContinue  | Select-Object HotFixID,InstalledOn,Caption 

    foreach ($hfitem in $getHF)
    {
        $hfid = $hfitem.hotfixid
        $hfdate = $hfitem.installedon
        $hfdate = ($hfdate).Date.ToString("yyyyMMdd")
        $hfurl = $hfitem.caption
        $trueFalse = "True"

        if ($date180days -gt $hfdate)
            {
                $hfdate = "Warning $($hfdate) Warning"
                $trueFalse = "False"
            }

        $newObjHF = New-Object psObject
        Add-Member -InputObject $newObjHF -Type NoteProperty -Name HotFixID -Value $hfid
        Add-Member -InputObject $newObjHF -Type NoteProperty -Name InstalledOn -Value $hfdate
        Add-Member -InputObject $newObjHF -Type NoteProperty -Name Caption -Value $hfurl
        Add-Member -InputObject $newObjHF -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse         
        
        $HotFix += $newObjHF
    }

################################################
##############  INSTALLED APPS  ################
################################################
    $getUninx64 = Get-ChildItem  "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue
    $getUninx86 = Get-ChildItem  "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"  -ErrorAction SilentlyContinue
    $getUnin = $getUninx64 + $getUninx86
    $UninChild = $getUnin.Name.Replace("HKEY_LOCAL_MACHINE","HKLM:")
    $InstallApps =@()
    $date180days = (Get-Date).AddDays(-180).toString("yyyyMMdd")

    
    foreach ($uninItem in  $UninChild)
    {
        $getUninItem = Get-ItemProperty $uninItem -ErrorAction SilentlyContinue | where {$_.displayname -notlike "*kb*"}
    
        #Write-Host $getUninItem.DisplayName
        $UninDisN = $getUninItem.DisplayName -replace "$null",""
        $UninDisVer = $getUninItem.DisplayVersion -replace "$null",""
        $UninPub = $getUninItem.Publisher -replace "$null",""
        $UninDisIcon = ($getUninItem.DisplayIcon -replace "$null","").split(",")[0]
        $UninDate = $getUninItem.InstallDate -replace "$null",""
        $trueFalse = "True"

        if ($date180days -gt $UninDate)
            {
                $UninDate = "Warning $($UninDate) Warning"
                $trueFalse = "False"
            }
    
        $newObjInstApps = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name Publisher -Value  $UninPub 
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name DisplayName -Value $UninDisN
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name DisplayVersion -Value $UninDisVer
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name DisplayIcon -Value $UninDisIcon
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name InstallDate -Value $UninDate
        Add-Member -InputObject $newObjInstApps -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse 
        $InstallApps += $newObjInstApps
    }
  
################################################
###########  INSTALLED UPDATES  ################
################################################
#MS are making a bit of a mess of udpates, get-hotfix only returns the latest 10 installed
#Office 2019 onwards doesnt register installed KB's
#But for Office 2016 and older installed KB's do create keys in the Uninstall 

    $getUnin16 = Get-ChildItem  "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\" -ErrorAction SilentlyContinue
    $UninChild16 = $getUnin16.Name.Replace("HKEY_LOCAL_MACHINE","HKLM:")
    $InstallApps16 =@()
    
    foreach ($uninItem16 in  $UninChild16)
    {
        $getUninItem16 = Get-ItemProperty $uninItem16 -ErrorAction SilentlyContinue | where {$_.displayname -like "*kb*"}
        $UninDisN16 = $getUninItem16.DisplayName -replace "$null",""
        $UninDisVer16 = $getUninItem16.DisplayVersion -replace "$null",""
        $UninPub16 = $getUninItem16.Publisher -replace "$null",""
        $UninDate16 = $getUninItem16.InstallDate -replace "$null",""
    
        $newObjInstApps16 = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjInstApps16 -Type NoteProperty -Name Publisher -Value  $UninPub16 
        Add-Member -InputObject $newObjInstApps16 -Type NoteProperty -Name DisplayName -Value  $UninDisN16
        Add-Member -InputObject $newObjInstApps16 -Type NoteProperty -Name DisplayVersion -Value  $UninDisVer16
        Add-Member -InputObject $newObjInstApps16 -Type NoteProperty -Name InstallDate -Value   $UninDate16
        $InstallApps16 += $newObjInstApps16
    }  
 
Write-Host " "
Write-Host "Completed Gathering Windows Update and Installed Application Information" -foregroundColor Green

################################################
##########  INSTALLED FEATURES #################
################################################
Write-Host " "
Write-Host "Windows Features" -foregroundColor Green
sleep 5

    $VulnReport = "C:\SecureReport"
    $OutFunc = "WindowsFeatures" 
                
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
       New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $WinFeaturePathtxt = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.txt"
    $FragWinFeature=@()
    $getWindows = Get-CimInstance win32_operatingsystem | Select-Object caption
        if ($getWindows.caption -notlike "*Server*")
            {
            Dism /online /Get-Features >> $WinFeaturePathtxt
            $getdismCont = (Get-Content $WinFeaturePathtxt | Select-String enabled -Context 1) -replace("  Feature Name : ","") -replace("> State : ",",") | Sort-Object 
   
                foreach ($dismItem in $getdismCont)
                    {
                        $dismSplit = $dismItem.split(",")
                        $dismSplit[0]
                        $dismSplit[1]

                        $newObjWinFeature = New-Object -TypeName PSObject
                        Add-Member -InputObject $newObjWinFeature -Type NoteProperty -Name WindowsFeature -Value $dismSplit[0]
                        Add-Member -InputObject $newObjWinFeature -Type NoteProperty -Name InstallState -Value $dismSplit[1]
                        $FragWinFeature += $newObjWinFeature
                    }
            }

        if($getdismCont -eq $null)
            {
           
            $getWindows  = Get-WindowsOptionalFeature -online | where {$_.state -eq "enabled"}
                foreach($feature in $getWindows)
                    {
                        $featureName = $feature.featurename
                        $featureState = $feature.state

                        $newObjWinFeature = New-Object -TypeName PSObject
                        Add-Member -InputObject $newObjWinFeature -Type NoteProperty -Name WindowsFeature -Value $featureName
                        Add-Member -InputObject $newObjWinFeature -Type NoteProperty -Name InstallState -Value $featureState
                        $FragWinFeature += $newObjWinFeature        
                    }
        
            }

            $FragAppx=@()
            $gtAppxPackage  = Get-AppxPackage 
                foreach($AppxPackageItem in $gtAppxPackage)
                    {
                        $appxName = $AppxPackageItem.name
                        $appxStatus = $AppxPackageItem.status

                        $newObjWinAppx = New-Object -TypeName PSObject
                        Add-Member -InputObject $newObjWinAppx -Type NoteProperty -Name WindowsFeature -Value $appxName
                        Add-Member -InputObject $newObjWinAppx -Type NoteProperty -Name InstallState -Value $appxStatus
                        $FragAppx += $newObjWinAppx       
                    }


        $FragSrvWinFeature=@()
        if($getWindows.caption -like "*Server*")
            {
            $WinFeature = Get-WindowsFeature | where {$_.installed -eq "installed"} | Sort-Object name
            foreach ($featureItem in $WinFeature)
                {
                    $newObjSrvWinFeature = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjSrvWinFeature -Type NoteProperty -Name WindowsSrvFeature -Value $featureItem.DisplayName 
                    #Add-Member -InputObject $newObjWinFeature -Type NoteProperty -Name InstallState -Value $featureItem.Installed
                    $FragSrvWinFeature += $newObjSrvWinFeature
                }
            }

################################################
##################  ANTIVIRUS  #################
################################################

#https://stackoverflow.com/questions/33649043/powershell-how-to-get-antivirus-product-details - "borrowed" baulk of script from site

    #$AntiVirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct  
    $AntiVirusProducts = Get-CimInstance -Namespace "root\SecurityCenter2" -Class AntiVirusProduct 

    if ($AntiVirusProducts -ne $null)
    {
        if ($AntiVirusProducts.Count -gt "1")
        {$AntiVirusProducts = $AntiVirusProducts | where {$_.displayname -ne "Windows Defender"}}
    
        $newObjAVStatus=@()
        foreach($AntiVirusProduct in $AntiVirusProducts){
            #Switch to determine the status of antivirus definitions and real-time protection.
            switch ($AntiVirusProduct.productState) 
            {
                "262144" {$defstatus = "Up to date" ;$rtstatus = "Warning Disabled warning"}
                "262160" {$defstatus = "Warning Out of date warning" ;$rtstatus = "Warning Disabled warning"}
                "266240" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
                "266256" {$defstatus = "Warning Out of date warning" ;$rtstatus = "Enabled"}
                "270336" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
                "393216" {$defstatus = "Up to date" ;$rtstatus = "Warning Disabled warning"}
                "393232" {$defstatus = "Warning Out of date" ;$rtstatus = "Warning Disabled warning"}
                "393488" {$defstatus = "Warning Out of date" ;$rtstatus = "Warning Disabled warning"}
                "397312" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
                "397568" {$defstatus = "Up to date" ;$rtstatus = "Enabled"}
                "397328" {$defstatus = "Warning Out of date" ;$rtstatus = "Enabled"}
                "397584" {$defstatus = "Warning Out of date" ;$rtstatus = "Enabled"}   
                "393472" {$defstatus = "Up to date" ;$rtstatus  = "Warning Disabled warning"}
                "401664" {$defstatus = "Up to date" ;$rtstatus  = "Warning Disabled warning"}
                default {$defstatus = "Warning Unknown warning" ;$rtstatus = "Warning Unknown warning"}
            }

            $avDisplay = $AntiVirusProduct.displayName
            $avProduct = $AntiVirusProduct.pathToSignedProductExe 
            $avPath = $AntiVirusProduct.pathToSignedReportingExe 
            $avStatus = $defstatus
            $avReal = $rtstatus

            $AVService = ((get-service | where {$_.DisplayName -like "*$avDisplay*" }).Status)[0]
        
            $newObjAVStatus = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjAVStatus -Type NoteProperty -Name AVName -Value $avDisplay
            Add-Member -InputObject $newObjAVStatus -Type NoteProperty -Name AVProduct -Value $avProduct
            Add-Member -InputObject $newObjAVStatus -Type NoteProperty -Name AVPathtoExecute -Value $avPath
            Add-Member -InputObject $newObjAVStatus -Type NoteProperty -Name AVStatus -Value $avStatus 
            Add-Member -InputObject $newObjAVStatus -Type NoteProperty -Name AVEngine -Value $avReal
            #Add-Member -InputObject $newObjAVStatus -Type NoteProperty -Name AVService -Value $AVService 
            $FragAVStatus += $newObjAVStatus

            }
        }
        Else  #server and Defender cant be detected
        {
            $newObjAVStatus = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjAVStatus -Type NoteProperty -Name AVName -Value "Warning Antivirus cant be detected, assume the worst and its not installed warning"
            $FragAVStatus += $newObjAVStatus
        }

################################################
############  UNQUOTED PATHS  ##################
################################################
Write-Host " "
Write-Host "From this point onwards things will slow down, in some cases it may appear nothing is happening, be patient" -foregroundColor Green
Write-Host " "
Write-Host "Searching for UnQuoted Path Vulnerabilities" -foregroundColor Green
sleep 7

    #Unquoted paths   
    $VulnReport = "C:\SecureReport"
    $OutFunc = "UnQuoted" 
                
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $qpath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"
 
    #Unquoted paths
    
    #Get-CimInstance win32_service
    #gwmi win32_service

    $vulnSvc = Get-CimInstance win32_service | foreach{$_} | 
    where {($_.pathname -ne $null) -and ($_.pathname.trim() -ne "")} | 
    where {-not $_.pathname.startswith("`"")} | 
    where {($_.pathname.substring(0, $_.pathname.indexof(".sys") + 4 )) -match ".* .*" -or ($_.pathname.substring(0, $_.pathname.indexof(".exe") + 4 )) -match ".* .*" }
    $fragUnQuoted=@()
    
    foreach ($unQSvc in $vulnSvc)
    {
    $svc = $unQSvc.name
    $SvcReg = Get-ItemProperty HKLM:\System\CurrentControlSet\Services\$svc -ErrorAction SilentlyContinue
    
        if ($SvcReg.imagePath -like "*.exe*")
        {
            $SvcRegSp =  $SvcReg.imagePath -split ".exe"
            $SvcRegSp0 = $SvcRegSp[0]
            $SvcRegSp1 = $SvcRegSp[1]
            $image = "`"$SvcRegSp0" + ".exe`""+  " " + $SvcRegSp1
            $SvcReg |Select-Object PSChildName,ImagePath  | out-file $qpath -Append
                
            $newObjSvc = New-Object psObject
            Add-Member -InputObject $newObjSvc -Type NoteProperty -Name ServiceName -Value "Warning $($SvcReg.PSChildName) warning"
            Add-Member -InputObject $newObjSvc -Type NoteProperty -Name Path -Value "Warning $($SvcReg.ImagePath) warning"
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
            Add-Member -InputObject $newObjSvc -Type NoteProperty -Name ServiceName -Value "Warning $($SvcReg.PSChildName) warning"
            Add-Member -InputObject $newObjSvc -Type NoteProperty -Name Path -Value "Warning $($SvcReg.ImagePath) warning"
            $fragUnQuoted += $newObjSvc
        }
    }

Write-Host " "
Write-Host "Finished Searching for UnQuoted Path Vulnerabilities" -foregroundColor Green
      
################################################
################  MSINFO32  ####################
################################################
Write-Host " "
Write-Host "Starting MSInfo32 and Outputting to File" -foregroundColor Green
sleep 5

    #Virtualization - msinfo32
    $VulnReport = "C:\SecureReport"
    $OutFunc = "MSInfo" 
    $wdacEnforce = "wdacEnforce"

                
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $msinfoPath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.txt"
    $msinfoPathcsv = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.csv"
    $msinfoPathXml = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.xml"

    $wdacEnforcecsv = "C:\SecureReport\output\$OutFunc\" + "$wdacEnforce.csv"
    $wdacEnforceXml = "C:\SecureReport\output\$OutFunc\" + "$wdacEnforce.xml"

    & cmd /c msinfo32 /nfo "C:\SecureReport\output\$OutFunc\" /report $msinfoPath
    $getMsinfo = Get-Content $msinfoPath | select -First 50

    <#
    Device Guard Virtualization based security	Running	
    Device Guard Required Security Properties	Base Virtualization Support, Secure Boot, DMA Protection	
    Device Guard Available Security Properties	Base Virtualization Support, Secure Boot, DMA Protection, UEFI Code Readonly	
    Device Guard Security Services Configured	Credential Guard, Hypervisor enforced Code Integrity	
    Device Guard Security Services Running	Credential Guard, Hypervisor enforced Code Integrity
    A hypervisor has been detected. Features required for Hyper-V will not be displayed.
    #>

    Set-Content -Path $msinfoPathcsv -Value 'Virtualization;On\Off'
    ($getMsinfo | Select-String "Secure Boot State") -replace "off",";off" -replace "on",";on" |Out-File $msinfoPathcsv -Encoding utf8 -Append
    ($getMsinfo | Select-String "Kernel DMA Protection") -replace "off",";off" -replace " on",";on"  |Out-File $msinfoPathcsv -Encoding utf8 -Append
    ($getMsinfo | Select-String "Guard Virtualization based") -replace "security	Run","security;	Run" |Out-File $msinfoPathcsv -Encoding utf8 -Append
    ($getMsinfo | Select-String "Required Security Properties") -replace "Required Security Properties","Required Security Properties;" |Out-File $msinfoPathcsv -Encoding utf8 -Append
    ($getMsinfo | Select-String "Available Security Properties") -replace "Available Security Properties","Available Security Properties;" |Out-File $msinfoPathcsv -Encoding utf8 -Append 
    ($getMsinfo | Select-String "based security services configured") -replace "based security services configured","based security services configured;"  |Out-File $msinfoPathcsv -Encoding utf8 -Append
    ($getMsinfo | Select-String "based security services running") -replace "based security services running","based security services running;" |Out-File $msinfoPathcsv -Encoding utf8 -Append
    ($getMsinfo | Select-String "Application Control Policy") -replace "policy	Enforced","policy;	Enforced" -replace "Policy  Audit","Policy;  Audit"|Out-File $msinfoPathcsv -Encoding utf8 -Append 
    ($getMsinfo | Select-String "Application Control User") -replace "off",";off" -replace " on",";on" -replace "policy	Enforced","policy;	Enforced"  -replace "Policy  Audit","Policy;  Audit" |Out-File $msinfoPathcsv -Encoding utf8 -Append 
    ($getMsinfo | Select-String "Device Encryption Support") -replace "Encryption Support","Encryption Support;" |Out-File $msinfoPathcsv -Encoding utf8 -Append

    Import-Csv $msinfoPathcsv -Delimiter ";" | Export-Clixml $msinfoPathXml
    $MsinfoClixml = Import-Clixml $msinfoPathXml 

    #Import-Clixml $msinfoPathXml | select-string "Windows Defender Application Control policy"

    Set-Content -Path $wdacEnforcecsv -Value 'WDAC\DeviceGuard;Enforced\Audit'
    ($getMsinfo | Select-String "Application Control Policy") -replace "policy	Enforced","policy;	Enforced" -replace "Policy  Audit","Policy;  Audit"|Out-File $wdacEnforcecsv -Encoding utf8 -Append 
    ($getMsinfo | Select-String "Application Control User") -replace "off",";off" -replace " on",";on" -replace "policy	Enforced","policy;	Enforced"  -replace "Policy  Audit","Policy;  Audit" |Out-File $wdacEnforcecsv -Encoding utf8 -Append 

    Import-Csv $wdacEnforcecsv -Delimiter ";" | Export-Clixml $wdacEnforceXml
    $fragwdacClixml = Import-Clixml $wdacEnforceXml


Write-Host " "
Write-Host "Finished Collecting MSInfo32 data for VBS" -foregroundColor Green


################################################
############  WDAC | DEVICE GUARD  #############
################################################
#Citools available from Windows 11 22H2
$osBuild = (Get-CimInstance -ClassName win32_operatingsystem).buildnumber 
$fragWDACCIPolicy=@()
if ($osBuild -ge "22621")
{
    $ciPolicyTool =  (CiTool -lp -json | ConvertFrom-Json).Policies | Where-Object {$_.IsEnforced -eq "True"} | Select-Object -Property * 

    Foreach($ciPolicy in $ciPolicyTool)
        {
            $ciPolName = $ciPolicy.FriendlyName
            $ciPolID = $ciPolicy.PolicyID
            $ciPolsys = $ciPolicy.IsSystemPolicy
            $ciPolDisk = $ciPolicy.IsOnDisk
            $ciPolEnforced = $ciPolicy.IsEnforced
            $ciPolEnforced = if ($ciPolicy.IsEnforced -match "False"){"Warning $($ciPolicy.IsEnforced) Warning"}else{$ciPolicy.IsEnforced}
            $ciPolAuthorised = $ciPolicy.IsAuthorized

            $newObjWdac = New-Object PSObject
            Add-Member -InputObject $newObjWdac -Type NoteProperty -Name CIPolicyName -Value $ciPolName
            Add-Member -InputObject $newObjWdac -Type NoteProperty -Name CIPolicyID -Value $ciPolID 
            Add-Member -InputObject $newObjWdac -Type NoteProperty -Name CIPolicySystemPol -Value $ciPolsys
            Add-Member -InputObject $newObjWdac -Type NoteProperty -Name CIPolicyOnDisk -Value $ciPolDisk                        
            Add-Member -InputObject $newObjWdac -Type NoteProperty -Name CIPolicyEnforced -Value $ciPolEnforced             
            Add-Member -InputObject $newObjWdac -Type NoteProperty -Name CIPolicyAuthorised -Value $ciPolAuthorised            
            $fragWDACCIPolicy += $newObjWdac        
        }
}

################################################
################  DRIVERQRY  ###################
################################################
Write-Host " "
Write-Host "Starting DriverQuery and Out putting to File" -foregroundColor Green
sleep 5

    $VulnReport = "C:\SecureReport"
    $OutFunc = "DriverQuery" 
                
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $devQryPathtxt = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.txt"
    $devQryPathcsv = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.csv"
    $devQryPathXml = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.xml"

    $drvSign = driverquery.exe /SI >>  $devQryPathtxt
    $getdrvQry = Get-Content  $devQryPathtxt | Select-String "FALSE" 

    $DriverQuery=@()

    foreach($drvQryItem in $getdrvQry)
    {
        if ($drvQryItem -match "FALSE")
        {
            $drvQryItem = "Warning $drvQryItem warning"
        }
    
        $newObjDriverQuery = New-Object PSObject
        Add-Member -InputObject $newObjDriverQuery -Type NoteProperty -Name DriverName -Value $drvQryItem 
        $DriverQuery += $newObjDriverQuery
    }

Write-Host " "
Write-Host "Finished Collectiong DriverQuery data for VBS" -foregroundColor Green

################################################
##############  NETWORK SETTINGS  ##############
################################################
#Going to use the table below for other projects prefix, mask, available addresses, number of hosts
    $IPSubnet =[ordered]@{

    32 = "32","255.255.255.255","1","1"
    31 = "31","255.255.255.254","2","2"
    30 = "30","255.255.255.252","4","2"
    29 = "29","255.255.255.248","8","6"
    28 = "28","255.255.255.240","16","14"
    27 = "27","255.255.255.224","32","30"
    26 = "26","255.255.255.192","64","62"
    25 = "25","255.255.255.128","128","126"
    24 = "24","255.255.255.0","256","254"
    23 = "23","255.255.254.0","512","510"
    22 = "22","255.255.252.0","1024","1022"
    21 = "21","255.255.248.0","2048","2046"
    20 = "20","255.255.240.0","4096","4094"
    19 = "19","255.255.224.0","8192","8190"
    18 = "18","255.255.192.0","16384","16382"
    17 = "17","255.255.128.0","32768","32766"
    16 = "16","255.255.0.0","65536","65534"
    15 = "15","255.254.0.0","131072","131070"
    14 = "14","255.252.0.0","262144","262142"
    13 = "13","255.248.0.0","524288","524286"
    12 = "12","255.240.0.0","1048576","1048574"
    11 = "11","255.224.0.0","2097152","2097150"
    10 = "10","255.192.0.0","4194304","4194302"
    9 = "9","255.128.0.0","8388608","8388606"
    8 = "8","255.0.0.0","16777216","16777214"
    7 = "7","254.0.0.0","33554432","33554430"
    6 = "6","252.0.0.0","67108864","67108862"
    5 = "5","248.0.0.0","134217728","134217726"
    4 = "4","240.0.0.0","268435456","268435454"
    3 = "3","224.0.0.0","536870912","536870910"
    2 = "2","192.0.0.0","1073741824","1073741822"
    1 = "1","128.0.0.0","2147483648","2147483646"
    0 = "0","0.0.0.0","4294967296","4294967294"
    }

$fragNetwork4=@()
$fragNetwork6=@()

    $gNetAdapter = Get-NetAdapter | where {$_.Status -eq "up"}

    foreach($gNetAdp in $gNetAdapter)
    {

        $intAlias = $gNetAdp.InterfaceAlias

        $macAddy = [string]$gNetAdp.MacAddress 

        $gNetIPC = Get-NetIPConfiguration -InterfaceAlias $gNetAdp.Name
            $IPAddress4 = $gNetIPC.IPv4Address.ipaddress 
            $IPAddress4 = [string]$IPAddress4 
        
            $IPAddress6 = $gNetIPC.IPv6Address.ipaddress 
            $IPAddress6 = [string]$IPAddress6

            $Router4 = $gNetIPC.IPv4DefaultGateway.nexthop 
            $Router4 =[string]$Router4
        
            $Router6 = $gNetIPC.IPv6DefaultGateway.nexthop 
            $Router6  = [string]$Router6 
        
            $dnsAddress = $gNetIPC.dnsserver.serveraddresses 
            $dnsAddress = [String]$dnsAddress

            $InterfaceAlias = $gNetAdp.Name
            $gNetIPA4 = Get-NetIPAddress  | where {$_.InterfaceAlias -eq "$InterfaceAlias" -and $_.AddressFamily -eq "IPv4"}
            $IPSubnet4 = $gNetIPA4.PrefixLength

            $gNetIPA6 = Get-NetIPAddress | where {$_.InterfaceAlias -eq "$InterfaceAlias" -and $_.AddressFamily -eq "IPv6"}
            $IPSubnet6 = $gNetIPA6.PrefixLength -join " ,"
            $IPSubnet6 = [string]$IPSubnet6 

            foreach ($IPSubItem in $IPSubnet.Values)
            {
                $subPrefix = $IPSubItem[0]
                $subnet = $IPSubItem[1]
                $subAddress = $IPSubItem[2]
                $subHosts = $IPSubItem[3]
                if ($subPrefix -eq $IPSubnet4)
                {
                    $subnetTrans = $subnet
                }
            }    

            $newObjNetwork4 = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjNetwork4 -Type NoteProperty -Name IPv4Address -Value $IPAddress4
            Add-Member -InputObject $newObjNetwork4 -Type NoteProperty -Name IPv4Subnet -Value $subnetTrans
            Add-Member -InputObject $newObjNetwork4 -Type NoteProperty -Name IPv4Gateway -Value $Router4
            Add-Member -InputObject $newObjNetwork4 -Type NoteProperty -Name DNSServers -Value $dnsAddress
            Add-Member -InputObject $newObjNetwork4 -Type NoteProperty -Name Mac -Value $macAddy 
            $fragNetwork4 += $newObjNetwork4

            $newObjNetwork6 = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjNetwork6 -Type NoteProperty -Name IPv6Address -Value $IPAddress6 
            Add-Member -InputObject $newObjNetwork6 -Type NoteProperty -Name IPv6Subnet -Value $IPSubnet6
            Add-Member -InputObject $newObjNetwork6 -Type NoteProperty -Name IPv6Gateway -Value $Router6
            Add-Member -InputObject $newObjNetwork6 -Type NoteProperty -Name DNSServers -Value $dnsAddress
            Add-Member -InputObject $newObjNetwork6 -Type NoteProperty -Name Mac -Value $macAddy 
            $fragNetwork6 += $newObjNetwork6

        }
################################################
#############  MISC REG SETTINGS  ##############
################################################
Write-Host " "
Write-Host "Auditing Various Registry Settings" -foregroundColor Green
sleep 5

    #kernel-mode hardware-enforced stack protection
    $getkernelMode = Get-Item 'HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\' -ErrorAction SilentlyContinue
    $getkernelModeVal =  $getkernelMode.GetValue("FeatureSettingsOverride")
    $fragkernelModeVal =@()

    if ($getkernelModeVal -eq "9")
    {
        $kernelModeSet = "Kernel-mode hardware-enforced stack protection key FeatureSettingsOverride is enabled with a value of $getkernelModeVal" 
        $kernelModeReg = "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\"
        $kernelModeCom = "Kernel-mode Hardware-enforced Stack Protection is a security feature of Windows 11 22H2"
        $trueFalse = "True"
    }
    else
    {
        $kernelModeSet = "Warning Kernel-mode hardware-enforced stack protection key FeatureSettingsOverride is disabled with a value of $getkernelModeVal Warning" 
        $kernelModeReg = "HKLM:\System\CurrentControlSet\Control\Session Manager\Memory Management\"
        $kernelModeCom = "Kernel-mode Hardware-enforced Stack Protection is a security feature of Windows 11 22H2"
        $trueFalse = "False"
    }

    $newObjkernelMode = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjkernelMode -Type NoteProperty -Name KernelModeSetting -Value  $kernelModeSet
    Add-Member -InputObject $newObjkernelMode -Type NoteProperty -Name KernelModeRegValue -Value $kernelModeReg 
    Add-Member -InputObject $newObjKernelMode -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    #Add-Member -InputObject $newObjkernelMode -Type NoteProperty -Name kernelModeComment -Value $kernelModeCom
    $fragkernelModeVal += $newObjkernelMode


    #LSA
    $getLSA = Get-Item 'HKLM:\System\CurrentControlSet\Control\lsa\' -ErrorAction SilentlyContinue
    $getLSAPPL =  $getLSA.GetValue("RunAsPPL")
    $fragLSAPPL =@()

    if ($getLSAPPL -eq "1")
    {
        $lsaSet = "LSA is enabled the RunAsPPL is set to $getLSAPPL" 
        $lsaReg = "HKLM:\System\CurrentControlSet\Control\lsa\"
        $lsaCom = "Win10 and above Credential Guard should be used for Domain joined clients"
        $trueFalse = "True"
    }
    else
    {
        $lsaSet = "Warning Secure LSA is disabled set RunAsPPL to 1 Warning" 
        $lsaReg = "HKLM:\System\CurrentControlSet\Control\lsa\"
        $lsaCom = "Required for Win8.1 and below"
        $trueFalse = "False"
    }

    $newObjLSA = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjLSA -Type NoteProperty -Name LSASetting -Value  $lsaSet
    Add-Member -InputObject $newObjLSA -Type NoteProperty -Name LSARegValue -Value $lsaReg 
    Add-Member -InputObject $newObjLSA -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    #Add-Member -InputObject $newObjLSA -Type NoteProperty -Name LSAComment -Value $lsaCom
    $fragLSAPPL += $newObjLSA
 
    #WDigest
    $getWDigest = Get-Item 'HKLM:\System\CurrentControlSet\Control\SecurityProviders\WDigest\' -ErrorAction SilentlyContinue
    $getWDigestULC =  $getWDigest.GetValue("UseLogonCredential")
    $fragWDigestULC =@()

    if ($getWDigestULC -eq "1")
    {
        $WDigestSet = "Warning WDigest is enabled and plain text passwords are stored in LSASS Warning" 
        $WDigestReg = "HKLM:\System\CurrentControlSet\Control\SecurityProviders\WDigest\"
        $trueFalse = "False"

    }
    else
    {
        $WDigestSet = "Secure WDigest is disabled" 
        $WDigestReg = "HKLM:\System\CurrentControlSet\Control\SecurityProviders\WDigest\"
        $trueFalse = "True"
    }

    $newObjWDigest = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWDigest -Type NoteProperty -Name WDigestSetting -Value  $WDigestSet
    Add-Member -InputObject $newObjWDigest -Type NoteProperty -Name WDigestRegValue -Value $WDigestReg 
    Add-Member -InputObject $newObjWDigest -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWDigestULC += $newObjWDigest


    #Credential Guard
    $getCredGu = Get-Item 'HKLM:\System\CurrentControlSet\Control\LSA\' -ErrorAction SilentlyContinue
    $getCredGuCFG =  $getCredGu.GetValue("LsaCfgFlags")
    $fragCredGuCFG =@()

    if ($getCredGuCFG -eq "1")
    {
        $CredGuSet = "Credential Guard is enabled, the LsaCfgFlags value is set to $getCredGuCFG" 
        $CredGuReg = "HKLM:\System\CurrentControlSet\Control\LSA\"
        $CredGuCom = "Credential Guard is enabled with UEFI persistance."
        $trueFalse = "True"
    }
    elseif ($getCredGuCFG -eq "2")
    {
        $CredGuSet = "Credential Guard is enabled, the LsaCfgFlags value is set to $getCredGuCFG" 
        $CredGuReg = "HKLM:\System\CurrentControlSet\Control\LSA\"
        $CredGuCom = "Credential Guard is enable without UEFI persistence."
        $trueFalse = "True"
    }
    else
    {
        $CredGuSet = "Warning Secure Credential Guard is disabled, LsaCfgFlags is set to 0 Warning" 
        $CredGuReg = "HKLM:\System\CurrentControlSet\Control\LSA\"
        $CredGuCom = "Credential Guard requires the client to be Domain joined"
        $trueFalse = "False"
    }

    $newObjCredGu = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjCredGu -Type NoteProperty -Name CredentialGuardSetting -Value  $CredGuSet
    Add-Member -InputObject $newObjCredGu -Type NoteProperty -Name CredentialGuardRegValue -Value $CredGuReg 
    Add-Member -InputObject $newObjCredGu -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    #Add-Member -InputObject $newObjCredGu -Type NoteProperty -Name CredGuComment -Value $CredGuCom
    $fragCredGuCFG += $newObjCredGu
 

    #LAPS is installed
    $getLapsPw = Get-Item "HKLM:\Software\Policies\Microsoft Services\AdmPwd\" -ErrorAction SilentlyContinue
    $getLapsPwEna =  $getLapsPw.GetValue("AdmPwdEnabled")
    $getLapsPwCom =  $getLapsPw.GetValue("PasswordComplexity")
    $getLapsPwLen =  $getLapsPw.GetValue("PasswordLength")
    $getLapsPwDay =  $getLapsPw.GetValue("PasswordAgeDays")
    $fragLapsPwEna =@()

    if ($getLapsPwEna -eq "1")
    {
        $LapsPwSetena = "LAPS is installed and enabled, the AdmPwdEnabled value is set to $getLapsPwEna" 
        $LapsPwSetcom = "LAPS password complexity value is set to $getLapsPwCom" 
        $LapsPwSetlen = "LAPS password length value is set to $getLapsPwLen" 
        $LapsPwSetday = "LAPS password age value is to $getLapsPwDay" 
        $LapsPwReg = "HKLM:\Software\Policies\Microsoft Services\AdmPwd\" 
        $trueFalse = "True"

        $newObjLapsPw = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LAPSPasswordEnabled -Value $LapsPwSetena
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LAPSPasswordComplexity -Value $LapsPwSetcom 
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LAPSPasswordLength -Value $LapsPwSetlen
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LAPSPasswordDay -Value $LapsPwSetday 
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LAPSPasswordReg -Value $LapsPwReg
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
        $fragLapsPwEna += $newObjLapsPw

    }
    else
    {
        $LapsPwSet = "Warning LAPS is not installed or the value is set to 0 Warning" 
        $LapsPwReg = "HKLM:\Software\Policies\Microsoft Services\AdmPwd\" 
        $LapsPwCom = "LAPS is not installed or configured - Ignore if not Domain Joined"
        $trueFalse = "False"

        $newObjLapsPw = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LAPSPasswordEnabled -Value  $LapsPwSet
        Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LAPSPasswordReg -Value $LapsPwReg
        Add-Member -InputObject $newObjLapsPW -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse         
        #Add-Member -InputObject $newObjLapsPw -Type NoteProperty -Name LapsPwComment -Value $LapsPwCom
        $fragLapsPwEna += $newObjLapsPw
    }

       
    #DLL Safe Search
    $getDLL = Get-Item 'HKLM:\System\CurrentControlSet\Control\Session Manager' -ErrorAction SilentlyContinue
    $getDLLSafe =  $getDLL.GetValue("SafeDLLSearchMode")

    $fragDLLSafe =@()
    if ($getDLLSafe -eq "1")
    {
        $dllSet = " DLLSafeSearch is enabled the SafeDLLSearchMode is set to $getDLLSafe" 
        $dllReg = "HKLM:\System\CurrentControlSet\Control\Session Manager"
        $dllCom = "Protects against DLL search order hijacking"
        $trueFalse = "True"
    }
    else
    {
        $dllSet = "Warning DLLSafeSearch is disabled set SafeDLLSearchMode to 1 Warning" 
        $dllReg = "HKLM:\System\CurrentControlSet\Control\Session Manager"
        $dllCom = "Protects against DLL search order hijacking"
        $trueFalse = "False"
    }

    $newObjDLLSafe = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjDLLSafe -Type NoteProperty -Name DLLSafeSetting -Value  $dllSet
    Add-Member -InputObject $newObjDLLSafe -Type NoteProperty -Name DLLSafeValue -Value $dllReg 
    Add-Member -InputObject $newObjDLLSafe -Type NoteProperty -Name DLLSafeComment -Value $dllCom
    Add-Member -InputObject $newObjDLLSafe -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragDLLSafe += $newObjDLLSafe


    #Code Integrity
    $getCode = Get-Item 'HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity' -ErrorAction SilentlyContinue
    $getCode =  $getCode.GetValue("Enabled")

    $fragCode =@()
    if ($getCode -eq "1")
    {
        $CodeSet = "Hypervisor Enforced Code Integrity is enabled" 
        $CodeReg = "HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
        $CodeCom = "Protects against credential theft"
        $trueFalse = "True"
    }
    else
    {
        $CodeSet = "Warning Hypervisor Enforced Code Integrity is disabled set Enabled to 1 Warning" 
        $CodeReg = "HKLM:\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity"
        #$CodeCom = "Protects against credential theft"
        $trueFalse = "False"
    }

    $newObjCode = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjCode -Type NoteProperty -Name CodeSetting -Value  $CodeSet
    Add-Member -InputObject $newObjCode -Type NoteProperty -Name CodeValue -Value $CodeReg 
    Add-Member -InputObject $newObjCode -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    #Add-Member -InputObject $newObjCode -Type NoteProperty -Name CodeComment -Value $CodeCom
    $fragCode += $newObjCode


    #InstallElevated
    $getPCInstaller = Get-Item HKLM:\Software\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue
    $getUserInstaller = Get-Item HKCU:\Software\Policies\Microsoft\Windows\Installer -ErrorAction SilentlyContinue
    $PCElevate =  $getUserInstaller.GetValue("AlwaysInstallElevated")
    $UserElevate = $getPCInstaller.GetValue("AlwaysInstallElevated")

    $fragPCElevate =@()
    if ($PCElevate -eq "1")
    {
        $ElevateSet = "Warning Client setting Always Install Elevate is enabled Warning" 
        $ElevateReg = "HKLM:\Software\Policies\Microsoft\Windows\Installer"
        $trueFalse = "False"
    }
    else
    {
        $ElevateSet = "Client setting  Always Install Elevate is disabled" 
        $ElevateReg = "HKLM:\Software\Policies\Microsoft\Windows\Installer"
        $trueFalse = "True"
    }

    $newObjElevate = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateSetting -Value  $ElevateSet
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateRegistry -Value $ElevateReg
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragPCElevate += $newObjElevate 

    if ($UserElevate -eq "1")
    {
        $ElevateSet = "Warning User setting Always Install Elevate is enabled Warning" 
        $ElevateReg = "HKCU:\Software\Policies\Microsoft\Windows\Installer"
        $trueFalse = "False"
    }
    else
    {
        $ElevateSet = "User setting Always Install Elevate is disabled" 
        $ElevateReg = "HKCU:\Software\Policies\Microsoft\Windows\Installer"
        $trueFalse = "True"
    }
       
    $newObjElevate = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateSetting -Value  $ElevateSet
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name AlwaysElevateRegistry -Value $ElevateReg
    Add-Member -InputObject $newObjElevate -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragPCElevate += $newObjElevate 

    #AutoLogon Details in REG inc password   
    $getAutoLogon = Get-Item  "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue
    $AutoLogonDefUser =  $getAutoLogon.GetValue("DefaultUserName")
    $AutoLogonDefPass =  $getAutoLogon.GetValue("DefaultPassword") 

    $fragAutoLogon =@()

    if ($AutoLogonDefPass  -eq "$null")
    {
        $AutoLPass = "There is no Default Password set for AutoLogon" 
        $AutoLUser = "There is no Default User set for AutoLogon" 
        $AutoLReg = "HKLM:\Software\Microsoft\Windows NT\Currentversion\Winlogon"
        $trueFalse = "True"
    }
    else
    {
        $AutoLPass = "Warning AutoLogon default password is set with a vaule of $AutoLogonDefPass Warning" 
        $AutoLUser = "Warning AutoLogon Default User is set with a vaule of $AutoLogonDefUser Warning" 
        $AutoLReg = "HKLM:\Software\Microsoft\Windows NT\Currentversion\Winlogon"
        $trueFalse = "False"
    }

    $newObjAutoLogon = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjAutoLogon -Type NoteProperty -Name AutoLogonUsername -Value $AutoLUser
    Add-Member -InputObject $newObjAutoLogon -Type NoteProperty -Name AutoLogonPassword -Value  $AutoLPass
    Add-Member -InputObject $newObjAutoLogon -Type NoteProperty -Name AutoLogonRegistry -Value $AutoLReg
    Add-Member -InputObject $newObjAutoLogon -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragAutoLogon += $newObjAutoLogon


        
################################################
#########  LEGACY NETWORK PROTOCOLS  ##########
################################################
#Legacy Network
    $VulnReport = "C:\SecureReport"
    $OutFunc = "llmnr" 
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }
    $llnmrpath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"
   
    $fragLegNIC=@()

    #SMB1 Driver
    cd HKLM:
    $getsmb1drv = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\MrxSmb10" -ErrorAction SilentlyContinue
    $ensmb1drv = $getsmb1drv.Start

    if ($ensmb1drv -eq "4")
    {
        $legProt = "SMB v1 client driver is set to $ensmb1drv in the Registry" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\MrxSmb10.Start"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning SMB v1 client driver is enabled Warning"
        $legReg = "HKLM:\System\CurrentControlSet\Services\MrxSmb10.Start"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #SMB v1 server
    cd HKLM:
    $getsmb1srv = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters\" -ErrorAction SilentlyContinue
    $ensmb1srv = $getsmb1srv.SMB1

    if ($ensmb1srv -eq "0")
    {
        $legProt = "SMB v1 Server is set to $ensmb1srv in the Registry" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters.SMB1"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning SMB v1 Server is enabled Warning"
        $legReg = "HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters.SMB1"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #Insecure logons to an SMB server must be disabled
    cd HKLM:
    $getsmb1srv = Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation\" -ErrorAction SilentlyContinue
    $ensmb1srv = $getsmb1srv.AllowInsecureGuestAuth

    if ($ensmb1srv -eq "0")
    {
        $legProt = "Insecure logons to an SMB server is set to $ensmb1srv and disabled" 
        $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation\Parameters.AllowInsecureGuestAuth"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning Insecure logons to an SMB server is enabled Warning"
        $legReg = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LanmanWorkstation\Parameters.AllowInsecureGuestAuth"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #llmnr = 0 is disabled
    cd HKLM:
    $getllmnrGPO = Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
    $enllmnrGpo = $getllmnrgpo.EnableMulticast

    if ($enllmnrGpo -eq "0" -or $enllmnrReg -eq "0")
    {
        $legProt = "LLMNR (Responder) is disabled GPO = $enllmnrGpo" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient.EnableMulticast"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning LLMNR (Responder) is Enabled Warning" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient.EnableMulticast"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC
    
    #NetBIOS over TCP/IP (NetBT) queries = 0 is disabled
    cd HKLM:
    $getNetBTGPO = Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient" -ErrorAction SilentlyContinue
    $enNetBTGPO = $getNetBTGPO.QueryNetBTFQDN

    if ($enNetBTGPO -eq "0")
    {
        $legProt = "NetBios is disabled the Registry = $enNetBTGPO" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient.QueryNetBTFQDN"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning NetBios is enabled Warning" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient.QueryNetBTFQDN"
        $legValue = $enNetBTGPO
        $legWarn = "Incorrect"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #ipv6 0xff (255)
    cd HKLM:
    $getIpv6 = get-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters" -ErrorAction SilentlyContinue
    $getIpv6Int = $getIpv6.DisabledComponents
    
    if ($getIpv6Int -eq "255")
    {
        $legProt = "IPv6 is disabled the Registry = $getIpv6Int" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters.DisabledComponents"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning IPv6 is enabled Warning" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters.DisabledComponents"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #Report on LMHosts file = 1
    cd HKLM:
    $getLMHostsReg = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters" -ErrorAction SilentlyContinue
    $enLMHostsReg =  $getLMHostsReg.EnableLMHosts
    
    if ($enLMHostsReg -eq "1")
    {
        $legProt = "LMHosts is disabled the Registry = $enLMHostsReg" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.EnableLMHosts"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning Disable LMHosts Warning" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.EnableLMHosts"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #NetBios Node Type set to 2 - Only Reg Setting
    cd HKLM:
    $getNetBtNodeReg = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters" -ErrorAction SilentlyContinue
    $enNetBTReg = $getNetBtNodeReg.NodeType
    
    if ($enNetBTReg -eq "2")
    {
        $legProt = "NetBios Node Type is set to 2 in the Registry" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.NodeType"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning NetBios Node Type is set to $enNetBTReg is incorrect and should be set to 2 Warning"
        $legReg = "HKLM:\System\CurrentControlSet\Services\NetBT\Parameters.NodeType"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #disable netbios
    cd HKLM:
    $getNetBiosInt = Get-ChildItem "HKLM:\System\CurrentControlSet\services\NetBT\Parameters\Interfaces" -ErrorAction SilentlyContinue
    
    foreach ($inter in $getNetBiosInt)
    {
        $getNetBiosReg = Get-ItemProperty $inter.Name
        $NetBiosValue = $getNetBiosReg.NetbiosOptions
        $NetBiosPath = $getNetBiosReg.PSChildName
        $NEtBiosPara = $NetBiosPath,$NetBiosValue
    
        if ($NetBiosValue -eq "0")
        {
            $legProt = "NetBios is set to $NetBiosValue in the Registry" 
            $legReg = "HKLM:\System\CurrentControlSet\services\NetBT\Parameters\Interfaces.$NetBiosPath"
            $trueFalse = "True"
        }
        else
        {
            $legProt = "Warning NetBios is set to $NetBiosValue, its incorrect and should be set to 0 Warning"
            $legReg = "HKLM:\System\CurrentControlSet\services\NetBT\Parameters\Interfaces.$NetBiosPath"
            $trueFalse = "False"
        }
    
        $newObjLegNIC = New-Object psObject
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
        Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
        $fragLegNIC += $newObjLegNIC
    }

    cd HKLM:

    #Peer Net
    $getPeer = Get-ItemProperty  "HKLM:\Software\policies\Microsoft\Peernet" -ErrorAction SilentlyContinue
    $getPeerDis = $getPeer.Disabled
    
    if ($getPeerDis -eq "1")
    {
        $legProt = "Peer to Peer is set to $getPeerDis and disabled" 
        $legReg = "HKLM:\Software\policies\Microsoft\Peernet"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning Peer to Peer is enabled Warning"
        $legReg = "HKLM:\Software\policies\Microsoft\Peernet"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #Enable Font Providers
    cd HKLM:
    $getFont = Get-ItemProperty  "HKLM:\Software\Policies\Microsoft\Windows\System" -ErrorAction SilentlyContinue
    $getFontPr = $getFont.EnableFontProviders
    
    if ( $getFontPr -eq "0")
    {
        $legProt = "Enable Font Providers is set to $getFontPr and is disabled" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\System"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning Enable Font Providers is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\System"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #LLTD
    #https://admx.help/HKLM/Software/Policies/Microsoft/Windows/LLTD
    $getNetLLTDInt = Get-item "HKLM:\Software\Policies\Microsoft\Windows\LLTD" -ErrorAction SilentlyContinue

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
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning EnableLLTDIO is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #EnableRspndr
    if ($getRspndr -eq "0")
    {
        $legProt = "EnableRspndr is set to $getRspndr in the Registry" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning EnableRspndr is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #AllowLLTDIOOnDomain
    if ($getOnDomain -eq "0")
    {
        $legProt = "AllowLLTDIOOnDomain is set to $getOnDomain in the Registry" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning AllowLLTDIOOnDomain is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC
   
    #AllowLLTDIOOnPublicNet
    if ($getPublicNet -eq "0")
    {
        $legProt = "AllowLLTDIOOnPublicNet is set to $getPublicNet in the Registry" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning AllowLLTDIOOnPublicNet is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC
   
    #AllowRspndrOnDomain  
    if ($getRspOnDomain -eq "0")
    {
        $legProt = "AllowRspndrOnDomain is set to $getRspOnDomain in the Registry" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning AllowRspndrOnDomain is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    #AllowRspndrOnPublicNet    
    if ($getRspPublicNet -eq "0")
    {
        $legProt = "AllowRspndrOnPublicNet is set to $getRspPublicNet in the Registry" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning AllowRspndrOnPublicNet is enabled Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC
   
    #ProhibitLLTDIOOnPrivateNe
    if ($getLLnPrivateNet -eq "0")
    {
        $legProt = "ProhibitLLTDIOOnPrivateNet is set to $getLLnPrivateNet in the Registry - When EnableLLTDIO is enabled, 1 is the correct setting" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning ProhibitLLTDIOOnPrivateNet is enabled - When EnableLLTDIO is enabled, 1 is the correct setting Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC
   
    #ProhibitRspndrOnPrivateNet      $getRspPrivateNet = $getNetLLTDInt.GetValue("ProhibitRspndrOnPrivateNet")
    if ($getRspPrivateNet -eq "0")
    {
        $legProt = "ProhibitLLTDIOOnPrivateNet is set to $getRspPrivateNet in the Registry - When EnableLLTDIO is enabled, 1 is the correct setting" 
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning ProhibitLLTDIOOnPrivateNet is enabled - When EnableLLTDIO is enabled, 1 is the correct setting Warning"
        $legReg = "HKLM:\Software\Policies\Microsoft\Windows\LLTD"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC
  
    cd HKLM:
    $getLMHostsReg = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters\" -ErrorAction SilentlyContinue
    $enLMHostsReg =  $getLMHostsReg.DisableIpSourceRouting
    
    if ($enLMHostsReg -eq "2")
    {
        $legProt = "IPv6 source routing must be configured to highest protection is enabled = $enLMHostsReg" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters.DisableIpSourceRouting"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning IPv6 source routing must be configured to highest protection is disabled or not set Warning" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip6\Parameters.DisableIpSourceRouting"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    
    cd HKLM:
    $getLMHostsReg = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters\" -ErrorAction SilentlyContinue
    $enLMHostsReg =  $getLMHostsReg.DisableIpSourceRouting
    
    if ($enLMHostsReg -eq "2")
    {
        $legProt = "IPv4 source routing must be configured to highest protection is enabled = $enLMHostsReg" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters.DisableIpSourceRouting"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning IPv4 source routing must be configured to highest protection is disabled or not set Warning" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters.DisableIpSourceRouting"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    cd HKLM:
    $getLMHostsReg = Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -ErrorAction SilentlyContinue
    $enLMHostsReg =  $getLMHostsReg.EnableICMPRedirect
    
    if ($enLMHostsReg -eq "0")
    {
        $legProt = "Allow ICMP redirects to override OSPF generated routes is disabled = $enLMHostsReg" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters.EnableICMPRedirect"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning Allow ICMP redirects to override OSPF generated routes is enabled Warning" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Tcpip\Parameters.EnableICMPRedirect"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    cd HKLM:
    $getLMHostsReg = Get-ItemProperty "HKLM:\System\CurrentControlSet\Services\Netbt\Parameters\" -ErrorAction SilentlyContinue
    $enLMHostsReg =  $getLMHostsReg.NoNameReleaseOnDemand
    
    if ($enLMHostsReg -eq "1")
    {
        $legProt = "Allow computer to ignore NetBIOS name release requests except from WINS servers is disabled = $enLMHostsReg" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Netbt\Parameters.NoNameReleaseOnDemand"
        $trueFalse = "True"
    }
    else
    {
        $legProt = "Warning Allow computer to ignore NetBIOS name release requests except from WINS servers is enabled Warning" 
        $legReg = "HKLM:\System\CurrentControlSet\Services\Netbt\Parameters.NoNameReleaseOnDemand"
        $trueFalse = "False"
    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

    <#
    WPAD
    Web Proxy Auto Discovery protocol

    The Web Proxy Auto Discovery (WPAD) protocol assists with the automatic detection of proxy settings for web browsers. 
    Unfortunately, WPAD has suffered from a number of severe security vulnerabilities. Organisations that do not rely on 
    the use of the WPAD protocol should disable it. This can be achieved by modifying each workstation's host file at

    %SystemDrive%\Windows\System32\Drivers\etc\hosts to create the following entry: 255.255.255.255 wpad

    #>

    cd C:\Windows\System32
    $getwpad = Get-content "C:\Windows\System32\Drivers\etc\hosts\" -ErrorAction SilentlyContinue
    $getwpadstring = $getwpad | Select-String '255.255.255.255 wpad'

    if ($getwpadstring -eq $null)
    {
        $legProt = "Warning There is no '255.255.255.255 wpad' entry Warning" 
        $legReg = "C:\Windows\System32\Drivers\etc\hosts\"
        $trueFalse = "False"
    }
    else
    {
        $legProt = "There's a 255.255.255.255 wpad entry" 
        $legReg = "C:\Windows\System32\Drivers\etc\hosts\"
        $trueFalse = "True"

    }
    
    $newObjLegNIC = New-Object psObject
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyProtocol -Value $legProt
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name LegacyPath -Value $legReg
    Add-Member -InputObject $newObjLegNIC -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragLegNIC += $newObjLegNIC

################################################
############  SECURITY OPTIONS  ################
################################################ 
    $fragSecOptions=@()
    $secOpTitle1 = "Domain member: Digitally encrypt or sign secure channel data (always)" # = 1
    $getSecOp1 = get-item 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters' -ErrorAction SilentlyContinue
    $getSecOp1res = $getSecOp1.getvalue("RequireSignOrSeal")

    if ($getSecOp1res -eq "1")
    {
        $SecOptName = "$secOpTitle1 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle1 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions 
    
    $secOpTitle2 = "Microsoft network client: Digitally sign communications (always)" # = 1
    $getSecOp2 = get-item 'HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters' -ErrorAction SilentlyContinue
    $getSecOp2res = $getSecOp2.getvalue("RequireSecuritySignature")

    if ($getSecOp2res -eq "1")
    {
        $SecOptName = "$secOpTitle2 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle2 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions 

    $secOpTitle3 = "Microsoft network server: Digitally sign communications (always)" # = 1
    $getSecOp3 = get-item 'HKLM:\System\CurrentControlSet\Services\LanmanServer\Parameters' -ErrorAction SilentlyContinue
    $getSecOp3res = $getSecOp3.getvalue("RequireSecuritySignature")

    if ($getSecOp3res -eq "1")
    {
        $SecOptName = "$secOpTitle3 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle3 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions 

    $secOpTitle4 = "Microsoft network client: Send unencrypted password to connect to third-party SMB servers" #  = 0
    $getSecOp4 = get-item 'HKLM:\System\CurrentControlSet\Services\LanmanWorkstation\Parameters' -ErrorAction SilentlyContinue
    $getSecOp4res = $getSecOp4.getvalue("EnablePlainTextPassword")

    if ($getSecOp4res -eq "0")
    {
        $SecOptName = "$secOpTitle4 - Disabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle4 - Enabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions 

    $secOpTitle5 = "Network security: Do not store LAN Manager hash value on next password change" #  = 1
    $getSecOp5 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\' -ErrorAction SilentlyContinue
    $getSecOp5res = $getSecOp5.getvalue("NoLmHash")

    if ($getSecOp5res -eq "1")
    {
        $SecOptName = "$secOpTitle5 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle5 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions

    $secOpTitle6 = "Network security: LAN Manager authentication level (Send NTLMv2 response only\refuse LM & NTLM)" #  = 5
    $getSecOp6 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\' -ErrorAction SilentlyContinue
    $getSecOp6res = $getSecOp6.getvalue("lmcompatibilitylevel")

    if ($getSecOp6res -eq "5")
    {
        $SecOptName = "$secOpTitle6 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle6 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions

    $secOpTitle7 = "Network Access: Do not allow anonymous enumeration of SAM accounts" #  = 1
    $getSecOp7 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\' -ErrorAction SilentlyContinue
    $getSecOp7res = $getSecOp7.getvalue("restrictanonymoussam")

    if ($getSecOp7res -eq "1")
    {
        $SecOptName = "$secOpTitle7 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle7 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions

    $secOpTitle8 = "Network Access: Do not allow anonymous enumeration of SAM accounts and shares" #  = 1
    $getSecOp8 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\' -ErrorAction SilentlyContinue
    $getSecOp8res = $getSecOp8.getvalue("restrictanonymous")

    if ($getSecOp8res -eq "1")
    {
        $SecOptName = "$secOpTitle8 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle8 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions

    $secOpTitle9 = "Network Access: Let Everyone permissions apply to anonymous users" # = 0
    $getSecOp9 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\' -ErrorAction SilentlyContinue
    $getSecOp9res = $getSecOp9.getvalue("everyoneincludesanonymous")

    if ($getSecOp9res -eq "0")
    {
        $SecOptName = "$secOpTitle9 - Disabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle9 - Enabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions

    $secOpTitle10 = "Network security: LDAP client signing requirements" # = 2 Required
    $getSecOp10 = get-item 'HKLM:\System\CurrentControlSet\Services\NTDS\parameters' -ErrorAction SilentlyContinue
    $getSecOp10res = $getSecOp10.getvalue("ldapserverintegrity")

    if ($getSecOp10res -eq "2")
    {
        $SecOptName = "$secOpTitle10 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle10 - Disabled Warning"
        $trueFalse = "False"
    }
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions


    $secOpTitle15 = "Network security: Minimum session security for NTLM SSP based (including secure RPC) clients" 
    $getSecOp15 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0\' -ErrorAction SilentlyContinue
    $getSecOp15res = $getSecOp15.getvalue("NTLMMinClientSec")

    if ($getSecOp15res -eq "537395200")
    {
        $SecOptName = "$secOpTitle15 - Enabled (Require NTLMv2 session security and Require 128-bit encryption)"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle15 - Disabled set Require NTLMv2 session security and Require 128-bit encryption Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions


    $secOpTitle16 = "Network security: Minimum session security for NTLM SSP based (including secure RPC) servers" 
    $getSecOp16 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\MSV1_0\' -ErrorAction SilentlyContinue
    $getSecOp16res = $getSecOp16.getvalue("NtlmMinServerSec")

    if ($getSecOp16res -eq "537395200")
    {
        $SecOptName = "$secOpTitle16 - Enabled (Require NTLMv2 session security and Require 128-bit encryption)"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle16 - Disabled set Require NTLMv2 session security and Require 128-bit encryption Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions

    <#
    All allows the AES encryption types aes256-cts-hmac-sha1-96 and aes128-cts-hmac-sha1-96, as well as the RC4 encryption type rc4-hmac. 
    AES takes precedence if the server supports AES and RC4 encryption types.

    * Strong or leaving it unset allows only the AES types.
    * Legacy allows only the RC4 type. RC4 is insecure. It should only be needed in very specific circumstances. 

    If possible, reconfigure the server to support AES encryption.
    
    Caution - removing RC4 can break trusts between parent\child where rc4 is configured
    
    Also see https://wiki.samba.org/index.php/Samba_4.6_Features_added/changed#Kerberos_client_encryption_types.
    #>
    
    $secOpTitle12 = "Network security: Configure encryption types allowed for Kerberos" 
    $getSecOp12 = get-item 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Kerberos\Parameters\' -ErrorAction SilentlyContinue
    $getSecOp12res = $getSecOp12.getvalue("supportedencryptiontypes")

    if ($getSecOp12res -eq "2147483640")
    {
        $SecOptName = "$secOpTitle12 - Enabled, (AES128_HMAC_SHA1,AES256_HMAC_SHA1,Future encryption types)"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle12 - Disabled Warning"
        $trueFalse = "False"
    }
    

    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions


    $secOpTitle11 = "Domain member: Require strong (Windows 2000 or later) session key" 
    $getSecOp11 = get-item 'HKLM:\System\CurrentControlSet\Services\Netlogon\Parameters\' -ErrorAction SilentlyContinue
    $getSecOp11res = $getSecOp11.getvalue("RequireStrongKey")

    if ($getSecOp11res -eq "1")
    {
        $SecOptName = "$secOpTitle11 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle11 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions


    $secOpTitle13 = "System cryptography: Force strong key protection for user keys stored on the computer" 
    $getSecOp13 = get-item 'HKLM:\Software\Policies\Microsoft\Cryptography\' -ErrorAction SilentlyContinue
    $getSecOp13res = $getSecOp13.getvalue("ForceKeyProtection")

    if ($getSecOp13res -eq "2")
    {
        $SecOptName = "$secOpTitle13 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle13 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions

    $secOpTitle14 = "System cryptography: Use FIPS compliant algorithms for encryption, hashing, and signing" 
    $getSecOp14 = get-item 'HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy\' -ErrorAction SilentlyContinue
    $getSecOp14res = $getSecOp14.getvalue("Enabled")

    if ($getSecOp14res -eq "1")
    {
        $SecOptName = "$secOpTitle14 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle14 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions


    $secOpTitle17 = "Devices: Prevent users from installing printer drivers"
    $getSecOp17 = get-item 'HKLM:\System\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers\' -ErrorAction SilentlyContinue
    $getSecOp17res = $getSecOp17.getvalue("AddPrinterDrivers")

    if ($getSecOp17res -eq "1")
    {
        $SecOptName = "$secOpTitle17 - Enabled"
        $trueFalse = "True"
    }
    else
    {
        $SecOptName = "Warning $secOpTitle17 - Disabled Warning"
        $trueFalse = "False"
    }
    
    $newObjSecOptions = New-Object psObject
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name SecurityOptions -Value $SecOptName
    Add-Member -InputObject $newObjSecOptions -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragSecOptions +=  $newObjSecOptions


#Network Access: Restrict anonymous Access to Named Pipes and Shares
#Network security: Do not store LAN Manager hash value on next password change
Write-Host " "
Write-Host "Finished Auditing Various Registry Settings" -foregroundColor Green

################################################
############  FIREWALL DETAILS  ################
################################################                
#Firewall Enabled \ Disabled
Write-Host " "
Write-Host "Auditing Firewall Rules" -foregroundColor Green
sleep 5

    $getFWProf = Get-NetFirewallProfile -PolicyStore activestore -ErrorAction SilentlyContinue
    $fragFWProfile=@()
    
    Foreach ($fwRule in $getFWProf)
    {
        $fwProfileNa = $fwRule.Name
        $fwProfileEn = $fwRule.Enabled
        $fwProfileIn = $fwRule.DefaultInboundAction 
        $fwProfileOut = $fwRule.DefaultOutboundAction 
    
        if ($fwProfileIn -eq "allow")
        {
                $newObjFWProf = New-Object psObject
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Name -Value $fwProfileNa
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Enabled -Value $fwProfileEn
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Inbound -Value "Warning $fwProfileIn warning"
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Outbound -Value $fwProfileOut
                $fragFWProfile += $newObjFWProf 
        }
        else
        {
                $newObjFWProf = New-Object psObject
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Name -Value $fwProfileNa
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Enabled -Value $fwProfileEn
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Inbound -Value $fwProfileIn
                Add-Member -InputObject $newObjFWProf  -Type NoteProperty -Name Outbound -Value $fwProfileOut
                $fragFWProfile += $newObjFWProf 
        }
    }

    #Firewall Rules
    $VulnReport = "C:\SecureReport"
    $OutFunc = "firewall" 
                
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $fwpath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"
    $fwpathcsv = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.csv"
    $fwpathxml = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.xml"

    [System.Text.StringBuilder]$fwtxt = New-Object System.Text.StringBuilder

    $getFw = Get-NetFirewallRule  -PolicyStore activestore | 
    Select-Object Displayname,ID,Enabled,Direction,Action,Status  | 
    where {$_.enabled -eq "true" -and $_.Direction -eq "Inbound"} | 
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

    Add-Content -Path $fwpath -Value $fwtxt -ErrorAction SilentlyContinue
    Get-Content $fwpath | Out-File $fwpathcsv -ErrorAction SilentlyContinue
    $fwCSV = Import-Csv $fwpathcsv -Delimiter "," | Export-Clixml $fwpathxml
    $fragFW = Import-Clixml $fwpathxml

Write-Host " "
Write-Host "Finished Auditing Firewall Rules" -foregroundColor Green

################################################
##############  SCHEDULED TasKS  ###############
################################################ 
Write-Host " "
Write-Host "Auditing Scheduled Tasks" -foregroundColor Green
sleep 5

    $getScTask = Get-ScheduledTask 
    $TaskHash=@()
    $SchedTaskPerms=@()

    foreach ($shTask in $getScTask | where {$_.Actions.execute -notlike "*system32*"})
    {
        $taskName = $shTask.TaskName
        $taskPath = $shTask.TaskPath
        $taskArgs = $shTask.Actions.Arguments | Select-Object -First 1
        $taskExe =  $shTask.Actions.execute | Select-Object -First 1
        $taskSet =  $shTask.Settings
        $taskSour = $shTask.Source
        $taskTrig = $shTask.Triggers
        $taskURI =  $shTask.URI
 
        #find file paths to check for permissions restricted to Admins Only
        if ($taskExe -ne $null)
        {
        #find file paths to check for permissions restricted to Admins Only
            if ($taskArgs -match "^[a-zA-Z]:")
            {
                $getAclArgs = Get-Acl $taskArgs 
                $getAclArgs.Path.Replace("Microsoft.PowerShell.Core\FileSystem::","")
                $taskUser = $getAclArgs.Access.IdentityReference
                $taskPerms = $getAclArgs.Access.FileSystemRights
        
                $getTaskCon = Get-Content $taskArgs 
                $syfoldAcl = Get-Acl $taskArgs -ErrorAction SilentlyContinue
            
            if ($syfoldAcl | where {$_.Accesstostring -like "*Users Allow  Write*" `
                -or $_.Accesstostring -like "*Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Users Allow  FullControl*"})
            {
                $taskUSerPers = "Warning User are allowed to WRITE or MODIFY $taskArgs Warning"
            }

            if ($syfoldAcl | where {$_.Accesstostring -like "*Everyone Allow  Write*" `
                -or $_.Accesstostring -like "*Everyone Allow  Modify*" `
                -or $_.Accesstostring -like "*Everyone Allow  FullControl*"})
            {
                $taskUSerPers = "Warning Everyone are allowed to WRITE or MODIFY $taskArgs Warning"
            }

            if ($syfoldAcl | where {$_.Accesstostring -like "*Authenticated Users Allow  Write*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  FullControl*"})
            {
                $taskUSerPers = "Warning Authenticated User are allowed to WRITE or MODIFY $taskArgs Warning"
            }
                $newObjSchedTaskPerms = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjSchedTaskPerms -Type NoteProperty -Name TaskName -Value $taskName
                Add-Member -InputObject $newObjSchedTaskPerms -Type NoteProperty -Name TaskPath -Value $taskArgs
                Add-Member -InputObject $newObjSchedTaskPerms -Type NoteProperty -Name TaskContent -Value $getTaskCon 
                Add-Member -InputObject $newObjSchedTaskPerms -Type NoteProperty -Name TaskPermissions -Value $taskUSerPers
                $SchedTaskPerms += $newObjSchedTaskPerms
            }
        }  
    }

 $getScTask = Get-ScheduledTask 
 $SchedTaskListings=@()

foreach ($shTask in $getScTask | where {$_.Actions.execute -notlike "*system32*" -and $_.Actions.execute -notlike "*MpCmdRun.exe*"})
    {
        $arrayTaskArgs=@()
        $arrayTaskExe=@()
        $TaskHash=@()
        $getTaskCon=@()

        $taskName = $shTask.TaskName
        $taskPath = $shTask.TaskPath
        $taskArgs = $shTask.Actions.Arguments 
        $taskExe =  $shTask.Actions.execute 
        $taskSet =  $shTask.Settings
        $taskSour = $shTask.Source
        $taskTrig = $shTask.Triggers
        $taskURI =  $shTask.URI

        if ($taskExe -ne $null)
        {
            if ($taskArgs -notmatch "^[a-zA-Z]:" -or $taskArgs -match "^[a-zA-Z]:")
            {
                foreach($Args in $taskArgs)
                {
                    $arrayTaskArgs += $Args
                }
                    $arrayjoinArgs = $arrayTaskArgs -join ", "
    
                foreach($Exes in $taskExe)
                {
                    $arrayTaskExe += $Exes
                }
        
                $arrayjoinExe = $arrayTaskExe -join ", "
                $newObjSchedTaskListings = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjSchedTaskListings -Type NoteProperty -Name TaskName -Value $taskName
                Add-Member -InputObject $newObjSchedTaskListings -Type NoteProperty -Name TaskExe -Value $arrayjoinExe
                Add-Member -InputObject $newObjSchedTaskListings -Type NoteProperty -Name TaskArguments -Value $arrayjoinArgs
                #Add-Member -InputObject $newObjSchedTaskListings -Type NoteProperty -Name TaskContent -Value $getTaskCon 
                #Add-Member -InputObject $newObjSchedTaskListings -Type NoteProperty -Name TaskPermissions -Value $taskUserPers
                $SchedTaskListings += $newObjSchedTaskListings
            }
        }
    }

Write-Host " "
Write-Host "Completed Scheduled Tasks" -foregroundColor Green

################################################
##########  Enabled Services  ########
################################################
$gtServices = Get-Service | where {$_.StartType -ne "Disabled"} | Select-Object Displayname,ServiceName,Status,StartType | Sort-Object displayname 
$fragRunServices=@()
foreach ($runService in $gtServices)
{
    $runSvcDisName = $runService.displayName
    $runSvcName = $runService.ServiceName
    $runSvcStatus = $runService.Status
    $runSvcStart = $runService.StartType


    $newObjRunningSvc= New-Object -TypeName PSObject
    Add-Member -InputObject $newObjRunningSvc -Type NoteProperty -Name DisplayName -Value $runSvcDisName
    Add-Member -InputObject $newObjRunningSvc -Type NoteProperty -Name ServiceName -Value $runSvcName
    Add-Member -InputObject $newObjRunningSvc -Type NoteProperty -Name Status -Value $runSvcStatus
    Add-Member -InputObject $newObjRunningSvc -Type NoteProperty -Name StartType -Value $runSvcStart
    $fragRunServices += $newObjRunningSvc
}


################################################
##########  FILES, FOLDERS, REG AUDITS  ########
################################################

#START OF IF
if ($folders -eq "y")
{

################################################
############  WRITEABLE FILES  #################
################################################
Write-Host " "
Write-Host "Now progress will slow whilst the script enumerates all folders and their permissions, be patient" -foregroundColor Green
Write-Host " "
Write-Host "Searching for Writeable Files Vulnerabilities" -foregroundColor Green
sleep 7

    $VulnReport = "C:\SecureReport"
    $OutFunc = "WriteableFiles"  

    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $hpath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"

    $drv = (psdrive | where {$_.root -match "^[a-zA-Z]:"})
    $drvRoot = $drv.root

    foreach ($rt in $drvRoot)
    {
        $hfiles =  Get-ChildItem $rt -ErrorAction SilentlyContinue |
        where {$_.Name -eq "PerfLogs" -or ` 
        $_.Name -eq "ProgramData" -or `
        $_.Name -eq "Program Files" -or `
        $_.Name -eq "Program Files (x86)" -or `
        $_.Name -eq "Windows"}

        $filehash = @()
        foreach ($hfile in $hfiles.fullname)
        {
            $subfl = Get-ChildItem -Path $hfile -force -Recurse -Include *.exe, *.dll -ErrorAction SilentlyContinue | 
            Where {$_.FullName -notMatch "winsxs" -and $_.FullName -notmatch "LCU"} 
            $filehash+=$subfl
            $filehash 
        }
    
        foreach ($cfile in $filehash.fullname)
        {
            $cfileAcl = Get-Acl $cfile -ErrorAction SilentlyContinue

            if ($cfileAcl | 
            where {$_.Accesstostring -like "*Users Allow  Write*" `
                -or $_.Accesstostring -like "*Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Users Allow  FullControl*"})
            
            {
                $cfile | Out-File $hpath -Append
                #Write-Host $cfile -ForegroundColor Yellow
            }

            if ($cfileAcl | where {$_.Accesstostring -like "*Everyone Allow  Write*" `
                -or $_.Accesstostring -like "*Everyone Allow  Modify*" `
                -or $_.Accesstostring -like "*Everyone Allow  FullControl*"})
            {
                $cfile | Out-File $hpath -Append
                #Write-Host $cfile -ForegroundColor Yellow
            }
    
            if ($cfileAcl | where {$_.Accesstostring -like "*Authenticated Users Allow  Write*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  FullControl*"})
            {
                $cfile | Out-File $hpath -Append
                #Write-Host $cfile -ForegroundColor Yellow
            }
        }
    
        $wFileDetails = Get-Content  $hpath -ErrorAction SilentlyContinue #|  where {$_ -ne ""} |select -skip 3
        $fragwFile =@()
    
        foreach ($wFileItems in $wFileDetails)
        {
            $newObjwFile = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjwFile -Type NoteProperty -Name WriteableFiles -Value "Warning $($wFileItems) warning"
            $fragwFile += $newObjwFile
            #Write-Host $wFileItems -ForegroundColor Yellow
        }
       
    }

Write-Host " "
Write-Host "Finished Searching for Writeable Files Vulnerabilities" -foregroundColor Green

################################################
#########  WRITEABLE REGISTRY HIVES  ###########
################################################
Write-Host " "
Write-Host "Now progress will slow whilst the script enumerates all Registry Hives and permissions, be patient" -foregroundColor Green
Write-Host " "
Write-Host "Searching for Writeable Registry Hive Vulnerabilities" -foregroundColor Green
sleep 7

    $VulnReport = "C:\SecureReport"
    $OutFunc = "WriteableReg"  

    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $rpath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"

    #Registry Permissions
    $HKLMSvc = 'HKLM:\System\CurrentControlSet\Services'
    $HKLMSoft = 'HKLM:\Software'
    $HKLMCheck = $HKLMSoft,$HKLMSvc

    Foreach ($key in $HKLMCheck) 
    {
        #Get a list of key names and make a variable
        cd hklm:
        $SvcPath = Get-childItem $key -Recurse -Depth 1 -ErrorAction SilentlyContinue | where {$_.Name -notmatch "Classes"}
        #Update HKEY_Local.... to HKLM:
        $RegList = $SvcPath.name.replace("HKEY_LOCAL_MACHINE","HKLM:")
    
        Foreach ($regPath in $RegList)
        {
            $acl = Get-Acl $regPath -ErrorAction SilentlyContinue
            $acc = $acl.AccessToString
            #Write-Output $regPath 
            #Write-Host $regPath  -ForegroundColor DarkCyan

            foreach ($ac in $acc)
                {
                    if ($ac | Select-String -SimpleMatch "BUILTIN\Users Allow  FullControl")
                    {
                        $regPath | Out-File $rpath -Append
                        #Write-Host $ac -ForegroundColor DarkCyan
                    } 

                    if ($ac | Select-String -SimpleMatch "NT AUTHORITY\Authenticated Users Allow  FullControl")
                    {
                        $regPath | Out-File $rpath -Append
                        #Write-Host $ac -ForegroundColor DarkCyan
                    }

                    if ($ac | Select-String -SimpleMatch "Everyone Allow  FullControl")
                    {
                        $regPath | Out-File $rpath -Append
                        #Write-Host $ac -ForegroundColor DarkCyan
                    }
                }
        }
        
        $regDetails = Get-Content $rpath -ErrorAction SilentlyContinue    #|  where {$_ -ne ""} |select -skip 3
        $fragReg =@()
    
        foreach ($regItems in $regDetails)
        {
            #Write-Host $regItems -ForegroundColor DarkCyan
            $newObjReg = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjReg -Type NoteProperty -Name RegWeakness -Value "Warning $($regItems) warning"
            $fragReg += $newObjReg    
        }
   }

Write-Host " "
Write-Host "Finished Searching for Writeable Registry Hive Vulnerabilities" -foregroundColor Green

################################################
#############  WRITEABLE FOLDERS  ##############
############  NON System FOLDERS  ##############
################################################
Write-Host " "
Write-Host "Now progress will slow whilst the script enumerates all folders and their permissions, be patient" -foregroundColor Green
Write-Host " "
Write-Host "Searching for Writeable Folder Vulnerabilities" -foregroundColor Green
sleep 7

    $VulnReport = "C:\SecureReport"
    $OutFunc = "WriteableFolders"  

    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }
    
    $fpath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"
    #Additional Folders off the root of C: that are not system
    
    $drv = (psdrive | where {$_.root -match "^[a-zA-Z]:"}) |  where {$_.displayroot -notlike "*\\*"}
    $drvRoot = $drv.root 
    $getRoot = Get-Item $drvRoot

    foreach ($rt in $drvRoot)
    {
        $hfolders =  Get-ChildItem $rt -ErrorAction SilentlyContinue  | 
        where {$_.Name -ne "PerfLogs" -and ` 
        $_.Name -ne "Program Files" -and `
        $_.Name -ne "Program Files (x86)" -and `
        $_.Name -ne "Users" -and `
        $_.Name -ne "Windows"}
    
        $foldhash = @()
        foreach ($hfold in $hfolders.fullname)
        {
            $subfl = Get-ChildItem -Path $hfold -Depth $depth -Directory -Recurse -Force -ErrorAction SilentlyContinue
            $foldhash+=$hfolders
            $foldhash+=$subfl
            $foldhash+=$getRoot
            #Write-Host $hfold -ForegroundColor Gray   
        }
    
        foreach ($cfold in $foldhash.fullname)
        {
        #Write-Host $cfold -ForegroundColor green
        $cfoldAcl = Get-Acl $cfold -ErrorAction SilentlyContinue

            if ($cfoldAcl | where {$_.Accesstostring -like "*Users Allow  Write*" `
                -or $_.Accesstostring -like "*Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Users Allow  FullControl*"})
            {
                $cfold | Out-File $fpath -Append
                #Write-Host $cfold -ForegroundColor red
            }

            if ($cfoldAcl | where {$_.Accesstostring -like "*Everyone Allow  Write*" `
                -or $_.Accesstostring -like "*Everyone Allow  Modify*" `
                -or $_.Accesstostring -like "*Everyone Allow  FullControl*"})
            {
                $cfold | Out-File $fpath -Append
                #Write-Host $cfold -ForegroundColor red
            }

            if ($cfoldAcl | where {$_.Accesstostring -like "*Authenticated Users Allow  Write*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  FullControl*"})
            {
                $cfold | Out-File $fpath -Append
                #Write-Host $cfold -ForegroundColor red
            } 
        }
        
        get-content $fpath | Sort-Object -Unique | set-Content $fpath -ErrorAction SilentlyContinue

        #Get content and remove the first 3 lines
        $wFolderDetails = Get-Content  $fpath  -ErrorAction SilentlyContinue   #|  where {$_ -ne ""} |select -skip 3
        $fragwFold =@()
    
        foreach ($wFoldItems in $wFolderDetails)
        {
            $newObjwFold = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjwFold -Type NoteProperty -Name FolderWeakness -Value $wFoldItems
            $fragwFold += $newObjwFold
            #Write-Host $wFoldItems -ForegroundColor Gray
        }       
    }
     
Write-Host " "
Write-Host "Finisehd Searching for Writeable Folder Vulnerabilities" -foregroundColor Green
 
################################################
#############  WRITEABLE FOLDERS  ##############
###############  System FOLDERS  ###############
################################################
Write-Host " "
Write-Host "Now progress will slow whilst the script enumerates all folders and their permissions, be patient" -foregroundColor Green
Write-Host " "
Write-Host "Searching for Writeable System Folder Vulnerabilities" -foregroundColor Green
sleep 7
    
    $VulnReport = "C:\SecureReport"
    $OutFunc = "SystemFolders"  

    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $sysPath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"

    $drv = (psdrive | where {$_.root -match "^[a-zA-Z]:"}) |  where {$_.displayroot -notlike "*\\*"}
    $drvRoot = $drv.root
    $getRoot = Get-Item $drvRoot

    foreach ($rt in $drvRoot)
    {
        $sysfolders =  Get-ChildItem $rt -ErrorAction SilentlyContinue | 
        where {$_.Name -eq "PerfLogs" -or ` 
        $_.Name -eq "ProgramData" -or `
        $_.Name -eq "Program Files" -or `
        $_.Name -eq "Program Files (x86)" -or `
        $_.Name -eq "Windows"}
        $sysfoldhash = @()
        $sysfolders  #+=$getRoot
    
        foreach ($sysfold in $sysfolders.fullname)
        {
            #Write-Host $sysfold
            $subsysfl = Get-ChildItem -Path $sysfold -Depth $depth -Directory -Recurse -Force -ErrorAction SilentlyContinue | 
            Where {$_.FullName -notMatch "winsxs" -and $_.FullName -notmatch "LCU"}

            $sysfoldhash+=$subsysfl
            #Write-Host $subsysfl -ForegroundColor White
        }
    
        foreach ($syfold in $sysfoldhash.fullname)
        {
            $syfoldAcl = Get-Acl $syfold -ErrorAction SilentlyContinue
            #Write-Host $sysfoldhash -ForegroundColor green
            if ($syfoldAcl | where {$_.Accesstostring -like "*Users Allow  Write*" `
                -or $_.Accesstostring -like "*Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Users Allow  FullControl*"})
            {
                $syfold | Out-File $sysPath -Append
                #Write-Host $syfold -ForegroundColor red
            }

            if ($syfoldAcl | where {$_.Accesstostring -like "*Everyone Allow  Write*" `
                -or $_.Accesstostring -like "*Everyone Allow  Modify*" `
                -or $_.Accesstostring -like "*Everyone Allow  FullControl*"})
            {
                $syfold | Out-File $sysPath -Append
                #Write-Host $syfold -ForegroundColor red
            }

            if ($syfoldAcl | where {$_.Accesstostring -like "*Authenticated Users Allow  Write*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  Modify*" `
                -or $_.Accesstostring -like "*Authenticated Users Allow  FullControl*"})

            {
                $syfold | Out-File $sysPath -Append
                #Write-Host $syfold -ForegroundColor red
            }
        }
    
        get-content $sysPath | Sort-Object -Unique | set-Content $sysPath 

        #Get content and remove the first 3 lines
        $sysFolderDetails = Get-Content $sysPath -ErrorAction SilentlyContinue #|  where {$_ -ne ""} |select -skip 3
        $fragsysFold =@()
    
        foreach ($sysFoldItems in $sysFolderDetails)
        {
            $newObjsysFold = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjsysFold -Type NoteProperty -Name FolderWeakness -Value $sysFoldItems
            $fragsysFold += $newObjsysFold
            #Write-Host $sysFoldItems -ForegroundColor White
        }
    }
 
Write-Host " "
Write-Host "Finished Searching for Writeable System Folder Vulnerabilities" -foregroundColor Green

################################################
#################  CREATEFILES  ################
###############  System FOLDERS  ###############
################################################
Write-Host " "
Write-Host "Now progress will slow whilst the script enumerates all folders and their permissions, be patient" -foregroundColor Green
Write-Host " "
Write-Host "Searching for CreateFile Permissions Vulnerabilities" -foregroundColor Green
sleep 7
  
    $VulnReport = "C:\SecureReport"
    $OutFunc = "CreateSystemFolders"  

    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }
    
    $createSysPath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"

    $drv = (psdrive | where {$_.root -match "^[a-zA-Z]:"}) | where {$_.displayroot -notlike "*\\*"}
    $drvRoot = $drv.root
    $getRoot = Get-Item $drvRoot

    foreach ($rt in $drvRoot)
    {   
        $createSysfolders =  Get-ChildItem $rt  -ErrorAction SilentlyContinue | 
        where {$_.Name -eq "PerfLogs" -or ` 
        $_.Name -eq "ProgramData" -or `
        $_.Name -eq "Program Files" -or `
        $_.Name -eq "Program Files (x86)" -or `
        $_.Name -eq "Windows"}
        $createSysfoldhash=@()
  
        foreach ($createSysfold in $createSysfolders.fullname)
        {
            $createSubsysfl = Get-ChildItem -Path $createSysfold -Depth $depth -Directory -Recurse -Force  -ErrorAction SilentlyContinue | 
            Where {$_.FullName -notMatch "winsxs" -and $_.FullName -notmatch "LCU"}
            
            $createSysfoldhash+=$createSubsysfl
            #Write-Host $createSubsysfl -ForegroundColor Green
        }

        foreach ($createSyfold in $createSysfoldhash.fullname)
        {
            $createSyfoldAcl = Get-Acl $createSyfold -ErrorAction SilentlyContinue
            #Write-Host $createSyfold -ForegroundColor green

            if ($createSyfoldAcl | where {$_.Accesstostring -like "*Users Allow  CreateFiles*"})
            {
                $createSyfold | Out-File $createSysPath -Append
                #Write-Host $createSyfold -ForegroundColor red
            }

            if ($createSyfoldAcl | where {$_.Accesstostring -like "*Everyone Allow  CreateFiles*"})
            {
                $createSyfold | Out-File $createSysPath -Append
                #Write-Host $createSyfold -ForegroundColor red
            }

            if ($createSyfoldAcl | where {$_.Accesstostring -like "*Authenticated Users Allow  CreateFiles*"})
            {
                $createSyfold | Out-File $createSysPath -Append
                #Write-Host $createSyfold -ForegroundColor red
            }
         }

            get-content $createSysPath | Sort-Object -Unique | set-Content $createSysPath 

            #Get content and remove the first 3 lines
            $createSysFolderDetails = Get-Content $createSysPath -ErrorAction SilentlyContinue #|  where {$_ -ne ""} |select -skip 3
            $fragcreateSysFold=@()
        
            foreach ($createSysFoldItems in $createSysFolderDetails)
            {
                $newObjcreateSysFold = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjcreateSysFold -Type NoteProperty -Name CreateFiles -Value $createSysFoldItems
                $fragcreateSysFold += $newObjcreateSysFold
                #Write-Host $createSysFoldItems -ForegroundColor green
            }
        }

        
Write-Host " "
Write-Host "Finised Searching for CreateFile Permissions Vulnerabilities" -foregroundColor Green

################################################
###############  DLL HIJACKING  ################
################################################
#All dlls' that are NOT signed and user permissions allow write  
    $VulnReport = "C:\SecureReport"
    $OutFunc = "DLLNotSigned"  

    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }
    
    $dllLogPath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.log"
    $dllLogPathtxt = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.txt"

    $drv = (psdrive | where {$_.root -match "^[a-zA-Z]:"}) |  where {$_.displayroot -notlike "*\\*"}
    $drvRoot = $drv.root 
    $getRoot = Get-Item $drvRoot

    foreach ($rt in $drvRoot)
    {
        $dllFolders =  Get-ChildItem $rt -ErrorAction SilentlyContinue  |
        where {$_.fullName -match "Program Files" -or `
        $_.fullName -match "(x86)" -or `
        $_.fullName -match "Windows"}
      
        foreach ($dllFold in $dllFolders.fullname)
        {$dllSigned =  Get-ChildItem -Path $dllFold -Recurse -depth $depth -force | 
              where {$_.FullName -notMatch "winsxs" -and $_.FullName -notmatch "LCU"} |
              where {$_.Extension -eq ".dll"} | get-authenticodesignature | 
              where {$_.status -ne "valid"} | get-acl | 
              where {$_.Accesstostring -like "*Users Allow  Write*" `
              -or $_.Accesstostring -like "*Users Allow  Modify*" `
              -or $_.Accesstostring -like "*Users Allow  FullControl*" `
              -or $_.Accesstostring -like "*Everyone Allow  Write*" `
              -or $_.Accesstostring -like "*Everyone Allow  Modify*" `
              -or $_.Accesstostring -like "*Everyone Allow  FullControl*" `
              -or $_.Accesstostring -like "*Authenticated Users Allow  Write*" `
              -or $_.Accesstostring -like "*Authenticated Users Allow  Modify*" `
              -or $_.Accesstostring -like "*Authenticated Users Allow  FullControl*"} 
             #write-host $dllSigned
             $dllSigned.path | out-file $dllLogPath -Append
         }
    }

    Get-Content $dllLogPath  | 
    foreach {$_ -replace "Microsoft.PowerShell.Core",""} |
    foreach {$_ -replace 'FileSystem::',""} |
    foreach {$_.substring(1)} |
    Set-Content $dllLogPathtxt -Force

    $fragDllNotSigned=@()
    $getDllPath = get-content $dllLogPathtxt

    foreach ($dllNotSigned in $getDllPath)
    {
        $newObjDllNotSigned = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjDllNotSigned -Type NoteProperty -Name CreateFiles -Value "Warning $($dllNotSigned) warning"
        $fragDllNotSigned += $newObjDllNotSigned
    }  

###########################################################################################################################
###########################################################################################################################
###########################################################################################################################

#END OF IF
}

################################################
########  AUTHENTICODE SIGNATURE  ##############
################################################
#Warning Very long running process - enable only when required
#START OF IF
if ($authenticode -eq "y")
{

Write-Host " "
Write-Host "Searching for authenticode signature hashmismatch" -foregroundColor Green

    $fragAuthCodeSig=@()
    $newObjAuthSig=@()

    $drv = (psdrive | where {$_.root -match "^[a-zA-Z]:"}) | where {$_.displayroot -notlike "*\\*"}
    $drvRoot = $drv.root
 
    foreach ($rt in $drvRoot)
        {
            $getAuthfiles = Get-ChildItem -Path $rt -Recurse -depth $depth -force | 
            where {$_.FullName -notMatch "winsxs" -and $_.FullName -notmatch "LCU"} |
            where { ! $_.PSIsContainer `
            -and $_.extension -ne ".log" `
            -and $_.extension -ne ".hve" `
            -and $_.extension -ne ".txt" `
            -and $_.extension -ne ".evtx" `
            -and $_.extension -ne ".elt"}

            foreach($file in $getAuthfiles)
            {
                $getAuthCodeSig = get-authenticodesignature -FilePath $file.FullName | where {$_.Status -eq "hashmismatch"
            }

        if ($getAuthCodeSig.path -eq $null){}
        else 
            {
                $authPath = $getAuthCodeSig.path
                $authStatus = $getAuthCodeSig.status

                $newObjAuthSig = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAuthSig -Type NoteProperty -Name PathAuthCodeSig -Value "Warning $($authPath) warning"
                Add-Member -InputObject $newObjAuthSig -Type NoteProperty -Name StatusAuthCodeSig -Value "Warning $($authStatus) warning"
                $fragAuthCodeSig += $newObjAuthSig
            }
        }
    }

Write-Host " "
Write-Host "Completed searching for authenticode signature hashmismatch" -foregroundColor Green
#END OF IF
}

################################################
##########  CERTIFICATE DETAILS  ###############
################################################
    $getCert = (Get-ChildItem Cert:\LocalMachine).Name
    $fragCertificates=@()
    $certIssuer=@()
    $dateToday = get-date
    foreach($certItem in $getCert)
    {
    $getCertItems = (Get-ChildItem "Cert:\LocalMachine\$($certItem)" )  #| where {$_.Subject -notlike "*microsoft*"}) 

        foreach ($allCertInfo in $getCertItems)
        {
            $certThumb = $allCertInfo.Thumbprint
            $certPath = ($allCertInfo.PSPath).replace("Microsoft.PowerShell.Security\Certificate::","").replace("$certThumb","")
            $certIssuer = $allCertInfo.Issuer
            $count = ($certIssuer.split(",")).count
            $certDns = $allCertInfo.DnsNameList
            $certSub = $allCertInfo.Subject
            $certExpire = $allCertInfo.NotAfter
            $certName = $allCertInfo.FriendlyName
            $certKey = $allCertInfo.HasPrivateKey
            $certkeysize = $allCertInfo.PublicKey.Key.KeySize
            $certSigAlgor =  $allCertInfo.SignatureAlgorithm.FriendlyName

            $dateDiff = (get-date $certExpire) -lt (get-date $dateToday)
            $dateShort = $certExpire.ToShortDateString()

            #Added for a naughty list of CN=, Domain Names or words
            $newObjCertificates = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertIssuer -Value $certIssuer
            Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertSha1 -Value "$certSigAlgor" -force
            Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertExpired -Value $dateShort
            Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertSelfSigned -Value False
            Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertPrivateKey -Value False


            if 
            (
                $certDns -like "*somexxx*" `
                -or $certDns -like "*thingxxx*" 
            )
            {
                Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertDNS -Value "Warning $($certDns) warning" -Force             
            }
            if
            (
                $certIssuer -like "*somexxx*" `
                -or $certIssuer -like "*thingxxx*" 
             )
            {
                Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertIssuer -Value "Warning $($certIssuer) warning" -Force
            }

            if ($certSigAlgor -match "sha1")
            {
                Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertSha1 -Value "Warning $($certSigAlgor) Warning" -force
            }

            if ($dateDiff -eq "false")
            {
                Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertExpired -Value "Expired - $($dateShort) expired" -Force
            }

            if ($certSub -eq $certIssuer -and $count -eq 1)
            {
                Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertSelfSigned -Value "SelfSigned - True SelfSigned" -force
            }

            if ($certKey -eq "true")
            {
                Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertPrivateKey -Value "privateKey - True privatekey" -force
            }
                                   
             #Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertIssuer -Value $certIssuer
             #Add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertExpired -Value $certExpire
             #add-Member -InputObject $newObjCertificates -Type NoteProperty -Name CertDNS -Value $certDns
             $fragCertificates += $newObjCertificates
        }
    }

################################################
###############  CIPHER SUITS  #################
################################################

$gtCipherSuit = Get-TlsCipherSuite
$fragCipherSuit=@()
foreach($CipherItem in $gtCipherSuit)
    {
        $cipherName = $CipherItem.name
        $cipherCert = $CipherItem.certificate
        $cipherhash = $CipherItem.hash
        $cipherExch = $CipherItem.Exchange
        $trueFalse = "True"   

        if ($cipherhash -match "sha1")
            {
            $cipherhash = "Warning $cipherhash is vulnerable to MitM Warning"
            $cipherName = "Warning $cipherName Warning"
            $trueFalse = "False"  
            }
                    
        $newObjCipherSuite = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjCipherSuite -Type NoteProperty -Name CipherName -Value $cipherName
        Add-Member -InputObject $newObjCipherSuite -Type NoteProperty -Name CipherCert -Value $cipherCert
        Add-Member -InputObject $newObjCipherSuite -Type NoteProperty -Name CipherHash -Value $cipherhash
        Add-Member -InputObject $newObjCipherSuite -Type NoteProperty -Name CipherExchange -Value $cipherExch
        Add-Member -InputObject $newObjCipherSuite -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
        
        $fragCipherSuit += $newObjCipherSuite 
        
    }

################################################
##############  SHARES AND PERMS  ##############
################################################ 

Write-Host " "
Write-Host "Auditing Shares and permissions" -foregroundColor Green
sleep 3

    $getShr = Get-SmbShare #| where {$_.name -ne "IPC$"}
    $Permarray=@()
    $fragShare=@()

    foreach($shr in $getShr)
    {
        $Permarray=@()
        $shrName = $Shr.name
        $shrPath = $Shr.path
        $shrDes = $Shr.description

        $getShrPerms = Get-FileShareAccessControlEntry -Name $shr.Name -ErrorAction SilentlyContinue
    
        foreach($perms in $getShrPerms)
        {
            $Permarray += $perms.AccountName
        }
    
            $arrayjoin = $Permarray -join ",  "
    
            $newObjShare = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjShare -Type NoteProperty -Name Name -Value $shrName
            Add-Member -InputObject $newObjShare -Type NoteProperty -Name Path -Value $shrPath
            Add-Member -InputObject $newObjShare -Type NoteProperty -Name Permissions -Value $arrayjoin
            $fragShare += $newObjShare
        }

Write-Host " "
Write-Host "Finised Auditing Shares and permissions" -foregroundColor Green

################################################
############  EMBEDDED PASSWordS  ##############
################################################  

Write-Host " "
Write-Host "Now progress will slow whilst the script enumerates all files for passwords, be patient" -foregroundColor Green
Write-Host " "
Write-Host "Searching for Embedded Password in Files" -foregroundColor Green
sleep 7
  
#Passwords in Processes
    #$getPSPass = gwmi win32_process -ErrorAction SilentlyContinue | 

    $getPSPass = Get-CimInstance win32_process -ErrorAction SilentlyContinue |
    Select-Object Caption, Description,CommandLine | 
    where {$_.commandline -like "*pass*" -or $_.commandline -like "*credential*" -or $_.commandline -like "*username*" }

    $fragPSPass=@()
    foreach ($PStems in $getPSPass)
    {
        $PSCap = $PStems.Caption
        $PSDes = $PStems.Description
        $PSCom = $PStems.CommandLine

        $newObjPSPass = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjPSPass -Type NoteProperty -Name ProcessCaption -Value "Warning $($PSCap) - warning"
        Add-Member -InputObject $newObjPSPass -Type NoteProperty -Name ProcessDescription -Value "Warning $($PSDes) - warning"
        Add-Member -InputObject $newObjPSPass -Type NoteProperty -Name ProcessCommandLine -Value "Warning $($PSCom) - warning"
        $fragPSPass += $newObjPSPass
    }

#passwords embedded in files
#findstr /si password *.txt - alt
if ($embeddedpw -eq "y")
    {
    $drv = (psdrive | where {$_.root -match "^[a-zA-Z]:"}) | where {$_.displayroot -notlike "*\\*"}
    $drvRoot = $drv.root
    $fragFilePass=@()
    $depthExtra = [int]$depth + 2
    foreach ($rt in $drvRoot)
        {
            $getUserFolder = Get-ChildItem -Path $rt -Recurse -Depth $depthExtra -Force -ErrorAction SilentlyContinue |
            where {$_.FullName -notmatch "WinSXS" `
            -and $_.FullName -notmatch "Packages" `
            -and $_.FullName -notmatch "Containers\BaseImages" `
            -and $_.FullName -notmatch  "MicrosoftOffice" `
            -and $_.FullName -notmatch "AppRepository" `
            -and $_.FullName -notmatch "IdentityCRL" `
            -and $_.FullName -notmatch "UEV" `
            -and $_.FullName -notlike "MicrosoftOffice201" `
            -and $_.FullName -notmatch "DriverStore" `
            -and $_.FullName -notmatch "spool" `
            -and $_.FullName -notmatch "icsxm"  } |
            where {$_.Extension -eq ".txt"`
            -or $_.Extension -eq ".ini" `
            -or $_.Extension -eq ".xml"}  #xml increase output, breaks report

            foreach ($PassFile in $getUserFolder)
            {
                #Write-Host $PassFile.fullname -ForegroundColor Yellow
                $SelectPassword  = Get-Content $PassFile.FullName |  Select-String -Pattern password, credential
 
            if ($SelectPassword -like "*password*")
            {
                $newObjFilePass = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjFilePass -Type NoteProperty -Name FilesContainingPassword -Value  $PassFile.FullName 
                $fragFilePass += $newObjFilePass
            }
        }
    }
    }

Write-Host " "
Write-Host "Finished Searching for Embedded Password in Files" -foregroundColor Green

################################################
#####  SEARCHING FOR REGISTRY PASSWordS   ######
################################################
Write-Host " "
Write-Host "Auditing Registry Passwords" -foregroundColor Green
sleep 5

    $VulnReport = "C:\SecureReport"
    $OutFunc = "RegPasswords" 
                
    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

    $secEditPath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.txt"

    #Enter list of Words to search
    $regSearchWords = "password", "passwd","DefaultPassword"

    foreach ($regSearchItems in $regSearchWords){
        #swapped to native tool, Powershell is too slow
        reg query HKLM\Software /f $regSearchItems /t REG_SZ /s >> $secEditPath
        reg query HKCU\Software /f $regSearchItems /t REG_SZ /s >> $secEditPath
        reg query HKLM\SYSTEM\CurrentControlSet\Services /f $regSearchItems /t REG_SZ /s >> $secEditPath
}

$getRegPassCon = (get-content $secEditPath | 
where {$_ -notmatch "classes" -and $_ -notmatch "ClickToRun" -and $_ -notmatch "}" -and $_ -notmatch "PolicyManager" -and $_ -notmatch "Internet" -and $_ -notmatch "WSMAN" -and $_ -notmatch "PasswordEnrollmentManager"} |Select-String -Pattern "hkey_", "hkcu_")# -and $_ -notmatch "microsoft" -and $_ -notmatch "default"} | 


$fragRegPasswords=@()
foreach ($getRegPassItem in $getRegPassCon)
{
    if ($getRegPassItem -match "HKEY_LOCAL_MACHINE"){$getRegPassItem = $getRegPassItem.tostring().replace("HKEY_LOCAL_MACHINE","HKLM:")}
    if ($getRegPassItem -match "HKEY_CURRENT_USER"){$getRegPassItem = $getRegPassItem.tostring().replace("HKEY_CURRENT_USER","HKCU:")}

    $gtRegPassItem = (Get-Item $getRegPassItem)
    $gtItemPasskey = (Get-Item $getRegPassItem).property | where {$_ -match "passd" -or $_ -match "password" -and $_ -notmatch "PasswordExpiryWarning"}
    $gtItemPassValue = (Get-ItemProperty $getRegPassItem).$gtItemPasskey

    $newObjRegPasswords = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjRegPasswords -Type NoteProperty -Name RegistryPath -Value "Warning $($getRegPassItem) warning"
    Add-Member -InputObject $newObjRegPasswords -Type NoteProperty -Name RegistryValue -Value "Warning $($gtItemPasskey) warning"
    Add-Member -InputObject $newObjRegPasswords -Type NoteProperty -Name RegistryPassword -Value "Warning $($gtItemPassValue) warning"
    $fragRegPasswords += $newObjRegPasswords          
} 

Write-Host " "
Write-Host "Finished Searching for Embedded Password in the Registry" -foregroundColor Green

################################################
########  POWERSHELL PASSWORD SEARCH  ##########
################################################
#$gtPSPawd = get-content $env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt | where {$_ -match "pass" -or $_ -match "user" }

$gtCachedProfiles = (Get-ChildItem c:\users\ -Force -Directory).fullname
$fragPSPasswords=@()
foreach ($CachedProfiles in $gtCachedProfiles)
    {
    $tpHistory = test-path "$($CachedProfiles)\Appdata\roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
    if ($tpHistory -eq $true)
        {
            [array]$gtPSPassword = get-content "$($CachedProfiles)\Appdata\roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" | where {$_ -match "pass" -or $_ -match "user" }
            foreach ($psHistory in $gtPSPassword)
            {
                $gtPSPassword
                $newObjPSPasswords = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjPSPasswords -Type NoteProperty -Name PSHistoryPath -Value $CachedProfiles
                Add-Member -InputObject $newObjPSPasswords -Type NoteProperty -Name PSWordsOfInterest -Value "Warning $($psHistory) warning"

                $fragPSPasswords += $newObjPSPasswords
            }
        }
    else {}
    }


################################################
###############  APPLOCKER AUDIT  ##############
################################################
$fragApplockerSvc=@()
$AppLockerSvc = get-service appidsvc
$newObjApplockerSvc = New-Object -TypeName PSObject
Add-Member -InputObject $newObjApplockerSvc -Type NoteProperty -Name Path $AppLockerSvc.DisplayName
Add-Member -InputObject $newObjApplockerSvc -Type NoteProperty -Name PubExcep $AppLockerSvc.Name
Add-Member -InputObject $newObjApplockerSvc -Type NoteProperty -Name PubPathExcep $AppLockerSvc.StartType
$fragApplockerSvc += $newObjApplockerSvc

$gtAppLRuleCollection = Get-ApplockerPolicy -Effective | select -ExpandProperty RuleCollections 
$gtAppLCollectionTypes = Get-ApplockerPolicy -Effective | select -ExpandProperty RuleCollectionTypes


#Enforcment mode
$fragApplockerEnforcement=@()
$gtApplockerEnforce = (Get-AppLockerPolicy -Effective).rulecollections | Select-Object -Property RuleCollectionType,EnforcementMode,ServiceEnforcementMode,SystemAppAllowMode,Count 

foreach($appEnforcement in $gtApplockerEnforce)
{

$applockerEnforceColl = $appEnforcement.RuleCollectionType
$applockerEnforceMode = $appEnforcement.EnforcementMode
$applockerEnforceSvc = $appEnforcement.ServiceEnforcementMode
$applockerEnforceSys = $appEnforcement.SystemAppAllowMode
$applockerEnforceCount = $appEnforcement.Count 

    $newObjApplockerEnforce= New-Object -TypeName PSObject
    Add-Member -InputObject $newObjApplockerEnforce -Type NoteProperty -Name CollectionType $applockerEnforceColl
    Add-Member -InputObject $newObjApplockerEnforce -Type NoteProperty -Name EnforceMode $applockerEnforceMode
    Add-Member -InputObject $newObjApplockerEnforce -Type NoteProperty -Name ServiceMode $applockerEnforceSvc 
    Add-Member -InputObject $newObjApplockerEnforce -Type NoteProperty -Name SysAppAllow $applockerEnforceSys
    Add-Member -InputObject $newObjApplockerEnforce -Type NoteProperty -Name NumerofRules $applockerEnforceCount              
    $fragApplockerEnforcement += $newObjApplockerEnforce
    
}


#Path Conditions
$fragApplockerPath=@()
foreach ($appLockerRule in $gtAppLCollectionTypes)
{
    $appLockerRuleType = ($gtAppLRuleCollection | where {$_.RuleCollectionType -eq "$appLockerRule"}) | select-object PathConditions,PathExceptions,PublisherExceptions,HashExceptions,action,UserOrGroupSid,id,name
    $appLockerPathAllow = $appLockerRuleType | where {$_.action -eq "allow" -and $_.pathconditions -ne $null}
    $appLockerPathDeny = $appLockerRuleType | where {$_.action -eq "deny" -and $_.pathconditions -ne $null} 

        foreach ($allowitem in $appLockerPathAllow)
            {
                $alPathName = [string]$allowitem.name
                $alPathCon = [string]$allowitem.pathconditions
                $alPublishExcep = [string]$allowitem.PublisherExceptions
                $alPublishPathExcep = [string]$allowitem.PathExceptions
                $alPublishHashExcep = [string]$allowitem.HashExceptions
                $alUserGroup = [string]$allowitem.UserOrGroupSid
                $alAction = [string]$allowitem.action
                $alID = [string]$allowitem.ID
                $alRule = [string]$appLockerRule

                $newObjApplocker = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Name $alPathName
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Path $alPathCon
                Add-Member -InputObject $newObjAppLocker -Type NoteProperty -Name PubExcep $alPublishExcep
                Add-Member -InputObject $newObjAppLocker -Type NoteProperty -Name PubPathExcep $alPublishPathExcep
                Add-Member -InputObject $newObjAppLocker -Type NoteProperty -Name PubHashExcep $alPublishHashExcep
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name UserorGroup -Value $alUserGroup                 
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Action -Value $alAction 
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Rule -Value $alRule
                #Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name ID -Value $alID
                $fragApplockerPath += $newObjApplocker    
            }

        foreach ($denyitem in $appLockerPathDeny)
            {
                $alPathName = [string]$denyitem.name
                $alPathCon = [string]$denyitem.pathconditions
                $alPublishExcep = [string]$denyitem.PublisherExceptions
                $alPublishPathExcep = [string]$denyitem.PathExceptions
                $alPublishHashExcep = [string]$denyitem.HashExceptions
                $alUserGroup = [string]$denyitem.UserOrGroupSid
                $alAction = [string]$denyitem.action
                $alID = [string]$denyitem.ID
                $alRule = [string]$appLockerRule

                $newObjApplocker = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Name $alPathName
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Path $alPathCon
                Add-Member -InputObject $newObjAppLocker -Type NoteProperty -Name PubExcep $alPublishExcep
                Add-Member -InputObject $newObjAppLocker -Type NoteProperty -Name PubPathExcep $alPublishPathExcep
                Add-Member -InputObject $newObjAppLocker -Type NoteProperty -Name PubHashExcep $alPublishHashExcep
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name UserorGroup -Value $alUserGroup                 
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Action -Value $alAction 
                Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name Rule -Value $alRule
                #Add-Member -InputObject $newObjApplocker -Type NoteProperty -Name ID -Value $alID
                $fragApplockerPath += $newObjApplocker
            }
}


#Publisher Rules
$gtAppLRuleCollection = Get-ApplockerPolicy -Effective | select -ExpandProperty RuleCollections 
$gtAppLCollectionTypes = Get-ApplockerPolicy -Effective | select -ExpandProperty RuleCollectionTypes

#$appLockerRule  = "exe"
#Path Conditions
$fragApplockerPublisher=@()
foreach ($appLockerRule in $gtAppLCollectionTypes)
{
    $appLockerRuleType = ($gtAppLRuleCollection | where {$_.RuleCollectionType -eq "$appLockerRule"}) | select-object PublisherConditions, PublisherExceptions, PathExceptions, HashExceptions, action,UserOrGroupSid,id,name
    $ApplockerPublisherAllow = $appLockerRuleType | where {$_.action -eq "allow" -and $_.PublisherConditions -ne $null}
    $ApplockerPublisherDeny = $appLockerRuleType | where {$_.action -eq "deny" -and $_.PublisherConditions -ne $null} 

        foreach ($allowitem in $ApplockerPublisherAllow)
            {
                $alPublishName = [string]$allowitem.name
                $alPublishCon = [string]$allowitem.PublisherConditions
                $alPublishExcep = [string]$allowitem.PublisherExceptions
                $alPublishPathExcep = [string]$allowitem.PathExceptions
                $alPublishHashExcep = [string]$allowitem.HashExceptions
                $alUserGroup = [string]$allowitem.UserOrGroupSid
                $alAction = [string]$allowitem.action
                $alID = [string]$allowitem.ID
                $alRule = [string]$appLockerRule

                $newObjAppLockPublisher = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PublisherName $alPublishName
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PublisherConditions $alPublishCon
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PubExcep $alPublishExcep
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PubPathExcep $alPublishPathExcep
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PubHashExcep $alPublishHashExcep
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name UserorGroup -Value $alUserGroup                 
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name Action -Value $alAction 
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name Rule -Value $alRule
                #Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name ID -Value $alID
                $fragApplockerPublisher += $newObjAppLockPublisher    
            }

        foreach ($denyitem in $ApplockerPublisherDeny)
            {
                $alPublishName = [string]$denyitem.name
                $alPublishCon = [string]$denyitem.PublisherConditions
                $alPublishExcep = [string]$denyitem.PublisherExceptions
                $alPublishPathExcep = [string]$denyitem.PathExceptions
                $alPublishHashExcep = [string]$denyitem.HashExceptions
                $alUserGroup = [string]$denyitem.UserOrGroupSid
                $alAction = [string]$denyitem.action
                $alID = [string]$denyitem.ID
                $alRule = [string]$appLockerRule

                $newObjAppLockPublisher = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PublisherName $alPublishName
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PublisherConditions $alPublishCon
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PubExcep $alPublishExcep
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PubPathExcep $alPublishPathExcep
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name PubHashExcep $alPublishHashExcep
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name UserorGroup -Value $alUserGroup                 
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name Action -Value $alAction 
                Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name Rule -Value $alRule
                #Add-Member -InputObject $newObjAppLockPublisher -Type NoteProperty -Name ID -Value $alID
                $fragApplockerPublisher += $newObjAppLockPublisher
            }
}


#hash conditions
$gtAppLRuleCollection = Get-ApplockerPolicy -Effective | select -ExpandProperty RuleCollections 
$gtAppLCollectionTypes = Get-ApplockerPolicy -Effective | select -ExpandProperty RuleCollectionTypes

#Path Conditions
$fragApplockerHash=@()
foreach ($appLockerRule in $gtAppLCollectionTypes)
{
    $appLockerRuleType = ($gtAppLRuleCollection | where {$_.RuleCollectionType -eq "$appLockerRule"}) | select-object HashConditions, action, UserOrGroupSid, id, name
    $ApplockerHashAllow = $appLockerRuleType | where {$_.action -eq "allow" -and $_.HashConditions -ne $null}
    $ApplockerHashDeny = $appLockerRuleType | where {$_.action -eq "deny" -and $_.HashConditions -ne $null} 

        foreach ($allowitem in $ApplockerHashAllow)
            {
                $alHashCon = [string]$allowitem.HashConditions #.split(";")[0]
                $alHashCon = $alHashCon.split(";")[0]
                $alUserGroup = [string]$allowitem.UserOrGroupSid
                $alAction = [string]$allowitem.action
                $alName = [string]$allowitem.name
                $alID = [string]$allowitem.ID
                $alRule = [string]$appLockerRule

                $newObjAppLockHash = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Name $alName
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Hash $alHashCon
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name UserorGroup -Value $alUserGroup                 
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Action -Value $alAction 
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Rule -Value $alRule
                #Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name ID -Value $alID
                $fragApplockerHash += $newObjAppLockHash    
            }

        foreach ($denyitem in $ApplockerHashDeny)
            {
                $alHashCon = [string]$denyitem.HashConditions #.split(";")[0]
                $alHashCon = $alHashCon.split(";")[0]
                $alUserGroup = [string]$denyitem.UserOrGroupSid
                $alAction = [string]$denyitem.action
                $alName = [string]$denyitem.name
                $alID = [string]$denyitem.ID
                $alRule = [string]$appLockerRule

                $newObjAppLockHash = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Name $alName
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Hash $HashCon
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name UserorGroup -Value $alUserGroup                 
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Action -Value $alAction 
                Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name Rule -Value $alRule
                #Add-Member -InputObject $newObjAppLockHash -Type NoteProperty -Name ID -Value $alID
                $fragApplockerHash += $newObjAppLockHash
            }
}



################################################
###############  DLL HIJACKING  ################
################################################
#Loaded  dll's that are vulnerable to dll hijacking - users permissions allow write

Write-Host " "
Write-Host "Searching for active processes that are vulnerable to dll hijacking" -foregroundColor Green
sleep 2

$getDll = Get-Process
$fragDLLHijack=@()
foreach ($dll in $getDll)
{
    $procName = $dll.Name
    $dllMods = $dll | Select-Object -ExpandProperty modules 
    $dllFilename = $dllMods.filename

    foreach ($dllPath in $dllFilename)
    {
        $dllFileAcl = Get-Acl $dllPath -ErrorAction SilentlyContinue

        if ($dllFileAcl | where {$_.Accesstostring -like "*Users Allow  Write*" -or `
        $_.Accesstostring -like "*Users Allow  Modify*" -or `
        $_.Accesstostring -like "*Users Allow  FullControl*" -or `
        $_.Accesstostring -like "*Everyone Allow  Write*" -or `
        $_.Accesstostring -like "*Everyone Allow  Modify*" -or `
        $_.Accesstostring -like "*Everyone Allow  FullControl*" -or `
        $_.Accesstostring -like "*Authenticated Users Allow  Write*" -or `
        $_.Accesstostring -like "*Authenticated Users Allow  Modify*" -or `
        $_.Accesstostring -like "*Authenticated Users Allow  FullControl*"})
            {
                $getAuthCodeSig = get-authenticodesignature -FilePath $dllPath 
                $dllStatus = $getAuthCodeSig.Status

                $newObjDLLHijack = New-Object psObject
                Add-Member -InputObject $newObjDLLHijack -Type NoteProperty -Name DLLProcess -Value "Warning $($procName) warning"
                Add-Member -InputObject $newObjDLLHijack -Type NoteProperty -Name DLLPath -Value "Warning $($dllPath) warning"
                Add-Member -InputObject $newObjDLLHijack -Type NoteProperty -Name DLLSigStatus -Value "Warning $($dllStatus) warning"
                $fragDLLHijack += $newObjDLLHijack
            }              
     }
}

################################################
####################  ASR  #####################
################################################

Write-Host " "
Write-Host "Starting ASR Audit" -foregroundColor Green
sleep 5

$VulnReport = "C:\SecureReport"
$OutFunc = "ASR" 
                
$tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
if ($tpSec10 -eq $false)
{
   New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
}

$ASRPathtxt = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.txt"
$getASRGuids = Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR\Rules" -ErrorAction SilentlyContinue

<#
    - 1 (Block)
    - 0 (Off)
    - 2 (Audit)
    - 5 (Not Configured)
    - 6 (Warn)
#>

if ($getASRGuids -eq $null)
    {
    Set-Content -Path $ASRPathtxt -Value "ASP Policy is not set: 0"
    $getASRCont = Get-Content $ASRPathtxt | Select-String -Pattern ": 1", ": 0"
    }
else
    {
    $getASRGuids | Out-File $ASRPathtxt
    $getASRCont = Get-Content $ASRPathtxt | Select-String -Pattern ": 1", ": 0",": 2",": 6",": 5"
    }


#List of known ASR's
$asrDescription = 
"Block abuse of exploited vulnerable signed drivers - 56a863a9-875e-4185-98a7-b882c64b5ce5",
"Block adobe Reader from creating child processes - 7674ba52-37eb-4a4f-a9a1-f0f9a1619a2c",
"Block all Office applications from creating child processes - d4f940ab-401b-4efc-aadc-ad5f3c50688a",
"Block credential stealing from the Windows local security authority subsystem (lsass.exe) - 9e6c4e1f-7d60-472f-ba1a-a39ef669e4b2",
"Block executable content from email client and webmail - be9ba2d9-53ea-4cdc-84e5-9b1eeee46550",
"Block executable files from running unless they meet a prevalence, age, or trusted list criterion - 01443614-cd74-433a-b99e-2ecdc07bfc25",
"Block execution of potentially obfuscated scripts - 5beb7efe-fd9a-4556-801d-275e5ffc04cc",
"Block JavaScript or VBScript from launching downloaded executable content - d3e037e1-3eb8-44c8-a917-57927947596d",
"Block Office applications from creating executable content - 3b576869-a4ec-4529-8536-b80a7769e899",
"Block Office applications from injecting code into other processes - 75668c1f-73b5-4cf0-bb93-3ecf5cb7cc84",
"Block Office communication application from creating child processes - 26190899-1602-49e8-8b27-eb1d0a1ce869",
"Block persistence through WMI event subscription * File and folder exclusions not supported. - e6db77e5-3df2-4cf1-b95a-636979351e5b",
"Block process creations originating from PSExec and WMI commands - d1e49aac-8f56-4280-b9ba-993a6d77406c",
"Block untrusted and unsigned processes that run from USB - b2b3f03d-6a65-4f7b-a9c7-1c7ef74a9ba4",
"Block Win32 API calls from Office macros - 92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b",
"Block Use advanced protection against ransomware - c1db55ab-c21a-4637-bb3f-a12568109d35"


$ASRList = 
"9BE9BA2D9-53EA-4CDC-84E5-9B1EEEE4655",
"D4F940AB-401B-4EFC-AADC-AD5F3C50688A",
"3B576869-A4EC-4529-8536-B80A7769E899",
"75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84",
"D3E037E1-3EB8-44C8-A917-57927947596D",
"5BEB7EFE-FD9A-4556-801D-275E5FFC04CC",
"92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B",
"01443614-CD74-433A-B99E-2ECDC07BFC25",
"C1DB55AB-C21A-4637-BB3F-A12568109D35",
"9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2",
"D1E49AAC-8F56-4280-B9BA-993A6D77406C",
"B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4",
"26190899-1602-49E8-8B27-EB1D0A1CE869",
"7674BA52-37EB-4A4F-A9A1-F0F9A1619A2C",
"E6DB77E5-3DF2-4CF1-B95A-636979351E5B",
"BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550",
"56a863a9-875e-4185-98a7-b882c64b5ce5"

$fragASR=@()
$asrGuidSetObj=@()

foreach ($getASRContItems in $getASRCont)
{
$asrGuid = $getASRContItems.ToString().split(":").replace(" ","")[0]
$asrGuidSetting = $getASRContItems.ToString().split(":").replace(" ","")[1]

     
        if ($asrGuidSetting -eq "1")
            {
                $asrGuidSetObj = "ASR (Block) = 1"    
            }
       
       if ($asrGuidSetting -eq "2")
            {
                $asrGuidSetObj = "Warning ASR (Audit) = 2 Warning"
            }

       if ($asrGuidSetting -eq "5")
            {
                $asrGuidSetObj = "Warning ASR (Not Configured) = 5 Warning"
            }
       if ($asrGuidSetting -eq "6")
            {
                $asrGuidSetObj = "Warning ASR (Warn) = 6 Warning"
            }
       
       if ($asrGuidSetting -eq "0")
            {
                $asrGuidSetObj = "Warning ASR is disabled Warning"

            }
       if ($asrGuidSetting -eq $null)
            {
                $asrGuidSetObj = "Warning ASR is disabled Warning"
            }

           $ASRDescripObj = $asrDescription | Select-String -Pattern $asrGuid

           $newObjASR = New-Object -TypeName PSObject
           Add-Member -InputObject $newObjASR -Type NoteProperty -Name ASRGuid -Value $asrGuid
           Add-Member -InputObject $newObjASR -Type NoteProperty -Name ASRSetting -Value $asrGuidSetObj
           Add-Member -InputObject $newObjASR -Type NoteProperty -Name ASRDescription -Value $ASRDescripObj
           $fragASR += $newObjASR

}

<# fix this compare to add missing settings that exist in the above table
$ASRContentGuid = $getASRCont.ToString().split(":").replace(" ","")[0]
$missingASRs = (Compare-Object $ASRList $ASRContentGuid | ?{$_.sideIndicator -eq '<='}).InputObject


foreach ($ASRmissingItem in $missingASRs)
{
           $ASRDescripObj = $asrDescription | Select-String -Pattern $ASRmissingItem

           $newObjASR = New-Object -TypeName PSObject
           Add-Member -InputObject $newObjASR -Type NoteProperty -Name ASRGuid -Value "Warning $ASRmissingItem Warning"
           Add-Member -InputObject $newObjASR -Type NoteProperty -Name ASRSetting -Value "Warning Is not Set Warning "
           Add-Member -InputObject $newObjASR -Type NoteProperty -Name ASRDescription -Value "Warning $ASRDescripObj Warning"
           $fragASR += $newObjASR

}
#>
################################################
##########  DOMAIN USER DETAILS  ###############
################################################
#Reports on the credentials of the user running this report 
    $VulnReport = "C:\SecureReport"
    $OutFunc = "DomainUser"  

    $tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
    if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }
    
    $DomainUserPath = "C:\SecureReport\output\$OutFunc\"


    $HostDomain = ((Get-CimInstance -ClassName win32_computersystem).Domain).split(".")[0] + "\" 

    $DomA = $HostDomain + "Domain Admins"
    $DomAWarn = "Warning " + $HostDomain + "Domain Admins" + "  Warning"

    $EntA = $HostDomain + "Enterprise Admins"
    $EntAWarn = "Warning " + $HostDomain + "Enterprise Admins" + "  Warning"

    $SchA = $HostDomain + "Schema Admins"
    $SchAWarn = "Warning " + $HostDomain + "Schema Admins" + "  Warning"

    #WHOAMI /User /FO CSV /NH > C:\SecureReport\output\DomainUser\User.csv
    WHOAMI /Groups /FO CSV /NH > C:\SecureReport\output\DomainUser\Groups.csv
    WHOAMI /Priv /FO CSV /NH > C:\SecureReport\output\DomainUser\Priv.csv

    (Get-Content C:\SecureReport\output\DomainUser\Groups.csv).replace("Mandatory group,","").replace("Enabled by default,","").replace("Enabled group,","").replace("Enabled group","").replace("Group owner","").replace(',"Attributes"',"").replace(',"  "',"").replace(',""',"").replace($EntA,$EntAWarn).replace($DomA,$DomAWarn).replace($SchA,$SchAWarn)  | out-file C:\SecureReport\output\DomainUser\Groups.csv     
    (Get-Content C:\SecureReport\output\DomainUser\Priv.csv).replace("Enabled","Review - Enabled Review") | out-file C:\SecureReport\output\DomainUser\Priv.csv
    
    #import-csv C:\SecureReport\output\DomainUser\User.csv -Delimiter "," | Export-Clixml C:\SecureReport\output\DomainUser\User.xml
    #$whoamiUser = Import-Clixml C:\SecureReport\output\DomainUser\User.xml

    import-csv C:\SecureReport\output\DomainUser\groups.csv -Delimiter "," | Export-Clixml C:\SecureReport\output\DomainUser\groups.xml
    $whoamiGroups = Import-Clixml C:\SecureReport\output\DomainUser\groups.xml

    import-csv C:\SecureReport\output\DomainUser\Priv.csv -Delimiter "," | Export-Clixml C:\SecureReport\output\DomainUser\Priv.xml
    $whoamiPriv = Import-Clixml C:\SecureReport\output\DomainUser\Priv.xml

################################################
################  AUTORUNS  ####################
################################################
#https://attack.mitre.org/techniques/T1547/001/

$fragAutoRunsVal=@()  
<#-------------------------------------------------
File System
--------------------------------------------------#>
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="Placing a program within a startup folder will also cause that program to execute when a user logs in. There is a startup folder location for individual user accounts as well as a system-wide startup folder that will be checked regardless of which user account logs in. The startup folder path for the current user is C:\Users\[Username]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup. The startup folder path for all users is C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp."

$gtCachedProfiles = (Get-ChildItem c:\users\ -Force -Directory).fullname
$fragPSPasswords=@()
foreach ($CachedProfiles in $gtCachedProfiles)
    {
        $tpAppDataStartup = test-path "$($CachedProfiles)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"

        if ($tpAppDataStartup -ne $null)
            {
                $gtAppDataStartup = Get-ChildItem "$($CachedProfiles)\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\" -Recurse -Force -Exclude desktop.ini

                foreach($AppDataStartup in $gtAppDataStartup)
                {
                    $gthkuRunValue=""
                    $newObjAutoRuns = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value ($AppDataStartup.Directory).FullName
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value ($AppDataStartup.Name) 
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                    $fragAutoRunsVal += $newObjAutoRuns 
                }
            }
    }

$tpProgDataStartup = Test-Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" 

if($tpProgDataStartup -ne $null)
    {
        $gtProgDataStartup = Get-ChildItem "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" -Recurse -Force -Exclude desktop.ini

        $newObjAutoRuns = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value ($AppDataStartup.Directory).FullName
        add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value ($AppDataStartup.Name) 
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
        $fragAutoRunsVal += $newObjAutoRuns
    }

<#-------------------------------------------------
HK USERS
--------------------------------------------------#>

New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS
$gtHKUSid = (Get-childItem HKU:\).Name 

foreach ($HKUSidItem in $gtHKUSid)
    {
    #$HKUSidItem = "HKEY_USERS\S-1-5-21-4000739697-4006183653-2191022337-1360"

        $hkuKey = ($HKUSidItem.Split("\")[0]).replace("HKEY_USERS","HKU")
        $hkuSID = $HKUSidItem.Split("\")[1]

        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="Placing a program within a startup folder will also cause that program to execute when a user logs in. There is a startup folder location for individual user accounts as well as a system-wide startup folder that will be checked regardless of which user account logs in. The startup folder path for the current user is C:\Users\[Username]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup. The startup folder path for all users is C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp."
        $hkuRunPath = "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\run"
        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
            foreach($hkuRunItem in $hkuRun)
                {
                    $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property * -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                    $newObjAutoRuns = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                    $fragAutoRunsVal += $newObjAutoRuns                            
                }
        }

        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="Placing a program within a startup folder will also cause that program to execute when a user logs in. There is a startup folder location for individual user accounts as well as a system-wide startup folder that will be checked regardless of which user account logs in. The startup folder path for the current user is C:\Users\[Username]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup. The startup folder path for all users is C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp."

        $hkuRunPath = "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\runonce"

        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
            foreach($hkuRunItem in $hkuRun)
                {
                    $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property * -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                    $newObjAutoRuns = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                    $fragAutoRunsVal += $newObjAutoRuns
                }
         }


        #HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
        #$hkuUserShellFolders = Get-ItemProperty "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="The following Registry keys can be used to set startup folder items for persistence: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders and HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"

        $hkuRunPath = "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = (Get-ItemProperty $hkuRunPath).startup #| select -ExpandProperty property 

            $hkuRunPath = $hkuRunPath
            $hkuRunItem = "startup"
            $gthkuRunValue = $hkuRun

            $newObjAutoRuns = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
            $fragAutoRunsVal += $newObjAutoRuns

         }


        #HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders
        #$hkuShellFolders = Get-ItemProperty "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="The following Registry keys can be used to set startup folder items for persistence: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders and HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"

        $hkuRunPath = "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"
        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = (Get-ItemProperty $hkuRunPath).startup #| select -ExpandProperty property 

            $hkuRunPath = $hkuRunPath
            $hkuRunItem = "startup"
            $gthkuRunValue = $hkuRun

            $newObjAutoRuns = New-Object -TypeName PSObject
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
            Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
            $fragAutoRunsVal += $newObjAutoRuns
         }
         
        #$hkuRunServiceOnce = Get-ItemProperty "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce"
        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="The following Registry keys can control automatic startup of services during boot: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce and HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunServices"
        $hkuRunPath = "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce"

        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
            foreach($hkuRunItem in $hkuRun)
                {
                    $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property * -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                    $newObjAutoRuns = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                    $fragAutoRunsVal += $newObjAutoRuns
                }
         }
         
        #$hkuRunServices = Get-ItemProperty "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\RunServices"
        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="The following Registry keys can control automatic startup of services during boot: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce and HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\RunServices"
        $hkuRunPath = "$($hkuKey):\$($hkuSID)\Software\Microsoft\Windows\CurrentVersion\RunServices"

        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
            foreach($hkuRunItem in $hkuRun)
                {
                    $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property * -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                    $newObjAutoRuns = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                    $fragAutoRunsVal += $newObjAutoRuns
                }
         }


        #HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run
        #$hkuExplorRun = Get-ItemProperty "$($hkuKey):\$($hkuSID)\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"
        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="Using policy settings to specify startup programs creates corresponding values in either of Registry key: HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"
        $hkuRunPath = "$($hkuKey):\$($hkuSID)\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"

        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
            foreach($hkuRunItem in $hkuRun)
                {
                    $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property * -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                    $newObjAutoRuns = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                    $fragAutoRunsVal += $newObjAutoRuns
                }
         }

        #$hkuWindows = Get-ItemProperty "$($hkuKey):\$($hkuSID)\Microsoft\Windows NT\CurrentVersion\Windows"
        $hkuRunComment=@()
        $hkuRunPath=@()
        $hkuRunItem=@()
        $gthkuRunValue=@()
        $tphkuRunPath=@()
        $hkuRunComment="Programs listed in the load value of the registry key: HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Windows run when any user logs on."
        $hkuRunPath = Get-ItemProperty "$($hkuKey):\$($hkuSID)\Microsoft\Windows NT\CurrentVersion\Windows"

        $tphkuRunPath = Test-Path $hkuRunPath

        if($tphkuRunPath -eq $true)
        {
            $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
            foreach($hkuRunItem in $hkuRun)
                {
                    $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property * -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                    $newObjAutoRuns = New-Object -TypeName PSObject
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                    $fragAutoRunsVal += $newObjAutoRuns
                }
         }

    }

<#-------------------------------------------------
HK Local Machine
--------------------------------------------------#>

New-PSDrive -Name HKLM -PSProvider Registry -Root HKEY_LOCAL_MACHINE

#$hklmCVRun = (Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run") 
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="Placing a program within a startup folder will also cause that program to execute when a user logs in. There is a startup folder location for individual user accounts as well as a system-wide startup folder that will be checked regardless of which user account logs in. The startup folder path for the current user is C:\Users\[Username]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup. The startup folder path for all users is C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp."
$hkuRunPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
        foreach($hkuRunItem in $hkuRun)
            {
                $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property *  -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                $newObjAutoRuns = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                $fragAutoRunsVal += $newObjAutoRuns
            }
    }

#$hklmCVRunOnce = (Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce")
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="Placing a program within a startup folder will also cause that program to execute when a user logs in. There is a startup folder location for individual user accounts as well as a system-wide startup folder that will be checked regardless of which user account logs in. The startup folder path for the current user is C:\Users\[Username]\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup. The startup folder path for all users is C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp."
$hkuRunPath = Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce"
$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
        foreach($hkuRunItem in $hkuRun)
            {
                $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property *  -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                $newObjAutoRuns = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                $fragAutoRunsVal += $newObjAutoRuns
            }
    }
    
#Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnceEx"
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="Run keys may exist under multiple hives. The HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunOnceEx is also available but is not created by default on Windows Vista and newer. Registry run key entries can reference programs directly or list them as a dependency. For example, it is possible to load a DLL at logon using a Depend key with RunOnceEx: reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnceEx\0001\Depend /v 1 /d C:\temp\evil[.]dll"
$hkuRunPath = Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnceEx"
$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
        foreach($hkuRunItem in $hkuRun)
            {
                $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property *  -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                $newObjAutoRuns = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                $fragAutoRunsVal += $newObjAutoRuns
            }
    }



#$hklExplorShellFolders = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" -Name "common startup").'Common Startup'
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="The following Registry keys can be used to set startup folder items for persistence: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders and HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$hkuRunPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders"

$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = (Get-ItemProperty $hkuRunPath).startup #| select -ExpandProperty property 

        $hkuRunPath = $hkuRunPath
        $hkuRunItem = "startup"
        $gthkuRunValue = $hkuRun

        $newObjAutoRuns = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
        $fragAutoRunsVal += $newObjAutoRuns

    }
    
#$hklExplorShell = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" -Name "common startup").'Common Startup'
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="The following Registry keys can be used to set startup folder items for persistence: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders and HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

$hkuRunPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"

$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = (Get-ItemProperty $hkuRunPath).startup #| select -ExpandProperty property 

        $hkuRunPath = $hkuRunPath
        $hkuRunItem = "startup"
        $gthkuRunValue = $hkuRun

        $newObjAutoRuns = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
        Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
        $fragAutoRunsVal += $newObjAutoRuns
    }

#$hklmCVRunSvcOnce = (Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce")
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="The following Registry keys can control automatic startup of services during boot:HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce and HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunServices"
$hkuRunPath = Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce"
$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
        foreach($hkuRunItem in $hkuRun)
            {
                $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property *  -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                $newObjAutoRuns = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                $fragAutoRunsVal += $newObjAutoRuns
            }
    }

#$hklmCVRunSvc = (Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServices")
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="The following Registry keys can control automatic startup of services during boot:HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunServicesOnce and HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\RunServices"

$hkuRunPath = Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunServices"
$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
        foreach($hkuRunItem in $hkuRun)
            {
                $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property *  -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                $newObjAutoRuns = New-Object -TypeName PSObject
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                $fragAutoRunsVal += $newObjAutoRuns
            }
    }
    
#$hklmCVPolRun = (Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run")
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="Using policy settings to specify startup programs creates corresponding values in either of two Registry keys: HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"
$hkuRunPath = Get-Item "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"
$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
    {
        $hkuRun = Get-Item $hkuRunPath | select -ExpandProperty property
        foreach($hkuRunItem in $hkuRun)
            {
                $gthkuRunValue = (Get-ItemProperty $hkuRunPath -Name $hkuRunItem | Select -Property *  -ExcludeProperty pspath,PSParentPath,PSChildName,psdrive,psprovider).$hkuRunItem 
            
                 $newObjAutoRuns = New-Object -TypeName PSObject
                 Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
                 Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
                 Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
                 Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
                 $fragAutoRunsVal += $newObjAutoRuns
            }
    }


#Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit" 
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="The Winlogon key controls actions that occur when a user logs on to a computer running Windows 7. Most of these actions are under the control of the operating system, but you can also add custom actions here. The HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit and HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell subkeys can automatically launch programs."
$hkuRunPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"

$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
{
    $hkuRun = (Get-ItemProperty $hkuRunPath).Userinit #| select -ExpandProperty property 

    $hkuRunPath = $hkuRunPath
    $hkuRunItem = "Userinit "
    $gthkuRunValue = $hkuRun

    if ($gthkuRunValue -notmatch "userinit.exe"){$gthkuRunValue = "Warning $gthkuRunValue Warning"}
    
    $newObjAutoRuns = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
    $fragAutoRunsVal += $newObjAutoRuns

}

#Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell"
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="The Winlogon key controls actions that occur when a user logs on to a computer running Windows 7. Most of these actions are under the control of the operating system, but you can also add custom actions here. The HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Userinit and HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\Shell subkeys can automatically launch programs."

$hkuRunPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"

$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
{
    $hkuRun = (Get-ItemProperty $hkuRunPath).Shell #| select -ExpandProperty property 

    $hkuRunPath = $hkuRunPath
    $hkuRunItem = "Shell"
    $gthkuRunValue = $hkuRun

    if ($gthkuRunValue -notmatch "explorer.exe" ){$gthkuRunValue = "Warning $gthkuRunValue Warning"}

    $newObjAutoRuns = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
    $fragAutoRunsVal += $newObjAutoRuns
}


#(Get-ItemProperty "HKLM:\\System\CurrentControlSet\Control\Session Manager").BootExecute
$hkuRunComment=@()
$hkuRunPath=@()
$hkuRunItem=@()
$gthkuRunValue=@()
$tphkuRunPath=@()
$hkuRunComment="By default, the multistring BootExecute value of the registry key HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager is set to autocheck autochk *. This value causes Windows, at startup, to check the file-system integrity of the hard disks if the system has been shut down abnormally. Adversaries can add other programs or processes to this registry value which will automatically launch at boot."
$hkuRunPath = "HKLM:\System\CurrentControlSet\Control\Session Manager"

$tphkuRunPath = Test-Path $hkuRunPath

if($tphkuRunPath -eq $true)
{
    $hkuRun = (Get-ItemProperty $hkuRunPath).BootExecute #| select -ExpandProperty property 

    $hkuRunPath = $hkuRunPath
    $hkuRunItem = "BootExecute"
    $gthkuRunValue = [string]$hkuRun

    if ($gthkuRunValue -notmatch "autocheck autochk *" ){$gthkuRunValue = "Warning $gthkuRunValue Warning"}

    $newObjAutoRuns = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsPath -Value $hkuRunPath
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsKey -Value $hkuRunItem 
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsValue -Value $gthkuRunValue
    Add-Member -InputObject $newObjAutoRuns -Type NoteProperty -Name AutoRunsComment -Value $hkuRunComment
    $fragAutoRunsVal += $newObjAutoRuns
}

################################################
#######  RECOMMENDED SECURITY SETTINGS  ########
################  WINDOWS OS  ##################
################################################

#Here's 3000 lines of fun ;(
#Unable to extract GPO spreadsheet due to the numbers involved and the amount of work getting the spreadsheet into a workable format
#Lastly some of the MS recommend settings are mental and would destroy the system when following blindly eg Kerberos Armouring 
# Here are the settings that should either be set or at least acknowledged

    $fragWindowsOSVal=@()

    <#
    Boot-Start Driver Initialization Policy

    Computer Configuration\Policies\Administrative Templates\System\Early Launch Antimalware

    This policy setting allows you to specify which boot-start drivers are initialized based on a classification determined by an Early Launch Antimalware boot-start driver. The Early Launch Antimalware boot-start driver can return the following classifications for each boot-start driver:
    - Good: The driver has been signed and has not been tampered with.
    - Bad: The driver has been identified as malware. It is recommended that you do not allow known bad drivers to be initialized.
    - Bad, but required for boot: The driver has been identified as malware, but the computer cannot successfully boot without loading this driver.
    - Unknown: This driver has not been attested to by your malware detection application and has not been classified by the Early Launch Antimalware boot-start driver.

    If you enable this policy setting you will be able to choose which boot-start drivers to initialize the next time the computer is started.
    If you disable or do not configure this policy setting, the boot start drivers determined to be Good, Unknown or Bad but Boot Critical are initialized and the initialization of drivers determined to be Bad is skipped.
    If your malware detection application does not include an Early Launch Antimalware boot-start driver or if your Early Launch Antimalware boot-start driver has been disabled, this setting has no effect and all boot-start drivers are initialized.

    #>
    $WindowsOSDescrip = "Boot-Start Driver Initialization Policy"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Early Launch Antimalware\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Policies\EarlyLaunch\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DriverLoadPolicy"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "8")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled good only boot-start drivers that can be initialized" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    elseif ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled good and unknown only boot-start drivers that can be initialized" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    elseif ($getWindowsOSVal -eq "3")
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Good, unknown and bad but critical boot-start drivers that can be initialized warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }
    else
    {
        #Else assume all boot-start drivers are allowed this is normally have a value of 7
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled all boot-start drivers that can be initialized warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

     if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse 
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Safe Mode

    An adversary with standard user credentials that can boot into Microsoft Windows using Safe Mode, Safe Mode with Networking or Safe Mode with 
    Command Prompt options may be able to bypass system protections and security functionality. To reduce this risk, users with standard credentials 
    should be prevented from using Safe Mode options to log in.

    The following registry entry can be implemented using Group Policy preferences to prevent non-administrators from using Safe Mode options.

    #>
    $WindowsOSDescrip = "Prevent SafeMode for Non Admins"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Error Reporting\Advanced Error Reporting Settings\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "SafeModeBlockNonAdmins"   
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is not set warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

     if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse 
    $fragWindowsOSVal += $newObjWindowsOS

    <#

    Do not display network selection UI Enabled

    Computer Configuration\Policies\Administrative Templates\System\Logon\Do not display network selection UI Enabled

    This policy setting allows you to control whether anyone can interact with available networks UI on the logon screen.
    If you enable this policy setting, the PC's network connectivity state cannot be changed without signing into Windows.
    If you disable or don't configure this policy setting, any user can disconnect the PC from the network or can connect the PC to other available networks without signing into Windows.
    #>

    $WindowsOSDescrip = "Do not display network selection UI Enabled"
    $gpopath = "Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DontDisplayNetworkSelectionUI"

    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal=@()
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal")

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is Enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }
    else
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }

     if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting  -Value $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    
    <#
    Enumerate local users on domain-joined computers

    Computer Configuration\Policies\Administrative Templates\System\Logon

    This policy setting allows local users to be enumerated on domain-joined computers.
    If you enable this policy setting, Logon UI will enumerate all local users on domain-joined computers.
    If you disable or do not configure this policy setting, the Logon UI will not enumerate local users on domain-joined computers.
    #>
    
    $WindowsOSDescrip = "Enumerate local users on domain-joined computers"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnumerateLocalUsers"

    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal=@()
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal")

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is Enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }
    else
    {
        $WindowsOSSet = "$WindowsOSDescrip is Disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Maintaining an audit trail of system activity logs can help identify configuration errors, troubleshoot service disruptions, 
    and analyze compromises that have occurred, as well as detect attacks. Audit logs are necessary to provide a trail of evidence 
    in case the system or network is compromised. Collecting this data is essential for analyzing the security of information 
    assets and detecting signs of suspicious and unexpected behavior. Enabling "Include command line data for process creation events"
     will record the command line information with the process creation events in the log. This can provide additional detail when 
     malware has run on a system.

    Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer

    #>
    $WindowsOSDescrip = "Include command line in process creation events"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Audit Process Creation\$WindowsOSDescrip"
    $RegKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit\'
    $WindowsOSVal=@()
    $WindowsOSVal = "ProcessCreationIncludeCmdLine_Enabled"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    This policy setting determines if the SMB client will allow insecure guest logons to an SMB server.
    If you enable this policy setting or if you do not configure this policy setting the SMB client will 
    allow insecure guest logons.If you disable this policy setting the SMB client will reject insecure guest logons.
    Insecure guest logons are used by file servers to allow unauthenticated access to shared folders. While uncommon 
    in an enterprise environment insecure guest logons are frequently used by consumer 
    Network Attached Storage (NAS) appliances acting as file servers. Windows file servers require authentication 
    and do not use insecure guest logons by default. Since insecure guest logons are unauthenticated important security 
    features such as SMB Signing and SMB Encryption are disabled. As a result clients that allow insecure guest logons 
    are vulnerable to a variety of man-in-the-middle attacks that can result in data loss data corruption and exposure to malware. 
    Additionally any data written to a file server using an insecure guest logon is potentially accessible to anyone on the network. 
    Microsoft recommends disabling insecure guest logons and configuring file servers to require authenticated access."      

    #>
    $WindowsOSDescrip = "Enable insecure guest logons"
    $gpopath ="Computer Configuration\Administrative Templates\Network\Lanman Workstation\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\LanmanWorkstation\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowInsecureGuestAuth"   
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is not set warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn off picture password sign-in

    Computer Configuration\Policies\Administrative Templates\System\Logon

    This policy setting allows you to control whether a domain user can sign in using a picture password.
    If you enable this policy setting, a domain user can't set up or sign in with a picture password.
    If you disable or don't configure this policy setting, a domain user can set up and use a picture password.
    Note that the user's domain password will be cached in the system vault when using this feature.

    #>
    $WindowsOSDescrip = "Turn off picture password sign-in"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "BlockDomainPicturePassword"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn on convenience PIN sign-in

    Computer Configuration\Policies\Administrative Templates\System\Logon

    This policy setting allows you to control whether a domain user can sign in using a convenience PIN.
    If you enable this policy setting, a domain user can set up and sign in with a convenience PIN.
    If you disable or don't configure this policy setting, a domain user can't set up and use a convenience PIN.
    Note: The user's domain password will be cached in the system vault when using this feature.
    To configure Windows Hello for Business, use the Administrative Template policies under Windows Hello for Business.

    #>
    $WindowsOSDescrip = "Turn on convenience PIN sign-in"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowDomainPINLogon"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip enabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

 <#
    Allow users to select when a password is required when resuming from connected standby

    Computer Configuration\Policies\Administrative Templates\System\Logon

    This policy setting allows you to control whether a user can change the time before a password is required when a Connected Standby device screen turns off.
    If you enable this policy setting, a user on a Connected Standby device can change the amount of time after the device's screen turns off before a password is required when waking the device. The time is limited by any EAS settings or Group Policies that affect the maximum idle time before a device locks. Additionally, if a password is required when a screensaver turns on, the screensaver timeout will limit the options the user may choose.
    If you disable this policy setting, a user cannot change the amount of time after the device's screen turns off before a password is required when waking the device. Instead, a password is required immediately after the screen turns off.

    #>
    $WindowsOSDescrip = "Allow users to select when a password is required when resuming from connected standby"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowDomainDelayLock"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Turn off app notifications on the lock screen

    Computer Configuration\Policies\Administrative Templates\System\Logon

    #>
    $WindowsOSDescrip = "Turn off app notifications on the lock screen"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableLockScreenAppNotifications"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS



<#
    Prevent the computer from joining a homegroup

    Computer Configuration\Policies\Administrative Templates\Windows Components\HomeGroup

    This policy setting specifies whether users can add computers to a homegroup. By default, users can add their computer to a homegroup on a private network.
    If you enable this policy setting, users cannot add computers to a homegroup. This policy setting does not affect other network sharing features.
    If you disable or do not configure this policy setting, users can add computers to a homegroup. However, data on a domain-joined computer is not shared with the homegroup.
    This policy setting is not configured by default.
    You must restart the computer for this policy setting to take effect.

    #>
    $WindowsOSDescrip = "Prevent the computer from joining a homegroup"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\HomeGroup\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\HomeGroup\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableHomeGroup"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


  <#
    Allow Windows Ink Workspace

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Ink Workspace

    #>
    $WindowsOSDescrip = "Allow Windows Ink Workspace"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Ink Workspace\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\WindowsInkWorkspace\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowWindowsInkWorkspace"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Show lock in the user tile menu

    Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer

    #>
    $WindowsOSDescrip = "Show lock in the user tile menu"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "ShowLockOption"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Enable screen saver

    User Configuration\Policies\Administrative Templates\Control Panel\Personalization

    #>
    $WindowsOSDescrip = "Enable screen saver"
    $gpopath ="User Configuration\Policies\Administrative Templates\Control Panel\Personalization\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop\'
    $WindowsOSVal=@()
    $WindowsOSVal = "ScreenSaveActive"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Password protect the screen saver

    User Configuration\Policies\Administrative Templates\Control Panel\Personalization

    #>
    $WindowsOSDescrip = "Password protect the screen saver"
    $gpopath ="User Configuration\Policies\Administrative Templates\Control Panel\Personalization\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop\'
    $WindowsOSVal=@()
    $WindowsOSVal = "ScreenSaverIsSecure"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Screen saver timeout

    User Configuration\Policies\Administrative Templates\Control Panel\Personalization

    #>
    $WindowsOSDescrip = "Screen saver timeout"
    $gpopath ="User Configuration\Policies\Administrative Templates\Control Panel\Personalization\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop\'
    $WindowsOSVal=@()
    $WindowsOSVal = "ScreenSaveTimeOut"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "900")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Turn off toast notifications on the lock screen

    User Configuration\Policies\Administrative Templates\Start Menu and Taskbar\Notifications

    #>
    $WindowsOSDescrip = "Turn off toast notifications on the lock screen"
    $gpopath ="User Configuration\Policies\Administrative Templates\Start Menu and Taskbar\Notifications\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\PushNotifications\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoToastApplicationNotificationOnLockScreen"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Do not suggest third-party content in Windows spotlight

    User Configuration\Policies\Administrative Templates\Windows Components\Cloud Content

    #>
    $WindowsOSDescrip = "Do not suggest third-party content in Windows spotlight"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\Cloud Content\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\CloudContent\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableThirdPartySuggestions"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Prevent enabling lock screen camera

    Computer Configuration\Policies\Administrative Templates\Control Panel\Personalization

    #>
    $WindowsOSDescrip = "Prevent enabling lock screen camera"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Control Panel\Personalization\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Personalization\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoLockScreenCamera"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Prevent enabling lock screen slide show

    Computer Configuration\Policies\Administrative Templates\Control Panel\Personalization

    #>
    $WindowsOSDescrip = "Prevent enabling lock screen camera"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Control Panel\Personalization\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Personalization\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoLockScreenSlideshow"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Prevent users from sharing files within their profile.

    User Configurations\Policies\Administrative Templates\Windows Components\Network Sharing

    By default users are allowed to share files within their profile to other users on their network once an administrator opts in the computer. An administrator can opt in the computer by using the sharing wizard to share a file within their profile.
    If you enable this policy, users will not be able to share files within their profile using the sharing wizard. Also, the sharing wizard will not create a share at %root%\users and can only be used to create SMB shares on folders.
    If you disable or don't configure this policy, then users will be able to share files out of their user profile once an administrator has opted in the computer.

    #>
    $WindowsOSDescrip = "Prevent users from sharing files within their profile"
    $gpopath ="User Configurations\Policies\Administrative Templates\Windows Components\Network Sharing\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoInplaceSharing"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Do not display the password reveal button

    Computer Configuration\Policies\Administrative Templates\System\Logon

    This policy setting allows you to configure the display of the password reveal button in password entry user experiences.
    If you enable this policy setting, the password reveal button will not be displayed after a user types a password in the password entry text box.
    If you disable or do not configure this policy setting, the password reveal button will be displayed after a user types a password in the password entry text box.
    By default, the password reveal button is displayed after a user types a password in the password entry text box. To display the password, click the password reveal button.
    The policy applies to all Windows components and applications that use the Windows system controls, including Internet Explorer.
    
    #>

    $WindowsOSDescrip = "Do not display the password reveal button"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\CredUI\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisablePasswordReveal"
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal=@()
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal")

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


   <#
    Enumerate administrator accounts on elevation

    Computer Configuration\Policies\Administrative Templates\Windows Components\Credential User Interface\

    This policy setting controls whether administrator accounts are displayed when a user attempts to elevate a running application. By default, administrator accounts are not displayed when the user attempts to elevate a running application.
    If you enable this policy setting, all local administrator accounts on the PC will be displayed so the user can choose one and enter the correct password.
    If you disable this policy setting, users will always be required to type a user name and password to elevate.
    #>

    $WindowsOSDescrip = "Enumerate administrator accounts on elevation"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Credential User Interface\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\CredUI\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnumerateAdministrators"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Require trusted path for credential entry

    Computer Configuration\Policies\Administrative Templates\Windows Components\Credential User Interface

    This policy setting requires the user to enter Microsoft Windows credentials using a trusted path, to prevent a Trojan horse or other types of malicious code from stealing the user's Windows credentials.
    Note: This policy affects nonlogon authentication tasks only. As a security best practice, this policy should be enabled.
    If you enable this policy setting, users will be required to enter Windows credentials on the Secure Desktop by means of the trusted path mechanism.
    If you disable or do not configure this policy setting, users will enter Windows credentials within the user's desktop session, potentially allowing malicious code Access to the user's Windows credentials.
    #>

    $WindowsOSDescrip = "Require trusted path for credential entry"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Credential User Interface\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\CredUI\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnableSecureCredentialPrompting"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse 
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Prevent the use of security questions for local accounts

    Computer Configuration\Policies\Administrative Templates\Windows Components\Credential User Interface

    If you turn this policy setting on, local users won't be able to set up and use security questions to reset their passwords.    
    #>

    $WindowsOSDescrip = "Prevent the use of security questions for local accounts"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Credential User Interface\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoLocalPasswordResetQuestions"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Disable or enable software Secure Attention Sequence

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Logon Options
    
    This policy setting controls whether or not software can simulate the Secure Attention Sequence (SAS).

    If you enable this policy setting, you have one of four options:

    If you set this policy setting to "None," user mode software cannot simulate the SAS.
    If you set this policy setting to "Services," services can simulate the SAS.
    If you set this policy setting to "Ease of Access applications," Ease of Access applications can simulate the SAS.
    If you set this policy setting to "Services and Ease of Access applications," both services and Ease of Access applications can simulate the SAS.

    If you disable or do not configure this setting, only Ease of Access applications running on the secure desktop can simulate the SAS.   
    #>

    $WindowsOSDescrip = "Disable or enable software Secure Attention Sequence"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Logon Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "SoftwareSASGeneration"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq $null)
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is Enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Sign-in last interactive user automatically after a system-initiated restart

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Logon Options 

    This policy setting controls whether a device will automatically sign-in the last interactive user after Windows Update restarts the system.

    If you enable or do not configure this policy setting, the device securely saves the user's credentials 
    (including the user name, domain and encrypted password) to configure automatic sign-in after a Windows Update restart. 
    After the Windows Update restart, the user is automatically signed-in and the session is automatically locked with all 
    the lock screen apps configured for that user.
    If you disable this policy setting, the device does not store the user's credentials for automatic sign-in after a 
    Windows Update restart. The users' lock screen apps are not restarted after the system restarts.
    #>
    $WindowsOSDescrip = "Sign-in last interactive user automatically after a system-initiated restart"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Logon Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableAutomaticRestartSignOn"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1" -or $getWindowsOSVal -eq $null)
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled or not Set Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Interactive logon: Do not require CTRL+ALT+DEL

    Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options 

    This security setting determines whether pressing CTRL+ALT+DEL is required before a user can log on.

    If this policy setting is enabled on a device, a user is not required to press CTRL+ALT+DEL to log on.
    If this policy is disabled, any user is required to press CTRL+ALT+DEL before logging on to the Windows operating system 
    (unless they are using a smart card for logon).
    Microsoft developed this feature to make it easier for users with certain types of physical impairments to log on to device
    running the Windows operating system; however, not having to press the CTRL+ALT+DELETE key combination leaves users susceptible 
    to attacks that attempt to intercept their passwords. Requiring CTRL+ALT+DELETE before users log on ensures that users are
    communicating by means of a trusted path when entering their passwords.
    A malicious user might install malware that looks like the standard logon dialog box for the Windows operating system, and 
    capture a user's password. The attacker can then log on to the compromised account with whatever level of user rights that user has.

    Note: passing ctrl, alt and Del through multiple RDP wont work
    #>

    $WindowsOSDescrip = "Interactive logon: Do not require CTRL+ALT+DEL"
    $gpopath ="Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options\Windows Logon Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "disablecad"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is Enabled or not defined Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Interactive logon: Machine inactivity limit

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    #>
    $WindowsOSDescrip = "Interactive logon: Machine inactivity limit"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "InactivityTimeoutSecs"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "900")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Interactive logon: Number of previous logons to cache (in case domain controller is not available)

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    Windows caches previous users' logon information locally so that they can log on if a logon server is unavailable during later logon attempts.
    If a domain controller is unavailable and a user's logon information is cached, the user will be prompted with a dialog that says:
    A domain controller for your domain could not be contacted. You have been logged on using cached account information. Changes to your profile 
    since you last logged on may not be available.
    With caching disabled, the user is prompted with this message:
    The system cannot log you on now because the domain <DOMAIN_NAME> is not available.

    #>

    $WindowsOSDescrip = "Interactive logon: Number of previous logons to cache"
    $gpopath ="Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options\Windows Logon Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\'
    $WindowsOSVal=@()
    $WindowsOSVal = "CachedLogonsCount"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -lt "2")
    {
        $WindowsOSSet = "$WindowsOSDescrip caches $getWindowsOSVal previous logons, ideally this should be set to 1" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is $getWindowsOSVal, ideally this should be set to 1 Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Network Access: Do not allow storage of passwords and credentials for network authentication

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    This security setting determines whether Credential Manager saves passwords and credentials for later use when it gains domain authentication.

    Possible values
    Enabled

    Credential Manager does not store passwords and credentials on the device

    Disabled

    Credential Manager will store passwords and credentials on this computer for later use for domain authentication.

    Not defined

    Best practices
    It is a recommended practice to disable the ability of the Windows operating system to cache credentials on any 
    device where credentials are not needed. Evaluate your servers and workstations to determine the requirements. 
    Cached credentials are designed primarily to be used on laptops that require domain credentials when disconnected from the domain.

    #>
    $WindowsOSDescrip = "Network Access: Do not allow storage of passwords and credentials for network authentication"
    $gpopath ="Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options\Windows Logon Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "disabledomaincreds"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS
 

    <#
    Apply UAC restrictions to local accounts on network logons

    This setting controls whether local accounts can be used for remote administration via network logon 
    (e.g., NET USE, connecting to C$, etc.). Local accounts are at high risk for credential theft when the 
    same account and password is configured on multiple systems. Enabling this policy significantly reduces that risk.

    Enabled (recommended): Applies UAC token-filtering to local accounts on network logons. Membership in 
    powerful group such as Administrators is disabled and powerful privileges are removed from the resulting 
    Access token. This configures the LocalAccountTokenFilterPolicy registry value to 0. This is the default behavior for Windows.

    Disabled: Allows local accounts to have full administrative rights when authenticating via network logon, 
    by configuring the LocalAccountTokenFilterPolicy registry value to 1.

    For more information about local accounts and credential theft, see "Mitigating Pass-the-Hash (PtH) 
    Attacks and Other Credential Theft Techniques": http://www.microsoft.com/en-us/download/details.aspx?id=36036.

    For more information about LocalAccountTokenFilterPolicy, see http://support.microsoft.com/kb/951016.

    #>
    $WindowsOSDescrip = "Apply UAC restrictions to local accounts on network logons"
    $gpopath ="No GPO Setting available"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "LocalAccountTokenFilterPolicy"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled, mitigates Pass-the-Hash Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

       <#
    Hardened UNC Paths

    Computer Configuration\Policies\Administrative Templates\Network\Network Provider

    Not applicable to non-domain joined systems

    When enabled ensures only domain joined systems can download and Access policies


    #>
    $WindowsOSDescrip = "Hardened UNC Paths"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Network\Network Provider\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\NetworkProvider\HardenedPaths\'
    $WindowsOSVal=@()
    $WindowsOSVal = "HardenedPaths"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
   # $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 
     $getWindowsOSVal = $getWindowsOS.Property

    if ($getWindowsOSVal -eq "\\*\SYSVOL" -and "\\*\NETLOGON")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled, \\*\SYSVOL and \\*\NETLOGON are missing Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    
   <#
    Configure registry policy processing

    Computer Configuration\Policies\Administrative Templates\System\Group Policy

    The "Process even if the Group Policy objects have not changed" option updates and reapplies the policies even if the policies 
    have not changed. Many policy implementations specify that they are updated only when changed. However, you might want to update 
    unchanged policies, such as reapplying a desired policy setting in case a user has changed it.

    #>
    $WindowsOSDescrip = "Configure registry policy processing"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Group Policy\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Group Policy\{35378EAC-683F-11D2-A89A-00C04FBBCFA2}\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoGPOListChanges"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

       <#
    Configure security policy processing

    Computer Configuration\Policies\Administrative Templates\System\Group Policy

    The "Process even if the Group Policy objects have not changed" option updates and reapplies the policies even if the policies 
    have not changed. Many policy implementations specify that they are updated only when changed. However, you might want to update 
    unchanged policies, such as reapplying a desired policy setting in case a user has changed it.

    reboot for reg to be created and gpo to apply

    #>
    $WindowsOSDescrip = "Configure security policy processing"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Group Policy\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Group Policy\{827D319E-6EAC-11D2-A4EA-00C04F79F83A}\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoBackgroundPolicy"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Turn off background refresh of Group Policy

    Computer Configuration\Policies\Administrative Templates\System\Group Policy

    This policy setting prevents Group Policy from being updated while the computer is in use. This policy setting applies to Group Policy for computers, users, and domain controllers.
    If you enable this policy setting, the system waits until the current user logs off the system before updating the computer and user settings.
    If you disable or do not configure this policy setting, updates can be applied while users are working. The frequency of updates is determined by the "Set Group Policy refresh interval for computers" and "Set Group Policy refresh interval for users" policy settings.


    #>
    $WindowsOSDescrip = "Turn off background refresh of Group Policy"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Group Policy\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableBkGndGroupPolicy"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn off Local Group Policy Objects processing

    Computer Configuration\Policies\Administrative Templates\System\Group Policy

    This policy setting prevents Local Group Policy Objects (Local GPOs) from being applied.
    By default, the policy settings in Local GPOs are applied before any domain-based GPO policy settings. These policy settings can apply to both users and the local computer. You can disable the processing and application of all Local GPOs to ensure that only domain-based GPOs are applied.
    If you enable this policy setting, the system does not process and apply any Local GPOs.
    If you disable or do not configure this policy setting, Local GPOs continue to be applied.
    Note: For computers joined to a domain, it is strongly recommended that you only configure this policy setting in domain-based GPOs. This policy setting will be ignored on computers that are joined to a workgroup.

    #>
    $WindowsOSDescrip = "Turn off Local Group Policy Objects processing"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Group Policy\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableLGPOProcessing"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Network Access: Allow anonymous SID/Name translation

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    This policy setting enables or disables the ability of an anonymous user to request security identifier (SID) attributes for another user.
    If this policy setting is enabled, a user might use the well-known Administrators SID to get the real name of the built-in Administrator account, even if the account has been renamed. That person might then use the account name to initiate a brute-force password-guessing attack.
    Misuse of this policy setting is a common error that can cause data loss or problems with data Access or security.

    #>
    $WindowsOSDescrip = "Network Access: Allow anonymous SID/Name translation"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AnonymousNameLookup"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Network Access: Let Everyone permissions apply to anonymous users

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    This policy setting determines what additional permissions are granted for anonymous connections to the device. 
    If you enable this policy setting, anonymous users can enumerate the names of domain accounts and shared folders and 
    perform certain other activities. This capability is convenient, for example, when an administrator wants to grant 
    Access to users in a trusted domain that does not maintain a reciprocal trust.

    By default, the token that is created for anonymous connections does not include the Everyone SID. Therefore, permissions 
    that are assigned to the Everyone group do not apply to anonymous users.

    #>
    $WindowsOSDescrip = "Network Access: Let Everyone permissions apply to anonymous users"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "everyoneincludesanonymous"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Network Access: Do not allow anonymous enumeration of SAM accounts

    RestrictAnonymousSAM (Sam accounts)

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    This policy setting determines which additional permissions will be assigned for anonymous connections to the 
    device. Windows allows anonymous users to perform certain activities, such as enumerating the names of domain 
    accounts and network shares. This is convenient, for example, when an administrator wants to give Access to users 
    in a trusted domain that does not maintain a reciprocal trust. However, even with this policy setting enabled,
     anonymous users will have Access to resources with permissions that explicitly include the built-in group, ANONYMOUS LOGON.
    This policy setting has no impact on domain controllers. Misuse of this policy setting is a common error that 
    can cause data loss or problems with data Access or security.

    #>
    $WindowsOSDescrip = "Network Access: Do not allow anonymous enumeration of SAM accounts"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "RestrictAnonymousSAM"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Network Access: Do not allow anonymous enumeration of SAM accounts and shares

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    RestrictAnonymous (Sam accounts and shares)

    This policy setting determines which additional permissions will be assigned for anonymous connections to the device. 
    Windows allows anonymous users to perform certain activities, such as enumerating the names of domain accounts and network shares. 
    This is convenient, for example, when an administrator wants to give Access to users in a trusted domain that does not 
    maintain a reciprocal trust. However, even with this policy setting enabled, anonymous users will have Access to resources 
    with permissions that explicitly include the built-in group, ANONYMOUS LOGON.
    This policy setting has no impact on domain controllers. Misuse of this policy setting is a common error that can cause data 
    loss or problems with data Access or security.

    #>
    $WindowsOSDescrip = "Network Access: Do not allow anonymous enumeration of SAM accounts and shares"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "RestrictAnonymous"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Network Access: Restrict anonymous Access to Named Pipes and Shares

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    This policy setting enables or disables the restriction of anonymous Access to only those shared folders and 
    pipes that are named in the Network Access: Named pipes that can be Accessed anonymously and Network Access: 
    Shares that can be Accessed anonymously settings. The setting controls null session Access to shared folders 
    on your computers by adding RestrictNullSessAccess with the value 1 in the registry key 
    HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\LanManServer\Parameters. This registry value toggles null session 
    shared folders on or off to control whether the Server service restricts unauthenticated clients' Access to named resources.
    Null sessions are a weakness that can be exploited through the various shared folders on the devices in your environment.


    #>
    $WindowsOSDescrip = "Network Access: Restrict anonymous Access to Named Pipes and Shares"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Services\LanManServer\Parameters\'
    $WindowsOSVal=@()
    $WindowsOSVal = "RestrictNullSessAccess"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Network Access: Restrict clients allowed to make remote calls to SAM

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/network-Access-restrict-clients-allowed-to-make-remote-sam-calls
    O:BAG:BAD:(A;;RC;;;BA) = Administrator
    #>
    $WindowsOSDescrip = "Network Access: Restrict clients allowed to make remote calls to SAM"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "RestrictRemoteSam"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "O:BAG:BAD:(A;;RC;;;BA)")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled to allow Administrator remote Access (O:BAG:BAD:(A;;RC;;;BA))" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"

    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled or not set Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Network security: Allow Local System to use computer identity for NTLM

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    When services connect to devices that are running versions of the Windows operating system earlier than 
    Windows Vista or Windows Server 2008, services that run as Local System and use SPNEGO (Negotiate) that revert 
    to NTLM will authenticate anonymously. In Windows Server 2008 R2 and Windows 7 and later, if a service connects 
    to a computer running Windows Server 2008 or Windows Vista, the system service uses the computer identity.
    When a service connects with the device identity, signing and encryption are supported to provide data protection. 
    (When a service connects anonymously, a system-generated session key is created, which provides no protection, 
    but it allows applications to sign and encrypt data without errors. Anonymous authentication uses a NULL session, 
    which is a session with a server in which no user authentication is performed; and therefore, anonymous Access is allowed.)
    
    #>
    $WindowsOSDescrip = "Network security: Allow Local System to use computer identity for NTLM"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "UseMachineId"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Network security: Allow LocalSystem NULL session fallback

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    This policy affects session security during the authentication process between devices running Windows Server 2008 R2 and Windows 7 
    and later and those devices running earlier versions of the Windows operating system. For computers running Windows Server 2008 R2 
    and Windows 7 and later, services running as Local System require a service principal name (SPN) to generate the session key. However, 
    if Network security: Allow Local System to use computer identity for NTLM is set to disabled, services running as Local System will 
    fall back to using NULL session authentication when they transmit data to servers running versions of Windows earlier than Windows 
    Vista or Windows Server 2008. NULL session does not establish a unique session key for each authentication; and thus, it cannot provide 
    integrity or confidentiality protection. The setting Network security: Allow LocalSystem NULL session fallback determines whether services 
    that request the use of session security are allowed to perform signature or encryption functions with a well-known key for application compatibility.
    
    #>
    $WindowsOSDescrip = "Network security: Allow LocalSystem NULL session fallback"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\LSA\MSV1_0\'
    $WindowsOSVal=@()
    $WindowsOSVal = "allownullsessionfallback"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS   

    <#
    Accounts: Limit local account use of blank passwords to console logon only

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    #>
    $WindowsOSDescrip = "Accounts: Limit local account use of blank passwords to console logon only"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Lsa\'
    $WindowsOSVal=@()
    $WindowsOSVal = "LimitBlankPasswordUse"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS



<#
    Disallow Autoplay for non-volume devices - Machine

    Computer Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies

    #>
    $WindowsOSDescrip = "Disallow Autoplay for non-volume devices"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoAutoplayfornonVolume"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Disallow Autoplay for non-volume devices - Users

    User Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies

    #>
    $WindowsOSDescrip = "Disallow Autoplay for non-volume devices"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoAutoplayfornonVolume"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Set the default behavior for AutoRun - Machine

    Computer Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies

    #>
    $WindowsOSDescrip = "Set the default behavior for AutoRun"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoAutorun"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Set the default behavior for AutoRun - Users

    User Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies

    #>
    $WindowsOSDescrip = "Set the default behavior for AutoRun"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoAutorun"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn off Autoplay - Machine

    Computer Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies

    #>
    $WindowsOSDescrip = "Turn off Autoplay"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoDriveTypeAutoRun"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "255")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn off Autoplay - Users

    User Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies

    #>
    $WindowsOSDescrip = "Turn off Autoplay"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\AutoPlay Policies\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoDriveTypeAutoRun"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "255")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

<#
    Prevent Access to the command prompt

    User Configuration\Policies\Administrative Templates\System

    This policy setting prevents users from running the interactive command prompt Cmd.exe.

    This policy setting also determines whether batch files (.cmd and .bat) can run on the computer.
    If you enable this policy setting and the user tries to open a command window, the system displays a message explaining that a setting prevents the action. .
    If you disable this policy setting or don't configure it, users can run Cmd.exe and batch files normally.

    #>
    $WindowsOSDescrip = "Prevent Access to the Command Prompt"
    $gpopath ="User Configuration\Policies\Administrative Templates\System\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableCMD"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Prevent Access to registry editing tools

    User Configuration\Policies\Administrative Templates\System

    #>
    $WindowsOSDescrip = "Prevent Access to Registry Editing Tools"
    $gpopath ="User Configuration\Policies\Administrative Templates\System\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableRegistryTools"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "2")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn on PowerShell Script Block Logging

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows PowerShell

    #>
    $WindowsOSDescrip = "Turn on PowerShell Script Block Logging"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows PowerShell\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnableScriptBlockLogging"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn on Script Execution

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows PowerShell

    #>
    $WindowsOSDescrip = "Turn on Script Execution - Execution Policy: Allow only signed scripts"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows PowerShell\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\PowerShell\'
    $WindowsOSVal=@()
    $WindowsOSVal = "ExecutionPolicy"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS
    
    <#
    Configure Windows Defender SmartScreen

    Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer

    This policy allows you to turn Windows Defender SmartScreen on or off. SmartScreen helps protect PCs by warning users before 
    running potentially malicious programs downloaded from the Internet. This warning is presented as an interstitial dialog shown 
    before running an app that has been downloaded from the Internet and is unrecognized or known to be malicious. No dialog is shown 
    for apps that do not appear to be suspicious.

    Some information is sent to Microsoft about files and programs run on PCs with this feature enabled.
    If you enable this policy, SmartScreen will be turned on for all users. Its behavior can be controlled by the following options:
    • Warn and prevent bypass
    • Warn

    #>
    $WindowsOSDescrip = "Configure Windows Defender SmartScreen (File Explorer)"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnableSmartScreen"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled to Warn and prevent bypass" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is set warn and allow bypass Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Configure Windows Defender SmartScreen

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Defender SmartScreen\Explorer

    This policy allows you to turn Windows Defender SmartScreen on or off. SmartScreen helps protect PCs by warning users before 
    running potentially malicious programs downloaded from the Internet. This warning is presented as an interstitial dialog shown 
    before running an app that has been downloaded from the Internet and is unrecognized or known to be malicious. No dialog is shown 
    for apps that do not appear to be suspicious.

    Some information is sent to Microsoft about files and programs run on PCs with this feature enabled.
    If you enable this policy, SmartScreen will be turned on for all users. Its behavior can be controlled by the following options:
    • Warn and prevent bypass
    • Warn

    Info: looks like both GPO's set the same registry setting

    #>
    $WindowsOSDescrip = "Configure Windows Defender SmartScreen (Windows Defender SmartScreen)"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Defender SmartScreen\Explorer\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnableSmartScreen"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled to Warn and prevent bypass" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is set warn and allow bypass Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    
    <#
    Allow user control over installs

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Installer

    This policy setting permits users to change installation options that typically are available only to system administrators.

    If you enable this policy setting, some of the security features of Windows Installer are bypassed. It permits installations to 
    complete that otherwise would be halted due to a security violation.
        If you disable or do not configure this policy setting, the security features of Windows Installer prevent users from changing 
        installation options typically reserved for system administrators, such as specifying the directory to which files are installed.

    #>
    $WindowsOSDescrip = "Allow user control over installs"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Installer\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Installer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnableUserControl"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip enabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Always install with elevated privileges - Computer

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Installer

    This policy setting permits users to change installation options that typically are available only to system administrators.

    If you enable this policy setting, privileges are extended to all programs. These privileges are usually reserved for programs 
    that have been assigned to the user (offered on the desktop), assigned to the computer (installed automatically), or made available 
    in Add or Remove Programs in Control Panel. This profile setting lets users install programs that require Access to directories that the user might not have permission to view or change, including directories on highly restricted computers.
    If you disable or do not configure this policy setting, the system applies the current user's permissions when it installs programs 
    that a system administrator does not distribute or offer.
    Note: This policy setting appears both in the Computer Configuration and User Configuration folders. To make this policy setting 
    effective, you must enable it in both folders.

    #>
    $WindowsOSDescrip = "Always install with elevated privileges"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Installer\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Installer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AlwaysInstallElevated"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip enabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Always install with elevated privileges - User

    User Configuration\Policies\Administrative Templates\Windows Components\Windows Installer

    This policy setting permits users to change installation options that typically are available only to system administrators.

    If you enable this policy setting, privileges are extended to all programs. These privileges are usually reserved for programs 
    that have been assigned to the user (offered on the desktop), assigned to the computer (installed automatically), or made available 
    in Add or Remove Programs in Control Panel. This profile setting lets users install programs that require Access to directories that the user might not have permission to view or change, including directories on highly restricted computers.
    If you disable or do not configure this policy setting, the system applies the current user's permissions when it installs programs 
    that a system administrator does not distribute or offer.
    Note: This policy setting appears both in the Computer Configuration and User Configuration folders. To make this policy setting 
    effective, you must enable it in both folders.

    #>
    $WindowsOSDescrip = "Always install with elevated privileges"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\Windows Installer\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\Installer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AlwaysInstallElevated"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip enabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Devices: Prevent users from installing printer drivers

    Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options

    #>
    $WindowsOSDescrip = "Devices: Prevent users from installing printer drivers"
    $gpopath ="Computer Configuration\Policies\Windows Settings\Security Settings\Local Policies\Security Options\$WindowsOSDescrip"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Print\Providers\LanMan Print Services\Servers\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AddPrinterDrivers"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled, only Admin can install printer drivers" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }
    
    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Do not process the legacy run list

    Computer Configuration\Policies\Administrative Templates\System\Logon

    Once malicious code has been copied to a workstation, an adversary with registry Access can remotely schedule it 
    to execute (i.e. using the run once list) or to automatically execute each time Microsoft Windows starts (i.e. using the legacy run list). 
    To reduce this risk, legacy and run once lists should be disabled. This may interfere with the operation of legitimate applications that 
    need to automatically execute each time Microsoft Windows starts. In such cases, the Run these programs at user logon Group Policy 
    setting can be used to perform the same function in a more secure manner when defined at a domain level; however, if not used this Group Policy 
    setting should be disabled rather than left in its default undefined state.

    #>
    $WindowsOSDescrip = "Do not process the legacy run list"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableCurrentUserRun"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Do not process the legacy run list

    Computer Configuration\Policies\Administrative Templates\System\Logon

    Once malicious code has been copied to a workstation, an adversary with registry Access can remotely schedule it 
    to execute (i.e. using the run once list) or to automatically execute each time Microsoft Windows starts (i.e. using the legacy run list). 
    To reduce this risk, legacy and run once lists should be disabled. This may interfere with the operation of legitimate applications that 
    need to automatically execute each time Microsoft Windows starts. In such cases, the Run these programs at user logon Group Policy 
    setting can be used to perform the same function in a more secure manner when defined at a domain level; however, if not used this Group Policy 
    setting should be disabled rather than left in its default undefined state.

    #>
    $WindowsOSDescrip = "Do not process the run once list"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableLocalMachineRunOnce"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Run these programs at user logon

    Computer Configuration\Policies\Administrative Templates\System\Logon

    This policy setting specifies additional programs or documents that Windows starts automatically when a user logs on to the system.
    If you enable this policy setting, you can specify which programs can run at the time the user logs on to this computer that has this policy applied.
    To specify values for this policy setting, click Show. In the Show Contents dialog box in the Value column, type the name of the executable program (.exe) 
    file or document file. To specify another name, press ENTER, and type the name. Unless the file is located in the %Systemroot% directory, you must specify 
    the fully qualified path to the file.
    If you disable or do not configure this policy setting, the user will have to start the appropriate programs after logon

    #>
    $WindowsOSDescrip = "Run these programs at user logon"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Logon\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run\'
    $WindowsOSVal=@()
    $WindowsOSVal = "1"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq 1)
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "$WindowsOSDescrip disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

<#
    Do not preserve zone information in file attachments

    User Configuration\Policies\Administrative Templates\Windows Components\Attachment Manager

    The Attachment Manager within Microsoft Windows works in conjunction with applications such as the Microsoft Office suite and Internet Explorer to 
    help protect workstations from attachments that have been received via email or downloaded from the internet. The Attachment Manager classifies files 
    as high, medium or low risk based on the zone they originated from and the type of file. Based on the risk to the workstation, the Attachment Manager 
    will either issue a warning to a user or prevent them from opening a file. If zone information is not preserved, or can be removed, it can allow an 
    adversary to socially engineer a user to bypass protections afforded by the Attachment Manager. To reduce this risk, the Attachment Manager should 
    be configured to preserve and protect zone information for files.


    #>
    $WindowsOSDescrip = "Do not preserve zone information in file attachments"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\Attachment Manager\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments\'
    $WindowsOSVal=@()
    $WindowsOSVal = "SaveZoneInformation"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "2")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Hide mechanisms to remove zone information

    User Configuration\Policies\Administrative Templates\Windows Components\Attachment Manager

    This policy setting allows you to manage whether users can manually remove the zone information from saved file attachments by 
    clicking the Unblock button in the file's property sheet or by using a check box in the security warning dialog. Removing the zone 
    information allows users to open potentially dangerous file attachments that Windows has blocked users from opening.
    If you enable this policy setting, Windows hides the check box and Unblock button.
    If you disable this policy setting, Windows shows the check box and Unblock button.
    If you do not configure this policy setting, Windows hides the check box and Unblock button.

    #>
    $WindowsOSDescrip = "Hide mechanisms to remove zone information"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\Attachment Manager\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments\'
    $WindowsOSVal=@()
    $WindowsOSVal = "HideZoneInfoOnProperties"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


<#
    Restrict Unauthenticated RPC clients

    Computer Configuration\Policies\Administrative Templates\System\Remote Procedure Call

    Remote Procedure Call (RPC) is a technique used for facilitating client and server application communications using a common interface. 
    RPC is designed to make client and server interaction easier and safer by using a common library to handle tasks such as security, 
    synchronisation and data flows. If unauthenticated communications are allowed between client and server applications, it could result in 
    accidental disclosure of sensitive information or the failure to take advantage of RPC security functionality. To reduce this risk, all 
    RPC clients should authenticate to RPC servers.

    This policy setting impacts all RPC applications.  In a domain environment this policy setting should be used with caution as it can impact a 
    wide range of functionality including group policy processing itself.  Reverting a change to this policy setting can require manual intervention 
    on each affected machine. 
    
    This policy setting should never be applied to a domain controller.

    #>
    $WindowsOSDescrip = "Restrict Unauthenticated RPC clients"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Remote Procedure Call\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows NT\Rpc\'
    $WindowsOSVal=@()
    $WindowsOSVal = "RestrictRemoteClients"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled - Not to be applied against DCs Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Restrict Unauthenticated RPC clients

    Computer Configuration\Policies\Administrative Templates\System\Remote Procedure Call

    This policy setting controls whether RPC clients authenticate with the Endpoint Mapper Service when the call 
    they are making contains authentication information. The Endpoint Mapper Service on computers running Windows 
    NT4 (all service packs) cannot process authentication information supplied in this manner.
    If you disable this policy setting, RPC clients will not authenticate to the Endpoint Mapper Service, but they 
    will be able to communicate with the Endpoint Mapper Service on Windows NT4 Server.
    If you enable this policy setting, RPC clients will authenticate to the Endpoint Mapper Service for calls that 
    contain authentication information. Clients making such calls will not be able to communicate with the Windows 
    NT4 Server Endpoint Mapper Service.

    #>
    $WindowsOSDescrip = "Enable RPC Endpoint Mapper Client Authentication"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Remote Procedure Call\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows NT\Rpc\'
    $WindowsOSVal=@()
    $WindowsOSVal = "EnableAuthEpResolution"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Disallow Digest authentication

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Client
    
    This policy setting allows you to manage whether the Windows Remote Management (WinRM) client uses Digest authentication.
    If you enable this policy setting, the WinRM client does not use Digest authentication.
    If you disable or do not configure this policy setting, the WinRM client uses Digest authentication.

    #>
    $WindowsOSDescrip = "Disallow Digest authentication"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Client\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowDigest"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

<#
    Allow Basic authentication

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Service
    
    This policy setting allows you to manage whether the Windows Remote Management (WinRM) service accepts Basic authentication from a remote client.
    If you enable this policy setting, the WinRM service accepts Basic authentication from a remote client.
    If you disable or do not configure this policy setting, the WinRM service does not accept Basic authentication from a remote client.

    #>
    $WindowsOSDescrip = "Allow Basic authentication"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Service\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\service\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowBasic"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Allow unencrypted traffic

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Service
    
    This policy setting allows you to manage whether the Windows Remote Management (WinRM) service sends and receives unencrypted messages over the network.
    If you enable this policy setting, the WinRM client sends and receives unencrypted messages over the network.
    If you disable or do not configure this policy setting, the WinRM client sends or receives only encrypted messages over the network.

    #>
    $WindowsOSDescrip = "Allow unencrypted traffic"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Service\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowUnencryptedTraffic"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Allow Basic authentication

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Client
    
    This policy setting allows you to manage whether the Windows Remote Management (WinRM) service accepts Basic authentication from a remote client.
    If you enable this policy setting, the WinRM service accepts Basic authentication from a remote client.
    If you disable or do not configure this policy setting, the WinRM service does not accept Basic authentication from a remote client.

    #>
    $WindowsOSDescrip = "Allow Basic authentication"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Client\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowBasic"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Allow unencrypted traffic

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Client
    
    This policy setting allows you to manage whether the Windows Remote Management (WinRM) service sends and receives unencrypted messages over the network.
    If you enable this policy setting, the WinRM client sends and receives unencrypted messages over the network.
    If you disable or do not configure this policy setting, the WinRM client sends or receives only encrypted messages over the network.

    #>
    $WindowsOSDescrip = "Allow unencrypted traffic"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Client\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Client\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowUnencryptedTraffic"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Disallow WinRM from storing RunAs credentials

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Service
    
    This policy setting allows you to manage whether the Windows Remote Management (WinRM) service will not allow RunAs credentials to be stored for any plug-ins.
    If you enable this policy setting, the WinRM service will not allow the RunAsUser or RunAsPassword configuration values to be set for any plug-ins. If a plug-in 
    has already set the RunAsUser and RunAsPassword configuration values, the RunAsPassword configuration value will be erased from the credential store on this 
    computer

    #>
    $WindowsOSDescrip = "Disallow WinRM from storing RunAs credentials"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Management (WinRM)\WinRM Client\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableRunAs"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Allow Remote Shell Access

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Shell
    
    This policy setting configures Access to remote shells.
    If you enable or do not configure this policy setting, new remote shell connections are accepted by the server.
    If you set this policy to 'disabled', new remote shell connections are rejected by the server.

    #>
    $WindowsOSDescrip = "Allow Remote Shell Access"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Remote Shell\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WinRM\Service\WinRS\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowRemoteShellAccess"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Prohibit connection to non-domain networks when connected to domain authenticated network

    "Computer Configuration\Administrative Templates\Network\Windows Connection Manager\"

    This policy setting prevents computers from connecting to both a domain based network and a non-domain based network 
    at the same time.If this policy setting is enabled the computer responds to automatic and manual network connection 
    attempts based on the following circumstances:Automatic connection attempts- When the computer is already connected 
    to a domain based network all automatic connection attempts to non-domain networks are blocked.- When the computer 
    is already connected to a non-domain based network automatic connection attempts to domain based networks are blocked.
    Manual connection attempts- When the computer is already connected to either a non-domain based network or a domain based 
    network over media other than Ethernet and a user attempts to create a manual connection to an additional network in 
    violation of this policy setting the existing network connection is disconnected and the manual connection is allowed.- 
    When the computer is already connected to either a non-domain based network or a domain based network over Ethernet 
    and a user attempts to create a manual connection to an additional network in violation of this policy setting the 
    existing Ethernet connection is maintained and the manual connection attempt is blocked.If this policy setting is 
    not configured or is disabled computers are allowed to connect simultaneously to both domain and non-domain networks.      
    
    #>
    $WindowsOSDescrip = "Prohibit connection to non-domain networks when connected to domain authenticated network"
    $gpopath ="Computer Configuration\Administrative Templates\Network\Windows Connection Manager\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WcmSvc\GroupPolicy\'
    $WindowsOSVal=@()
    $WindowsOSVal = "fBlockNonDomain"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disbled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Prohibit use of Internet Connection Sharing on your DNS domain network

    "Computer Configuration\Administrative Templates\Network\Network Connections"

    Determines whether administrators can enable and configure the Internet Connection Sharing (ICS) feature of an Internet 
    connection and if the ICS service can run on the computer.ICS lets administrators configure their system as an Internet 
    gateway for a small network and provides network services such as name resolution and addressing through DHCP to the local 
    private network.If you enable this setting ICS cannot be enabled or configured by administrators and the ICS service cannot 
    run on the computer. The Advanced tab in the Properties dialog box for a LAN or remote access connection is removed. The Internet 
    Connection Sharing page is removed from the New Connection Wizard. The Network Setup Wizard is disabled.If you disable this setting 
    or do not configure it and have two or more connections administrators can enable ICS. The Advanced tab in the properties dialog 
    box for a LAN or remote access connection is available. In addition the user is presented with the option to enable Internet Connection 
    Sharing in the Network Setup Wizard and Make New Connection Wizard. (The Network Setup Wizard is available only in Windows XP 
    Professional.)By default ICS is disabled when you create a remote access connection but administrators can use the Advanced tab to 
    enable it. When running the New Connection Wizard or Network Setup Wizard administrators can choose to enable ICS.Note: Internet 
    Connection Sharing is only available when two or more network connections are present.Note: When the "Prohibit access to properties 
    of a LAN connection" "Ability to change properties of an all user remote access connection" or "Prohibit changing properties of a 
    private remote access connection" settings are set to deny access to the Connection Properties dialog box the Advanced tab for the 
    connection is blocked.Note: Nonadministrators are already prohibited from configuring Internet Connection Sharing regardless of this 
    setting.Note: Disabling this setting does not prevent Wireless Hosted Networking from using the ICS service for DHCP services. 
    To prevent the ICS service from running on the Network Permissions tab in the network's policy properties select the "Don't use 
    hosted networks" check box.
    
    #>

    $WindowsOSDescrip = "Prohibit use of Internet Connection Sharing on your DNS domain network"
    $gpopath ="Computer Configuration\Administrative Templates\Network\Network Connections\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Network Connections\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NC_ShowSharedAccessUI"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

 
    <#
    Allow Windows to automatically connect to suggested open hotspots to networks shared by contacts and to hotspots offering paid services
    
    "Computer Configuration\Administrative Templates\Network\WLAN Service\WLAN SettingsAllow Windows to automatically connect to suggested open hotspots to networks shared by contacts and to hotspots offering paid services"

    This policy setting determines whether users can enable the following WLAN settings: "Connect to suggested open hotspots" 
    "Connect to networks shared by my contacts" and "Enable paid services"."Connect to suggested open hotspots" enables Windows 
    to automatically connect users to open hotspots it knows about by crowdsourcing networks that other people using Windows have 
    connected to."Connect to networks shared by my contacts" enables Windows to automatically connect to networks that the user's 
    contacts have shared with them and enables users on this device to share networks with their contacts."Enable paid services" 
    enables Windows to temporarily connect to open hotspots to determine if paid services are available.If this policy setting is 
    disabled both "Connect to suggested open hotspots" "Connect to networks shared by my contacts" and "Enable paid services" will 
    be turned off and users on this device will be prevented from enabling them.If this policy setting is not configured or is enabled 
    users can choose to enable or disable either "Connect to suggested open hotspots"  or "Connect to networks shared by my contacts".      
    #>

    $WindowsOSDescrip = "Allow Windows to automatically connect to suggested open hotspots to networks shared by contacts and to hotspots offering paid services"
    $gpopath ="Computer Configuration\Administrative Templates\Network\WLAN Service\WLAN Settings\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\wcmsvc\wifinetworkmanager\config\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AutoConnectAllowedOEM"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Remote host allows delegation of non-exportable credentials
    
    "Computer Configuration\Administrative Templates\System\Credentials Delegation\Remote host allows delegation of non-exportable credentials"

    Remote host allows delegation of non-exportable credentialsWhen using credential delegation devices provide an exportable version of 
    credentials to the remote host. This exposes users to the risk of credential theft from attackers on the remote host.If you enable 
    this policy setting the host supports Restricted Admin or Remote Credential Guard mode.If you disable or do not configure this policy 
    setting Restricted Administration and Remote Credential Guard mode are not supported. User will always need to pass their credentials 
    to the host.   
    #>

    $WindowsOSDescrip = "Remote host allows delegation of non-exportable credentials"
    $gpopath ="Computer Configuration\Administrative Templates\System\Credentials Delegation\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\CredentialsDelegation\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowProtectedCreds"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Encryption Oracle Remediation
        
    "Computer Configuration\Administrative Templates\System\Credentials Delegation"

    Encryption Oracle RemediationThis policy setting applies to applications using the CredSSP component (for example: Remote Desktop Connection).
    Some versions of the CredSSP protocol are vulnerable to an encryption oracle attack against the client.  This policy controls 
    compatibility with vulnerable clients and servers.  This policy allows you to set the level of protection desired for the 
    encryption oracle vulnerability.If you enable this policy setting CredSSP version support will be selected based on the 
    following options:Force Updated Clients: Client applications which use CredSSP will not be able to fall back to the insecure 
    versions and services using CredSSP will not accept unpatched clients. Note: this setting should not be deployed until all 
    remote hosts support the newest version.Mitigated: Client applications which use CredSSP will not be able to fall back to the 
    insecure version but services using CredSSP will accept unpatched clients. See the link below for important information about 
    the risk posed by remaining unpatched clients.Vulnerable: Client applications which use CredSSP will expose the remote servers to 
    attacks by supporting fall back to the insecure versions and services using CredSSP will accept unpatched clients.For more information 
    about the vulnerability and servicing requirements for protection see https://go.microsoft.com/fwlink/?linkid=866660   
    #>

    $WindowsOSDescrip = "Encryption Oracle Remediation"
    $gpopath ="Computer Configuration\Administrative Templates\System\Credentials Delegation\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowEncryptionOracle"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled Force Updated Clients" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


  
      <#
    Allow Cortana

    Computer Configuration\Policies\Administrative Templates\Windows Components\Search
    
    This policy setting specifies whether Cortana is allowed on the device.
    If you enable or don't configure this setting, Cortana will be allowed on the device. If you disable this setting, Cortana will be turned off.

    #>
    $WindowsOSDescrip = "Allow Cortana"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Search\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Windows Search\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowCortana"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Don't search the web or display web results in Search

    Computer Configuration\Policies\Administrative Templates\Windows Components\Search
    
    This policy setting allows you to control whether or not Search can perform queries on the web, and if the web results are displayed in Search.
    If you enable this policy setting, queries won't be performed on the web and web results won't be displayed when a user performs a query in Search.
    If you disable this policy setting, queries will be performed on the web and web results will be displayed when a user performs a query in Search.
    If you don't configure this policy setting, a user can choose whether or not Search can perform queries on the web, and if the web results are displayed in Search

    #>
    $WindowsOSDescrip = "Don't search the web or display web results in Search"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Search\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsSearch\'
    $WindowsOSVal=@()
    $WindowsOSVal = "ConnectedSearchUseWeb"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Microsoft Support Diagnostic Tool: Turn on MSDT interactive communication with support provider

    Computer Configuration\Policies\Administrative Templates\System\Troubleshooting and Diagnostics\Microsoft Support Diagnostic Tool

    #>
    $WindowsOSDescrip = "Microsoft Support Diagnostic Tool: Turn on MSDT interactive communication with support provider"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Troubleshooting and Diagnostics\Microsoft Support Diagnostic Tool\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\ScriptedDiagnosticsProvider\Policy\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableQueryRemoteServer"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip enabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn off Inventory Collector

    Computer Configuration\Policies\Administrative Templates\Windows Components\Application Compatibility

    The Inventory Collector inventories applications, files, devices, and drivers on the system and sends the information to Microsoft. 
    This information is used to help diagnose compatibility problems.
    If you enable this policy setting, the Inventory Collector will be turned off and data will not be sent to Microsoft. Collection of
     installation data through the Program Compatibility Assistant is also disabled.
    If you disable or do not configure this policy setting, the Inventory Collector will be turned on.

    #>
    $WindowsOSDescrip = "Turn off Inventory Collector"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Application Compatibility\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\AppCompat\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableInventory"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn off Steps Recorder

    Computer Configuration\Policies\Administrative Templates\Windows Components\Application Compatibility
    Steps Recorder keeps a record of steps taken by the user. The data generated by Steps Recorder can be used in feedback systems 
    such as Windows Error Reporting to help developers understand and fix problems. The data includes user actions such as keyboard 
    input and mouse input, user interface data, and screen shots. Steps Recorder includes an option to turn on and off data collection.

    #>
    $WindowsOSDescrip = "Turn off Steps Recorder"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Application Compatibility\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\AppCompat\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableUAR"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Prevent Access to 16-bit applications

    Computer Configuration\Policies\Administrative Templates\Windows Components\Application Compatibility

    Specifies whether to prevent the MS-DOS subsystem (ntvdm.exe) from running on this computer. This setting affects the launching of 16-bit
     applications in the operating system.
    You can use this setting to turn off the MS-DOS subsystem, which will reduce resource usage and prevent users from running 16-bit applications. 
    To run any 16-bit application or any application with 16-bit components, ntvdm.exe must be allowed to run. The MS-DOS subsystem starts when the 
    first 16-bit application is launched. While the MS-DOS subsystem is running, any subsequent 16-bit applications launch faster, but overall resource 
    usage on the system is increased.
    If the status is set to Enabled, the MS-DOS subsystem is prevented from running, which then prevents any 16-bit applications from running. 
    In addition, any 32-bit applications with 16-bit installers or other 16-bit components cannot run.

    #>
    $WindowsOSDescrip = "Prevent Access to 16-bit applications"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Application Compatibility\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\AppCompat\'
    $WindowsOSVal=@()
    $WindowsOSVal = "VDMDisallowed"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Allow Telemetry

    Computer Configuration\Policies\Administrative Templates\Windows Components\Data Collection and Preview Builds

    Diagnostic data is categorized into four levels, as follows:
    - 0 (Security). Information that's required to help keep Windows, Windows Server, and System Center secure, including data about the Connected User Experiences and Telemetry component settings, the Malicious Software Removal Tool, and Windows Defender.
    - 1 (Required). Basic device info, including: quality-related data, app compatibility, and data from the Security level.
    - 2 (Enhanced). Additional insights, including: how Windows, Windows Server, System Center, and apps are used, how they perform, advanced reliability data, and data from both the Required and the Security levels.
    - 3 (Optional). All data necessary to identify and help to fix problems, plus data from the Security, Required, and Enhanced levels.

    #>
    $WindowsOSDescrip = "Allow Telemetry"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Data Collection and Preview Builds\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowTelemetry"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled for Enterprise Only - Computer" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


        <#
    Allow Telemetry

    Computer Configuration\Policies\Administrative Templates\Windows Components\Data Collection and Preview Builds

    Diagnostic data is categorized into four levels, as follows:
    - 0 (Security). Information that's required to help keep Windows, Windows Server, and System Center secure, including data about the Connected User Experiences and Telemetry component settings, the Malicious Software Removal Tool, and Windows Defender.
    - 1 (Required). Basic device info, including: quality-related data, app compatibility, and data from the Security level.
    - 2 (Enhanced). Additional insights, including: how Windows, Windows Server, System Center, and apps are used, how they perform, advanced reliability data, and data from both the Required and the Security levels.
    - 3 (Optional). All data necessary to identify and help to fix problems, plus data from the Security, Required, and Enhanced levels.

    #>
    $WindowsOSDescrip = "Allow Telemetry"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Data Collection and Preview Builds\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\DataCollection\'
    $WindowsOSVal=@()
    $WindowsOSVal = "AllowTelemetry"
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled for Enterprise Only - User" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip disabled warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Configure Corporate Windows Error Reporting

    Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Error Reporting\Advanced Error Reporting Settings

    This policy setting specifies a corporate server to which Windows Error Reporting sends reports (if you do not want to send error reports to Microsoft).
    If you enable this policy setting, you can specify the name or IP address of an error report destination server on your organization's network. 
    You can also select Connect using SSL to transmit error reports over a Secure Sockets Layer (SSL) connection, and specify a port number on the destination 
    server for transmission.

    #>
    $WindowsOSDescrip = "Configure Corporate Windows Error Reporting"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Windows Error Reporting\Advanced Error Reporting Settings\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\WindowsErrorReporting\'
    $WindowsOSVal=@()
    $WindowsOSVal = "CorporateWerUseSSL"   #query for SSL to be enabled
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is not set warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

    <#
    Turn off Data Execution Prevention for Explorer

    Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer

    Disabling data execution prevention can allow certain legacy plug-in applications to function without terminating Explorer.

    #>
    $WindowsOSDescrip = "Turn off Data Execution Prevention for Explorer"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoDataExecutionPrevention"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Enabled Structured Exception Handling Overwrite Protection (SEHOP)

    Computer Configuration\Policies\Administrative Templates\Windows Components\File Explorer

    If this setting is enabled, SEHOP is enforced. For more information, see 
    https://support.microsoft.com/en-us/help/956607/how-to-enable-structured-exception-handling-overwrite-protection-sehop-in-windows-operating-systems.
    If this setting is disabled or not configured, SEHOP is not enforced for 32-bit processes.

    https://support.microsoft.com/en-us/topic/how-to-enable-structured-exception-handling-overwrite-protection-sehop-in-windows-operating-systems-8d4595f7-827f-72ee-8c34-fa8e0fe7b915

    #>
    $WindowsOSDescrip = "Enabled Structured Exception Handling Overwrite Protection (SEHOP)"
    $gpopath ="Create manually or via GPO Preferences"
    $RegKey = 'HKLM:\System\CurrentControlSet\Control\Session Manager\kernel\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableExceptionChainValidation"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
    Remove Security tab

    User Configuration\Policies\Administrative Templates\Windows Components\File Explorer

    #>
    $WindowsOSDescrip = "Remove Security tab - User"
    $gpopath ="User Configuration\Policies\Administrative Templates\Windows Components\File Explorer\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoSecurityTab"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

   <#
    Turn off location

    Computer Configuration\Policies\Administrative Templates\Windows Components\Location and Sensors

    #>
    $WindowsOSDescrip = "Turn off location"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Location and Sensors\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\LocationAndSensors\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableLocationScripting"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS
    

       <#
   Turn off Windows Location Provider

    Computer Configuration\Policies\Administrative Templates\Windows Components\Location and Sensors\Windows Location Provider

    #>
    $WindowsOSDescrip = "Turn off Windows Location Provider"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Location and Sensors\Windows Location Provider\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\LocationAndSensors\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DisableWindowsLocationProvider"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


    <#
   Turn off Access to the Store

    Computer Configuration\Policies\Administrative Templates\System\Internet Communication Management\Internet Communication settings

    Pointless setting, I dont know anyone who uses the Windows Store or at least own up to using it ;)

    #>
    $WindowsOSDescrip = "Turn off Access to the Store"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\System\Internet Communication Management\Internet Communication settings\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\Windows\Explorer\'
    $WindowsOSVal=@()
    $WindowsOSVal = "NoUseStoreOpenWith"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


   <#
   Turn off the Store application

    Computer Configuration\Policies\Administrative Templates\Windows Components\Store

    Pointless setting, I dont know anyone who uses the Windows Store or at least own up to using it ;)

    #>
    $WindowsOSDescrip = "Turn off the Store application"
    $gpopath ="Computer Configuration\Policies\Administrative Templates\Windows Components\Store\$WindowsOSDescrip"
    $RegKey = 'HKLM:\Software\Policies\Microsoft\WindowsStore\'
    $WindowsOSVal=@()
    $WindowsOSVal = "RemoveWindowsStore"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "1")
    {
        $WindowsOSSet = "$WindowsOSDescrip is Enabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is disabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsSetting -Value  $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS

   <#
   Determine if interactive users can generate Resultant Set of Policy data

    User Configuration\Policies\Administrative Templates\System\Group Policy - Users

    Allows user to interrogate gpos for system weaknesses

    #>
    $WindowsOSDescrip = "Determine if interactive users can generate RSOP"
    $gpopath ="User Configuration\Policies\Administrative Templates\System\Group Policy\$WindowsOSDescrip"
    $RegKey = 'HKCU:\Software\Policies\Microsoft\Windows\System\'
    $WindowsOSVal=@()
    $WindowsOSVal = "DenyRsopToInteractiveUser"  
    $getWindowsOSVal=@()
    $getWindowsOS = Get-Item $RegKey -ErrorAction SilentlyContinue
    $getWindowsOSVal = $getWindowsOS.GetValue("$WindowsOSVal") 

    if ($getWindowsOSVal -eq "0")
    {
        $WindowsOSSet = "$WindowsOSDescrip is disabled" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "True"
    }
    else
    {
        $WindowsOSSet = "Warning $WindowsOSDescrip is enabled Warning" 
        $WindowsOSReg = "<div title=$gpoPath>$RegKey" +"$WindowsOSVal"
        $trueFalse = "False"
    }

    if ([string]::IsNullorEmpty($getWindowsOSVal) -eq $true){$WindowsOSSet = "DefaultGPO $WindowsOSDescrip is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjWindowsOS = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsGPONameSetting -Value $WindowsOSSet
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name WindowsRegValue -Value $WindowsOSReg 
    Add-Member -InputObject $newObjWindowsOS -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
    $fragWindowsOSVal += $newObjWindowsOS


################################################
#######  RECOMMENDED SECURITY SETTINGS  ########
###################  EDGE  #####################
################################################

<#
"TyposquattingChecker" , 
"Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","   ","

"Configure Edge TyposquattingChecker",

"Enabled","HKLM:\Software\Policies\Microsoft\Edge\",

"TyposquattingCheckerEnabled",

"This policy setting lets you configure whether to turn on Edge TyposquattingChecker. Edge TyposquattingChecker provides warning messages to help protect your users from potential typosquatting sites. By default Edge TyposquattingChecker is turned on.If you enable this policy Edge TyposquattingChecker is turned on.If you disable this policy Edge TyposquattingChecker is turned off.If you don't configure this policy Edge TyposquattingChecker is turned on but users can choose whether to use Edge TyposquattingChecker."}

#>

$EdgePolicies =[ordered]@{
#stig
"SSLVersionMin"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Minimum TLS version enabled","SSLVersionMin","tls1.2","HKLM:\Software\Policies\Microsoft\Edge\"
"SyncDisabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Disable synchronization of data using Microsoft sync services","SyncDisabled","1","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportBrowserSettings"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of browser settings","ImportBrowserSettings","0","HKLM:\Software\Policies\Microsoft\Edge\"
"DeveloperToolsAvailability"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Control where developer tools can be used","DeveloperToolsAvailability","2","HKLM:\Software\Policies\Microsoft\Edge\"
"PromptForDownloadLocation"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Ask where to save downloaded files","PromptForDownloadLocation","1","HKLM:\Software\Policies\Microsoft\Edge\"
"PreventSmartScreenPromptOverride"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","SmartScreen settings/Prevent bypassing Microsoft Defender SmartScreen prompts for sites","PreventSmartScreenPromptOverride","1","HKLM:\Software\Policies\Microsoft\Edge\"
"PreventSmartScreenPromptOverrideForFiles"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","SmartScreen settings/Prevent bypassing of Microsoft Defender SmartScreen warnings about downloads","PreventSmartScreenPromptOverrideForFiles","1","HKLM:\Software\Policies\Microsoft\Edge\"
"InPrivateModeAvailability"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Configure InPrivate mode availability","InPrivateModeAvailability","1","HKLM:\Software\Policies\Microsoft\Edge\"
"AllowDeletingBrowserHistory"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable deleting browser and download history","AllowDeletingBrowserHistory","0","HKLM:\Software\Policies\Microsoft\Edge\"
"BackgroundModeEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Continue running background apps after Microsoft Edge closes","BackgroundModeEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"DefaultPopupsSetting"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Content settings","Default pop-up window setting","DefaultPopupsSetting","2","HKLM:\Software\Policies\Microsoft\Edge\"
"NetworkPredictionOptions"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Enable network prediction","Don't predict network actions on any network connection","NetworkPredictionOptions","2","HKLM:\Software\Policies\Microsoft\Edge\"
"SearchSuggestEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable search suggestions","SearchSuggestEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportAutofillFormData"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of autofill form data","ImportAutofillFormData","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportCookies"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of cookies","ImportCookies","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportExtensions"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of extensions","ImportExtensions","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportHistory"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of browsing history","ImportHistory","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportHomepage"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of home page settings","ImportHomepage","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportOpenTabs"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of open tabs","ImportOpenTabs","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportPaymentInfo"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of payment info","ImportPaymentInfo","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportSavedPasswords"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of saved passwords","ImportSavedPasswords","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportSearchEngine"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of search engine settings","ImportSearchEngine","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ImportShortcuts"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow importing of shortcuts","ImportShortcuts","0","HKLM:\Software\Policies\Microsoft\Edge\"
"AutoplayAllowed"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow media autoplay for websites","AutoplayAllowed","0","HKLM:\Software\Policies\Microsoft\Edge\"
"EnableMediaRouter"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Cast\","Enable Google Cast","EnableMediaRouter","0","HKLM:\Software\Policies\Microsoft\Edge\"
"AutofillCreditCardEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable AutoFill for credit cards","AutofillCreditCardEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"AutofillAddressEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable AutoFill for addresses","AutofillAddressEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"PersonalizationReportingEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow personalization of ads, search and news by sending browsing history to Microsoft","PersonalizationReportingEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"DefaultGeolocationSetting"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Content settings/Default geolocation setting\","Don't allow any site to track users' physical location","DefaultGeolocationSetting","2","HKLM:\Software\Policies\Microsoft\Edge\"
"PasswordManagerEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Password manager and protection/Enable saving passwords to the password manager","PasswordManagerEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
#"IsolateOrigins"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable site isolation for every site","IsolateOrigins","1","HKLM:\Software\Policies\Microsoft\Edge\"
"SmartScreenEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\SmartScreen settings\","Configure Microsoft Defender SmartScreen","SmartScreenEnabled","1","HKLM:\Software\Policies\Microsoft\Edge\"
"SmartScreenPuaEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\SmartScreen settings\","Configure Microsoft Defender SmartScreen to block potentially unwanted apps","SmartScreenPuaEnabled","1","HKLM:\Software\Policies\Microsoft\Edge\"
"PaymentMethodQueryEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow websites to query for available payment methods","PaymentMethodQueryEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"AlternateErrorPagesEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Suggest similar pages when a webpage can't be found","AlternateErrorPagesEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"UserFeedbackAllowed"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow user feedback","UserFeedbackAllowed","0","HKLM:\Software\Policies\Microsoft\Edge\"
"EdgeCollectionsEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable the Collections feature","EdgeCollectionsEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"ConfigureShare"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Configure the Share experience\","Don't allow using the Share experience","ConfigureShare","1","HKLM:\Software\Policies\Microsoft\Edge\"
"BrowserGuestModeEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable guest mode","BrowserGuestModeEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"BuiltInDnsClientEnabled"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Use built-in DNS client","BuiltInDnsClientEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"SitePerProcess"="Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Enable site isolation for every site\","Enable site isolation for every site","SitePerProcess","1","HKLM:\Software\Policies\Microsoft\Edge\"
#MS
"InternetExplorerIntegrationReloadInIEModeAllowed" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Allow unconfigured sites to be reloaded in Internet Explorer mode","InternetExplorerIntegrationReloadInIEModeAllowed","0","HKLM:\Software\Policies\Microsoft\Edge\"
"TripleDESEnabled" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable 3DES cipher suites in TLS","TripleDESEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"BrowserLegacyExtensionPointsBlockingEnabled" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Enable browser legacy extension point blocking","BrowserLegacyExtensionPointsBlockingEnabled","1","HKLM:\Software\Policies\Microsoft\Edge\"
"InternetExplorerModeToolbarButtonEnabled" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Show the Reload in Internet Explorer mode button in the toolbar","InternetExplorerModeToolbarButtonEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"SharedArrayBufferUnrestrictedAccessAllowed" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Specifies whether SharedArrayBuffers can be used in a non cross-origin-isolated context","SharedArrayBufferUnrestrictedAccessAllowed","0","HKLM:\Software\Policies\Microsoft\Edge\"
"DisplayCapturePermissionsPolicyEnabled" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\","Specifies whether the display-capture permissions-policy is checked or skipped","DisplayCapturePermissionsPolicyEnabled","1","HKLM:\Software\Policies\Microsoft\Edge\"
"ExtensionInstallBlocklist" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Extensions\","Control which extensions cannot be installed","1","*","HKLM:\Software\Policies\Microsoft\Edge\ExtensionInstallBlocklist\"
"BasicAuthOverHttpEnabled" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\HTTP authentication\","Allow Basic authentication for HTTP","BasicAuthOverHttpEnabled","0","HKLM:\Software\Policies\Microsoft\Edge\"
"NativeMessagingUserLevelHosts" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Native Messaging\","Allow user-level native messaging hosts (installed without admin permissions)","NativeMessagingUserLevelHosts","0","HKLM:\Software\Policies\Microsoft\Edge\"
"InsecurePrivateNetworkRequestsAllowed" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Private Network Request Settings\","Specifies whether to allow insecure websites to make requests to more-private network endpoints","InsecurePrivateNetworkRequestsAllowed","0","HKLM:\Software\Policies\Microsoft\Edge\"
"TyposquattingChecker" = "Computer Configuration\Policies\Administrative Templates\Microsoft Edge\TyposquattingChecker settings\","Configure Edge TyposquattingChecker","TyposquattingCheckerEnabled","1","HKLM:\Software\Policies\Microsoft\Edge\"

}

$fragEdgeVal=@()

foreach ($EdgePolItems in $EdgePolicies.values)
{
$EdgeVal=@()
$getEdgeValue=@()
$EdgeDescrip=@()
$regpath=@()

$edgeGPOPath = $EdgePolItems[0]    #Computer Configuration\Policies\Administrative Templates\Microsoft Edge\Allow download restrictions\
$edgeGPOName = $EdgePolItems[1]    #Block potentially dangerous or unwanted downloads
$edgeRegName = $EdgePolItems[2]    #DownloadRestrictions
$edgeRegValue = $EdgePolItems[3]   #1
$edgeRegPath = $EdgePolItems[4]    #HKLM:\Software\Policies\Microsoft\Edge\
#$edgeHelp = $EdgePolItems[5]

if ($edgeRegValue -eq "1"){$edgeGPOValue = "Enabled"}
if ($edgeRegValue -eq "0"){$edgeGPOValue = "Disabled"}

$gpopath = $edgeGPOPath + $edgeGPOName
$regpath = $edgeRegPath + $edgeRegName

$getEdgePath = Get-Item $edgeRegPath -ErrorAction SilentlyContinue
$getEdgeValue = $getEdgePath.GetValue("$edgeRegName") 

    if ($getEdgeValue -eq "$edgeRegValue")
    {
        $EdgeSet = "$edgeGPOName is correctly set to $edgeGPOValue" 
        $EdgeReg = "<div title=$gpoPath>$regpath"
        $edgeTrue = "True"
    }
    else
    {
        $EdgeSet = "Warning $edgeGPOName is misconfigured with a value of $edgeGPOValue Warning" 
        $EdgeReg = "<div title=$gpoPath>$regpath"
        $edgeTrue = "False"
    }

    if ([string]::IsNullorEmpty($getEdgeValue) -eq $true){$EdgeSet = "DefaultGPO $edgeGPOName is not explicitly set in GPO and the default setting is applied DefaultGPO"}

    $newObjEdge = New-Object -TypeName PSObject
    Add-Member -InputObject $newObjEdge -Type NoteProperty -Name EdgeGPONameSetting -Value $EdgeSet
    Add-Member -InputObject $newObjEdge -Type NoteProperty -Name EdgeRegValue -Value $EdgeReg 
    Add-Member -InputObject $newObjEdge -Type NoteProperty -Name TrueIsCompliant -Value $edgeTrue 
    $fragEdgeVal += $newObjEdge

}


################################################
#######  RECOMMENDED SECURITY SETTINGS  ########
#################  Office  #####################
################################################

$OfficePolicies =[ordered]@{


#NO GPO
"DataConnectionWarnings"="MS Security - No GPO create Registry keys with preferences","DataConnectionWarnings","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","DataConnectionWarnings"
"RichDataConnectionWarnings"="MS Security - No GPO create Registry keys with preferences","RichDataConnectionWarnings","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","RichDataConnectionWarnings"
"WorkbookLinkWarnings"="MS Security - No GPO create Registry keys with preferences","WorkbookLinkWarnings","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","WorkbookLinkWarnings"
"ppPackagerPrompt"="MS Security - No GPO create Registry keys with preferences","WorkbookLinkWarnings","2","HKCU:\Software\Policies\Microsoft\Office\16.0\PowerPoint\Security","PackagerPrompt"
"wwPackagerPrompt"="MS Security - No GPO create Registry keys with preferences","WorkbookLinkWarnings","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security","PackagerPrompt"
"PackagerPrompt"="MS Security - No GPO create Registry keys with preferences","WorkbookLinkWarnings","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","PackagerPrompt"


#High Risk
#Office
"disableallactivex"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Disable All ActiveX","1","HKCU:\Software\Policies\Microsoft\Office\common\security","disableallactivex"
"includescreenshot"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center","Allow users to include screenshots and attachments when they submit feedback to Microsoft","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\feedback","includescreenshot"
#office dont share with MS
"updatereliabilitydata"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center","Automatically receive small updates to improve reliability","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Common","updatereliabilitydata"
"sendtelemetry"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center","Configure the level of client software diagnostic data sent by Office to Microsoft","3","HKCU:\Software\Policies\Microsoft\Office\common\clienttelemetry","sendtelemetry"
"shownfirstrunoptin"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center","Disable Opt-in Wizard on first run","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\general","shownfirstrunoptin"
"qmenable"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center","Enable Customer Experience Improvement Program","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Common","qmenable"
"enabled"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center","Allow users to submit feedback to Microsoft","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Feedback","enabled"
"sendcustomerdata"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Privacy\Trust Center","Send personal information","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Common","sendcustomerdata"
#lower risk
"uficontrols"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","ActiveX Control Initialization","6","HKCU:\Software\Policies\Microsoft\Office\Common\Security","uficontrols"
"allowvbaintranetreferences"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Allow VBA to load typelib references by path from untrusted intranet locations","0","HKCU:\Software\Policies\Microsoft\vba\Security","allowvbaintranetreferences"
"automationsecurity"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Automation Security","2","HKCU:\Software\Policies\Microsoft\Office\Common\Security","automationsecurity"
"disablestrictvbarefssecurity"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Disable additional security checks on VBA library references that may refer to unsafe locations on the local machine","0","HKCU:\Software\Policies\Microsoft\vba\Security","disablestrictvbarefssecurity"
"trustbar"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Disable all Trust Bar notifications for security issues","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\trustcenter","trustbar"
"defaultencryption12"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Encryption type for password protected Office 97-2003 files","Microsoft Enhanced RSA and AES Cryptographic Provider,AES 256,256","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Security","defaultencryption12"
"openxmlencryption"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Encryption type for password protected Office Open XML files","Microsoft Enhanced RSA and AES Cryptographic Provider,AES 256,256","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Security","openxmlencryption"
"loadcontrolsinforms"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Load Controls in Forms3","1","HKCU:\Software\Policies\Microsoft\vba\Security","loadcontrolsinforms"
"macroruntimescanscope"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Macro Runtime Scan Scope","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Security","macroruntimescanscope"
"drmencryptproperty"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings","Protect document metadata for rights managed Office Open XML Files","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Security","drmencryptproperty"
"allow user locations"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Security Settings\Trust Center","Allow mix of policy and user locations","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\Security\Trusted Locations","allow user locations"
"linkpublishingdisabled"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Server Settings","Disable the Office client from polling the SharePoint Server for published links","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Common\portal","linkpublishingdisabled"
"neverloadmanifests"="User Configuration\Policies\Administrative Templates\Microsoft Office 2016\Smart Documents (Word  Excel)","Disable Smart Document's use of manifests","1","HKCU:\Software\Policies\Microsoft\Office\Common\smart tag","neverloadmanifests"


#Access
"Accblockcontentexecutionfrominternet"="User Configuration\Policies\Administrative Templates\Microsoft Access 2016\Application Settings\Security\Trust Center","Block macros from running in Office files from the Internet","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Access\Security","blockcontentexecutionfrominternet"
"acdisabletrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Access 2016\Access Options\Security\Trust Center","Turn off trusted documents","1","HKCU:\software\policies\microsoft\office\16.0\access\security\trusted documents","disabletrusteddocuments"
"acdisablenetworktrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Access 2016\Excel Options\Security\Trust Center","Turn off Trusted Documents on the network","1","HKCU:\software\policies\microsoft\office\16.0\Access\security\trusted documents","disablenetworktrusteddocuments"
"allownetworklocations"="User Configuration\Policies\Administrative Templates\Microsoft Access 2016\Application Settings\Security\Trust Center\Trusted Locations","Allow Trusted Locations on the network","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Access\Security\Trusted Locations","allownetworklocations"


#word
"wwdontupdatelinks"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Advanced","Update automatic links at Open","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\options","dontupdatelinks"
"woblockcontentexecutionfrominternet"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center","Block macros from running in Office files from the Internet","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security","blockcontentexecutionfrominternet"
"vbawarnings"="User Configuration\Policies\Administrative Templates\Microsoft Access 2016\Application Settings\Security\Trust Center","VBA Macro Notification Settings","3","HKCU:\Software\Policies\Microsoft\Office\16.0\Access\Security","vbawarnings"
"wovbawarnings"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center","VBA Macro Notification Settings","3","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security","vbawarnings"
#When gpo is set to disabled the allowdde value is removed
"woallowdde"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center","Dynamic Data Exchange","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security","allowdde"
"wonotbpromptunsignedaddin"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center","Disable Trust Bar Notification for unsigned application add-ins and block them","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security","notbpromptunsignedaddin"
"worequireaddinsig"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center","Require that application add-ins are signed by Trusted Publisher","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security","requireaddinsig"
"woopeninprotectedview"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Set default file block behavior","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","openinprotectedview"
"Word2files"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word 2 and earlier binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Word2files"
"Word2000files"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word 2000 binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Word2000files"
"Word2003files"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word 2003 binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Word2003files"
"Word2007files"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word 2007 and later binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Word2007files"
"Word60files"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word 6.0 binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Word60files"
"Word95files"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word 95 binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Word95files"
"Word97files"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word 97 binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Word97files"
"Wordxpfiles"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\File Block Settings","Word XP binary documents and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\fileblock","Wordxpfiles"
#reg enable = 0 disable = 1
"woenableonload"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security","Turn off file validation","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\filevalidation","enableonload"
"wodisableinternetfilesinpv"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\Protected View","Do not open files from the Internet zone in Protected View","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\protectedview","disableinternetfilesinpv"
"wodisableunsafelocationsinpv"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\Protected View","Do not open files in unsafe locations in Protected View","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\protectedview","disableunsafelocationsinpv"
"wodisableattachmentsinpv"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\Protected View","Turn off Protected View for attachments opened from Outlook","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\protectedview","disableattachmentsinpv"
"wwdisableattachmentsinpv"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Powerpoint Options\Security\Trust Center\Protected View","Set document behaviour if file validation fails","0","HKCU:\Software\Policies\Microsoft\office\16.0\Word\security\filevalidation","openinprotectedview"
"showmarkupopensave"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security","Make hidden markup visible","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\options","showmarkupopensave"
"wwdisabletrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\PowerPoint Options\Security\Trust Center","Turn off trusted documents","1","HKCU:\software\policies\microsoft\office\16.0\Visio\security\trusted documents","disabletrusteddocuments"
"wwdisablenetworktrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\PowerPoint Options\Security\Trust Center","Turn off Trusted Documents on the network","1","HKCU:\software\policies\microsoft\office\16.0\Word\security\trusted documents","disablenetworktrusteddocuments"
"Wordbypassencryptedmacroscan"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center","Scan encrypted macros in Word Open XML documents","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security","Wordbypassencryptedmacroscan"
"woallownetworklocations"="User Configuration\Policies\Administrative Templates\Microsoft Word 2016\Word Options\Security\Trust Center\Trusted Locations","Allow Trusted Locations on the network","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Word\Security\Trusted Locations","allownetworklocations"

#excel
"enableblockunsecurequeryfiles"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\External Content","Always prevent untrusted Microsoft Query files from opening","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\external content","enableblockunsecurequeryfiles"
"disableddeserverlaunch"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\External Content","Don't allow Dynamic Data Exchange (DDE) server launch in Excel","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\external content","disableddeserverlaunch"
"disableddeserverlookup"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\External Content","Don't allow Dynamic Data Exchange (DDE) server lookup in Excel","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\external content","disableddeserverlookup"
"Execblockcontentexecutionfrominternet"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center","Block macros from running in Office files from the Internet","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","blockcontentexecutionfrominternet"
"notbpromptunsignedaddin"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center","Disable Trust Bar Notification for unsigned application add-ins and block them","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","notbpromptunsignedaddin"
"requireaddinsig"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center","Require that application add-ins are signed by Trusted Publisher","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","requireaddinsig"
"extensionhardening"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security","Force file extension to match file type","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","extensionhardening"
"dbasefiles"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","dBase III / IV files","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","dbasefiles"
"difandsylkfiles"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Dif and Sylk files","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","difandsylkfiles"
"xl2macros"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 2 macrosheets and add-in files","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl2macros"
"xl2worksheets"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 2 worksheets","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl2worksheets"
"xl3macros"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 3 macrosheets and add-in files","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl3macros"
"xl3worksheets"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 3 worksheets","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl3worksheets"
"xl4macros"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 4 macrosheets and add-in files","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl4macros"
"xl4workbooks"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 4 workbooks","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl4workbooks"
"xl4worksheets"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 4 worksheets","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl4worksheets"
"xl95workbooks"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 95 workbooks","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl95workbooks"
"xl9597workbooksandtemplates"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 95-97 workbooks and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl9597workbooksandtemplates"
"xl97workbooksandtemplates"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Excel 97-2003 workbooks and templates","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","xl97workbooksandtemplates"
"openinprotectedview"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Set default file block behavior","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","openinprotectedview"
"htmlandxmlssfiles"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\File Block Settings","Web pages and Excel 2003 XML spreadsheets","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\fileblock","htmlandxmlssfiles"
#reg enable = 0 disable = 1
"enableonload"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security","Turn off file validation","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\Filevalidation","enableonload"
"enabledatabasefileprotectedview"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\Protected View","Always open untrusted database files in Protected View","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\protectedview","enabledatabasefileprotectedview"
"disableinternetfilesinpv"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\Protected View","Do not open files from the Internet zone in Protected View","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\protectedview","disableinternetfilesinpv"
"disableunsafelocationsinpv"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\Protected View","Do not open files in unsafe locations in Protected View","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\protectedview","disableunsafelocationsinpv"
"disableattachmentsinpv"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\Protected View","Turn off Protected View for attachments opened from Outlook","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\protectedview","disableattachmentsinpv"
"exdisableattachmentsinpv"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Powerpoint Options\Security\Trust Center\Protected View","Set document behaviour if file validation fails","0","HKCU:\Software\Policies\Microsoft\office\16.0\excel\security\filevalidation","openinprotectedview"
"exdisabletrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center","Turn off trusted documents","1","HKCU:\software\policies\microsoft\office\16.0\excel\security\trusted documents","disabletrusteddocuments"
"exdisablenetworktrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center","Turn off Trusted Documents on the network","1","HKCU:\software\policies\microsoft\office\16.0\excel\security\trusted documents","disablenetworktrusteddocuments"
"donotloadpictures"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Advanced\Web Options...\General","Load pictures from Web pages not created in Excel","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\internet","donotloadpictures"
"disableautorepublish"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Save","Disable AutoRepublish","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\options","disableautorepublish"
"disableautorepublishwarning"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Save","Do not show AutoRepublish warning alert","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\options","disableautorepublishwarning"
"Excelbypassencryptedmacroscan"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security","Scan encrypted macros in Excel Open XML workbooks","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","Excelbypassencryptedmacroscan"
"webservicefunctionwarnings"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security","WEBSERVICE Function Notification Settings","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","webservicefunctionwarnings"
"xl4macrooff"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center","Prevent Excel from running XLM macros","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security","xl4macrooff"
"Exceallownetworklocations"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Security\Trust Center\Trusted Locations","Allow Trusted Locations on the network","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\Security\Trusted Locations","allownetworklocations"
"extractdatadisableui"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Data Recovery","Do not show data extraction options when opening corrupt workbooks","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\options","extractdatadisableui"
#reg enable = 0 disable = 1
"fupdateext_78_1"="User Configuration\Policies\Administrative Templates\Microsoft Excel 2016\Excel Options\Advanced","Ask to update automatic links","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Excel\options\binaryoptions","fupdateext_78_1"

#powerpoint
"blockcontentexecutionfrominternet"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center","Block macros from running in Office files from the Internet","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security","blockcontentexecutionfrominternet"
"ppvbawarnings"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center","VBA Macro Notification Settings","3","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security","vbawarnings"
"ppnotbpromptunsignedaddin"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center","Disable Trust Bar Notification for unsigned application add-ins and block them","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security","notbpromptunsignedaddin"
"pprequireaddinsig"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center","Require that application add-ins are signed by Trusted Publisher","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security","requireaddinsig"
"binaryfiles"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center\File Block Settings","PowerPoint 97-2003 presentations  shows  templates and add-in files","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security\fileblock","binaryfiles"
"ppopeninprotectedview"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center\File Block Settings","Set default file block behavior","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security\fileblock","openinprotectedview"
#reg enable = 0 disable = 1
"ppenableonload"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security","Turn off file validation","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security\filevalidation","enableonload"
"runprograms"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security","Run Programs","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security","runprograms"
"ppdisableinternetfilesinpv"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center\Protected View","Do not open files from the Internet zone in Protected View","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security\protectedview","disableinternetfilesinpv"
"ppdisableunsafelocationsinpv"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center\Protected View","Do not open files in unsafe locations in Protected View","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security\protectedview","disableunsafelocationsinpv"
"ppdisableattachmentsinpv"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center\Protected View","Turn off Protected View for attachments opened from Outlook","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security\protectedview","disableattachmentsinpv"
"pdisableattachmentsinpv"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center\Protected View","Set document behaviour if file validation fails","0","HKCU:\Software\Policies\Microsoft\office\16.0\Powerpoint\security\filevalidation","openinprotectedview"
"markupopensave"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\PowerPoint Options\Security","Make hidden markup visible","1","HKCU:\Software\Policies\Microsoft\Office\16.0\powerpoint\options","markupopensave"
"ppdisabletrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\PowerPoint Options\Security\Trust Center","Turn off trusted documents","1","HKCU:\software\policies\microsoft\office\16.0\Powerpoint\security\trusted documents","disabletrusteddocuments"
"ppdisablenetworktrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\PowerPoint Options\Security\Trust Center","Turn off Trusted Documents on the network","1","HKCU:\software\policies\microsoft\office\16.0\Powerpoint\security\trusted documents","disablenetworktrusteddocuments"
#reg enable = 0 disable = 1
"powerpointbypassencryptedmacroscan"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security","Scan encrypted macros in PowerPoint Open XML presentations","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security","powerpointbypassencryptedmacroscan"
"ppallownetworklocations"="User Configuration\Policies\Administrative Templates\Microsoft PowerPoint 2016\Powerpoint Options\Security\Trust Center\Trusted Locations","Allow Trusted Locations on the network","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Powerpoint\Security\Trusted Locations","allownetworklocations"

#outlook
"authenticationservice"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Account Settings\Exchange","Authentication with Exchange Server","16","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","authenticationservice"
"enablerpcencryption"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Account Settings\Exchange","Enable RPC encryption","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\rpc","enablerpcencryption"
"publicfolderscript"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Outlook Options\Other\Advanced","Do not allow Outlook object model scripts to run for public folders","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","publicfolderscript"
"sharedfolderscript"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Outlook Options\Other\Advanced","Do not allow Outlook object model scripts to run for shared folders","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","sharedfolderscript"
"msgformat"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Outlook Options\Other\Advanced","Use Unicode format when dragging e-mail message to file system","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\options\general","msgformat"
"junkmailprotection"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Outlook Options\Preferences\Junk E-mail","Junk E-mail protection level","3","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\options\mail","junkmailprotection"
"allowactivexoneoffforms"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security","Allow Active X One Off Forms","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","allowactivexoneoffforms"
"disallowattachmentcustomization"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security","Prevent users from customizing attachment security settings","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook","disallowattachmentcustomization"
"internet"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Automatic Picture Download Settings","Include Internet in Safe Zones for Automatic Picture Download","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\options\mail","internet"
"minenckey"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Cryptography","Minimum encryption settings","168","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","minenckey"
"warnaboutinvalid"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Cryptography","Signature Warning","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","warnaboutinvalid"
"usecrlchasing"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Cryptography\Signature Status dialog box","Retrieving CRLs (Certificate Revocation Lists)","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","usecrlchasing"
"adminsecuritymode"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings","Outlook Security Mode","3","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","adminsecuritymode"
"allowuserstolowerattachments"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Attachment Security","Allow users to demote attachments to Level 2","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","allowuserstolowerattachments"
"showlevel1attach"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Attachment Security","Display Level 1 attachments","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","showlevel1attach"
"fileextensionsremovelevel1"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Attachment Security","Remove file extensions blocked as Level 1",";","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","fileextensionsremovelevel1"
"fileextensionsremovelevel2"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Attachment Security","Remove file extensions blocked as Level 2",";","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","fileextensionsremovelevel2"
"enableoneoffformscripts"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Custom Form Security","Allow scripts in one-off Outlook forms","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","enableoneoffformscripts"
"promptoomcustomaction"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Custom Form Security","Set Outlook object model custom actions execution prompt","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","promptoomcustomaction"
"promptoomaddressbookAccess"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Programmatic Security","Configure Outlook object model prompt when Accessing an address book","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","promptoomaddressbookAccess"
"promptoomformulaAccess"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Programmatic Security","Configure Outlook object model prompt When Accessing the Formula property of a UserProperty object","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","promptoomformulaAccess"
"promptoomsaveas"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Programmatic Security","Configure Outlook object model prompt when executing Save As","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","promptoomsaveas"
"promptoomaddressinformationAccess"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Programmatic Security","Configure Outlook object model prompt when reading address information","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","promptoomaddressinformationAccess"
"promptoommeetingtaskrequestresponse"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Programmatic Security","Configure Outlook object model prompt when responding to meeting and task requests","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","promptoommeetingtaskrequestresponse"
"promptoomsend"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Security Form Settings\Programmatic Security","Configure Outlook object model prompt when sending mail","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","promptoomsend"
"junkmailenablelinks"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Trust Center","Allow hyperlinks in suspected phishing e-mail messages","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\options\mail","junkmailenablelinks"
"level"="User Configuration\Policies\Administrative Templates\Microsoft Outlook 2016\Security\Trust Center","Security setting for macros","3","HKCU:\Software\Policies\Microsoft\Office\16.0\Outlook\Security","level"

#publisher
"puvbawarnings"="User Configuration\Policies\Administrative Templates\Microsoft Publisher 2016\Security\Trust Center","VBA Macro Notification Settings","3","HKCU:\Software\Policies\Microsoft\Office\16.0\publisher\Security","vbawarnings"
"punotbpromptunsignedaddin"="User Configuration\Policies\Administrative Templates\Microsoft Publisher 2016\Security\Trust Center","Disable Trust Bar Notification for unsigned application add-ins","1","HKCU:\Software\Policies\Microsoft\Office\16.0\publisher\Security","notbpromptunsignedaddin"
"purequireaddinsig"="User Configuration\Policies\Administrative Templates\Microsoft Publisher 2016\Security\Trust Center","Require that application add-ins are signed by Trusted Publisher","1","HKCU:\Software\Policies\Microsoft\office\16.0\publisher\security","requireaddinsig"
"puautomationsecuritypublisher"="User Configuration\Policies\Administrative Templates\Microsoft Publisher 2016\Security","Publisher Automation Security Level","2","HKCU:\Software\Policies\Microsoft\Office\Common\Security","automationsecuritypublisher"

#Project
"prvbawarnings"="User Configuration\Policies\Administrative Templates\Microsoft Project 2016\Project Options\Security\Trust Center","VBA Macro Notification Settings","3","HKCU:\Software\Policies\Microsoft\Office\16.0\MS Project\Security","vbawarnings"
"prnotbpromptunsignedaddin"="User Configuration\Policies\Administrative Templates\Microsoft Project 2016\Project Options\Security\Trust Center","Disable Trust Bar Notification for unsigned application add-ins and block them","1","HKCU:\Software\Policies\Microsoft\Office\16.0\MS Project\Security","notbpromptunsignedaddin"
"prrequireaddinsig"="User Configuration\Policies\Administrative Templates\Microsoft Project 2016\Project Options\Security\Trust Center","Require that application add-ins are signed by Trusted Publisher","1","HKCU:\Software\Policies\Microsoft\Office\16.0\MS Project\Security","requireaddinsig"
"prallownetworklocations"="User Configuration\Policies\Administrative Templates\Microsoft Project 2016\Project Options\Security\Trust Center","Allow Trusted Locations on the network","0","HKCU:\Software\Policies\Microsoft\Office\16.0\MS Project\Security\Trusted Locations","allownetworklocations"

#visio
"viblockcontentexecutionfrominternet"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center","Block macros from running in Office files from the Internet","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security","blockcontentexecutionfrominternet"
"vivbawarnings"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center","VBA Macro Notification Settings","3","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security","vbawarnings"
"vinotbpromptunsignedaddin"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center","Disable Trust Bar Notification for unsigned application add-ins and block them","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security","notbpromptunsignedaddin"
"virequireaddinsig"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center","Require that application add-ins are signed by Trusted Publisher","1","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security","requireaddinsig"
"Visio2000files"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center\File Block Settings","Visio 2000-2002 Binary Drawings  Templates and Stencils","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security\fileblock","Visio2000files"
"Visio2003files"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center\File Block Settings","Visio 2003-2010 Binary Drawings  Templates and Stencils","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security\fileblock","Visio2003files"
"Visio50andearlierfiles"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center\File Block Settings","Visio 5.0 or earlier Binary Drawings  Templates and Stencils","2","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security\fileblock","Visio50andearlierfiles"
"vvdisabletrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\PowerPoint Options\Security\Trust Center","Turn off trusted documents","1","HKCU:\software\policies\microsoft\office\16.0\Visio\security\trusted documents","disabletrusteddocuments"
"vvdisablenetworktrusteddocuments"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\PowerPoint Options\Security\Trust Center","Turn off Trusted Documents on the network","1","HKCU:\software\policies\microsoft\office\16.0\Visio\security\trusted documents","disablenetworktrusteddocuments"
"viallownetworklocations"="User Configuration\Policies\Administrative Templates\Microsoft Visio 2016\Visio Options\Security\Trust Center","Allow Trusted Locations on the network","0","HKCU:\Software\Policies\Microsoft\Office\16.0\Visio\Security\Trusted Locations","allownetworklocations"

#Lync
"enablesiphighsecuritymode"="Computer Configuration\Policies\Administrative Templates\Skype for Business 2016\Microsoft Lync Feature Policies","Configure SIP security mode","0","HKLM:\Software\Policies\Microsoft\Office\16.0\Lync","enablesiphighsecuritymode"
"disablehttpconnect"="Computer Configuration\Policies\Administrative Templates\Skype for Business 2016\Microsoft Lync Feature Policies","Disable HTTP fallback for SIP connection","1","HKLM:\Software\Policies\Microsoft\Office\16.0\Lync","disablehttpconnect"

}


$fragOfficeVal=@()

foreach ($OfficePolItems in $OfficePolicies.values)
{
    $OfficeVal=@()
    $getOfficeValue=@()
    $OfficeDescrip=@()
    $regPath=@()

    $OfficeGPOPath = $OfficePolItems[0]
    $OfficeGPOName = $OfficePolItems[1]
    $OfficeRegValue = $OfficePolItems[2]
    $OfficeRegPath = $OfficePolItems[3]
    $OfficeRegName = $OfficePolItems[4]
    $OfficeHelp = $OfficePolItems[5]

    # write-host $OfficeGPOPath -ForegroundColor Red
    # write-host $OfficeGPOName -ForegroundColor Red
    # write-host $OfficeRegPath  -ForegroundColor Green
    # write-host $OfficeRegName -ForegroundColor Yellow
    # Write-Host $OfficeRegValue -ForegroundColor White

    #MS cant decided if 1 is enabled or disabled, compounded with double negs and positives, so this is of little use, updated the above table with the correct numerical values
    #if ($OfficeRegValue -eq "Enabled"){$OfficeRegValue = "1"}
    #if ($OfficeRegValue -eq "Disabled"){$OfficeRegValue = "0"}

    $gpopath = $OfficeGPOPath +"\"+ $OfficeGPOName
    $regPath = $OfficeRegPath  +"\"+ $OfficeRegName

    $getOfficePath = Get-Item $OfficeRegPath -ErrorAction SilentlyContinue
    $getOfficeValue = $getOfficePath.GetValue("$OfficeRegName") 

    #defaulf behaviour is disabled even with gpo set so reg value is not created
    if ($OfficeRegName -eq "allowdde" -and $getOfficeValue -eq $null){$getOfficeValue = "0"}
    if ($OfficeRegName -eq "runprograms" -and $getOfficeValue -eq $null){$getOfficeValue = "0"}

   # Write-Host $getOfficeValue -ForegroundColor Cyan

        if ($getOfficeValue -eq "$OfficeRegValue")
        {
            $OfficeSet = "$OfficeGPOName is set correctly with a value of $getOfficeValue" 
            $OfficeReg = "<div title=$gpoPath>$regPath"
            $trueFalse = "True"
        }
        else
        {
            $OfficeSet = "Warning $OfficeGPOName is not set or has the wrong setting with value of $getOfficeValue Warning" 
            $OfficeReg = "<div title=$gpoPath>$regPath"
            $trueFalse = "False"
        }

        if ([string]::IsNullorEmpty($getOfficeValue) -eq $true){$OfficeSet = "DefaultGPO $OfficeGPOName is not explicitly set in GPO and the default setting is applied DefaultGPO"}

        $newObjOffice = New-Object -TypeName PSObject
        Add-Member -InputObject $newObjOffice -Type NoteProperty -Name OfficeGPONameSetting -Value $OfficeSet
        Add-Member -InputObject $newObjOffice -Type NoteProperty -Name OfficeRegValue -Value $OfficeReg 
        Add-Member -InputObject $newObjOffice -Type NoteProperty -Name TrueIsCompliant -Value $trueFalse
        $fragOfficeVal += $newObjOffice

}

################################################
#################  SUMMARY  ####################
################################################
   if ($BiosUEFI -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#BiosUEFI">Out of date BIOS or UEFI</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   }

   if ($HotFix -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#Hotfix">Windows Updates are out of date</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   }

   if ($fragInstaApps -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#InstalledApps">Out of date Applications</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   }
    
    if ($MsinfoClixml -eq $null)
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#vbs">Virtualised Based Security</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragCode -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#HECI">Hypervisor Enforced Code Integrity</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragBitLocker -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#Bitlockerisnotenabled">Bitlocker</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Very High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragkernelModeVal -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#KernelMode">Kernel-mode Hardware-enforced Stack Protection is not enabled</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragPreAuth -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#PreAuth">There are AD accounts that dont Pre-Authenticated</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }
 

    if ($fragNeverExpires -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#PassExpire">There are AD accounts that dont Expire their Passwords</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragLSAPPL -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#LSA">LSA is Disabled</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragCredGuCFG -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#CredGuard">Credential Guard is Disabled</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

   if ($getFw -like "*Inbound*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#InFirewall">There are Firewall rules Allowing Inbound Firewall Traffic</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   } 

    if ($fragWDigestULC -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#WDigest">WDigest is Enabled</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragLapsPwEna -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#LAPS">LAPS is not Configured</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($FragAVStatus -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#AV">There are issues with AntiVirus</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

   if ($fragPSPass -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#ProcPW">Processes have been found that contain Embedded Passwords</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   }

   if ($fragFilePass -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#FilePW">Files have been found that contain Embedded Passwords</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   }  

   if ($fragRegPasswords -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#RegPW">Passwords in the Registry</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragRegPasswords -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#PSHistory">Passwords in Powershell History</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   }

    if ($fragAutoLogon -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#AutoLogon">The Registry contains Autologon credentials</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragAutoRunsVal -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#AutoRuns">AutoRuns Requires Review</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
    }
    $frag_AutoRuns


    if ($fragPCElevate -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#SoftElevation">Installation of Software will Auto Elevate</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
    }

    if ($fragDLLSafe -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#DLLSafe">DLL Safe Search is not Enabled</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
    }

   if ($fragDllNotSigned -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#DLLSign">Dlls that are Not Signed and User Permissions Allow Write</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragDLLHijack -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#DLLHigh">Loaded  dlls that are Vulnerable to dll Hijacking by the User</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragAuthCodeSig -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#AuthentiCode">Found Authenticode Signature Hash Mismatch</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragCertificates -like "*Warning*" -or $fragCertificates -like "*selfsigned*" -or $fragCertificates -like "*Expired*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#Certs">Installed Certificate Issues</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   }

   if ($fragCipherSuit -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#CipherSuites">SHA1 Cipher Suites are Supported</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   }

   if ($fragUnQuoted -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#unquoted">Unquoted Paths Vulnerability</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Very High Risk"
       $fragSummary += $newObjSummary
   }   

   if ($fragReg -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#RegWrite">Registry Keys that are Writeable</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragsysFold -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#SysDirWrite">Program Files or Windows Directories are Writeable</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium to High Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragcreateSysFold -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#sysDirExe">Users can both Execute and Write to Program Files or Windows Directories</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium to High Risk"
       $fragSummary += $newObjSummary
   }

   if ($fragwFile -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#sysFileWrite">File in Program Files or Windows Directories are Writeable</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragwFold -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#nonSysDirWrite">Directories that are Writeable and Non System</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragShare -like "*C$*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#shares">There are System Shares available</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Informational"
       $fragSummary += $newObjSummary
   }

   if ($fragLegNIC -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#LegNetProt">Legacy Network Protocols are Enabled</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium to High Risk"
       $fragSummary += $newObjSummary
   } 

   if ($SchedTaskPerms -ne $null)
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#schedDir">Scheduled Tasks with Scripts and Permissions are Weak</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   } 

      if ($SchedTaskListings -ne $null)
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#schedTask">Scheduled Tasks Contain Base64 or Commands that Require Reviewing</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   } 


    if ($DriverQuery -like "*warning*")
    {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#drivers">There are Drivers that Arent Signed</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
    }

      if ($fragSecOptions -like "*warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#secOptions">Security Options that Pevent MitM Attack are Enabled</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "High Risk"
       $fragSummary += $newObjSummary
   } 

   if ($fragASR -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#asr">Attack Surface Reduction GPOs have not been Set</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   }

      if ($fragWindowsOSVal -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#WinSSLF">Windows Hardening Policies Recommended by Microsoft are Missing</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   }

   if ($fragEdgeVal -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#EdgeSSLF">Edge Hardening Policies Recommended by Microsoft are Missing</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   }


   if ($fragOfficeVal -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#OfficeSSLF">Office Hardening Policies Recommended by Microsoft are Missing</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Medium Risk"
       $fragSummary += $newObjSummary
   }
       
   #if ($fragFWProfile| % {$_.inbound -eq "Allow"})
    if ($fragFWProfile -like "*Warning*")
   {
       $newObjSummary = New-Object psObject
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Vulnerability -Value '<a href="#FirewallProf">The Firewall Profile Allows Inbound Traffic</a>'
       Add-Member -InputObject $newObjSummary -Type NoteProperty -Name Risk -Value "Very High Risk"
       $fragSummary += $newObjSummary      
   }

################################################
##########  HTML GENERATION  ###################
################################################

#Tenaka and Default Colour scheme of dark brown and copper text
#B87333 = copper
#250F00 = root beer
#181818 = alt background 
#4682B4 = Blue dark pastel
#FF4040 = Red pastel
#DBDBDB = grey
#766A6A = Dark Grey with hint of beige
#A88F7E = mouse
#<font color="red"> <font>

#Blue - dark
#FFF9EC = copper
#28425F = root beer
#06273A = alt background 
#FFEEE0 = Blue dark pastel
#FF4040 = Red pastel
#FFFEF8 = grey
#766A6A = Dark Grey with hint of beige
#A88F7E = mouse
#<font color="red"> <font>

#Light
#79253D = copper
#EBEAE7 = root beer
#F4F2EC = alt background 
#FFEEE0 = Blue dark pastel
#FF4040 = Red pastel
#D0D0D0 = grey
#766A6A = Dark Grey with hint of beige
#A88F7E = mouse
#<font color="red"> <font>

    #$VulnReport = "C:\SecureReport"
    #$OutFunc = "scheme" 
                
    #$tpScheme = Test-Path "C:\SecureReport\output\$OutFunc\"
    #$SchemePath = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.txt"

    #$Scheme = Get-Content $SchemePath

#$font = "helvetica"
$font = "Raleway"
$FontTitle_H1 = "175%"
$FontSub_H2 = "115%"
$FontBody_H3 = "105%"
$FontHelps_H4 = "100%"

if ($Scheme -eq "Tenaka")
{
$titleCol = "#4682B4"

#HTML GENERATOR CSS
$style = @"
    <Style>
    body
    {
        background-color:#250F00; 
        color:#B87333;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word
    }
    table
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#B87333;
        border-collapse:collapse;
        width:auto
    }
    h1
    {
        background-color:#250F00; 
        color:#B87333;
        font-size:$FontTitle_H1;
        font-family:$font;
        margin:0,0,10px,0;
        Word-break:normal; 
        Word-wrap:break-Word
    }
    h2
    {
        background-color:#250F00; 
        color:#4682B4
        font-size:$FontSub_H2;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        font-weight: normal;  
        Word-wrap:break-Word
    }
    h3
    {
        background-color:#250F00; 
        color:#B87333;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal;
        width:auto
    }
    h4
    {
        background-color:#250F00; 
        color:#766A6A;
        font-size:$FontHelps_H4;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal
    }
    th
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#B87333;
        background-color:#250F00
    }
    td
    {
        border-width: 1px;
        padding:7px;
        font-size:$FontBody_H3;
        font-family:$font;
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

    a:link {
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:visited {
    color:#ff9933;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:hover {
    color:#B87333;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:active {
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:link {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:visited {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:hover {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:active {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    details > summary {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    details > p {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    </Style>
"@
}

elseif ($Scheme -eq "Dark")
{
$titleCol = "#4682B4"

#HTML GENERATOR CSS
$style = @"
    <Style>
    body
    {
        background-color:#06273A; 
        color:#FFF9EC;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word
    }
    table
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#FFF9EC;
        border-collapse:collapse;
        width:auto
    }
    h1
    {
        background-color:#06273A; 
        color:#FFF9EC;
        font-size:$FontTitle_H1;
        font-family:$font;
        margin:0,0,10px,0;
        Word-break:normal; 
        Word-wrap:break-Word
    }
    h2
    {
        background-color:#06273A; 
        color:#4682B4;
        font-size:$FontSub_H2;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        font-weight: normal;  
        Word-wrap:break-Word
    }
    h3
    {
        background-color:#06273A; 
        color:#FFF9EC;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal;
        width:auto
    }
    h4
    {
        background-color:#06273A; 
        color:#766A6A;
        font-size:$FontHelps_H4;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal
    }
    th
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#FFF9EC;
        background-color:#06273A
    }
    td
    {
        border-width: 1px;
        padding:7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid; 
        border-style: #FFF9EC
    }
    tr:nth-child(odd) 
    {
        background-color:#06273A;
    }
    tr:nth-child(even) 
    {
        background-color:#28425F;
    }

    a:link {
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:visited {
    color:#ff9933;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:hover {
    color:#FFF9EC;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:active {
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }
    
    a.class1:link {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:visited {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:hover {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:active {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    details > summary {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    details > p {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    </Style>
"@
}

elseif ($Scheme -eq "Light")
{
$titleCol = "#000000"

#HTML GENERATOR CSS
$style = @"
    <Style>
    body
    {
        background-color:#EBEAE7; 
        color:#79253D;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word
    }
    table
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#FFF9EC;
        border-collapse:collapse;
        width:auto
    }
    h1
    {
        background-color:#EBEAE7 
        color:#79253D;
        font-size:$FontTitle_H1;
        font-family:$font;
        margin:0,0,10px,0;
        Word-break:normal; 
        Word-wrap:break-Word
    }
    h2
    {
        background-color:#EBEAE7; 
        color:#000000;
        font-size:$FontSub_H2;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        font-weight: normal;  
        Word-wrap:break-Word
    }
    h3
    {
        background-color:#EBEAE7; 
        color:#79253D;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal;
        width:auto
    }
    h4
    {
        background-color:#EBEAE7; 
        color:#877F7D;
        font-size:$FontHelps_H4;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal
    }
    th
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#79253D;
        background-color:#EBEAE7
    }
    td
    {
        border-width: 1px;
        padding:7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid; 
        border-style: #79253D
    }
    tr:nth-child(odd) 
    {
        background-color:#EBEAE7;
    }
    tr:nth-child(even) 
    {
        background-color:#F4F2EC;
    }

    a:link {
    color:#000000;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:visited {
    color:#ff9933;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:hover {
    color:#79253D;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:active {
    color:#000000;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:link {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:visited {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:hover {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:active {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    details > summary {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    details > p {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    </Style>
"@
}

elseif ($Scheme -eq "Grey")
{
$titleCol = "#D3BAA9"

#HTML GENERATOR CSS
$style = @"
    <Style>
    
    body
    {
        background-color:#454545; 
        color:#D3BAA9;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word
    }
    table
    {
        border-width: 1px;
        padding: 7px;
        border-style: solid;
        border-color:#D3BAA9;
        border-collapse:collapse;
        width:auto
    }
    h1
    {
        background-color:#454545; 
        color:#D3BAA9;
        font-size:$FontTitle_H1;
        font-family:$font;
        margin:0,0,10px,0;
        Word-break:normal; 
        Word-wrap:break-Word
    }
    h2
    {
        background-color:#454545; 
        color:#D3BAA9;
        font-size:$FontSub_H2;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        font-weight: normal;  
        Word-wrap:break-Word
    }
    h3
    {
        background-color:#454545; 
        color:#A88F7E;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal;
        width:auto
    }
        h4
    {
        background-color:#454545; 
        color:#D3BAA9;
        font-size:$FontHelps_H4;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal
    }
    th
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#D3BAA9;
        background-color:#454545
    }
    td
    {
        border-width: 1px;
        padding:7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid; 
        border-style: #D3BAA9
    }
    tr:nth-child(odd) 
    {
        background-color:#404040;
    }
    tr:nth-child(even) 
    {
        background-color:#4d4d4d;
    }

    a:link {
    color:#D3BAA9;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:visited {
    color:#ff9933;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:hover {
    color:#A88F7E;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:active {
    color:#D3BAA9;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }  
    a.class1:link {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:visited {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:hover {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:active {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    details > summary {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    details > p {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }
      

    </Style>
"@
}

#4682B4 - blue
#FFF9EC - white

else 
{#Dark Theme

$titleCol = "#4682B4"

#HTML GENERATOR CSS
$style = @"
    <Style>
    body
    {
        background-color:#06273A; 
        color:#FFF9EC;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word
    }
    table
    {   
        border-width: 1px;
        padding: 7px;
        border-style: solid;
        border-color:#FFF9EC;
        border-collapse:collapse;
        width:auto
    }
    h1
    {
        background-color:#06273A; 
        color:#FFF9EC;
        font-size:$FontTitle_H1;
        font-family:$font;
        margin:0,0,10px,0;
        Word-break:normal; 
        Word-wrap:break-Word
    }
    h2
    {
        background-color:#06273A; 
        color:#4682B4;
        font-size:$FontSub_H2;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal;
        font-weight: normal;         
        Word-wrap:break-Word
    }
    h3
    {
        background-color:#06273A; 
        color:#FFF9EC;
        font-size:$FontBody_H3;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal;
        width:auto
    }
    h4
    {
        background-color:#06273A; 
        color:#9f9696;
        font-size:$FontHelps_H4;
        font-family:$font;
        margin:0,0,10px,0; 
        Word-break:normal; 
        Word-wrap:break-Word;
        font-weight: normal
    }
    th
    {
        border-width: 1px;
        padding: 7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid;
        border-color:#FFF9EC;
        background-color:#06273A
    }
    td
    {
        border-width: 1px;
        padding:7px;
        font-size:$FontBody_H3;
        font-family:$font;
        border-style: solid; 
        border-style: #FFF9EC
    }
    tr:nth-child(odd) 
    {
        background-color:#06273A;
    }
    tr:nth-child(even) 
    {
        background-color:#28425F;
    }

    a:link {
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:visited {
    color:#ff9933;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:hover {
    color:#FFF9EC;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a:active {
    color:#D3BAA9;
    font-size:$FontSub_H2;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    } 

    a.class1:link {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:visited {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:hover {
    color:#FFF9EC;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    a.class1:active {
    color:#4682B4;
    font-size:$FontBody_H4;
    font-family:$font;
    background-color: transparent;
    text-decoration: none;
    }

    details > summary {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    details > p {
    background-color:#06273A; 
    color:#4682B4;
    font-size:$FontSub_H2;
    font-family:$font;
    margin:0,0,10px,0; 
    Word-break:normal; 
    Word-wrap:break-Word
    }

    </Style>
"@
}

$VulnReport = "C:\SecureReport"
$OutFunc = "SystemReport"  
$tpSec10 = Test-Path "C:\SecureReport\output\$OutFunc\"
    
if ($tpSec10 -eq $false)
    {
        New-Item -Path "C:\SecureReport\output\$OutFunc\" -ItemType Directory -Force
    }

$working = "C:\SecureReport\output\$OutFunc\"
$NonFilteredReport = "C:\SecureReport\output\$OutFunc\" + "NonFilteredReport.html"
$Report = "C:\SecureReport\output\$OutFunc\" + "$OutFunc.html"

################################################
##########  HELPS AND DESCRIPTIONS  ############
################################################

    $Intro = "Thanks for using the vulnerability report written by <a href=`"https://www.tenaka.net`" class=`"class1`">Tenaka.net</a>, please show your support and visit my site, it's non-profit and Ad-free. <br> <br>Any issues with the report's accuracy please do let me know and I'll get it fixed asap. The results in this report are a guide and not a guarantee that the tested system is not without further defects or vulnerability.<br>
    <br>The tests focus on known and common issues with Windows that can be exploited by an attacker. Each section contains a small snippet to provide some context, follow the links for further detail.<br><br>The html output can be imported into Excel for further analysis and uses the True and False values as a drop-down filter.<br>Open Excel, Data, Import from Web. Enter the file path in the following format file:///C:/SecureReport/NameOfReport.htm, then Select multiple items and click on Load and select 'Load To', click on Table.<br><br>Further support for this report can be found @ <a href=`"https://www.tenaka.net/windowsclient-vulnscanner`" class=`"class1`">Vulnerability Scanner</a>"

    #$Intro2 = "The results in this report are a guide and not a guarantee that the tested system is not without further defect or vulnerability.<br>The tests focus on known and common issues with Windows that can be exploited by an attacker. Each section contains a small snippet to provide some context, follow the links for further detail.<br><br>The html output can be imported into Excel for further analysis and uses the True and False values as a drop-down filter.<br><br>Open Excel, Data, Import from Web. Enter the file path in the following format file:///C:/SecureReport/NameOfReport.htm, then Select multiple items and click on Load and select 'Load To', click on Table.<br>"

    $Finish = "This script has been provided by Tenaka.net, if it's beneficial, please provide feedback and any additional feature requests gratefully received. "

    $descripBitlocker = "TPM and Bitlocker protect against offline attack from usb and mounting the local Windows system then Accessing the local data. 'TPM and Pin' enhances Bitlocker by preventing LPC Bus (Low Pin Count) bypasses of Bitlocker with TPM. <br> <br>Further information can be found @ <a href=`"https://www.tenaka.net/bitlocker`" class=`"class1`">Bitlocker</a>"

    $descripVirt = "Virtualization-based security (VBS), isolates core system resources to create secure regions of memory. Enabling VBS allows for Hypervisor-Enforced Code Integrity (HVCI), Device Guard and Credential Guard. <br> <br>Further information can be found @ https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-vbs<br> <br><a href=`"https://www.tenaka.net/deviceguard-vs-rce`" class=`"class1`">WDAC vs RCE</a> and <a href=`"https://www.tenaka.net/pass-the-hash`" class=`"class1`">Pass the Hash</a> <br><br>Secure Boot is a security standard to ensure only trusted OEM software is allowed at boot. At startup the UEFi and boot software's digital signatures are validated preventing rootkits. <br> <br>More on Secure Boot can be found here @ https://media.defense.gov/2020/Sep/15/2002497594/-1/-1/0/CTR-UEFI-SECURE-BOOT-CUSTOMIZATION-20200915.PDF/CTR-UEFI-SECURE-BOOT-CUSTOMIZATION-20200915.PDF<br>"

    $descripVirt2 = "Virtualization-based security (VBS), isolates core system resources to create secure regions of memory. Enabling VBS allows for Hypervisor-Enforced Code Integrity (HVCI), Device Guard and Credential Guard. <br> <br>Further information can be found @ https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-vbs<br> <br><a href=`"https://www.tenaka.net/deviceguard-vs-rce`" class=`"class1`">WDAC vs RCE</a> and <a href=`"https://www.tenaka.net/pass-the-hash`" class=`"class1`">Pass the Hash</a> <br>"

    $descripSecOptions = "<br>GPO settings can be found @ Computer Configuration\Windows Settings\Security Settings\Local Policies\Security Options<br><br>Prevent credential relay with Impacket and Man in the Middle by Digitally Signing for SMB and LDAP connections enforcement. <br> <br>Further information can be found @ <a href=`"https://www.tenaka.net/smb-relay-attack`" class=`"class1`">SMB-Relay-Attack</a><br> <br>System cryptography: Force strong key protection for user keys stored on the computer should only be set on clients and not Servers<br>"

    $descripLSA = "Enabling RunAsPPL for LSA Protection allows only digitally signed binaries to load as a protected process preventing credential theft and Access by code injection and memory Access by processes that aren't signed. <br> <br>Further information can be found @ https://docs.microsoft.com/en-us/windows-server/security/credentials-protection-and-management/configuring-additional-lsa-protection<br>"

    $descripDLL = "Loading DLL's default behaviour is to call the dll from the current working directory of the application, then the directories listed in the environmental variable. Setting 'DLL Safe Search' mitigates the risk by moving CWD to later in the search order. <br> <br>Further information can be found @ https://docs.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order<br>"

    $descripHyper = "Hypervisor Enforced Code Integrity prevents the loading of unsigned kernel-mode drivers and system binaries from being loaded into system memory. <br> <br>Further information can be found @ https://docs.microsoft.com/en-us/windows/security/threat-protection/device-guard/enable-virtualization-based-protection-of-code-integrity<br>"

    $descripElev = "Auto Elevate User is a setting that elevates users allowing them to install software without being an administrator. "

    $descripFilePw = "Files that contain password or credentials"

    $descripAutoLogon = "MECM\SCCM\MDT could leave Autologon credentials including a clear text password in the Registry."

    $descripUnquoted = "The Unquoted paths vulnerability is when a Windows Service's 'Path to Executable' contains spaces and not wrapped in double-quotes providing a route to System. <br> <br>Further information can be found @ <a href=`"https://www.tenaka.net/unquotedpaths`" class=`"class1`">UnQuoted Paths</a><br>"

    $descripProcPw = "Processes that contain credentials to authenticate and Access applications. Launching Task Manager, Details and add 'Command line' to the view."

    $descripLegacyNet = "LLMNR and other legacy network protocols can be used to steal password hashes. <br> <br>Further information can be found @ <a href=`"https://www.tenaka.net/responder`" class=`"class1`">Responder</a><br>"

    $descripRegPer ="Weak Registry permissions allowing users to change the path to launch malicious software.<br><br>Further information can be found @ <a href=`"https://www.tenaka.net/unquotedpaths`" class=`"class1`">UnQuoted Paths</a>"

    $descripSysFold = "Default System Folders that allow a User the Write permissions. These can be abused by creating content in some of the allowable default locations. Prevent by applying Execution controls eg Applocker.<br> <br> Further information can be found @ <a href=`"https://www.tenaka.net/unquotedpaths`" class=`"class1`">UnQuoted Paths</a><br>"

    $descripCreateSysFold = "Default System Folders that allows a User the CreateFile permissions. These can be abused by creating content in some of the allowable default locations. Prevent by applying Execution controls eg Applocker.<br> <br>Further information can be found @ <a href=`"https://www.tenaka.net/unquotedpaths`" class=`"class1`">UnQuoted Paths</a><br>"

    $descripNonFold = "A vulnerability exists when enterprise software has been installed on the root of C:\. The default permissions allow a user to replace approved software binaries with malicious binaries. <br> <br>Further information can be found @ <a href=`"https://www.tenaka.net/unquotedpaths`" class=`"class1`">UnQuoted Paths</a><br>"

    $descripFile = "System files that allow users to write can be swapped out for malicious software binaries. <br> <br>Further  information can be found @ <a href=`"https://www.tenaka.net/unquotedpaths`" class=`"class1`">UnQuoted Paths</a>"

    $descripFirewalls = "Firewalls should always block inbound and exceptions should be to a named IP and Port.<br> <br>Further  information can be found @ <a href=`"https://www.tenaka.net/whyhbfirewallsneeded`" class=`"class1`">Why Hostbased Firewalls are Essential</a><br>" 

    $descripTaskSchPerms = "Checks for Scheduled Tasks excluding any that reference System32 as a directory. These potential user-created tasks are checked for scripts and their directory permissions are validated. No user should be allowed to Access the script and make amendments, this is a privilege escalation route." 

    $descripTaskSchEncode = "Checks for encoded scripts, PowerShell or exe's that make calls off box or run within Task Scheduler" 

    $descriptDriverQuery = "All Drivers should be signed with a digital signature to verify the integrity of the packages. 64bit kernel Mode drivers must be signed without exception"

    $descriptAuthCodeSig = "Checks that digitally signed files have a valid and trusted hash. If any Hash Mis-Matches then the file could have been altered"

    $descriptDLLHijack = "DLL Hijacking is when a malicious dll replaces a legitimate dll due to a path vulnerability. A program or service makes a call on that dll gaining the privileges of that program or service. Additionally missing dll's presents a risk where a malicious dll is dropped into a path where no current dll exists but the program or service is making a call to that non-existent dll. This audit is reliant on programs being launched so that DLL's are loaded. Each process's loaded dll's are checked for permissions issues and whether they are signed. The DLL hijacking audit does not currently check for missing dll's being called. Process Monitor filtered for 'NAME NOT FOUND' and path ends with 'DLL' will."

    $descripCredGu = "Credential Guard securely isolating the LSA process preventing the recovery of domain hashes from memory. Credential Guard only works for Domain joined clients and servers.<br> <br>Further information can be found @ <a href=`"https://www.tenaka.net/pass-the-hash`" class=`"class1`">Pass the Hash</a><br>"

    $descripLAPS = "Local Administrator Password Solution (LAPS) is a small program with some GPO settings that randomly sets the local administrator password for clients and servers across the estate. Domain Admins have default permission to view the local administrator password via DSA.MSC. Access to the LAPS passwords may be delegated unintentionally, this could lead to a serious security breach, leaking all local admin accounts passwords for all computer objects to those that shouldn't have Access. <br> <br>Installation guide can be found @ <a href=`"https://www.tenaka.net/post/local-admin-passwords`" class=`"class1`">LAPS Installation</a>. <br> <br>Security related issue details can be found @ <a href=`"https://www.tenaka.net/post/laps-leaks-local-admin-passwords`" class=`"class1`">LAPS Leaking Admin Passwords</a><br>"

    $descripURA = "User Rights Assignments (URA) control what tasks a user can perform on the local client, server or Domain Controller. For example the 'Log on as a service' (SeServiceLogonRight) provides the rights for a service account to Logon as a Service, not Interactively. <br> <br> Access to URA can be abused and attack the system. <br> <br>Both SeImpersonatePrivilege (Impersonate a client after authentication) and SeAssignPrimaryTokenPrivilege (Replace a process level token) are commonly used by service accounts and vulnerable to escalation of privilege via Juicy Potato exploits.<br> <br>SeBackupPrivilege (Back up files and directories), read Access to all files including SAM Database, Registry and NTDS.dit (AD Database). <br> <br>SeRestorePrivilege (Restore files and directories), Write Access to all files. <br> <br>SeDebugPrivilege (Debug programs), allows the ability to dump and inject into process memory inc kernel. Passwords are stored in memory in the clear and can be dumped and easily extracted. <br> <br>SeTakeOwnershipPrivilege (Take ownership of files or other objects), take ownership of file regardless of Access.<br> <br>SeNetworkLogonRight (Access this computer from the network) allows pass-the-hash when Local Admins share the same password, remove all the default groups and apply named groups, separating client from servers.<br><br>SeCreateGlobalPrivilege (Create global objects), do not assign any user or group other than Local System as this will allow system takeover<br><br>Further details can be found @ <br>https://docs.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment<br>https://www.microsoft.com/en-us/download/details.aspx?id=55319<br><br>**UserRightAssignment-Name - Mouse over to show Microsofts recommended setting"

    $descripRegPasswords = "Searches HKLM and HKCU for the Words 'password' and 'passwd', then displays the password value in the report.<br><br>The search will work with VNC encrypted passwords stored in the registry, from Kali run the following command<br> <br>echo -n PasswordHere | xxd -r -p | openssl enc -des-cbc --nopad --nosalt -K e84ad660c4721ae0 -iv 0000000000000000 -d | hexdump -Cv<br>"

    $descripASR = "Attack Surface Reduction (ASR) requires Windows Defender Real-Time Antivirus and works in conjunction with Exploit Guard to prevent malware abusing legitimate MS Office functionality<br> <br>Further information can be found @ https://docs.microsoft.com/en-us/microsoft-365/security/defender-endpoint/overview-attack-surface-reduction?view=o365-worldwide<br>"

    $descripWDigest = "WDigest was introduced with Windows XP\2003 and has been enabled by default until and including Windows 8 and Server 2012. Enabling allows clear text passwords to be recoverable from LSASS with Mimikatz"

    $descripDomainGroups = "Group membership of the user executing this script. Local admins are required, the account should not have Domain Admins as this can result in privilege escalation."

    $descripDomainPrivs = "Reference User Rights Assignment (URA) section below for further details"

    $descripLocalAccounts = "Local accounts should be disabled when the client or server is part of a Domain. LAPS should be deployed to ensure all local account passwords are unique"

    $descripWindowsOS = "Warning: Absence of a GPO setting will raise an issue as the default setting is not assumed<br>These are recommended GPO settings to secure Windows by Microsoft, do NOT implement without the correct research and testing. Some settings could adversely affect your system.<br> <br>Due to the sheer number of settings, the script contains details and the equivalent GPO settings, search for RECOMMENDED SECURITY SETTINGS section<br><br>MS Security Compliance Toolkit can be found @ <br>https://admx.help/?Category=security-compliance-toolkit<br>https://www.microsoft.com/en-us/download/details.aspx?id=55319<br><br>**WindowsRegValue - Mouse over to show Reg Key to GPO path translation" 

    $descripOffice2016 = "These are recommended GPO settings to secure Office 2016-365 by Microsoft, do NOT implement without the correct research and testing. Some settings could adversely affect your system.<br> Its recommended that Attack Surface Reduction (ASR) is enabled but requires Windows Defender Real-Time Antivirus and works in conjunction with Exploit Guard to prevent malware abusing legitimate MS Office functionality"

    $descripPreAuth = "READ ME - Requires the installation of the AD RSAT tools for this to work.<br><br>Pre-authentication is when the user sends the KDC an Authentication Service Request (AS_REQ) with an encrypted Timestamp. The KDC replies with an Authentication Service Reply (AS_REP) with the TGT and a logon session. The issue arises when the user's account doesn't require pre-authentication, it's a check box on the user's account settings. An attacker is then able to request a DC, and the DC dutifully replies with user encrypted TGT using the user's own NTLM password hash. An offline brute force attack is then possible in the hope of extracting the clear text password, known as AS-REP Roasting <br> <br>Further information @ <a href=`"https://www.tenaka.net/kerberos-armouring`" class=`"class1`">Kerberos Armouring</a><br>"

    $descripAV = ""

    $descripDomainPrivsGps = "Review and minimise members of privileged groups and delegate as much as possible. Don't nest groups into Domain Admins, add direct user accounts only. Deploy User Rights Assignments to explicitly prevent Domain Admins from logging on to Member Servers and Clients more information can be found here @ <a href=`"https://www.tenaka.net/post/deny-domain-admins-logon-to-workstations`" class=`"class1`">URA to Deny Domain Admins Logging to Workstations</a><br><br>Dont add privilged groups to Guests or Domain Guests and yes I've seen Domain Guests added to Domain Admins"

    $descripCerts = ""

    $decripCipher = ""

    $descripKernelMode = "Enabed with Windwos 11 22H2 - For code running in kernel mode, the CPU confirms requested return addresses with a second copy of the address stored in the shadow stack to prevent attackers from substituting an address that runs malicious code. Not all drivers are compatiable with this security feature. More information can be found here @<br><br>https://techcommunity.microsoft.com/t5/windows-os-platform-blog/understanding-hardware-enforced-stack-protection/ba-p/1247815"

    $descripInstalledApps = "Will assume any installed program older than 6 months is out of date"

    $descripBios = "Will assume any UEFI\BIOS is out of date if its older than 6 months"

    $descripWinUpdates = "Will assume any Windows Updates are out of date if older than 6 months"

    $descripPowershellHistory = "Searches Powershell history for Password or Usernames @ C:\Users\SomeUser\APDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"

    $descripAutoRuns = "Autoruns are Windows programs set to auto-execute during startup launching when the operating system boots. These include legitimate apps, system utilities, and potentially malicious software. Autoruns can be exploited by planting malicious code in startup locations or manipulating system settings. This grants them persistence and control over compromised systems. Malware in startup locations can steal data, spread, or provide backdoor access. Exploited programs often leverage system vulnerabilities or manipulate user trust through disguised software.<br><br> The `"Run`" or `"RunOnce`" keys in the Windows Registry, like `"HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run`", enabling their malware to launch at boot. Similarly, they might abuse the `"Startup`" folder where shortcuts execute on login. Notable examples include the use of these mechanisms by malware like `"Sasser`" (2004) and `"WannaCry`" (2017) worms. Regularly monitoring and securing these auto-start points is vital to prevent such exploits. Further information can be founds @ https://attack.mitre.org/techniques/T1547/001/ "

    $descripWDAC = "Requires CITool.exe, comes as default with Windows 11 22H2<br><br>WDAC (Windows Defender Application Control), Device Guard was its release name, is a security feature in Windows operating systems designed to enhance system security. In kernel mode, WDAC operates by enforcing code integrity policies, which restrict the execution of unauthorized or unsigned code, preventing malicious software from running. It uses kernel-mode drivers to monitor and control the loading of executables and scripts, ensuring only approved applications run, bolstering system security<br><br>Application Control Policy and Application Control User should be set to Enforce when enabled.<br><br>There should be a named policy that is also set to (CIPolicyEnforced = True) and not Audit (CIPolicyEnforced = False)<br><br>For this to report on WDAC while Enforced, either sign this script or temporarily set 'Set-RuleOption -FilePath C:\WDAC\Policy.xml -Option 11'"
    
    $descripToDo = ""

################################################
############  NON FILTERED FRAGMENTS  ##########
################################################
#Generates report without any filternig of content or details summary drop downs, this is to provide a fall back in case filtering is excessive. 
#Final report filters out null fragments 
   
    #Top and Tail
    $nFragDescrip1 =  $Descrip1 | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:$font;>$Intro</span></h3>" | Out-String
    #$FragDescrip2 =  $Descrip2 | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:$font;>$Intro2</span></h3>" | Out-String
    $nFragDescripFin =  $DescripFin | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:$font;>$Finish</span></h3>" | Out-String
    $nFrag_descripVirt2 = ConvertTo-Html -as table -Fragment -PostContent "<h4>$descripVirt2</h4>" | Out-String
    
    #Summary
    $nfrag_Summary = $fragSummary | ConvertTo-Html -As Table -fragment -PreContent "<h2>Overall Compliance Status</span></h2>"  | Out-String
            
    #Host details    
    $nfrag_Host = $fragHost | ConvertTo-Html -As List -Property Name,Domain,Model -fragment -PreContent "<h2>Host Details</span></h2>"  | Out-String
    $nfragOS = $OS | ConvertTo-Html -As List -property Caption,Version,OSArchitecture,InstallDate -fragment -PreContent "<h2>Windows Details</span></h2>" | Out-String
    $nfrag_Patchversion = $fragPatchversion | ConvertTo-Html -As Table  -fragment -PreContent "<h2>Windows Patch Version</span></h2>" | Out-String
    $nFragAccountDetails = $AccountDetails  | ConvertTo-Html -As Table -fragment -PreContent "<h2>Local Account Details</span></h2>" -PostContent "<h4>$descripLocalAccounts</h4>" | Out-String 
    $nfrag_DCList  = $fragDCList | ConvertTo-Html -As Table -fragment -PreContent "<h2>List of Domain Controllers</span></h2>" | Out-String 
    $nfrag_FSMO = $fragFSMO | ConvertTo-Html -As Table -fragment -PreContent "<h2>FSMO Roles</span></h2>" | Out-String 
    $nfrag_DomainGrps = $fragDomainGrps | ConvertTo-Html -As Table -fragment -PreContent "<h2>Members of Privilege Groups</span></h2>" -PostContent "<h4>$descripDomainPrivsGps</h4>" | Out-String 
    $nfrag_PreAuth = $fragPreAuth | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"PreAuth`"><a href=`"#TOP`">Domain Accounts that DO NOT Pre-Authenticate</a></span></h2>" -PostContent "<h4>$descripPreAuth</h4>" | Out-String
    $nfrag_NeverExpires = $fragNeverExpires | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"PassExpire`"><a href=`"#TOP`">Domain Accounts that Never Expire their Password</a></span></h2>"  | Out-String
    $nFragGroupDetails =  $GroupDetails  | ConvertTo-Html -As Table -fragment -PreContent "<h2>Local System Group Members</span></h2>" | Out-String
    $nFragPassPol = $PassPol | Select-Object -SkipLast 3 | ConvertTo-Html -As Table -fragment -PreContent "<h2>Local Password Policy</span></h2>" | Out-String
    $nfragInstaApps  =  $InstallApps | Sort-Object publisher,displayname -Unique  | ConvertTo-Html -As Table  -fragment -PreContent "<h2><a name=`"InstalledApps`"><a href=`"#TOP`">Installed Applications</a></span></h2>" -PostContent "<h4>$descripInstalledApps</h4>" | Out-String
    $nfragHotFix = $HotFix | ConvertTo-Html -As Table -property HotFixID,InstalledOn,Caption -fragment -PreContent "<h2><a name=`"Hotfix`"><a href=`"#TOP`">Installed Windows Updates</a></span></h2>" -PostContent "<h4>$descripWinUpdates</h4>"| Out-String   
    $nfragInstaApps16  =  $InstallApps16 | Sort-Object publisher,displayname -Unique  | ConvertTo-Html -As Table  -fragment -PreContent "<h2>Updates to Office 2016 and older or Updates that create KB's in the Registry</span></h2>" | Out-String
    $nfragBios = $BiosUEFI | ConvertTo-Html -As List -fragment -PreContent "<h2><a name=`"BiosUEFI`"><a href=`"#TOP`">Bios Details</a></span></h2>" -PostContent "<h4>$descripBios</h4>"| Out-String
    $nfragCpu = $cpu | ConvertTo-Html -As List -property Name,MaxClockSpeed,NumberOfCores,ThreadCount -fragment -PreContent "<h2>Processor Details</span></h2>" | Out-String
    $nfrag_whoamiGroups =  $whoamiGroups | ConvertTo-Html -As Table -fragment -PreContent "<h2>Current Users Group Membership</span></h2>" -PostContent "<h4>$descripDomainGroups</h4>" | Out-String
    $nfrag_whoamiPriv =  $whoamiPriv | ConvertTo-Html -As Table -fragment -PreContent "<h2>Current Users Local Privileges</span></h2>" -PostContent "<h4>$descripDomainPrivs</h4>" | Out-String
    $nfrag_Network4 = $fragNetwork4 | ConvertTo-Html -As List -fragment -PreContent "<h2>IPv4 Address Details</span></h2>"  | Out-String
    $nfrag_Network6 = $fragNetwork6 | ConvertTo-Html -As List -fragment -PreContent "<h2>IPv4 Address Details</span></h2>"  | Out-String
    $nFrag_WinFeature = $FragWinFeature | ConvertTo-Html -As table -fragment -PreContent "<h2>Installed Windows Client Features</span></h2>"  | Out-String
    
    $nFrag_Appx = $FragAppx | ConvertTo-Html -As table -fragment -PreContent "<h2>Installed Windows Optional Features</span></h2>"  | Out-String
    $nFrag_SrvWinFeature = $FragSrvWinFeature | ConvertTo-Html -As table -fragment -PreContent "<h2>Installed Windows ServerFeatures</span></h2>"  | Out-String
    $nfrag_MDTBuild = $fragMDTBuild | ConvertTo-Html -As table -fragment -PreContent "<h2>MDT Deployment Details</span></h2>"  | Out-String
    
    #Security Review
    $nFrag_AVStatus = $FragAVStatus | ConvertTo-Html -As Table  -fragment -PreContent "<h2><a name=`"AV`"><a href=`"#TOP`">AntiVirus Engine and Definition Status</a></span></h2>" -PostContent "<h4>$descripAV</h4>" | Out-String
    $nfrag_BitLocker = $fragBitLocker | ConvertTo-Html -As List -fragment -PreContent "<h2><a name=`"Bitlockerisnotenabled`"><a href=`"#TOP`">Bitlocker and TPM Details</a></span></h2>" -PostContent "<h4>$descripBitlocker</h4>" | Out-String
    $nfrag_Msinfo = $MsinfoClixml | ConvertTo-Html -As Table -fragment -PreContent "<h2><a name=`"VBS`"><a href=`"#TOP`">Virtualization and Secure Boot Details</a></span></h2>" -PostContent "<h4>$descripVirt</h4>"  | Out-String
    $nfrag_kernelModeVal = $fragkernelModeVal | ConvertTo-Html -As Table -fragment -PreContent "<h2><a name=`"KernelMode`"><a href=`"#TOP`">Kernel-mode Hardware-enforced Stack Protection</a></span></h2>" -PostContent "<h4>$descripKernelMode</h4>"  | Out-String
    $nfrag_LSAPPL = $fragLSAPPL | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"LSA`"><a href=`"#TOP`">LSA Protection for Stored Credentials</a></span></h2>" -PostContent "<h4>$descripLSA</h4>" | Out-String
    $nfrag_DLLSafe = $fragDLLSafe | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"DLLSafe`"><a href=`"#TOP`">DLL Safe Search Order</a></span></h2>"  -PostContent "<h4>$descripDLL</h4>"| Out-String
    $nfrag_DLLHijack = $fragDLLHijack | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"DLLHigh`"><a href=`"#TOP`">Loaded DLL's that are vulnerable to DLL Hijacking</a></span></h2>" | Out-String
    $nfrag_DllNotSigned = $fragDllNotSigned | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"DLLSign`"><a href=`"#TOP`">All DLL's that aren't signed and user permissions allow write</a></span></h2>"  -PostContent "<h4>$descriptDLLHijack</h4>"| Out-String
    $nfrag_Code = $fragCode | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"HECI`"><a href=`"#TOP`">Hypervisor Enforced Code Integrity</a></span></h2>" -PostContent "<h4>$descripHyper</h4>" | Out-String
    $nfrag_PCElevate = $fragPCElevate | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"SoftElevation`"><a href=`"#TOP`">Automatically Elevates User Installing Software</a></span></h2>"  -PostContent "<h4>$descripElev</h4>"| Out-String
    $nfrag_FilePass = $fragFilePass | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"FilePW`"><a href=`"#TOP`">Files that Contain the Word PASSWord</a></span></h2>" -PostContent "<h4>$descripFilePw</h4>" | Out-String
    $nfrag_AutoLogon = $fragAutoLogon   | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"AutoLogon`"><a href=`"#TOP`">AutoLogon Credentials in Registry</a></span></h2>"  -PostContent "<h4>$descripAutoLogon</h4>"| Out-String
    $nfrag_UnQu = $fragUnQuoted | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"unquoted`"><a href=`"#TOP`">UnQuoted Paths Attack</a></span></h2>" -PostContent "<h4>$DescripUnquoted</h4>" | Out-String
    $nfrag_LegNIC = $fragLegNIC | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"LegNetProt`"><a href=`"#TOP`">Legacy and Vulnerable Network Protocols</a></span></h2>" -PostContent "<h4>$DescripLegacyNet</h4>" | Out-String
    $nfrag_SysRegPerms = $fragReg | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"RegWrite`"><a href=`"#TOP`">Registry Permissions Allowing User Access - Security Risk if Exist</a></span></h2>" -PostContent "<h4>$descripRegPer</h4>" | Out-String
    $nfrag_PSPass = $fragPSPass | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"ProcPW`"><a href=`"#TOP`">Processes where CommandLine Contains a Password</a></span></h2>" -PostContent "<h4>$Finish</h4>" | Out-String
    $nfrag_SecOptions = $fragSecOptions | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"secOptions`"><a href=`"#TOP`">Security Options to Prevent MitM Attacks</a></span></h2>" -PostContent "<h4>$descripSecOptions</h4>" | Out-String
    $nfrag_wFolders = $fragwFold | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"sysFileWrite `"><a href=`"#TOP`">Non System Folders that are Writeable - Security Risk when Executable</span></a></h2>" -PostContent "<h4>$descripNonFold</h4>"| Out-String
    $nfrag_SysFolders = $fragsysFold | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"SysDirWrite`"><a href=`"#TOP`">Default System Folders that are Writeable - Security Risk if Exist</span></a></h2>"  -PostContent "<h4>$descripSysFold</h4>"| Out-String
    $nfrag_CreateSysFold = $fragCreateSysFold | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"sysDirExe`"><a href=`"#TOP`">Default System Folders that Permit Users to Create Files - Security Risk if Exist</a></span></h2>"  -PostContent "<h4>$descripCreateSysFold</h4>"| Out-String
    $nfrag_wFile = $fragwFile | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"sysFileWrite`"><a href=`"#TOP`">System Files that are Writeable - Security Risk if Exist</a></span></h2>" -PostContent "<h4>$descripFile</h4>" | Out-String
    $nfrag_FWProf = $fragFWProfile | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"FirewallProf`"><a href=`"#TOP`">Firewall Profile</a></span></h2>"  -PostContent "<h4>$DescripFirewalls</h4>"| Out-String
    $nfrag_FW = $fragFW | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"InFirewall`"><a href=`"#TOP`">Enabled Firewall Rules</a></span></h2>" | Out-String
    $nfrag_TaskPerms =  $SchedTaskPerms | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"schedDir`"><a href=`"#TOP`">Scheduled Tasks with Scripts Stored on Disk</a></span></h2>"  -PostContent "<h4>$descripTaskSchPerms</h4>" | Out-String
    $nfrag_RunServices =  $fragRunServices | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"RunningServices`"><a href=`"#TOP`">Running Services</a></span></h2>"  | Out-String
    $nfrag_AutoRuns = $fragAutoRunsVal | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"AutoRuns`"><a href=`"#TOP`">AutoRuns</summary></a><p>" -PostContent "<h4>$descripAutoRuns</h4></details>" | Out-String         
            
    $nfrag_TaskListings = $SchedTaskListings | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"schedTask`"><a href=`"#TOP`">Scheduled Tasks that Contain something Encoded</a></span></h2>"  -PostContent "<h4>$descripTaskSchEncode</h4>" | Out-String
    $nfrag_DriverQuery = $DriverQuery | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"drivers`"><a href=`"#TOP`">Drivers that aren't Signed</a></span></h2>" -PostContent "<h4>$descriptDriverQuery</h4>" | Out-String
    $nfrag_Share = $fragShare | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"shares`"><a href=`"#TOP`">Shares and their Share Permissions</a></span></h2>"  | Out-String
    $nfrag_AuthCodeSig = $fragAuthCodeSig | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"AuthentiCode`"><a href=`"#TOP`">Files with an Authenticode Signature HashMisMatch</a></span></h2>" -PostContent "<h4>$descriptAuthCodeSig</h4>"  | Out-String  
    $nfrag_CredGuCFG = $fragCredGuCFG | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"CredGuard`"><a href=`"#TOP`">Credential Guard</a></span></h2>" -PostContent "<h4>$descripCredGu</h4>" | Out-String
    $nfrag_LapsPwEna = $fragLapsPwEna | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"LAPS`"><a href=`"#TOP`">LAPS - Local Administrator Password Solution</a></span></h2>" -PostContent "<h4>$descripLAPS</h4>" | Out-String
    $nfrag_URA = $fragURA | ConvertTo-Html -as Table -Fragment -PreContent "<h2>URA - Local Systems User Rights Assignments</a></span></h2>" -PostContent "<h4>$descripURA</h4>" | Out-String
    $nfrag_RegPasswords = $fragRegPasswords | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"RegPW`"><a href=`"#TOP`">Passwords Embedded in the Registry</a></span></h2>" -PostContent "<h4>$descripRegPasswords</h4>" | Out-String
    $nfrag_ASR = $fragASR | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"asr`"><a href=`"#TOP`">Attack Surface Reduction (ASR)</a></span></h2>" -PostContent "<h4>$descripASR</h4>" | Out-String
    $nfrag_WDigestULC = $fragWDigestULC | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"WDigest`"><a href=`"#TOP`">WDigest</a></span></h2>" -PostContent "<h4>$descripWDigest</h4>" | Out-String
    $nfrag_Certificates = $fragCertificates | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"Certs`"><a href=`"#TOP`">Installed Certificates</a></span></h2>" -PostContent "<h4>$descripCerts</h4>" | Out-String
    $nfrag_CipherSuit = $fragCipherSuit | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"CipherSuites`"><a href=`"#TOP`">Supported Cipher Suites</a></span></h2>" -PostContent "<h4>$decripCipher</h4>" | Out-String
    $nfrag_PSPasswords = $fragPSPasswords | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"PSHistory`"><a href=`"#TOP`">PowerShell History Containing Creds</a></span></h2>" -PostContent "<h4>$descripPowershellHistory</h4>" | Out-String
    $nfrag_ApplockerSvc = $fragApplockerSvc | ConvertTo-Html -As table -fragment -PreContent "<h2>Applocker Service Status</span></h2>"  | Out-String      
    $nfrag_ApplockerPath = $fragApplockerPath | ConvertTo-Html -As table -fragment -PreContent "<h2>Applocker Path Rules</span></h2>"  | Out-String
    $nfrag_ApplockerPublisher = $fragApplockerPublisher | ConvertTo-Html -As table -fragment -PreContent "<h2>Applocker Publisher Rules</span></h2>"  | Out-String
    $nfrag_ApplockerHash = $fragApplockerHash | ConvertTo-Html -As table -fragment -PreContent "<h2>Applocker Hash Rules</span></h2>"  | Out-String
    $nfrag_ApplockerEnforcement = $fragApplockerEnforcement | ConvertTo-Html -As table -fragment -PreContent "<h2>Applocker Enforcement Rules</span></h2>"  | Out-String  
 
    $nfrag_wdacClixml = $fragwdacClixml | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a name=`"WDACEnforce`"><a href=`"#TOP`">WDAC Enforcement Mode</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String
    $nfrag_WDACCIPolicy = $fragWDACCIPolicy | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a name=`"WDACPolicy`"><a href=`"#TOP`">WDAC Policy</summary></a><p>" -PostContent "<h4>$descripWDAC</h4></details>"  | Out-String
            
    #MS Recommended Secuirty settings (SSLF)
    $nfrag_WindowsOSVal = $fragWindowsOSVal | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"WinSSLF`"><a href=`"#TOP`">Windows OS Security Recommendations</a></span></h2>" -PostContent "<h4>$descripWindowsOS</h4>" | Out-String
    $nfrag_EdgeVal = $fragEdgeVal | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"EdgeSSLF`"><a href=`"#TOP`">MS Edge Security Recommendations</a></span></h2>" | Out-String
    $nfrag_OfficeVal = $fragOfficeVal | ConvertTo-Html -as Table -Fragment -PreContent "<h2><a name=`"OfficeSSLF`"><a href=`"#TOP`">MS Office Security Recommendations</a></span></h2>" -PostContent "<h4>$descripOffice2016</h4>" | Out-String
    
    ConvertTo-Html -Head $style -Body "<h1 align=center style='text-align:center'>$basePNG<h1>",    

    $nfragDescrip1, 
    $nfrag_Summary,
    $nfrag_host, 
    #n$frag_MDTBuild,
    $nfragOS, 
    $nfrag_Patchversion,
    $nfragbios, 
    $nfragcpu, 
    $nfrag_Network4,
    $nfrag_Network6,
    $nfrag_Share,
    $nfrag_LegNIC,
    $nfrag_SecOptions,
    $nfrag_FWProf,
    $nfrag_FW,
    $nfrag_Msinfo,
    $nfrag_BitLocker, 
    $nfrag_Code,
    $nfrag_LSAPPL,
    $nfrag_WDigestULC,
    $nfrag_CredGuCFG,
    $nfrag_kernelModeVal,
#accounts and groups
    $nFragPassPol,
    $nFragAccountDetails,
    $nfrag_DomainGrps,
    $nfrag_DCList,
    $nfrag_FSMO,
    $nfrag_PreAuth,
    $nfrag_NeverExpires,
    $nFragGroupDetails,
    $nfrag_whoamiGroups, 
    $nfrag_whoamiPriv,
    $nfrag_URA,
    $nfrag_LapsPwEna,
#progs
    $nFrag_WinFeature,
    $nFrag_Appx,
    $nFrag_SrvWinFeature,
    $nfragInstaApps,
    $nfragHotFix,
    $nfragInstaApps16,
    $nFrag_AVStatus,
    $nfrag_UnQu,
#applocker
    $nfrag_wdacClixml,
    $nfrag_WDACCIPolicy,
    $nfrag_ApplockerSvc,
    $nfrag_ApplockerEnforcement,
    $nfrag_ApplockerPath, 
    $nfrag_ApplockerPublisher,
    $nfrag_ApplockerHash, 
#certs and ciphers     
    $nfrag_Certificates,
    $nfrag_CipherSuit,
#file and reg audits
    $nfrag_DLLSafe,
    $nfrag_DLLHijack,
    $nfrag_DllNotSigned,
    $nfrag_PCElevate,
    $nfrag_PSPass,
    $nfrag_FilePass,
    $nfrag_RegPasswords,
    $nfrag_PSPasswords,
    $nfrag_AutoLogon,
    $nfrag_AutoRuns,
    $nfrag_TaskPerms,
    $nfrag_TaskListings,
    #$nfrag_RunServices,
    $nfrag_SysRegPerms,
    $nfrag_SysFolders,
    $nfrag_CreateSysFold,
    $nfrag_wFolders,
    $nfrag_wFile,
    $nfrag_DriverQuery,
    $nfrag_AuthCodeSig,
#policy
    $nfrag_ASR,
    $nfrag_WindowsOSVal,
    $nfrag_EdgeVal,
    $nfrag_OfficeVal,
    $nFragDescripFin  | out-file $NonFilteredReport

################################################
##########  FINAL REPORT FRAGMENTS  ############
################################################
#Generates report with empty or null fragments removed   
    #Top and Tail
    $FragDescrip1 =  $Descrip1 | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:$font;>$Intro</span></h3>" | Out-String
    #$FragDescrip2 =  $Descrip2 | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:$font;>$Intro2</span></h3>" | Out-String
    $FragDescripFin =  $DescripFin | ConvertTo-Html -as table -Fragment -PreContent "<h3><span style=font-family:$font;>$Finish</span></h3>" | Out-String
    $Frag_descripVirt2 = ConvertTo-Html -as table -Fragment -PostContent "<h4>$descripVirt2</h4>" | Out-String
    
    #Summary
    $frag_Summary = $fragSummary | ConvertTo-Html -As Table -fragment -PreContent "<h2><a href=`"#TOP`">Overall Compliance Status</a></span></h2>"  | Out-String
            
    #Host details    
    $frag_Host = $fragHost | ConvertTo-Html -As List -Property Name,Domain,Model -fragment -PreContent "<h2><a href=`"#TOP`">Host Details</a></span></h2>"  | Out-String

    $fragOS = $OS | ConvertTo-Html -As List -property Caption,Version,OSArchitecture,InstallDate -fragment -PreContent "<h2><summary><a href=`"#TOP`">Windows Details</a></span></h2>" | Out-String
    
    $frag_Patchversion = $fragPatchversion  | ConvertTo-Html -As list -fragment -PreContent "<h2><a href=`"#TOP`">Windows Patch Version</a></span></h2>" | Out-String
    $frag_OSPatchver = $frag_Patchversion.Replace("<td>*:</td>","")

    if ([string]::IsNullOrEmpty($AccountDetails.ToString())){$FragAccountDetails = $null}
    else{$FragAccountDetails = $AccountDetails  | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Local Account Detail</a></summary><p>" -PostContent "<h4>$descripLocalAccounts</h4></details>" | Out-String} 
    
    if ([string]::IsNullOrEmpty($fragDCList)){$frag_DCList = $null} 
    else{$frag_DCList  = $fragDCList | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">List of Domain Controllers</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String} 
    
    if ([string]::IsNullOrEmpty($fragFSMO)){$frag_FSMO = $null} 
    else{$frag_FSMO = $fragFSMO | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">FSMO Roles</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>"| Out-String} 
    
    if ([string]::IsNullOrEmpty($fragDomainGrps)){$frag_DomainGrps = $null} 
    else{$frag_DomainGrps = $fragDomainGrps | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Members of Privilege Groups</a></summary><p>" -PostContent "<h4>$descripDomainPrivsGps</h4></details>" | Out-String} 
    
    if ([string]::IsNullOrEmpty($fragPreAuth)){$frag_PreAuth = $null} 
    else{$frag_PreAuth = $fragPreAuth | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"PreAuth`"><a href=`"#TOP`">Domain Accounts that DO NOT Pre-Authenticate</summary></a><p>" -PostContent "<h4>$descripPreAuth</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragNeverExpires)){$frag_NeverExpires = $null} 
    else{$frag_NeverExpires = $fragNeverExpires | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"PassExpire`"><a href=`"#TOP`">Domain Accounts that Never Expire their Password</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}
    
    if ([string]::IsNullOrEmpty($GroupDetails.ToString())){$FragGroupDetails = $null} 
    else{$FragGroupDetails = $GroupDetails  | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Local System Group Members</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($PassPol.ToString())){$FragPassPol = $null} 
    else{$FragPassPol = $PassPol | Select-Object -SkipLast 3 | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Local Password Policy</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($InstallApps.ToString())){$fragInstaApps = $null} 
    else{$fragInstaApps = $InstallApps | Sort-Object publisher,displayname -Unique  | ConvertTo-Html -As Table  -fragment -PreContent "<p></p><details><summary><a name=`"InstalledApps`"><a href=`"#TOP`">Installed Applications</summary></a><p>" -PostContent "<h4>$descripInstalledApps</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($HotFix.ToString())){$fragHotFix = $null} 
    else{$fragHotFix = $HotFix | ConvertTo-Html -As Table -property HotFixID,InstalledOn,Caption -fragment -PreContent "<p></p><details><summary><a name=`"Hotfix`"><a href=`"#TOP`">Installed Windows Updates</summary></a><p>" -PostContent "<h4>$descripWinUpdates</h4></details>"| Out-String}   
    
    if ([string]::IsNullOrEmpty($InstallApps16)){$fragInstaApps16 = $null} 
    else{$fragInstaApps16 = $InstallApps16 | Sort-Object publisher,displayname -Unique  | ConvertTo-Html -As Table  -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Updates to Office 2016 and older or Updates that create KB's in the Registry</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($BiosUEFI.ToString())){$fragBios = $null} 
    else{$fragBios = $BiosUEFI | ConvertTo-Html -As List -fragment -PreContent "<p></p><details><summary><a name=`"BiosUEFI`"><a href=`"#TOP`">Bios Details</summary></a><p>" -PostContent "<h4>$descripBios</h4></details>"| Out-String}
    
    if ([string]::IsNullOrEmpty($cpu.ToString())){$fragCpu = $null} 
    else{$fragCpu = $cpu | ConvertTo-Html -As List -property Name,MaxClockSpeed,NumberOfCores,ThreadCount -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Processor Details</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($whoamiGroups.ToString())){$frag_whoamiGroups = $null} 
    else{$frag_whoamiGroups =  $whoamiGroups | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Current Users Group Membership</a></summary><p>" -PostContent "<h4>$descripDomainGroups</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($whoamiPriv.ToString())){$frag_whoamiPriv = $null} 
    else{$frag_whoamiPriv =  $whoamiPriv | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Current Users Local Privileges</a></summary><p>" -PostContent "<h4>$descripDomainPrivs</h4></details>" | Out-String}
    
    $frag_Network4 = $fragNetwork4 | ConvertTo-Html -As List -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">IPv4 Address Details</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String
    
    $frag_Network6 = $fragNetwork6 | ConvertTo-Html -As List -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">IPv6 Address Details</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String
    
    #Client Features
    if ([string]::IsNullOrEmpty($FragWinFeature.ToString())){$Frag_WinFeature = $null} 
    else{$Frag_WinFeature = $FragWinFeature | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Installed Windows Client Features</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
 
    if ([string]::IsNullOrEmpty($FragAppx.ToString())){$Frag_Appx = $null} 
    else{$Frag_Appx = $FragAppx | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Installed Windows Client Optional Features</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    #Server Features
    if ([string]::IsNullOrEmpty($FragSrvWinFeature.ToString())){$Frag_SrvWinFeature = $null} 
    else{$Frag_SrvWinFeature = $FragSrvWinFeature | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Installed Windows Server Features</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}

    if ([string]::IsNullOrEmpty($fragMDTBuild.ToString())){$frag_MDTBuild = $null} 
    else{$frag_MDTBuild = $fragMDTBuild | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">MDT Deployment Details</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}
    
    #Security Review - <th>*</th>
    $Frag_AVStatus = $FragAVStatus | ConvertTo-Html -As Table  -fragment -PreContent "<p></p><details><summary><a name=`"AV`"><a href=`"#TOP`">AntiVirus Engine and Definition Status</summary></a><p>" -PostContent "<h4>$descripAV</h4></details>" | Out-String
    $Frag_AVStatusN = $Frag_AVStatus.replace("<th>*</th>","")

    $frag_BitLocker = $fragBitLocker | ConvertTo-Html -As List -fragment -PreContent "<p></p><details><summary><a name=`"Bitlockerisnotenabled`"><a href=`"#TOP`">Bitlocker and TPM Details</summary></a><p>" -PostContent "<h4>$descripBitlocker</h4></details>" | Out-String
    $frag_BitLockerN = $frag_BitLocker.Replace("<td>*:</td>","")

    if ([string]::IsNullOrEmpty($MsinfoClixml.ToString())){$frag_Msinfo = $null} 
    else{$frag_Msinfo = $MsinfoClixml | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a name=`"VBS`"><a href=`"#TOP`">Virtualization and Secure Boot Details</summary></a><p>" -PostContent "<h4>$descripVirt</h4></details>"  | Out-String}    

    if ([string]::IsNullOrEmpty($fragkernelModeVal.ToString())){$frag_kernelModeVal = $null} 
    else{$frag_kernelModeVal = $fragkernelModeVal | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a name=`"KernelMode`"><a href=`"#TOP`">Kernel-mode Hardware-enforced Stack Protection</summary></a><p>" -PostContent "<h4>$descripKernelMode</h4></details>"  | Out-String}
    
    if ([string]::IsNullOrEmpty($fragLSAPPL.ToString())){$fragLSAPPL = $null} 
    else{$frag_LSAPPL = $fragLSAPPL | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"LSA`"><a href=`"#TOP`">LSA Protection for Stored Credentials</summary></a><p>" -PostContent "<h4>$descripLSA</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragDLLSafe.ToString())){$frag_DLLSafe  = $null} 
    else{$frag_DLLSafe = $fragDLLSafe | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"DLLSafe`"><a href=`"#TOP`">DLL Safe Search Order</summary></a><p>"  -PostContent "<h4>$descripDLL</h4></details>"| Out-String}
    
    if ([string]::IsNullOrEmpty($fragDLLHijack)){$frag_DLLHijack = $null} 
    else{$frag_DLLHijack = $fragDLLHijack | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"DLLHigh`"><a href=`"#TOP`">Loaded DLL's that are vulnerable to DLL Hijacking</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragDllNotSigned.ToString())){$frag_DllNotSigned = $null} 
    else{$frag_DllNotSigned = $fragDllNotSigned | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"DLLSign`"><a href=`"#TOP`">All DLL's that aren't signed and user permissions allow write</summary></a><p>"  -PostContent "<h4>$descriptDLLHijack</h4></details>"| Out-String}
    
    if ([string]::IsNullOrEmpty($fragCode.ToString())){$frag_Code = $null} 
    else{$frag_Code = $fragCode | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"HECI`"><a href=`"#TOP`">Hypervisor Enforced Code Integrity</summary></a><p>" -PostContent "<h4>$descripHyper</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragPCElevate.ToString())){$frag_PCElevate = $null} 
    else{$frag_PCElevate = $fragPCElevate | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"SoftElevation`"><a href=`"#TOP`">Automatically Elevates User Installing Software</summary></a><p>"  -PostContent "<h4>$descripElev</h4></details>"| Out-String}
    
    if ($fragFilePass -eq $null){$frag_FilePass = $null} 
    else{$frag_FilePass = $fragFilePass | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"FilePW`"><a href=`"#TOP`">Files that Contain the Word PASSWord</summary></a><p>" -PostContent "<h4>$descripFilePw</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragAutoLogon.ToString())){$frag_AutoLogon = $null} 
    else{$frag_AutoLogon = $fragAutoLogon  | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"AutoLogon`"><a href=`"#TOP`">AutoLogon Credentials in Registry</summary></a><p>"  -PostContent "<h4>$descripAutoLogon</h4></details>"| Out-String}
    
    if ([string]::IsNullOrEmpty($fragUnQuoted)){$frag_UnQu = $null} 
    else{$frag_UnQu = $fragUnQuoted | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"unquoted`"><a href=`"#TOP`">UnQuoted Paths Attack</summary></a><p>" -PostContent "<h4>$DescripUnquoted</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragLegNIC.ToString())){$frag_LegNIC = $null} 
    else{$frag_LegNIC = $fragLegNIC | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"LegNetProt`"><a href=`"#TOP`">Legacy and Vulnerable Network Protocols</summary></a><p>" -PostContent "<h4>$DescripLegacyNet</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragReg.ToString())){$frag_SysRegPerms = $null} 
    else{$frag_SysRegPerms = $fragReg | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"RegWrite`"><a href=`"#TOP`">Registry Permissions Allowing User Access - Security Risk if Exist</summary></a><p>" -PostContent "<h4>$descripRegPer</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragPSPass)){$frag_PSPass = $null} 
    else{$frag_PSPass = $fragPSPass | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"ProcPW`"><a href=`"#TOP`">Processes where CommandLine Contains a Password</summary></a><p>" -PostContent "<h4>$Finish</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragSecOptions.ToString())){$frag_SecOptions = $null} 
    else{$frag_SecOptions = $fragSecOptions | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"secOptions`"><a href=`"#TOP`">Security Options to Prevent MitM Attacks</summary></a><p>" -PostContent "<h4>$descripSecOptions</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragwFold.ToString())){$frag_wFolders = $nulll = $null} 
    else{$frag_wFolders = $fragwFold | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"sysFileWrite `"><a href=`"#TOP`">Non System Folders that are Writeable - Security Risk when Executable</summary></a><p>" -PostContent "<h4>$descripNonFold</h4></details>"| Out-String}
        
    if ([string]::IsNullOrEmpty($fragsysFold.ToString())){$frag_SysFolders = $null}
    else{$frag_SysFolders = $fragsysFold | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"SysDirWrite`"><a href=`"#TOP`">Default System Folders that are Writeable - Security Risk if Exist</summary></a><p>"  -PostContent "<h4>$descripSysFold</h4></details>"| Out-String}
        
    if ([string]::IsNullOrWhiteSpace($fragCreateSysFold.ToString())){$frag_CreateSysFold = $null}
    else{$frag_CreateSysFold = $fragCreateSysFold | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"sysDirExe`"><a href=`"#TOP`">Default System Folders that Permit Users to Create Files - Security Risk if Exist</summary></a><p>"  -PostContent "<h4>$descripCreateSysFold</h4></details>"| Out-String}
       
    if ([string]::IsNullOrEmpty($fragwFile)){$frag_wFile = $null}
    else{$frag_wFile = $fragwFile | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"sysFileWrite`"><a href=`"#TOP`">System Files that are Writeable - Security Risk if Exist</summary></a><p>" -PostContent "<h4>$descripFile</h4></details>" | Out-String}
   
    if ([string]::IsNullOrEmpty($fragFWProfile.ToString())){$frag_FWProfile = $null} 
    else{$frag_FWProf = $fragFWProfile | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"FirewallProf`"><a href=`"#TOP`">Firewall Profile</summary></a><p>"  -PostContent "<h4>$DescripFirewalls</h4></details>"| Out-String}
    
    if ([string]::IsNullOrEmpty($fragFW.ToString())){$frag_FW = $null} 
    else{$frag_FW = $fragFW | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"InFirewall`"><a href=`"#TOP`">Enabled Firewall Rules</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>"| Out-String}
    
    if ([string]::IsNullOrEmpty($SchedTaskPerms)){$frag_TaskPerms = $null} 
    else{$frag_TaskPerms = $SchedTaskPerms | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"schedDir`"><a href=`"#TOP`">Scheduled Tasks with Scripts Stored on Disk</summary></a><p>"  -PostContent "<h4>$descripTaskSchPerms</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragRunServices.ToString())){$frag_RunServices = $null} 
    else{$frag_RunServices =  $fragRunServices | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"RunningServices`"><a href=`"#TOP`">Running Services</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}
    
    if ([string]::IsNullOrEmpty($SchedTaskListings)){$frag_TaskListings = $null} 
    else{$frag_TaskListings = $SchedTaskListings | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"schedTask`"><a href=`"#TOP`">Scheduled Tasks that Contain something Encoded</summary></a><p>"  -PostContent "<h4>$descripTaskSchEncode</h4></details>" | Out-String}
    
    if ($DriverQuery -eq $null){$frag_DriverQuery = $null} 
    else{$frag_DriverQuery = $DriverQuery | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"drivers`"><a href=`"#TOP`">Drivers that aren't Signed</summary></a><p>" -PostContent "<h4>$descriptDriverQuery</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragShare.ToString())){$frag_Share = $null} 
    else{$frag_Share = $fragShare | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"shares`"><a href=`"#TOP`">Shares and their Share Permissions</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}
    
    if ([string]::IsNullOrEmpty($fragAuthCodeSig.ToString())){$frag_AuthCodeSig = $null} 
    else{$frag_AuthCodeSig = $fragAuthCodeSig | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"AuthentiCode`"><a href=`"#TOP`">Files with an Authenticode Signature HashMisMatch</summary></a><p>" -PostContent "<h4>$descriptAuthCodeSig</h4></details>"  | Out-String}  
    
    if ([string]::IsNullOrEmpty($fragCredGuCFG.ToString())){$frag_CredGuCFG = $null} 
    else{$frag_CredGuCFG = $fragCredGuCFG | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"CredGuard`"><a href=`"#TOP`">Credential Guard</summary></a><p>" -PostContent "<h4>$descripCredGu</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragLapsPwEna.ToString())){$frag_LapsPwEna = $null} 
    else{$frag_LapsPwEna = $fragLapsPwEna | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"LAPS`"><a href=`"#TOP`">LAPS - Local Administrator Password Solution</summary></a><p>" -PostContent "<h4>$descripLAPS</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragURA.ToString())){$frag_URA = $null} 
    else{$frag_URA = $fragURA | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">User Rights Assignments</a></summary><p>" -PostContent "<h4>$descripURA</h4></details>" | Out-String}
    
    if ($fragRegPasswords -eq $null){$frag_RegPasswords = $null} 
    else{$frag_RegPasswords = $fragRegPasswords | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"RegPW`"><a href=`"#TOP`">Passwords Embedded in the Registry</summary></a><p>" -PostContent "<h4>$descripRegPasswords</h4></details>" | Out-String}
    
    if ([string]::IsNullOrempty($fragASR.ToString())){$frag_ASR = $null} 
    else{$frag_ASR = $fragASR | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"asr`"><a href=`"#TOP`">Attack Surface Reduction (ASR)</summary></a><p>" -PostContent "<h4>$descripASR</h4></details>" | Out-String}
    
    if ($fragWDigestULC-eq $null){$frag_WDigestULC = $null} 
    else{$frag_WDigestULC = $fragWDigestULC | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"WDigest`"><a href=`"#TOP`">WDigest</summary></a><p>" -PostContent "<h4>$descripWDigest</h4></details>" | Out-String}
    
    $frag_Certificates = $fragCertificates | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"Certs`"><a href=`"#TOP`">Installed Certificates</summary></a><p>" -PostContent "<h4>$descripCerts</h4></details>" | Out-String
    
    $frag_CipherSuit = $fragCipherSuit | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"CipherSuites`"><a href=`"#TOP`">Supported Cipher Suites</summary></a><p>" -PostContent "<h4>$decripCipher</h4></details>" | Out-String
    
    if ([string]::IsNullOrEmpty($fragPSPasswords)){$frag_PSPasswords = $null} 
    else{$frag_PSPasswords = $fragPSPasswords | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"PSHistory`"><a href=`"#TOP`">PowerShell History Containing Creds</summary></a><p>" -PostContent "<h4>$descripPowershellHistory</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragAutoRunsVal.ToString())){$frag_AutoRuns = $null} 
    else{$frag_AutoRuns = $fragAutoRunsVal | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"AutoRuns`"><a href=`"#TOP`">AutoRuns</summary></a><p>" -PostContent "<h4>$descripAutoRuns</h4></details>" | Out-String}
        
    if ([string]::IsNullOrEmpty($fragApplockerSvc.ToString())){$fragApplockerSvc = $null} 
    else{$frag_ApplockerSvc = $fragApplockerSvc | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Applocker Service Status</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}      
    
    if ([string]::IsNullOrEmpty($fragApplockerEnforcement.ToString())){$fragApplockerEnforcement = $null} 
    else{$frag_ApplockerEnforcement = $fragApplockerEnforcement | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Applocker Enforcement</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}      
   
    if ([string]::IsNullOrEmpty($fragApplockerPath)){$frag_ApplockerPath = $null} 
    else{$frag_ApplockerPath = $fragApplockerPath | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Applocker Path Rules</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}
    
    if ([string]::IsNullOrEmpty($fragApplockerPublisher)){$frag_ApplockerPublisher = $null} 
    else{$frag_ApplockerPublisher = $fragApplockerPublisher | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Applocker Publisher Rules</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragApplockerHash)){$frag_ApplockerHash = $null} 
    else{$frag_ApplockerHash = $fragApplockerHash | ConvertTo-Html -As table -fragment -PreContent "<p></p><details><summary><a href=`"#TOP`">Applocker Hash Rules</a></summary><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}

    if ([string]::IsNullOrEmpty($fragwdacClixml.ToString())){$frag_wdacClixml = $null} 
    else{$frag_wdacClixml = $fragwdacClixml | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a name=`"WDACEnforce`"><a href=`"#TOP`">WDAC Enforcement Mode</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>"  | Out-String}
     
    if ($fragWDACCIPolicy -eq $null){$frag_WDACCIPolicy = $null} 
    else{$frag_WDACCIPolicy = $fragWDACCIPolicy | ConvertTo-Html -As Table -fragment -PreContent "<p></p><details><summary><a name=`"WDACPolicy`"><a href=`"#TOP`">WDAC Policy</summary></a><p>" -PostContent "<h4>$descripWDAC</h4></details>"  | Out-String}
            
    #MS Recommended Secuirty settings (SSLF)
    if ([string]::IsNullOrEmpty($fragWindowsOSVal.ToString())){$frag_WindowsOSVal = $null}
    else{$frag_WindowsOSVal = $fragWindowsOSVal | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"WinSSLF`"><a href=`"#TOP`">Windows OS Security Recommendations</summary></a><p>" -PostContent "<h4>$descripWindowsOS</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragEdgeVal.ToString())){$frag_EdgeVal = $null}
    else{$frag_EdgeVal = $fragEdgeVal | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"EdgeSSLF`"><a href=`"#TOP`">MS Edge Security Recommendations</summary></a><p>" -PostContent "<h4>$descripToDo</h4></details>" | Out-String}
    
    if ([string]::IsNullOrEmpty($fragOfficeVal.ToString())){$frag_OfficeVal = $null}
    else{$frag_OfficeVal = $fragOfficeVal | ConvertTo-Html -as Table -Fragment -PreContent "<p></p><details><summary><a name=`"OfficeSSLF`"><a href=`"#TOP`">MS Office Security Recommendations</summary></a><p>" -PostContent "<h4>$descripOffice2016</h4></details>" | Out-String}
    

    <#to be used as filter
    #[string]::IsNullOrEmpty
    $nonNullVariables = @()
    $var1 = "Value1"
    $var2 = $null
    $var3 = "Value3"
    $var4 = $null
    $var5 = "Value5"

    $variables = @($var1, $var2, $var3, $var4, $var5)

    foreach ($variable in $variables) 
        {
            if ($variable -ne $null) {
            $nonNullVariables += "$($variable)," 
        }
    }
    Write-Host ($nonNullVariables).TrimEnd(",")
   



################################################
###########  EMBEDDED IMAGE BRANDING  ##########
################################################
    <#
        Convert image file to base64 for embedded picture in report
        Image is the title image on www.tenaka.net, if you wish to download image and confirm base64 and that it contains nothing malicious 

        [convert]::ToBase64String((get-content -path C:\Image\Image.png -Encoding Byte)) >> C:\image\base.txt

        [convert]::FromBase64String((get-content -path C:\Image\base.txt -Encoding Byte)) >> C:\image\Image.png   
    #>
    $basePNG = '<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAE4gAAATgCAYAAAAbRqi8AAAAAXNSR0IArs4c6QAAIABJREFUeF7s3L+LnVd6B/BzJsN4BCoEkQoVtrewG6uyK5VqV50NA1Y0kk1ARZTCArkQaI1GyKDOJotlaeps5T8i+Q+2se8Eg8GFWzdxwCFGc0/QDgtO1rr3vfd975nz46NW7z3neT7fA9N9Y/CPAAECBAgQIECAAAECBAgQIJBJ4N8Pfrf7P//19/+d6brR16SUbvz+sz//afRBDiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMBAgTjwO58RIECAAAECBAgQIECAAAECBEYLKIgbTegAAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQaF1AQ13jA1iNAgAABAgQIECBAgAABAiUJKIgrKQ2zECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBQooCCuBJTMRMBAgQIECBAgAABAgQIEGhUQEFco8FaiwABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACByQQUxE1G6SACBAgQIECAAAECBAgQIEBgmYCCuGVC/p8AAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgd4FFMT1/gLsT4AAAQIECBAgQIAAAQIEMgooiMuI7SoCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBKoUUBBXZWyGJkCAAAECBAgQIECAAAECdQooiKszN1MTIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIJBPQEFcPms3ESBAgAABAgQIECBAgACB7gUUxHX/BAAQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQILBEQEGcJ0KAAAECBAgQIECAAAECBAhkE1AQl43aRQQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIVCqgIK7S4IxNgAABAgQIECBAgAABAgRqFFAQV2NqZiZAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAIKeAgric2u4iQIAAAQIECBAgQIAAAQKdCyiI6/wBWJ8AAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgaUCCuKWEvmAAAECBAgQIECAAAECBAgQmEpAQdxUks4hQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKBVAQVxrSZrLwIECBAgQIAAAQIECBAgUKCAgrgCQzESAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQJFCSiIKyoOwxAgQIAAAQIECBAgQIAAgbYFFMS1na/tCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAYL6AgbryhEwgQIECAAAECBAgQIECAAIGBAgriBkL5jAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBbgUUxHUbvcUJECBAgAABAgQIECBAgEB+AQVx+c3dSIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAXQIK4urKy7QECBAgQIAAAQIECBAgQKBqAQVxVcdneAIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEMggoiMuA7AoCBAgQIECAAAECBAgQIEDgREBBnJdAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBxQIK4rwQAgQIECBAgAABAgQIECBAIJuAgrhs1C4iQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKBSAQVxlQZnbAIECBAgQIAAAQIECBAgUKOAgrgaUzMzAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQI5BRTE5dR2FwECBAgQIECAAAECBAgQ6FxAQVznD8D6BAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgsFVAQt5TIBwQIECBAgAABAgQIECBAgMBUAgrippJ0DgECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECrQooiGs1WXsRIECAAAECBAgQIECAAIECBRTEFRiKkQgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQKEpAQVxRcRiGAAECBAgQIECAAAECBAi0LaAgru18bUeAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwHgBBXHjDZ1AgAABAgQIECBAgAABAgQIDBRQEDcQymcECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECHQroCCu2+gtToAAAQIECBAgQIAAAQIE8gsoiMtv7kYCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBOoSUBBXV16mJUCAAAECBAgQIECAAAECVQsoiKs6PsMTIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIJBBQEFcBmRXECBAgAABAgQIECBAgAABAicCCuK8BAIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECCwWUBDnhRAgQIAAAQIECBAgQIAAAQLZBBTEZaN2EQECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAEClQooiKs0OGMTIECAAAECBAgQIECAAIEaBRTE1ZiamQkQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQyCmgIC6ntrsIECBAgAABAgQIECBAgEDnAgriOn8A1idAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAYKmAgrilRD4gQIAAAQIECBAgQIAAAQIEphJQEDeVpHMIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEGhVQEFcq8naiwABAgQIECBAgAABAgQIFCigIK7AUIxEgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEBRAgriiorDMAQIECBAgAABAgQIECBAoG0BBXFt52s7AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgTGCyiIG2/oBAIECBAgQIAAAQIECBAgQGCggIK4gVA+I0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECgWwEFcd1Gb3ECBAgQIECAAAECBAgQIJBfQEFcfnM3EiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBQl4CCuLryMi0BAgQIECBAgAABAgQIEKhaQEFc1fEZngABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBDAIK4jIgu4IAAQIECBAgQIAAAQIECBA4EVAQ5yUQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgsYCCOC+EAAECBAgQIECAAAECBAgQyCagIC4btYsIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEKhUQEFcpcEZmwABAgQIECBAgAABAgQI1CigIK7G1MxMgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEBOAQVxObXdRYAAAQIECBAgQIAAAQIEOhdQENf5A7A+AQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQJLBRTELSXyAQECBAgQIECAAAECBAgQIDCVgIK4qSSdQ4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAqwIK4lpN1l4ECBAgQIAAAQIECBAgQKBAAQVxBYZiJAIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEihJQEFdUHIYhQIAAAQIECBAgQIAAAQJtCyiIaztf2xEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgMF5AQdx4QycQIECAAAECBAgQIECAAAECAwUUxA2E8hkBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAt0KKIjrNnqLEyBAgAABAgQIECBAgACB/AIK4vKbu5EAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgboEFMTVlZdpCRAgQIAAAQIECBAgQIBA1QIK4qqOz/AECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECGQQUBCXAdkVBAgQIECAAAECBAgQIECAwImAgjgvgQABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAosFFMR5IQQIECBAgAABAgQIECBAgEA2AQVx2ahdRIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBApQIK4ioNztgECBAgQIAAAQIECBAgQKBGAQVxNaZmZgIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEcgooiMup7S4CBAgQIECAAAECBAgQINC5gIK4zh+A9QkQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQWCqgIG4pkQ8IECBAgAABAgQIECBAgACBqQQUxE0l6RwCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBFoVUBDXarL2IkCAAAECBAgQIECAAAECBQooiCswFCMRIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIFCUgIK4ouIwDAECBAgQIECAAAECBAgQaFtAQVzb+dqOAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIHxAgrixhs6gQABAgQIECBAgAABAgQIEBgooCBuIJTPCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBDoVkBBXLfRW5wAAQIECBAgQIAAAQIECOQXUBCX39yNBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAjUJaAgrq68TEuAAAECBAgQIECAAAECBKoWUBBXdXyGJ0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEAgg4CCuAzIriBAgAABAgQIECBAgAABAgROBBTEeQkECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBBYLKAgzgshQIAAAQIECBAgQIAAAQIEsgkoiMtG7SICBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBCoVUBBXaXDGJkCAAAECBAgQIECAAAECNQooiKsxNTMTIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIJBTQEFcTm13ESBAgAABAgQIECBAgACBzgUUxHX+AKxPgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMBSAQVxS4l8QIAAAQIECBAgQIAAAQIECEwloCBuKknnECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECDQqoCCuFaTtRcBAgQIECBAgAABAgQIEChQQEFcgaEYiQABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBogQUxBUVh2EIECBAgAABAgQIECBAgEDbAgri2s7XdgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIjBdQEDfe0AkECBAgQIAAAQIECBAgQIDAQAEFcQOhfEaAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQLcCCuK6jd7iBAgQIECAAAECBAgQIEAgv4CCuPzmbiRAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoC4BBXF15WVaAgQIECBAgAABAgQIECBQtYCCuKrjMzwBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAhkEFMRlQHYFAQIECBAgQIAAAQIECBAgcCKgIM5LIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwGIBBXFeCAECBAgQIECAAAECBAgQIJBNQEFcNmoXESBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBQqYCCuEqDMzYBAgQIECBAgAABAgQIEKhRQEFcjamZmQABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBnAIK4nJqu4sAAQIECBAgQIAAAQIECHQuoCCu8wdgfQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIElgooiFtK5AMCBAgQIECAAAECBAgQIEBgKgEFcVNJOocAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgVYFFMS1mqy9CBAgQIAAAQIECBAgQIBAgQIK4goMxUgECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBQloCCuqDgMQ4AAAQIECBAgQIAAAQIE2hZQENd2vrYjQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGC8gIK48YZOIECAAAECBAgQIECAAAECBAYKKIgbCOUzAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgS6FVAQ1230FidAgAABAgQIECBAgAABAvkFFMTlN3cjAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQJ1CSiIqysv0xIgQIAAAQIECBAgQIAAgaoFFMRVHZ/hCRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBDIIKAgLgOyKwgQIECAAAECBAgQIECAAIETAQVxXgIBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQWCyiI80IIECBAgAABAgQIECBAgACBbAIK4rJRu4gAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgUoFFMRVGpyxCRAgQIAAAQIECBAgQIBAjQIK4mpMzcwECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECOQUUBCXU9tdBAgQIECAAAECBAgQIECgcwEFcZ0/AOsTIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQILBUQEHcUiIfECBAgAABAgQIECBAgAABAlMJKIibStI5BAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAi0KqAgrtVk7UWAAAECBAgQIECAAAECBAoUUBBXYChGIkCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECgKAEFcUXFYRgCBAgQIECAAAECBAgQINC2gIK4tvO1HQECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAjvkO+kAAAgAElEQVQQIECAAAEC4wUUxI03dAIBAgQIECBAgAABAgQIECAwUEBB3EAonxEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAg0K2Agrhuo7c4AQIECBAgQIAAAQIECBDIL6AgLr+5GwkQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQqEtAQVxdeZmWAAECBAgQIECAAAECBAhULaAgrur4DE+AAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQAYBBXEZkF1BgAABAgQIECBAgAABAgQInAgoiPMSCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgsFhAQZwXQoAAAQIECBAgQIAAAQIECGQTUBCXjdpFBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAhUKqAgrtLgjE2AAAECBAgQIECAAAECBGoUUBBXY2pmJkCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEAgp4CCuJza7iJAgAABAgQIECBAgAABAp0LKIjr/AFYnwABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBpQIK4pYS+YAAAQIECBAgQIAAAQIECBCYSkBB3FSSziFAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoFUBBXGtJmsvAgQIECBAgAABAgQIECBQoICCuAJDMRIBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAkUJKIgrKg7DECBAgAABAgQIECBAgACBtgUUxLWdr+0IECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEBgvoCBuvKETCBAgQIAAAQIECBAgQIAAgYECCuIGQvmMAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIFuBRTEdRu9xQkQIECAAAECBAgQIECAQH4BBXH5zd1IgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEBdAgri6srLtAQIECBAgAABAgQIECBAoGoBBXFVx2d4AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQyCCiIy4DsCgIECBAgQIAAAQIECBAgQOBEQEGcl0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIHFAgrivBACBAgQIECAAAECBAgQIEAgm4CCuGzULiJAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoFIBBXGVBmdsAgQIECBAgAABAgQIECBQo4CCuBpTMzMBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAjkFFMTl1HYXAQIECBAgQIAAAQIECBDoXEBBXOcPwPoECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECCwVUBC3lMgHBAgQIECAAAECBAgQIECAwFQCCuKmknQOAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQKtCiiIazVZexEgQIAAAQIECBAgQIAAgQIFFMQVGIqRCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAoSkBBXFFxGIYAAQIECBAgQIAAAQIECLQtoCCu7XxtR4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDAeAEFceMNnUCAAAECBAgQIECAAAECBAgMFFAQNxDKZwQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIdCugIK7b6C1OgAABAgQIECBAgAABAgTyCyiIy2/uRgIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIE6hJQEFdXXqYlQIAAAQIECBAgQIAAAQJVCyiIqzo+wxMgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgkEFAQVwGZFcQIECAAAECBAgQIECAAAECJwIK4rwEAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQILBZQEOeFECBAgAABAgQIECBAgAABAtkEFMRlo3YRAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQKVCiiIqzQ4YxMgQIAAAQIECBAgQIAAgRoFFMTVmJqZCRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBDIKaAgLqe2uwgQIECAAAECBAgQIECAQOcCCuI6fwDWJ0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgqYCCuKVEPiBAgAABAgQIECBAgAABAgSmElAQN5WkcwgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQaFVAQVyrydqLAAECBAgQIECAAAECBAgUKKAgrsBQjESAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQFECCuKKisMwBAgQIECAAAECBAgQIECgbQEFcW3nazsCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBMYLKIgbb+gEAgQIECBAgAABAgQIECBAYKCAgriBUD4jQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKBbAQVx3UZvcQIECBAgQIAAAQIECBAgkF9AQVx+czcSIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIFCXgIK4uvIyLQECBAgQIECAAAECBAgQqFpAQVzV8RmeAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIEMAgriMiC7ggABAgQIECBAgAABAgQIEDgRUBDnJRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGCxgII4L4QAAQIECBAgQIAAAQIECBDIJqAgLhu1iwgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQqFRAQVylwRmbAAECBAgQIECAAAECBAjUKKAgrsbUzEyAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQE4BBXE5td1FgAABAgQIECBAgAABAgQ6F1AQ1/kDsD4BAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAksFFMQtJfIBAQIECBAgQIAAAQIECBAgMJWAgripJJ1DgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgECrAgriWk3WXgQIECBAgAABAgQIECBAoEABBXEFhmIkAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgSKElAQV1QchiFAgAABAgQIECBAgAABAm0LKIhrO1/bESBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECAwXkBB3HhDJxAgQIAAAQIECBAgQIAAAQIDBRTEDYTyGQECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAEC3QooiOs2eosTIECAAAECBAgQIECAAIH8Agri8pu7kQABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBugQUxNWVl2kJECBAgAABAgQIECBAgEDVAgriqo7P8AQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIZBBQEJcB2RUECBAgQIAAAQIECBAgQIDAiYCCOC+BAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECiwUUxHkhBAgQIECAAAECBAgQIECAQDYBBXHZqF1EgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEClAgriKg3O2AQIECBAgAABAgQIECBAoEYBBXE1pmZmAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgRyCiiIy6ntLgIECBAgQIAAAQIECBAg0LmAgrjOH4D1CRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBBYKqAgbimRDwgQIECAQD0CR8/+4c2U/u7VS//0r/9Wz9QmJUCAAAECBHoSUBDXU9p2JUCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgHQEFceuo+Q0BAgQIEChMYPb05ttpnv4QYno3pvDHS//8pzuFjWgcAgQIECBAgMBfBBTEeQgECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBBYLKAgzgshQIAAAQIVC8yeXX8rHW89elEMF0L8y9/1mNK/KIirOFSjEyBAgACBxgUUxDUesPUIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEBgtoCBuNKEDCBAgQIBAfoHZk/03UowPQwrvhxi2fj2Bgrj8ebiRAAECBAgQGC6gIG64lS8JECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEOhTQEFcn7nbmgABAgQqFZgd3nht/jw8CCHdjDFu/9YaCuIqDdfYBAgQIECgEwEFcZ0EbU0CBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBNYWUBC3Np0fEiBAgACBfAJHh/sX58fxfgjpVghxZ9HNCuLy5eImAgQIECBAYHUBBXGrm/kFAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQJ9CSiI6ytv2xIgQIBAZQLfHl47/8vz7XshpNsxxjNDxlcQN0TJNwQIECBAgMBpCSiIOy159xIgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgUIuAgrhakjInAQIECHQl8P3nH577eef44xTSRyHGs6ssryBuFS3fEiBAgAABArkFFMTlFncfAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQK1CSiIqy0x8xIgQIBA0wKzJ3tnU9y9k1K4G2M4t86yCuLWUfMbAgQIECBAIJeAgrhc0u4hQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKBWAQVxtSZnbgIECBBoSuCHz/bO/PTK7u0U070Q4vkxyymIG6PntwQIECBAgMCmBRTEbVrY+QQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQI1C6gIK72BM1PgAABAlULzL7a20k/7t4KId0PIV6cYhkFcVMoOoMAAQIECBDYlICCuE3JOpcAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgVYEFMS1kqQ9CBAgQKAqgXRwZfubC69+EEP6JMT4+pTDK4ibUtNZBAgQIECAwNQCCuKmFnUeAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQKtCSiIay1R+xAgQIBA0QLp4GDr6MJ311IMD0KIb25iWAVxm1B1JgECBAgQIDCVgIK4qSSdQ4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAqwIK4lpN1l4ECBAgUJRASiHOnu2/F+bxYYjh0iaHUxC3SV1nEyBAgAABAmMFFMSNFfR7AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgRaF1AQ13rC9iNAgACBUxV4UQz3H09u/P44pkcxxndyDKMgLoeyOwgQIECAAIF1BRTErSvndwQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQI9CKgIK6XpO1JgAABAtkFjr64cTVnMdxfF1QQlz1qFxIgQIAAAQIrCCiIWwHLpwQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIdCmgIK7L2C1NgAABApsU+Prp/pWQwuMY4uVN3vOysxXEnYa6OwkQIECAAIGhAgrihkr5jgABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBXgUUxPWavL0JECBAYHKBoy+vX56H+DiEeGXyw1c4UEHcClg+JUCAAAECBLILKIjLTu5CAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQqE1AQV1lgxiVAgACB8gRmT2++PZ+nT2MMV0uYTkFcCSmYgQABAgQIEHiZgII4b4MAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQKLBRTEeSEECBAgQGBNgdmz62+l461HIaZ3Q4jF/E1VELdmoH5GgAABAgQIZBFQEJeF2SUECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECFQsUEyZTcWGRidAgACBzgRmT/bfSDE+DCm8H2LYKm19BXGlJWIeAgQIECBA4NcCCuK8BwIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECCwWUBDnhRAgQIAAgYECs8Mbr82fhwchpJsxxu2BP8v+mYK47OQuJECAAAECBFYQUBC3ApZPCRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBDoUkBBXJexW5oAAQIEVhE4Oty/OD+O90NIt0KIO6v89jS+VRB3GuruJECAAAECBIYKKIgbKuU7AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgR6FVAQ12vy9iZAgACBpQLfHl47/8vz7XshpNsxxjNLf1DIBwriCgnCGAQIECBAgMBvCiiI8zAIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECCwWEBBnBdCgAABAgT+n8D3n3947ued449TSB+FGM/WBqQgrrbEzEuAAAECBPoSUBDXV962JUCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgdQEFcaub+QUBAgQINCowe7J3NsXdOymFuzGGc7WuqSCu1uTMTYAAAQIE+hBQENdHzrYkQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGB9AQVx69v5JQECBAg0IvDDZ3tnfnpl93aK6V4I8XztaymIqz1B8xMgQIAAgbYFFMS1na/tCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAYL6AgbryhEwgQIECgUoEXxXD/ubv7jyGk+yHEi5Wu8TdjK4hrJUl7ECBAgACBNgUUxLWZq60IECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEJhOQEHcdJZOIkCAAIFKBGZf7e2kH3dvtVYM91d+BXGVPERjEiBAgACBTgUUxHUavLUJECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEBgsoCBuMJUPCRAgQKB2gXRwZfubC69+EEP6JMT4eu37vGx+BXGtJmsvAgQIECDQhoCCuDZytAUBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABApsTUBC3OVsnEyBAgEAhAungYOvownfXUgwPQohvFjLWxsZQELcxWgcTIECAAAECEwgoiJsA0REECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECDQtoCCu6XgtR4AAgb4FUgpx9mz/vTCPD0MMl3rRUH4iiIoAACAASURBVBDXS9L2JECAAAECdQooiKszN1MTIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIJBPQEFcPms3ESBAgEBGgaMvblw9julRjPGdjNcWcZWCuCJiMAQBAgQIECDwEgEFcZ4GAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEFgsoiPNCCBAgQKApga+f7l8JKTyOIV5uarEVllEQtwKWTwkQIECAAIHsAgrispO7kAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBygQUxFUWmHEJECBA4LcFjr68fnke4uMQ4pXejRTE9f4C7E+AAAECBMoWUBBXdj6mI0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEDg9AUUxJ1+BiYgQIAAgRECs6c3357P06cxhqsjjmnqpwrimorTMgQIECBAoDkBBXHNRWohAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQmFlAQNzGo4wgQIEAgj8Ds2fW30vHWoxDTuyFEf89+xa4gLs8bdAsBAgQIECCwnoCCuPXc/IoAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgX4EFOr0k7VNCRAg0ITA7Mn+GynGhyGF90MMW00sNfESCuImBnUcAQIECBAgMKmAgrhJOR1GgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgECDAgriGgzVSgQIEGhRYHZ447X58/AghHQzxrjd4o5T7aQgbipJ5xAgQIAAAQKbEFAQtwlVZxIgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAg0JKAgriW0rQLAQIEGhQ4Oty/OD+O90NIt0KIOw2uOPlKCuImJ3UgAQIECBAgMKGAgrgJMR1FgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgECTAgrimozVUgQIEKhf4EUx3PHzeDeEdDvGeKb+jfJtoCAun7WbCBAgQIAAgdUFFMStbuYXBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAj0JaAgrq+8bUuAAIHiBb49vHb+l+fb9xTDrR+Vgrj17fySAAECBAgQ2LyAgrjNG7uBAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIG6BRTE1Z2f6QkQINCMwPeff3ju553jj1NIH4UYzzaz2CksoiDuFNBdSYAAAQIECAwWUBA3mMqHBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAh0KqAgrtPgrU2AAIFSBGZP9s6muHsnpXA3xnCulLlqnkNBXM3pmZ0AAQIECLQvoCCu/YxtSIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDAOAEFceP8/JoAAQIE1hT44bO9Mz+9sns7xXQvhHh+zWP87DcEFMR5FgQIECBAgEDJAgriSk7HbAQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIlCCgIK6EFMxAgACBjgRmX+3tpB93b4WQ7ocQL3a0erZVFcRlo3YRAQIECBAgsIaAgrg10PyEAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIGuBBTEdRW3ZQkQIHB6AungyvY3F179IIb0SYjx9dObpP2bFcS1n7ENCRAgQIBAzQIK4mpOz+wECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECOQQUBCXQ9kdBAgQ6FggHRxsHV347lqK4UEI8c2OKbKtriAuG7WLCBAgQIAAgTUEFMStgeYnBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAh0JaAgrqu4LUuAAIF8AimFOHu2/16Yx4chhkv5bnaTgjhvgAABAgQIEChZQEFcyemYjQABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBEgQUxJWQghkIECDQmMDRFzeuHsf0KMb4TmOrVbGOgrgqYjIkAQIECBDoVkBBXLfRW5wAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgYECCuIGQvmMAAECBJYLfP10/0pI4XEM8fLyr32xKQEFcZuSdS4BAgQIECAwhYCCuCkUnUGAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQMsCCuJaTtduBAgQyCRw9OX1y/MQH4cQr2S60jULBBTEeR4ECBAgQIBAyQIK4kpOx2wECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECJQgoCCuhBTMQIAAgUoFZk9vvj2fp09jDFcrXaHJsRXENRmrpQgQIECAQDMCCuKaidIiBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAhsSEBB3IZgHUuAAIGWBV4Uw6V5+kOI6d0Qor8lhYWtIK6wQIxDgAABAgQI/B8BBXEeBAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBBYLKPXxQggQIEBgsMDs2fW30vHWI8Vwg8lO5UMFcafC7lICBAgQIEBgoICCuIFQPiNAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoFsBBXHdRm9xAgQIDBeYPdl/I8X4MKTwfohha/gvfXkaAgriTkPdnQQIECBAgMBQAQVxQ6V8R4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBArwIK4npN3t4ECBAYIDA7vPHa/Hl4EEK6GWPcHvATnxQgoCCugBCMQIAAAQIECLxUQEGcx0GAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIHFAgrivBACBAgQ+BuBo8P9i/PjeD+EdCuEuIOoLgEFcXXlZVoCBAgQINCbgIK43hK3LwECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECqwooiFtVzPcECBBoWODbw2vnf3m+fS+EdDvGeKbhVZteTUFc0/FajgABAgQIVC+gIK76CC1AgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMCGBRTEbRjY8QQIEKhB4PvPPzz3887xxymkj0KMZ2uY2YwvF1AQ53UQIECAAAECJQsoiCs5HbMRIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIFCCgIK4ElIwAwECBE5JYPZk72yKu3dSCndjDOdOaQzXTiygIG5iUMcRIECAAAECkwooiJuU02EECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECDQooCCuwVCtRIAAgWUCP3y2d+anV3Zvp5juhRDPL/ve/9cloCCurrxMS4AAAQIEehNQENdb4vYlQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGBVAQVxq4r5ngABAhULzL7a20k/7t4KId0PIV6seBWjLxBQEOd5ECBAgAABAiULKIgrOR2zESBAgAABAgQIECBAgAABAgQI/C979x/kd13fi/71/mYJCUbMaLCmVbjtDbUXFMiurdHqNKf+YDfq9YA3LZTw43gEbZQf2Y02NkUSw5G2uBvbEiCd8faeO72de2xv70yZshvU0mk91nva3bSFzakjHac6c7Q92BmpcgSz3/cdtB2hQvLd3c/38/Phv/v5vH48Xh+CDOQZAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgTqICAgrg5XMAMBAgSGLJAPbB95+JyXXZsi3xopnTfkdspXLCAgruIDaE+AAAECBAicUkBAnA+EAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECpxYQEOcLIUCAQIsF8oEDvRPnPHJlTnFbRDq/xata7WkCAuJ8DgQIECBAgECdBQTE1fk6ZiNAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoA4CAuLqcAUzECBAoGCBnCMt3rvr8uing5HiwoLLK1dzAQFxNT+Q8QgQIECAQMcFBMR1/AOwPgECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECpxUQEHdaIg8QIECgOQJPBcP91yNXTyylfCilNNqcyU1apICAuCI11SJAgAABAgSKFhAQV7SoegQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQItE1AQFzbLmofAgQ6K3Dirqt3CIbr7PmfsbiAON8BAQIECBAgUGcBAXF1vo7ZCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBCog4CAuDpcwQwECBBYhcBD9+zaHjnuSJG2raKMV1skICCuRce0CgECBAgQaKGAgLgWHtVKBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgUKiAgrlBOxQgQIFCewIm7r9rWj3RHRNpeXledmiAgIK4JVzIjAQIECBDoroCAuO7e3uYECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECAwmICBuMCdPESBAoDYCi/dcs7Xfz7enFDtqM5RBaiUgIK5W5zAMAQIECBAg8K8EBMT5JAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIHBqAQFxvhACBAg0RGDx3qsuyEu9Q5HyZRHJr98NuVsVYwqIq0JdTwIECBAgQGBQAQFxg0p5jgABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBrgoIGOrq5e1NgEBjBBaP7NqSUzoYOa6IFL3GDG7QygQExFVGrzEBAgQIECAwgICAuAGQPEKAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQKcFBMR1+vyWJ0CgzgKLR68+t38ybovI16SURuo8q9nqJSAgrl73MA0BAgQIECDwTAEBcb4IAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQInFpAQJwvhAABAjUTOHF01+b+Utofka+PSGtrNp5xGiAgIK4BRzIiAQIECBDosICAuA4f3+oECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECAwkICBuICYPESBAYPgCnz965aYnT47si8i7U0rrh99Rh7YKCIhr62XtRYAAAQIE2iEgIK4dd7QFAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQLDExAQNzxblQkQIDCQwBcPX7fx8bVLe3PkmyOlDQO95CECpxAQEOfzIECAAAECBOosICCuztcxGwECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECdRAQEFeHK5iBAIFOCiwe2bkhp3W35BxTKcXGTiJYeigCAuKGwqooAQIECBAgUJCAgLiCIJUhQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKC1AgLiWntaixEgUFeBp4LhIta9O6e8LyJtquuc5mqugIC45t7O5AQIECBAoAsCAuK6cGU7EiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECCwGgEBcavR8y4BAgSWIfDlmZ3rHztz3W7BcMtA8+iKBATErYjNSwQIECBAgEBJAgLiSoLWhgABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBxgoIiGvs6QxOgEBTBBY/sXNtfnTd9RF5f0Ta3JS5zdlcAQFxzb2dyQkQIECAQBcEBMR14cp2JECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgNQIC4laj510CBAicQiAf2D7y8DkvuzZFvjVSOg8WgbIEBMSVJa0PAQIECBAgsBIBAXErUfMOAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQJdEhAQ16Vr25UAgVIE8oEDvRPnPHJlTnFbRDq/lKaaEHiagIA4nwMBAgQIECBQZwEBcXW+jtkIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEKiDgIC4OlzBDAQItEIg50iL9+66PPrpYKS4sBVLWaKRAgLiGnk2QxMgQIAAgc4ICIjrzKktSoAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDACgUExK0QzmsECBB4usCJu67esZTyoZTSKBkCVQsIiKv6AvoTIECAAAECpxIQEOf7IECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwKkFBMT5QggQILAKgYfu2bU9ctyRIm1bRRmvEihUQEBcoZyKESBAgAABAgULCIgrGFQ5AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgRaJyAgrnUntRABAmUInLj7qm39SHdEpO1l9NODwHIEBMQtR8uzBAgQIECAQNkCAuLKFtePAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIGmCQiIa9rFzEuAQKUCi/dcs7Xfz7enFDsqHURzAqcQEBDn8yBAgAABAgTqLCAgrs7XMRsBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAnUQEBBXhyuYgQCB2gss3nvVBXmpdyhSviwi+bWz9hfr9oAC4rp9f9sTIECAAIG6CwiIq/uFzEeAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQNUCQo6qvoD+BAjUWmDxyK4tOaWDkeOKSNGr9bCGI/DPAgLifAoECBAgQIBAnQUExNX5OmYjQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKAOAgLi6nAFMxAgUDuBxaNXn9s/GbdF5GtSSiO1G9BABE4hICDO50GAAAECBAjUWUBAXJ2vYzYCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBOogICCuDlcwAwECtRF4KhguL8UHIvL1EWltbQYzCIFlCAiIWwaWRwkQIECAAIHSBQTElU6uIQECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECDRMQENewgxmXAIHhCJw4umtzfyntFww3HF9VyxUQEFeut24ECBAgQIDA8gQExC3Py9MECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECHRPQEBc925uYwIEnibw+aNXbnry5Mi+iLw7pbQeDoE2CAiIa8MV7UCAAAECBNorICCuvbe1GQECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECxQgIiCvGURUCBBom8MXD1218fO3S3hz55khpQ8PGNy6BUwoIiPOBECBAgAABAnUWEBBX5+uYjQABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBOggIiKvDFcxAgEBpAotHdm7Iad0tOcdUSrGxtMYaEShRQEBcidhaESBAgAABAssWEBC3bDIvECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECDQMQEBcR07uHUJdFXgyzM71z925rrdOeV9EWlTVx3s3Q0BAXHduLMtCRAgQIBAUwUExDX1cuYmQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKAsAQFxZUnrQ4BAJQKLn9i5Nj+67vqIvD8iba5kCE0JlCwgIK5kcO0IECBAgACBZQkIiFsWl4cJECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEOiggIC4Dh7dygS6IJAPbB95+JyXXZsi3xopndeFne1I4F8EBMT5FggQIECAAIE6CwiIq/N1zEaAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQB0EBMTV4QpmIECgMIF84EDvxDmPXJlT3BaRzi+ssEIEGiQgIK5BxzIqAQIECBDooICAuA4e3coECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgRt5G8wAAIABJREFUQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECCxLQEDcsrg8TIBAXQVyjrR4767Lo58ORooL6zqnuQiUISAgrgxlPQgQIECAAIGVCgiIW6mc9wgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQ6IqAgLiuXNqeBFoscOKuq3cspXwopTTa4jWtRmBgAQFxA1N5kAABAgQIEKhAQEBcBehaEiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECDQKAEBcY06l2EJEHi6wEP37NoeOe5IkbaRIUDgewIC4nwNBAgQIECAQJ0FBMTV+TpmI0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECgDgIC4upwBTMQILAsgRN3X7WtH+mOiLR9WS96mEBHBATEdeTQ1iRAgAABAg0VEBDX0MMZmwABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACB0gQExJVGrREBAqsVeCoYbin3bk0pdqy2lvcJtFlAQFybr2s3AgQIECDQfAEBcc2/oQ0IECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEBiugIC44fqqToBAAQKL91yztd/PtwuGKwBTiU4ICIjrxJktSYAAAQIEGisgIK6xpzM4AQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIlCQiIKwlaGwIEli+weO9VF+Sl3qFI+bKI5Ner5RN6o6MCAuI6enhrEyBAgACBhggIiGvIoYxJgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEBlAgKXKqPXmACB5xJYPLJrS07pYOS4IlL0SBEgsDwBAXHL8/I0AQIECBAgUK6AgLhyvXUjQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKB5AgLimnczExNorcDi0avP7Z+M2yLyNSmlkdYuajECQxYQEDdkYOUJECBAgACBVQkIiFsVn5cJECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEOiAgIC4DhzZigTqLnDi6K7N/aW0PyJfH5HW1n1e8xGou4CAuLpfyHwECBAgQKDbAgLiun1/2xMgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgcHoBAXGnN/IEAQJDEvj80Ss3PXlyZF9E3p1SWj+kNsoS6JyAgLjOndzCBAgQIECgUQIC4hp1LsMSIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIFCBgIC4CtC1JNB1gS8evm7j42uX9ubIN0dKG7ruYX8CRQsIiCtaVD0CBAgQIECgSAEBcUVqqkWAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQBsFBMS18ap2IlBTgcUjOzfktO6WnGMqpdhY0zGNRaDxAgLiGn9CCxAgQIAAgVYLCIhr9XktR4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAAQIC4gpAVIIAgVMLfHlm5/rHzly3O6e8LyJt4kWAwHAFBMQN11d1AgQIECBAYHUCAuJW5+dtAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgTaLyAgrv03tiGBygQWP7FzbX503fUReX9E2lzZIBoT6JiAgLiOHbwD6356z8U/dLLXu/zS6eO/0YF1rUiAAIHWCwiIa/2JLUiAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwCoFBMStEtDrBAh8v0A+sH3k4XNedm2KfGukdB4jAgTKFRAQV663bsMTmLtlbHP08v5I6b2R82fHZxZ+cnjdVCZAgACBsgQExJUlrQ8BAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAk0VEBDX1MuZm0ANBfKBA70T5zxyZU5xW0Q6v4YjGolAJwQExHXizK1e8sGpsU1PROzLOXanFOu/s6yAuFbf3HIECHRLQEBct+5tWwIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEli8gIG75Zt4gQOBfCTwVDLf4A49cFv10MFJcCIgAgWoFBMRV66/7ygUevOWSjU+s6b0/ctwUKW14RiUBcSuH9SYBAgRqJiAgrmYHMQ4BAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABArUTEBBXu5MYiEBzBHKOtHjvrssFwzXnZibthoCAuG7cuU1bPrj7gg1PrFu/J1JMRcQLnnU3AXFtOrldCBDouICAuI5/ANYnQIAAAQIECBAgQIAAAQIECBAg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QIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgaoEBMRVJa8vgSEJLH5i59r86LrrI/L+iLR5SG2UJUCgxgIC4mp8nAaNNnfL2OZYEx+KiPfUYmwBcbU4gyEIECBQhICAuCIU1SBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoM0CAuLafF27dUogH9g+8vA5L7s2Rb41UjqvU8tblgCBZwgIiPNBrEbgwamxTU/kvD9SeioYbt1qahX6roC4QjkVI0CAQJUCAuKq1NebAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIEmCAiIa8KVzEjgFAL5wIHeiXMeuTKnuC0inQ+LAAECAuJ8AysRePCWSzZ+a82aX0iRb4xIz1tJjaG+IyBuqLyKEyBAoEwBAXFlautFgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEATBQTENfFqZiYQETlHWrx31+XRTwcjxYVQCBAg8C8CAuJ8C8sRuP/GLWenM86ejEh7Uoqzl/Nuqc8KiCuVWzMCBAgMU0BA3DB11SZAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoA0CAuLacEU7dE7gxF1X71hK+VBKabRzy1uYAIHTCgiIOy2RByLivhvGzhp5ftyUcrw/Uryw9igC4mp/IgMSIEBgUAEBcYNKeY4AAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAga4KCIjr6uXt3UiBh+7ZtT1y3JEibWvkAoYmQKAUAQFxpTA3usns1OieFLEvIr24MYsIiGvMqQxKgACB0wkIiDudkJ8TIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQINB1AQFxXf8C7N8IgRN3X7WtH+mOiLS9EQMbkgCBSgUExFXKX+vmxybHfr4feX9K6YdqPeizDScgrnEnMzABAgSeS0BAnG+DAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECpxYQEOcLIVBjgcV7rtna7+fbU4odNR7TaAQI1ExAQFzNDlKDceb2jv676MeHIqX/qQbjrGwEAXErc/MWAQIEaiggIK6GRzESAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQK1EhAQV6tzGIbAdwUW773qgrzUOxQpXxaR/HXqwyBAYFkCAuKWxdXqh+f2jP1c9PKBiHR+4xcVENf4E1qAAAEC/yIgIM63QIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgVMLCJ7yhRCokcDikV1bckoHI8cVkaJXo9GMQoBAgwQExDXoWEMadXZq9PKU04cjxYVDalF+WQFx5ZvrSIAAgSEJCIgbEqyyBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAi0RkBAXGtOaZEmCywevfrc/sm4LSJfk1IaafIuZidAoHoBAXHV36CqCeb2jr0l+vFUMNxoVTMMra+AuKHRKkyAAIGyBQTElS2uHwECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECTRMQENe0i5m3VQJPBcPlpfhARL4+Iq1t1XKWIUCgMgEBcZXRV9Z4dnLrG1JKhyLSayobYtiNBcQNW1h9AgQIlCYgIK40ao0IECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEGiogIC4hh7O2M0WOHF01+b+UtovGK7ZdzQ9gboKCIir62WKn+v+ydFtKaU7U8Triq9es4oC4mp2EOMQIEBg5QIC4lZu500CBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBLohICCuG3e2ZU0EPn/0yk1PnhzZF5F3p5TW12QsYxAg0DIBAXEtO+izrHP/5MVbU1pzR4p0afu3/ecNBcR15tQWJUCg/QIC4tp/YxsSIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQILA6AQFxq/PzNoGBBL54+LqNj69d2psj3xwpbRjoJQ8RIEBghQIC4lYI14DX7p/aekEv9z4SKd7egHGLHVFAXLGeqhEgQKBCAQFxFeJrTYAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAIwQExDXiTIZsqsDikZ0bclp3S84xlVJsbOoe5iZAoFkCAuKada9Bpp29+aKXpzUjByOlnx3k+VY+IyCulWe1FAEC3RQQENfNu9uaAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIHBBQTEDW7lSQIDC3x5Zuf6x85ctzunvC8ibRr4RQ8SIECgAAEBcQUg1qTEsb0X/XDun3EgUlxTk5GqG0NAXHX2OhMgQKBgAQFxBYMqR4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBA6wQExLXupBaqUmDxEzvX5kfXXR+R90ekzVXOojcBAt0VEBDX/Nt/es/FP/Rkb82HUqQbmr9NQRsIiCsIUhkCBAhULyAgrvobmIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgXoLCIir931M1xCBfGD7yMPnvOzaFPnWSOm8hoxtTAIEWiogIK65hz2296IX9/MZv5QibmzuFkOaXEDckGCVJUCAQPkCAuLKN9eRAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIFmCQiIa9a9TFszgXzgQO/EOY9cmVPcFpHOr9l4xiFAoKMCAuKad/i5PRe+MPfO3Bc5vTelOKt5G5QwsYC4EpC1IECAQDkCAuLKcdaFAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIHmCgiIa+7tTF6hQM6RFu/ddXn008FIcWGFo2hNgACB7xMQENecj+L+G7ec3TvjBXtziltSxPObM3kFkwqIqwBdSwIECAxHQEDccFxVJUCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECgPQIC4tpzS5uUJHDirqt3LKV8KKU0WlJLbQgQILAsAQFxy+Kq5OH7bhg7a+2GvCdH7I2UNlYyRNOaCohr2sXMS4AAgecUEBDn4yBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMCpBQTE+UIIDCjw0D27tkeOO1KkbQO+4jECBAhUIiAgrhL2gZp+ds9L1z/W+4HdOWJfitg00Ese+q6AgDhfAgECBFojICCuNae0CAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECQxIQEDckWGXbI/BUMFzKcVtE2t6erWxCgECbBQTE1fO6c3tG3xcp/WKk2FzPCWs+lYC4mh/IeAQIEBhcQEDc4FaeJECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECgmwIC4rp5d1sPIHDi7qu29SPdIRhuACyPECBQKwEBcbU6R8xNjb0rctwaKc6t12QNm0ZAXMMOZlwCBAg8t4CAOF8HAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIETi0gIM4XQuBfCSzec83Wfj/fnlLsgEOAAIEmCgiIq8fVZidHd0VKB1LE/1yPiRo+hYC4hh/Q+AQIEPiegIA4XwMBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgROLSAgzhdC4J8FFu+96oK81DsUKV8Wkfy14csgQKCxAgLiqj3d7OTYzhT5YKT0v1Q7Scu6C4hr2UGtQ4BAlwUExHX5+nYnQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGAQASFYgyh5ptUCi0d2bckpHYwcV0SKXquXtRwBAp0QEBBXzZmP7R19W+7HoUjp4momaHlXAXEtP7D1CBDokoCAuC5d264ECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECKxEQEDcStS80wqBxaNXn9s/GbdF5GtSSiOtWMoSBAgQiAgBceV+Bg/sGXtzPz0VDBc/UW7njnUTENexg1uXAIE2CwiIa/N17UaAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQBECAuKKUFSjUQInju7a3F9K+yPy9RFpbaOGNywBAgTOwixfAAAgAElEQVQGEBAQNwBSAY/MTo29LnK+M6W0rYBySpxOQEDc6YT8nAABAo0REBDXmFMZlAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBigQExFUEr235Ap8/euWmJ0+O7IvIu1NK68ufQEcCBAiUIyAgbrjOD+zZ+qp+r/eRiHjTcDup/gwBAXE+CAIECLRGQEBca05pEQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEhiQgIG5IsMrWR+CLh6/b+Pjapb058s2R0ob6TGYSAgQIDEdAQNxwXD+5Z+yVSyl/JFJ663A6qHpKAQFxPhACBAi0RkBAXGtOaRECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBIYkICBuSLDKVi+weGTnhpzW3ZJzTKUUG6ufyAQECBAoR0BAXLHOszdf9PIY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IIAAAggggAACCCCAAAIIIIAAAggggAACCCCAAAIIIIAAAggggAACLgoQEOfiVuipZwHnA+JUd6kxK4+YmKifsnLDjp4HpkCmBAiIy9Q6GQaBRAVUda8Rc22f2bticPU/jyX6OI8hgAACCCDQpgABcW1CcQwBBBBAAAEEEEAAAQQQQAABBP5/du6gN64rTQ/wd4v2JF7lT3idTXZZZZCFe/ov5Cd4EUgUAWsiRVQUoZVAastJjxajjW1RlgZE7FkpswgaXAQZbVqyKJNGbAMDG4oVNOSBANOgukjeL/B45OlJW1SxWHXrnHsfbln3nO973rN+CRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGCwAgriBht9vxcvtSAuM3Yj8s+a/N0vfvb21t/2OwXbTSugIG5aOd8RGK5AZuw3Ee/vj/bOv3Vj+6vhSticAAECBGoQUBBXQ0pmJECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgkQIK4hap7+65CZRYEJcR/3XU7P3HNy5v/nZuizu4FwIK4noRoyUIdCKQkW1k3F5qDs6dXNv6opNLXUKAAAECBI4poCDumIA+J0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECg9wIK4nof8TAXLKkgLiP//I/ag//wr99+8H+GmYatjyqgIO6oYn5PYIACmRkRH0UcnD11c2t7gAJWJkCAAIGKBRTEVRye0QkQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQ6ERAQVwnzC7pWqCIgriM95vR3uoblzf/puv93Ve3gIK4uvMzPYF5C2TkndF+c2b59oP7877L+QQIECBAYB4CCuLmoepMAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgT6JKAgrk9p2uVHgYUWxGX+RWSc+dnb974QCYFpBBTETaPmGwKDENhoMk8v39y8O4htLUmAAAECvRVQENfbaC1GgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMCMBBTEzQjSMWUJLKgg7i/baP/dz6/c3y5LwzS1CSiIqy0x8xKYs0Dm3Wza0ytrn2zM+SbHEyBAgACBTgQUxHXC7BICBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBCoWUBBXcXhGf7FApwVxmX/VxsGf/vyXD+7LhMAsBBTEzULRGQTqF8jMv45RnFm5sfnr+rexAQFqMyuKAAAgAElEQVQCBAgQ+AcBBXFeAwECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBA4XUBDnhfRSoIuCuIz4n5m58vNf3rvbS0RLLUxAQdzC6F1MoAiBjLw3avPs8gcP7xQxkCEIECBAgMCMBRTEzRjUcQQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQI9E5AQVzvIrXQ9wJzLYjL/F/NKM6+cfner2kTmIeAgrh5qDqTQAUCGVttk+dW1jY/bCKygomNSIAAAQIEphJQEDcVm48IECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEBiQgIK4AYU9pFXnUxCXv2kiz75x5f5/H5KlXbsXUBDXvbkbCSxSIDM+b5r2/M7rD2+trka7yFncTYAAAQIEuhBQENeFsjsIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEKhZQEFczemZ/YUCsyyIy4yHoyb+/RtXfvOXyAl0IaAgrgtldxAoQCDjy8y88N3Xm++tbsR+ARMZgQABAgQIdCKgIK4TZpcQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIFCxgIK4isMz+osFZlEQlxH/O9p29U/evn+bNYEuBRTEdantLgILEXjcZHvx2/HB9dX17fFCJnApAQIECBBYoICCuAXiu5oAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgSoEFMRVEZMhjypwzIK4v2kizr9x5TfvHfVevycwCwEFcbNQdAaBAgUynkTEpdH4m2sn1x/tFjihkQgQIECAQCcCCuI6YXYJAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIVCyiIqzg8o79YYJqCuIx4NIq88MaVe3/OlsAiBRTELVLf3QTmIvA02vbKa3sHV99c396Zyw0OJUCAAAECFQkoiKsoLKMSIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQILAQAQVxC2F36bwFjlIQlxH/NzJ+8Se//M1/mfdczicwiYCCuEmU/IZABQKZOxnxziuvji6fePfjpxVMbEQCBAgQINCJgIK4TphdQoAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAxQIK4ioOz+gvFpiwIO6bbPI//bOD3/7qX779aJcngVIEFMSVkoQ5CEwpkLEbkdeifXbp1K3Pnkx5is8IECBAgEBvBRTE9TZaixEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgMCMBBXEzgnRMWQKHFsRlPs0mr/zT3d9d/eNr2ztlTW4aAhEK4rwCAnUKZOa4ieb6UjO+eGLt08d1bmFqAgQIECAwfwEFcfM3dgMBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAnULKIirOz/Tv0DgJwviMr8vg3vnn7Tt5T+++vFTeARKFVAQV2oy5iLw0wKZsd9EvL8/2jv/1o3trzgRIECAAAEChwsoiPNCCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgcLiAgjgvpJcCv18Qlxm7EflnTf7uFz97e+tve7mwpXoloCCuV3FapscCGdlGxu2l5uDcybWtL3q8qtUIECBAgMBMBRTEzZTTYQQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQI9FBAQVwPQ7VSxI8FcZm/akb7F964vPlbLgRqEVAQV0tS5hyqwPNiuCYOLp66ubU9VAd7EyBAgACBaQUUxE0r5zsCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBIYioCBuKEkPbM+/Wv4X/7Zd2vtvP//Pm48Gtrp1eyCgIK4HIVqhnwKZGREfRRycVQzXz4htRYAAAQLdCCiI68bZLQQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQI1CugIK7e7ExOgEBPBRTE9TRYa1UtkJF3RvvNmeXbD+5XvYjhCRAgQIBAAQIK4goIwQgECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBQtoCCu6HgMR4DAEAUUxA0xdTsXLLDRZJ5evrl5t+AZjUaAAAECBKoSUBBXVVyGJUCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgAQIK4haA7koCBAgcJqAgzvsgUIBA5t1s2tMra59sFDCNEQgQIECAQK8EFMT1Kk7LECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECAwBwEFcXNAdSQBAgSOI6Ag7jh6viVwPIGMvDdq8+zyBw/vHO8kXxMgQIAAAQIvElAQ520QIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEDgcAEFcV4IAQIEChNQEFdYIMYZhkDGVtvkuZW1zQ+biBzG0rYkQIAAAQKLEVAQtxh3txIgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgUI+Agrh6sjIpAQIDEVAQN5CgrVmEQGZ83jTt+Z3XH95aXY22iKEMQYAAAQIEei6gIK7nAVuPAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIFjCyiIOzahAwgQIDBbAQVxs/V0GoGfFMj4MjMvfPf15nurG7FPiQABAgQIEOhOQEFcd9ZuIkCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECgTgEFcXXmZmoCBHosoCCux+FarQSBx022F78dH1xfXd8elzCQGQgQIECAwNAEFMQNLXH7EiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBwVAEFcUcV83sCBAjMWUBB3JyBHT9MgYwnEXFpNP7m2sn1R7vDRLA1AQIECBAoQ0BBXBk5mIIAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgXIFFMSVm43JCBAYqICCuIEGb+15CTyNtr3y2t7B1TfXt3fmdYlzCRAgQIAAgckFFMRNbuWXBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgMU0BB3DBztzUBAgULKIgrOByj1SOQuZMR77zy6ujyiXc/flrP4CYlQIAAAQL9F1AQ1/+MbUiAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwPEEFMQdz8/XBAgQmLmAgriZkzpwSAJ/XwzXtM+unrr12ZMhrW5XAgQIECBQi4CCuFqSMicBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAosSUBC3KHn3EiBA4AUCCuI8DQJTCGTsRuS1aJ9dUgw3hZ9PCBAgQIBAhwIK4jrEdhUBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAlUKKIirMjZDEyDQZwEFcX1O126zFsjMcRPN9aVmfPHE2qePZ32+8wgQIECAAIHZCyiIm72pEwkQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQ6JeAgrh+5WkbAgR6IKAgrgchWmHuApmx30S8vz/aO//Wje2v5n6hCwgQIECAAIGZCSiImxmlgwgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQ6KmAgrieBmstAgTqFVAQV292Jp+/QEa2kXF7qTk4d3Jt64v53+gGAgQIECBAYNYCCuJmLeo8AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgT6JqAgrm+J2ocAgeoFFMRVH6EF5iGQmRHxUcTB2VM3t7bncYUzCRAgQIAAgW4EFMR14+wWAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgTqFVAQV292JidAoKcCCuJ6Gqy1phbIyDuj/ebM8u0H96c+xIcECBAgQIBAMQIK4oqJwiAECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBQqoCCu0GCMRYDAcAUUxA03e5v/gcBGk3l6+ebmXTYECBAgQIBAfwQUxPUnS5sQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIDAfAQVx83F1KgECBKYWUBA3NZ0P+yKQeTeb9vTK2icbfVnJHgQIECBAgMA/CCiI8xoIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBwuICCOC+EAAEChQkoiCssEON0JpCR90Ztnl3+4OGdzi51EQECBAgQINC5gIK4zsldSIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAZQIK4ioLzLgECPRfQEFc/zO24f8nkLHVNnluZW3zwyYi+RAgQIAAAQL9FlAQ1+98bUeAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwPEFFMQd39AJBAgQmKmAgriZcjqsYIHM+Lxp2vM7rz+8tboabcGjGo0AAQIECBCYoYCCuBliOooAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgV4KKIjrZayWIkCgZgEFcTWnZ/aJBDK+zMwL3329+d7qRuxP9I0fESBAgAABAr0RUBDXmygtQoAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDAnAQUxM0J1rEECBCYVkBB3LRyvite4Hkx3N7+jdX17XHx8xqQAAECBAgQmIuAgri5sDqUAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIEeCSiI61GYViFAoB8CCuL6kaMt/pHA4ybbi9+OD64rhvMyCBAgQIAAAQVx3gABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQOF1AQ54UQIECgMAEFcYUFYpzpBTKeRMSl0fibayfXH+1Of5AvCRAgQIAAgT4JKIjrU5p2IUCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgHgIK4uah6kwCBAgcQ0BB3DHwfFqKwNNo2yuv7R1cfXN9e6eUocxBgAABAgQIlCGgIK6MHExBgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEC5Agriys3GZAQIDFRAQdxAg+/D2pk7GfHOK6+OLp949+OnfVjJDgQIECBAgMDsBRTEzd7UiQQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQI9EtAQVy/8rQNAQI9EFAQ14MQh7ZCxm5EXov22aVTtz57MrT17UuAAAECBAgcTUBB3NG8/JoAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgeEJKIgbXuY2JkCgcAEFcYUHZLwfBTJz3ERzfakZXzyx9uljNAQIECBAgACBSQQUxE2i5DcECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECAxZQEHckNO3OwECRQooiCsyFkP9nkBm7DcR7++P9s6/dWP7KzgECBAgQIAAgaMIKIg7ipbfEiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECAwRAEFcUNM3c4ECBQtoCCu6HgGPVxGtpFxe6k5OHdybeuLQWNYngABAgQIEJhaQEHc1HQ+JECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgIAIK4gYStDUJEKhHQEFcPVkNZtLMjIiPIg7Onrq5tT2YvS1KgAABAgQIzEVAQdxcWB1KgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgECPBBTE9ShMqxAg0A8BBXH9yLEvW2TkndF+c2b59oP7fdnJHgQIECBAgMBiBRTELdbf7QQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIlC+gIK78jExIgMDABBTEDSzwctfdaDJPL9/cvFvuiCYjQIAAAQIEahRQEFdjamYmQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKBLAQVxXWq7iwABAhMIKIibAMlP5ieQeTeb9vTK2icb87vEyQQIECBAgMCQBRTEDTl9uxMgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgMImAgrhJlPyGAAECHQooiOsQ21U/CmTmX8cozqzc2Pw1FgIECBAgQIDAPAUUxM1T19kECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECPRBQEFcH1K0AwECvRJQENerOItfJiPvjdo8u/zBwzvFD2tAAgQIECBAoBcCCuJ6EaMlCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBCYo4CCuDniOpoAAQLTCCiIm0bNN0cWyNhqmzy3srb5YRORR/7eBwQIECBAgACBKQUUxE0J5zMCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAYjoCBuMFFblACBWgQUxNWSVJ1zZsbnTdOe33n94a3V1Wjr3MLUBAgQIECAQM0CCuJqTs/sBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAh0IaAgrgtldxAgQOAIAgrijoDlp5MLZHyZmRe++3rzvdWN2J/8Q78kQIAAAQIECMxWQEHcbD2dRoAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBA/wQUxPUvUxsRIFC5gIK4ygMsb/zHTbYXvx0fXF9d3x6XN56JCBAgQIAAgaEJKIgbWuL2JUCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEDgqAIK4o4q5vcECBCYs4CCuDkDD+X4jCcRcWk0/ubayfVHu0NZ254ECBAgQIBA+QIK4srPyIQECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECCxWQEHcYv3dToAAgT8QUBDnURxT4Gm07ZXX9g6uvrm+vXPMs3xOgAABAgQIEJi5gIK4mZM6kAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBngkoiOtZoNYhQKB+AQVx9We4kA0ydzLinVdeHV0+8e7HTxcyg0sJECBAgAABAhMIKIibAMlPCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAYtICCuEHHb3kCBEoUUBBXYioFz5SxG5HXon126dStz54UPKnRCBAgQIAAAQJ/J6AgzkMgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDA4QIK4rwQAgQIFCagIK6wQAodJzPHTTTXl5rxxRNrnz4udExjESBAgAABAgT+QEBBnEdBgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBwwUUxHkhBAgQKExAQVxhgRQ2TmbsNxHv74/2zr91Y/urwsYzDgECBAgQIEDgpQIK4l5K5AcECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECAxcQEHcwB+A9QkQKE9AQVx5mZQwUUa2kXF7qTk4d3Jt64sSZjIDAQIECBAgQGAaAQVx06j5hgABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBIQkoiBtS2nYlQKAKAQVxVcTU2ZDPi+GaOLh46ubWdmcXu4gAAQIECBAgMCcBBXFzgnUsAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQK9EVAQ15soLUKAQF8EFMT1Jclj7pGZEfFRxMFZxXDHtPQ5AQIECBAgUJSAgrii4jAMAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIFCiiIKzAUIxEgMGwBBXHDzv/77TPyzmi/ObN8+8F9GgQIECBAgACBvgkoiOtbovYhQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGDWAgriZi3qPAIECBxTQEHcMQHr/nyjyTy9fHPzbt1rmJ4AAYbUpgcAACAASURBVAIECBAg8GIBBXFeBwECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBA4XUBDnhRAgQKAwAQVxhQXSxTiZd7NpT6+sfbLRxXXuIECAAAECBAgsUkBB3CL13U2AAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQA0CCuJqSMmMBAgMSkBB3HDizsh7ozbPLn/w8M5wtrYpAQIECBAgMHQBBXFDfwH2J0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEDgZQIK4l4m5P8ECBDoWEBBXMfgi7guY6tt8tzK2uaHTUQuYgR3EiBAgAABAgQWJaAgblHy7iVAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoBYBBXG1JGVOAgQGI6Agrr9RZ8bnTdOe33n94a3V1Wj7u6nNCBAgQIAAAQIvFlAQ53UQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEDgcAEFcV4IAQIEChNQEFdYILMYJ+PLzLzw3deb761uxP4sjnQGAQIECBAgQKBWAQVxtSZnbgIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEuhJQENeVtHsIECAwoYCCuAmh6vjZ4ybbi9+OD66vrm+P6xjZlAQIECBAgACB+QooiJuvr9MJECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEKhfQEFc/RnagACBngkoiOtBoBlPIuLSaPzNtZPrj3Z7sJEVCBAgQIAAAQIzE1AQNzNKBxEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAg0FMBBXE9DdZaBAjUK6Agrt7sIuJptO2V1/YOrr65vr1T9SaGJ0CAAAECBAjMSUBB3JxgHUuAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQG8EFMT1JkqLECDQFwEFcRUmmbmTEe+88uro8ol3P35a4QZGJkCAAAECBAh0JqAgrjNqFxEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgUKmAgrhKgzM2AQL9FVAQV1G2f18M17TPrp669dmTiiY3KgECBAgQIEBgYQIK4hZG72ICBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBCoRUBBXSVDGJEBgOAIK4irIOmM3Iq9F++ySYrgK8jIiAQIECBAgUJSAgrii4jAMAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIFCiiIKzAUIxEgMGwBBXHl5p+Z4yaa60vN+OKJtU8flzupyQgQIECAAAEC5QooiCs3G5MRIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIFCGgIK4MnIwBQECBH4UUBBX3mPIjP0m4v390d75t25sf1XehCYiQIAAAQIECNQjoCCunqxMSoAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDAYgQUxC3G3a0ECBB4oYCCuHIeR0a2kXF7qTk4d3Jt64tyJjMJAQIECBAgQKBeAQVx9WZncgIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEuhFQENeNs1sIECAwsYCCuImp5vfDzIyIjyIOzp66ubU9v4ucTIAAAQIECBAYnoCCuOFlbmMCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBI4moCDuaF5+TYAAgbkLKIibO/GhF2TkndF+c2b59oP7i53E7QQIECBAgACBfgooiOtnrrYiQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGB2AgriZmfpJAIECMxEQEHcTBinOWSjyTy9fHPz7jQf+4YAAQIECBAgQGAyAQVxkzn5FQECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECwxVQEDfc7G1OgEChAgriOg4m82427emVtU82Or7ZdQQIECBAgACBQQooiBtk7JYmQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQOAIAgrijoDlpwQIEOhCQEFcF8oRGXlv1ObZ5Q8e3unmRrcQIECAAAECBAh8L6AgzjsgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDA4QIK4rwQAgQIFCagIG7OgWRstU2eW1nb/LD5vifOHwECBAgQIECAQKcCCuI65XYZAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIVCiiIqzA0IxMg0G8BBXHzyTczPm+a9vzO6w9vra5GO59bnEqAAAECBAgQIPAyAQVxLxPyfwIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEhi6gIG7oL8D+BAgUJ6AgbraR/FgM9+jhX6xuxP5sT3caAQIECBAgQIDAUQUUxB1VzO8JECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEBiagIK4oSVuXwIEihdQEDejiDK+zMwL3329+Z5iuBmZOoYAAQIECBAgMAMBBXEzQHQEAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQK9FlAQ1+t4LUeAQI0CCuKOndrjJtuL344Prq+ub4+PfZoDCBAgQIAAAQIEZiqgIG6mnA4jQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKCHAgriehiqlQgQqFtAQdyU+WU8iYhLo/E3106uP9qd8hSfESBAgAABAgQIzFlAQdycgR1PgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgED1Agriqo/QAgQI9E1AQdyRE30abXvltb2Dq2+ub+8c+WsfECBAgAABAgQIdCqgIK5TbpcRIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIFChgIK4CkMzMgEC/RZQEDdhvpk7GfHOK6+OLp949+OnE37lZwQIECBAgAABAgsWUBC34ABcT4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBA8QIK4oqPyIAECAxNQEHcSxLP2I3Ia9E+u3Tq1mdPhvY+7EuAAAECBAgQqF1AQVztCZqfAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIF5CyiIm7ew8wkQIHBEAQVxPw2WmeMmmutLzfjiibVPHx+R1c8JECBAgAABAgQKEVAQV0gQxiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAoFgBBXHFRmMwAgSGKqAg7h8nnxn7TcT7+6O982/d2P5qqO/C3gQIECBAgACBvggoiOtLkvYgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGBeAgri5iXrXAIECEwpoCDuB7iMbCPj9lJzcO7k2tYXU3L6jAABAgQIECBAoDABBXGFBWIcAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgSKE1AQV1wkBiJAYOgCgy+Iy8yI+Cji4Oypm1vbQ38P9idAgAABAgQI9E1AQVzfErUPAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQKzFlAQN2tR5xEgQOCYAkMuiMvIO6P95szy7Qf3j8nocwIECBAgQIAAgUIFFMQVGoyxCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAoRkBBXDFRGIQAAQI/CAy0IG6jyTy9fHPzrndAgAABAgQIECDQbwEFcf3O13YECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBxfQEHc8Q2dQIAAgZkKDKwgbiPj4PzK2icbM0V0GAECBAgQIECAQLECCuKKjcZgBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgUIqAgrpAgjEGAAIHnAoMoiMu8m017WjGcd0+AAAECBAgQGJ6AgrjhZW5jAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgSOJqAg7mhefk2AAIG5C/S5IC4j743aPLv8wcM7c4d0AQECBAgQIECAQJECCuKKjMVQBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgUJKAgrqAwjEKAAIHvBXpZEJex1TZ5bmVt88MmIiVNgAABAgQIECAwXAEFccPN3uYECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECEwmoCBuMie/IkCAQGcCfSqIy4zPm6Y9v/P6w1urq9F2hugiAgQIECBAgACBYgUUxBUbjcEIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEChEQEFcIUEYgwABAs8FelEQl/FlZl747uvN91Y3Yl+6BAgQIECAAAECBJ4LKIjzFggQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIHC4gII4L4QAAQKFCVReEPe4yfbit+OD66vr2+PCaI1DgAABAgQIECBQgICCuAJCMAIBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAkULKIgrOh7DESAwRIEqC+IynkTEpdH4m2sn1x/tDjE3OxMgQIAAAQIECEwmoCBuMie/IkCAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBguAIK4oabvc0JEChUoLKCuKfRtlde2zu4+ub69k6hpMYiQIAAAQIECBAoSEBBXEFhGIUAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgSIFFMQVGYuhCBAYskAVBXGZOxnxziuvji6fePfjp0POy+4ECBAgQIAAAQJHE1AQdzQvvyZAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAYHgCCuKGl7mNCRAoXKDogriM3Yi8Fu2zS6duffakcErjESBAgAABAgQIFCigIK7AUIxEgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEBRAgriiorDMAQIEIgosSAuM8dNNNeXmvHFE2ufPpYTAQIECBAgQIAAgWkFFMRNK+c7AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgSGIqAgbihJ25MAgWoESiqIy4z9JuL9/dHe+bdubH9VDaJBCRAgQIAAAQIEihVQEFdsNAYjQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKAQAQVxhQRhDAIECDwXKKEg7nkx3KjZ/8XJta0vpEOAAAECBAgQIEBgVgIK4mYl6RwCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBPoqoCCur8naiwCBagUWWRCXkW1k3F5qDs4phqv2CRmcAAECBAgQIFC0gIK4ouMxHAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBQgoiCsgBCMQIEDg9wUWUhCXmRHxUcTB2VM3t7YlQoAAAQIECBAgQGBeAgri5iXrXAIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIE+iKgIK4vSdqDAIHeCHRdEJeRd0b7zZnl2w/u9wbRIgQIECBAgAABAsUKKIgrNhqDESBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBQiICCuEKCMAYBAgSeC3RYELfRZJ5evrl5lz4BAgQIECBAgACBrgQUxHUl7R4CBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBGoVUBBXa3LmJkCgtwJzL4jLvJtNe3pl7ZON3iJajAABAgQIECBAoFgBBXHFRmMwAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQKEVAQV0gQxiBAgMBzgXkVxGXkvVGbZ5c/eHiHNgECBAgQIECAAIFFCSiIW5S8ewkQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQqEVAQVwtSZmTAIHBCMy8IC5jq23y3Mra5odNRA4G0qIECBAgQIAAAQJFCiiIKzIWQxEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgUJCAgriCwjAKAQIEvheYVUFcZnzeNO35ndcf3lpdjZYuAQIECBAgQIAAgRIEFMSVkIIZCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAoWUBBXMnpmI0AgUEKHLsgLuPLzLzw3deb761uxP4gES1NgAABAgQIECBQrICCuGKjMRgBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAoUIKIgrJAhjECBA4LnAMQriHjfZXvx2fHB9dX17TJQAAQIECBAgQIBAiQIK4kpMxUwECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECJQkoCCupDTMQoAAgYg4ckFcxpOIuDQaf3Pt5PqjXYgECBAgQIAAAQIEShZQEFdyOmYjQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKAEAQVxJaRgBgIECPyewBEK4p5G2155be/g6pvr2zsQCRAgQIAAAQIECNQgoCCuhpTMSIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDAIgUUxC1S390ECBD4CYEJCuL+rhhu6Y+WfnXi3Y+fQiRAgAABAgQIECBQk4CCuJrSMisBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAosQUBC3CHV3EiBA4BCBFxbEZe5kxDuvvDq6rBjOEyJAgAABAgQIEKhVQEFcrcmZmwABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBrgQUxHUl7R4CBAhMKPAHBXEZuxF5Ldpnl07d+uzJhMf4GQECBAgQIECAAIEiBRTEFRmLoQgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQKEhAQVxBYRiFAAEC3ws8L4jLzHETzfWlZnzxxNqnj+kQIECAAAECBAgQ6IOAgrg+pGgHAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgTmKaAgbp66ziZAgMAUApf/zT//HxHNl/ujvfNv3dj+aoojfEKAAAECBAgQIECgWAEFccVGYzACBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAoRUBBXSBDGIECAwHOB1X8Vr6xuxD4RAgQIECBAgAABAn0UUBDXx1TtRIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDALAUUxM1S01kECBAgQIAAAQIECBAgQIDAoQIK4jwQAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIHC6gIM4LIUCAAAECBAgQIECAAAECBDoTUBDXGbWLCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBCoVEBBXKXBGZsAAQIECBAgQIAAAQIECNQooCCuxtTMTIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAlwIK4rrUdhcBAgQIECBAgAABAgQIEBi4gIK4gT8A6xMgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAg8FIBBXEvJfIDAgQIECBAgAABAgQIECBAYFYCCuJmJekcAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgT6KqAgrq/J2osAAQIECBAgQIAAAQIECBQooCCuwFCMRIAAAQIECBAg741D0QAAIABJREFUQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAUQIK4oqKwzAECBAgQIAAAQIECBAgQKDfAgri+p2v7QgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQOL6AgrjjGzqBAAECBAgQIECAAAECBAgQmFBAQdyEUH5GgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMBgBRTEDTZ6ixMgQIAAAQIECBAgQIAAge4FFMR1b+5GAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgTqElAQV1depiVAgAABAgQIECBAgAABAlULKIirOj7DEyBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECDQgYCCuA6QXUGAAAECBAgQIECAAAECBAj8IKAgzksgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDA4QIK4rwQAgQIECBAgAABAgQIECBAoDMBBXGdUbuIAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIFKBRTEVRqcsQkQIECAAAECBAgQIECAQI0CCuJqTM3MBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAh0KaAgrkttdxEgQIAAAQIECBAgQIAAgYELKIgb+AOwPgECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECLxVQEPdSIj8gQIAAAQIECBAgQIAAAQIEZiWgIG5Wks4hQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKCvAgri+pqsvQgQIECAAAECBAgQIECAQIECCuIKDMVIBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgUJaAgrqg4DEOAAAECBAgQIECAAAECBPotoCCu3/najgABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACB4wsoiDu+oRMIECBAgAABAgQIECBAgACBCQUUxE0I5WcECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECAxWQEHcYKO3OAECBAgQIECAAAECBAgQ6F5AQVz35m4kQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKAuAQVxdeVlWgIECBAgQIAAAQIECBAgULWAgriq4zM8AQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIdCCiI6wDZFQQIECBAgAABAgQIECBAgMAPAgrivAQCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgcLqAgzgshQIAAAQIECBAgQIAAAQIEOhNQENcZtYsIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEKhUQEFcpcEZmwABAgQIECBAgAABAgQI1CigIK7G1MxMgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgECXAgriutR2FwECBAgQIECAAAECBAgQGLiAgriBPwDrEyBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECDwUgEFcS8l8gMCBAgQIECAAAECBAgQIEBgVgIK4mYl6RwCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBPoqoCCur8naiwABAgQIECBAgAABAgQIFCigIK7AUIxEgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgEBRAgriiorDMAQIECBAgAABAgQIECBAoN8CCuL6na/tCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBA4voCCuOMbOoEAAQIECBAgQIAAAQIECBCYUEBB3IRQfkaAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwGAFFMQNNnqLEyBAgAABAgQIECBAgACB7gUUxHVv7kYCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBOoSUBBXV16mJUCAAAECBAgQIECAAAECVQsoiKs6PsMTIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQINCBgIK4DpBdQYAAAQIECBAgQIAAAQIECPwgoCDOSyBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMDhAgrivBACBAgQIECAAAECBAgQIECgMwEFcZ1Ru4gAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgUoFFMRVGpyxCRAgQIAAAQIECBAgQIBAjQIK4mpMzcwECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECHQpoCCuS213ESBAgAABAgQIECBAgACBgQsoiBv4A7A+AQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIvFVAQ91IiPyBAgAABAgQIECBAgAABAgRmJaAgblaSziFAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBA4P+1c8c2FBQxFEWhBkqhC9qhFBqiEJpABAgSCH7+d6RZWX72yVc7nuOJLwECBAgQIECAwFQBgbipm3UvAgQIECBAgAABAgQIECDQUEAgruFSjESAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQCsBgbhW6zAMAQIECBAgQIAAAQIECBCYLSAQN3u/bkeAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwL2AQNy9oT8QIECAAAECBAgQIECAAAEChwICcYdQPiNAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAYK2AQNza1bs4AQIECBAgQIAAAQIECBCoFxCIqzd3IgECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECWQICcVn7Mi0BAgQIECBAgAABAgQIEIgWEIiLXp/hCRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAoEBCIK0B2BAECBAgQIECAAAECBAgQIPAREIjzEggQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIPBdQCDOCyFAgAABAgQIECBAgAABAgTKBATiyqgdRIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAqIBAXOjijE2AAAECBAgQIECAAAECBBIFBOISt2ZmAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQqBQTiKrWdRYAAAQIECBAgQIAAAQIElgsIxC1/AK5PgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMCjgEDcI5EPCBAgQIAAAQIECBAgQIAAgbcEBOLekvQfAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgSmCgjETd2sexEgQIAAAQIECBAgQIAAgYYCAnENl2IkAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgRaCQjEtVqHYQgQIECAAAECBAgQIECAwGwBgbjZ+3U7AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgTuBQTi7g39gQABAgQIECBAgAABAgQIEDgUEIg7hPIZAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQJrBQTi1q7exQkQIECAAAECBAgQIECAQL2AQFy9uRMJECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEMgSEIjL2pdpCRAgQIAAAQIECBAgQIBAtIBAXPT6DE+AAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAQIGAQFwBsiMIECBAgAABAgQIECBAgACBj4BAnJdAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACB7wICcV4IAQIECBAgQIAAAQIECBAgUCYgEFdG7SACBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBEIFBOJCF2dsAgQIECBAgAABAgQIECCQKCAQl7g1MxMgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgUCkgEFep7SwCBAgQIECAAAECBAgQILBcQCBu+QNwfQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIEHgUE4h6JfECAAAECBAgQIECAAAECBAi8JSAQ95ak/xAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgMFVAIG7qZt2LAAECBAgQIECAAAECBAg0FBCIa7gUIxEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAg0EpAIK7VOgxDgAABAgQIECBAgAABAgRmCwjEzd6v2xEgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgcC8gEHdv6A8ECBAgQIAAAQIECBAgQIDAoYBA3CGUzwgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQWCsgELd29S5OgAABAgQIECBAgAABAgTqBQTi6s2dSIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAloBAXNa+TEuAAAECBAgQIECAAAECBKIFBOKi12d4AgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQKBATiCpAdQYAAAQIECBAgQIAAAQIECHwEBOK8BAIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECHwXEIjzQggQIECAAAECBAgQIECAAIEyAYG4MmoHESBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECAQKiAQF7o4YxMgQIAAAQIECBAgQIAAgUQBgbjErZmZAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIFKAYG4Sm1nESBAgAABAgQIECBAgACB5QICccsfgOsTIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIPAoIBD3SOQDAgQIECBAgAABAgQIECBA4C0Bgbi3JP2HAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIGpAgJxUzfrXgQIECBAgAABAgQIECBAoKGAQFzDpRiJAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIFWAgJxrdZhGAIECBAgQIAAAQIECBAgMFtAIG72ft2OAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIF7AYG4e0N/IECAAAECBAgQIECAAAECBA4FBOIOoXxGgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgMBaAYG4tat3cQIECBAgQIAAAQIECBAgUC8gEFdv7kQCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBLIEBOKy9mVaAgQIECBAgAABAgQIECAQLSAQF70+wxMgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgUCAgEFeA7AgCBAgQIECAAAECBAgQIEDgIyAQ5yUQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEDgu4BAnBdCgAABAgQIECBAgAABAgQIlAkIxJVRO4gAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgVABgbjQxRmbAAECBAgQIECAAAECBAgkCgjEJW7NzAQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIVAoIxFVqO4sAAQIECBAgQIAAAQIECCwXEIhb/gBcnwABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBRwGBuEciHxAgQIAAAQIECBAgQIAAAQJvCQjEvSXpPwQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQITBUQiJu6WfciQIAAAQIECBAgQIAAAQINBQTiGi7FSAQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQItBIQiGu1DsMQIECAAAECBAgQIECAAIHZAgJxs/frdgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQI3AsIxN0b+gMBAgQIECBAgAABAgQIECBwKCAQdwjlMwIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIE1goIxK1dvYsTIECAAAECBAgQIECAAIF6AYG4enMnEiBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECCQJSAQl7Uv0xIgQIAAAQIECBAgQIAAgWgBgbjo9RmeAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAIECAYG4AmRHECBAgAABAgQIECBAgAABAh8BgTgvgQABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAt8FBOK8EAIECBAgQIAAAQIECBAgQKBMQCCujNpBBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAiECgjEhS7O2AQIECBAgAABAgQIECBAIFFAIC5xa2YmQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKBSQCCuUttZBAgQIECAAAECBAgQIEBguYBA3PIH4PoECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECDwKCMQ9EvmAAAECBAgQIECAAAECBAgQeEtAIO4tSf8hQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQGCqgEDc1M26FwECBAgQIECAAAECBAgQaCggENdwKUYiQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKCVgEBcq3UYhgABAgQIECBAgAABAgQIzBYQiJu9X7cjQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQOBeQCDu3tAfCBAgQIAAAQIECBAgQIAAgUMBgbhDKJ8RIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQILBWQCBu7epdnAABAgQIECBAgAABAgQI1AsIxNWbO5EAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAgSwBgbisfZmWAAECBAgQIECAAAECBAhECwjERa/P8AQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIFAgIxBUgO4IAAQIECBAgQIAAAQIECBD4CAjEeQkECBAgQIAAAQLaZPUcAAAPQ0lEQVQECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBD4LiAQ54UQIECAAAECBAgQIECAAAECZQICcWXUDiJAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAIFRAIC50ccYmQIAAAQIECBAgQIAAAQKJAgJxiVszMwECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAEClQICcZXaziJAgAABAgQIECBAgAABAssFBOKWPwDXJ0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEDgUUAg7pHIBwQIECBAgAABAgQIECBAgMBbAgJxb0n6DwECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECUwUE4qZu1r0IECBAgAABAgQIECBAgEBDAYG4hksxEgECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECrQQE4lqtwzAECBAgQIAAAQIECBAgQGC2gEDc7P26HQECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAEC9wICcfeG/kCAAAECBAgQIECAAAECBAgcCgjEHUL5jAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgACBtQICcWtX7+IECBAgQIAAAQIECBAgQKBeQCCu3tyJBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAhkCQjEZe3LtAQIECBAgAABAgQIECBAIFpAIC56fYYnQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQKBAQCCuANkRBAgQIECAAAECBAgQIECAwEdAIM5LIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwHcBgTgvhAABAgQIECBAgAABAgQIECgTEIgro3YQAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQKhAgJxoYszNgECBAgQIECAAAECBAgQSBQQiEvcmpkJECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEKgUEIir1HYWAQIECBAgQIAAAQIECBBYLiAQt/wBuD4BAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAo8CAnGPRD4gQIAAAQIECBAgQIAAAQIE3hIQiHtL0n8IECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEJgqIBA3dbPuRYAAAQIECBAgQIAAAQIEGgoIxDVcipEIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIEGglIBDXah2GIUCAAAECBAgQIECAAAECswUE4mbv1+0IECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIELgXEIi7N/QHAgQIECBAgAABAgQIECBA4FBAIO4QymcECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECKwVEIhbu3oXJ0CAAAECBAgQIECAAAEC9QICcfXmTiRAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAIEtAIC5rX6YlQIAAAQIECBAgQIAAAQLRAgJx0eszPAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBQICcQXIjiBAgAABAgQIECBAgAABAgQ+AgJxXgIBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgS+CwjEeSEECBAgQIAAAQIECBAgQIBAmYBAXBm1gwgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQCBUQiAtdnLEJECBAgAABAgQIECBAgECigEBc4tbMTIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBApYBAXKW2swgQIECAAAECBAgQIECAwHIBgbjlD8D1CRAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBB4FBCIeyTyAQECBAgQIECAAAECBAgQIPCWgEDcW5L+Q4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDAVAGBuKmbdS8CBAgQIECAAAECBAgQINBQQCCu4VKMRIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAKwGBuFbrMAwBAgQIECBAgAABAgQIEJgtIBA3e79uR4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIDAvYBA3L2hPxAgQIAAAQIECBAgQIAAAQKHAgJxh1A+I0CAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIEBgrYBA3NrVuzgBAgQIECBAgAABAgQIEKgXEIirN3ciAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQJZAgJxWfsyLQECBAgQIECAAAECBAgQiBYQiIten+EJECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECgQEIgrQHYEAQIECBAgQIAAAQIECBAg8BEQiPMSCBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAg8F1AIM4LIUCAAAECBAgQIECAAAECBMoEBOLKqB1EgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgECogEBc6OKMTYAAAQIECBAgQIAAAQIEEgUE4hK3ZmYCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBCoFBOIqtZ1FgAABAgQIECBAgAABAgSWCwjELX8Ark+AAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAwKOAQNwjkQ8IECBAgAABAgQIECBAgACBtwQE4t6S9B8CBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBKYKCMRN3ax7ESBAgAABAgQIECBAgACBhgICcQ2XYiQCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBFoJCMS1WodhCBAgQIAAAQIECBAgQIDAbAGBuNn7dTsCBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBO4FBOLuDf2BAAECBAgQIECAAAECBAgQOBQQiDuE8hkBAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAgQIECBAgAABAmsFBOLWrt7FCRAgQIAAAQIECBAgQIBAvYBAXL25EwkQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQIECAAAECBAgQyBIQiMval2kJECBAgAABAgQIECBAgEC0gEBc9PoMT4AAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIBAgYBAXAGyIwgQIECAAAECBAgQIECAAIGPwH8//PDj77/+/FOKx9///vnXL7/98U/KvOYkQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQIAAAQIECBAgQCBf4H9eJHFmQLuwNQAAAABJRU5ErkJggg=="style="width:300px;height:75px;">'


################################################
############  CREATE HTML REPORT  ##############
################################################
    #ConvertTo-Html -Head $style -Body "<h1 align=center style='text-align:center'><span style='color:$titleCol;'>TENAKA.NET</span><h1>", 
    ConvertTo-Html -Head $style -Body "<h1 align=center style='text-align:center'>$basePNG<h1>",    

    $fragDescrip1, 
    $frag_Summary,
    $frag_host, 
    #$frag_MDTBuild,
    $fragOS, 
    $frag_OSPatchver,
    $fragbios, 
    $fragcpu, 
    $frag_Network4,
    $frag_Network6,
    $frag_Share,
    $frag_LegNIC,
    $frag_SecOptions,
    $frag_FWProf,
    $frag_FW,
    $frag_Msinfo,
    $frag_BitLockerN, 
    $frag_Code,
    $frag_LSAPPL,
    $frag_WDigestULC,
    $frag_CredGuCFG,
    $frag_kernelModeVal,
#accounts and groups
    $FragPassPol,
    $FragAccountDetails,
    $frag_DomainGrps,
    $frag_DCList,
    $frag_FSMO,
    $frag_PreAuth,
    $frag_NeverExpires,
    $FragGroupDetails,
    $frag_whoamiGroups, 
    $frag_whoamiPriv,
    $frag_URA,
    $frag_LapsPwEna,
#progs
    $Frag_WinFeature,
    $Frag_Appx,
    $Frag_SrvWinFeature,
    $fragInstaApps,
    $fragHotFix,
    $fragInstaApps16,
    $Frag_AVStatusN,
    $frag_UnQu,
#applocker - wdac
    $frag_wdacClixml,
    $frag_WDACCIPolicy,
    $frag_ApplockerSvc,
    $frag_ApplockerEnforcement,
    $frag_ApplockerPath, 
    $frag_ApplockerPublisher,
    $frag_ApplockerHash, 
#certs and ciphers     
    $frag_Certificates,
    $frag_CipherSuit,
#file and reg audits
    $frag_DLLSafe,
    $frag_DLLHijack,
    $frag_DllNotSigned,
    $frag_PCElevate,
    $frag_PSPass,
    $frag_FilePass,
    $frag_RegPasswords,
    $frag_PSPasswords,
    $frag_AutoLogon,
    $frag_AutoRuns,
    $frag_TaskPerms,
    $frag_TaskListings,
    #$frag_RunServices,
    $frag_SysRegPerms,
    $frag_SysFolders,
    $frag_CreateSysFold,
    $frag_wFolders,
    $frag_wFile,
    $frag_DriverQuery,
    $frag_AuthCodeSig,
#policy
    $frag_ASR,
    $frag_WindowsOSVal,
    $frag_EdgeVal,
    $frag_OfficeVal,
    $FragDescripFin  | out-file $Report

    $HostDomain = ((Get-CimInstance -ClassName win32_computersystem).Domain) + "\" 
    $repDate = (Get-Date).Date.ToString("yy-MM-dd").Replace(":","_")

    Get-Content $Report | 
    foreach {$_ -replace "<tr><th>*</th></tr>",""} | 
    foreach {$_ -replace "<tr><td> </td></tr>",""} |
    foreach {$_ -replace "<td>*:</td>",""} |

    foreach {$_ -replace "<td>expired","<td><font color=#ff9933>expired"} | 
    foreach {$_ -replace "expired</td>","<font></td>"} |

    foreach {$_ -replace "<td>Selfsigned","<td><font color=#ff9933>selfsigned"} | 
    foreach {$_ -replace "selfsigned</td>","<font></td>"} |

    foreach {$_ -replace "<td>privateKey","<td><font color=#ff9933>privateKey"} | 
    foreach {$_ -replace "privateKey</td>","<font></td>"} |
    
    foreach {$_ -replace "<td>Warning","<td><font color=#ff9933>Warning"} | 
    foreach {$_ -replace "#ff9933>Warning ","#ff9933>"} |
    foreach {$_ -replace "Warning</td>","<font></td>"} |

    foreach {$_ -replace "<td>DefaultGPO","<td><font color=#ffd633>DefaultGPO"} | 
    foreach {$_ -replace "#ffd633>DefaultGPO ","#ffd633>"} |
    foreach {$_ -replace "DefaultGPO</td>","<font></td>"} |

    foreach {$_ -replace "<td>Review","<td><font color=#ff9933>Review"} | 
    foreach {$_ -replace "Review</td>","<font></td>"}  | 
  
    foreach {$_ -replace "<td>SeImpersonatePrivilege","<td><font color=#ff9933>SeImpersonatePrivilege"} | 
    foreach {$_ -replace "SeImpersonatePrivilege</td>","SeImpersonatePrivilege<font></td>"}  | 
    
    foreach {$_ -replace "<td>SeAssignPrimaryTokenPrivilege","<td><font color=#ff9933>SeAssignPrimaryTokenPrivilege"} | 
    foreach {$_ -replace "SeAssignPrimaryTokenPrivilege</td>","SeAssignPrimaryTokenPrivilege<font></td>"}  | 

    foreach {$_ -replace "<td>SeBackupPrivilege","<td><font color=#ff9933>SeBackupPrivilege"} | 
    foreach {$_ -replace "SeBackupPrivilege</td>","SeBackupPrivilege<font></td>"}  | 

    foreach {$_ -replace "<td>SeDebugPrivilege","<td><font color=#ff9933>SeDebugPrivilege"} | 
    foreach {$_ -replace "SeDebugPrivilege</td>","SeDebugPrivilege<font></td>"}  | 

    foreach {$_ -replace "<td>SeTakeOwnershipPrivilege ","<td><font color=#ff9933>SeTakeOwnershipPrivilege "} | 
    foreach {$_ -replace "SeTakeOwnershipPrivilege</td>","SeTakeOwnershipPrivilege<font></td>"}  | 

    foreach {$_ -replace "<td>SeNetworkLogonRight","<td><font color=#ff9933>SeNetworkLogonRight"} | 
    foreach {$_ -replace "SeNetworkLogonRight</td>","SeNetworkLogonRight<font></td>"}  | 

    foreach {$_ -replace "<td>SeLoadDriverPrivilege","<td><font color=#ff9933>SeLoadDriverPrivilege"} | 
    foreach {$_ -replace "SeLoadDriverPrivilege</td>","SeLoadDriverPrivilege<font></td>"}  |    

    foreach {$_ -replace "<td>SeTakeOwnershipPrivilege","<td><font color=#ff9933>SeTakeOwnershipPrivilege"} | 
    foreach {$_ -replace "SeTakeOwnershipPrivilege</td>","SeTakeOwnershipPrivilege<font></td>"}  | 
   
    foreach {$_ -replace "<td>SeRestorePrivilege","<td><font color=#ff9933>SeRestorePrivilege"} | 
    foreach {$_ -replace "SeRestorePrivilege</td>","SeRestorePrivilege<font></td>"}  | 

    foreach {$_ -replace "<td>SeCreateGlobalPrivilege","<td><font color=#ff9933>SeCreateGlobalPrivilege"} | 
    foreach {$_ -replace "SeCreateGlobalPrivilege</td>","SeCreateGlobalPrivilege<font></td>"}  | 

    foreach {$_ -replace '<td>&lt;div title=','<td><div title="'} | 
    foreach {$_ -replace "&gt;",'">'}  | 
    
    foreach {$_ -replace ">Take ownership of files or other objects </td><td><div",">Take ownership of files or other objects</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace ">Load and unload device drivers </td><td><div",">Load and unload device drivers</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace ">Back up files and directories </td><td><div",">Back up files and directories</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace ">Restore files and directories </td><td><div",">Restore files and directories</td><td><font color=#ff9933><div"}|

    foreach {$_ -replace ">Impersonate a client after authentication </td><td><div",">Impersonate a client after authentication</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace ">Create global objects </td><td><div",">Create global objects</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace ">Replace a process level token</td><td><div",">Replace a process level token</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace ">Debug programs</td><td><div",">Debug programs</td><td><font color=#ff9933><div"} |
    foreach {$_ -replace ">Debug programs </td><td><div",">Debug programs</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace ">Access this computer from the network </td><td><div",">Access this computer from the network</td><td><font color=#ff9933><div"} |

    foreach {$_ -replace "<td>Very High Risk","<td><font color=#e60000>Very High Risk"} | 
    foreach {$_ -replace "<td>High Risk","<td><font color=#ff471a>High Risk"} | 
    foreach {$_ -replace "<td>Medium to High Risk","<td><font color=#ff751a>Medium to High Risk"} | 
    foreach {$_ -replace "<td>Medium Risk","<td><font color=#ffb366>Medium Risk"} | 
    foreach {$_ -replace "<td>Low to Medium Risk","<td><font color=#a6ff4d>Low to Medium Risk"} | 
    foreach {$_ -replace "<td>Low Risk","<td><font color=#ffff66>Low Risk"} | 
    foreach {$_ -replace "<td>Informational","<td><font color=#80ff80>Informational"} | 

    foreach {$_ -replace '&lt;a href=&quot;','<a href="'} | 
    foreach {$_ -replace '&lt;/a">','</a>'} |
    foreach {$_ -replace '&quot;">','">'} |

    foreach {$_ -replace 'Warning ',''} |
    foreach {$_ -replace 'expired - ',''} |
    foreach {$_ -replace 'selfsigned - ',''} |
    foreach {$_ -replace 'privateKey - ',''} |
           
    Set-Content "C:\SecureReport\$($repDate)-$($env:COMPUTERNAME)-Report.htm" -Force
    
    invoke-item 'C:\SecureReport'   

    }
}
reports

<#
Stuff to Fix.....


$ExecutionContext.SessionState.LanguageMode -eq "ConstrainedLanguage"
Null message warning that security is missing
set warning for secure boot
Expand on explanations - currently of use to non-techies

remove extra blanks when listing progs via registry 

Stuff to Audit.....

Proxy password reg key

FLTMC.exe - mini driver altitude looking for 'stuff' thats at an altitude to bypass security or encryption
report on appX bypass and seriousSam
Remote desktop and permissions
look for %COMSPEC%
snmp

data streams dir /r
Get-Item   -Stream * | where {$_.stream -notmatch "$DATA"}

netstat -ano
Find network neighbours and accessible shares
dated or old drivers
wifi passwords
    netsh wlan show profile
    netsh wlan show profile name="wifi name" key=clear

credential manager
    %Systemdrive%\Users\<Username>\AppData\Local\Microsoft\Credentials
    cmdkey /list 
powershell passwords, history, transcript, creds
Services and svc accounts
GPO and GPP's that apply
Browser security
DNS
Auditing Wec\wef - remote collection point
Interesting events
wevtutil "Microsoft-Windows-Wcmsvc/Operational"
Add Applocker audit
Add WDAC audit
File hash database
Performance tweaks audit client and hyper v
warn on stuff thats older than 6 months - apps, updates etc
Warn Bios\uefi version and date


remove powershell commands where performance is an issue, consider replacing with cmd alts

####GPO Settings as recommended by MS####

UAC
networks
Updates

Audit Settings - ms rec

Chrome GPOs
Add further MS Edge GPO checks

Report on Windows defender and memory protections

Allign look and feel for all Reg and gpo queries inc mouse over effect

Stuff that wont get fixed.....
Progress bars or screen output will remain limited, each time an output is written to screen the performance degrads


dism get-features replace with
$features = Get-WindowsOptionalFeature -Online
foreach($feature in $features)
{
    if($feature.FeatureName -like "*")
    {
        $feature
    }
}



#>

