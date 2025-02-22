# Local Setup | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup#prerequisites>
You are going to be mounting wim files, so yes, this is an absolute with no way around it
You are going to be downloading lots of stuff, so you need Internet access. There is no Proxy or Firewall configuration in OSDCloud yet, but it is planned
OSD PowerShell Module
This changes frequently until OSDCloud is working fully, so I recommend that you wash, rinse, and repeat this command frequently
Install-Module OSD -Force
PowerShell Capable
Finally, you need to be PowerShell capable, or at least be willing to learn how to use PowerShell. I do not offer individual training sessions
Machine Configuration
The first decision you need to make is whether or not you want Wireless to work in WinPE. If you do, then you must create your OSDCloud Template on Windows 10 as you will be using Windows 10's WinRE. Windows 11 WinRE isn't compatible with older systems, and virtual machines.
If your HOST Operating System is running Windows 11, you can use the Windows 11 ADK's winpe.wim, or you can create a Hyper-V Virtual Machine and install Windows 10 21H2 and use that
Install the Windows ADK
Once you have your OS sorted out, you will need to install the Microsoft Windows ADK. Download the proper ADK and make sure you install the Deployment Tools

After the ADK Deployment Tools install is complete, download and install the Windows PE add-on for the ADK

Microsoft DaRT Integration
If you have Microsoft Desktop Optimization Pack 2015, you can install Microsoft DaRT 10. This will allow you to have DaRT Tools in your OSDCloud WinPE Media

Microsoft Deployment Toolkit
If you don't have DaRT installed, skip this step
For DaRT 10 to work in WinPE you will also need a Dart Config file. The easiest way to get this is to install Microsoft Deployment Toolkit

The final steps are to make sure that your Execution Policy is set properly, and to install the OSD PowerShell Module if you haven't already
Set-ExecutionPolicy RemoteSigned -Force
Install-Module OSD -Force

## Build Process | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-template/build-process>
The next few screenshots will detail the steps that are needed to make OSDCloud work

 1. Start writing the PowerShell Transcript
 2. Mirror the ADK Media directory to the OSDCloud Template
 3. Copy the ADK winpe.wim to the OSDCloud Template boot.wim
 4. Mount the boot.wim
 5. Mount the WinPE registry to get the WinPE Info

 6. Inject ADK Packages for PowerShell functionality
 7. Save the Windows Image

 8. Copy some helper files from the running OS
 9. If MDT is installed, add the Dart Configuration
 10. If Microsoft Dart is installed, inject the Tools
 11. Save the Windows Image
 12. Set the WinPE PowerShell ExecutionPolicy
 13. Enable PowerShell Gallery support
 14. Remove winpeshl.ini if it is present
 15. Change some settings for a better Command Prompt experience

 16. Display the installed Windows Packages

 17. Dismount the Windows Image
 18. Export the Boot.wim to compress the file
 19. Create empty configuration directories
 20. Create the ISOs
 21. Set the OSDCloud Template to the new path
 22. Stop writing the PowerShell Transcript

### WinRE WiFi | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-template/winre-wifi>
In addition to using the winpe.wim that is in the ADK, you can also create an OSDCloud Template using WinRE
To do this, use the WinRE parameter. The benefit of using WinRE is you gain Wireless support. One thing you need to remember is that the ADK you are using needs to match your running OS, so if your OS is Windows 11 22H2, you need to use the ADK for Windows 11 22H2. Finally, make sure you use the Name parameter to keep things tidy
In my example below, you can see the WinPE-WiFi Packages that come with WinRE

New-OSDCloudTemplate -Name WinRE -WinRE

Additional Information

#### Build a WinPE with wireless support - MSEndpointMgr

Clipped from: <https://msendpointmgr.com/2018/03/06/build-a-winpe-with-wireless-support/>
Deploying Windows with the help of a Windows Preinstallation Environment (WinPE) is known since the release of Windows XP. We always take care of adding network drivers to WinPE to support our various models in the environment. The standard WinPE provided by the Windows Assessment and Deployment Kit (Windows ADK) does not have any support for wireless network. Even the latest (at the time of writing) WinPE version 1709 (10.0.16299) does not provide native wireless support. If we look at the Windows Recovery Environment (WinRE) you can find an additional optional component that provides WiFi support for the WinRE. This is easily verified by mounting the WinRE with dism and listing the features:
dism /Image:C:\mount\offline /Get-Features
The output should list all available features and the additional WinPE-WiFi feature only provided in WinRE:
Feature Name : WinPE-WiFi
State : Enabled
All we need to do is to replace our WinPE with a WinRE and some additional modifications to get wireless support in our new WinPE. The modifications are basically:
 • adding wireless drivers to the PE if needed (I used a Surface devices which has wireless driver support out of the box)
 • removing or modifying winpeshl.ini as it tries to load the recovery environment of the WinRE
 • adding back some dependency dlls otherwise the support is broken for WinPE version later than 1511
 • creating a wireless xml profile
 • assigning and connecting to the wireless network via netsh
 • a good strategy how to use the new wireless support with MDT and ConfigMgr 🙂
Building a test WinPE with wireless support
 • Create a folder C:\mount and a sub folder offline md C:\mount\offline
 • copy WinRE from the Windows folder to the new mount folder (assuming the running OS on which the new WinPE is created is Windows 10 1709) copy /y C:\Windows\System32\Recovery\Winre.wim C:\mount
 • Mount the WinRE to C:\mount\offline dism /Mount-Image /ImageFile:C:\mount\winre.wim /index:1 /MountDir:C:\mount\offline /Optimize
 • Copy missing libraries (dlls) to WinRE copy /y C:\Windows\System32\dmcmnutils.dll C:\mount\offline\Windows\System32
copy /y C:\Windows\System32\mdmregistration.dll  C:\mount\offline\Windows\System32
 Without the additional dlls you will get the following error when using netsh in the wlan context (netsh wlan): The following helper DLL cannot be loaded: WLANCFG.DLL. I troubleshoot this with the help of the Dependency Walker (depends.exe). I loaded wlancfg.dll with depends.exe within the WinPE environment and observed mdmregistration.dll listed as “Error opening file. The system cannot find the file specified“. Loading mdmregistration.dll then and found the second layer dependency dmcmnutils.dll with the same error. I added them to the WinRE and the initial error for wlancfg.dll was solved. After a manual connect via netsh the wlan context was working. All this is needed for WinRE versions 1607 and later. With a WinRE version 1511 it is working without the two dlls.
 • Create the wireless xml profile Wi-Fi-YourNetwork.xml by exporting your Wi-Fi with netsh wlan export netsh wlan export profile name=YourNetwork key=clear
 Note that the described WinPE setup does support shared key authentication with Open\WEP\WPA and WPA2. The command above will export the shared key as plain text within the xml file!
 • Create a batch file wlan.cmd to start the WLAN AutoConfig Service and use netsh to add a wireless profile to the wlan interface and finally connect to the wireless network net start wlansvc
netsh wlan add profile filename=Wi-Fi-YourNetwork.xml
netsh wlan connect name=YourNetwork ssid=YourNetwork
ping localhost -n 30 >nul
 The timeout of 30 seconds (build with the ping command) is needed to make sure the script pauses some time to let the wireless network stack connect to the wireless network. My tests have shown between 30-45 seconds are needed to successfully connect, get an IP address, and to have a valid connection in the end.
 • Remove the winpeshl.ini file as it has an entry to load the recovery environment del /q C:\mount\Windows\System32\winpeshl.ini
 • Un-mount the WinRE file to get our newly created WinPE with wireless support Dism /Unmount-Image /MountDir:C:\mount\offline /commit
Please note the downside of this approach is the plaintext shared key in the Wi-Fi-YourNetwork.xml file.
Now we have a tow basic options what to do with the new test WinPE. Here some ideas:

 1. use it with MDT
 rename the existing winpe.wim template in the path:
 C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\en-us\winpe.wim
 and copy the newly created one as winpe.wim there. Now we can build a MDT solution with our new WinPE. As soon as the WinPE is loaded we can test wireless by hitting F8 and type wlan.cmd.
 2. use it with ConfigMgr
 I didn’t test yet but as we need the support for the wireless network very early in the process, I assume we need to hook something into TsBootShell.ini, and let the system connect to the wireless before starting the actual task sequence.
