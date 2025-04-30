--------------------------------------------------------------------
# Script que lance el Ansible para preparar la maquina server 

DIR="/home/usuario"
INVENTORY="$DIR/hosts"
PLAYBOOK=(
    "playbook.yml"
    "playbook1.yml"
    "playbook2.yml"
    "playbook3.yml"
    "playbook4.yml"
    "playbook5.yml"

)


for PLAYBOOK in "${PLAYBOOK[@]}"; do
    echo "Ejecutando $PLAYBOOK..."
    ansible-playbook -i "$INVENTORY" "$DIR/$PLAYBOOK"

done

--------------------------------------------------------------------
