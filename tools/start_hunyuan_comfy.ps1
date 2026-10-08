param([int]$Port = 8189)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$pythonPath = Join-Path $projectRoot '.tools\hunyuan-env\Scripts\python.exe'
$comfyPath = Join-Path $projectRoot '.tools\comfy-hunyuan'
$sessionPath = Join-Path $projectRoot '.tools\hunyuan-session'
New-Item -ItemType Directory -Force $sessionPath | Out-Null
if (-not (Test-Path -LiteralPath $pythonPath)) { throw 'Hunyuan environment is missing' }
$env:HF_HOME = Join-Path $projectRoot '.tools\hunyuan-hf'
$env:TORCH_HOME = Join-Path $projectRoot '.tools\hunyuan-torch'
$env:U2NET_HOME = Join-Path $projectRoot '.tools\hunyuan-rembg'
$env:NUMBA_CACHE_DIR = Join-Path $projectRoot '.tools\hunyuan-numba'
$env:MPLCONFIGDIR = Join-Path $projectRoot '.tools\hunyuan-matplotlib'
$env:HF_HUB_DISABLE_SYMLINKS_WARNING = '1'
$env:PYTHONNOUSERSITE = '1'
$stdout = Join-Path $sessionPath 'stdout.log'
$stderr = Join-Path $sessionPath 'stderr.log'
try {
    $existing = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/system_stats" -TimeoutSec 2
    if ($existing.system.python_version) { throw "Port $Port is already serving ComfyUI; inspect it before starting a second process" }
} catch {
    if ($_.Exception.Message -match 'already serving') { throw }
}
$process = Start-Process -FilePath $pythonPath -ArgumentList @(
    '-u', (Join-Path $comfyPath 'main.py'), '--listen','127.0.0.1',
    '--port', $Port, '--disable-auto-launch', '--disable-xformers',
    '--use-pytorch-cross-attention'
) -WorkingDirectory $comfyPath -RedirectStandardOutput $stdout -RedirectStandardError $stderr -WindowStyle Hidden -PassThru
$record = @{ pid=$process.Id; port=$Port; python=$pythonPath; comfy=$comfyPath; stdout=$stdout; stderr=$stderr }
$record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $sessionPath 'service.json')
$record | ConvertTo-Json
