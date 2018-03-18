#!/bin/sh
# IP del servidor SQUID
SQUID_SERVER="192.168.0.2"
# Interface conectada a Internet
INTERNET="enp0s8"
# Interface interna
LAN_IN="enp0s3"
# Puerto Squid
SQUID_PORT="3128"

# Limpia las reglas anteriores
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
# Carga los modulos IPTABLES para NAT e IP con soporte conntrack
modprobe ip_conntrack
modprobe ip_conntrack_ftp
echo 1 > /proc/sys/net/ipv4/ip_forward
# Politica de filtro por defecto
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
# Acceso ilimitado a loop back
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# Permite UDP, DNS y FTP pasivo
iptables -A INPUT -i $INTERNET -m state --state ESTABLISHED,RELATED -j ACCEPT
# Establece el servidor como router para la red
iptables --table nat --append POSTROUTING --out-interface $INTERNET -j MASQUERADE
iptables --append FORWARD --in-interface $LAN_IN -j ACCEPT
# acceso ilimiato a la LAN
iptables -A INPUT -i $LAN_IN -j ACCEPT
iptables -A OUTPUT -o $LAN_IN -j ACCEPT
# Redirige las peticiones de la red interna hacia el proxy
iptables -t nat -A PREROUTING -i $LAN_IN -p tcp --dport 80 -j DNAT --to $SQUID_SERVER:$SQUID_PORT
# Redirige la entrada al proxy
iptables -t nat -A PREROUTING -i $INTERNET -p tcp --dport 80 -j REDIRECT --to-port $SQUID_PORT
# Registrar todo
iptables -A INPUT -j LOG
iptables -A INPUT -j DROP