@echo off
:: install.bat - Zyllen Wallpaper Installer
:: Versão: 1.3 - Roda como usuario logado (nao SYSTEM)

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
echo   Zyllen Wallpaper - Instalador v1.3
echo ============================================
echo.

:: ─── Define destino ──────────────────────────────────────────────────────
set "DEST=C:\ProgramData\ZyllenWallpaper"
set "TASK_NAME=ZyllenWallpaper"
set "SCRIPT_SRC=%~dp0update-wallpaper.ps1"

:: ─── Detecta usuario logado ──────────────────────────────────────────────
for /f "tokens=1" %%u in ('query session ^| findstr ">"') do set "SESSION=%%u"
for /f "skip=1 tokens=1" %%u in ('query user ^| findstr ">"') do set "LOGGEDUSER=%%u"
if "%LOGGEDUSER%"=="" set "LOGGEDUSER=%USERNAME%"

echo Usuario detectado: %LOGGEDUSER%
echo.

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

:: ─── Cria tarefa agendada como usuario logado ────────────────────────────
echo [3/3] Criando tarefa agendada "%TASK_NAME%"...

schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

schtasks /Create /TN "%TASK_NAME%" ^
    /TR "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%DEST%\update-wallpaper.ps1\"" ^
    /SC ONLOGON ^
    /DELAY 0001:00 ^
    /RU "%LOGGEDUSER%" ^
    /F >nul 2>&1

if %errorlevel% neq 0 (
    echo [AVISO] Falha com usuario %LOGGEDUSER%. Tentando usuario atual...
    schtasks /Create /TN "%TASK_NAME%" ^
        /TR "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%DEST%\update-wallpaper.ps1\"" ^
        /SC ONLOGON ^
        /DELAY 0001:00 ^
        /RU "%USERNAME%" ^
        /F >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao criar tarefa agendada.
        pause
        exit /b 1
    )
)
echo     OK: Tarefa criada para usuario %LOGGEDUSER% - roda 1 minuto apos cada login

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
