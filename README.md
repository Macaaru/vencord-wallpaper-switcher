# vencord-wallpaper-switcher

Tema ClearVision v7 modificado para Vencord con cambiador de fondo de pantalla mediante interfaz gráfica.

## ¿Qué es esto?

Una versión tuneada del tema [ClearVision v7](https://github.com/ClearVision/ClearVision-v7) para Vencord que permite **cambiar el fondo de Discord visualmente** sin tocar el CSS manualmente.

Incluye:
- Tema completamente autocontenido (sin dependencias externas, funciona offline)
- Colores de acento personalizados
- GUI en PowerShell con miniaturas para elegir el wallpaper con un clic

## Estructura del repo

```
vencord-wallpaper-switcher/
├── theme/
│   ├── ClearVision.css              ← tema principal (va en la carpeta de temas de Vencord)
│   └── ClearVisionAssets/
│       ├── WallpaperPicker.ps1      ← script GUI del cambiador
│       ├── discord.svg              ← icono de Discord (asset del tema)
│       └── pill.svg                 ← indicador de canal no leído (asset del tema)
├── launcher/
│   └── WallpaperDiscord.vbs         ← lanzador sin consola (doble clic para abrir la GUI)
└── README.md
```

## Instalación

### 1. Tema
Copia el contenido de `theme/` en tu carpeta de temas de Vencord:
```
%AppData%\Vencord\themes\
```
Resultado esperado:
```
%AppData%\Vencord\themes\
├── ClearVision.css
└── ClearVisionAssets\
    ├── WallpaperPicker.ps1
    ├── discord.svg
    └── pill.svg
```

### 2. Lanzador
Copia `launcher/WallpaperDiscord.vbs` donde quieras (escritorio, carpeta de accesos directos, etc.).

### 3. Wallpapers
Pon tus wallpapers como PNGs numerados en:
```
%USERPROFILE%\Pictures\Wallpapers\
```
Ejemplo: `1.png`, `2.png`, `3.png`...

## Rutas configurables

Abre `ClearVisionAssets\WallpaperPicker.ps1` y ajusta si es necesario:

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `$wallpapersDir` | Carpeta con tus wallpapers | `%USERPROFILE%\Pictures\Wallpapers` |

El resto de rutas son dinámicas (`$PSScriptRoot`, `%APPDATA%`, `%LOCALAPPDATA%`).

## Uso

Doble clic en `WallpaperDiscord.vbs`. Se abre una ventana con miniaturas de todos tus wallpapers. Haz clic en uno para aplicarlo. Vencord recarga el tema automáticamente.

## Origen del tema

Basado en [ClearVision v7 for BetterDiscord](https://github.com/ClearVision/ClearVision-v7).  
Los assets externos (imágenes, iconos SVG) están embebidos en base64 directamente en el CSS.
