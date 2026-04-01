@echo off
:: install.bat - Zyllen Wallpaper Installer
:: Execute via duplo clique no pendrive (como Administrador recomendado)
:: Versão: 1.0

setlocal EnableDelayedExpansion
title Zyllen Wallpaper - Instalação

echo ============================================
echo   Zyllen Wallpaper - Instalador v1.0
echo ============================================
echo.

:: ─── Verifica privilégios ────────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] Execute como Administrador para criar tarefa agendada.
    echo Tentando com permissoes atuais...
    echo.
)

:: ─── Define destino ──────────────────────────────────────────────────────
set "DEST=C:\ProgramData\ZyllenWallpaper"
set "TASK_NAME=ZyllenWallpaper"

:: ─── Cria diretório de destino ───────────────────────────────────────────
echo [1/4] Criando diretorio de instalacao...
if not exist "%DEST%" (
    mkdir "%DEST%"
)
if not exist "%DEST%\wallpapers" (
    mkdir "%DEST%\wallpapers"
)

:: ─── Copia script PowerShell ─────────────────────────────────────────────
echo [2/4] Copiando scripts...
copy /Y "%~dp0update-wallpaper.ps1" "%DEST%\update-wallpaper.ps1" >nul
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao copiar update-wallpaper.ps1
    pause
    exit /b 1
)
echo     OK: update-wallpaper.ps1 copiado

:: ─── Cria tarefa agendada ────────────────────────────────────────────────
echo [3/4] Criando tarefa agendada "%TASK_NAME%"...

:: Remove tarefa antiga se existir
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

:: Cria nova tarefa: roda todo dia às 08:00 como SYSTEM (sem popup)
schtasks /Create /TN "%TASK_NAME%" ^
    /TR "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%DEST%\update-wallpaper.ps1\"" ^
    /SC DAILY ^
    /ST 08:00 ^
    /RU SYSTEM ^
    /RL HIGHEST ^
    /F >nul 2>&1

if %errorlevel% neq 0 (
    echo [AVISO] Nao foi possivel criar tarefa como SYSTEM.
    echo         Tentando com usuario atual...
    schtasks /Create /TN "%TASK_NAME%" ^
        /TR "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%DEST%\update-wallpaper.ps1\"" ^
        /SC DAILY ^
        /ST 08:00 ^
        /F >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERRO] Falha ao criar tarefa agendada.
        pause
        exit /b 1
    )
)
echo     OK: Tarefa agendada criada (diaria as 08:00)

:: ─── Roda imediatamente ──────────────────────────────────────────────────
echo [4/4] Aplicando wallpaper agora...
powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%DEST%\update-wallpaper.ps1"

echo.
echo ============================================
echo   Instalacao concluida com sucesso!
echo.
echo   - Script em: %DEST%\update-wallpaper.ps1
echo   - Tarefa: %TASK_NAME% (todo dia as 08:00)
echo   - Log em: %DEST%\log.txt
echo ============================================
echo.
pause
