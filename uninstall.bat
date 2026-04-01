@echo off
:: uninstall.bat - Zyllen Wallpaper Uninstaller
:: Versão: 1.0

setlocal
title Zyllen Wallpaper - Desinstalação

echo ============================================
echo   Zyllen Wallpaper - Desinstalador v1.0
echo ============================================
echo.

set "DEST=C:\ProgramData\ZyllenWallpaper"
set "TASK_NAME=ZyllenWallpaper"

:: ─── Remove tarefa agendada ──────────────────────────────────────────────
echo [1/2] Removendo tarefa agendada "%TASK_NAME%"...
schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1
if %errorlevel% equ 0 (
    echo     OK: Tarefa removida
) else (
    echo     INFO: Tarefa nao encontrada (pode ja ter sido removida)
)

:: ─── Remove arquivos ─────────────────────────────────────────────────────
echo [2/2] Removendo arquivos de "%DEST%"...
if exist "%DEST%" (
    rmdir /S /Q "%DEST%"
    if %errorlevel% equ 0 (
        echo     OK: Arquivos removidos
    ) else (
        echo     [ERRO] Nao foi possivel remover todos os arquivos.
        echo            Tente fechar programas que usem a pasta e repita.
    )
) else (
    echo     INFO: Pasta nao encontrada (ja desinstalado?)
)

echo.
echo ============================================
echo   Desinstalacao concluida!
echo ============================================
echo.
pause