User driven experience with wireless connect
I built a solution with MDT which does not use the Wi-Fi-YourNetwork.xml file which has the plain text key material. The solution is a simple .NET 4.5 program to simplify the connection to a wireless network. Remember to add .NET framework support to the WinPE. The tool will create the xml file with the correct parameters provided by the UI and connects to the wireless network. It will make active probes to the Microsoft Network Connection Status Indicator (NCSI) to verify if there is an internet connection. This can be easily overwritten by providing a parameter during startup of the tool via:
`WirelessConnect.exe <specify-custom-url-as-arg-here>`

To support the keyboard button we must add the osk.exe and osksupport.dll to the execution directory of WirelessConnect. The .NET solution WirelessConnect can be found on my GitHub Helper repository here:
 <https://github.com/okieselbach/Helpers>
After download we can create a MDT bootable USB device with wireless support and easy connection handling with WirelessConnect.exe. We provide the WirelessConnect.exe and the unattend.xml file for the WinPE as an extra file in MDT to start the WirelessConnect.exe before we run the MDT LiteTouch process.

When using MDT we can also easily provide mdmregistration.dll and dmcmnutils.dll in a sub folder Windows\System within the extra directory to add. The MDT process will only need a modified WinRE to have no winpeshl.ini file and then MDT builds the complete WinPE for us.
The ExtraFiles folder should look like this:
 • WirelessConnect.exe
 • unattend.xml
 • Windows\System32\mdmregistration.dll
 • Windows\System32\dmcmnutils.dll
 • osk.exe
 • osksupport.dll
Adding an extra directory to MDT is a simple task:

As last step I needed to modify ZTIUtility.vbs to support a deployment via wireless network:
If sIPConnectionMetric = "" Then
   ' ################################################################ MODIFIED CODE #########################################################################
   'oLogging.CreateEntry "No physical adapters present, cannot deploy over wireless", LogTypeError
   'ValidateNetworkConnectivity = Failure
   'Exit Function
   oLogging.CreateEntry "No physical adapters present, cannot deploy over wireless", LogTypeInfo
   oLogging.CreateEntry "=> normally MDT would exit here!", LogTypeInfo
   oLogging.CreateEntry "=> CUSTOM HOOK UP", LogTypeInfo
   ' ################################################################ MODIFIED CODE #########################################################################
End IF
If everything was successful you will see the WirelessConnect UI from above and you are able to connect to your wireless network protected by WPA/WPA2/WEP or as an Open network before the task sequence will start.
Additional considerations need to be made when dealing with reboots during WinPE phase to ensure proper reconnect and during OS phase. Basically I wanted to show the possibility to provide wireless support, even when not used with OSD it might help in other scenarios.
Views: 55,096

##### Languages | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-template/languages>
You can add additional languages to your WinPE by using the Language parameter. In my example, I used the ADK winpe.wim and added Spanish and French to my English US WinPE so I gave a Name that will help me identify the added languages

New-OSDCloudTemplate -Name 'ADK en es fr' -Language es-es,fr-fr -SetInputLocale

This parameter allows me to set the default keyboard to something else, like English (US) Dvorak

New-OSDCloudTemplate -Name 'ADK en Dvorak' -SetInputLocale '0409:00010409'

Finally, I can change all the International Defaults to one of the added Languages using this parameter. This will make the following changes
 • UI language
 • System locale
 • User locale
 • Input locale

###### Cumulative Updates | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-template/cumulative-updates>
I've added the ability to apply a Cumulative Update to an OSDCloud Template due to the Secure Boot vulnerability. The next two links give some details on the issue
Download the Cumulative Update
Start by downloading the update from Microsoft Update Catalog and specifying the path to the downloaded update. Start by downloading the x64 version at this link if you are using the ADK for Windows 11 version 22H2
Microsoft Update Catalog

Apply the Cumulative Update
Once you have the update downloaded, use the CumulativeUpdate parameter and supply the Path to the downloaded MSU. In the example below I applied this in my default OSDCloud Template as this will be the one I use the most

 1. Cumulative Update is applied
 2. Updated Windows Information is displayed
 3. Boot files are updated
 4. DISM Component Cleanup is run

Apply the WRONG Cumulative Update
It's absolutely possible to apply the wrong Cumulative Update for WinPE, so make sure you understand that the Cumulative Update that you download must match your ADK. So if you are using the ADK for Windows 11 version 22H2, you need the Windows 11 22H2 x64 Cumulative Update

 1. Cumulative Update is applied
 2. Updated Windows Information is displayed. In this case, the UBR did not change
 3. Warning is displayed that the UBR has not been changed. The Boot files will not be updated
 4. DISM Component Cleanup is run

I'm not properly staffed to answer individual questions about which Cumulative Update you need for the ADK you have installed. If this is not something you can resolve on your own, then you should probably wait for updated Media from Microsoft that already has the Secure Boot updates applied

If you are interested in reviewing how this works, here is a snipped from the New-OSDCloudTemplate function

###### ISO Boot Media | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-template/iso-boot-media>
Just a quick note, every time you make a new OSDCloud Template, ISO's are automatically generated for you to test with right away and located in the root of the OSDCloud Template

OSDCloud_NoPrompt.iso will skip this message below and boot straight to WinPE

OSDCloud.iso

###### OSDCloud Workspace | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace>

 1. OSDCloud
 2. Local Setup
OSD 23.5.21.1+ Updated May 21, 2023
Before getting too deep on how to create an OSDCloud Workspace, let me first explain what an OSDCloud Workspace is. In a nutshell, an OSDCloud Workspace is a copy of the OSDCloud Template that you can customize with Configuration Files, Wallpaper, Drivers, and Startup Configuration. Since it is a copy of your OSDCloud Template, this allows you to create multiple OSDCloud Workspaces that are customized with different configurations. The best example I can give as to why you might need separate OSDCloud Workspaces is to keep one for Development and the second for Production
PreviousUniversal WinPENextGet-OSDCloudWorkspace
Last updated 1 year ago
Was this helpful?

###### Get-OSDCloudWorkspace | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace/get-osdcloudworkspace>
It's a good idea to remember how to know what your current OSDCloud Workspace is. You can find out with this function. On a system that has never created an OSDCloud Workspace, you will receive the following Warning and nothing will be returned
PS C:\> Get-OSDCloudWorkspace
WARNING: 2022-02-22-223047 Unable to locate C:\ProgramData\OSDCloud\workspace.json
Here is an example of how to test if you have an OSDCloud Workspace
PS C:\> if (Get-OSDCloudWorkspace) {$true} else {$false}
WARNING: 2022-02-22-223256 Unable to locate C:\ProgramData\OSDCloud\workspace.json
False
Ideally, you should get a path returned if you have an OSDCloud Workspace
PS C:\> Get-OSDCloudWorkspace
C:\OSDCloud
The current OSDCloud Workspace is stored in the OSDCloud Template at C:\ProgramData\OSDCloud\workspace.json

## Set-OSDCloudWorkspace | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace/set-osdcloudworkspace>
This function requires elevated Admin Rights
The OSDCloud Workspace can also be set. This is typically handled automatically when you create a new OSDCloud Workspace, but you can also set this with the Set-OSDCloudWorkspace function. Here are some examples
[ADMIN]: PS C:\> Get-OSDCloudWorkspace
C:\OSDCloud

[ADMIN]: PS C:\> Set-OSDCloudWorkspace C:\OSDCloudDev
C:\OSDCloudDev

[ADMIN]: PS C:\> Get-OSDCloudWorkspace
C:\OSDCloudDev

[ADMIN]: PS C:\> Set-OSDCloudWorkspace -WorkspacePath C:\OSDCloudProd
C:\OSDCloudProd

[ADMIN]: PS C:\> Get-OSDCloudWorkspace
C:\OSDCloudProd

