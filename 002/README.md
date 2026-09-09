# 🐉 Kali Universal Master

### Version 1.1 — VPS • VirtualBox • WSL

**Kali Universal Master** est un script Bash permettant de préparer automatiquement une nouvelle installation de **Kali Linux** selon l'environnement dans lequel elle fonctionne.

L'objectif du projet est volontairement simple :

> **Une Kali fraîche → une commande → un environnement propre, configuré et prêt à travailler.**

La version **1.1** prend officiellement en charge :

```text
☁️  Kali sur VPS
🖥️  Kali dans VirtualBox
🪟  Kali sous Windows Subsystem for Linux
🤖  Détection automatique
```

---

# 📦 Structure du projet

```text
kali-universal-master/
│
├── kali-master-v1.1.sh
├── README.md
└── LICENSE
```

La V1 reste volontairement basée sur **un unique script Bash** afin de faciliter :

- son audit ;
- son transfert ;
- sa modification ;
- son utilisation sur une Kali fraîche ;
- sa maintenance.

---

# 🎯 Objectif

Lorsqu'une nouvelle Kali est installée, plusieurs opérations sont généralement répétées :

```text
Installation Kali
       │
       ▼
Mise à jour
       │
       ▼
Installation des outils
       │
       ▼
Configuration système
       │
       ▼
Sécurisation
       │
       ▼
Configuration environnement
       │
       ▼
Machine prête
```

`kali-master-v1.1.sh` automatise cette préparation.

Le script adapte également son comportement à l'environnement utilisé afin de ne pas appliquer une configuration VPS à une VM de laboratoire ou à une instance WSL.

---

# ✨ Nouveautés de la v1.1

La version **1.1** ajoute principalement le support de **Kali sous WSL**.

Elle introduit également :

- `--profile wsl` ;
- détection WSL ;
- distinction partielle WSL2 ;
- amélioration de `--profile auto` ;
- mode `--detect` ;
- gestion plus prudente des environnements inconnus ;
- configuration `/etc/wsl.conf` ;
- activation optionnelle de SSH sous WSL ;
- meilleure séparation des configurations VPS / VirtualBox / WSL.

---

# 🧭 Profils disponibles

Kali Universal Master possède maintenant quatre modes :

```text
                    kali-master-v1.1.sh
                            │
             ┌──────────────┼──────────────┐
             │              │              │
             ▼              ▼              ▼
            VPS         VirtualBox        WSL
             ▲              ▲              ▲
             └──────────────┼──────────────┘
                            │
                           AUTO
```

Commandes correspondantes :

```bash
sudo ./kali-master-v1.1.sh --profile vps
```

```bash
sudo ./kali-master-v1.1.sh --profile virtualbox
```

```bash
sudo ./kali-master-v1.1.sh --profile wsl
```

ou :

```bash
sudo ./kali-master-v1.1.sh --profile auto
```

---

# 🤖 Détection automatique

Le mode :

```bash
sudo ./kali-master-v1.1.sh --profile auto
```

essaie de déterminer l'environnement actuel avant d'appliquer la configuration.

La logique générale est :

```text
Kali
 │
 ├── WSL détecté ?
 │      │
 │      └── OUI → profil WSL
 │
 ├── VirtualBox détecté ?
 │      │
 │      └── OUI → profil VirtualBox
 │
 ├── virtualisation serveur connue ?
 │      │
 │      └── OUI → profil VPS
 │
 └── environnement incertain
        │
        └── arrêt + sélection manuelle
```

Contrairement à la première version, le script évite de considérer automatiquement toute machine inconnue comme un VPS.

Cela réduit le risque d'appliquer accidentellement une configuration serveur à une machine physique ou à un environnement atypique.

---

# 🔎 Mode détection

La v1.1 introduit :

```bash
sudo ./kali-master-v1.1.sh --detect
```

Ce mode identifie l'environnement **sans effectuer le bootstrap complet**.

Exemple :

```text
Kali Universal Master v1.1

Distribution :
Kali GNU/Linux Rolling

Environnement détecté :
wsl

WSL :
2
```

