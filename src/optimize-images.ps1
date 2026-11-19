# MSroofing – zmenšení fotek pro web
# Vstup:  src\_originals\<původní název>   Výstup: msroofing\assets\img\<slug>-<šířka>.jpg
# Použití: powershell -ExecutionPolicy Bypass -File src\optimize-images.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$src = $PSScriptRoot
$in = Join-Path $src '_originals'
$out = Join-Path (Split-Path $src -Parent) 'msroofing\assets\img'
New-Item -ItemType Directory -Force -Path $out | Out-Null
$site = [IO.File]::ReadAllText((Join-Path $src 'content\site.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json

$codec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$ep = New-Object Drawing.Imaging.EncoderParameters(1)
$ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter([Drawing.Imaging.Encoder]::Quality, [long]78)

function Fix-Orientation($img) {
  if ($img.PropertyIdList -contains 0x0112) {
    $o = $img.GetPropertyItem(0x0112).Value[0]
    switch ($o) {
      3 { $img.RotateFlip([Drawing.RotateFlipType]::Rotate180FlipNone) }
      6 { $img.RotateFlip([Drawing.RotateFlipType]::Rotate90FlipNone) }
      8 { $img.RotateFlip([Drawing.RotateFlipType]::Rotate270FlipNone) }
    }
  }
}

$total0 = 0; $total1 = 0
foreach ($p in $site.images.PSObject.Properties) {
  $file = Join-Path $in $p.Name
  if (-not (Test-Path $file)) { Write-Warning "Chybí $($p.Name)"; continue }
  $total0 += (Get-Item $file).Length
  $img = [Drawing.Image]::FromFile($file)
  Fix-Orientation $img
  $targets = $site.sizes
  if ($p.Name -eq 'logo.jpg') { $targets = @(400) }
  foreach ($w in $targets) {
    $nw = [Math]::Min($w, $img.Width)
    $nh = [int][Math]::Round($img.Height * $nw / $img.Width)
    $bmp = New-Object Drawing.Bitmap($nw, $nh)
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [Drawing.Drawing2D.CompositingQuality]::HighQuality
    $g.Clear([Drawing.Color]::White)
    $g.DrawImage($img, 0, 0, $nw, $nh)
    $dest = Join-Path $out "$($p.Value)-$w.jpg"
    $q = 78; if ($w -ge 1600) { $q = 70 }
    $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter([Drawing.Imaging.Encoder]::Quality, [long]$q)
    $bmp.Save($dest, $codec, $ep)
    $g.Dispose(); $bmp.Dispose()
    $total1 += (Get-Item $dest).Length
  }
  $img.Dispose()
}
Write-Host ("Hotovo: originály {0:N1} MB -> všechny velikosti dohromady {1:N1} MB" -f ($total0 / 1MB), ($total1 / 1MB))
