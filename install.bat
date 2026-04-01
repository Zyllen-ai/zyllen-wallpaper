@echo off
:: install.bat - Zyllen Wallpaper Installer
:: Versão: 1.2 - Auto-elevação de privilégios

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
echo   Zyllen Wallpaper - Instalador v1.2
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

:: ─── Copia script PowerShell ─────────────────────────────────────────────
echo [2/3] Copiando scripts...
copy /Y "%SCRIPT_SRC%" "%DEST%\update-wallpaper.ps1" >nul
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao copiar update-wallpaper.ps1
    echo Verifique se o pendrive esta conectado corretamente.
    pause
    exit /b 1
)
echo     OK: update-wallpaper.ps1 copiado

:: ─── Cria tarefa agendada ────────────────────────────────────────────────
echo [3/3] Criando tarefa agendada "%TASK_NAME%"...

schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

schtasks /Create /TN "%TASK_NAME%" ^
    /TR "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%DEST%\update-wallpaper.ps1\"" ^
    /SC ONLOGON ^
    /DELAY 0001:00 ^
    /RU SYSTEM ^
    /RL HIGHEST ^
    /F >nul 2>&1

if %errorlevel% neq 0 (
    echo [AVISO] Falha ao criar tarefa como SYSTEM. Tentando usuario atual...
    schtasks /Create /TN "%TASK_NAME%" ^
        /TR "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%DEST%\update-wallpaper.ps1\"" ^
        /SC ONLOGON ^
        /DELAY 0001:00 ^
        /F >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao criar tarefa agendada.
        pause
        exit /b 1
    )
)
echo     OK: Tarefa criada - roda 1 minuto apos cada login

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
