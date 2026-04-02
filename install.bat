@echo off
:: install.bat - Zyllen Wallpaper Installer
:: Versão: 2.0 - HKLM Run Key (sem Task Scheduler, funciona em qualquer idioma)
:: Plug and play: rodar como admin uma vez em cada máquina

:: ─── Auto-elevação ───────────────────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissao de Administrador...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal EnableDelayedExpansion
title Zyllen Wallpaper - Instalacao v2.0
color 0A

echo.
echo  ============================================
echo    Zyllen Wallpaper - Instalador v2.0
echo  ============================================
echo.

:: ─── Caminhos ────────────────────────────────────────────────────────────────
set "DEST=C:\ProgramData\ZyllenWallpaper"
set "SCRIPT_SRC=%~dp0update-wallpaper.ps1"
set "SCRIPT_DEST=%DEST%\update-wallpaper.ps1"
set "REG_KEY=HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
set "REG_NAME=ZyllenWallpaper"

:: ─── Verifica script fonte ───────────────────────────────────────────────────
if not exist "%SCRIPT_SRC%" (
    echo [ERRO] update-wallpaper.ps1 nao encontrado em:
    echo        %SCRIPT_SRC%
    echo.
    echo Certifique-se de que install.bat e update-wallpaper.ps1
    echo estao na mesma pasta.
    pause
    exit /b 1
)

:: ─── Cria diretórios ─────────────────────────────────────────────────────────
echo [1/3] Criando diretorios...
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\wallpapers" mkdir "%DEST%\wallpapers"

:: Permissões de escrita para todos os usuários (necessário para salvar log/current.txt)
icacls "%DEST%" /grant "Usuarios:(OI)(CI)F" /T >nul 2>&1
icacls "%DEST%" /grant "Users:(OI)(CI)F" /T >nul 2>&1
icacls "%DEST%" /grant "Everyone:(OI)(CI)F" /T >nul 2>&1
echo     OK

:: ─── Copia script ────────────────────────────────────────────────────────────
echo [2/3] Copiando script...
copy /Y "%SCRIPT_SRC%" "%SCRIPT_DEST%" >nul
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao copiar update-wallpaper.ps1
    pause
    exit /b 1
)
echo     OK: %SCRIPT_DEST%

:: ─── Registra Run Key no HKLM ────────────────────────────────────────────────
echo [3/3] Registrando execucao automatica no logon (HKLM Run)...

set "RUN_CMD=powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT_DEST%\""
reg add "%REG_KEY%" /v "%REG_NAME%" /t REG_SZ /d "%RUN_CMD%" /f >nul 2>&1

if %errorlevel% neq 0 (
    echo [ERRO] Falha ao registrar Run Key.
    pause
    exit /b 1
)
echo     OK: HKLM\...\Run\ZyllenWallpaper

:: ─── Executa agora para aplicar imediatamente ────────────────────────────────
echo.
echo Aplicando wallpaper agora...
powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_DEST%"
if %errorlevel% equ 0 (
    echo     OK: Wallpaper aplicado!
) else (
    echo     AVISO: Falha ao aplicar agora (sem internet?). Sera aplicado no proximo logon.
)

:: ─── Resumo ──────────────────────────────────────────────────────────────────
echo.
echo  ============================================
echo    Instalacao concluida!
echo.
echo    Script : %SCRIPT_DEST%
echo    Logon  : HKLM Run (todos os usuarios)
echo    Log    : %DEST%\log.txt
echo.
echo    O wallpaper sera atualizado automaticamente
echo    toda vez que qualquer usuario fizer login.
echo  ============================================
echo.
pause
