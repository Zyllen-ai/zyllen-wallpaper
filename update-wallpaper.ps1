# update-wallpaper.ps1
# Zyllen Wallpaper Updater v2.0
# Roda no logon via HKLM Run key (para todos os usuarios)

$BaseDir      = "C:\ProgramData\ZyllenWallpaper"
$LogFile      = "$BaseDir\log.txt"
$CurrentFile  = "$BaseDir\current.txt"
$WallpaperDir = "$BaseDir\wallpapers"
$BaseURL      = "https://raw.githubusercontent.com/Zyllen-ai/zyllen-wallpaper/main/"
$ManifestURL  = "${BaseURL}manifest.json"
$MaxLogLines  = 100

# ─── Helpers ────────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop
        # Mantém apenas as últimas $MaxLogLines linhas
        $lines = Get-Content $LogFile -ErrorAction SilentlyContinue
        if ($lines -and $lines.Count -gt $MaxLogLines) {
            $lines | Select-Object -Last $MaxLogLines | Set-Content $LogFile -Encoding UTF8
        }
    } catch { }
}

function Set-Wallpaper {
    param([string]$ImagePath)

    $code = @"
using System;
using System.Runtime.InteropServices;
public class ZyllenWallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    public const int SPI_SETDESKWALLPAPER = 20;
    public const int SPIF_UPDATEINIFILE   = 0x01;
    public const int SPIF_SENDCHANGE      = 0x02;
    public static void Set(string path) {
        SystemParametersInfo(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }
}
"@
    if (-not ([System.Management.Automation.PSTypeName]'ZyllenWallpaper').Type) {
        Add-Type -TypeDefinition $code
    }

    # Aplica via Win32 API
    [ZyllenWallpaper]::Set($ImagePath)

    # Persiste no registry do usuário atual
    $regPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $regPath -Name Wallpaper      -Value $ImagePath
    Set-ItemProperty -Path $regPath -Name WallpaperStyle -Value "10"  # Fill
    Set-ItemProperty -Path $regPath -Name TileWallpaper  -Value "0"
}

# ─── Main ────────────────────────────────────────────────────────────────────

# Garante diretórios
foreach ($dir in @($BaseDir, $WallpaperDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

Write-Log "=== Iniciando verificacao de wallpaper (usuario: $env:USERNAME) ==="

# 1. Baixa manifest.json
try {
    $response = Invoke-WebRequest -Uri $ManifestURL -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
    $content = $response.Content.TrimStart([char]0xEF, [char]0xBB, [char]0xBF, [char]0xFEFF)
    $manifest = $content | ConvertFrom-Json
    $remoteName = $manifest.current
    Write-Log "Manifest lido. Wallpaper remoto: $remoteName"
} catch {
    Write-Log "Sem internet ou erro ao baixar manifest: $_" "WARN"
    # Sem internet: tenta aplicar o wallpaper atual se já existir local
    if (Test-Path $CurrentFile) {
        $currentName = (Get-Content $CurrentFile -Raw).Trim()
        $localPath = "$WallpaperDir\$currentName"
        if (Test-Path $localPath) {
            Write-Log "Aplicando wallpaper local existente: $currentName"
            try {
                Set-Wallpaper -ImagePath $localPath
                Write-Log "Wallpaper local aplicado com sucesso."
            } catch {
                Write-Log "Erro ao aplicar wallpaper local: $_" "ERROR"
            }
        }
    }
    exit 0
}

# 2. Verifica wallpaper atual
$currentName = ""
if (Test-Path $CurrentFile) {
    $currentName = (Get-Content $CurrentFile -Raw).Trim()
}
Write-Log "Wallpaper atual: $(if ($currentName) { $currentName } else { '(nenhum)' })"

# 3. Se igual, só reaplicar (garante que não foi resetado por outro software)
$localPath = "$WallpaperDir\$remoteName"
if ($currentName -eq $remoteName -and (Test-Path $localPath)) {
    Write-Log "Wallpaper ja atualizado. Reaplicando para garantir..."
    try {
        Set-Wallpaper -ImagePath $localPath
        Write-Log "Reaplicado com sucesso."
    } catch {
        Write-Log "Erro ao reaplicar: $_" "ERROR"
    }
    exit 0
}

# 4. Baixa novo wallpaper
$imageURL = "${BaseURL}${remoteName}"
Write-Log "Baixando novo wallpaper: $imageURL"
try {
    Invoke-WebRequest -Uri $imageURL -OutFile $localPath -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
    Write-Log "Download concluido: $localPath"
} catch {
    Write-Log "Erro ao baixar imagem: $_" "ERROR"
    exit 1
}

# 5. Aplica wallpaper
try {
    Set-Wallpaper -ImagePath $localPath
    Write-Log "Wallpaper aplicado: $localPath"
} catch {
    Write-Log "Erro ao aplicar wallpaper: $_" "ERROR"
    exit 1
}

# 6. Salva estado
Set-Content -Path $CurrentFile -Value $remoteName -Encoding UTF8
Write-Log "Estado salvo: $remoteName"
Write-Log "=== Concluido com sucesso ==="
