# tomcatPS
Tomcat Print Service

A tool for helping with batch major upgrade of Windows Apache Tomcat installations.

Target audience: Windows system administrators who should upgrade many Tomcat installations.

This **PS** solution will be replaced by a [build in function](https://issues.apache.org/jira/browse/DAEMON-422) in the next Tomcat release.

## Problem
An existing Tomcat installation can have a lot of parameter set Java and the like. 
When doing a major upgrade from e.g. 8.0 to 9.0, one have to preserve these options
but the only way to upgrade is by first removing the service and then install it again.
In this process the Java options is lost.

## Solution
The tool `tomcatPS.ps1` is a PowerShell script which can extract the Tomcat Java options 
which is stored in the Windows Registry system.
The script will output the same options which was set when you issued the command:
```
\bin\service.bat install foo
```

## Installation
Copy the script to a subdirectory on the disk say `C:\Tool\tomcatPS.ps1`.
Often PowerShell will prevent external scripts from running so it has to changed.
* Start PowerShell as Administrator
* Run the command: `Set Execute Remote`
Now the the script can be tested with the following command and sample output:
```
C:\> powershell -File C:\Tool\tomcatPS.ps1 -List
foo
bar
```

## Commands
A list of commands can be invoked from command line:
* `-List` Show a list of all Tomcat instances found in the registry
* `-ListFor` Generate a script to stdout to extract all Tomcat instances
* `-Instance <instance>` Generate a script for extracting one Tomcat instance
* `-Delete` Switch for adding delete (remove) script commands

## Workflow
Run the `-List` command to get an overview:
```
C:\> powershell -File C:\Tool\tomcatPS.ps1 -List
foo
bar
```

If you want to have a copy of all the current installations create an `old` directory with these scripts:
```
MKDIR old
CD old
powershell -File C:\Tool\tomcatPS.ps1 -Delete -ListFor > ListFor.cmd
ListFor.cmd
TYPE t_foo.cmd
CD ..
```
Then make a set of scripts which can be edited with the new major version.
```
MKDIR new
CD new
powershell -File C:\Tool\tomcatPS.ps1 -Delete -ListFor > ListFor.cmd
ListFor.cmd
```
Then all the scripts generated can be changed.
 
## Example of instance remove/install script
Here is a sample of the command
`powershell -File C:\Tools\tomcatPS.ps1 -Delete -Instance foo > foo.cmd`

```
REM Delete Service
NET STOP foo
:WAIT_STOP
sc query linearsearch | findstr PENDING
IF %ERRORLEVEL% EQU 1 GOTO :WAIT_DONE
timeout 1
GOTO :WAIT_STOP
:WAIT_DONE
"C:\Apache\tomcat-9.0\bin\tomcat9.exe" //DS//foo
PAUSE

REM Install Service
"C:\Apache\tomcat-9.0\bin\tomcat9.exe" //IS//foo ^
     --Description "Apache Tomcat 9.0 Server - https://tomcat.apache.org/" ^
     --DisplayName "Apache Tomcat 9.0 foo" ^
     --Install "C:\Apache\tomcat-9.0\bin\tomcat9.exe" ^
     --LogPath "C:\tomcat\foo\logs" ^
     --StdOutput auto ^
     --StdError auto ^
     --Classpath "C:\Apache\tomcat-9.0\bin\bootstrap.jar;C:\tomcat\foo\bin\tomcat-juli.jar;C:\Apache\tomcat-9.0\bin\tomcat-juli.jar" ^
     --Jvm "C:\Java\jdk11\bin\server\jvm.dll" ^
     --StartMode jvm ^
     --StopMode jvm ^
     --StartPath "C:\Apache\tomcat-9.0" ^
     --StopPath "C:\Apache\tomcat-9.0" ^
     --StartClass org.apache.catalina.startup.Bootstrap ^
     --StopClass org.apache.catalina.startup.Bootstrap ^
     --StartParams start ^
     --StopParams stop ^
     --JvmOptions "-Dcatalina.home=C:\Apache\tomcat-9.0;-Dcatalina.base=C:\tomcat\foo;-Dignore.endorsed.dirs=C:\Apache\tomcat-9.0\endorsed;-Djava.io.tmpdir=C:\tomcat\foo\temp;-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager;-Djava.util.logging.config.file=C:\tomcat\foo\conf\logging.properties;-Dsegments-web-api.home=c:\tomcat\foo\dictionary-cache;" ^
     --JvmOptions9 "--add-opens=java.base/java.lang=ALL-UNNAMED#--add-opens=java.base/java.io=ALL-UNNAMED#--add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED#" ^
     --Startup "auto" ^
     --JvmMs "4000" ^
     --JvmMx "4000"
IF NOT ERRORLEVEL 1 GOTO :installed
ECHO Failed installing 'foo' service
GOTO :end
:installed
@ECHO The service 'foo' has been installed.
ECHO Goto Windows Service/Properties and change 'Log On' / 'Log on as:' to 'Local System'
:end
```
## Example of ListFor script:
Here is a sample of the command
`powershell -File C:\Tools\tomcatPS.ps1 -ListFor > ListFor.cmd`

```
SET PREFIX=t_
FOR %%i IN (
foo bar
) DO (
powershell -File  D:\tools\tomcatPS.ps1  -Delete -Instance %%i > %PREFIX%%%i.cmd
)
```
