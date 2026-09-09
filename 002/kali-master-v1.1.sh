#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

# ============================================================
# Kali Universal Master
# Version 1.1
#
# Profils :
#   auto
#   vps
#   virtualbox
#   wsl
#
# Usage :
#   sudo ./kali-master-v1.1.sh --profile auto
#   sudo ./kali-master-v1.1.sh --profile vps
#   sudo ./kali-master-v1.1.sh --profile virtualbox
#   sudo ./kali-master-v1.1.sh --profile wsl
#
# Variables :
#   MASTER_USER=kaliadmin
#   SSH_PUBLIC_KEY="ssh-ed25519 AAAA..."
#   SSH_PORT=22
#   ENABLE_SSH=auto|true|false
# ============================================================

VERSION="1.1"
PROFILE="auto"

MASTER_USER="${MASTER_USER:-kaliadmin}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"
SSH_PORT="${SSH_PORT:-22}"
ENABLE_SSH="${ENABLE_SSH:-auto}"

# ------------------------------------------------------------
# Couleurs
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Gestion des erreurs
# ------------------------------------------------------------

on_error() {
    local exit_code=$?
    local line="${BASH_LINENO[0]:-?}"

    printf "\n${RED}[ERREUR]${NC} Échec ligne %s (code %s)\n" \
        "$line" "$exit_code" >&2

    exit "$exit_code"
}

trap on_error ERR

# ------------------------------------------------------------
# Aide
# ------------------------------------------------------------

usage() {
    cat <<EOF

Kali Universal Master v${VERSION}

Usage :
  $0 --profile auto
  $0 --profile vps
  $0 --profile virtualbox
  $0 --profile wsl

Profils :

  auto
      Détection automatique.

  vps
      Kali Linux sur VPS distant.

  virtualbox
      Kali Linux dans Oracle VirtualBox.

  wsl
      Kali Linux sous Windows Subsystem for Linux.

Options :

  --profile PROFILE
  --detect
  -h, --help

Variables facultatives :

  MASTER_USER
  SSH_PUBLIC_KEY
  SSH_PORT
  ENABLE_SSH

EOF
}

# ------------------------------------------------------------
# Arguments
# ------------------------------------------------------------

DETECT_ONLY=false

while [[ $# -gt 0 ]]; do

    case "$1" in

        --profile)

            [[ $# -ge 2 ]] || die "--profile nécessite une valeur."

            PROFILE="$2"
            shift 2
            ;;

        --detect)
            DETECT_ONLY=true
            shift
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

# ------------------------------------------------------------
# Vérifications générales
# ------------------------------------------------------------

[[ "$EUID" -eq 0 ]] || \
    die "Exécute le script avec sudo ou en root."

[[ -r /etc/os-release ]] || \
    die "/etc/os-release introuvable."

. /etc/os-release

log "Kali Universal Master v${VERSION}"
log "Distribution : ${PRETTY_NAME:-inconnue}"

# ============================================================
# Détection environnement
# ============================================================

is_wsl() {

    # Méthode 1 : variable fournie par WSL
    if [[ -n "${WSL_INTEROP:-}" ]]; then
        return 0
    fi

    # Méthode 2 : kernel
    if grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null; then
        return 0
    fi

    # Méthode 3 : release kernel
    if grep -qiE 'microsoft|wsl' /proc/sys/kernel/osrelease 2>/dev/null; then
        return 0
    fi

    return 1
}

detect_wsl_version() {

    if ! is_wsl; then
        echo "none"
        return
    fi

    # WSL2 utilise généralement le kernel Microsoft WSL2.
    if grep -qi 'WSL2' /proc/version 2>/dev/null ||
       grep -qi 'WSL2' /proc/sys/kernel/osrelease 2>/dev/null; then

        echo "2"

    else
        echo "unknown"
    fi
}

detect_environment() {

    if is_wsl; then
        echo "wsl"
        return
    fi

    local virt=""

    if command -v systemd-detect-virt >/dev/null 2>&1; then
        virt="$(systemd-detect-virt 2>/dev/null || true)"
    fi

    case "$virt" in

        oracle)
            echo "virtualbox"
            ;;

        kvm|qemu|xen|vmware|microsoft|amazon|google)
            # Probablement environnement serveur/cloud.
            echo "vps"
            ;;

        none|"")
            # Impossible d'affirmer qu'il s'agit d'un VPS.
            echo "unknown"
            ;;

        *)
            echo "unknown"
            ;;
    esac
}

DETECTED_PROFILE="$(detect_environment)"

log "Environnement détecté : $DETECTED_PROFILE"

if [[ "$DETECTED_PROFILE" == "wsl" ]]; then
    log "Version WSL détectée : $(detect_wsl_version)"
fi

