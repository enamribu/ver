@echo off
title Script Gabungan
color 0A

echo ==========================================
echo 1. Aktivasi Windows
echo ==========================================
:: Isi dari 10 11 PRO.bat (tanpa del "%~f0")
cscript //nologo c:\windows\system32\slmgr.vbs /ipk W269N-WFGWX-YVC9B-4J6C9-T83GX >nul
cscript //nologo c:\windows\system32\slmgr.vbs /skms kms8.msguides.com >nul
cscript //nologo c:\windows\system32\slmgr.vbs /ato
ping -n 3 127.0.0.1 >nul

echo.
echo ==========================================
echo 2. Instal Google Chrome
echo ==========================================
:: Isi dari Chrome Download.bat (tanpa del "%~f0")
set "URL=https://dl.google.com/chrome/install/latest/chrome_installer.exe"
set "INSTALLER=%TEMP%\chrome_installer.exe"
powershell -Command "(New-Object System.Net.WebClient).DownloadFile('%URL%', '%INSTALLER%')"
if exist "%INSTALLER%" (
    start /wait "" "%INSTALLER%" /silent /install
    del "%INSTALLER%"
) else (
    echo Gagal mengunduh Google Chrome.
)

echo.
echo ==========================================
echo 3. Disable Windows Update
echo ==========================================
:: Isi dari DisableWindowsUpdate.bat (tanpa del "%~f0")
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: Harus dijalankan sebagai Administrator!
    pause
    exit /b 1
)

for %%S in (
    wuauserv
    bits
    dosvc
    UsoSvc
    WaaSMedicSvc
) do (
    sc stop %%S >nul 2>&1
    sc config %%S start= disabled >nul 2>&1
)

for %%T in (
    "\Microsoft\Windows\WindowsUpdate\Scheduled Start"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Scan"
    "\Microsoft\Windows\UpdateOrchestrator\Schedule Retry Scan"
    "\Microsoft\Windows\UpdateOrchestrator\USO_UxBroker"
    "\Microsoft\Windows\UpdateOrchestrator\Reboot"
    "\Microsoft\Windows\UpdateOrchestrator\Maintenance Install"
) do (
    schtasks /Change /TN %%~T /Disable >nul 2>&1
)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate    /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions        /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"    /v DisableOSUpgrade /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection"   /v AllowTelemetry   /t REG_DWORD /d 0 /f

attrib -R "%SystemRoot%\System32\drivers\etc\hosts"
>>"%SystemRoot%\System32\drivers\etc\hosts" echo 127.0.0.1 windowsupdate.microsoft.com
>>"%SystemRoot%\System32\drivers\etc\hosts" echo 127.0.0.1 update.microsoft.com
>>"%SystemRoot%\System32\drivers\etc\hosts" echo 127.0.0.1 download.windowsupdate.com
attrib +R "%SystemRoot%\System32\drivers\etc\hosts"

gpupdate /force >nul 2>&1

echo.
echo **********************************************
echo * Semua script sudah dijalankan.             *
echo **********************************************

:: Hapus diri sendiri di akhir
echo exit | timeout /t 3 >nul & del "%~f0"
