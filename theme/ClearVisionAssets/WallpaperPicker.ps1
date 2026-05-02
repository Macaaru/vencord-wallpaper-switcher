Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DWM {
    [DllImport("dwmapi.dll")]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);
    [DllImport("uxtheme.dll", CharSet = CharSet.Unicode)]
    public static extern int SetWindowTheme(IntPtr hwnd, string appname, string idlist);
    public static void DarkTitle(IntPtr hwnd)       { int v=1; DwmSetWindowAttribute(hwnd,20,ref v,4); }
    public static void RoundedCorners(IntPtr hwnd)  { int v=2; DwmSetWindowAttribute(hwnd,33,ref v,4); }
    public static void BorderColor(IntPtr hwnd, int c)  { DwmSetWindowAttribute(hwnd,34,ref c,4); }
    public static void CaptionColor(IntPtr hwnd, int c) { DwmSetWindowAttribute(hwnd,35,ref c,4); }
    public static void DarkScrollbar(IntPtr hwnd)   { SetWindowTheme(hwnd, "DarkMode_Explorer", null); }
}
"@

$wallpapersDir = "$env:USERPROFILE\Pictures\Wallpapers"   # CONFIGURABLE: carpeta con tus wallpapers (1.png, 2.png...)
$cssPath       = "$PSScriptRoot\..\ClearVision.css"
$thumbW        = 220
$cols          = 3
$cardMargin    = 6

# Calcular alto del thumb respetando el aspect ratio de la primera imagen
$firstImg = Get-ChildItem $wallpapersDir -Filter "*.png" | Sort-Object { [int]($_.BaseName) } | Select-Object -First 1
$_bmp0    = [System.Drawing.Bitmap]::new($firstImg.FullName)
$thumbH   = [int]($thumbW * $_bmp0.Height / $_bmp0.Width)
$_bmp0.Dispose()

$cardW         = $thumbW + 16
$cardH         = $thumbH + 38
$flowW         = ($cardW + $cardMargin * 2) * $cols
$rowsToShow    = 3
$flowH         = $rowsToShow * ($cardH + $cardMargin * 2) + 12

# Colores
$cBg      = [System.Drawing.Color]::FromArgb(18, 18, 20)
$cCard    = [System.Drawing.Color]::FromArgb(30, 30, 32)
$cCardHov = [System.Drawing.Color]::FromArgb(44, 44, 48)
$cStatus  = [System.Drawing.Color]::FromArgb(12, 12, 14)

function Set-RoundedRegion($control, [int]$radius) {
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $w = $control.Width; $h = $control.Height; $d = $radius * 2
    $path.AddArc(0,        0,        $d, $d, 180, 90)
    $path.AddArc($w - $d,  0,        $d, $d, 270, 90)
    $path.AddArc($w - $d,  $h - $d,  $d, $d,   0, 90)
    $path.AddArc(0,        $h - $d,  $d, $d,  90, 90)
    $path.CloseAllFigures()
    $control.Region = [System.Drawing.Region]::new($path)
}

function Apply-Wallpaper($imagePath) {
    $bmp       = [System.Drawing.Bitmap]::new($imagePath)
    $ms        = [System.IO.MemoryStream]::new()
    $codec     = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
    $encParams = [System.Drawing.Imaging.EncoderParameters]::new(1)
    $encParams.Param[0] = [System.Drawing.Imaging.EncoderParameter]::new([System.Drawing.Imaging.Encoder]::Quality, 85L)
    $bmp.Save($ms, $codec, $encParams)
    $bmp.Dispose()
    $bytes = $ms.ToArray()
    $ms.Dispose()

    $b64     = [System.Convert]::ToBase64String($bytes)
    $dataUrl = "url(data:image/jpeg;base64,$b64)"
    $css     = [System.IO.File]::ReadAllText($cssPath, [System.Text.Encoding]::UTF8)
    $css     = $css -replace '--background-image: url\(data:[^)]+\)', "--background-image: $dataUrl"
    [System.IO.File]::WriteAllText($cssPath, $css, [System.Text.Encoding]::UTF8)
}

# --- Icono desde discord.svg via Discord.exe ---
$form = [System.Windows.Forms.Form]::new()
$discordExe = Get-ChildItem "$env:LOCALAPPDATA\Discord" -Filter "Discord.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if ($discordExe) {
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($discordExe.FullName)
}

