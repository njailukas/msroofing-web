param([int]$Port = 8765, [string]$Root = (Join-Path $PSScriptRoot 'msroofing'))
$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
Write-Host "Serving $Root on http://localhost:$Port/"
$types = @{'.html'='text/html; charset=utf-8';'.js'='application/javascript; charset=utf-8';'.css'='text/css; charset=utf-8';'.svg'='image/svg+xml';'.xml'='application/xml';'.txt'='text/plain; charset=utf-8';'.png'='image/png';'.jpg'='image/jpeg';'.jpeg'='image/jpeg';'.webp'='image/webp'}
while ($l.IsListening) {
  $c = $l.GetContext()
  $p = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath).TrimStart('/')
  if ($p -eq '' -or $p.EndsWith('/')) { $p += 'index.html' }
  $f = Join-Path $Root $p
  if (Test-Path $f -PathType Leaf) {
    $b = [IO.File]::ReadAllBytes($f)
    $ext = [IO.Path]::GetExtension($f).ToLower()
    $c.Response.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
    $c.Response.Headers.Add('Cache-Control','no-cache')
    $c.Response.OutputStream.Write($b, 0, $b.Length)
  } else { $c.Response.StatusCode = 404 }
  $c.Response.Close()
}
