
@echo off
setlocal
title Advanced Laptop Maintenance Toolbox
color 0B

set "LOG=%USERPROFILE%\Desktop\LaptopMaintenance.log"

:: Check Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Please right-click this file and select Run as administrator.
    pause
    exit /b
)

:MENU
cls
echo ==================================================
echo          ADVANCED LAPTOP MAINTENANCE
echo ==================================================
echo.
echo  1. Quick maintenance
echo  2. Full Windows repair (DISM + SFC)
echo  3. Component store cleanup
echo  4. Disk and SSD health check
echo  5. Clean user temporary files
echo  6. Windows Disk Cleanup
echo  7. Reset Windows Update download cache
echo  8. Network troubleshooting
echo  9. Advanced network reset
echo 10. Update installed applications
echo 11. Generate battery health report
echo 12. Generate system and driver reports
echo 13. Create Windows restore point
echo 14. Check available disk space
echo 15. Exit
echo.
echo Log file: %LOG%
echo ==================================================
set /p choice="Choose an option: "

if "%choice%"=="1" goto QUICK
if "%choice%"=="2" goto REPAIR
if "%choice%"=="3" goto COMPONENT
if "%choice%"=="4" goto DISK
if "%choice%"=="5" goto TEMP
if "%choice%"=="6" goto CLEANMGR
if "%choice%"=="7" goto UPDATECACHE
if "%choice%"=="8" goto NETWORK
if "%choice%"=="9" goto NETRESET
if "%choice%"=="10" goto WINGET
if "%choice%"=="11" goto BATTERY
if "%choice%"=="12" goto REPORTS
if "%choice%"=="13" goto RESTORE
if "%choice%"=="14" goto SPACE
if "%choice%"=="15" exit /b

echo Invalid choice.
pause
goto MENU


:QUICK
cls
echo Running quick maintenance...
echo.

echo Checking Windows component store...
DISM /Online /Cleanup-Image /CheckHealth

echo.
echo Cleaning superseded Windows components...
DISM /Online /Cleanup-Image /StartComponentCleanup

echo.
echo Checking file system...
chkdsk C: /scan

echo.
echo Cleaning user temporary files...
powershell -NoProfile -Command "Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue"

echo.
echo Quick maintenance completed.
pause
goto MENU


:REPAIR
cls
echo Windows image repair and system file check
echo This may take some time.
echo.

DISM /Online /Cleanup-Image /ScanHealth
DISM /Online /Cleanup-Image /RestoreHealth

echo.
echo Running System File Checker...
sfc /scannow

echo.
echo Repair completed. Restart if requested.
pause
goto MENU


:COMPONENT
cls
echo Analyzing Windows component store...
DISM /Online /Cleanup-Image /AnalyzeComponentStore

echo.
echo Cleaning outdated components...
DISM /Online /Cleanup-Image /StartComponentCleanup

echo.
echo Done. ResetBase is intentionally not used.
pause
goto MENU


:DISK
cls
echo Checking file system...
chkdsk C: /scan

echo.
echo Checking physical disk status...
powershell -NoProfile -Command "Get-PhysicalDisk | Select-Object FriendlyName,MediaType,HealthStatus,OperationalStatus,Size | Format-Table -AutoSize"

echo.
echo Note: This does not replace manufacturer SSD diagnostics.
pause
goto MENU


:TEMP
cls
echo Cleaning your user temporary folder...
powershell -NoProfile -Command "Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue"

echo.
echo Temporary file cleanup completed.
echo Some files may remain because they are currently in use.
pause
goto MENU



:CLEANMGR
cls
echo =====================================
echo       WINDOWS DISK CLEANUP
echo =====================================
echo.
echo 1. Classic Windows Disk Cleanup
echo 2. Open Windows Storage Settings
echo 3. Clean user temporary files
echo 4. Return to main menu
echo.
set /p cleanchoice="Choose an option: "

if "%cleanchoice%"=="1" (
    if exist "%SystemRoot%\System32\cleanmgr.exe" (
        start "" "%SystemRoot%\System32\cleanmgr.exe"
    ) else (
        echo Disk Cleanup is unavailable on this Windows installation.
    )
)

if "%cleanchoice%"=="2" (
    start ms-settings:storagesense
)

if "%cleanchoice%"=="3" (
    powershell -NoProfile -Command "Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue"
    echo Temporary files cleanup completed.
)

if "%cleanchoice%"=="4" goto MENU

pause
goto CLEANMGR


:UPDATECACHE
cls
echo Resetting Windows Update download cache...
echo.

set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU

net stop bits
net stop wuauserv

if exist "%windir%\SoftwareDistribution\Download\" (
    rd /s /q "%windir%\SoftwareDistribution\Download"
    echo Download cache deleted.
) else (
    echo Download cache does not exist. Skipping.
)

net start wuauserv
net start bits

echo.
echo Windows Update cache reset completed.
pause
goto MENU


:NETRESET
cls
echo This resets Winsock and TCP/IP settings.
echo It may affect VPNs or custom network configurations.
echo A restart will be required.
echo.
set /p confirm="Continue? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU

netsh winsock reset
netsh int ip reset

echo.
echo Restart your laptop to complete the reset.
pause
goto MENU


:WINGET
cls
echo Checking available application updates...
winget upgrade

echo.
set /p confirm="Install all available updates? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU

winget upgrade --all --accept-source-agreements --accept-package-agreements

echo.
echo Application update process completed.
pause
goto MENU


:BATTERY
cls
echo Generating battery report...
powercfg /batteryreport /output "%USERPROFILE%\Desktop\battery-report.html"

echo.
echo Report saved to your Desktop.
pause
goto MENU


:REPORTS
cls
echo Generating system information...
systeminfo > "%USERPROFILE%\Desktop\SystemInfo.txt"

echo Generating driver list...
driverquery /v /fo csv > "%USERPROFILE%\Desktop\DriverList.csv"

echo Generating network information...
ipconfig /all > "%USERPROFILE%\Desktop\NetworkInfo.txt"

echo.
echo Reports saved to your Desktop:
echo SystemInfo.txt
echo DriverList.csv
echo NetworkInfo.txt
pause
goto MENU


:RESTORE
cls
echo Attempting to create a restore point...
echo System Protection must be enabled.
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Checkpoint-Computer -Description 'BeforeMaintenance' -RestorePointType 'MODIFY_SETTINGS'"

echo.
echo If an error appeared, System Protection may be disabled
echo or Windows may have recently created a restore point.
pause
goto MENU


:SPACE
cls
echo Available disk space:
powershell -NoProfile -Command "Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{Name='UsedGB';Expression={[math]::Round($_.Used/1GB,2)}},@{Name='FreeGB';Expression={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize"

echo.
pause
goto MENU
