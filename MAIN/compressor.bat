@echo off
setlocal enabledelayedexpansion

:: Lock script execution to the directory where this .bat file is saved
cd /d "%~dp0"

set "IN_DIR=%~dp0input"
set "OUT_DIR=%~dp0output"

echo ========================================================
echo        Archival Video Auto-Batch Compressor (H.265)
echo ========================================================
echo.

:: 1. Verify FFmpeg is available
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg is not detected!
    echo.
    echo Make sure FFmpeg is installed in your Windows PATH, 
    echo OR place "ffmpeg.exe" in this exact same folder next to this .bat file.
    echo.
    pause
    exit /b
)

:: 2. Create the input folder if it doesn't exist yet
if not exist "%IN_DIR%" (
    mkdir "%IN_DIR%"
    mkdir "%OUT_DIR%"
    echo [!] "input" folder was missing, so it has been created for you.
    echo.
    echo Place your raw video files inside the "input" folder,
    echo then double-click this .bat file again.
    echo.
    pause
    exit /b
)

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "COUNT=0"

:: 3. Process video files (handles subfolders too if you organize by dates/folders)
for /R "%IN_DIR%" %%F in (*.mp4 *.mov *.mkv *.avi *.m4v *.webm *.mts) do (
    set "FILE_PATH=%%F"
    set "REL_PATH=!FILE_PATH:%IN_DIR%=!"
    set "TARGET_FILE=%OUT_DIR%!REL_PATH!"
    
    for %%I in ("!TARGET_FILE!") do (
        set "TARGET_SUBDIR=%%~dpI"
        set "TARGET_NAME=%%~nI"
    )
    set "FINAL_OUTPUT=!TARGET_SUBDIR!!TARGET_NAME!.mp4"

    if not exist "!TARGET_SUBDIR!" mkdir "!TARGET_SUBDIR!"

    echo --------------------------------------------------------
    echo [Encoding] "%%~nxF"
    echo --------------------------------------------------------

    rem Archival Settings:
    rem - H.265 10-bit (yuv420p10le) to eliminate color banding
    rem - CRF 23 for near-transparent visual quality
    rem - Preset medium for optimal size-to-speed ratio
    rem - AAC 128k stereo audio
    rem - Retains all original camera metadata & creation dates
    rem - faststart enables instant web/cloud playback

    ffmpeg -hide_banner -loglevel warning -stats -i "%%F" ^
      -map 0:v:0 -map 0:a? ^
      -c:v libx265 -pix_fmt yuv420p10le -crf 23 -preset medium ^
      -c:a aac -b:a 128k ^
      -map_metadata 0 -movflags +faststart "!FINAL_OUTPUT!" -y

    set /a COUNT+=1
    echo.
    echo [Done] Saved to output folder.
    echo.
)

if !COUNT! equ 0 (
    echo [!] No videos were found inside the "input" folder.
    echo Drop your video files inside "input" and run this again.
) else (
    echo ========================================================
    echo [SUCCESS] Finished compressing !COUNT! video(s)!
    echo You can find your new files in the "output" folder.
    echo ========================================================
)

pause