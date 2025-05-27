param([string]$nombre)

if (-not $nombre -or $nombre.Trim() -eq "") {
    $fechaAhora = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $nombre = "captura_$fechaAhora"
}

$archivoSalida = "$nombre.mkv"

Write-Host "Grabando a archivo: $archivoSalida"
Start-Sleep -Milliseconds 500

ffmpeg -hide_banner -f dshow -use_wallclock_as_timestamps 1 `
-i video="AV TO USB2.0":audio="Micrófono (USB2.0 MIC)" -async 1 `
-filter_complex "[0:v]split=2[v1][v2];[0:a]asplit=2[a1][a2]" `
-map "[v1]" -map "[a1]" `
-c:v ffv1 -level 3 -coder 1 -context 1 -g 1 -slices 4 -slicecrc 1 -pix_fmt yuv422p `
-c:a pcm_s16le `
-f matroska "$archivoSalida" `
-map "[v2]" -map "[a2]" `
-c:v libx264 -preset ultrafast -tune zerolatency -pix_fmt yuv420p `
-c:a mp2 -b:a 192k -ar 48000 -ac 2 `
-f mpegts "udp://127.0.0.1:1234?pkt_size=1316"

<# param([string]$nombre)

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
 #>