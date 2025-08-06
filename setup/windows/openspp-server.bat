@echo off
REM OpenSPP Server Launcher for Windows

set OPENSPP_HOME=%~dp0
set OPENSPP_CONFIG=%OPENSPP_HOME%\openspp.conf

echo Starting OpenSPP Server...
echo.
echo Configuration: %OPENSPP_CONFIG%
echo Home Directory: %OPENSPP_HOME%
echo.
echo Server will be available at: http://localhost:8069
echo.
echo Press Ctrl+C to stop the server
echo.

cd /d "%OPENSPP_HOME%"

REM Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in PATH
    echo Please install Python 3.10 or later
    pause
    exit /b 1
)

REM Check if Odoo is installed
python -c "import odoo" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Odoo is not installed
    echo Installing Odoo...
    pip install odoo==17.0
)

REM Start OpenSPP server
python -m odoo --config="%OPENSPP_CONFIG%" --addons-path="%OPENSPP_HOME%\addons"

pause