### New-OSDCloudWorkspace | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace/new-osdcloudworkspace>
This function requires elevated Admin Rights
This is the function that will create an OSDCloud Workspace from your active OSDCloud Template. If you have multiple OSDCloud Templates, it's a good idea to check the one you are currently using and to change it if necessary. In this example below I'm changing to a patched WinRE as my OSDCloud Template
PS C:\> Get-OSDCloudTemplate
C:\ProgramData\OSDCloud\Templates\WinPE KB5026372

PS C:\> Get-OSDCloudTemplateNames
default
Public WinPE
Public WinPE KB5026372
Public WinRE
Public WinRE KB5026372
WinPE
WinPE KB5026372
WinPE Language en Dvorak
WinPE Language en es fr
WinPE Language fr en es
WinRE
WinRE KB5026372

PS C:\> Set-OSDCloudTemplate -Name 'WinRE KB5026372'
C:\ProgramData\OSDCloud\Templates\WinRE KB5026372
Now that I've checked my OSDCloud Template, I'll create a new OSDCloud Workspace. By default, the OSDCloud Workspace is created at C:\OSDCloud but I can change the default by specifying a WorkspacePath

#### Restore from ISO | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace/new-osdcloudworkspace/restore-from-iso>
If you have an existing OSDCloud ISO, you can use this to create a new OSDCloud Workspace and the -fromIsoFile parameter. Here is an example of how this works

##### Restore from ISO URL | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace/new-osdcloudworkspace/restore-from-iso-url>
If your existing OSDCloud ISO is saved on the Internet, then use the -fromIsoUrl parameter. This will download the ISO, mount the ISO, create the OSDCloud Workspace, then dismount the ISO

#### Restore from USB | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace/new-osdcloudworkspace/restore-from-usb>
If you have an OSDCloud USB, you can use the -fromUsbDrive switch parameter to create the OSDCloud Workspace from the USB content

### Configuration Files | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-workspace/configuration-files>
If you have any of the following OSDCloud Config Files, they can be added to your OSDCloud Template. This will ensure that they are always copied to any newly created Workspace
Intune exported Autopilot Profiles can be copied to the following path
C:\ProgramData\OSDCloud\Config\AutopilotJSON

AutopilotOOBE configuration files can be copied into the following path
C:\ProgramData\OSDCloud\Config\AutopilotOOBE
OOBEDeploy configuration files can be copied into the following path
C:\ProgramData\OSDCloud\Config\OOBEDeploy

#### OSDCloud WinPE | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-winpe>
Edit-OSDCloudWinPE
This function requires elevated Admin Rights
This is the function that is used to edit the WinPE in your OSDCloud Workspace. The basic design of this function is to edit the Startnet.cmd in WinPE to perform a startup to run OSDCloud
In the example below, the default configuration starts WinPE with 3 windows

 1. Startnet.cmd. Closing this window will cause WinPE to restart
 2. Normal PowerShell window. This is where you should run you OSDCloud commands
 3. Minimized PowerShell window. This is a backup so you can run some commands while OSDCloud is running in the normal PowerShell window

### Drivers | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-winpe/drivers>
I spent some time automating the download, extraction, and injecting the drivers in OSDCloud's WinPE. I call these CloudDrivers. For this parameter I recommend you use install everything with the following command line
Edit-OSDCloudWinPE -CloudDriver *
This will download and inject the following drivers
 • Dell Enterprise Driver Cab
 • HP WinPE 10 Driver Pack
 • Intel Ethernet Drivers
 • Lenovo Dock Drivers (Microsoft Catalog)
 • Nutanix
 • USB Dongles (Microsoft Catalog)
 • VMware (Microsoft Catalog)
 • WiFi (Intel Wireless Drivers) [Requires WinRE]
These are handled by mixing and matching the following values
Edit-OSDCloudWinPE -CloudDriver Dell,HP,IntelNet,LenovoDock,Nutanix,USB,VMware,WiFi
Here's an example using Dell, USB, and Intel WiFi
Edit-OSDCloudWinPE -CloudDriver Dell,USB,WiFi

If you have a HardwareID, you can specify that with this parameter. This will download the appropriate driver from Microsoft Catalog and inject it into WinPE. Here's an example
Edit-OSDCloudWinPE -DriverHWID 'VID_045E&PID_0927','VID_0B95&PID_7720'

Finally, you can use a Driver Path to specify a folder containing driver INF's that you want to install
Edit-OSDCloudWinPE -DriverPath 'C:\SomePath'

### PSModule | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-winpe/psmodule>
This parameter allows me to copy a PowerShell Module from my local computer to WinPE. I use this frequently in testing an updated OSD Module that I'm working on before publishing it to PowerShell Gallery. This parameter is also useful if you have your own custom PowerShell Modules that you do not publish in the PowerShell Gallery, but you need them in WinPE. This is ideal for adding a custom OSDCloud GUI

PSModuleInstall
If you want to add a PowerShell Module that is in the PowerShell Gallery, this parameter will download expand it into WinPE PowerShell Modules

### Startup | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-winpe/startup>
Every time you run Edit-OSDCloudWinPE, even to add Drivers or change the Wallpaper, the WinPE Startup will reset to the Default
The default for WinPE Startup is to open a PowerShell window. This is the method I prefer as it gives me the flexibility to do anything I want, rather than to be locked into something specific.
Edit-OSDCloudWinPE

WinPE Startnet.cmd
This is the Startnet.cmd when using the Default WinPE Startup configuration. This is what is edited when you make one of the changes below
@ECHO OFF
wpeinit
cd\
title OSD 23.5.21.1
PowerShell -Nol -C Initialize-OSDCloudStartnet
@ECHO OFF
start PowerShell -NoL

WinPE Startup Options
These are the available WinPE Start options that you can configure

StartOSDCloudGUI
This parameter will automatically launch Start-OSDCloudGUI
Edit-OSDCloudWinPE -StartOSDCloudGUI

StartOSDCloudGUI -Brand
If you don't want OSDCloud displayed on the OSDCloud GUI, give it your own brand
Edit-OSDCloudWinPE -StartOSDCloudGUI -Brand 'David Segura'

Edit-OSDCloudWinPE -StartOSDCloudGUI -Brand 'HP'

Yes, WinPE can start OSDCloud (CLI) automatically using this parameter. The value for this parameter need to be the parameters for Start-OSDCloud (CLI). Here's an example:
Edit-OSDCloudWinPE -StartOSDCloud "-OSName 'Windows 10 21H2 x64' -OSLanguage en-us -OSEdition Pro -OSActivation Retail"

Here is a cool example of putting your Command Line into a GitHub Gist
Then use the 'view raw' URL as the value for StartURL. This is great way to customize the launch of your WinPE, or make some last minute changes.

### OSDCloud ISO | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-iso>
New-OSDCloudISO
This function requires elevated Admin Rights
If you have the Windows ADK installed, you can use New-OSDCloudISO to create bootable ISO Media for OSDCloud. There are no parameters for this function

Two ISO's will be saved in your OSDCloud Workspace. The NoPrompt ISO will boot automatically into WinPE without prompting for a keyboard press

### New-OSDCloudUSB | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-usb/new-osdcloudusb>
This function requires elevated Admin Rights
There are two reasons for creating an OSDCloudUSB. The first reason is to simply boot to WinPE and let everything download from the Internet. The second reason is to support OSDCloud Offline, which works without any internet connection at all
To create an OSDCloud USB, use the New-OSDCloudUSB OSD function. This OSD Function is used for both OSDCloud WinPE and OSDCloud Offline
 • Operating System - To create an OSDCloudUSB from a USB Drive, make sure you are running Windows 10 1703+ or Windows 11. This minimum requirement is to create a USB Drive with 2 Partitions
 • Admin Rights - Since you need to mess with Disk Partitions, you will need Admin Rights to Clear-Disk and New-Partition
[Default] fromWorkspace
To get started, open PowerShell with Admin rights. Simply enter New-OSDCloudUSBto prepare a new or used USB Drive
You will be presented with a table of the USB Drives that are present on your system, regardless of whether you have 1 or 5. Simply enter the DiskNumber to make a selection
After selecting a DiskNumber, you will be prompted to Confirm the selection as this is a destructive process. Once you Confirm, the USB Drive will be Cleared, Initialized, Partitioned, and Formatted. When the USB Volumes are ready, your OSDCloud Media will be copied to the Boot partition. The whole process should take between 1-2 minutes to complete

