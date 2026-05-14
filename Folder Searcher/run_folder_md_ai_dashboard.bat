@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

title Folder Markdown AI Dashboard

echo ================================================
echo   Folder Markdown AI Dashboard Launcher
echo ================================================
echo.
echo Use the folder dialogs to pick paths. Other questions use Y/N keys only.
echo Defaults: Markdown in ^<scanned folder^>\Folder-Markups, qwen2.5:7b + thinking ^(Ollama ~8B-class tag^).
echo.

:after_python_check
where py >nul 2>nul
if %errorlevel%==0 (
    set "PY_CMD=py -3"
    goto python_ready
)

where python >nul 2>nul
if %errorlevel%==0 (
    set "PY_CMD=python"
    goto python_ready
)

echo Python was not found in PATH.
echo Install Python 3 and make sure the launcher or python.exe is on PATH.
pause
exit /b 1

:python_ready
if not exist "%~dp0app.py" (
    echo Could not find app.py in:
    echo %~dp0
    echo Put this .bat file in the same folder as the Python script.
    pause
    exit /b 1
)

set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not "%~1"=="" (
    set "ROOT_FOLDER=%~1"
    goto have_root
)

echo [1/3] Select the folder to scan...
for /f "delims=" %%I in ('"%PS%" -NoProfile -STA -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Select the folder to scan'; $d.ShowNewFolderButton = $false; if ($d.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 1 }; if ([string]::IsNullOrEmpty($d.SelectedPath)) { exit 1 }; Write-Output -NoNewline $d.SelectedPath"') do set "ROOT_FOLDER=%%I"
if not defined ROOT_FOLDER (
    echo Cancelled or no folder selected.
    pause
    exit /b 0
)

:have_root
if not exist "!ROOT_FOLDER!" (
    echo The folder does not exist:
    echo !ROOT_FOLDER!
    pause
    exit /b 1
)

set "DEFAULT_OUTPUT=!ROOT_FOLDER!\Folder-Markups"
echo.
echo [2/3] Where to write Markdown reports?
choice /C DB /M "  [D] Default: !DEFAULT_OUTPUT!   [B] Pick a different folder"
if errorlevel 2 goto browse_output
set "OUTPUT_MD=!DEFAULT_OUTPUT!"
goto have_output
:browse_output
echo.
echo Select the output folder...
for /f "delims=" %%I in ('"%PS%" -NoProfile -STA -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = 'Select output folder for Markdown reports'; $d.ShowNewFolderButton = $true; if ($d.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { exit 1 }; if ([string]::IsNullOrEmpty($d.SelectedPath)) { exit 1 }; Write-Output -NoNewline $d.SelectedPath"') do set "OUTPUT_MD=%%I"
if not defined OUTPUT_MD (
    echo Cancelled.
    pause
    exit /b 0
)

:have_output
echo.
echo [3/3] Options (Y = first choice, N = second)
echo.
set "INVENTORY_ARG="
choice /C YN /M "Save inventory JSON in the output folder as folder_inventory.json"
if errorlevel 2 goto no_json
set "INV_JSON=!OUTPUT_MD!\folder_inventory.json"
set INVENTORY_ARG=--inventory-json "!INV_JSON!"
:no_json

choice /C YN /M "Analyze images with the vision model"
set "IMAGE_ARG="
if errorlevel 2 goto no_img
set "IMAGE_ARG=--analyze-images"
:no_img

choice /C YN /M "Include hidden files and folders"
set "HIDDEN_ARG="
if errorlevel 2 goto no_hidden
set "HIDDEN_ARG=--include-hidden"
:no_hidden

choice /C YN /M "Disable AI (deterministic report only)"
set "AI_ARG="
set "MODEL_ARG="
set "OLLAMA_ARG="
set "THINK_ARG="
if errorlevel 2 goto ai_on
set "AI_ARG=--disable-ai"
goto after_ai

:ai_on
rem Ollama lists this as qwen2.5:7b (~7.6B); closest official "Qwen 2.5 ~8B" tag. Thinking via --think.
set "DEFAULT_MODEL=qwen2.5:7b"
set "DEFAULT_OLLAMA=http://localhost:11434"
set "MODEL_NAME=!DEFAULT_MODEL!"
set "OLLAMA_URL=!DEFAULT_OLLAMA!"
set "THINK_ARG=--think"
choice /C YN /M "Use defaults: !DEFAULT_MODEL! + --think, Ollama at !DEFAULT_OLLAMA!"
if errorlevel 2 goto custom_ai
goto after_ai

:custom_ai
set /p MODEL_NAME=Ollama model [!DEFAULT_MODEL!]: 
if not defined MODEL_NAME set "MODEL_NAME=!DEFAULT_MODEL!"
set MODEL_ARG=--model "!MODEL_NAME!"
set /p OLLAMA_URL=Ollama URL [!DEFAULT_OLLAMA!]: 
if not defined OLLAMA_URL set "OLLAMA_URL=!DEFAULT_OLLAMA!"
set OLLAMA_ARG=--ollama-url "!OLLAMA_URL!"
choice /C YN /M "Add --think for models that support thinking traces"
if errorlevel 2 (
    set "THINK_ARG="
) else (
    set "THINK_ARG=--think"
)
goto after_ai_custom_done

:after_ai
if defined AI_ARG goto after_ai_custom_done
set MODEL_ARG=--model "!MODEL_NAME!"
set OLLAMA_ARG=--ollama-url "!OLLAMA_URL!"

:after_ai_custom_done
set "MAX_DOCS=16"
set "MAX_IMAGES=8"

echo.
echo Running...
echo.
echo Root folder  : !ROOT_FOLDER!
echo Output folder: !OUTPUT_MD!
if defined INVENTORY_ARG echo JSON manifest: !OUTPUT_MD!\folder_inventory.json
if defined AI_ARG (
    echo AI mode    : disabled
) else (
    echo AI model   : !MODEL_NAME! !THINK_ARG!
    echo Ollama URL : !OLLAMA_URL!
)
echo.

%PY_CMD% "%~dp0app.py" "!ROOT_FOLDER!" --output-dir "!OUTPUT_MD!" !INVENTORY_ARG! !IMAGE_ARG! !HIDDEN_ARG! !AI_ARG! !MODEL_ARG! !OLLAMA_ARG! !THINK_ARG! --max-doc-evidence-per-folder !MAX_DOCS! --max-image-evidence-per-folder !MAX_IMAGES!
set "EXIT_CODE=!errorlevel!"

echo.
if "!EXIT_CODE!"=="0" (
    echo Done.
    if exist "!OUTPUT_MD!" (
        echo Opening output folder...
        start "" "!OUTPUT_MD!"
    )
) else (
    echo The script ended with exit code !EXIT_CODE!.
)

echo.
pause
exit /b !EXIT_CODE!