C'est une bonne première commande à exécuter sur une nouvelle machine.

---

# 🔧 Configuration commune

Les trois profils commencent par une base commune.

Le script effectue notamment :

- mise à jour des dépôts APT ;
- `full-upgrade` ;
- installation d'outils essentiels ;
- configuration d'une baseline de sécurité ;
- installation des utilitaires réseau et système.

Parmi les outils installés :

```text
sudo
ca-certificates

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
iproute2
```

---

# 🛡️ Baseline système

Une configuration commune est créée dans :

```text
/etc/sysctl.d/90-kali-master-common.conf
```

Elle active notamment plusieurs protections concernant :

```text
kernel.dmesg_restrict
kernel.kptr_restrict

fs.protected_hardlinks
fs.protected_symlinks
```

Certains environnements virtualisés peuvent empêcher la modification de paramètres kernel.

Dans ce cas, le script affiche un avertissement plutôt que de considérer systématiquement cela comme une erreur fatale.

---

# ☁️ Profil VPS

Utilisation :

```bash
sudo ./kali-master-v1.1.sh --profile vps
```

Le profil VPS est destiné à une Kali hébergée sur une infrastructure distante.

Il privilégie :

> **réduction de la surface réseau + accès SSH sécurisé + administration distante.**

---

## 🔐 SSH

Le profil VPS installe et configure OpenSSH.

Il applique notamment :

```text
PubkeyAuthentication yes

PasswordAuthentication no
KbdInteractiveAuthentication no

MaxAuthTries 3
LoginGraceTime 30
```

Une clé SSH publique doit être fournie.

Exemple :

```bash
sudo \
MASTER_USER=jarvis \
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
./kali-master-v1.1.sh --profile vps
```

---

## 👤 Utilisateur administrateur

Par défaut :

```text
MASTER_USER=kaliadmin
```

Il peut être remplacé :

```bash
sudo \
MASTER_USER=jarvis \
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
./kali-master-v1.1.sh --profile vps
```

Le compte est ajouté au groupe :

```text
sudo
```

et la clé publique est installée dans :

```text
~/.ssh/authorized_keys
```

---

# 🔑 Accès root

Durant le premier bootstrap :

```text
PermitRootLogin prohibit-password
```

est utilisé.

Cela conserve temporairement la possibilité d'un accès root **par clé**, tout en interdisant son authentification par mot de passe.

Avant de fermer la session SSH actuelle, ouvrez **un second terminal**.

Testez :

```bash
ssh kaliadmin@IP_DU_VPS
```

puis :

```bash
sudo -i
```

Une fois l'accès administrateur confirmé, il est recommandé de passer à :

```text
PermitRootLogin no
```

---

# 🔥 Firewall VPS

Le profil VPS utilise **UFW**.

Politique par défaut :

```text
INCOMING
   │
   └── DENY

OUTGOING
   │
   └── ALLOW
```

Le port SSH configuré est explicitement autorisé.

Vérification :

```bash
sudo ufw status verbose
```

---

# 🚫 Fail2ban

Fail2ban est activé pour SSH.

Configuration de base :

```text
Tentatives : 5
Fenêtre    : 10 minutes
Ban        : 1 heure
```

Vérification :

```bash
sudo fail2ban-client status
```

---

# 🌐 Durcissement réseau VPS

Le profil VPS applique également une configuration réseau spécifique dans :

```text
/etc/sysctl.d/91-kali-vps-network.conf
```

Elle concerne notamment :

- ICMP redirects ;
- source routing ;
- reverse-path filtering ;
- SYN cookies.

Ces paramètres ne sont volontairement **pas appliqués de la même manière aux environnements de laboratoire**.

---

# 🖥️ Profil VirtualBox

Utilisation :

```bash
sudo ./kali-master-v1.1.sh --profile virtualbox
```

Ce profil est conçu pour une Kali fonctionnant dans **Oracle VirtualBox**.

Son objectif est différent du VPS :

> conserver une bonne baseline de sécurité sans casser les possibilités de laboratoire réseau.

