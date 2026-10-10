# Recorta el borde superior derecho de las imágenes generadas por Copilot
# para ocultar la etiqueta "Made with AI", guardándolas de nuevo con el MISMO
# nombre y en PNG (sin pérdida), para no tener que tocar el HTML.
#
# Uso:
#   powershell -ExecutionPolicy Bypass -File recortar-ia.ps1
#   powershell -ExecutionPolicy Bypass -File recortar-ia.ps1 -Top 14 -Right 16
#
# Parámetros:
#   Top    = píxeles que se recortan del borde superior (sutil, por defecto 10)
#   Right  = píxeles que se recortan del borde derecho  (sutil, por defecto 12)
#   Folder = carpeta de las imágenes (por defecto ./imagenes)
#   Filter = patrón de archivos a procesar (por defecto Copilot_*.png)

param(
  [int]$Top = 10,
  [int]$Right = 12,
  [string]$Folder = (Join-Path $PSScriptRoot "imagenes"),
  [string]$Filter = "Copilot_*.png"
)

Add-Type -AssemblyName System.Drawing

$files = Get-ChildItem -LiteralPath $Folder -Filter $Filter -File
if (-not $files) {
  Write-Output "No hay archivos que coincidan con '$Filter' en '$Folder'."
  exit 0
}

foreach ($f in $files) {
  $path = $f.FullName
  $src = [System.Drawing.Image]::FromFile($path)
  $w = $src.Width
  $h = $src.Height
  $nw = $w - $Right
  $nh = $h - $Top

  if ($nw -lt 1 -or $nh -lt 1) {
    $src.Dispose()
    Write-Warning "Dimensiones insuficientes, se omite: $($f.Name) ($w x $h)"
    continue
  }

  $bmp = New-Object System.Drawing.Bitmap($nw, $nh)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  # Origen: se salta Top píxeles arriba y Right píxeles a la derecha (esquina superior derecha).
  $dstRect = New-Object System.Drawing.Rectangle(0, 0, $nw, $nh)
  $srcRect = New-Object System.Drawing.Rectangle(0, $Top, $nw, $nh)
  $g.DrawImage($src, $dstRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
  $g.Dispose()
  $src.Dispose()

  # Guardado PNG: sin pérdida, reemplaza el original con el mismo nombre.
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()

  Write-Output ("Recortada: {0}  ({1} x {2}  ->  {3} x {4})  -Top {5} -Right {6}" -f $f.Name, $w, $h, $nw, $nh, $Top, $Right)
}

Write-Output "Listo: $($files.Count) imagen(es) procesada(s)."