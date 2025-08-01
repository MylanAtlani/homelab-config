#!/bin/bash

# Script de sauvegarde automatique des configurations
# À exécuter via cron sur le LXC de monitoring

# Variables
ANSIBLE_DIR="/opt/monitoring/homelab-config"
INVENTORY_FILE="$ANSIBLE_DIR/inventory.ini"
PLAYBOOK_FILE="$ANSIBLE_DIR/playbooks/sync-configs.yml"
LOG_FILE="/var/log/ansible-backup.log"

# Fonction de logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Vérifier que les fichiers nécessaires existent
if [ ! -f "$INVENTORY_FILE" ]; then
    log "ERREUR: Fichier inventory.ini introuvable: $INVENTORY_FILE"
    exit 1
fi

if [ ! -f "$PLAYBOOK_FILE" ]; then
    log "ERREUR: Fichier playbook introuvable: $PLAYBOOK_FILE"
    exit 1
fi

# Aller dans le répertoire Ansible
cd "$ANSIBLE_DIR" || {
    log "ERREUR: Impossible de se déplacer dans $ANSIBLE_DIR"
    exit 1
}

log "Début de la synchronisation des configurations"

# Exécuter le playbook Ansible
ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE" --limit homelab >> "$LOG_FILE" 2>&1

# Vérifier le code de retour
if [ $? -eq 0 ]; then
    log "Synchronisation terminée avec succès"
else
    log "ERREUR: Échec de la synchronisation"
    exit 1
fi

log "Script de sauvegarde terminé" 