if [[ "$DETECT_ONLY" == "true" ]]; then

    echo
    echo "Environnement : $DETECTED_PROFILE"

    if [[ "$DETECTED_PROFILE" == "wsl" ]]; then
        echo "WSL            : $(detect_wsl_version)"
    fi

    exit 0
fi

# ------------------------------------------------------------
# Mode automatique
# ------------------------------------------------------------

if [[ "$PROFILE" == "auto" ]]; then

    if [[ "$DETECTED_PROFILE" == "unknown" ]]; then

        die "Détection automatique incertaine.
Relance avec :
  --profile vps
  --profile virtualbox
  --profile wsl"

    fi

    PROFILE="$DETECTED_PROFILE"

    log "Profil sélectionné automatiquement : $PROFILE"
fi

case "$PROFILE" in
    vps|virtualbox|wsl)
        ;;
    *)
        die "Profil invalide : $PROFILE"
        ;;
esac

# ============================================================
# APT / outils communs
# ============================================================

export DEBIAN_FRONTEND=noninteractive

update_system() {

    log "Mise à jour des dépôts"

    apt-get update

    log "Mise à niveau du système"

    apt-get -y full-upgrade
}

install_common_tools() {

    log "Installation des outils communs"

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
        iproute2
}

configure_common_security() {

    log "Baseline de sécurité commune"

    cat > /etc/sysctl.d/90-kali-master-common.conf <<'EOF'
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2

fs.protected_hardlinks = 1
fs.protected_symlinks = 1
EOF

    # Certains paramètres peuvent ne pas être modifiables
    # dans tous les environnements.
    sysctl --system >/dev/null 2>&1 || \
        warn "Certains paramètres sysctl n'ont pas pu être appliqués."
}

# ============================================================
# Utilisateur administrateur VPS
# ============================================================

