--------------------------------------------------------------------
Script para el cliente 

#!/bin/bash

# Definir las variables
usuario="root"
ip="192.168.238.136"
remoto_usuario="usuario"  # El nombre del usuario al que quieres cambiar después de entrar en la máquina remota
directorio_ansible="/home/usuario/ansible_cliente"  # La ruta donde se encuentra ansible_cliente

# Ejecutar el script en la máquina remota
ssh $usuario@$ip << EOF
    echo "Conectado a $ip como $usuario"

    # Cambiar al usuario especificado
    su - $remoto_usuario -c "
        echo 'Ejecutando playbook en $remoto_usuario...'

        # Verificar si el directorio ansible_cliente existe
        if [ -d '$directorio_ansible' ]; then
            cd '$directorio_ansible'
            ansible-playbook -i hosts playbook.yml
        else
            echo 'Directorio ansible_cliente no encontrado'
        fi
    "
EOF
--------------------------------------------------------------------
