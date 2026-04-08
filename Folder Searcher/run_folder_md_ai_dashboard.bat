@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

title Folder Markdown AI Dashboard

echo ================================================
echo   Folder Markdown AI Dashboard Launcher
echo ================================================
echo.

after_python_check:
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
if not exist "%~dp0folder_md_ai_dashboard.py" (
    echo Could not find folder_md_ai_dashboard.py in:
    echo %~dp0
    echo Put this .bat file in the same folder as the Python script.
    pause
    exit /b 1
)

set "ROOT_FOLDER=%~1"
if not defined ROOT_FOLDER (
    set /p ROOT_FOLDER=Enter the folder to scan: 
)

if not defined ROOT_FOLDER (
    echo No folder was entered.
    pause
    exit /b 1
)

if not exist "%ROOT_FOLDER%" (
    echo The folder does not exist:
    echo %ROOT_FOLDER%
    pause
    exit /b 1
)

set "DEFAULT_OUTPUT=%ROOT_FOLDER%\folder_dashboard.md"
set /p OUTPUT_MD=Output Markdown path [default: %DEFAULT_OUTPUT%]: 
if not defined OUTPUT_MD set "OUTPUT_MD=%DEFAULT_OUTPUT%"

set /p SAVE_JSON=Also save inventory JSON? [y/N]: 
set "INVENTORY_ARG="
if /I "%SAVE_JSON%"=="Y" goto ask_json
if /I "%SAVE_JSON%"=="YES" goto ask_json
goto after_json

:ask_json
set "DEFAULT_JSON=%ROOT_FOLDER%\folder_inventory.json"
set /p INVENTORY_JSON=Inventory JSON path [default: %DEFAULT_JSON%]: 
if not defined INVENTORY_JSON set "INVENTORY_JSON=%DEFAULT_JSON%"
set "INVENTORY_ARG=--inventory-json "%INVENTORY_JSON%""

:after_json
set /p ANALYZE_IMAGES=Analyze images with local AI? [y/N]: 
set "IMAGE_ARG="
if /I "%ANALYZE_IMAGES%"=="Y" set "IMAGE_ARG=--analyze-images"
if /I "%ANALYZE_IMAGES%"=="YES" set "IMAGE_ARG=--analyze-images"

set /p INCLUDE_HIDDEN=Include hidden files and folders? [y/N]: 
set "HIDDEN_ARG="
if /I "%INCLUDE_HIDDEN%"=="Y" set "HIDDEN_ARG=--include-hidden"
if /I "%INCLUDE_HIDDEN%"=="YES" set "HIDDEN_ARG=--include-hidden"

set /p DISABLE_AI=Disable AI and make a deterministic report only? [y/N]: 
set "AI_ARG="
if /I "%DISABLE_AI%"=="Y" set "AI_ARG=--disable-ai"
if /I "%DISABLE_AI%"=="YES" set "AI_ARG=--disable-ai"

set "MODEL_ARG="
set "OLLAMA_ARG="
if not defined AI_ARG (
    set "DEFAULT_MODEL=gemma3:4b"
    set /p MODEL_NAME=Ollama model [default: %DEFAULT_MODEL%]: 
    if not defined MODEL_NAME set "MODEL_NAME=%DEFAULT_MODEL%"
    set "MODEL_ARG=--model "%MODEL_NAME%""

    set "DEFAULT_OLLAMA=http://localhost:11434"
    set /p OLLAMA_URL=Ollama URL [default: %DEFAULT_OLLAMA%]: 
    if not defined OLLAMA_URL set "OLLAMA_URL=%DEFAULT_OLLAMA%"
    set "OLLAMA_ARG=--ollama-url "%OLLAMA_URL%""
)

set /p MAX_DEPTH=Max folder section depth [default: 2]: 
if not defined MAX_DEPTH set "MAX_DEPTH=2"

set /p MAX_DOCS=Max docs to summarize with AI [default: 36]: 
if not defined MAX_DOCS set "MAX_DOCS=36"

set /p MAX_IMAGES=Max images to describe [default: 20]: 
if not defined MAX_IMAGES set "MAX_IMAGES=20"

echo.
echo Running...
echo.
echo Root folder: %ROOT_FOLDER%
echo Output MD : %OUTPUT_MD%
if defined INVENTORY_JSON echo Inventory : %INVENTORY_JSON%
if defined AI_ARG (
    echo AI mode   : disabled
) else (
    echo AI model  : %MODEL_NAME%
    echo Ollama URL: %OLLAMA_URL%
)
echo.

%PY_CMD% "%~dp0folder_md_ai_dashboard.py" "%ROOT_FOLDER%" -o "%OUTPUT_MD%" %INVENTORY_ARG% %IMAGE_ARG% %HIDDEN_ARG% %AI_ARG% %MODEL_ARG% %OLLAMA_ARG% --max-section-depth %MAX_DEPTH% --max-docs-to-summarize %MAX_DOCS% --max-images-to-describe %MAX_IMAGES%
set "EXIT_CODE=%errorlevel%"

echo.
if "%EXIT_CODE%"=="0" (
    echo Done.
    if exist "%OUTPUT_MD%" (
        echo Opening Markdown file...
        start "" "%OUTPUT_MD%"
    )
) else (
    echo The script ended with exit code %EXIT_CODE%.
)

echo.
pause
exit /b %EXIT_CODE%
