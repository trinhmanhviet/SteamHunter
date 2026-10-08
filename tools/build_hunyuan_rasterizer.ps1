$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$wrapper = Join-Path $projectRoot '.tools\comfy-hunyuan\custom_nodes\ComfyUI-Hunyuan3DWrapper'
$source = Join-Path $wrapper 'hy3dgen\texgen\custom_rasterizer'
$setup = Join-Path $source 'setup.py'
$content = Get-Content -LiteralPath $setup -Raw
if ($content -notmatch 'allow-unsupported-compiler') {
    $content = $content.Replace("nvcc_args = []", "nvcc_args = ['-allow-unsupported-compiler', '-D_ALLOW_COMPILER_AND_STL_VERSION_MISMATCH']")
    [IO.File]::WriteAllText($setup, $content)
}
$patchDir = Join-Path $projectRoot 'prototypes\hunyuan_hunter\patches'
New-Item -ItemType Directory -Force $patchDir | Out-Null
git -C $wrapper diff -- hy3dgen/texgen/custom_rasterizer/setup.py | Set-Content -LiteralPath (Join-Path $patchDir 'rasterizer_build.patch')
$batch = Join-Path $projectRoot '.tools\hunyuan-rasterizer-build.cmd'
$python = Join-Path $projectRoot '.tools\hunyuan-env\Scripts\python.exe'
$commands = @(
    '@echo off',
    'call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"',
    'if errorlevel 1 exit /b 1',
    'set "CUDA_HOME=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.4"',
    'set "TORCH_CUDA_ARCH_LIST=8.6"',
    'set "MAX_JOBS=2"',
    'set "DISTUTILS_USE_SDK=1"',
    ('cd /d "' + $source + '"'),
    ('"' + $python + '" setup.py bdist_wheel'),
    'exit /b %errorlevel%'
)
$commands | Set-Content -LiteralPath $batch
cmd.exe /c $batch
if ($LASTEXITCODE -ne 0) { throw 'Rasterizer compilation failed' }
$wheel = Get-ChildItem -LiteralPath (Join-Path $source 'dist') -Filter '*.whl' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$env:UV_CACHE_DIR = Join-Path $projectRoot '.tools\uv-cache'
uv pip install --python $python --force-reinstall --no-deps $wheel.FullName
if ($LASTEXITCODE -ne 0) { throw 'Rasterizer installation failed' }
Write-Output "RASTERIZER_BUILT_FOR_SM86 $($wheel.FullName)"
