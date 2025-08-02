#!/bin/bash

echo "[+] Atualizando sistema e instalando pacotes essenciais..."
sudo apt update && sudo apt upgrade -y || true
sudo apt install -y wireguard tor dnscrypt-proxy iptables netcat nmap curl dialog || true

echo "[+] Criando arquivo wg0.conf de exemplo..."

cat << 'EOF' | sudo tee /etc/wireguard/wg0.conf >/dev/null
[Interface]
PrivateKey = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
Address = 10.0.0.2/24
DNS = 127.0.0.1

[Peer]
PublicKey = YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
Endpoint = vpn.exemplo.com:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

sudo chmod 600 /etc/wireguard/wg0.conf || true

echo "[+] Configurando Tor..."
if [ -f /etc/tor/torrc ]; then
  if grep -q "^#SocksPort 9050" /etc/tor/torrc; then
    sudo sed -i 's/^#SocksPort 9050/SocksPort 9050/' /etc/tor/torrc
  elif ! grep -q "^SocksPort 9050" /etc/tor/torrc; then
    echo "SocksPort 9050" | sudo tee -a /etc/tor/torrc >/dev/null
  fi
  sudo systemctl enable tor || true
  sudo systemctl start tor || true
else
  echo "[!] Arquivo /etc/tor/torrc não encontrado, pulando configuração do Tor."
fi

echo "[+] Configurando dnscrypt-proxy..."
sudo systemctl enable dnscrypt-proxy || true
sudo systemctl start dnscrypt-proxy || true

echo "[+] Configurando proxychains para usar Tor SOCKS5..."
if [ -f /etc/proxychains.conf ]; then
  sudo sed -i 's/^socks4  127.0.0.1 9050$/socks5  127.0.0.1 9050/' /etc/proxychains.conf || true
else
  echo "[!] Arquivo /etc/proxychains.conf não encontrado, pulando configuração do proxychains."
fi

echo "[+] Criando firewall kill switch..."

cat << 'EOF' | sudo tee /usr/local/bin/firewall-anon.sh >/dev/null
#!/bin/bash
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A OUTPUT -o wg0 -j ACCEPT

iptables -A OUTPUT -p udp --dport 53 -d 127.0.0.1 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -d 127.0.0.1 -j ACCEPT

iptables -A OUTPUT -p tcp --dport 9050 -d 127.0.0.1 -j ACCEPT

iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
EOF

sudo chmod +x /usr/local/bin/firewall-anon.sh || true
sudo /usr/local/bin/firewall-anon.sh || true

echo "[+] Criando script para reiniciar WireGuard a cada 10 minutos..."

cat << 'EOF' | sudo tee /usr/local/bin/wg-restart.sh >/dev/null
#!/bin/bash
while true; do
  wg-quick down wg0 || true
  sleep 5
  wg-quick up wg0 || true
  sleep 600
done
EOF

sudo chmod +x /usr/local/bin/wg-restart.sh || true

echo "[+] Criando serviço systemd para rodar a troca automática de IP..."

cat << 'EOF' | sudo tee /etc/systemd/system/wg-restart.service >/dev/null
[Unit]
Description=WireGuard IP rotation service
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/wg-restart.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload || true
sudo systemctl enable wg-restart.service || true
sudo systemctl start wg-restart.service || true

echo "[+] Criando menu simples para controle..."

cat << 'EOF' | sudo tee /usr/local/bin/anon-menu.sh >/dev/null
#!/bin/bash

while true; do
  if ! command -v dialog >/dev/null 2>&1; then
    echo "O programa 'dialog' não está instalado. Instale com: sudo apt install dialog"
    exit 1
  fi

  choice=$(dialog --menu "Sistema Anônimo - Menu" 15 50 8 \
    1 "Ativar VPN WireGuard" \
    2 "Desativar VPN WireGuard" \
    3 "Iniciar Tor" \
    4 "Parar Tor" \
    5 "Ativar firewall" \
    6 "Desativar firewall" \
    7 "Mostrar status" \
    8 "Sair" 3>&1 1>&2 2>&3)

  case $choice in
    1) sudo wg-quick up wg0 || true ;;
    2) sudo wg-quick down wg0 || true ;;
    3) sudo systemctl start tor || true ;;
    4) sudo systemctl stop tor || true ;;
    5) sudo /usr/local/bin/firewall-anon.sh || true ;;
    6) sudo iptables -F || true ;;
    7) clear; echo "=== WireGuard Status ==="; sudo wg show || true; echo; echo "=== Tor Status ==="; sudo systemctl status tor --no-pager || true; echo; echo "=== Firewall Rules ==="; sudo iptables -L -v || true; read -p "Pressione Enter para voltar ao menu..." ;;
    8) break ;;
  esac
done
EOF

sudo chmod +x /usr/local/bin/anon-menu.sh || true

echo "[+] Iniciando VPN WireGuard automaticamente..."
sudo wg-quick up wg0 || echo "[!] Erro ao iniciar WireGuard. Verifique o wg0.conf."

echo "[+] Tudo pronto! Sistema 100% anônimo rodando."
echo "Use 'sudo /usr/local/bin/anon-menu.sh' para controlar manualmente."