If you have an OSDCloud ISO, you can use this to create an OSDCloud USB using the -fromIsoFile parameter

If you have an ISO saved on the Internet, you may be able to use the -fromIsoUrl parameter

This is not guaranteed to work in all situations due to firewall and proxy configuration
When you create a new OSDCloud USB, only the WinPE partition will contain files. If you do not plan on using OSDCloud Offline, you can rename the OSDCloud partition and use it for something else

Disk Management
As you can see in Disk Management, the USB Drive will contain two partitions. The first partition will be the OSDCloud NTFS partition, with the second being the 2GB FAT32 Partition. Other guides may tell you to create the FAT32 partition first, but they are wrong, and I am right. For one reason, FAT32 gets corrupted all the time. Its easier to destroy and recreate at the end of the drive without messing with the NTFS partition. Secondly, you are free to shrink and extend this smaller partition. If the partitions were reversed, you would not be able to extend the start point of the second partition without losing all the NTFS data

#### Update-OSDCloudUSB | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-usb/update-osdcloudusb>
If you make changes to WinPE in your OSDCloud Workspace, you can easily update your OSDCloud USB WinPE volume by using Update-OSDCloudUSB
This OSD function easily works on multiple OSDCloud USB drives

Update-OSDCloudUSB -DriverPack
If you are ready to use OSDCloud Offline, then you can start by adding Driver Packs for your supported computers using Update-OSDCloudUSB with the DriverPack parameter. Supported manufacturers are Dell, HP, Lenovo, and Microsoft Surface
You can start by downloading the Driver Pack for your computer. Simply use the following command line
Update-OSDCloudUSB -DriverPack ThisPC

You can also specify one or more of the supported Manufacturers. Each manufacturer specified will present a PowerShell GridView which will allow you to select multiple models.
Some models have Driver Packs for both Windows 10 and Windows 11. In the Dell example below, both Driver Packs should be downloaded for proper compatibility. During an OSDCloud deployment, Windows 11 Driver Packs are selected over Windows 10
Update-OSDCloudUSB -DriverPack Dell

The DriverPack parameter will accept multiple values, separated by a comma. Additionally, Driver Packs that have already been downloaded will show as Downloaded in the Status column of PowerShell gridview
Update-OSDCloudUSB -DriverPack ThisPC,Dell

If you want to download the Driver Pack for your computer, and to select Driver Packs from all available Manufacturers, use this command
Update-OSDCloudUSB -DriverPack *

Update-OSDCloudUSB -OS
Finally, you can save any Operating Systems (Windows 10 1809 - Windows 11 21H2) that OSDCloud uses to your OSDCloud USB. You can download all OSDCloud supported Operating Systems with the following command line
Update-OSDCloudUSB -OS
Once Update-OSDCloudUSB runs, you will be prompted to select one or more Operating Systems from PowerShell gridview. You can then press OK to download the ESD files

If you know which OS you want to download, you can use the OSName parameter with a supported value

In my opinion, the best filter that you can select is OSLanguage. This will allow you select from all Operating Systems in your selected language

You can filter the OSLicense by Volume or Retail to narrow down the selections as well

### OSDCloud VM | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-vm>
This page is under construction and the update hasn't even been released, so there is nothing you can do yet. Be patient
Let's have an intimate conversation about Hyper-V and OSDCloud. For starters, I do almost all of my testing in Hyper-V on my Workstation, and I've been creating Virtual Machines hundreds of times ... all of that wasted time. So how about automating this process for OSDCloud
Let's start with the obvious, you will need Admin Rights. You won't even see the New-OSDCloudVM function without it. Got it?

Get your Hyper-V in working order. This is a new function, and I don't have all the checks in place so expect things to go sour if you haven't at least created a Virtual Machine
Your OSDCloud Workspace should be in good order as well. You can easily check this with Get-OSDCloudWorkspace. What is important to know is that OSDCloud VM uses the OSDCloud_NoPrompt.iso to boot.
If you need to change your OSDCloud Workspace, use the Set-OSDCloudWorkspace function

#### Get-OSDCloudVMDefaults | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-vm/get-osdcloudvmdefaults>
There function is used to return the OSDCloudVM defaults. The defaults are set in the OSD Module by importing the settings from the OSD.json file that exists in the root of the OSD Module. This file cannot be changed

When creating a new OSDCloud VM, these defaults will be used to create the Virtual Machine. Most of the values used are defaults that are required for Windows 11, although I would recommend using more powerful settings if your system can handle it. The defaults represent the Minimum level that should be used with an OSDCloud VM
{
  "CheckpointVM": true,
  "Generation": 2,
  "MemoryStartupGB": 4,
  "NamePrefix": "OSDCloud",
  "ProcessorCount": 1,
  "StartVM": true,
  "SwitchName": null,
  "VHDSizeGB": 64
}

##### Get-OSDCloudVMSettings | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-vm/get-osdcloudvmsettings>
While you can't change the OSDCloud VM Defaults as those are OSD Module based, you can add OSDCloud VM Settings that overlay over the OSDCloud VM Defaults. Using the Get-OSDCloudVMSettings function, you are able to see the current effective settings that are a combination of the following. In this design, the last entry wins

 1. OSD Module Defaults
 2. OSDCloud Template Settings
 3. OSDCloud Workspace Settings
If you have not made any changes to the Template or Workspace Settings, the current settings should mirror the OSD Module Defaults

##### Set-OSDCloudVMSettings | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-vm/set-osdcloudvmsettings>
Using this function, you can use Parameters to change the OSDCloud VM Template settings. This creates a configuration file that is imported every time you create an OSDCloud VM. In the example below I have changed the Memory from 4GB to 10GB, the Processor Count from 1 to 2, and set the Switch from 'No connection' to 'Default Switch' using the following commands
Set-OSDCloudVMSettings -MemoryStartupGB 10 -ProcessorCount 2 -SwitchName 'Default Switch'
Get-OSDCloudVMSettings will show the updated values and the inclusion of the configuration file

New-OSDCloudVM will show when Settings are being used, resulting in an OSDCloud VM being created with the updated Settings

#### Reset-OSDCloudVMSettings | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-vm/reset-osdcloudvmsettings>
You can reset the OSDCloud VM Settings to the OSD Module defaults using this function. It will simply delete all configuration files

##### New-OSDCloudVM | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/setup/osdcloud-vm/new-osdcloudvm>
You can customize the defaults of the Virtual Machine by using the parameters of this function. When you change any of the parameters, it will save the configuration in the OSDCloud Workspace. Every subsequent OSDCloud VM that you create in the same OSDCloud Workspace will use these settings. In this example I have set my OSDCloud VM Settings (Template) with the following configuration

When I run New-OSDCloudVM, it will inherit my OSDCloud VM Settings that were created in my OSDCloud Template by Set-OSDCloudVMSettings

This should absolutely be one of the first things you set in your Virtual Machine. Ideally it should be inherited from Set-OSDCloudVMSettings
And yes, you will be able to Tab Complete through your available Virtual Switches

If you need your VM set to 'Not connected', just use a $null value

By default, OSDCloud VM will startup automatically. I can prevent this from happening by using this parameter and setting the value to $false

This value determines if a New VM Checkpoint will be created or not, which is incredibly helpful if you need to reset the VM to a clean state. You can change this at the command line as well

This Prefix is given to the Virtual Machine name created with New-OSDCloudVM. By default, this is OSDCloud, but you can also configure this at the command line

By default, the VM will be created as Generation 2, which is UEFI. But if you want to live in a world of pain, you can create a Generation 1 Virtual Machine.
Seriously don't do this. OSDCloud will partition your disk as GPT, which won't boot your Generation 1 VM. This feature was added for testing only. I will not address any questions about this parameter, so you're on your own here.

