# tomcatPS.ps1
# By Claus Dantzer-Sorensen 2020-08-15
# Maintainer: Hans Schou <hasch@miracle42.dk> 2020-09-04
# Homepage: https://github.com/hanschou/tomcatPS

# Requirements: PowerShell version 2.0

# PowerShell prevents foreign scripts execution. Enable with:
#   Start powershell as Administrator:
#     Set-ExecutionPolicy RemoteSigned

Param (
    [string]$ErrorActionPreference = "Stop",
    [string]$Instance="",
    [switch]$Help=$false,
    [switch]$List=$false,
    [switch]$ListFor=$false,
    [switch]$Delete=$false,
    [switch]$Variable=$false,
    [switch]$Debug=$false
)

If ($List) {
    Get-ChildItem -Path "HKLM:\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0\" | Split-Path -leaf
    Exit
}

If ($ListFor) {
    $TomcatPsOption = ""
    If ($Delete) {
        $TomcatPsOption += " -Delete"
    }
    If ($Variable) {
        $TomcatPsOption += " -Variable"
    }
    Write-Host "SET PREFIX=t_"
    Write-Host "FOR %%i IN ("
    (Get-ChildItem -Path "HKLM:\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0\" | Split-Path -leaf) -Join " "
    Write-Host ") DO ("
    Write-Host "powershell -File " $MyInvocation.MyCommand.Path "$TomcatPsOption -Instance %%i > %PREFIX%%%i.cmd"
    Write-Host ")"
    Exit
}

If ($Help -Or 0 -eq $Instance.Length) {
    Write-Host "Help Tomcat PS - Print Service"
    Write-Host
    Write-Host "Options:"
    Write-Host "  -Help"
    Write-Host "      This help."
    Write-Host "  -List"
    Write-Host "      Show list of Tomcat instances."
    Write-Host "  -ListFor"
    Write-Host "      List instances with a prepared for-loop."
    Write-Host "  -Instance <instance>"
    Write-Host "      Print install parameters for an instance."
    Write-Host "  -Delete"
    Write-Host "      Output delete option for instance."
    Write-Host "  -Variable"
    Write-Host "      Output variables for easy edit."
    Write-Host
    Write-Host "Example 1, create BAT-file for deleting af service and install it again:"
    Write-Host "  powershell -File "$MyInvocation.MyCommand.Path" -Delete -Variable -Instance foo > foo.bat"
    Write-Host
    Exit
}

# ==================================================

$RegSrv = [String]"HKLM:\SYSTEM\CurrentControlSet\Services\$Instance"
$RegDat = Get-ChildItem -Path "HKLM:\SOFTWARE\Wow6432Node\Apache Software Foundation\Procrun 2.0\$Instance\Parameters\" 

# ==================================================

$RegLeafs    = (split-path $RegDat -leaf)
$JavaPos     = [array]::IndexOf($RegLeafs, 'Java') 
$LogPos      = [array]::IndexOf($RegLeafs, 'Log') 
$StartPos    = [array]::IndexOf($RegLeafs, 'Start') 
$StopPos     = [array]::IndexOf($RegLeafs, 'Stop') 
<# PS > ver 3.x
$JavaPos     = (split-path $RegDat -leaf).indexof('Java')
$LogPos      = (split-path $RegDat -leaf).indexof('Log')
$StartPos    = (split-path $RegDat -leaf).indexof('Start')
$StopPos     = (split-path $RegDat -leaf).indexof('Stop')
#>

$execPath    = [string](get-itemproperty -Path $RegSrv).ImagePath
$ObjectName  = [string](get-itemproperty -Path $RegSrv).ObjectName

# ==================================================

$CLASSPATH     = $RegDat[$JavaPos].GetValue('Classpath')      #    => java.classpath
$Description   = (get-itemproperty -Path $RegSrv).Description
$DisplayName   = (get-itemproperty -Path $RegSrv).DisplayName
$EXECUTABLE    = $execPath.Split(" ")[0]
$JVM           = $RegDat[$JavaPos].GetValue('Jvm')            #     => ~.dll
$JvmMs         = $RegDat[$JavaPos].GetValue('JvmMs')          # 128  => Reg.java 128  JvmMs
$JvmMx         = $RegDat[$JavaPos].GetValue('JvmMx')          # 256
$JvmOptions    = $RegDat[$JavaPos].GetValue('Options') -Join ";"
$JvmOptions9   = $RegDat[$JavaPos].GetValue('Options9') -Join "#"
$SERVICE_NAME  = (get-itemproperty -Path $RegSrv).PSChildName
$start_Par     = $RegDat[$StartPos].GetValue('Params')      #  => reg > start.params
$StartClass    = $RegDat[$StartPos].GetValue('Class')       #  => reg > start.class
$StartMode     = $RegDat[$StartPos].GetValue('Mode')        #  => reg > start.Mode
$StartPath     = $RegDat[$StartPos].GetValue('WorkingPath') #  => reg > start.path
$Startup       = switch ((get-itemproperty -Path $RegSrv).Start) { 
                   0 {"Boot"; break}
                   1 {"System"; break}
                   2 {"auto"; break}
                   3 {"manual"; break}
                   4 {"Disabled"; break}
                 } # switch
$LogPath       = $RegDat[$LogPos].GetValue('Path')
$StdError      = $RegDat[$LogPos].GetValue('StdError')      #  => reg > log.StdError
$StdOutput     = $RegDat[$LogPos].GetValue('StdOutput')     #  => reg > log.StdOutput
$stop_Par      = $RegDat[$StopPos].GetValue('Params')       #  => reg > stop.params
$StopPath      = $RegDat[$StopPos].GetValue('WorkingPath')  #  => reg > stop.path
$StopClass     = $RegDat[$StopPos].GetValue('Class')        #  => reg > stop.class
$StopMode      = $RegDat[$StopPos].GetValue('Mode')         #  => reg > stop.Mode

If (0 -eq $JvmOptions9.Length) {
    # Hardcoded: 
    $JvmOptions9 = [string]"--add-opens=java.base/java.lang=ALL-UNNAMED#--add-opens=java.base/java.io=ALL-UNNAMED#--add-opens=java.rmi/sun.rmi.transport=ALL-UNNAMED"
}

If ($Delete) {
    Write-Host "REM Delete Service"
    Write-Host "NET STOP $SERVICE_NAME" # Stop service and wait for stopped
    Write-Host ":WAIT_STOP"
    Write-Host "sc query $SERVICE_NAME | findstr _PENDING"
    Write-Host "IF %ERRORLEVEL% EQU 1 GOTO :WAIT_DONE"
    Write-Host "timeout 1"
    Write-Host "GOTO :WAIT_STOP"
    Write-Host ":WAIT_DONE"
    Write-Host "`"$EXECUTABLE`" //DS//$SERVICE_NAME"
    Write-Host "PAUSE"
    Write-Host
}

Write-Host "REM Install Service"
if ($Variable) {
Write-Host "SET EXECUTABLE=$EXECUTABLE"
Write-Host "SET Description=$Description"
Write-Host "SET DisplayName=$DisplayName"
Write-Host "SET Classpath=$Classpath"
Write-Host "SET JVM=$JVM"
Write-Host "SET JvmMs=$JvmMs"
Write-Host "SET JvmMx=$JvmMx"
Write-Host "SET JvmOptions=$JvmOptions"
Write-Host "SET JvmOptions9=$JvmOptions9"
Write-Host "SET SERVICE_NAME=$SERVICE_NAME"
Write-Host "SET start_Par=$start_Par"
Write-Host "SET StartClass=$StartClass"
Write-Host "SET StartMode=$StartMode"
Write-Host "SET StartPath=$StartPath"
Write-Host "SET Startup=$Startup"
Write-Host "SET LogPath=$LogPath"
Write-Host "SET StdError=$StdError"
Write-Host "SET StdOutput=$StdOutput"
Write-Host "SET stop_Par=$stop_Par"
Write-Host "SET StopPath=$StopPath"
Write-Host "SET StopClass=$StopClass"
Write-Host "SET StopMode=$StopMode"
Write-Host `
"`"%EXECUTABLE%`" //IS//$SERVICE_NAME ^`n"`
"    --Description `"%Description%`" ^`n"`
"    --DisplayName `"%DisplayName%`" ^`n"`
"    --Install `"%EXECUTABLE%`" ^`n"`
"    --LogPath `"%LogPath%`" ^`n"`
"    --StdOutput %StdOutput% ^`n"`
"    --StdError %StdError% ^`n"`
"    --Classpath `"%Classpath%`" ^`n"`
"    --Jvm `"%JVM%`" ^`n"`
"    --StartMode %StartMode% ^`n"`
"    --StopMode %StopMode% ^`n"`
"    --StartPath `"%StartPath%`" ^`n"`
"    --StopPath `"%StopPath%`" ^`n"`
"    --StartClass %StartClass% ^`n"`
"    --StopClass %StopClass% ^`n"`
"    --StartParams %start_Par% ^`n"`
"    --StopParams %stop_Par% ^`n"`
"    --JvmOptions `"%JvmOptions%`" ^`n"`
"    --JvmOptions9 `"%JvmOptions9%`" ^`n"`
"    --Startup `"%Startup%`" ^`n"`
"    --JvmMs `"%JvmMs%`" ^`n"`
"    --JvmMx `"%JvmMx%`""
Write-Host "ECHO ERRORLEVEL: %ERRORLEVEL%"
}
else
{
Write-Host `
"`"$EXECUTABLE`" //IS//$SERVICE_NAME ^`n"`
"    --Description `"$Description`" ^`n"`
"    --DisplayName `"$DisplayName`" ^`n"`
"    --Install `"$EXECUTABLE`" ^`n"`
"    --LogPath `"$LogPath`" ^`n"`
"    --StdOutput $StdOutput ^`n"`
"    --StdError $StdError ^`n"`
"    --Classpath `"$CLASSPATH`" ^`n"`
"    --Jvm `"$JVM`" ^`n"`
"    --StartMode $StartMode ^`n"`
"    --StopMode $StopMode ^`n"`
"    --StartPath `"$StartPath`" ^`n"`
"    --StopPath `"$StopPath`" ^`n"`
"    --StartClass $StartClass ^`n"`
"    --StopClass $StopClass ^`n"`
"    --StartParams $start_Par ^`n"`
"    --StopParams $stop_Par ^`n"`
"    --JvmOptions `"$JvmOptions`" ^`n"`
"    --JvmOptions9 `"$JvmOptions9`" ^`n"`
"    --Startup `"$Startup`" ^`n"`
"    --JvmMs `"$JvmMs`" ^`n"`
"    --JvmMx `"$JvmMx`""
Write-Host "IF NOT ERRORLEVEL 1 GOTO :installed"
Write-Host "ECHO Failed installing '$SERVICE_NAME' service"
Write-Host "GOTO :end"
Write-Host ":installed"
Write-Host "@ECHO The service '$SERVICE_NAME' has been installed."
If ("LocalSystem" -eq $ObjectName) {
    Write-Host "ECHO Goto Windows Service/Properties and change 'Log On' / 'Log on as:' to 'Local System'"
} else {
    Write-Host "NET START $SERVICE_NAME"
}
Write-Host ":end"
}
