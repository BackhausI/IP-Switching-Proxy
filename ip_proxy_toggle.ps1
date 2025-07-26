# ===========================================
#     TOGGLE AUTOMATICO DE IP PROXY
#     para OpenKore - Ragnarok Online
# ===========================================
# 
# Este script detecta automaticamente o estado atual
# e alterna entre ATIVAR e DESATIVAR o IP proxy
#

# Carregar configuracoes
if (Test-Path ".\config.ps1") {
    . .\config.ps1
    $adapterName = $global:AdapterName
    $extraIP = $global:ExtraIP
    $extraPrefix = $global:ExtraPrefix
} else {
    # Configuracoes padrao
    $adapterName = "Wi-Fi"
    $extraIP = "172.65.175.254"
    $extraPrefix = 32
}

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Header {
    param([string]$Title, [string]$Color = "Cyan")
    Write-ColorOutput "===========================================" -Color $Color
    Write-ColorOutput "  $Title" -Color $Color
    Write-ColorOutput "===========================================" -Color $Color
}

function Test-ExtraIP {
    param([string]$IP)
    Write-ColorOutput "Testando conectividade com $IP..." -Color "Yellow"
    
    # Aguardar mais tempo inicial para rede estabilizar
    Write-ColorOutput "  Aguardando rede estabilizar completamente..." -Color "Gray"
    Start-Sleep -Seconds 5
    
    # Tentar múltiplas vezes para atingir <1ms
    $maxAttempts = 5
    $bestTime = 999
    
    for ($i = 1; $i -le $maxAttempts; $i++) {
        try {
            Write-ColorOutput "  Tentativa $i/$maxAttempts..." -Color "Gray"
            
            # Usar ping nativo para melhor precisão
            $pingResult = ping $IP -n 1
            $pingOutput = $pingResult -join "`n"
            
            # Extrair tempo de resposta
            if ($pingOutput -match "tempo[<=](\d+)ms" -or $pingOutput -match "time[<=](\d+)ms") {
                $responseTime = [int]$matches[1]
                $bestTime = [Math]::Min($bestTime, $responseTime)
                
                Write-ColorOutput "    Tempo de resposta: ${responseTime}ms" -Color "Cyan"
                
                if ($responseTime -eq 0 -or $pingOutput -match "tempo<1ms" -or $pingOutput -match "time<1ms") {
                    Write-ColorOutput "PERFEITO: Ping para $IP com tempo <1ms!" -Color "Green"
                    $pingResult | Write-Host
                    return $true
                } elseif ($responseTime -eq 1) {
                    Write-ColorOutput "EXCELENTE: Ping para $IP com tempo 1ms!" -Color "Green"
                    $pingResult | Write-Host
                    return $true
                } elseif ($responseTime -le 5) {
                    Write-ColorOutput "BOM: Ping funcionando (${responseTime}ms)" -Color "Yellow"
                    if ($i -eq $maxAttempts) {
                        Write-ColorOutput "IP extra funcionando - Aguarde alguns segundos para otimizar" -Color "Green"
                        $pingResult | Write-Host
                        return $true
                    }
                } else {
                    Write-ColorOutput "    Tempo alto (${responseTime}ms), tentando novamente..." -Color "Yellow"
                }
            } elseif ($pingOutput -match "TTL=") {
                # Ping funcionou mas não conseguiu extrair tempo
                Write-ColorOutput "SUCESSO: Ping para $IP funcionou!" -Color "Green"
                $pingResult | Write-Host
                return $true
            } else {
                Write-ColorOutput "    Sem resposta nesta tentativa" -Color "Gray"
            }
            
            # Aguardar entre tentativas para rede otimizar
            if ($i -lt $maxAttempts) {
                Start-Sleep -Seconds 2
            }
            
        } catch {
            $errorMsg = $_.Exception.Message
            Write-ColorOutput "    Erro na tentativa ${i}: $errorMsg" -Color "Gray"
        }
    }
    
    if ($bestTime -lt 999) {
        Write-ColorOutput "RESULTADO: Melhor tempo obtido: ${bestTime}ms" -Color "Cyan"
        Write-ColorOutput "IP extra esta funcionando - Pode melhorar com o tempo" -Color "Green"
        return $true
    } else {
        Write-ColorOutput "AVISO: Ping nao respondeu apos $maxAttempts tentativas" -Color "Yellow"
        Write-ColorOutput "Isso pode ser normal - teste manualmente: ping $IP" -Color "Yellow"
        return $false
    }
}

