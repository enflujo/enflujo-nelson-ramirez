# Archivo de Nelson Ramírez

![Estilo Código](https://github.com/enflujo/enflujo-nelson-ramirez/actions/workflows/estilo-codigo.yml/badge.svg)
![Tamaño](https://img.shields.io/github/repo-size/enflujo/enflujo-nelson-ramirez?color=%235757f7&label=Tama%C3%B1o%20repo&logo=open-access&logoColor=white)
![Licencia](https://img.shields.io/github/license/enflujo/enflujo-nelson-ramirez?label=Licencia&logo=open-source-initiative&logoColor=white)

## Guía de captura y digitalización de video analógico con FFmpeg

## Objetivo

Este es el flujo de trabajo para capturar videos sin pérdidas desde señales de video y audio analógico: VHS, Betamax, Umatic 3/4 y Betacam (u otras fuentes SD). Usamos una capturadora USB, generando archivos de la máxima calidad posible (`.mkv`) aptos para preservación digital.

---

## Requisitos

- **Sistema operativo:** Windows (PowerShell 7 o superior)
- **Software:** [FFmpeg](https://ffmpeg.org/) y `ffplay` instalados y accesibles desde la línea de comandos
- **Dispositivo:** Capturadora USB reconocida como `"AV TO USB2.0"` + entrada de audio `"Micrófono (USB2.0 MIC)"`

---

## Códecs y parámetros utilizados

### Video

- **Códec:** `ffv1` (lossless)
- **PixFmt:** `yuv422p` (espacio de color preferible para SD analógico)
- **Parámetros adicionales:**  
  `-level 3 -g 1 -coder 1 -context 1` → compresión determinista y de alta compatibilidad

### Audio

- **Códec:** `pcm_s16le` (audio sin compresión, 16 bits, estéreo)
- **Frecuencia:** `48000 Hz`

### Corrección de color

- Filtro: `scale=in_color_matrix=bt601:out_color_matrix=bt601`
- Justificación: BT.601 es el estándar de referencia para señales SD analógicas

---

## Comando base

```powershell
ffmpeg -f dshow -i video="AV TO USB2.0":audio="Micrófono (USB2.0 MIC)" `
-filter_complex "[0:v]scale=in_color_matrix=bt601:out_color_matrix=bt601,split=2[out1][out2]" `
-map "[out1]" -map 0:a -map "[out2]" `
-c:v ffv1 -level 3 -g 1 -coder 1 -context 1 -pix_fmt yuv422p `
-c:a pcm_s16le `
-f tee "[f=matroska]ejemplo.mkv|[f=nut]pipe:1" | ffplay -
```

---

## Explicación del flujo que se genera

- `ffmpeg` accede a video y audio desde la capturadora
- `-i video` especifica la fuente de video
- `-i audio` especifica la fuente de audio
- `-filter_complex` aplica un filtro complejo al video:
  - `scale=in_color_matrix=bt601:out_color_matrix=bt601` convierte el espacio de color de entrada y salida a BT.601
  - `split=2` divide el flujo de video en dos salidas
- `-map "[out1]"` selecciona la primera salida del filtro para el archivo de salida
- `-map 0:a` selecciona el audio de la fuente de entrada
- `-map "[out2]"` selecciona la segunda salida del filtro para el monitoreo
- `-c:v ffv1` especifica el códec de video sin pérdidas (FFV1)
- `-level 3 -g 1 -coder 1 -context 1` establece parámetros de compresión para el códec FFV1
- `-pix_fmt yuv422p` establece el formato de píxeles a YUV 4:2:2
- `-c:a pcm_s16le` especifica el códec de audio sin compresión
- `-f tee` permite enviar la salida a múltiples destinos
  - `[f=matroska]ejemplo.mkv` guarda el video en un archivo `.mkv`
  - `[f=nut]pipe:1` envía el video a `ffplay` para monitoreo en tiempo real
- `| ffplay -` envía la salida de video a `ffplay` para su visualización en tiempo real
- `-f nut` especifica el formato de salida como NUT (un contenedor de video)
- `pipe:1` envía la salida de video a la salida estándar (stdout) para que `ffplay` la reciba
- `ffplay -` recibe la salida de video y audio para su visualización en tiempo real

---

## Cosas que se deben tener en cuenta

- **Solo un proceso** (ffmpeg) accede al hardware; ffplay (el monitoreo) solo recibe un duplicado del archivo que se está generando.
- **El audio se escucha** en la vista previa gracias a `pipe:1`.
- Presionar `CTRL+C` termina la grabación de forma segura y permite que el archivo `.mkv` se guarde correctamente.
- Mientras se está grabando, no se deben usar otras aplicaciones que puedan acceder a la capturadora USB como: OBS, Zoom, etc.

---

## Como grabar

Con el siguiente comando se inicia la grabación y sistema de monitoreo en tiempo real. Para detener la grabación, presiona `CTRL+C` en la consola de PowerShell.

```powershell
./captura.ps1 --nombre="001"
```

Al final, se crea un archivo `.mkv` con el nombre que se le haya pasado como parámetro. Si no se pasa ningún parámetro, se genera un nombre automático basado en la fecha y hora de la grabación.
El nombre del archivo se genera con el siguiente formato: `captura_YYYY-MM-DD_HHMMSS.mkv`, donde `YYYY-MM-DD` es la fecha y `HHMMSS` es la hora de inicio de la grabación.

El comando que se ejecuta cuando usamos `./captura.ps1` es el siguiente. Si se usa una capturadora con otro nombre, se debe cambiar el nombre de la capturadora en el comando. El archivo `captura.ps1` esta en este mismo repositorio.

```powershell
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
```
