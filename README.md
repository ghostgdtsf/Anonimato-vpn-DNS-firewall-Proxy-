
Aqui estão os requisitos para usar o script setup-anon-auto.sh corretamente:


---

✅ Requisitos do sistema

🖥️ Sistema Operacional

Linux Debian-based (como Ubuntu, Debian, Linux Mint)

Arquitetura compatível com os pacotes (amd64, arm64, etc.)



---

📦 Pacotes e dependências

O script instala automaticamente os seguintes pacotes, mas o sistema precisa permitir isso:

wireguard

tor

dnscrypt-proxy

iptables

netcat

nmap

curl

dialog


> Importante: o sistema precisa estar conectado à internet para que os pacotes sejam baixados com sucesso via apt.




---

🔑 Configuração necessária do usuário

Privilégios de superusuário (root):
O script precisa ser executado com sudo para realizar alterações no sistema (instalação de pacotes, regras de firewall, criação de serviços, etc.).

Chaves e dados da VPN:
Você precisará editar manualmente o arquivo /etc/wireguard/wg0.conf gerado pelo script com:

Sua chave privada (PrivateKey)

A chave pública do servidor VPN (PublicKey)

O endereço do servidor (Endpoint)




---

🧠 Conhecimentos recomendados (opcional)

Embora o script automatize tudo, é útil ter noções básicas de:

Terminal Linux

Uso de VPNs (WireGuard)

Conceitos de firewall e segurança de rede

Tor e ProxyChains



---

⚠️ Outros requisitos e observações

O serviço systemd deve estar presente e funcional, já que o script cria serviços para rotação automática da VPN.

Evite executar em sistemas com regras personalizadas de firewall já existentes, pois o script sobrescreve as regras.

O menu só funciona corretamente com dialog instalado (o script o instala).

🖥️ Como funciona o setup-anon-auto.sh no terminal

✅ 1. Preparação e execução

Antes de tudo, torne o script executável e rode como administrador:

chmod +x setup-anon-auto.sh
sudo ./setup-anon-auto.sh

Isso inicia a instalação e configuração automática de todas as ferramentas necessárias.


---

🔧 2. O que o script faz

Atualiza o sistema:
Executa apt update && upgrade.

Instala pacotes essenciais:
WireGuard (VPN), Tor, dnscrypt-proxy, iptables, dialog, entre outros.

Configura o WireGuard:
Cria /etc/wireguard/wg0.conf com configurações padrão (você deve ajustar as chaves e endpoint conforme sua VPN).

Ativa e inicia Tor:
Edita /etc/tor/torrc e inicia o serviço.

Ajusta ProxyChains:
Torna o tráfego socks5 pela porta 9050 (Tor).

Cria firewall kill switch:
Garante que só há tráfego permitido pela VPN, Tor e DNS local.

Cria rotação automática de IP com WireGuard:
Um serviço reinicia a VPN a cada 10 minutos para trocar o IP.

Gera menu interativo:
Cria um menu em modo texto com opções de controle direto.



---

🧭 3. Como usar após instalação

Para acessar o menu principal:

sudo /usr/local/bin/anon-menu.sh

No menu, você verá:

1. Ativar VPN WireGuard
2. Desativar VPN WireGuard
3. Iniciar Tor
4. Parar Tor
5. Ativar firewall
6. Desativar firewall
7. Mostrar status
8. Sair

Navegue com as setas, escolha uma opção com Enter. O status mostra o estado da VPN, do Tor e das regras do firewall.


---

🛑 Dica importante

Antes de usar, edite o arquivo /etc/wireguard/wg0.conf com sua chave privada e dados do servidor VPN. O script fornece um modelo padrão.



---

📌 Conclusão

O setup-anon-auto.sh transforma seu sistema Linux em um ambiente anônimo e seguro com um único comando. Ideal para privacidade máxima com controle simples e direto no terminal.
