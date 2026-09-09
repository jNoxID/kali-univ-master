#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# ============================================================
# Kali Linux Universal Master
# Profils :
#   --profile auto
#   --profile vps
#   --profile virtualbox
#
# Exemples :
#
# VPS :
#   sudo MASTER_USER=jarvis \
#     SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
#     ./kali-master.sh --profile vps
#
# VirtualBox :
#   sudo ./kali-master.sh --profile virtualbox
#
# Auto :
#   sudo ./kali-master.sh --profile auto
#
# Variables facultatives :
#   MASTER_USER=kaliadmin
#   SSH_PUBLIC_KEY="ssh-ed25519 AAAA..."
#   SSH_PORT=22
#   ENABLE_SSH=true|false
# ============================================================

PROFILE="auto"

MASTER_USER="${MASTER_USER:-kaliadmin}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"
SSH_PORT="${SSH_PORT:-22}"
ENABLE_SSH="${ENABLE_SSH:-auto}"

BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'

log() {
    printf "\n${BLUE}[MASTER]${NC} %s\n" "$*"
}

ok() {
    printf "${GREEN}[OK]${NC} %s\n" "$*"
}

warn() {
    printf "${YELLOW}[ATTENTION]${NC} %s\n" "$*"
}

die() {
    printf "${RED}[ERREUR]${NC} %s\n" "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage:
  $0 --profile auto
  $0 --profile vps
  $0 --profile virtualbox

Options:
  --profile PROFILE
  -h, --help

Profils disponibles:
  auto         Détection automatique
  vps          Kali sur VPS
  virtualbox   Kali dans Oracle VirtualBox
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --profile)
            PROFILE="${2:-}"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Option inconnue : $1"
            ;;
    esac
done

[[ "$EUID" -eq 0 ]] || die "Exécute ce script avec sudo ou en root."

[[ -r /etc/os-release ]] || die "/etc/os-release introuvable."

. /etc/os-release

log "Distribution : ${PRETTY_NAME:-inconnue}"

# ============================================================
# Détection environnement
# ============================================================

detect_environment() {

    local virt="none"

    if command -v systemd-detect-virt >/dev/null 2>&1; then
        virt="$(systemd-detect-virt 2>/dev/null || true)"
    fi

    case "$virt" in
        oracle)
            echo "virtualbox"
            ;;
        *)
            echo "vps"
            ;;
    esac
}

if [[ "$PROFILE" == "auto" ]]; then
    PROFILE="$(detect_environment)"
    log "Profil détecté automatiquement : $PROFILE"
fi

case "$PROFILE" in
    vps|virtualbox)
        ;;
    *)
        die "Profil invalide : $PROFILE"
        ;;
esac

# ============================================================
# Préparation système
# ============================================================

export DEBIAN_FRONTEND=noninteractive

log "Mise à jour du système"

apt-get update
apt-get -y full-upgrade

log "Installation des paquets communs"

apt-get install -y \
    sudo \
    ca-certificates \
    curl \
    wget \
    git \
    jq \
    rsync \
    vim \
    nano \
    tmux \
    htop \
    tree \
    unzip \
    zip \
    gnupg \
    lsof \
    net-tools \
    dnsutils \
    chrony

systemctl enable --now chrony 2>/dev/null || true

# ============================================================
# Fonctions communes
# ============================================================

configure_basic_sysctl() {

    log "Application des protections kernel communes"

    cat > /etc/sysctl.d/90-kali-master-common.conf <<'EOF'
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.protected_fifos = 1
fs.protected_regular = 2
EOF

    sysctl --system >/dev/null
}

configure_updates() {

    log "Configuration des mises à jour automatiques"

    apt-get install -y unattended-upgrades

    cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF
}