function Remove-AllIPsAndRoutes {
    param([string]$AdapterName)
    Write-ColorOutput "Limpando configuracao de rede..." -Color "Yellow"
    
    try {
        Get-NetRoute -InterfaceAlias $AdapterName -ErrorAction SilentlyContinue | Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue
        Get-NetIPAddress -InterfaceAlias $AdapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        Write-ColorOutput "  Limpeza concluida" -Color "Green"
    } catch {
        $errorMsg = $_.Exception.Message
        Write-ColorOutput "  Aviso durante limpeza: $errorMsg" -Color "Yellow"
    }
}

function Set-StaticIP {
    param([string]$AdapterName, [string]$IPAddress, [int]$PrefixLength, [string]$Gateway)
    
    Write-ColorOutput "Configurando IP estatico: $IPAddress/$PrefixLength" -Color "Yellow"
    
    try {
        # Configurar IP principal
        New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $IPAddress -PrefixLength $PrefixLength -ErrorAction Stop | Out-Null
        Write-ColorOutput "  IP principal configurado" -Color "Green"
        
        # Configurar gateway se fornecido
        if ($Gateway -and $Gateway -ne "0.0.0.0") {
            Write-ColorOutput "Configurando gateway: $Gateway" -Color "Yellow"
            try {
                New-NetRoute -InterfaceAlias $AdapterName -DestinationPrefix "0.0.0.0/0" -NextHop $Gateway -RouteMetric 1 -ErrorAction Stop | Out-Null
                Write-ColorOutput "  Gateway configurado" -Color "Green"
            } catch {
                Write-ColorOutput "  Aviso: Gateway nao configurado, continuando..." -Color "Yellow"
            }
        }
        return $true
    } catch {
        $errorMsg = $_.Exception.Message
        Write-ColorOutput "  ERRO: $errorMsg" -Color "Red"
        return $false
    }
}

function Add-ExtraIP {
    param([string]$AdapterName, [string]$ExtraIP, [int]$ExtraPrefix)
    
    Write-ColorOutput "Adicionando IP extra: $ExtraIP/$ExtraPrefix" -Color "Yellow"
    try {
        New-NetIPAddress -InterfaceAlias $AdapterName -IPAddress $ExtraIP -PrefixLength $ExtraPrefix -ErrorAction Stop | Out-Null
        Write-ColorOutput "  IP extra adicionado com sucesso!" -Color "Green"
        return $true
    } catch {
        $errorMsg = $_.Exception.Message
        Write-ColorOutput "  ERRO: $errorMsg" -Color "Red"
        return $false
    }
}

# ===========================================
#            DETECCAO E TOGGLE
# ===========================================

Write-ColorOutput ""
Write-ColorOutput "Detectando estado atual do IP proxy..." -Color "Cyan"
Write-ColorOutput ""

# Verificar se o adaptador existe
try {
    $adapter = Get-NetAdapter -Name $adapterName -ErrorAction Stop
    Write-ColorOutput "Adaptador detectado: $($adapter.Name)" -Color "White"
    Write-ColorOutput "  Tipo: $($adapter.InterfaceDescription)" -Color "Gray"
    Write-ColorOutput "  Status: $($adapter.Status)" -Color "Green"
} catch {
    Write-ColorOutput "ERRO: Adaptador '$adapterName' nao encontrado!" -Color "Red"
    Write-ColorOutput ""
    Write-ColorOutput "Adaptadores disponiveis:" -Color "Yellow"
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        Write-ColorOutput "  - $($_.Name)" -Color "White"
    }
    Write-ColorOutput ""
    Write-ColorOutput "Configure o adaptador correto editando config.ps1" -Color "Yellow"
    exit 1
}

# Verificar se o IP extra esta configurado
Write-ColorOutput ""
Write-ColorOutput "Verificando se IP extra esta ativo..." -Color "Cyan"

$extraIPExists = Get-NetIPAddress -InterfaceAlias $adapterName -IPAddress $extraIP -ErrorAction SilentlyContinue

