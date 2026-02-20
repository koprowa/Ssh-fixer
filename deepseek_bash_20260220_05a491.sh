#!/bin/bash

# ===========================================
# MR NODE PVT LTD - SERVER SETUP SCRIPT
# ===========================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# ===========================================
# HEADER
# ===========================================
clear
echo -e "${PURPLE}"
echo "   ╔═══════════════════════════════════════════╗"
echo "   ║     MR NODE PVT LTD - SERVER SETUP       ║"
echo "   ║         Secure Configuration Tool         ║"
echo "   ╚═══════════════════════════════════════════╝"
echo -e "${NC}"
sleep 2

# ===========================================
# CHECK USER TYPE
# ===========================================
if [ "$EUID" -eq 0 ]; then
    echo -e "${GREEN}✅ Running as root user${NC}"
    echo -e "${GREEN}✓ All commands will execute directly${NC}\n"
    SUDO=""
else
    echo -e "${GREEN}✅ Running as normal user with sudo access${NC}\n"
    SUDO="sudo"
fi
sleep 2

# ===========================================
# STEP 1: SET ROOT PASSWORD
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 1: ROOT PASSWORD SETUP${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

echo -e "${BLUE}▶ Setting root password${NC}"
echo -e "${YELLOW}⚠ Choose a strong password and save it securely${NC}\n"

$SUDO passwd root
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Root password configured successfully${NC}\n"
else
    echo -e "${RED}❌ Failed to set root password. Exiting.${NC}"
    exit 1
fi
sleep 2

# ===========================================
# STEP 2: SET HOSTNAME
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 2: HOSTNAME CONFIGURATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

echo -e "${BLUE}▶ Setting hostname to mrnode.in${NC}"

# Show current hostname
OLD_HOSTNAME=$(hostname)
echo -e "   Current hostname: ${YELLOW}$OLD_HOSTNAME${NC}"
echo -e "   New hostname: ${GREEN}mrnode.in${NC}\n"

# Set new hostname
$SUDO hostnamectl set-hostname mrnode.in

# Update hosts file
$SUDO tee /etc/hosts > /dev/null <<EOF
127.0.0.1 localhost
127.0.1.1 mrnode.in
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF

# Update hostname file
echo "mrnode.in" | $SUDO tee /etc/hostname > /dev/null

echo -e "${GREEN}✅ Hostname successfully changed to: $(hostname)${NC}\n"
sleep 2

# ===========================================
# STEP 3: BACKUP SSH CONFIG
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 3: SSH CONFIGURATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

# Create backup
BACKUP_FILE="/etc/ssh/sshd_config.backup-$(date +%Y%m%d-%H%M%S)"
echo -e "${BLUE}▶ Creating backup of current SSH configuration${NC}"
$SUDO cp /etc/ssh/sshd_config $BACKUP_FILE
echo -e "${GREEN}✅ Backup saved at: $BACKUP_FILE${NC}\n"
sleep 1

# ===========================================
# STEP 4: APPLY MR NODE SSH CONFIG
# ===========================================
echo -e "${BLUE}▶ Applying MrNode SSH configuration${NC}"

$SUDO tee /etc/ssh/sshd_config > /dev/null <<'MRNODE_SSH'
# =============================================
# MR NODE PVT LTD - SSH SERVER CONFIGURATION
# Generated on $(date)
# =============================================

# NETWORK SETTINGS
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# AUTHENTICATION SETTINGS
PermitRootLogin yes
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
AuthenticationMethods publickey,password

# SECURITY SETTINGS
PermitEmptyPasswords no
X11Forwarding no
AllowTcpForwarding yes
AllowAgentForwarding no
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 30

# LOGGING
SyslogFacility AUTH
LogLevel INFO

# SFTP SUBSYSTEM
Subsystem sftp /usr/lib/openssh/sftp-server

# =============================================
# END MR NODE SSH CONFIGURATION
# =============================================
MRNODE_SSH

echo -e "${GREEN}✅ MrNode SSH configuration applied${NC}\n"
sleep 1

# ===========================================
# STEP 5: TEST SSH CONFIG
# ===========================================
echo -e "${BLUE}▶ Testing SSH configuration for errors${NC}"
$SUDO sshd -t
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSH configuration test PASSED${NC}\n"
else
    echo -e "${RED}❌ SSH configuration test FAILED${NC}"
    echo -e "${YELLOW}→ Restoring backup...${NC}"
    $SUDO cp $BACKUP_FILE /etc/ssh/sshd_config
    echo -e "${GREEN}✅ Original configuration restored${NC}"
    exit 1
fi
sleep 1

# ===========================================
# STEP 6: RESTART SSH SERVICE
# ===========================================
echo -e "${BLUE}▶ Restarting SSH service${NC}"
$SUDO systemctl restart ssh > /dev/null 2>&1 || $SUDO service ssh restart > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSH service restarted successfully${NC}\n"
else
    echo -e "${RED}❌ Failed to restart SSH service${NC}"
    echo -e "${YELLOW}→ Manual restart may be required: sudo systemctl restart ssh${NC}\n"
fi
sleep 2

# ===========================================
# STEP 7: INSTALL MR NODE MOTD
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 7: MR NODE MOTD INSTALLATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

echo -e "${BLUE}▶ Installing custom MrNode MOTD${NC}"

# Create MOTD directory
$SUDO mkdir -p /etc/update-motd.d

# Remove existing MOTD files
$SUDO rm -f /etc/update-motd.d/*
$SUDO rm -f /etc/motd

# Create MrNode MOTD
$SUDO tee /etc/update-motd.d/99-mrnode > /dev/null <<'MRNODE_MOTD'
#!/bin/bash

# MR NODE PVT LTD - CUSTOM WELCOME SCREEN

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Clear screen for clean look
clear

# MrNode Logo
echo -e "${PURPLE}"
echo "   ╔═══════════════════════════════════════════╗"
echo "   ║         MR NODE PVT LTD                   ║"
echo "   ║       Enterprise Server Solutions         ║"
echo "   ╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# System Information
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
printf "${WHITE}▶ Hostname:${NC}     ${GREEN}%s${NC}\n" "$(hostname)"
printf "${WHITE}▶ Domain:${NC}       ${GREEN}mrnode.in${NC}\n"
printf "${WHITE}▶ IP Address:${NC}   ${GREEN}%s${NC}\n" "$(hostname -I | awk '{print $1}')"
printf "${WHITE}▶ OS Version:${NC}   ${GREEN}%s${NC}\n" "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
printf "${WHITE}▶ Kernel:${NC}       ${GREEN}%s${NC}\n" "$(uname -r)"
printf "${WHITE}▶ Uptime:${NC}       ${GREEN}%s${NC}\n" "$(uptime -p | sed 's/up //')"
printf "${WHITE}▶ Users:${NC}        ${GREEN}%s${NC}\n" "$(who | wc -l)"
printf "${WHITE}▶ Load:${NC}         ${GREEN}%s${NC}\n" "$(uptime | awk -F'load average:' '{print $2}')"
printf "${WHITE}▶ Memory:${NC}       ${GREEN}%s${NC}\n" "$(free -h | grep Mem | awk '{print $3"/"$2}')"
printf "${WHITE}▶ Disk:${NC}         ${GREEN}%s${NC}\n" "$(df -h / | awk 'NR==2 {print $3"/"$2}')"
printf "${WHITE}▶ Date:${NC}         ${GREEN}%s${NC}\n" "$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Security Notice
echo -e "${YELLOW}⚠  UNAUTHORIZED ACCESS IS PROHIBITED${NC}"
echo -e "${WHITE}   All activities are monitored and logged${NC}"
echo -e "${WHITE}   For support: ${CYAN}support@mrnode.in${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
MRNODE_MOTD

# Set permissions
$SUDO chmod +x /etc/update-motd.d/99-mrnode

echo -e "${GREEN}✅ MrNode MOTD installed successfully${NC}\n"
sleep 2

# ===========================================
# STEP 8: SHOW MOTD PREVIEW
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 MR NODE SERVER - PREVIEW${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

/etc/update-motd.d/99-mrnode
sleep 3

# ===========================================
# COMPLETION SUMMARY
# ===========================================
echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ MR NODE SERVER SETUP COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}\n"

echo -e "${WHITE}📋 CONFIGURATION SUMMARY:${NC}"
echo -e "   ${GREEN}✓${NC} Root Password: ${GREEN}Configured${NC}"
echo -e "   ${GREEN}✓${NC} Hostname: ${GREEN}mrnode.in${NC}"
echo -e "   ${GREEN}✓${NC} SSH Port: ${GREEN}22${NC}"
echo -e "   ${GREEN}✓${NC} SSH Keys: ${GREEN}Enabled${NC}"
echo -e "   ${GREEN}✓${NC} SSH Password: ${GREEN}Enabled${NC}"
echo -e "   ${GREEN}✓${NC} Root Login: ${GREEN}Allowed${NC}"
echo -e "   ${GREEN}✓${NC} MOTD: ${GREEN}MrNode Custom${NC}"
echo -e "   ${GREEN}✓${NC} Backup: ${YELLOW}$BACKUP_FILE${NC}\n"

# Get IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${YELLOW}🔑 LOGIN TEST COMMAND:${NC}"
echo -e "${WHITE}   ssh root@$SERVER_IP${NC}"
echo -e "${WHITE}   (Use the root password you just set)${NC}\n"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Welcome to MrNode PVT LTD! Your server is ready.${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"