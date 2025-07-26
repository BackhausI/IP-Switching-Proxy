@echo off
title IP Proxy Toggle - OpenKore
color 0A

echo.
echo ==========================================
echo    IP PROXY TOGGLE - OPENKORE
echo ==========================================
echo.
echo Detectando estado atual...

:: Verificar se está executando como administrador
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo ⚠️ REQUER PRIVILEGIOS DE ADMINISTRADOR
    echo Solicitando permissoes, se nao funcionar, execute o script como administrador...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit
)

:: Executar o script de toggle
powershell -ExecutionPolicy Bypass -Command "& '%~dp0ip_proxy_toggle.ps1'"

echo.
pause 