---

# 📦 VirtualBox Guest

Le script tente d'installer :

```text
virtualbox-guest-x11
virtualbox-guest-utils
virtualbox-guest-dkms
```

L'utilisateur Kali peut également être ajouté aux groupes nécessaires à l'intégration VirtualBox.

---

# 🌐 Réseau VirtualBox

Pour une VM Kali classique :

```text
VirtualBox
│
└── Adapter 1
       │
       └── NAT
```

Pour un laboratoire :

```text
VirtualBox
│
├── Adapter 1
│      └── NAT
│
└── Adapter 2
       └── Internal Network
              ou
           Host-Only
```

Le profil VirtualBox évite volontairement certains paramètres VPS susceptibles de gêner :

- plusieurs interfaces ;
- routage ;
- réseaux internes ;
- topologies de laboratoire.

---

# 🔒 Isolation VirtualBox recommandée

Pour une VM destinée à rester isolée :

```text
Network
└── NAT

Shared Clipboard
└── Disabled

Drag & Drop
└── Disabled

Shared Folders
└── Disabled
```

Activez uniquement les mécanismes d'intégration réellement nécessaires.

La création régulière de **snapshots** est également recommandée.

---

# 🪟 Profil WSL

Nouveauté principale de la **v1.1** :

```bash
sudo ./kali-master-v1.1.sh --profile wsl
```

Ce profil est destiné à Kali fonctionnant sous :

**Windows Subsystem for Linux**.

---

# 🔍 Détection WSL

Le script recherche notamment :

```text
WSL_INTEROP
```

ainsi que des signatures Microsoft/WSL dans :

```text
/proc/version
```

et :

```text
/proc/sys/kernel/osrelease
```

Le script essaie également d'identifier WSL2 lorsqu'une signature suffisamment explicite est disponible.

---

# ⚙️ Configuration WSL

Le profil installe notamment :

```text
procps
psmisc

iputils-ping
traceroute

dnsutils
net-tools
iproute2

socat
openssh-client
```

Les composants propres à VirtualBox sont naturellement ignorés.

---

# 🧠 systemd sous WSL

Lorsque `/etc/wsl.conf` n'existe pas, le script crée :

```ini
[boot]
systemd=true

[interop]
enabled=true
appendWindowsPath=true
```

Le script **n'écrase pas automatiquement un `/etc/wsl.conf` existant**.

Cela évite de supprimer une configuration WSL personnalisée.

---

# 🔄 Redémarrer WSL

Après une modification de `/etc/wsl.conf`, fermez vos sessions WSL.

Depuis **PowerShell ou Windows Terminal**, exécutez :

```powershell
wsl --shutdown
```

Puis relancez Kali.

---

# 🔥 Firewall sous WSL

Le profil WSL **n'active pas UFW automatiquement**.

WSL possède une architecture réseau différente d'une VM ou d'un VPS traditionnel, et la sécurité réseau doit également être considérée au niveau de l'hôte Windows.

Le script évite donc d'imposer une politique firewall Linux susceptible de donner une fausse impression d'isolation complète.

---

# 🔐 SSH sous WSL

SSH serveur est désactivé par défaut.

Pour l'activer explicitement :

```bash
sudo \
ENABLE_SSH=true \
./kali-master-v1.1.sh --profile wsl
```

Le script installe alors :

```text
openssh-server
```

et crée une configuration SSH adaptée au profil WSL.

Dans la majorité des utilisations locales de Kali WSL, un serveur SSH n'est cependant pas nécessaire.

---

# ⚙️ Variables disponibles

## MASTER_USER

Utilisateur administrateur VPS :

```text
MASTER_USER=kaliadmin
```

Exemple :

```bash
MASTER_USER=jarvis
```

---

## SSH_PUBLIC_KEY

Clé publique SSH :

```bash
SSH_PUBLIC_KEY="ssh-ed25519 AAAA..."
```

Exemple pratique :

```bash
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)"
```

---

## SSH_PORT

Port par défaut :

```text
SSH_PORT=22
```

