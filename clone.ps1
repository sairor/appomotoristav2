$baseUrl = "https://app.Direção Certa.com"
$outputDir = "C:\Users\sairo\.gemini\antigravity\scratch\Direção Certa-clone"

# Garantir que os diretórios existam
New-Item -ItemType Directory -Force -Path $outputDir
New-Item -ItemType Directory -Force -Path "$outputDir\assets"
New-Item -ItemType Directory -Force -Path "$outputDir\img"

$files = @(
    "/index.html",
    "/manifest.json",
    "/assets/index-BPCPb1Jt.js",
    "/assets/jsx-runtime-B6wIE3fT.js",
    "/assets/index-DSshgIPB.css",
    "/img/favicon.svg",
    "/img/icon-192.png",
    "/img/icon-512.png",
    "/img/logo.png",
    "/img/uber.webp",
    "/img/99.webp",
    "/img/ifood.webp",
    "/img/rappi.webp"
)

# Download dos arquivos iniciais mapeados
foreach ($file in $files) {
    $url = $baseUrl + $file
    $localPath = Join-Path $outputDir $file.Replace("/", "\")
    $localFileDir = Split-Path $localPath -Parent
    if (!(Test-Path $localFileDir)) {
        New-Item -ItemType Directory -Force -Path $localFileDir | Out-Null
    }
    Write-Host "Baixando $url para $localPath..."
    try {
        Invoke-WebRequest -Uri $url -OutFile $localPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -TimeoutSec 15
    } catch {
        Write-Warning "Falha ao baixar $($url): $_"
    }
}

# Procurar assets adicionais no arquivo JavaScript principal
$jsPath = "$outputDir\assets\index-BPCPb1Jt.js"
if (Test-Path $jsPath) {
    Write-Host "Analisando JS principal para encontrar mais assets..."
    $content = Get-Content -Raw -Path $jsPath
    
    # Regex simples para buscar caminhos de assets ou imagens comuns
    $matches = [regex]::Matches($content, '(?:"|'')(/assets/[^"''\s]+|/img/[^"''\s]+)(?:"|'')')
    $extraAssets = @()
    foreach ($match in $matches) {
        $path = $match.Groups[1].Value
        # Filtrar caminhos que não pareçam arquivos estáticos válidos (ex: sem extensão ou contendo caracteres inválidos)
        if ($path -match "\.[a-zA-Z0-9]+$") {
            if ($files -notcontains $path -and $extraAssets -notcontains $path) {
                $extraAssets += $path
            }
        }
    }
    
    Write-Host "Encontrados $($extraAssets.Count) assets adicionais."
    foreach ($file in $extraAssets) {
        $url = $baseUrl + $file
        $localPath = Join-Path $outputDir $file.Replace("/", "\")
        $localFileDir = Split-Path $localPath -Parent
        if (!(Test-Path $localFileDir)) {
            New-Item -ItemType Directory -Force -Path $localFileDir | Out-Null
        }
        Write-Host "Baixando asset extra $url para $localPath..."
        try {
            Invoke-WebRequest -Uri $url -OutFile $localPath -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -TimeoutSec 15
        } catch {
            Write-Warning "Falha ao baixar asset extra $($url): $_"
        }
    }
}

Write-Host "Clonagem concluída!"
