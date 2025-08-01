# Homelab Config Backup

Ce projet permet de sauvegarder automatiquement les fichiers de configuration de tous les services de votre homelab vers un dépôt Git centralisé.

## 🎯 Objectif

Synchroniser automatiquement les fichiers de configuration (docker-compose.yml, fichiers de config, etc.) de tous les services de votre homelab vers un serveur central de monitoring, puis les commiter et pousser sur une branche Git dédiée.

## 📁 Structure du projet

```
homelab-config/
├── inventory.ini              # Inventaire Ansible des hôtes
├── playbooks/
│   ├── sync-configs.yml       # Playbook principal de synchronisation
│   ├── test-config-paths.yml  # Playbook de test des chemins
│   └── bootstrap-ansible-user.yml  # Bootstrap des utilisateurs ansible
├── scripts/
│   └── backup-configs.sh      # Script de sauvegarde automatique
└── config/                    # Dossier de destination des configs (créé automatiquement)
    ├── traefik/
    ├── paperless/
    ├── prometheus/
    └── ...
```

## 🔧 Services supportés

| Service | Chemin de configuration | Description |
|---------|------------------------|-------------|
| traefik | `/opt/traefik` | Reverse proxy et load balancer |
| homarr | `/opt/homarr` | Dashboard d'arrangement |
| adguard | `/opt/adguardhome/conf` | Ad blocker et DNS |
| immich | `/opt/immich/docker` | Gestionnaire de photos |
| vaultwarden | `/opt/vaultwarden` | Gestionnaire de mots de passe |
| jellyseer | `/opt/jellyseer` | Interface de recherche pour Jellyfin |
| mealie | `/opt/mealie` | Gestionnaire de recettes |
| grocy | `/opt/grocy` | Gestionnaire de stock |
| arrstack | `/opt/appdata` | Stack des applications *arr |
| paperless | `/mnt/paperless_data` | Gestionnaire de documents |
| prometheus | `/opt/monitoring/prometheus` | Monitoring et métriques |
| mealie_grocy | `/opt/mealie_grocy` | Service combiné |

## 🚀 Installation et configuration

### Prérequis

- **Serveur de monitoring** : Machine Linux avec Ansible installé
- **Hôtes distants** : Accès SSH avec clé publique configurée
- **Utilisateur ansible** : Créé sur chaque hôte avec droits sudo

### 1. Configuration des hôtes distants

#### Créer l'utilisateur ansible sur chaque hôte

```bash
# Sur chaque hôte distant
sudo useradd -m -s /bin/bash ansible
sudo usermod -aG sudo ansible
```

#### Configurer l'accès SSH

```bash
# Sur le serveur de monitoring
ssh-keygen -t rsa -b 4096 -C "ansible@monitoring"

# Copier la clé sur chaque hôte
ssh-copy-id ansible@IP_DU_HOST
```

### 2. Configuration du serveur de monitoring

#### Cloner le projet

```bash
cd /opt/monitoring
git clone <URL_DU_REPO> homelab-config
cd homelab-config
```

#### Configurer l'inventaire

Éditer `inventory.ini` avec les IPs de vos hôtes :

```ini
[homelab]
traefik ansible_host=192.168.99.1
paperless ansible_host=192.168.99.4
prometheus ansible_host=192.168.99.11
# ... autres hôtes
```

#### Tester la connectivité

```bash
# Test de base
ansible all -i inventory.ini -m ping

# Test des chemins de configuration
ansible-playbook -i inventory.ini playbooks/test-config-paths.yml
```

### 3. Configuration de la sauvegarde automatique

#### Installer le script de sauvegarde

```bash
# Copier le script
sudo cp scripts/backup-configs.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-configs.sh

# Créer le fichier de log
sudo touch /var/log/ansible-backup.log
sudo chown root:root /var/log/ansible-backup.log
```

#### Configurer le cron

```bash
# Éditer le crontab de root
sudo crontab -e

# Ajouter la ligne suivante pour une sauvegarde hebdomadaire le dimanche à 2h
0 2 * * 0 /usr/local/bin/backup-configs.sh
```

#### Vérifier la configuration

```bash
# Lister les tâches cron
sudo crontab -l

# Tester le script manuellement
sudo /usr/local/bin/backup-configs.sh
```

## 📋 Utilisation

### Synchronisation manuelle

```bash
# Synchroniser tous les services
ansible-playbook -i inventory.ini playbooks/sync-configs.yml

# Synchroniser un service spécifique
ansible-playbook -i inventory.ini playbooks/sync-configs.yml --limit paperless
```

### Test des chemins

