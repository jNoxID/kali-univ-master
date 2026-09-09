# 🐉 Kali Universal Master

**Kali Universal Master** est un script Bash de bootstrap et de durcissement permettant de préparer automatiquement une nouvelle installation de **Kali Linux** selon son environnement.

La V1 prend en charge deux scénarios principaux :

- ☁️ **Kali Linux sur VPS**
- 🖥️ **Kali Linux dans VirtualBox**

Un mode `auto` permet également au script de déterminer automatiquement le profil à appliquer.

---

## 🎯 Objectif

L'objectif est simple :

> Partir d'une installation Kali Linux fraîche et obtenir rapidement un environnement propre, reproductible et raisonnablement sécurisé.

Au lieu de répéter manuellement les mêmes opérations après chaque nouvelle installation, `kali-master.sh` automatise la préparation du système.

---

# ✨ Fonctionnalités

## 🔧 Configuration commune

Quel que soit le profil utilisé, le script effectue notamment :

- mise à jour des dépôts APT ;
- mise à niveau du système ;
- installation d'outils système courants ;
- installation et configuration de `chrony` ;
- configuration des mises à jour automatiques ;
- application d'une baseline de sécurité `sysctl` ;
- durcissement de plusieurs paramètres du kernel et du système de fichiers.

Outils installés notamment :

```text
sudo
curl
wget
git
jq
rsync
vim
nano
tmux
htop
tree
unzip
zip
gnupg
lsof
net-tools
dnsutils
chrony
```

---

# ☁️ Profil VPS

Le profil :

```bash
--profile vps
```

est destiné à une machine Kali Linux hébergée sur un serveur distant.

Il ajoute notamment :

### SSH

- installation d'OpenSSH ;
- authentification par clé publique ;
- désactivation de l'authentification SSH par mot de passe ;
- limitation des tentatives de connexion ;
- création d'un utilisateur administrateur dédié ;
- restriction SSH à cet utilisateur.

Par sécurité, la V1 configure initialement :

```text
PermitRootLogin prohibit-password
```

Cela permet de conserver temporairement un accès root par **clé SSH** pendant la validation du nouvel utilisateur.

Après avoir vérifié le fonctionnement de :

```bash
ssh kaliadmin@IP_DU_VPS
```

puis :

```bash
sudo -i
```

il est recommandé de passer à :

```text
PermitRootLogin no
```

---

### Firewall

Le profil VPS installe et configure **UFW** avec une politique restrictive :

```text
Entrant  → DENY
Sortant  → ALLOW
```

Seul le port SSH configuré est explicitement autorisé par défaut.

---

### Fail2ban

Fail2ban est installé et activé pour surveiller SSH.

Configuration de base :

```text
5 échecs maximum
Fenêtre : 10 minutes
Ban : 1 heure
```

---

### Durcissement réseau

Plusieurs protections `sysctl` sont appliquées, notamment contre :

- les redirections ICMP non souhaitées ;
- le source routing ;
- certaines formes de spoofing ;
- certaines attaques SYN.

Le reverse-path filtering est également activé sur le profil VPS.

---

# 🖥️ Profil VirtualBox

Le profil :

```bash
--profile virtualbox
```

est destiné à une installation Kali Linux fonctionnant dans **Oracle VirtualBox**.

Contrairement au profil VPS, il conserve volontairement davantage de flexibilité réseau afin de ne pas perturber les environnements de laboratoire.

---

## VirtualBox Guest

Le script tente d'installer :

```text
virtualbox-guest-x11
virtualbox-guest-utils
virtualbox-guest-dkms
```

L'utilisateur Kali est également ajouté aux groupes appropriés lorsque cela est possible.

---

## SSH

SSH est **désactivé par défaut** dans le profil VirtualBox.

Il peut néanmoins être explicitement activé.

Cette approche réduit les services réseau inutiles lorsqu'une VM est simplement utilisée depuis la console VirtualBox.

---

## Réseau

Pour une VM standard, la configuration VirtualBox recommandée est :

```text
Adapter 1
└── NAT
```

Pour construire un laboratoire isolé :

```text
Adapter 1
└── NAT

Adapter 2
└── Internal Network / Host-Only
```

Le profil VirtualBox évite volontairement certains réglages réseau stricts du profil VPS pouvant gêner :

- plusieurs interfaces ;
- le routage ;
- les réseaux internes ;
- certains laboratoires de cybersécurité.

---

# 🤖 Détection automatique

Le script dispose également du profil :

```bash
--profile auto
```

Il utilise notamment :

```bash
systemd-detect-virt
```

afin de détecter VirtualBox.

Si VirtualBox est identifié :

```text
auto
 └── virtualbox
```

Sinon :

```text
auto
 └── vps
```

> **Attention :** `auto` est une aide pratique, pas une détection infaillible. Sur un autre hyperviseur ou un environnement atypique, utilisez explicitement `--profile vps` ou `--profile virtualbox`.