MemoryStartupGB
The minimum requirements for Windows 11 are 4GB, but I've seen some things not work right, so I suggest bumping this up a little

I recommend setting this to at least 2, but that's your call.

If you are curious as to how many processors you can use at the same time across all Virtual Machines ...

Can you create a Virtual Machine with a Processor Count greater than the number of Processors? Yes you can, but you'll have problems getting it to start

Finally feel free to give your Virtual Machine a few extra GB's of space. Enjoy!

As a reminder, you can reset things back to default if you need to

A TimeStamp is used in the Virtual Machine Name so you should always be able to quickly identify the last one you created. Finally, if you have a failed deployment, you can Apply the initial Checkpoint to reset the Virtual Machine to a newly created state

#### Deployment | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment>
Deployment
OSD 23.5.21.1+ Updated May 21, 2023

### WinPE | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe>

 1. OSDCloud
 2. Deployment
WinPE
OSD 23.5.21.1+ Updated May 21, 2023

#### Start-OSDCloud | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloud>
This is the OSDCloud Command Line which is useful for scripting. Parameters are optional, but you will be prompted to make Operating System selections

#### OS Parameters | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloud/os-parameters>
You can specify Operating System parameters so you can deploy without being prompted for a selection

##### ZTI | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloud/zti>
The ZTI Parameter will automatically deploy using the defaults for any Operating System parameters that are not specified. You will not be prompted to confirm the Clear-Disk

### Start-OSDCloudGUI | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloudgui>
After WinPE startup is complete, enter Start-OSDCloudGUI at the PowerShell prompt

You will briefly see the OSDCloudGUI Configuration and the TPM/Autopilot status before this PowerShell window is minimized

Operating System
You can select an Operating System from the combobox. The default Operating System will always be the latest, which is currently Windows 11 22H2 x64

Currently, there are 760 Operating System combinations (OS, Language, Activation) that are available which you can review using the Get-OSDCloudOperatingSystems function

The Windows Edition is set to Enterprise by default

The Windows Language is set to en-us by default

Activation (License)
The Windows Activation is set to Volume by default due to the default Windows Edition being set to Enterprise

Depending on the Computer Model and Operating System, a Driver Pack will automatically be selected for you. In the case of a Virtual Machine or an unknown Computer Model, Microsoft Update Catalog will be selected. You can also select None for a DriverPack if you would prefer to go a different route

Deployment Options
By default, you will need to confirm the Clear-Disk operation during a deployment. You can unselect this requirement from the Deployment Options menu. After the deployment is complete, the computer will automatically restart. This can be disabled from this menu
capture Screenshots isn't working at this time

Microsoft Update Catalog
Disk, Network, and SCSI Adapter drivers will be downloaded from Microsoft Update Catalog by default. Optionally, you can download Firmware updates for your device

When you are ready to deploy, press the Start button. You should get prompted to confirm the Clear-Disk step

Clear-Disk Confirm
The Operating System ESD will be downloaded from Microsoft

Once the ESD has been downloaded, it is expanded to C:\

The DriverPack will be expanded in WinPE, or staged for first boot. PowerShell Modules that are required for Autopilot will be updated in the offline Operating System

Finally, the computer should reboot to OOBE. At this point, OSDCloud is complete

#### Parameters | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloudgui/parameters>
This is the default OSDCloudGUI. There are a few parameters that you can use for minimal customization

Change the Brand Name
Start-OSDCloudGUI -BrandName 'MMSMOA2023'

Change the Brand Color
Start-OSDCloudGUI -BrandColor '#ED1C24'

-ComputerManufacturer
This parameter is helpful in testing Manufacturer customizations in a Virtual Machine. You can see the Manufacturer displayed in the Title Bar
Start-OSDCloudGUI -ComputerManufacturer 'HP'

-ComputerProduct
OSDCloud matches the Driver Pack based on the computer Product. This parameter is helpful for testing a Driver Pack on a Virtual Machine. You can see the Computer Product displayed in the Title Bar

HP Dragonfly G2

Start-OSDCloudGUI -ComputerProduct '8716'

#### Defaults | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloudgui/defaults>
Start-OSDCloudGUI has some defaults that are set using the $OSDCloudModuleResource Global Variable. These are initialized when the OSD PowerShell Module is imported.

These variables can be modified before launching Start-OSDCloudGUI

### Global Variable | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloudgui/global-variable>
When you run Start-OSDCloudGUI, all of the settings are stored in the $OSDCloudGUI Global Variable. Invoke-OSDCloud digests this Global Variable when you press the Start button

### Start-OSDCloud Wrapping | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/winpe/start-osdcloud-wrapping>
OSDCloud is heavily variable driven, similar to a ConfigMgr Task Sequence.
There are many variables in OSDCloud to control the process, similar to running OSDCloud with parameters to control a small set of the variables, you can script around Start-OSDCloud to configure so much more to get the exact zero touch scenario you're looking for.
Start-OSDCloud has about 60 variables in the Start-OSDCloud script beginning that are set, but along the way, several others can be used as well, which can be consumed by the OSDCloud engine which at last check, has about 130 variables.
At the start of the OSDCloud engine, it has a default set for these variables, then it looks at what you sent along the way with Start-OSDCloud, and it overwrites the defaults with the variables you set, but if you manually set any variables ahead of time using the global variable "MyOSDCloud", it will overwrite any previous variables with what you've set in that variable, I hope you're all tracking. Let's look at an example.
NOTE: See Start-OSDCloudGUI -> Global Variable for additional details
By Default, there is a $Global:OSDCloud variable with several sub keys, once of which is "OSVersion", which is set to "Windows 10" by default. If I run Start-OSDCloud with some parameters, I can see that a new Global variable $Global:StartOSDCloud is created with the information I just fed into it:

OSDCloud Default Variables, OSVersion set to 'Windows 10'

So now when OSDCloud runs, it will overwrite the defaults in $Global:OSDCloud with the ones in $Global:StartOSDCloud, updating $Global:OSDCloud.OSVersion from "Windows 10" to "Windows 11"

So, from this small example, you can see how OSDCloud overwrites the defaults with the variables you're setting along the way using parameters, but that's just one way to set them. The GUI? It's really just a front end that allows you to set several variables using a GUI interface. Each drop down and check box maps directly to a variable.
Now we're finally getting to the good part, this is how I have automated several unique experiences based on a simple PowerShell wrapper file that gets called. Lets look at some code examples. For instance, I have a Windows 11 wrapper script that sets several items and calls OSDCloud

#### Variables to define the Windows OS / Edition etc to be applied during OSDCloud

$OSName = 'Windows 11 23H2 x64'
$OSEdition = 'Pro'
$OSActivation = 'Retail'
$OSLanguage = 'en-us'

#### Set OSDCloud Vars

$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$true
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true

####### Launch OSDCloud

Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"

Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage
When I trigger that script, it launches OSDCloud with the OS I want deployed, and presets several variables that are in the Global:MyOSDCloud variable.

You can see the variables in my script have been merged into the $global:OSDCloud variable

I keep a few variations of my wrapper scripts in GitHub, which I then call and based on hardware models, will also set additional variables, like for HP, I have it update TPM, BIOS, and run HPIA to update Drivers during Setup Complete.
As all of the available variables do change, I'm not going to list them here, but feel free to look at things in the code in the module to see a full list. If you'd ever like to see my of my examples, please reach out via Discord (WinAdmins) or X - @gwblok

##### First Boot | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/first-boot>
During First Boot (Specialize Phase), any EXE based DriverPacks in C:\Drivers will be expanded. Once expanded, they will be applied using the following PowerShell commands
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
pnpunattend.exe AuditSystem /L
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
You can identify this phase by the "Getting ready"

Dell uses CAB files or EXE files that can be expanded in WinPE, so there is no activity in First Boot other than a long delay. You can review the logs in C:\Windows\debug
Start-Process -FilePath $ExpandFile -ArgumentList "/s /e=`"$DestinationPath`"" -Wait

Write-Verbose -Verbose "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Applying DriverPack with PNPUNATTEND"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
pnpunattend.exe AuditSystem /L
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force
HP DriverPacks are silent, so there is no progress displayed during this phase other than a long delay. You can review the logs in C:\Windows\debug
Start-Process -FilePath $ExpandFile -ArgumentList "/s /e /f `"$DestinationPath`"" -Wait

