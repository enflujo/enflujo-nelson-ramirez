param([string]$nombre)

if (-not $nombre -or $nombre.Trim() -eq "") {
    $fechaAhora = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $nombre = "captura_$fechaAhora"
}

$archivoSalida = "$nombre.mkv"

Write-Host "Grabando a archivo: $archivoSalida"
Start-Sleep -Milliseconds 500

ffmpeg -f dshow -i video="AV TO USB2.0":audio="Micrófono (USB2.0 MIC)" `
-filter_complex "[0:v]scale=in_color_matrix=bt601:out_color_matrix=bt601,split=2[out1][out2]" `
-map "[out1]" -map 0:a -map "[out2]" `
-c:v ffv1 -level 3 -g 1 -coder 1 -context 1 -pix_fmt yuv422p `
-c:a pcm_s16le `
-f tee "[f=matroska]$archivoSalida|[f=nut]pipe:1" | ffplay -
