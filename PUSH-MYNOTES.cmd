@echo off
cd /d "%~dp0"
where git >nul 2>&1 || (echo Git fehlt - zuerst BUILD-MYNOTES.cmd ausfuehren oder Git installieren. & pause & exit /b 1)
git push -u origin main
echo.
echo Exitcode %ERRORLEVEL% (0 = erfolgreich gepusht).
pause
