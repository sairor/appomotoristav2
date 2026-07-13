$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:3000/")
$logPath = "C:\Users\sairo\.gemini\antigravity\scratch\appomotoristav2\server_log.txt"

# Limpar log anterior
if (Test-Path $logPath) { Remove-Item $logPath }

function Log-Request($msg) {
    $time = Get-Date -Format "HH:mm:ss"
    Add-Content -Path $logPath -Value "[$time] $msg"
    Write-Host "[$time] $msg"
}

try {
    $listener.Start()
    Log-Request "Servidor HTTP rodando em http://localhost:3000/"
} catch {
    Log-Request "Falha ao iniciar o listener. Porta 3000 pode estar em uso: $_"
    exit
}

$outputDir = "C:\Users\sairo\.gemini\antigravity\scratch\appomotoristav2"

while ($listener.IsListening) {
    $context = $null
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $urlPath = $request.Url.LocalPath
        Log-Request "Request: $($request.HttpMethod) $($urlPath)"
        
        if ($urlPath -eq "/") {
            $urlPath = "/index.html"
        }
        
        $filePath = Join-Path $outputDir $urlPath.Replace("/", "\").TrimStart("\")
        
        if (Test-Path $filePath -PathType Leaf) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = switch ($ext) {
                ".html" { "text/html; charset=utf-8" }
                ".css"  { "text/css; charset=utf-8" }
                ".js"   { "application/javascript; charset=utf-8" }
                ".png"  { "image/png" }
                ".webp" { "image/webp" }
                ".svg"  { "image/svg+xml" }
                ".json" { "application/json; charset=utf-8" }
                default { "application/octet-stream" }
            }
            
            $response.ContentType = $contentType
            $response.ContentLength64 = $bytes.Length
            $response.Headers.Add("Access-Control-Allow-Origin", "*")
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            Log-Request "200 OK: $filePath ($($bytes.Length) bytes) - ContentType: $contentType"
        } else {
            $response.StatusCode = 404
            $errBytes = [System.Text.Encoding]::UTF8.GetBytes("404 - Arquivo nao encontrado: $urlPath")
            $response.ContentType = "text/plain; charset=utf-8"
            $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
            Log-Request "404 Not Found: $filePath"
        }
    } catch {
        Log-Request "Erro ao processar request: $_"
    } finally {
        if ($context -ne $null) {
            try {
                $context.Response.Close()
            } catch {
                # Ignorar erros ao fechar a conexão
            }
        }
    }
}