$form.Text            = "Discord Wallpaper"
$form.BackColor       = $cBg
$form.ForeColor       = [System.Drawing.Color]::WhiteSmoke
$form.StartPosition   = "CenterScreen"
# ancho: scrollbar(17) + padding(24) + flowW | alto: padding top(8) + flowH + sep(1) + status(32)
$form.ClientSize      = [System.Drawing.Size]::new($flowW + 17 + 24, 8 + $flowH + 1 + 32)
$form.Padding         = [System.Windows.Forms.Padding]::new(12, 8, 12, 0)
$form.Font            = [System.Drawing.Font]::new("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$form.FormBorderStyle = "Sizable"

$form.Add_Shown({
    $hwnd = $form.Handle
    [DWM]::DarkTitle($hwnd)
    [DWM]::RoundedCorners($hwnd)
    [DWM]::BorderColor($hwnd,  0x00241812)
    [DWM]::CaptionColor($hwnd, 0x00141412)
    [DWM]::DarkScrollbar($scroll.Handle)
    $form.MinimumSize = $form.Size
    & $centerFlow
})


# --- Scroll panel ---
$scroll = [System.Windows.Forms.Panel]::new()
$scroll.AutoScroll  = $true
$scroll.BackColor   = $cBg
$scroll.Dock        = "Fill"
$scroll.HorizontalScroll.Maximum = 0
$scroll.AutoScrollMinSize = [System.Drawing.Size]::new(0, 0)

# --- FlowLayout con ancho fijo para forzar 3 por fila ---
$flow = [System.Windows.Forms.FlowLayoutPanel]::new()
$flow.AutoSize     = $true
$flow.AutoSizeMode = "GrowAndShrink"
$flow.BackColor    = $cBg
$flow.MaximumSize  = [System.Drawing.Size]::new($flowW, 0)
$flow.Padding      = [System.Windows.Forms.Padding]::new(0, 4, 0, 8)

# --- Status ---
$status = [System.Windows.Forms.Label]::new()
$status.AutoSize  = $false
$status.Dock      = "Bottom"
$status.Height    = 32
$status.TextAlign = "MiddleCenter"
$status.BackColor = $cStatus
$status.ForeColor = [System.Drawing.Color]::FromArgb(160, 160, 170)
$status.Font      = [System.Drawing.Font]::new("Consolas", 8.5, [System.Drawing.FontStyle]::Bold)
$status.Text      = "Haz clic en un wallpaper para aplicarlo"

$sep = [System.Windows.Forms.Panel]::new()
$sep.Dock      = "Bottom"
$sep.Height    = 1
$sep.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 50)

# --- Miniaturas ---
$images = Get-ChildItem $wallpapersDir -Filter "*.png" | Sort-Object { [int]($_.BaseName) }

foreach ($img in $images) {
    $panel = [System.Windows.Forms.Panel]::new()
    $panel.Size      = [System.Drawing.Size]::new($cardW, $cardH)
    $panel.BackColor = $cCard
    $panel.Margin    = [System.Windows.Forms.Padding]::new($cardMargin)
    $panel.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $panel.Tag       = $img.FullName

    $pic = [System.Windows.Forms.PictureBox]::new()
    $pic.Size      = [System.Drawing.Size]::new($thumbW, $thumbH)
    $pic.Location  = [System.Drawing.Point]::new(8, 8)
    $pic.SizeMode  = "StretchImage"
    $pic.BackColor = $cCard
    $pic.Tag       = $img.FullName

    $bmp   = [System.Drawing.Bitmap]::new($img.FullName)
    $thumb = $bmp.GetThumbnailImage($thumbW, $thumbH, $null, [IntPtr]::Zero)
    $bmp.Dispose()
    $pic.Image = $thumb

    $lbl = [System.Windows.Forms.Label]::new()
    $lbl.Text      = "Wallpaper $($img.BaseName)"
    $lbl.AutoSize  = $false
    $lbl.Width     = $cardW
    $lbl.Height    = 22
    $lbl.Location  = [System.Drawing.Point]::new(0, $thumbH + 11)
    $lbl.TextAlign = "MiddleCenter"
    $lbl.ForeColor = [System.Drawing.Color]::FromArgb(180, 180, 190)
    $lbl.Font      = [System.Drawing.Font]::new("Consolas", 8, [System.Drawing.FontStyle]::Bold)
    $lbl.Tag       = $img.FullName

    Set-RoundedRegion $panel 10
    Set-RoundedRegion $pic   8

    $panel.Controls.Add($pic)
    $panel.Controls.Add($lbl)
    $flow.Controls.Add($panel)

    $clickHandler = {
        param($s, $e)
        $path = $s.Tag
        $name = [System.IO.Path]::GetFileNameWithoutExtension($path)
        $status.Text      = "Aplicando wallpaper $name..."
        $status.ForeColor = [System.Drawing.Color]::FromArgb(250, 204, 21)
        $form.Refresh()
        Apply-Wallpaper $path
        $status.Text      = "Wallpaper $name aplicado."
        $status.ForeColor = [System.Drawing.Color]::FromArgb(74, 222, 128)
    }.GetNewClosure()

    $panel.Add_Click($clickHandler)
    $pic.Add_Click($clickHandler)
    $lbl.Add_Click($clickHandler)

    $lbl.BackColor = $cCard

    $enterHandler = {
        param($s,$e)
        $panel.BackColor = $cCardHov
        $pic.BackColor   = $cCardHov
        $lbl.BackColor   = $cCardHov
    }.GetNewClosure()
    $leaveHandler = {
        param($s,$e)
        $cursor = $panel.PointToClient([System.Windows.Forms.Cursor]::Position)
        if (-not $panel.ClientRectangle.Contains($cursor)) {
            $panel.BackColor = $cCard
            $pic.BackColor   = $cCard
            $lbl.BackColor   = $cCard
        }
    }.GetNewClosure()

    $panel.Add_MouseEnter($enterHandler)
    $panel.Add_MouseLeave($leaveHandler)
    $pic.Add_MouseEnter($enterHandler)
    $pic.Add_MouseLeave($leaveHandler)
    $lbl.Add_MouseEnter($enterHandler)
    $lbl.Add_MouseLeave($leaveHandler)
}

$centerFlow = {
    $x = [Math]::Max(0, [int](($scroll.ClientSize.Width - $flow.Width) / 2))
    $flow.Location = [System.Drawing.Point]::new($x, 4)
}

$scroll.Add_Resize({ & $centerFlow })
$scroll.Controls.Add($flow)

$form.Controls.Add($scroll)
$form.Controls.Add($sep)
$form.Controls.Add($status)

[System.Windows.Forms.Application]::Run($form)
