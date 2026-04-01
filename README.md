# Zyllen Wallpaper Distribution System

Sistema de distribuição automática de wallpaper para múltiplas máquinas Windows via GitHub.

---

## Como funciona

1. O wallpaper atual é definido no arquivo `manifest.json` deste repositório.
2. Cada máquina instalada verifica o manifest todo dia às **08:00**.
3. Se o wallpaper mudou, ela baixa o novo arquivo e aplica automaticamente.
4. Silencioso — sem janelas popup, sem interação do usuário.

---

## Instalação nas máquinas (via pendrive)

### Arquivos necessários no pendrive
```
📁 pendrive/
  ├── install.bat
  └── update-wallpaper.ps1
```

### Passos
1. Copie `install.bat` e `update-wallpaper.ps1` para o pendrive.
2. Na máquina cliente, conecte o pendrive.
3. Clique com o botão direito em `install.bat` → **Executar como Administrador**.
4. Aguarde a mensagem de sucesso.

O instalador vai:
- Criar `C:\ProgramData\ZyllenWallpaper\`
- Copiar o script para lá
- Criar a tarefa agendada `ZyllenWallpaper` (diária às 08:00)
- Aplicar o wallpaper imediatamente

---

## Como trocar o wallpaper

### 1. Suba a nova imagem para este repositório
- Formatos suportados: `.jpg`, `.png`, `.bmp`
- Recomendado: resolução **1920×1080** ou superior
- Nome sugerido: `YYYY-MM.jpg` (ex: `2026-05.jpg`)

### 2. Atualize o `manifest.json`
```json
{
  "current": "2026-05.jpg"
}
```

### 3. Faça commit e push
```bash
git add 2026-05.jpg manifest.json
git commit -m "Wallpaper maio 2026"
git push
```

Na manhã seguinte (08:00), todas as máquinas aplicarão o novo wallpaper automaticamente.

---

## Estrutura do repositório
```
📁 zyllen-wallpaper/
  ├── manifest.json          ← Define qual wallpaper está ativo
  ├── install.bat            ← Instalador (roda no pendrive)
  ├── update-wallpaper.ps1   ← Agente diário de atualização
  ├── uninstall.bat          ← Desinstalador
  ├── README.md              ← Este arquivo
  └── 2026-04.jpg            ← Imagens dos wallpapers
```

---

## Estrutura do manifest.json
```json
{
  "current": "nome-do-arquivo.jpg"
}
```
| Campo | Tipo | Descrição |
|-------|------|-----------|
| `current` | string | Nome exato do arquivo de imagem no repositório |

---

## Diagnóstico / Logs

Log de execução em cada máquina:
```
C:\ProgramData\ZyllenWallpaper\log.txt
```

Wallpaper atualmente instalado:
```
C:\ProgramData\ZyllenWallpaper\current.txt
```

### Verificar tarefa agendada (PowerShell)
```powershell
Get-ScheduledTask -TaskName "ZyllenWallpaper"
```

### Forçar execução manual (PowerShell como Admin)
```powershell
Start-ScheduledTask -TaskName "ZyllenWallpaper"
```

---

## Desinstalação

Execute `uninstall.bat` como Administrador na máquina cliente.

---

## Requisitos
- Windows 10 ou superior
- PowerShell 5.1+
- Acesso à internet (porta 443 — GitHub raw content)
- Sem conta GitHub necessária nas máquinas clientes
