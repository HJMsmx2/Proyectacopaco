#!/bin/bash
# Script de configuración desde la máquina local hacia la máquina Server

# Variables
USERsv1="usuario"
PASSsv1="usuario"
PASSsv2="melon"
SVIP0=$1                  # IP actual del servidor
SVIP1="192.168.237.2"     # IP fija para enp1s0
SVIP2="192.168.1.2"       # IP fija para enp2s0

# ------------------------------------------------------------------
# Parte local
# ------------------------------------------------------------------

echo "[+] Actualizando repositorios localmente..."
echo "$PASSsv1" | sudo -S apt update

echo "[+] Instalando sshpass y ansible..."
echo "$PASSsv1" | sudo -S apt install -y sshpass ansible

# ------------------------------------------------------------------
# Parte remota (Server)
# ------------------------------------------------------------------

echo "[+] Generando configuración de red..."
NETPLAN_CONFIG=$(cat <<EOF_NETPLAN
network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: false
      addresses:
        - $SVIP1/22
    enp2s0:
      dhcp4: false
      addresses:
        - $SVIP2/24
      routes:
        - to: default
          via: 192.168.236.1
      nameservers:
        addresses: [192.168.236.1]
EOF_NETPLAN
)

echo "[+] Conectando y configurando la máquina Server ($SVIP0)..."

sshpass -p "$PASSsv1" ssh -o StrictHostKeyChecking=no "$USERsv1@$SVIP0" bash << EOF
echo "$PASSsv1" | sudo -S bash -c '
    echo "[+] Cambiando contraseña de root..."
    echo "root:$PASSsv2" | chpasswd

    echo "[+] Cambiando hostname a Server..."
    hostnamectl set-hostname Server

    echo "[+] Habilitando acceso root por SSH..."
    sed -i "s/^#\\?PermitRootLogin .*/PermitRootLogin yes/" /etc/ssh/sshd_config
    systemctl restart ssh

    if [ ! -f /etc/netplan/50-cloud-init.yaml.bkup ]; then
        echo "[+] Haciendo copia de seguridad de Netplan..."
        cp /etc/netplan/50-cloud-init.yaml /etc/netplan/50-cloud-init.yaml.bkup
    else
        echo "[i] Backup de Netplan ya existe, no se sobrescribe."
    fi

    echo "[+] Reescribiendo Netplan..."
    cat > /etc/netplan/50-cloud-init.yaml << 'EONET'
$NETPLAN_CONFIG
EONET

    echo "[+] Aplicando nueva configuración de red en segundo plano..."
    nohup bash -c "sleep 2 && netplan apply" > /dev/null 2>&1 &

    echo "[✔] Configuración aplicada. Cerrando sesión."
    exit
'
EOF

# ------------------------------------------------------------------
# Postconfiguración
# ------------------------------------------------------------------

echo "[✔] Script ejecutado correctamente. La máquina Server ya está configurada."

# Clave pública SSH
if [[ -f ~/.ssh/id_rsa.pub ]]; then
    read -p "[?] Ya existe una clave SSH en ~/.ssh/id_rsa.pub. ¿Deseas sobrescribirla? (s/n): " RESP
    if [[ "$RESP" == "s" || "$RESP" == "S" ]]; then
        echo "[+] Eliminando clave SSH antigua..."
        rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
        echo "[+] Generando nueva clave SSH..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    else
        echo "[i] Se usará la clave SSH existente."
    fi
else
    echo "[+] Generando clave SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

echo "[...] Esperando a que la máquina Server esté disponible en $SVIP1..."
for i in {1..10}; do
    ping -c 1 "$SVIP1" > /dev/null 2>&1 && break
    echo "Esperando... ($SVIP1)"
    sleep 3
done

echo "[+] Copiando clave SSH al root del servidor..."
sshpass -p "$PASSsv2" ssh-copy-id root@"$SVIP1"

echo "[+] Comprobando conexión SSH como root..."
ssh root@"$SVIP1"