create_admin_user() {

    if id "$MASTER_USER" >/dev/null 2>&1; then
        ok "Utilisateur $MASTER_USER déjà présent."
    else
        log "Création de l'utilisateur $MASTER_USER"

        useradd \
            --create-home \
            --shell /bin/bash \
            "$MASTER_USER"

        passwd -l "$MASTER_USER" >/dev/null 2>&1 || true
    fi

    usermod -aG sudo "$MASTER_USER"

    if [[ -n "$SSH_PUBLIC_KEY" ]]; then

        local home_dir
        home_dir="$(getent passwd "$MASTER_USER" | cut -d: -f6)"

        install -d \
            -m 700 \
            -o "$MASTER_USER" \
            -g "$MASTER_USER" \
            "$home_dir/.ssh"

        printf '%s\n' "$SSH_PUBLIC_KEY" \
            > "$home_dir/.ssh/authorized_keys"

        chown "$MASTER_USER:$MASTER_USER" \
            "$home_dir/.ssh/authorized_keys"

        chmod 600 \
            "$home_dir/.ssh/authorized_keys"

        ok "Clé SSH installée pour $MASTER_USER."
    fi
}

# ============================================================
# Profil VPS
# ============================================================

configure_vps() {

    log "Configuration profil VPS"

    apt-get install -y \
        openssh-server \
        ufw \
        fail2ban

    create_admin_user

    # --------------------------------------------------------
    # SSH
    # --------------------------------------------------------

    if [[ "$ENABLE_SSH" == "auto" ]]; then
        ENABLE_SSH="true"
    fi

    if [[ "$ENABLE_SSH" == "true" ]]; then

        [[ -n "$SSH_PUBLIC_KEY" ]] || \
            die "Profil VPS : SSH_PUBLIC_KEY doit être fournie avant de désactiver les mots de passe."

        log "Durcissement OpenSSH"

        mkdir -p /etc/ssh/sshd_config.d

        cat > /etc/ssh/sshd_config.d/90-kali-vps.conf <<EOF
Port ${SSH_PORT}

PubkeyAuthentication yes

PasswordAuthentication no
KbdInteractiveAuthentication no
PermitEmptyPasswords no

PermitRootLogin prohibit-password

X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding yes

MaxAuthTries 3
LoginGraceTime 30

ClientAliveInterval 300
ClientAliveCountMax 2

AllowUsers ${MASTER_USER}
EOF

        sshd -t || die "La configuration SSH générée est invalide."

        systemctl enable ssh
    fi

    # --------------------------------------------------------
    # Pare-feu
    # --------------------------------------------------------

    log "Configuration UFW"

    ufw --force reset

    ufw default deny incoming
    ufw default allow outgoing

    if [[ "$ENABLE_SSH" == "true" ]]; then
        ufw allow "${SSH_PORT}/tcp" comment "SSH"
    fi

    ufw --force enable

    # --------------------------------------------------------
    # Fail2ban
    # --------------------------------------------------------

    if [[ "$ENABLE_SSH" == "true" ]]; then

        log "Configuration Fail2ban"

        cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[sshd]
enabled = true
port = ${SSH_PORT}
maxretry = 5
findtime = 10m
bantime = 1h
EOF

        systemctl enable --now fail2ban
    fi

    # --------------------------------------------------------
    # sysctl VPS
    # --------------------------------------------------------

    log "Durcissement réseau VPS"

    cat > /etc/sysctl.d/91-kali-vps-network.conf <<'EOF'
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0

net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0

net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

net.ipv4.tcp_syncookies = 1
EOF

    sysctl --system >/dev/null

    if [[ "$ENABLE_SSH" == "true" ]]; then
        sshd -t
        systemctl reload ssh
    fi

    ok "Profil VPS terminé."
}

# ============================================================
# Profil VirtualBox
# ============================================================

