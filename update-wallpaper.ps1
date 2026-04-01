# update-wallpaper.ps1
# Zyllen Wallpaper Updater
# Roda todo dia às 08:00 via Task Scheduler
# Versão: 1.0

$BaseDir    = "C:\ProgramData\ZyllenWallpaper"
$LogFile    = "$BaseDir\log.txt"
$CurrentFile = "$BaseDir\current.txt"
$WallpaperDir = "$BaseDir\wallpapers"
$BaseURL    = "https://raw.githubusercontent.com/Zyllen-ai/zyllen-wallpaper/main/"
$ManifestURL = "${BaseURL}manifest.json"
$MaxLogLines = 100

# ─── Helpers ────────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $line -Encoding UTF8

    # Mantém apenas as últimas $MaxLogLines linhas
    if (Test-Path $LogFile) {
        $lines = Get-Content $LogFile
        if ($lines.Count -gt $MaxLogLines) {
            $lines | Select-Object -Last $MaxLogLines | Set-Content $LogFile -Encoding UTF8
        }
    }
}

function Set-Wallpaper {
    param([string]$ImagePath)

    $code = @"
using System;
using System.Runtime.InteropServices;

public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    public const int SPI_SETDESKWALLPAPER = 20;
    public const int SPIF_UPDATEINIFILE   = 0x01;
    public const int SPIF_SENDCHANGE      = 0x02;

    public static void Set(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path,
            SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
"@

    # Compila apenas se o tipo ainda não existe na sessão
    if (-not ([System.Management.Automation.PSTypeName]'Wallpaper').Type) {
        Add-Type -TypeDefinition $code
    }

    # Aplica via Win32 API
    [Wallpaper]::Set($ImagePath)

    # Persiste no registry (garante que sobrevive a logoff/logon)
    $regPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $regPath -Name Wallpaper        -Value $ImagePath
    Set-ItemProperty -Path $regPath -Name WallpaperStyle   -Value "10"   # Fill
    Set-ItemProperty -Path $regPath -Name TileWallpaper    -Value "0"
}

# ─── Main ────────────────────────────────────────────────────────────────────

Write-Log "=== Iniciando verificação de wallpaper ==="

# Garante diretórios
foreach ($dir in @($BaseDir, $WallpaperDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# 1. Baixa manifest.json
try {
    $response = Invoke-WebRequest -Uri $ManifestURL -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop
    $manifest = $response.Content | ConvertFrom-Json
    $remoteName = $manifest.current
    Write-Log "Manifest lido. Wallpaper remoto: $remoteName"
} catch {
    Write-Log "ERRO ao baixar manifest: $_" "ERROR"
    exit 1
}

# 2. Verifica wallpaper atual
$currentName = ""
if (Test-Path $CurrentFile) {
    $currentName = (Get-Content $CurrentFile -Raw).Trim()
}
Write-Log "Wallpaper atual: $(if ($currentName) { $currentName } else { '(nenhum)' })"

# 3. Compara — se igual, nada a fazer
if ($currentName -eq $remoteName) {
    Write-Log "Wallpaper já está atualizado. Nenhuma ação necessária."
    exit 0
}

# 4. Baixa novo wallpaper
$imageURL  = "${BaseURL}${remoteName}"
$localPath = "$WallpaperDir\$remoteName"

Write-Log "Baixando: $imageURL"
try {
    Invoke-WebRequest -Uri $imageURL -OutFile $localPath -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
    Write-Log "Download concluído: $localPath"
} catch {
    Write-Log "ERRO ao baixar imagem: $_" "ERROR"
    exit 1
}

# 5. Aplica wallpaper
try {
    Set-Wallpaper -ImagePath $localPath
    Write-Log "Wallpaper aplicado: $localPath"
} catch {
    Write-Log "ERRO ao aplicar wallpaper: $_" "ERROR"
    exit 1
}

# 6. Atualiza registro local
Set-Content -Path $CurrentFile -Value $remoteName -Encoding UTF8
Write-Log "Estado salvo em current.txt: $remoteName"
Write-Log "=== Concluído com sucesso ==="
