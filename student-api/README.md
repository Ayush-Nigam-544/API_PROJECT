## Docker Deployment

### Build the image

```bash
make docker-build
```

### deppendencies before the installation of the whole project

1. Save as install_dependencies.ps1
   powershell
   <#
   .SYNOPSIS
   Installs all dependencies for the Student REST API project
   #>

# Require admin privileges

if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
Write-Host "Please run this script as Administrator!" -ForegroundColor Red
Exit 1
}

# 1. Install Chocolatey (Package Manager)

Write-Host "`nInstalling Chocolatey..." -ForegroundColor Cyan
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

# 2. Core Dependencies

Write-Host "`nInstalling Core Dependencies..." -ForegroundColor Cyan
choco install -y `
git `    python`
vscode `    docker-desktop`
postgresql `
curl

# 3. VS Code Extensions

Write-Host "`nInstalling VS Code Extensions..." -ForegroundColor Cyan
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-docker
code --install-extension alefragnani.project-manager
code --install-extension humao.rest-client
code --install-extension mtxr.sqltools
code --install-extension streetsidesoftware.code-spell-checker

# 4. Python Packages

Write-Host "`nInstalling Python Packages..." -ForegroundColor Cyan
python -m pip install --upgrade pip
pip install `
flask `    flask-sqlalchemy`
flask-migrate `    python-dotenv`
psycopg2-binary `    pytest`
python-json-logger

# 5. Docker Configuration

Write-Host "`nConfiguring Docker..." -ForegroundColor Cyan

# Enable WSL2 backend if not enabled

wsl --set-default-version 2

# 6. PostgreSQL Setup

Write-Host "`nConfiguring PostgreSQL..." -ForegroundColor Cyan

# Initialize DB (password will be prompted)

initdb -D "C:\Program Files\PostgreSQL\data"
pg_ctl register -N PostgreSQL -D "C:\Program Files\PostgreSQL\data"

# 7. VS Code Settings

Write-Host "`nConfiguring VS Code..." -ForegroundColor Cyan
$vscodeSettings = @"
{
    "python.pythonPath": "venv\\Scripts\\python.exe",
    "python.linting.enabled": true,
    "python.testing.pytestEnabled": true,
    "[python]": {
        "editor.formatOnSave": true
    },
    "docker.explorerRefreshInterval": 3000
}
"@
New-Item -Path "$env:APPDATA\Code\User\settings.json" -Value $vscodeSettings -Force

# 8. Environment Variables

Write-Host "`nSetting Environment Variables..." -ForegroundColor Cyan
[System.Environment]::SetEnvironmentVariable("DATABASE_URL", "sqlite:///students.db", "User")
[System.Environment]::SetEnvironmentVariable("FLASK_ENV", "development", "User")

# 9. PowerShell Execution Policy

Write-Host "`nUpdating Execution Policy..." -ForegroundColor Cyan
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Write-Host "`nAll dependencies installed successfully!`n" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart your computer" -ForegroundColor Yellow
Write-Host "2. Open VS Code and clone your repository" -ForegroundColor Yellow
Write-Host "3. Run 'docker-desktop' from Start Menu" -ForegroundColor Yellow
How to Use This Script
Save as install_dependencies.ps1

Right-click → "Run with PowerShell" (as Administrator)

Follow any prompts during installation

What This Installs
Category Components
Package Manager Chocolatey
Core Tools Git, Python, VS Code, Docker, PostgreSQL
VS Code Extensions Python, Docker, REST Client, SQLTools
Python Packages Flask, SQLAlchemy, pytest, etc.
Database PostgreSQL + SQLite support
Configuration VS Code settings, Environment variables