Write-Verbose -Verbose "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Applying DriverPack with PNPUNATTEND"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
pnpunattend.exe AuditSystem /L
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force

Lenovo devices will display a progress when the DriverPacks is expanded
Start-Process -FilePath $ExpandFile -ArgumentList "/SILENT /SUPPRESSMSGBOXES" -Wait

Write-Verbose -Verbose "$((Get-Date).ToString('yyyy-MM-dd-HHmmss')) Applying DriverPack with PNPUNATTEND"
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths" -Name 1 -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Name Path -Value $DestinationPath -Force
pnpunattend.exe AuditSystem /L
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\UnattendSettings\PnPUnattend\DriverPaths\1" -Recurse -Force

Microsoft Surface Devices
Microsoft uses MSI DriverPacks which expanded silently, so there is no activity in First Boot other than a long delay. You can review the logs in C:\Windows\debug
$DateStamp = Get-Date -Format yyyyMMddTHHmmss
$logFile = '{0}-{1}.log' -f $ExpandFile,$DateStamp
$MSIArguments = @(
 "/i"
 ('"{0}"' -f $ExpandFile)
 "/qb"
 "/norestart"
 "/L*v"
 $logFile
)
Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow

##### OOBE | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/oobe>

 1. OSDCloud
 2. Deployment
OOBE
OSD 23.5.21.1+ Updated May 21, 2023

#### Windows | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud/deployment/windows>
DriverPacks are downloaded and expanded to C:\Drivers. This directory is not removed when an OSDCloud deployment is complete

Logs can be found in C:\OSDCloud\Logs. This directory is not removed when an OSDCloud deployment is complete

The Windows Image that was downloaded can be found in C:\OSDCloud\OS. This directory is not removed when an OSDCloud deployment is complete

#### Basic Configuration | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud-automate/basic-configuration>
Create a new OSDCloud Workspace
For this demo, I decided to create a new OSDCloud Workspace for testing. You can use your existing OSDCloud Workspace, but it's easier if I start clean. Here's the script that I used

### Set my working OSDCloud Template

Set-OSDCloudTemplate -Name 'WinPE KB5026372'

#### Create my new OSDCloud Workspace

New-OSDCloudWorkspace -WorkspacePath D:\Demo\OSDCloud\Automate

##### Cleanup Languages

$KeepTheseDirs = @('boot','efi','en-us','sources','fonts','resources')
Get-ChildItem "$(Get-OSDCloudWorkspace)\Media" | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem "$(Get-OSDCloudWorkspace)\Media\Boot" | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem "$(Get-OSDCloudWorkspace)\Media\EFI\Microsoft\Boot" | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force

### Build WinPE to start OSDCloudGUI automatically

Edit-OSDCloudWinPE -UseDefaultWallpaper -StartOSDCloudGUI

OSDCloud Automate looks for content in the following relative path by scanning all drives. It does not include C:\
`<DriveLetter>:\OSDCloud\Automate`
Understanding that requirement, there are two places that I can use this in my OSDCloud Workspace

### Content will be on the ISO or USB Boot Partition

#### Ideal for Virtual Machine testing

$(Get-OSDCloudWorkspace)\Media\OSDCloud\Automate

### Content will be on the USB Drive

#### Ideal for Physical Machine testing

$(Get-OSDCloudWorkspace)\OSDCloud\Automate

A third option would be to mount my WinPE and add an OSDCloud\Automate directory so it resolves to X:\OSDCloud\Automate. This would be ideal for WDS, but that solution isn't covered in this guide
Finally, keep in mind that if you plan on having large Provisioning Packages, your WinPE Boot Partition on a USB may not be large enough for the PPKG file. Got it?

#### OSDCloudGUI Defaults | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud-automate/osdcloudgui-defaults>
Several of you have been asking me about setting the OSDCloudGUI defaults. So let's get into it. First of all you need to be running OSD PowerShell Module 23.5.24.1 or newer, so make sure you have that updated
Start-OSDCloudGUI.json
In Windows, launch Start-OSDCloudGUI and focus on the first line. This is the default OSDCloudGUI configuration

Copy this file to your OSDCloud Automate directory in your OSDCloud Workspace

Edit Start-OSDCloudGUI.json
Start cleaning up this file and remove everything that does not need to be modified, especially the Computer information and the DriverPacks. You should end up with something similar to what I have below
{
    "BrandName":  "OSDCloud",
    "BrandColor":  "#0096D6",
    "OSActivation":  "Volume",
    "OSEdition":  "Enterprise",
    "OSLanguage":  "en-us",
    "OSImageIndex":  6,
    "OSName":  "Windows 11 22H2 x64",
    "OSReleaseID":  "22H2",
    "OSVersion":  "Windows 11",
    "OSActivationValues":  [
                               "Retail",
                               "Volume"
                           ],
    "OSEditionValues":  [
                            "Home",
                            "Home N",
                            "Home Single Language",
                            "Education",
                            "Education N",
                            "Enterprise",
                            "Enterprise N",
                            "Pro",
                            "Pro N"
                        ],
    "OSLanguageValues":  [
                             "ar-sa",
                             "bg-bg",
                             "cs-cz",
                             "da-dk",
                             "de-de",
                             "el-gr",
                             "en-gb",
                             "en-us",
                             "es-es",
                             "es-mx",
                             "et-ee",
                             "fi-fi",
                             "fr-ca",
                             "fr-fr",
                             "he-il",
                             "hr-hr",
                             "hu-hu",
                             "it-it",
                             "ja-jp",
                             "ko-kr",
                             "lt-lt",
                             "lv-lv",
                             "nb-no",
                             "nl-nl",
                             "pl-pl",
                             "pt-br",
                             "pt-pt",
                             "ro-ro",
                             "ru-ru",
                             "sk-sk",
                             "sl-si",
                             "sr-latn-rs",
                             "sv-se",
                             "th-th",
                             "tr-tr",
                             "uk-ua",
                             "zh-cn",
                             "zh-tw"
                         ],
    "OSNameValues":  [
                         "Windows 11 22H2 x64",
                         "Windows 11 21H2 x64",
                         "Windows 10 22H2 x64",
                         "Windows 10 21H2 x64",
                         "Windows 10 21H1 x64",
                         "Windows 10 20H2 x64",
                         "Windows 10 2004 x64",
                         "Windows 10 1909 x64",
                         "Windows 10 1903 x64",
                         "Windows 10 1809 x64"
                     ],
    "OSReleaseIDValues":  [
                              "22H2",
                              "21H2",
                              "21H1",
                              "20H2",
                              "2004",
                              "1909",
                              "1903",
                              "1809"
                          ],
    "OSVersionValues":  [
                            "Windows 11",
                            "Windows 10"
                        ],
    "captureScreenshots":  false,
    "ClearDiskConfirm":  true,
    "restartComputer":  true,
    "updateDiskDrivers":  true,
    "updateFirmware":  false,
    "updateNetworkDrivers":  true,
    "updateSCSIDrivers":  true
}
Collapsing a few items will help you see the design of this file. There is Branding, Defaults, Values, and Menu Options

In my configuration, I'll change the default branding to the following. If you have no plans on changing the branding, you can remove these entries
"BrandName":  "David Cloud",
"BrandColor":  "RED",
These can be difficult to configure since you have to get the OSImageIndex correct, but you can use the GUI to get that value. In my case I changed the defaults from Enterprise Volume to Pro Retail, as well as changing the Language to en-gb
"OSActivation":  "Retail",
"OSEdition":  "Pro",
"OSLanguage":  "en-gb",
"OSImageIndex":  9,
"OSName":  "Windows 11 22H2 x64",
"OSReleaseID":  "22H2",
"OSVersion":  "Windows 11",
These are all the possible Values that appear in the combobox. I'll make some minor adjustments and limit my deployment to 22H2 only, as well as cleaning up the Editions
"OSActivationValues":  [
                            "Retail",
                            "Volume"
                        ],
