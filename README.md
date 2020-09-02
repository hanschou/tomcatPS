# tomcatPS
Tomcat Print Service

A tool for helping with batch major upgrade of Windows Apache Tomcat installations.

Target audience: Windows system administrators who should upgrade many Tomcat installations.

## Problem
An existing Tomcat installation can have a lot of parameter set Java and the like. 
When doing a major upgrade from e.g. 8.0 to 9.0, one have to preserve these options
but the only way to upgrade is by first removing the service and then install it again.
In this process the Java options is lost.

## Solution
The tool `tomcatPS.ps1` is a PowerShell script which can extract the Tomcat Java options 
which is stored in the Windows Registry system.
The script will output the same options which was set when you issued the command:
> `\bin\service.bat install foo`

## Installation
Copy the script to a subdirectory on the disk say `C:\Tool\tomcatPS.ps1`.
Often PowerShell will prevent external scripts from running so it has to changed.
* Start PowerShell as Administrator
* Run the command: `Set Execute Remote`
Now the the script can be tested with the following command and sample output:
> `C:\> powershell -File C:\Tool\tomcatPS.ps1 -List`  
> `foo`  
> `bar`

## Commands
A list of commands can be invoked from command line:
* `-List` Show a list of all Tomcat instances found int the registry
* `-ListFor` Generate a script to stdout to extrct all Tomcat instances
* `-Instance <instance>` Generate a script for extracting one Tomcat instance
* `-Delete` Switch for adding delete (remove) script commands

## Workflow
Run the `-List` command to get an overview:
> `C:\> powershell -File C:\Tool\tomcatPS.ps1 -List`
If you want to have a copy of all the current installations create an `old` directory with these scripts:
> `MKDIR old`  
> `CD old`  
> `powershell -File C:\Tool\tomcatPS.ps1 -Delete -ListFor > ListFor.cmd` 
> `ListFor.cmd`  
> `TYPE t_foo.cmd`  
> `CD ..`  
Then make a set of scripts which can be edited with the new major version.
    MKDIR new
    CD new
    powershell -File C:\Tool\tomcatPS.ps1 -Delete -ListFor > ListFor.cmd
    ListFor.cmd
 Then all the scripts generated can be changed.
 
 ## Example of instance remove/install script
     <REM paste here>
 
 ## Example of ListFor script:
     <REM paste here>
 
 
