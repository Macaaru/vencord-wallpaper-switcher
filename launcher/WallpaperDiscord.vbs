Set shell = CreateObject("WScript.Shell")
scriptPath = shell.ExpandEnvironmentStrings("%APPDATA%\Vencord\themes\ClearVisionAssets\WallpaperPicker.ps1")
shell.Run "powershell -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File """ & scriptPath & """", 0, False