create_admin_user() {

    if id "$MASTER_USER" >/dev/null 2>&1; then

        ok "Utilisateur $MASTER_USER déjà présent."

    else

        log "Création de $MASTER_USER"

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
# PROFIL VPS
# ============================================================

configure_vps() {

    log "===== PROFIL VPS ====="

    apt-get install -y \
        openssh-server \
        ufw \
        fail2ban \
        chrony \
        unattended-upgrades

    create_admin_user

    # --------------------------------------------------------
    # SSH
    # --------------------------------------------------------

    if [[ "$ENABLE_SSH" == "auto" ]]; then
        ENABLE_SSH=true
    fi

    if [[ "$ENABLE_SSH" == "true" ]]; then

        [[ -n "$SSH_PUBLIC_KEY" ]] || \
            die "Une SSH_PUBLIC_KEY est obligatoire pour le profil VPS."

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

MaxAuthTries 3
LoginGraceTime 30

ClientAliveInterval 300
ClientAliveCountMax 2

AllowUsers ${MASTER_USER}
EOF

        sshd -t || die "Configuration SSH invalide."

        systemctl enable ssh
    fi

    # --------------------------------------------------------
    # UFW
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
    # Réseau VPS
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

    systemctl enable --now chrony 2>/dev/null || true

    if [[ "$ENABLE_SSH" == "true" ]]; then

        sshd -t
        systemctl reload ssh
    fi

    ok "Profil VPS configuré."
}

# ============================================================
# PROFIL VIRTUALBOX
# ============================================================

configure_virtualbox() {

    log "===== PROFIL VIRTUALBOX ====="

    log "Installation des composants VirtualBox"

    apt-get install -y \
        virtualbox-guest-x11 \
        virtualbox-guest-utils \
        virtualbox-guest-dkms || \
        warn "Certains composants VirtualBox n'ont pas été installés."

    local normal_user=""

    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then

        normal_user="$SUDO_USER"

    elif id kali >/dev/null 2>&1; then

        normal_user="kali"
    fi

    if [[ -n "$normal_user" ]]; then

        usermod -aG \
            vboxsf,audio,video,plugdev \
            "$normal_user" 2>/dev/null || true

        ok "Utilisateur VirtualBox : $normal_user"
    fi

    # --------------------------------------------------------
    # SSH facultatif
    # --------------------------------------------------------

    if [[ "$ENABLE_SSH" == "auto" ]]; then
        ENABLE_SSH=false
    fi

    if [[ "$ENABLE_SSH" == "true" ]]; then

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

        systemctl disable --now ssh 2>/dev/null || true
    fi

    # --------------------------------------------------------
    # Firewall
    # --------------------------------------------------------

    apt-get install -y ufw

    ufw --force reset

    ufw default deny incoming
    ufw default allow outgoing

    if [[ "$ENABLE_SSH" == "true" ]]; then
        ufw allow "${SSH_PORT}/tcp"
    fi

    ufw --force enable

    ok "Profil VirtualBox configuré."
}

# ============================================================
# PROFIL WSL
# ============================================================

configure_wsl() {

    log "===== PROFIL WSL ====="

    if ! is_wsl; then
        warn "WSL n'a pas été détecté, mais le profil WSL a été forcé."
    fi

    local wsl_version
    wsl_version="$(detect_wsl_version)"

    log "WSL : ${wsl_version}"

    # --------------------------------------------------------
    # Outils adaptés à WSL
    # --------------------------------------------------------

    log "Installation des outils WSL"

    apt-get install -y \
        procps \
        psmisc \
        iputils-ping \
        traceroute \
        dnsutils \
        net-tools \
        iproute2 \
        socat \
        openssh-client

    # --------------------------------------------------------
    # Pas de Guest Additions
    # --------------------------------------------------------

    ok "VirtualBox Guest Additions ignorées."

    # --------------------------------------------------------
    # Pas de firewall Linux imposé
    # --------------------------------------------------------

    log "Firewall"

    warn "UFW n'est pas activé automatiquement sous WSL."
    warn "La sécurité réseau de l'hôte doit également être gérée côté Windows."

    # --------------------------------------------------------
    # SSH
    # --------------------------------------------------------

    if [[ "$ENABLE_SSH" == "auto" ]]; then
        ENABLE_SSH=false
    fi

    if [[ "$ENABLE_SSH" == "true" ]]; then

        log "Installation facultative du serveur SSH"

        apt-get install -y openssh-server

        mkdir -p /etc/ssh/sshd_config.d

        cat > /etc/ssh/sshd_config.d/90-kali-wsl.conf <<EOF
Port ${SSH_PORT}

PermitRootLogin no

PubkeyAuthentication yes
PasswordAuthentication yes

MaxAuthTries 5
EOF

        sshd -t

        if command -v systemctl >/dev/null 2>&1 &&
           systemctl is-system-running >/dev/null 2>&1; then

            systemctl enable --now ssh || true

        else

            warn "systemd ne semble pas actif."
            warn "SSH est installé mais n'a pas été lancé automatiquement."
        fi
    fi

    # --------------------------------------------------------
    # Configuration WSL
    # --------------------------------------------------------

    log "Vérification de /etc/wsl.conf"

    if [[ -f /etc/wsl.conf ]]; then

        ok "/etc/wsl.conf existe."

    else

        cat > /etc/wsl.conf <<'EOF'
[boot]
systemd=true

[interop]
enabled=true
appendWindowsPath=true
EOF

        ok "/etc/wsl.conf créé."
        warn "Un redémarrage complet de WSL sera nécessaire."
    fi

    # --------------------------------------------------------
    # Nettoyage spécifique
    # --------------------------------------------------------

    apt-get autoremove -y
    apt-get clean

    ok "Profil WSL configuré."
}

# ============================================================
# Exécution principale
# ============================================================

update_system
install_common_tools
configure_common_security

case "$PROFILE" in

    vps)
        configure_vps
        ;;

    virtualbox)
        configure_virtualbox
        ;;

    wsl)
        configure_wsl
        ;;

esac

# ============================================================
# Rapport final
# ============================================================

echo
echo "============================================================"
echo "       KALI UNIVERSAL MASTER v${VERSION}"
echo "============================================================"
echo
echo "Profil appliqué : $PROFILE"
echo

case "$PROFILE" in

    vps)

        echo "Mode           : VPS"
        echo "SSH            : $ENABLE_SSH"
        echo "Port SSH       : $SSH_PORT"
        echo "Utilisateur    : $MASTER_USER"
        echo
        echo "IMPORTANT :"
        echo
        echo "Ne ferme pas ta session SSH actuelle."
        echo
        echo "Teste une seconde connexion :"
        echo
        echo "  ssh -p $SSH_PORT $MASTER_USER@IP_DU_VPS"
        echo
        echo "Puis :"
        echo
        echo "  sudo -i"
        ;;

    virtualbox)

        echo "Mode           : VirtualBox"
        echo "SSH            : $ENABLE_SSH"
        echo
        echo "Recommandation :"
        echo
        echo "  Adapter 1     : NAT"
        echo "  Clipboard     : Disabled"
        echo "  Drag & Drop   : Disabled"
        echo "  Shared Folder : Disabled"
        ;;

    wsl)

        echo "Mode           : Windows Subsystem for Linux"
        echo "WSL détecté    : $(detect_wsl_version)"
        echo "SSH            : $ENABLE_SSH"
        echo
        echo "Après modification de /etc/wsl.conf,"
        echo "depuis PowerShell exécute :"
        echo
        echo "  wsl --shutdown"
        echo
        echo "puis relance Kali."
        ;;
esac

echo
echo "============================================================"
echo " Installation terminée."
echo "============================================================"