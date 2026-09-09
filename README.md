# 🐉 Kali Universal Master

### Bootstrap • Hardening • Reproductibilité

**Kali Universal Master** est un projet d'automatisation permettant de préparer rapidement une nouvelle installation de **Kali Linux** selon son environnement d'exécution.

L'objectif est simple :

> **Une Kali fraîche → une commande → un environnement propre, configuré et prêt à travailler.**

Le projet prend en compte plusieurs façons d'utiliser Kali :

- ☁️ **VPS** — serveur Kali distant ;
- 🖥️ **VirtualBox** — machine virtuelle locale ou laboratoire ;
- 🪟 **WSL** — Kali sous Windows Subsystem for Linux.

Chaque environnement possède ses propres contraintes. Kali Universal Master adapte donc la configuration au système ciblé plutôt que d'appliquer aveuglément les mêmes paramètres partout.

---

# 🚀 Le projet

Kali Universal Master automatise les opérations habituellement répétées après une nouvelle installation :

```text id="6lh83d"
             KALI FRAÎCHE
                  │
                  ▼
          Kali Universal Master
                  │
       ┌──────────┼──────────┐
       │          │          │
       ▼          ▼          ▼
      VPS     VirtualBox    WSL
       │          │          │
       └──────────┼──────────┘
                  │
                  ▼
          Système préparé
                  │
                  ▼
             Prêt à travailler
```

Selon le profil choisi, le projet peut notamment gérer :

- mises à jour système ;
- outils essentiels ;
- configuration SSH ;
- comptes administrateurs ;
- firewall ;
- Fail2ban ;
- paramètres kernel ;
- configuration réseau ;
- intégration VirtualBox ;
- intégration WSL ;
- baseline de sécurité.

---

# 📦 Versions

Le projet est organisé autour de deux générations.

```text id="71b8im"
Kali Universal Master
│
├── V1
│   └── Simple / Stable / Lisible
│
└── V2
    └── Avancée / Modulaire / Résiliente
```

---

# 🟢 Version 1 — Stable

### Version actuelle : `v1.1`

La V1 représente la branche simple du projet.

Elle privilégie :

```text id="j0brhh"
Simplicité
    +
Lisibilité
    +
Déploiement rapide
    +
Peu de dépendances
```

Toute la logique principale tient dans un script Bash.

```text id="zn1fkw"
V1/
│
├── kali-master-v1.1.sh
└── README.md
```

---

## Profils V1

La version 1.1 prend en charge :

```text id="asqlsr"
--profile vps
--profile virtualbox
--profile wsl
--profile auto
```

Elle possède également :

```text id="bxyv4h"
--detect
```

permettant d'inspecter l'environnement avant d'effectuer le bootstrap.

---

## ☁️ VPS

Le profil VPS privilégie la sécurisation d'un système distant.

Il peut notamment configurer :

```text id="6coc10"
OpenSSH
   │
   ├── clés publiques
   ├── mots de passe désactivés
   └── restrictions de connexion

UFW
   │
   └── politique entrante restrictive

Fail2ban
   │
   └── protection SSH

Kernel
   │
   └── paramètres réseau adaptés
```

---

## 🖥️ VirtualBox

Le profil VirtualBox est conçu pour les VM Kali utilisées comme postes de travail ou environnements de laboratoire.

Il privilégie un équilibre entre :

> **isolation et flexibilité réseau.**

Il peut notamment gérer :

- VirtualBox Guest ;
- utilisateur Kali ;
- firewall local ;
- SSH facultatif ;
- baseline kernel adaptée.

Certains paramètres réseau stricts du VPS sont volontairement évités afin de ne pas perturber les laboratoires multi-interface.

---

## 🪟 WSL

Le profil WSL prépare Kali pour **Windows Subsystem for Linux**.

Il prend notamment en compte :

```text id="bm1a8q"
WSL
 │
 ├── détection environnement
 ├── outils Linux
 ├── intégration Windows
 ├── systemd
 ├── /etc/wsl.conf
 └── SSH facultatif
```

Les réglages propres aux VPS et VirtualBox ne sont pas appliqués inutilement.

