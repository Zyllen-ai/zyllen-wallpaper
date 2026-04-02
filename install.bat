@echo off
:: install.bat - Zyllen Wallpaper Installer
:: Versao: 3.0 - Blindado para Windows 7/8/10/11 PT-BR e EN

:: ─── Auto-elevacao ───────────────────────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Solicitando permissao de Administrador...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

setlocal EnableDelayedExpansion
title Zyllen Wallpaper - Instalacao v3.0
color 0A

echo.
echo  ============================================
echo    Zyllen Wallpaper - Instalador v3.0
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
    echo Certifique-se que install.bat e update-wallpaper.ps1 estao na mesma pasta.
    pause
    exit /b 1
)

:: ─── Cria diretorios ─────────────────────────────────────────────────────────
echo [1/4] Criando diretorios...
if not exist "%DEST%" mkdir "%DEST%"
if not exist "%DEST%\wallpapers" mkdir "%DEST%\wallpapers"
echo     OK

:: ─── Permissoes usando SID (funciona em qualquer idioma) ────────────────────
echo [2/4] Configurando permissoes...

:: Toma posse da pasta inteira
takeown /F "%DEST%" /R /D S >nul 2>&1

:: SID S-1-1-0 = Everyone/Todos (universal, qualquer idioma)
icacls "%DEST%" /grant "*S-1-1-0:(OI)(CI)F" /T /C >nul 2>&1
:: SID S-1-5-32-545 = Users/Usuarios (universal)
icacls "%DEST%" /grant "*S-1-5-32-545:(OI)(CI)F" /T /C >nul 2>&1
:: SID S-1-5-32-544 = Administrators (universal)  
icacls "%DEST%" /grant "*S-1-5-32-544:(OI)(CI)F" /T /C >nul 2>&1

:: Cria arquivos de estado com permissao garantida
if not exist "%DEST%\current.txt" (
    echo.> "%DEST%\current.txt"
)
if not exist "%DEST%\log.txt" (
    echo.> "%DEST%\log.txt"
)

:: Permissao explicita nos arquivos de estado
takeown /F "%DEST%\current.txt" >nul 2>&1
takeown /F "%DEST%\log.txt" >nul 2>&1
icacls "%DEST%\current.txt" /grant "*S-1-1-0:(F)" /C >nul 2>&1
icacls "%DEST%\log.txt" /grant "*S-1-1-0:(F)" /C >nul 2>&1
icacls "%DEST%\wallpapers" /grant "*S-1-1-0:(OI)(CI)F" /T /C >nul 2>&1

echo     OK

:: ─── Copia script ────────────────────────────────────────────────────────────
echo [3/4] Copiando script...
copy /Y "%SCRIPT_SRC%" "%SCRIPT_DEST%" >nul
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao copiar update-wallpaper.ps1
    pause
    exit /b 1
)
:: Permissao de leitura/execucao no script
icacls "%SCRIPT_DEST%" /grant "*S-1-1-0:(RX)" /C >nul 2>&1
echo     OK: %SCRIPT_DEST%

:: ─── Registra Run Key no HKLM ────────────────────────────────────────────────
echo [4/4] Registrando execucao automatica (HKLM Run)...

:: Remove entrada antiga se existir
reg delete "%REG_KEY%" /v "%REG_NAME%" /f >nul 2>&1

:: Registra com caminho sem espacos problematicos
reg add "%REG_KEY%" /v "%REG_NAME%" /t REG_SZ /d "powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File \"%SCRIPT_DEST%\"" /f >nul 2>&1

if %errorlevel% neq 0 (
    echo [ERRO] Falha ao registrar Run Key.
    pause
    exit /b 1
)
echo     OK: HKLM\...\Run\ZyllenWallpaper

:: ─── Executa agora para aplicar imediatamente ────────────────────────────────
echo.
echo Aplicando wallpaper agora (pode demorar alguns segundos)...
powershell.exe -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "%SCRIPT_DEST%"
if %errorlevel% equ 0 (
    echo     OK: Wallpaper aplicado!
) else (
    echo     AVISO: Nao foi possivel aplicar agora. Sera aplicado no proximo logon.
)

:: ─── Resumo ──────────────────────────────────────────────────────────────────
echo.
echo  ============================================
echo    Instalacao concluida com sucesso!
echo.
echo    Script : %SCRIPT_DEST%
echo    Logon  : HKLM Run (todos os usuarios)
echo    Log    : %DEST%\log.txt
echo.
echo    Wallpaper atualiza automaticamente a cada
echo    logon de qualquer usuario.
echo  ============================================
echo.
pause
