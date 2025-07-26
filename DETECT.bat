@echo off
title Detectar Adaptadores de Rede
color 0B

echo.
echo ==========================================
echo    DETECTAR ADAPTADORES DE REDE
echo ==========================================
echo.

:: Verificar se está executando como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ⚠️ REQUER PRIVILEGIOS DE ADMINISTRADOR
    echo Solicitando permissoes...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)

:: Executar detecção de adaptadores
powershell -Command "Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object Name, InterfaceDescription, LinkSpeed | Format-Table -AutoSize; Write-Host ''; Write-Host 'Configure o adaptador correto em config.ps1' -ForegroundColor Yellow"

echo.
pause 