---

# ⚡ Démarrage V1

Rendre le script exécutable :

```bash id="bxvvuo"
chmod +x kali-master-v1.1.sh
```

### Détection

```bash id="dshcpk"
sudo ./kali-master-v1.1.sh --detect
```

### Automatique

```bash id="o7mzvj"
sudo ./kali-master-v1.1.sh --profile auto
```

### VirtualBox

```bash id="qwbys5"
sudo ./kali-master-v1.1.sh --profile virtualbox
```

### WSL

```bash id="35o2ed"
sudo ./kali-master-v1.1.sh --profile wsl
```

### VPS

Le profil VPS nécessite une clé SSH :

```bash id="i9w6mh"
sudo \
MASTER_USER=jarvis \
SSH_PUBLIC_KEY="$(cat ~/.ssh/id_ed25519.pub)" \
./kali-master-v1.1.sh --profile vps
```

Consultez le README de la V1 pour la documentation complète.

---

# 🔵 Version 2 — Nouvelle génération

La V2 reprend les principes de la V1 mais vise une architecture plus robuste.

L'objectif n'est pas de transformer Kali Universal Master en framework complexe.

La philosophie reste :

> **Simple à utiliser, robuste derrière.**

La commande finale doit rester proche de :

```bash id="uc18xk"
sudo ./kali-master.sh --profile auto
```

---

# 🧩 Architecture V2

La V2 séparera progressivement les responsabilités :

```text id="lkyyid"
Kali Universal Master V2
│
├── Core
│   ├── détection
│   ├── configuration
│   ├── validation
│   └── logging
│
├── Profiles
│   ├── VPS
│   ├── VirtualBox
│   └── WSL
│
├── Security
│   ├── SSH
│   ├── nftables
│   └── WireGuard
│
├── Safety
│   ├── backup
│   ├── rollback
│   └── dry-run
│
└── Reports
    └── rapport final
```

---

# 🛡️ Sécurité V2

Plusieurs améliorations sont prévues.

### nftables

La V2 pourra utiliser directement :

```text id="gsy8a7"
nftables
```

afin de disposer d'un contrôle plus précis du filtrage réseau.

### WireGuard

Pour les VPS, WireGuard permettra éventuellement une architecture :

```text id="gybgh5"
PC administrateur
       │
       │ WireGuard
       ▼
      VPS
       │
       └── SSH
```

L'objectif sera notamment de pouvoir limiter certains services d'administration au réseau VPN.

---

# 💾 Backup et rollback

Avant une modification importante :

```text id="3dnqpx"
Configuration actuelle
        │
        ▼
      BACKUP
        │
        ▼
    Modification
        │
    ┌───┴───┐
    │       │
    ▼       ▼
   OK     ERREUR
    │       │
    ▼       ▼
continuer  rollback
```

Les fichiers sensibles pourront être sauvegardés avant modification.

Par exemple :

```text id="mklbz7"
/etc/ssh/
/etc/nftables.conf
/etc/sysctl.d/
/etc/wsl.conf
```

---

# 🧪 Dry Run

La V2 prévoit un mode :

```bash id="knngvp"
sudo ./kali-master.sh --profile vps --dry-run
```

permettant d'afficher les opérations prévues **sans les appliquer**.

Exemple conceptuel :

```text id="cy1s4r"
[DRY-RUN]

✓ Détection : VPS

Prévu :

[+] apt update
[+] installation OpenSSH
[+] création utilisateur
[+] configuration SSH
[+] configuration nftables
[+] configuration WireGuard
[+] baseline kernel

Aucune modification effectuée.
```

---

# 📜 Journalisation

La V2 pourra conserver un journal d'installation.

Exemple :

```text id="mb52lc"
/var/log/kali-master/
```

avec :

```text id="bq8ao1"
install.log
backup.log
security.log
report.txt
```

Cela permettra de comprendre précisément ce qui a été modifié.

---

# 📊 Rapport final

Après installation, la V2 pourra produire un résumé du système :