Pour utiliser par exemple `2222` :

```bash
SSH_PORT=2222
```

---

## ENABLE_SSH

Valeurs :

```text
ENABLE_SSH=auto
ENABLE_SSH=true
ENABLE_SSH=false
```

Comportement par défaut :

| Profil     | SSH avec `auto` |
| ---------- | --------------- |
| VPS        | Activé          |
| VirtualBox | Désactivé       |
| WSL        | Désactivé       |

---

# 🚀 Exemples rapides

### Détecter l'environnement

```bash
sudo ./kali-master-v1.1.sh --detect
```

### VPS

```bash
sudo \
MASTER_USER=jarvis \
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
./kali-master-v1.1.sh --profile vps
```

### VirtualBox

```bash
sudo ./kali-master-v1.1.sh --profile virtualbox
```

### WSL

```bash
sudo ./kali-master-v1.1.sh --profile wsl
```

### Automatique

```bash
sudo ./kali-master-v1.1.sh --profile auto
```

---

# 🩺 Vérifications après installation

## Environnement

```bash
systemd-detect-virt
```

## Services réseau

```bash
sudo ss -tulpn
```

## SSH

```bash
sudo sshd -t
```

## Firewall

Sur VPS / VirtualBox :

```bash
sudo ufw status verbose
```

## Fail2ban

Sur VPS :

```bash
sudo fail2ban-client status
```

## Kernel

```bash
sysctl kernel.dmesg_restrict
```

---

# ⚠️ Sécurité

Le script modifie potentiellement :

```text
SSH
Firewall
Utilisateurs
Services systemd
Paramètres kernel
Configuration WSL
Configuration réseau
```

Il est recommandé de **lire le script avant de l'exécuter**.

Sur VPS, conservez la console de récupération de votre hébergeur disponible pendant le premier bootstrap.

Sur VirtualBox, créez un snapshot avant une modification importante.

Sur WSL, gardez à l'esprit que Kali partage une partie de son environnement avec Windows et ne constitue pas une frontière d'isolation équivalente à une machine physique distante.

---

# 🧪 Philosophie du projet

Kali Universal Master cherche à rester :

```text
Simple
  +
Lisible
  +
Reproductible
  +
Auditable
  +
Modifiable
```

La V1 évite volontairement une architecture complexe.

L'idée est qu'un administrateur puisse ouvrir :

```text
kali-master-v1.1.sh
```

et comprendre directement ce que le script va modifier.

---

# 🗺️ Roadmap — Version 2

La future **Kali Universal Master V2** conservera la même simplicité d'utilisation :

```bash
sudo ./kali-master.sh --profile auto
```

mais ajoutera une architecture plus robuste.

Objectifs envisagés :

```text
Kali Universal Master V2
│
├── Profils
│   ├── VPS
│   ├── VirtualBox
│   └── WSL
│
├── Sécurité
│   ├── nftables
│   ├── WireGuard
│   └── SSH avancé
│
├── Fiabilité
│   ├── backup automatique
│   ├── rollback
│   └── validation configuration
│
├── Exploitation
│   ├── --dry-run
│   ├── logs
│   └── rapport final
│
└── Reconstruction
    ├── export configuration
    └── rebuild
```

La philosophie restera :

> **Une commande simple en façade, une configuration robuste derrière.**

---

# 📌 Version

```text
Projet       : Kali Universal Master
Version      : 1.1
Plateforme   : Kali Linux

Profils :
  - VPS
  - VirtualBox
  - WSL
  - Auto

Mode :
  - --detect
```

---

# ⚖️ Utilisation responsable

Kali Linux contient des outils destinés à l'administration, au diagnostic, à l'audit et à la cybersécurité.

Utilisez les fonctionnalités de sécurité uniquement sur des systèmes, machines et réseaux que vous possédez ou pour lesquels vous disposez d'une autorisation explicite.

---

# 🐉 Kali Universal Master v1.1

### VPS • VirtualBox • WSL

**Bootstrap • Hardening • Reproductibilité**

> _Build once. Deploy clean._