```bash
# Tester tous les chemins
ansible-playbook -i inventory.ini playbooks/test-config-paths.yml

# Tester un hôte spécifique
ansible-playbook -i inventory.ini playbooks/test-config-paths.yml --limit paperless
```

### Vérification des logs

```bash
# Consulter les logs de sauvegarde
tail -f /var/log/ansible-backup.log

# Voir les dernières sauvegardes
ls -la /opt/monitoring/homelab-config/config/
```

## 🔄 Migration vers une nouvelle machine

### 1. Préparer la nouvelle machine

```bash
# Installer Ansible
sudo apt update
sudo apt install ansible git

# Créer le répertoire de destination
sudo mkdir -p /opt/monitoring
sudo chown $USER:$USER /opt/monitoring
```

### 2. Cloner et configurer le projet

```bash
# Cloner le projet
cd /opt/monitoring
git clone <URL_DU_REPO> homelab-config
cd homelab-config

# Vérifier que l'inventaire est correct
cat inventory.ini
```

### 3. Configurer l'accès SSH

```bash
# Générer une nouvelle clé SSH si nécessaire
ssh-keygen -t rsa -b 4096 -C "ansible@nouvelle-machine"

# Copier la clé sur tous les hôtes
for host in $(ansible all -i inventory.ini --list-hosts | grep -v hosts); do
    ssh-copy-id ansible@$host
done
```

### 4. Installer le script de sauvegarde

```bash
# Copier le script
sudo cp scripts/backup-configs.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup-configs.sh

# Créer le fichier de log
sudo touch /var/log/ansible-backup.log
sudo chown root:root /var/log/ansible-backup.log
```

### 5. Configurer le cron

```bash
# Éditer le crontab de root
sudo crontab -e

# Ajouter la tâche hebdomadaire
0 2 * * 0 /usr/local/bin/backup-configs.sh
```

### 6. Tester la configuration

```bash
# Test de connectivité
ansible all -i inventory.ini -m ping

# Test des chemins
ansible-playbook -i inventory.ini playbooks/test-config-paths.yml

# Test de synchronisation
ansible-playbook -i inventory.ini playbooks/sync-configs.yml --limit paperless
```

## 📝 Fichiers de configuration récupérés

Le script récupère automatiquement les fichiers suivants :

- `*.yml` et `*.yaml` (docker-compose, configs)
- `*.toml` (configurations TOML)
- `*.json` (configurations JSON)
- `.env` (variables d'environnement)
- `*.ini` (configurations INI)
- `*.sh` (scripts shell)

### Exclusions automatiques

Les dossiers suivants sont ignorés :
- `data/` (données utilisateur)
- `node_modules/` (dépendances Node.js)
- `vendor/` (dépendances PHP)
- `.git/` (dépôt Git)
- `build/`, `dist/`, `target/` (fichiers de build)
- `@*` (dossiers système comme @Recycle)

## 🔍 Dépannage

### Problèmes de connectivité SSH

```bash
# Tester la connectivité manuellement
ssh ansible@IP_DU_HOST

# Vérifier les clés SSH
ssh-add -l
```

### Problèmes de permissions

```bash
# Vérifier les permissions du script
ls -la /usr/local/bin/backup-configs.sh

# Vérifier les permissions du fichier de log
ls -la /var/log/ansible-backup.log
```

### Problèmes de cron

```bash
# Vérifier que cron fonctionne
sudo systemctl status cron

# Voir les logs de cron
sudo tail -f /var/log/syslog | grep CRON
```

### Problèmes Git

```bash
# Vérifier la configuration Git
cd /opt/monitoring/homelab-config
git status
git remote -v

# Vérifier les permissions du dépôt
ls -la /opt/monitoring/homelab-config/.git/
```

## 📊 Monitoring

### Logs de sauvegarde

```bash
# Suivre les logs en temps réel
tail -f /var/log/ansible-backup.log

# Voir les dernières sauvegardes
grep "Sauvegarde terminée" /var/log/ansible-backup.log | tail -10
```

### Vérification des sauvegardes

```bash
# Lister les services sauvegardés
ls -la /opt/monitoring/homelab-config/config/

# Vérifier le contenu d'un service
ls -la /opt/monitoring/homelab-config/config/paperless/
```

## 🤝 Contribution

Pour ajouter un nouveau service :

1. Ajouter l'entrée dans `inventory.ini`
2. Ajouter le chemin dans `playbooks/sync-configs.yml` (variable `services`)
3. Tester avec `playbooks/test-config-paths.yml`
4. Vérifier la synchronisation

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier LICENSE pour plus de détails.