if ($extraIPExists) {
    # IP EXTRA EXISTE - DESATIVAR
    Write-Header "IP PROXY ATIVO - DESATIVANDO" "Red"
    Write-ColorOutput ""
    Write-ColorOutput "O IP extra $extraIP esta configurado." -Color "White"
    Write-ColorOutput "Voltando para modo DHCP automatico..." -Color "Yellow"
    Write-ColorOutput ""
    
    try {
        Remove-AllIPsAndRoutes -AdapterName $adapterName
        
        Write-ColorOutput "Ativando DHCP..." -Color "Yellow"
        Set-NetIPInterface -InterfaceAlias $adapterName -AddressFamily IPv4 -Dhcp Enabled
        
        Write-ColorOutput ""
        Write-Header "IP PROXY DESATIVADO COM SUCESSO!" "Green"
        Write-ColorOutput ""
        Write-ColorOutput "Aguardando DHCP obter novo IP..." -Color "Yellow"
        
        # Aguardar e verificar se DHCP conseguiu obter IP
        $attempts = 0
        $maxAttempts = 10
        $newIP = $null
        
        while ($attempts -lt $maxAttempts -and -not $newIP) {
            Start-Sleep -Seconds 2
            $attempts++
            Write-ColorOutput "  Tentativa $attempts/$maxAttempts..." -Color "Gray"
            
            try {
                $newIP = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.AddressState -eq "Preferred" }
            } catch {
                # Ignorar erros e continuar tentando
            }
        }
        
        if ($newIP) {
            Write-ColorOutput "Nova configuracao DHCP:" -Color "Cyan"
            Write-ColorOutput "  IP: $($newIP.IPAddress)/$($newIP.PrefixLength)" -Color "White"
            
            # Verificar se é IP APIPA (sem internet)
            if ($newIP.IPAddress -like "169.254.*") {
                Write-ColorOutput ""
                Write-ColorOutput "AVISO: IP APIPA detectado - SEM INTERNET!" -Color "Red"
                Write-ColorOutput "Tentando forcar renovacao DHCP..." -Color "Yellow"
                
                try {
                    # Forçar renovação via ipconfig
                    $result = cmd /c "ipconfig /release `"Wi-Fi`" 2>&1"
                    Start-Sleep -Seconds 2
                    $result = cmd /c "ipconfig /renew `"Wi-Fi`" 2>&1"
                    Start-Sleep -Seconds 3
                    
                    # Verificar novamente
                    $finalIP = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.AddressState -eq "Preferred" }
                    if ($finalIP -and -not ($finalIP.IPAddress -like "169.254.*")) {
                        Write-ColorOutput "SUCESSO: IP valido obtido: $($finalIP.IPAddress)" -Color "Green"
                        Write-ColorOutput "Modo normal ativado - Rede funcionando normalmente" -Color "Green"
                    } else {
                        Write-ColorOutput "PROBLEMA: Execute RESTAURAR_INTERNET.bat!" -Color "Red"
                    }
                } catch {
                    Write-ColorOutput "PROBLEMA: Execute RESTAURAR_INTERNET.bat!" -Color "Red"
                }
            } else {
                Write-ColorOutput ""
                Write-ColorOutput "Modo normal ativado - Rede funcionando normalmente" -Color "Green"
            }
        } else {
            Write-ColorOutput "AVISO: DHCP nao conseguiu obter IP automaticamente!" -Color "Red"
            Write-ColorOutput "Tentando forcar renovacao..." -Color "Yellow"
            
            # Tentar reiniciar o adaptador
            try {
                Restart-NetAdapter -Name $adapterName -ErrorAction Stop
                Start-Sleep -Seconds 3
                Write-ColorOutput "Adaptador reiniciado. Verificando conectividade..." -Color "Yellow"
                
                # Verificar novamente
                $newIP = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object { $_.AddressState -eq "Preferred" }
                if ($newIP) {
                    Write-ColorOutput "SUCESSO: IP obtido apos reinicio do adaptador" -Color "Green"
                    Write-ColorOutput "  IP: $($newIP.IPAddress)/$($newIP.PrefixLength)" -Color "White"
                } else {
                    Write-ColorOutput "PROBLEMA: Execute RESTAURAR_INTERNET.bat para corrigir!" -Color "Red"
                }
            } catch {
                Write-ColorOutput "PROBLEMA: Execute RESTAURAR_INTERNET.bat para corrigir!" -Color "Red"
            }
        }
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-ColorOutput "ERRO durante desativacao: $errorMsg" -Color "Red"
        exit 1
    }
    
} else {
    # IP EXTRA NAO EXISTE - ATIVAR
    Write-Header "IP PROXY INATIVO - ATIVANDO" "Green"
    Write-ColorOutput ""
    Write-ColorOutput "O IP extra $extraIP nao esta configurado." -Color "White"
    Write-ColorOutput "Configurando IP estatico + IP extra..." -Color "Yellow"
    Write-ColorOutput ""
    
    try {
        $ipInterface = Get-NetIPInterface -InterfaceAlias $adapterName -AddressFamily IPv4
        
        if ($ipInterface.Dhcp -eq "Enabled") {
            Write-ColorOutput "Obtendo configuracao DHCP atual..." -Color "Yellow"
            
            $currentIPConfig = Get-NetIPAddress -InterfaceAlias $adapterName -AddressFamily IPv4 | Where-Object { $_.AddressState -eq "Preferred" }
            if (-not $currentIPConfig) {
                Write-ColorOutput "Nao foi possivel obter IP atual!" -Color "Red"
                exit 1
            }
            
            $currentIP = $currentIPConfig.IPAddress
            $currentPrefix = $currentIPConfig.PrefixLength
            $gatewayRoute = Get-NetRoute -InterfaceAlias $adapterName -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue
            $gateway = if ($gatewayRoute) { $gatewayRoute.NextHop } else { $null }
            
            Write-ColorOutput "Configuracao atual detectada:" -Color "Cyan"
            Write-ColorOutput "  IP: $currentIP/$currentPrefix" -Color "White"
            Write-ColorOutput "  Gateway: $gateway" -Color "White"
            Write-ColorOutput ""
            
            # Converter para estatico
            Write-ColorOutput "Convertendo para IP estatico..." -Color "Yellow"
            Set-NetIPInterface -InterfaceAlias $adapterName -AddressFamily IPv4 -Dhcp Disabled
            
            Remove-AllIPsAndRoutes -AdapterName $adapterName
            
            $success = Set-StaticIP -AdapterName $adapterName -IPAddress $currentIP -PrefixLength $currentPrefix -Gateway $gateway
            if (-not $success) {
                Write-ColorOutput "Falha! Restaurando DHCP..." -Color "Red"
                Set-NetIPInterface -InterfaceAlias $adapterName -AddressFamily IPv4 -Dhcp Enabled
                exit 1
            }
            
            Write-ColorOutput "Aguardando estabilizacao..." -Color "Yellow"
            Start-Sleep -Seconds 3
            
            $extraSuccess = Add-ExtraIP -AdapterName $adapterName -ExtraIP $extraIP -ExtraPrefix $extraPrefix
            if ($extraSuccess) {
                Write-ColorOutput ""
                Write-Header "IP PROXY ATIVADO COM SUCESSO!" "Green"
                Write-ColorOutput ""
                Write-ColorOutput "Modo OpenKore ativado - Pronto para jogar!" -Color "Green"
                Write-ColorOutput ""
                
                # Aguardar mais tempo para rede estabilizar completamente
                Write-ColorOutput "Aguardando rede estabilizar para teste otimo..." -Color "Yellow"
                Start-Sleep -Seconds 2
                
                # Testar IP extra
                Test-ExtraIP -IP $extraIP
            } else {
                Write-ColorOutput "IP principal configurado, mas falha no IP extra" -Color "Yellow"
            }
            
        } else {
            # Ja esta em modo estatico, apenas adicionar IP extra
            Write-ColorOutput "Adaptador ja em modo estatico" -Color "Blue"
            $success = Add-ExtraIP -AdapterName $adapterName -ExtraIP $extraIP -ExtraPrefix $extraPrefix
            if ($success) {
                Write-ColorOutput ""
                Write-Header "IP EXTRA ADICIONADO COM SUCESSO!" "Green"
                Write-ColorOutput ""
                
                # Aguardar rede estabilizar antes do teste
                Write-ColorOutput "Aguardando rede estabilizar para teste otimo..." -Color "Yellow"
                Start-Sleep -Seconds 2
                
                Test-ExtraIP -IP $extraIP
            }
        }
        
    } catch {
        $errorMsg = $_.Exception.Message
        Write-ColorOutput "ERRO CRITICO: $errorMsg" -Color "Red"
        Write-ColorOutput "Tentando restaurar DHCP..." -Color "Yellow"
        try {
            Set-NetIPInterface -InterfaceAlias $adapterName -AddressFamily IPv4 -Dhcp Enabled
        } catch {
            # Ignorar erros na restauracao
        }
        exit 1
    }
}

Write-ColorOutput ""
Write-ColorOutput "================================================" -Color "Cyan"
Write-ColorOutput "Para alternar novamente, execute este script!" -Color "Yellow"
Write-ColorOutput "================================================" -Color "Cyan" 