---

# 🚀 Installation

Récupérez le fichier :

```text
kali-master.sh
```

puis rendez-le exécutable :

```bash
chmod +x kali-master.sh
```

---

# ☁️ Utilisation sur VPS

Une clé SSH publique est nécessaire pour utiliser le durcissement SSH du profil VPS.

Exemple :

```bash
sudo \
MASTER_USER=jarvis \
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
./kali-master.sh --profile vps
```

Le script va notamment :

```text
mettre à jour Kali
        ↓
installer les dépendances
        ↓
créer l'utilisateur
        ↓
installer la clé SSH
        ↓
durcir SSH
        ↓
configurer UFW
        ↓
configurer Fail2ban
        ↓
appliquer la baseline sysctl
```

---

# 🖥️ Utilisation avec VirtualBox

Depuis la VM Kali :

```bash
sudo ./kali-master.sh --profile virtualbox
```

Puis redémarrez :

```bash
sudo reboot
```

---

# 🤖 Mode automatique

Pour laisser le script choisir :

```bash
sudo ./kali-master.sh --profile auto
```

---

# ⚙️ Variables

Plusieurs paramètres peuvent être transmis via des variables d'environnement.

### Utilisateur administrateur

```bash
MASTER_USER=kaliadmin
```

### Clé SSH

```bash
SSH_PUBLIC_KEY="ssh-ed25519 AAAA..."
```

### Port SSH

Par défaut :

```bash
SSH_PORT=22
```

Exemple :

```bash
SSH_PORT=2222
```

### Activation SSH

Valeurs disponibles :

```text
ENABLE_SSH=auto
ENABLE_SSH=true
ENABLE_SSH=false
```

Sur VPS, `auto` active SSH.

Sur VirtualBox, `auto` le désactive.

---

# 🔐 Recommandations VPS

Ne fermez **jamais la session SSH actuelle immédiatement après le bootstrap**.

Ouvrez un deuxième terminal et vérifiez d'abord :

```bash
ssh -p 22 kaliadmin@IP_DU_VPS
```

Puis :

```bash
sudo -i
```

Une fois l'accès confirmé, le login root SSH peut être complètement désactivé.

---

# 🛡️ Recommandations VirtualBox

Pour augmenter l'isolation d'une VM Kali, envisagez :

```text
Network
    NAT

Shared Clipboard
    Disabled

Drag & Drop
    Disabled

Shared Folders
    Disabled
```

Activez uniquement les fonctions d'intégration dont vous avez réellement besoin.

Avant une modification importante de la VM, créez également un **snapshot VirtualBox**.

---

# ⚠️ Avertissements

Ce script modifie des composants importants du système :

- SSH ;
- firewall ;
- utilisateurs ;
- paramètres kernel ;
- services systemd ;
- configuration réseau de sécurité.

Lisez le script avant son exécution.

Sur un VPS distant, une mauvaise configuration SSH ou firewall peut provoquer une perte d'accès.

Conservez si possible la **console de récupération fournie par l'hébergeur** pendant la première installation.

---

# 🔎 Vérifications après installation

### Firewall

```bash
sudo ufw status verbose
```

### SSH

```bash
sudo sshd -t
```

### Fail2ban

```bash
sudo fail2ban-client status
```

### Chrony

```bash
chronyc tracking
```

### Virtualisation

```bash
systemd-detect-virt
```

### Services en écoute

```bash
sudo ss -tulpn
```

---

# 📁 Structure V1

La première version reste volontairement simple :

```text
kali-universal-master/
│
├── kali-master.sh
├── README.md
└── LICENSE
```

Toute la logique principale est contenue dans un unique script Bash.

Cela facilite son audit, son transfert et son utilisation sur une installation fraîche.

---

# 🗺️ Roadmap

La **V2** conservera cette simplicité d'utilisation tout en améliorant l'architecture interne.

Fonctionnalités envisagées :

```text
Kali Universal Master V2
│
├── VPS
├── VirtualBox
│
├── détection environnement améliorée
├── sauvegarde des configurations
├── --dry-run
├── rollback
│
├── nftables
├── WireGuard
│
├── journalisation
├── rapport de fin d'installation
│
└── restauration / rebuild
```

L'objectif restera le même :

> **Une commande pour transformer une Kali fraîche en environnement prêt à travailler.**

---

# 📌 Version

```text
Kali Universal Master
Version : 1.0
Plateforme : Kali Linux
Profils : VPS / VirtualBox / Auto
```

---

## ⚖️ Utilisation responsable

Kali Linux contient de nombreux outils destinés à l'administration système, à l'audit et à la cybersécurité.

Utilisez ces outils uniquement sur des systèmes, réseaux et infrastructures que vous possédez ou pour lesquels vous disposez d'une autorisation explicite.

---

**Kali Universal Master V1**
_Bootstrap • Hardening • Reproductibilité_
