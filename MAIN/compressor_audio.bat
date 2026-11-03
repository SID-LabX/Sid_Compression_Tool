@echo off
if not defined SCRIPT_STAY_OPEN (
    set "SCRIPT_STAY_OPEN=1"
    cmd /k ""%~f0" %*"
    exit /b
)

setlocal enabledelayedexpansion

cd /d "%~dp0"
set "IN_DIR=%~dp0input"
set "OUT_DIR=%~dp0output"

cls
echo =========================================================================
echo               ARCHIVAL AUDIO COMPRESSION SYSTEM (Opus / FLAC)
echo =========================================================================
echo.

where ffmpeg >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] FFmpeg is not detected!
    echo Ensure ffmpeg is in your PATH or place "ffmpeg.exe" next to this script.
    echo.
    pause
    exit /b
)

if not exist "%IN_DIR%" (
    mkdir "%IN_DIR%"
    mkdir "%OUT_DIR%"
    echo [!] "input" folder was missing and has just been created.
    echo Drop your raw audio files into the "input" folder, then run this script again.
    echo.
    pause
    exit /b
)
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo Choose your target compression level:
echo.
echo [1] SPEECH / HIGH COMPRESSION (Opus 48 kbps)
echo     - Setting : Opus 48k VBR
echo     - Note    : Existing WhatsApp .opus files are copied directly (not inflated).
echo     - Best for: Voice notes, podcasts, WhatsApp archives.
echo.
echo [2] BALANCED / MUSIC SWEET SPOT (Opus 96 kbps)
echo     - Setting : Opus 96k VBR
echo     - Best for: General music library, day-to-day listening.
echo.
echo [3] HIGH-FIDELITY LOSSY (Opus 160 kbps)
echo     - Setting : Opus 160k VBR
echo     - Best for: Critical listening, complex tracks, near-transparency.
echo.
echo [4] MASTER LOSSLESS ARCHIVE (FLAC Level 8)
echo     - Setting : FLAC Compression Level 8
echo     - Best for: Studio masters / WAV files (DO NOT use on MP3s).
echo.
echo =========================================================================

choice /c 1234 /n /m "Type a number [1, 2, 3, or 4]: "

if errorlevel 4 (
    set "OUT_EXT=flac"
    set "A_PARAMS=-c:a flac -compression_level 8"
    set "PROFILE_NAME=Option 4 (FLAC Master)"
    goto start_encoding
)
if errorlevel 3 (
    set "OUT_EXT=opus"
    set "A_PARAMS=-c:a libopus -b:a 160k -vbr on"
    set "PROFILE_NAME=Option 3 (High Opus 160k)"
    goto start_encoding
)
if errorlevel 2 (
    set "OUT_EXT=opus"
    set "A_PARAMS=-c:a libopus -b:a 96k -vbr on"
    set "PROFILE_NAME=Option 2 (Balanced Opus 96k)"
    goto start_encoding
)
if errorlevel 1 (
    set "OUT_EXT=opus"
    set "A_PARAMS=-c:a libopus -b:a 48k -vbr on"
    set "PROFILE_NAME=Option 1 (Speech Opus 48k)"
    goto start_encoding
)

:start_encoding
echo.
echo [Selected] !PROFILE_NAME!
echo [Processing] Calculating folder paths...

rem Safely calculate the length of IN_DIR
set "TMP_DIR=%IN_DIR%"
set "DIR_LEN=0"
:calc_len
if not "!TMP_DIR!"=="" (
    set "TMP_DIR=!TMP_DIR:~1!"
    set /a DIR_LEN+=1
    goto calc_len
)

echo [Processing] Scanning "input" folder...
echo.

set "COUNT=0"
set "SKIPPED=0"

for /R "%IN_DIR%" %%F in (*.mp3 *.m4a *.flac *.wav *.ogg *.opus *.wma *.aac) do (
    set "FILE_PATH=%%F"
    set "FILE_EXT=%%~xF"
    set "REL_PATH=!FILE_PATH:~%DIR_LEN%!"
    set "TARGET_FILE=%OUT_DIR%!REL_PATH!"
    
    for %%I in ("!TARGET_FILE!") do (
        set "TARGET_SUBDIR=%%~dpI"
        set "TARGET_NAME=%%~nI"
    )
    set "FINAL_OUTPUT=!TARGET_SUBDIR!!TARGET_NAME!.!OUT_EXT!"

    if exist "!FINAL_OUTPUT!" (
        echo [SKIPPED] Already exists: "!TARGET_NAME!.!OUT_EXT!"
        set /a SKIPPED+=1
    ) else (
        if not exist "!TARGET_SUBDIR!" mkdir "!TARGET_SUBDIR!"

        set "DO_COPY=0"
        if /I "!FILE_EXT!"==".opus" if /I "!OUT_EXT!"=="opus" set "DO_COPY=1"

        if "!DO_COPY!"=="1" (
            echo -------------------------------------------------------------------------
            echo Copying as-is [Already Opus]: "%%~nxF"
            echo -------------------------------------------------------------------------
            copy /Y "%%F" "!FINAL_OUTPUT!" >nul
            set /a COUNT+=1
            echo.
        ) else (
            echo -------------------------------------------------------------------------
            echo Encoding: "%%~nxF"
            echo -------------------------------------------------------------------------
            ffmpeg -hide_banner -loglevel warning -stats -i "%%F" -vn !A_PARAMS! -map_metadata 0 "!FINAL_OUTPUT!" -n
            set /a COUNT+=1
            echo.
        )
    )
)

set /a TOTAL=!COUNT!+!SKIPPED!
if !TOTAL! equ 0 (
    echo [!] No audio files found in the "input" folder!
) else (
    echo =========================================================================
    echo [SUCCESS] Finished! Processed: !COUNT! ^| Skipped: !SKIPPED!
    echo Profile used: !PROFILE_NAME!
    echo Your converted files are in the "output" folder.
    echo =========================================================================
)

echo.
pause