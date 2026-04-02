# update-wallpaper.ps1
# Zyllen Wallpaper Updater v3.0
# Blindado para Windows 7/8/10/11 PT-BR e EN

$BaseDir      = "C:\ProgramData\ZyllenWallpaper"
$LogFile      = "$BaseDir\log.txt"
$CurrentFile  = "$BaseDir\current.txt"
$WallpaperDir = "$BaseDir\wallpapers"
$BaseURL      = "https://raw.githubusercontent.com/Zyllen-ai/zyllen-wallpaper/main/"
$ManifestURL  = "${BaseURL}manifest.json"
$MaxLogLines  = 200

# ─── Aguarda desktop carregar (critico em logon via HKLM Run) ───────────────
Start-Sleep -Seconds 10

# ─── Helpers ─────────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"
    try {
        Add-Content -Path $LogFile -Value $line -Encoding UTF8 -ErrorAction Stop
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

    [ZyllenWallpaper]::Set($ImagePath)

    # Persiste no registry HKCU do usuario atual
    try {
        $regPath = "HKCU:\Control Panel\Desktop"
        Set-ItemProperty -Path $regPath -Name Wallpaper      -Value $ImagePath
        Set-ItemProperty -Path $regPath -Name WallpaperStyle -Value "10"
        Set-ItemProperty -Path $regPath -Name TileWallpaper  -Value "0"
    } catch { }
}

function Remove-SafeFile {
    param([string]$Path)
    if (Test-Path $Path) {
        try {
            Remove-Item $Path -Force -ErrorAction Stop
        } catch {
            # Tenta takeown via cmd se remocao falhar
            $null = & cmd /c "takeown /F `"$Path`" /A >nul 2>&1 && icacls `"$Path`" /grant *S-1-1-0:(F) >nul 2>&1"
            Start-Sleep -Seconds 1
            Remove-Item $Path -Force -ErrorAction SilentlyContinue
        }
    }
}

# ─── Garante diretorios ───────────────────────────────────────────────────────
foreach ($dir in @($BaseDir, $WallpaperDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# ─── Info de diagnostico ─────────────────────────────────────────────────────
$osInfo = (Get-WmiObject Win32_OperatingSystem).Caption
$psVer  = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
Write-Log "=== Iniciando (usuario: $env:USERNAME | OS: $osInfo | PS: $psVer) ==="

# ─── Baixa manifest ──────────────────────────────────────────────────────────
try {
    $response = Invoke-WebRequest -Uri $ManifestURL -UseBasicParsing -TimeoutSec 20 -ErrorAction Stop
    # Strip BOM (previne erro de parse JSON)
    $content = $response.Content -replace '^\xEF\xBB\xBF', '' -replace '^\xFE\xFF', '' -replace '^\xFF\xFE', ''
    $content = $content.TrimStart([char]0xFEFF)
    $manifest = $content | ConvertFrom-Json
    $remoteName = $manifest.current
    Write-Log "Manifest lido. Wallpaper remoto: $remoteName"
} catch {
    Write-Log "Sem internet ou erro ao baixar manifest: $_" "WARN"
    # Sem internet: tenta reaplicar wallpaper local
    if (Test-Path $CurrentFile) {
        $currentName = (Get-Content $CurrentFile -Raw -ErrorAction SilentlyContinue).Trim()
        if ($currentName) {
            $localPath = "$WallpaperDir\$currentName"
            if (Test-Path $localPath) {
                Write-Log "Reaplicando wallpaper local: $currentName"
                try { Set-Wallpaper -ImagePath $localPath; Write-Log "Wallpaper local aplicado." }
                catch { Write-Log "Erro ao aplicar local: $_" "ERROR" }
            }
        }
    }
    exit 0
}

# ─── Compara com atual ────────────────────────────────────────────────────────
$currentName = ""
if (Test-Path $CurrentFile) {
    $currentName = (Get-Content $CurrentFile -Raw -ErrorAction SilentlyContinue).Trim()
}
Write-Log "Wallpaper atual: $(if ($currentName) { $currentName } else { '(nenhum)' })"

$localPath = "$WallpaperDir\$remoteName"

# Se ja e o mesmo e arquivo existe, so reaplicar
if ($currentName -eq $remoteName -and (Test-Path $localPath)) {
    Write-Log "Ja atualizado. Reaplicando para garantir..."
    try { Set-Wallpaper -ImagePath $localPath; Write-Log "Reaplicado com sucesso." }
    catch { Write-Log "Erro ao reaplicar: $_" "ERROR" }
    exit 0
}

# ─── Remove arquivo local se existir (evita erro de permissao) ───────────────
if (Test-Path $localPath) {
    Write-Log "Removendo versao anterior: $remoteName"
    Remove-SafeFile -Path $localPath
}

# ─── Baixa nova imagem ────────────────────────────────────────────────────────
$imageURL = "${BaseURL}${remoteName}"
Write-Log "Baixando: $imageURL"
try {
    Invoke-WebRequest -Uri $imageURL -OutFile $localPath -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
    Write-Log "Download concluido: $localPath"
} catch {
    Write-Log "Erro ao baixar imagem: $_" "ERROR"
    exit 1
}

# ─── Aplica wallpaper ─────────────────────────────────────────────────────────
try {
    Set-Wallpaper -ImagePath $localPath
    Write-Log "Wallpaper aplicado: $localPath"
} catch {
    Write-Log "Erro ao aplicar wallpaper: $_" "ERROR"
    exit 1
}

# ─── Salva estado ─────────────────────────────────────────────────────────────
try {
    Set-Content -Path $CurrentFile -Value $remoteName -Encoding UTF8 -Force
    Write-Log "Estado salvo: $remoteName"
} catch {
    Write-Log "Aviso: nao foi possivel salvar current.txt: $_" "WARN"
}

Write-Log "=== Concluido com sucesso ==="
