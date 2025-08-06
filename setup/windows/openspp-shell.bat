@echo off
REM OpenSPP Shell for Windows - Interactive Python Console with OpenSPP/Odoo

set OPENSPP_HOME=%~dp0
set OPENSPP_CONFIG=%OPENSPP_HOME%\openspp.conf

echo OpenSPP Shell - Interactive Console
echo ====================================
echo.
echo This shell provides access to OpenSPP and Odoo objects.
echo Use 'env' to access the Odoo environment.
echo Use 'self' to access the current model.
echo.
echo Example commands:
echo   env['res.users'].search([])
echo   env['spp.program'].create({'name': 'Test Program'})
echo.
echo Type 'exit()' or press Ctrl+Z to quit.
echo.

cd /d "%OPENSPP_HOME%"

REM Start Odoo shell with OpenSPP modules
python -m odoo shell --config="%OPENSPP_CONFIG%" --addons-path="%OPENSPP_HOME%\addons"

pause