configure_virtualbox() {

    log "Configuration profil VirtualBox"

    # --------------------------------------------------------
    # Guest Additions
    # --------------------------------------------------------

    log "Installation des composants VirtualBox"

    apt-get install -y \
        virtualbox-guest-x11 \
        virtualbox-guest-utils \
        virtualbox-guest-dkms || \
        warn "Certains paquets VirtualBox n'ont pas pu être installés."

    # --------------------------------------------------------
    # Utilisateur
    # --------------------------------------------------------

    local normal_user=""

    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        normal_user="$SUDO_USER"
    elif id kali >/dev/null 2>&1; then
        normal_user="kali"
    fi

    if [[ -n "$normal_user" ]]; then

        log "Préparation de l'utilisateur $normal_user"

        usermod -aG \
            vboxsf,audio,video,plugdev \
            "$normal_user" 2>/dev/null || true
    fi

    # --------------------------------------------------------
    # SSH facultatif
    # --------------------------------------------------------

    if [[ "$ENABLE_SSH" == "auto" ]]; then
        ENABLE_SSH="false"
    fi

    if [[ "$ENABLE_SSH" == "true" ]]; then

        log "Activation SSH pour la VM"

        apt-get install -y openssh-server

        mkdir -p /etc/ssh/sshd_config.d

        cat > /etc/ssh/sshd_config.d/90-kali-vbox.conf <<EOF
Port ${SSH_PORT}

PermitRootLogin no

PubkeyAuthentication yes
PasswordAuthentication yes

MaxAuthTries 5
LoginGraceTime 60
EOF

        sshd -t
        systemctl enable --now ssh

    else
        log "SSH désactivé par défaut sur VirtualBox"

        systemctl disable --now ssh 2>/dev/null || true
    fi

    # --------------------------------------------------------
    # Firewall léger
    # --------------------------------------------------------

    apt-get install -y ufw

    log "Configuration firewall adaptée au lab"

    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing

    if [[ "$ENABLE_SSH" == "true" ]]; then
        ufw allow "${SSH_PORT}/tcp"
    fi

    ufw --force enable

    # --------------------------------------------------------
    # sysctl VM
    # --------------------------------------------------------

    # On évite volontairement rp_filter=1 et les paramètres
    # pouvant gêner le routage ou les interfaces multiples.

    cat > /etc/sysctl.d/91-kali-virtualbox.conf <<'EOF'
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

    sysctl --system >/dev/null

    # --------------------------------------------------------
    # Nettoyage
    # --------------------------------------------------------

    apt-get autoremove -y
    apt-get clean

    ok "Profil VirtualBox terminé."

    echo
    echo "Conseil VirtualBox :"
    echo
    echo "  Réseau principal : NAT"
    echo "  Presse-papiers   : désactivé si isolation maximale"
    echo "  Drag & Drop       : désactivé"
    echo "  Shared folders    : désactivés"
    echo
    echo "Pour les labs réseau, ajoute une seconde interface"
    echo "Host-Only ou Internal Network selon les besoins."
}

# ============================================================
# Exécution
# ============================================================

configure_basic_sysctl
configure_updates

case "$PROFILE" in
    vps)
        configure_vps
        ;;
    virtualbox)
        configure_virtualbox
        ;;
esac

echo
echo "============================================================"
echo " KALI MASTER TERMINÉ"
echo "============================================================"
echo
echo "Profil : $PROFILE"
echo

if [[ "$PROFILE" == "vps" ]]; then

    echo "IMPORTANT : ne ferme pas ta session actuelle."
    echo
    echo "Teste d'abord une seconde connexion :"
    echo
    echo "  ssh -p $SSH_PORT $MASTER_USER@IP_DU_VPS"
    echo
    echo "Puis :"
    echo
    echo "  sudo -i"
    echo
    echo "Après validation, tu peux remplacer :"
    echo
    echo "  PermitRootLogin prohibit-password"
    echo
    echo "par :"
    echo
    echo "  PermitRootLogin no"
    echo
fi

echo
echo "Redémarrage recommandé :"
echo
echo "  sudo reboot"
echo