@echo off
cd /d "%~dp0"
echo MyNotes Setup und Build - Log: build.log
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Transcript -Path '%~dp0build.log' -Force; & '%~dp0setup-and-build-mynotes.ps1' %*; $c=$LASTEXITCODE; Stop-Transcript; exit $c"
echo.
echo Fertig (Exitcode %ERRORLEVEL%). Fenster kann geschlossen werden.
pause