"OSEditionValues":  [
                        "Home",
                        "Education",
                        "Enterprise",
                        "Pro"
                    ],
"OSLanguageValues":  [
                            "en-gb",
                            "en-us"
                        ],
"OSNameValues":  [
                        "Windows 11 22H2 x64",
                        "Windows 10 22H2 x64"
                    ],
"OSReleaseIDValues":  [
                            "22H2"
                        ],
"OSVersionValues":  [
                        "Windows 11",
                        "Windows 10"
                    ],
Finally some changes to the Menu Options, enabling Firmware updates and removing the Clear-Disk confirmation prompt (dangerous)
"ClearDiskConfirm":  false,
"restartComputer":  true,
"updateDiskDrivers":  true,
"updateFirmware":  true,
"updateNetworkDrivers":  true,
"updateSCSIDrivers":  true
Here's what my complete file looks like. I'll give it a quick save
{
    "BrandName":  "David Cloud",
    "BrandColor":  "RED",
    "OSActivation":  "Retail",
    "OSEdition":  "Pro",
    "OSLanguage":  "en-gb",
    "OSImageIndex":  9,
    "OSName":  "Windows 11 22H2 x64",
    "OSReleaseID":  "22H2",
    "OSVersion":  "Windows 11",
    "OSActivationValues":  [
                                "Retail",
                                "Volume"
                            ],
    "OSEditionValues":  [
                            "Home",
                            "Education",
                            "Enterprise",
                            "Pro"
                        ],
    "OSLanguageValues":  [
                                "en-gb",
                                "en-us"
                            ],
    "OSNameValues":  [
                            "Windows 11 22H2 x64",
                            "Windows 10 22H2 x64"
                        ],
    "OSReleaseIDValues":  [
                                "22H2"
                            ],
    "OSVersionValues":  [
                            "Windows 11",
                            "Windows 10"
                        ],
    "ClearDiskConfirm":  false,
    "restartComputer":  true,
    "updateDiskDrivers":  true,
    "updateFirmware":  true,
    "updateNetworkDrivers":  true,
    "updateSCSIDrivers":  true
}
Now I can rebuild my OSDCloud ISO so my saved file will be available when OSDCloud starts. I'm also side-loading the OSD Module as I have unreleased changes that I haven't released to the PowerShell Gallery yet. Finally I set OSDCloudGUI to start automatically when WinPE starts up

Boot to WinPE and Test
When WinPE started up, OSDCloudGUI automatically launched. A quick check at my minimized PowerShell window shows that it found the configuration file and imported it. OSDCloudGUI shows the defaults that I selected and my custom David Cloud Branding

My Operating Systems are limited to Windows 10 and Windows 11 22H2, and the Windows 11 22H2 Business WIM that I had in my ISO:\OSDCloud\OS directory

Windows Edition is set properly and several values were removed

Languages are incredibly limited to just what I have configured

Finally my Deployment Options are set

### Autopilot | OSDCloud.com

Clipped from: <https://www.osdcloud.com/osdcloud-automate/autopilot>
In this example, I'm going to copy an AutopilotConfigurationFile.json in my OSDCloud Workspace in the Media\OSDCloud\Automate directory. Additionally, I'll copy a WIM to Media\OSDCloud\OS so that don't have to download an OS for my testing.

Now I'll boot to a Virtual Machine to this ISO and start an OSDCloud deployment. The screenshot below should help you visualize where the Autopilot file is on the ISO

You will see the AutopilotConfigurationFile.json is identified before the disk is wiped. This is for you to validate that your process worked.

At the end of the OSDCloud deployment, the OSDCloud Automate will inject the Autopilot Configuration File automatically

### ISO: Adding a WIM | OSDCloud.com

Clipped from: <https://www.osdcloud.com/offline-deployment/iso-adding-a-wim>
In this example, I am going to show you how to add a WIM to an ISO for deployment with OSDCloud.
OSDCloud Workspace
You probably have your own OSDCloud Workspace already configured, but I'm sharing what I'm doing for this demo, so hopefully you'll learn something new

## Set your OSDCloud Template

Set-OSDCloudTemplate -Name 'WinPE KB5026372'

## Create a new OSDCloud Workspace

New-OSDCloudWorkspace -WorkspacePath D:\Demo\OSDCloud\CustomImage

## Cleanup OSDCloud Workspace Media

$KeepTheseDirs = @('boot','efi','en-us','sources','fonts','resources')
Get-ChildItem D:\Demo\OSDCloud\CustomImage\Media | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem D:\Demo\OSDCloud\CustomImage\Media\Boot | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem D:\Demo\OSDCloud\CustomImage\Media\EFI\Microsoft\Boot | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force

## Edit WinPE and rebuild ISO

Edit-OSDCloudWinPE -UseDefaultWallpaper

For my Windows Image, I'm just going to grab one from OSDBuilder. In this case I am going to just Copy as Path

I can now copy the Windows Image to my OSDCloud Workspace and rebuild the ISO
$WindowsImage = "D:\OSDBuilder\OSMedia\Windows 11 Enterprise x64 22H2 22621.674\OS\sources\install.wim"
$Destination = "$(Get-OSDCloudWorkspace)\Media\OSDCloud\OS"
New-Item -Path $Destination -ItemType Directory -Force
Copy-Item -Path $WindowsImage -Destination "$Destination\CustomImage.wim" -Force
New-OSDCloudISO
Now when using OSDCloudGUI, WIM files that exist on any drive letter in the `<drive>:\OSDCloud\OS` path are added to the Operating System combobox. In the screenshots below I have two WIM files present

Once a WIM file has been selected in the Operating System combobox, the ImageName for each Index is populated in the secondary combobox

## Media Cleanup | OSDCloud.com

Clipped from: <https://www.osdcloud.com/archive/tips/media-cleanup>
The default OSDCloud Template Media directory contains quite a bit of language resources

