@echo off
:: install.bat - Zyllen Wallpaper Installer
:: Versão: 1.4 - ONLOGON sem /RU para funcionar sem senha

:: ─── Auto-elevação ───────────────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissao de Administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

setlocal EnableDelayedExpansion
title Zyllen Wallpaper - Instalação

echo ============================================
echo   Zyllen Wallpaper - Instalador v1.4
echo ============================================
echo.

:: ─── Define destino ──────────────────────────────────────────────────────
set "DEST=C:\ProgramData\ZyllenWallpaper"
set "TASK_NAME=ZyllenWallpaper"
set "SCRIPT_SRC=%~dp0update-wallpaper.ps1"

:: ─── Cria diretório de destino ───────────────────────────────────────────
echo [1/3] Criando diretorio de instalacao...
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\wallpapers" mkdir "%DEST%\wallpapers"

:: Garante permissao de escrita para todos os usuarios
icacls "%DEST%" /grant "Users:(OI)(CI)F" /T >nul 2>&1

:: ─── Copia script PowerShell ─────────────────────────────────────────────
echo [2/3] Copiando scripts...
copy /Y "%SCRIPT_SRC%" "%DEST%\update-wallpaper.ps1" >nul
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao copiar update-wallpaper.ps1
    pause
    exit /b 1
)
echo     OK: update-wallpaper.ps1 copiado

:: ─── Cria tarefa via PowerShell (mais confiavel que schtasks) ────────────
echo [3/3] Criando tarefa agendada "%TASK_NAME%"...

schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

powershell -Command "$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument '-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%DEST%\update-wallpaper.ps1\"'; $trigger = New-ScheduledTaskTrigger -AtLogOn; $trigger.Delay = 'PT1M'; $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 10); $principal = New-ScheduledTaskPrincipal -GroupId \"Users\" -RunLevel Limited; Register-ScheduledTask -TaskName '%TASK_NAME%' -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force" >nul 2>&1

if %errorlevel% neq 0 (
    echo [ERRO] Falha ao criar tarefa agendada.
    pause
    exit /b 1
)
echo     OK: Tarefa criada para todos os usuarios - roda 1 minuto apos cada login

echo.
echo ============================================
echo   Instalacao concluida com sucesso!
echo.
echo   - Script em: %DEST%\update-wallpaper.ps1
echo   - Tarefa: %TASK_NAME% (roda ao ligar/logar)
echo   - Wallpaper sera aplicado na proxima vez
echo     que a maquina ligar
echo   - Log em: %DEST%\log.txt
echo ============================================
echo.
pause
