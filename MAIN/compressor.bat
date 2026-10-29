@echo off
setlocal enabledelayedexpansion

cd /d "%~dp0"
set "IN_DIR=%~dp0input"
set "OUT_DIR=%~dp0output"

cls
echo =========================================================================
echo               ARCHIVAL VIDEO COMPRESSION SYSTEM (H.265)
echo =========================================================================
echo.

:: Verify FFmpeg is present
where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg is not detected!
    echo Ensure ffmpeg is in your PATH or place "ffmpeg.exe" next to this script.
    echo.
    pause
    exit /b
)

:: Ensure directories exist
if not exist "%IN_DIR%" (
    mkdir "%IN_DIR%"
    mkdir "%OUT_DIR%"
    echo [!] "input" folder was missing and has just been created.
    echo Drop your raw videos into the "input" folder, then run this script again.
    echo.
    pause
    exit /b
)
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

:: Menu display
echo Choose your target compression level:
echo.
echo [1] MAXIMUM COMPRESSION (Smallest Size / Lower Quality)
echo     - Setting : CRF 28 ^| Audio: 96k AAC
echo     - Space   : Cuts ~75%% to 85%% of original size
echo     - Quality : Noticeable softening of skin, texture, and dark scenes.
echo     - Best for: Disposable footage, quick sharing, severe disk space limits.
echo.
echo [2] BALANCED / OPTIMAL (Recommended Sweet Spot)
echo     - Setting : CRF 23 ^| Audio: 128k AAC
echo     - Space   : Cuts ~55%% to 75%% of original size
echo     - Quality : Virtually indistinguishable from raw on TVs and phones.
echo     - Best for: Everyday family videos, phone dumps, smart storage balance.
echo.
echo [3] HIGH ARCHIVAL QUALITY (Near-Transparency)
echo     - Setting : CRF 20 ^| Audio: 160k AAC
echo     - Space   : Cuts ~40%% to 55%% of original size
echo     - Quality : Retains film grain, fine clothing textures, and night details.
echo     - Best for: Important archives, professional footage, high-detail clips.
echo.
echo [4] MASTER PRESERVATION (Highest Quality / Largest Size)
echo     - Setting : CRF 17 ^| Audio: 100%% Lossless Copy (No re-encoding)
echo     - Space   : Cuts only ~20%% to 35%% of original size
echo     - Quality : Visually identical master copy. Virtually zero compression loss.
echo     - Best for: Rare historical footage, cinematic projects, source masters.
echo.
echo =========================================================================

choice /c 1234 /n /m "Type a number [1, 2, 3, or 4]: "

if errorlevel 4 (
    set "CRF_VAL=17"
    set "A_PARAMS=-c:a copy"
    set "PROFILE_NAME=Option 4 (Master Preservation)"
    goto start_encoding
)
if errorlevel 3 (
    set "CRF_VAL=20"
    set "A_PARAMS=-c:a aac -b:a 160k"
    set "PROFILE_NAME=Option 3 (High Archival)"
    goto start_encoding
)
if errorlevel 2 (
    set "CRF_VAL=23"
    set "A_PARAMS=-c:a aac -b:a 128k"
    set "PROFILE_NAME=Option 2 (Balanced Optimal)"
    goto start_encoding
)
if errorlevel 1 (
    set "CRF_VAL=28"
    set "A_PARAMS=-c:a aac -b:a 96k"
    set "PROFILE_NAME=Option 1 (Maximum Compression)"
    goto start_encoding
)

:start_encoding
echo.
echo [Selected] !PROFILE_NAME!
echo [Processing] Scanning "input" folder...
echo.

set "COUNT=0"

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

    echo -------------------------------------------------------------------------
    echo Encoding: "%%~nxF"
    echo -------------------------------------------------------------------------

    ffmpeg -hide_banner -loglevel warning -stats -i "%%F" ^
      -map 0:v:0 -map 0:a? ^
      -c:v libx265 -pix_fmt yuv420p10le -crf !CRF_VAL! -preset medium ^
      !A_PARAMS! ^
      -map_metadata 0 -movflags +faststart "!FINAL_OUTPUT!" -y

    set /a COUNT+=1
    echo.
)

if !COUNT! equ 0 (
    echo [!] No video files found in the "input" folder!
) else (
    echo =========================================================================
    echo [SUCCESS] Finished processing !COUNT! video(s) using !PROFILE_NAME!!
    echo Your converted files are in the "output" folder.
    echo =========================================================================
)

pause