These don't really do much for me as the only language in my WinPE is en-us. This can be cleaned up a bit in PowerShell with these commands
$KeepTheseDirs = @('boot','efi','en-us','sources','fonts','resources')
Get-ChildItem $env:ProgramData\OSDCloud\Media | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem $env:ProgramData\OSDCloud\Media\Boot | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
Get-ChildItem $env:ProgramData\OSDCloud\Media\EFI\Microsoft\Boot | Where {$_.PSIsContainer} | Where {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force

### Firmware Update | OSDCloud.com

Clipped from: <https://www.osdcloud.com/archive/tips/firmware-update>
OSDCloud has the ability to update Device Firmware if it is published in Microsoft Update Catalog. You can read how this works at this link

Start-OSDCloudGUI
This feature is enabled (checked) by default when using the OSDCloud GUI

When using OSDCloud Command Line, use the Firmware parameter to enable this feature

Invoke-OSDCloud
When using Invoke-OSDCloud, this feature is controlled by setting the MyOSDCloud Global Variable
$Global:MyOSDCloud = @{
 ApplyManufacturerDrivers = $false
 ApplyCatalogDrivers = $false
 ApplyCatalogFirmware = $false
}

#### Quick Setup | OSDCloud.com

Clipped from: <https://www.osdcloud.com/archive/tips/quick-setup>
Requires Admin Rights
If you are looking to quickly get OSDCloud running, and you have all the Prerequisites met, then this script should do the job. This process should take less than 10 minutes to complete

## Requires -RunAsAdministrator

## How To: Quick Setup of OSDCloud

## Drivers: All

## Startup: OSDCloudGUI

Install-Module OSD -Force
Import-Module OSD -Force
New-OSDCloud.template
New-OSDCloud.workspace -WorkspacePath C:\OSDCloud
Edit-OSDCloud.winpe -CloudDriver * -StartOSDCloudGUI
New-OSDCloud.iso
Here's how things look when you boot to the ISO

### OSDCloud - Image devices without need of infrastructure - Mindcore Techblog

Clipped from: <https://blog.mindcore.dk/2021/03/osdcloud-image-devices-without-need-of-2/>
Blog » OSDCloud – Image devices without need of infrastructure

Introduction
Have you ever been in a situation where you need to image or reimage your device? Of course, you have and so have I. Recently David Segura launched some awesome PowerShell code called OSDCloud. You might know him better for the Offline patching of images OSDBuilder, which has been on the market for quite some time.
OSDCloud is brand new and working without the need to build your own infrastructure.
How much does it cost; you may ask? Nothing, David spends his weekends for us to use it. It is free. You pay for your internet and that’s all.
This tool will deploy the OS until a state where you can onboard the device using Autopilot and finally be fully managed by Intune.
In this post I will demonstrate the steps you need to proceed with this awesome tool.

Requirements
 • Internet
 • ADK
 • USB (Only for physical devices)

  • Windows 10 1703+ to create the USB disk
 • Intune license

Table of Content

 1. Install ADK
 2. Create OSDCloud Workspace
 3. Create ISO
 4. Boot into WinPE
 5. Cloud Image your device
 6. Autopilot
 7. Managing it with Intune

ADK
You can do this on your host machine but if you don’t like to spend 5 GB on installing ADK, then find a server or another device to do the following steps. Just be aware that the function to create USB drive will not work on a server OS.

Download ADK
Install the downloaded file
Adkwinpesetup.exe
Click Next

Click Next

Click Accept

Click Install

Click Close

Download this one too
Double click adksetup.exe
Click Next, next, Accept

Click Install

Click Close

Create OSDCloud Workspace and ISO
Open PowerShell as admin

Install-Module -Name OSD -force

To build a more refined copy of ADK’s WinPE we will run this command.
New-OSDCloud.template -Verbose

Create a workspace for the binaries
New-OSDCloud.workspace -WorkspacePath E:OSDCloud

If we go to the workspace, we find the folders Autopilot and media. Let’s focus on how to get our Autopilot profile and locate it to the folder.

Let’s go and get those Autopilot profiles
$creds = Get-Credential

Insert your credentials (Intune admin)

(If you don’t have MSGraph installed yet you need to run Install-module Microsoft.Graph first)
Connect-MSGraph -Credential $creds

Get-AutopilotProfile | select displayname

Get-AutopilotProfile | Where-Object DisplayName -eq “Mindlab Production” | ConvertTo-AutopilotConfigurationJSON | Out-File -FilePath E:OSDCloudAutoPilotProfilesAutoPilotConfigurationFile.json -Encoding ASCII

Successfully downloaded the Autopilot JSON.

To get the Autopilot configuration file into the WinPe we need to edit that.
Edit-OSDCloud.winpe -WorkspacePath E:OSDCloud

If you need drivers in your PE image for supporting certain Network interfaces that can be done too. There are 2 commands at the moment.
The first one adds all WinPE drivers that exist for Dell, Nutanix and VMware.

Edit-OSDCloud.winpe -CloudDriver Dell,Nutanix,VMware

The second option is to choose your own drivers from a path
Edit-OSDCloud.winpe -DriverPath “E:OSDCloudDrivers”

Lastly we complete the ISO by building with all the elements we prepared.
New-OSDCloud.iso

And the result will look somewhat like this:

If you need to put it on a USB stick, make sure that it will be ok to erase what’s on it.
Simply run this command
New-OSDCloud.usb

Boot into PE and Cloud image your device
Start Hyper-v and create a new empty Virtual Machine.

Inside the virtual machine, PowerShell starts up.
Install-module -name OSD -force
Start-OSDCloud -OSEdition “Enterprise” -Culture “da-dk”

Press 1

Press A to confirm you will format the disk

After a while depending on your internet line, the device is ready to be rebooted. Mine took 13 minutes and 33 seconds.

Write exit

And on the CMD as well
Write exit

Autopilot
The device will reboot and start running some configurations. After a couple of minutes, you will see the known OOBE

It will reboot automatically once more and after that you will be presented with your company name.
Type your username

Type your password

Managing the device using Intune
First, we need to know the new name of the device.
Open a CMD
Type hostname

Go to <https://endpoint.microsoft.com/>
Devices -> Windows
We see our device joined Intune just fine. Now it is time to make sure our device will be converted to the Autopilot service, so next time we need to refresh Windows, this will be done without the need to reinstall the device.

Go to Groups

Press New Group

Give it a group name
Group description
Set membership to Dynamic device
Click Add dynamic variable.

Click Edit
Insert (device.enrollmentProfileName -eq “OfflineAutopilotprofile-08988bcd-1a6f-4102-878b-a713c4c9a2f1”)

You can find it in the autopilot JSON file located in E:OSDCloudAutoPilotProfiles
Grab the ID and overwrite mine.

Save the group
And press Create

Wait some time and verify your device got into the group.

We verified our device came into the group. Very nice.

Go to Devices -> Enroll devices -> Deployment Profiles
Create profile -> Windows PC

Give it a name
Convert all targeted devices to autopilot set to yes
Press Next

My device should be a user driven Autopilot experience. Set settings as beneath.
Click next

Click next

Add groups

Select Autopilot – Cloud Devices JSON
Click Select and Next

Press create

Wait some time for the profile to target the device.

Go to devices -> Windows
Click on the device

Grab the Serial number

Go to Devices -> Enroll Devices -> Devices

Insert the serial number

We did it and got our device from scratch to fully managed by Intune and converted to Autopilot without ever touching the import script or hardware hash.

Summary
For companies that needs to start their cloud journey or just need a quick way of getting Windows reinstalled, OSDCloud is an excellent choice. No expensive bills and very fast to setup to use.
Happy Cloud OSD!

#### WIM | OSDCloud.com

Clipped from: <https://www.osdcloud.com/archive/under-review/wim>
You can use a CustomImage with Start-OSDCloud by either specifying a URL, or placing the file on a USB or Network Share
If you happen to have a URL for a WIM or an ESD, you can specify that using the -ImageFileUrl parameter. Make sure you include -ImageIndex, otherwise it will default to 1

Invoke-OSDCloud Variables
These are passed from Start-OSDCloud -ImageFileUrl to Invoke-OSDCloud for processing

If you have a Custom WIM or an ESD file, simply place it in a the following path (subdirectories are good) on a USB Drive or Network Share
`<DriveLetter>:\OSDCloud\OS\*`
OSDCloud will scan the above path on available drives for image files, as long as they are WIM or ESD Files
Only Drive Letters D-Z except X: because that's WinPE (C: isn't checked because it will be wiped)
In my example below, I have mapped a Network Drive which contains the OSDCloud OS Path and 4 OS Images have been found. After selecting an ImageFile, I will be prompted to select an ImageIndex

Invoke-OSDCloud Variables
My example above will pass these variables to Invoke-OSDCloud for processing

#### Start-OOBE.settings | OSDCloud.com

Clipped from: <https://www.osdcloud.com/archive/recycle-bin/oobe/start-oobe.settings>
This function will run start ms-settings: if you need to make changes to your system in OOBE

### Start-OOBE.wifi | OSDCloud.com

Clipped from: <https://www.osdcloud.com/archive/recycle-bin/oobe/start-oobe.wifi>
If you need to connect to a Wireless network, this will run start:ms-availablenetworks:

## Start-OOBE.autopilot | OSDCloud.com

Clipped from: <https://www.osdcloud.com/archive/recycle-bin/oobe/start-oobe.autopilot>
This function makes it easy for AutoPilot Manual Registration. It will get stuck in a loop if you don't have an internet connection to powershellgallery.com

If you need to connect Wi-Fi, just CTRL + C to break out of this function and run Start-OOBE.wifi

Once you have a good internet connection, run Start-OOBE.autopilot again and it will install all the Required Modules

Get-WindowsAutoPilotInfo Script
Finally the script you need will be installed

New PowerShell Session
A new PowerShell session will open so you can do your AutoPilot business. This lets you break out of the Start-OOBE.autopilot routine if there are additional steps that you need to run

Finally when you close the new PowerShell session, you will be prompted to press Enter to start Sysprep. One you press Enter, the following steps will occur

 1. Set-ExecutionPolicy RemoteSigned
 2. Sysprep /oobe /reboot
Once this is complete you should be back in OOBE ready for AutoPilot
