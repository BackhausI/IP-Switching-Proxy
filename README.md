IP Switching Proxy
O que é isso?

É uma ferramenta para trocar rapidamente a configuração de rede do seu PC. Ela ajuda a melhorar a conexão com servidores de jogos online (como Ragnarok Online), alternando entre um modo normal e um modo "proxy" que muda o IP para reduzir lag e contornar bloqueios.
Como funciona de forma básica?

Modo Normal: Seu IP é automático (fornecido pelo roteador).
Modo Proxy: Adiciona um IP extra (172.65.175.254) para otimizar a rota da conexão, mantendo o IP original como fixo.

A ferramenta usa scripts simples (.bat e PowerShell) para fazer isso automaticamente, sem precisar configurar tudo manualmente.
Como usar (passos simples para o usuário):

Baixe os scripts do repositório.
Execute o arquivo .bat principal como administrador.
O script verifica sua rede atual:

Se o IP extra já estiver ativo, ele remove e volta ao normal (DHCP).
Se não estiver, ele fixa seu IP atual e adiciona o IP extra para o modo proxy.


Ele testa a conexão (com ping) para confirmar se melhorou (alvo: lag <1ms).
Se der erro, volta automaticamente ao modo normal.

Dicas rápidas:

Rode no Windows (usa ferramentas nativas como PowerShell).
Para mudar o IP: Basta rodar o script – ele faz tudo!
Benefícios: Menos lag nos jogos, ignora limites baseados em IP ou localização.
Cuidado: Pode afetar outras conexões; teste em uma rede estável.
