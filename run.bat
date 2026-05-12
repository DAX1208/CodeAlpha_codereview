@echo off
setlocal
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo Creating virtual environment...
  py -3 -m venv .venv 2>nul || python -m venv .venv
  call ".venv\Scripts\activate.bat"
  python -m pip install -q -r requirements.txt
) else (
  call ".venv\Scripts\activate.bat"
)

if not exist ".env" (
  echo Copying .env.example to .env ...
  copy /Y ".env.example" ".env" >nul
)

echo.
echo Starting Flask — open http://127.0.0.1:5000  (Ctrl+C to stop)
echo.
python app.py

pause
