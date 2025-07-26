# Arquivo de configuração para toggle_ip.ps1
# Edite apenas este arquivo para personalizar suas configurações

# Nome do adaptador de rede - AJUSTE CONFORME NECESSÁRIO
# Execute .\detect_adapter.ps1 para encontrar o nome correto
$global:AdapterName = "Wi-Fi"  # Exemplos: "Ethernet", "Wi-Fi", "Conexão Local"

# IP adicional que será adicionado para o OpenKore
$global:ExtraIP = "172.65.175.254"

# Prefixo do IP adicional (32 = máscara 255.255.255.255)
$global:ExtraPrefix = 32

# Configurações avançadas (normalmente não precisam ser alteradas)
$global:PingTimeoutSeconds = 5
$global:NetworkStabilizeSeconds = 2
$global:DHCPWaitSeconds = 5

Write-Host "✅ Configurações carregadas:" -ForegroundColor Green
Write-Host "   Adaptador: $global:AdapterName" -ForegroundColor White
Write-Host "   IP Extra: $global:ExtraIP/$global:ExtraPrefix" -ForegroundColor White 