```text id="mkq8ar"
========================================
      KALI UNIVERSAL MASTER
========================================

Profile       : VPS
Environment   : KVM
SSH           : OK
Firewall      : OK
WireGuard     : OK
Fail2ban      : OK
Updates       : OK

Backup        : created
Validation    : passed

Status        : READY
========================================
```

---

# 🔄 Rebuild

À terme, l'objectif est également de faciliter la reconstruction d'une machine.

```text id="wmkr0m"
Configuration
      │
      ▼
    export
      │
      ▼
VPS détruit
      │
      ▼
nouveau VPS
      │
      ▼
Kali Master
      │
      ▼
    rebuild
```

Cela est particulièrement utile pour des VPS conçus pour être **remplaçables plutôt que réparés indéfiniment**.

---

# 🗂️ Organisation proposée du dépôt

```text id="7sjb9u"
kali-universal-master/
│
├── README.md
├── LICENSE
│
├── v1/
│   ├── README.md
│   └── kali-master-v1.1.sh
│
└── v2/
    ├── README.md
    └── kali-master.sh
```

Le README présent à la racine sert de **présentation générale du projet**.

Chaque version possède ensuite sa propre documentation détaillée.

---

# 🆚 V1 ou V2 ?

|               | V1.1    | V2          |
| ------------- | ------- | ----------- |
| VPS           | ✅      | ✅ prévu    |
| VirtualBox    | ✅      | ✅ prévu    |
| WSL           | ✅      | ✅ prévu    |
| Auto Detect   | ✅      | ✅ amélioré |
| SSH hardening | ✅      | ✅          |
| UFW           | ✅      | —           |
| nftables      | —       | 🔵 prévu    |
| Fail2ban      | ✅ VPS  | 🔵 prévu    |
| WireGuard     | —       | 🔵 prévu    |
| Dry Run       | —       | 🔵 prévu    |
| Backup        | —       | 🔵 prévu    |
| Rollback      | —       | 🔵 prévu    |
| Logs avancés  | —       | 🔵 prévu    |
| Rapport final | Basique | 🔵 prévu    |
| Rebuild       | —       | 🔵 prévu    |

**V1.1** est la branche à privilégier pour commencer immédiatement.

**V2** constitue l'évolution du projet et sera construite progressivement sans sacrifier la simplicité de la V1.

---

# 🔐 Principes de sécurité

Kali Universal Master suit quelques principes simples :

```text id="d1qesd"
Minimum nécessaire
       │
       ▼
Réduire les services exposés
       │
       ▼
Séparer les environnements
       │
       ▼
Sauvegarder avant modification
       │
       ▼
Vérifier après modification
       │
       ▼
Pouvoir reconstruire
```

Un script de hardening ne constitue cependant jamais à lui seul une garantie de sécurité.

La sécurité dépend également :

- de l'hyperviseur ;
- du fournisseur VPS ;
- de Windows dans le cas de WSL ;
- de la configuration réseau ;
- des mises à jour ;
- des comptes et clés utilisés ;
- des services installés ;
- de l'usage de la machine.

---

# ⚠️ VPS : précaution importante

Après toute modification SSH distante :

> **Ne fermez pas immédiatement votre session SSH actuelle.**

Ouvrez une seconde connexion et vérifiez le nouvel accès avant de fermer la première.

Lorsque cela est disponible, conservez également la console de récupération de l'hébergeur accessible pendant le bootstrap.

---

# ⚖️ Utilisation responsable

Kali Linux contient de nombreux outils destinés à l'administration système, au diagnostic, à l'audit et à la cybersécurité.

Kali Universal Master doit être utilisé sur des machines, systèmes et réseaux que vous possédez ou pour lesquels vous disposez des autorisations nécessaires.

---

# 🐉 Kali Universal Master

```text id="i85s6n"
            KALI UNIVERSAL MASTER

                   ┌─────┐
                   │KALI │
                   └──┬──┘
                      │
              ┌───────┼───────┐
              ▼       ▼       ▼
             VPS     VBox     WSL
              │       │       │
              └───────┼───────┘
                      ▼
                MASTER READY
```

### V1 — Simple & Stable

### V2 — Robust & Modular

**Build once. Deploy clean. Rebuild anytime.**
