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
sleep 1

# ===========================================
# CHECK SUDO ACCESS
# ===========================================
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ Please don't run as root directly${NC}"
    echo -e "${YELLOW}→ Run this script as normal user with sudo access${NC}"
    exit 1
fi

# Check sudo permissions
if ! sudo -v > /dev/null 2>&1; then
    echo -e "${RED}❌ This script requires sudo privileges${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Sudo access verified${NC}\n"
sleep 1

# ===========================================
# STEP 1: SET ROOT PASSWORD
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 1: ROOT PASSWORD SETUP${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

echo -e "${BLUE}▶ Setting root password (required for console access)${NC}"
echo -e "${YELLOW}⚠  Choose a strong password and save it securely${NC}\n"

sudo passwd root
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Root password configured${NC}\n"
else
    echo -e "${RED}❌ Failed to set root password. Exiting.${NC}"
    exit 1
fi
sleep 1

# ===========================================
# STEP 2: SET HOSTNAME
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 2: HOSTNAME CONFIGURATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

echo -e "${BLUE}▶ Setting hostname to mrnode.in${NC}"

# Backup current hostname
OLD_HOSTNAME=$(hostname)
echo -e "   Old hostname: ${YELLOW}$OLD_HOSTNAME${NC}"

# Set new hostname
sudo hostnamectl set-hostname mrnode.in

# Update hosts file
sudo tee /etc/hosts > /dev/null <<EOF
127.0.0.1 localhost
127.0.1.1 mrnode.in
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters
EOF

# Update hostname file
echo "mrnode.in" | sudo tee /etc/hostname > /dev/null

echo -e "${GREEN}✅ Hostname set to: $(hostname)${NC}\n"
sleep 1

# ===========================================
# STEP 3: BACKUP SSH CONFIG
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 3: SSH CONFIGURATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

# Create backup
BACKUP_FILE="/etc/ssh/sshd_config.backup-$(date +%Y%m%d-%H%M%S)"
echo -e "${BLUE}▶ Creating backup of current SSH config${NC}"
sudo cp /etc/ssh/sshd_config $BACKUP_FILE
echo -e "${GREEN}✅ Backup saved: $BACKUP_FILE${NC}\n"

# ===========================================
# STEP 4: APPLY MR NODE SSH CONFIG
# ===========================================
echo -e "${BLUE}▶ Applying MrNode SSH configuration${NC}"

sudo tee /etc/ssh/sshd_config > /dev/null <<'MRNODE_SSH'
# =============================================
# MR NODE PVT LTD - SSH SERVER CONFIGURATION
# =============================================

# PORT SETTINGS
Port 22

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

# SFTP
Subsystem sftp /usr/lib/openssh/sftp-server

# =============================================
# END MR NODE SSH CONFIGURATION
# =============================================
MRNODE_SSH

echo -e "${GREEN}✅ MrNode SSH configuration applied${NC}\n"

# ===========================================
# STEP 5: TEST SSH CONFIG
# ===========================================
echo -e "${BLUE}▶ Testing SSH configuration${NC}"
sudo sshd -t
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSH configuration test passed${NC}\n"
else
    echo -e "${RED}❌ SSH configuration test failed${NC}"
    echo -e "${YELLOW}→ Restoring backup...${NC}"
    sudo cp $BACKUP_FILE /etc/ssh/sshd_config
    echo -e "${GREEN}✅ Original config restored${NC}"
    exit 1
fi
sleep 1

# ===========================================
# STEP 6: RESTART SSH
# ===========================================
echo -e "${BLUE}▶ Restarting SSH service${NC}"
sudo systemctl restart ssh > /dev/null 2>&1 || sudo service ssh restart > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ SSH service restarted${NC}\n"
else
    echo -e "${RED}❌ Failed to restart SSH${NC}"
    echo -e "${YELLOW}→ Manual restart may be required${NC}\n"
fi
sleep 1

# ===========================================
# STEP 7: INSTALL MR NODE MOTD
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 STEP 7: MR NODE MOTD INSTALLATION${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

echo -e "${BLUE}▶ Installing custom MOTD${NC}"

# Create MOTD directory
sudo mkdir -p /etc/update-motd.d

# Remove existing MOTD files
sudo rm -f /etc/update-motd.d/*
sudo rm -f /etc/motd

# Create MrNode MOTD
sudo tee /etc/update-motd.d/99-mrnode > /dev/null <<'MRNODE_MOTD'
#!/bin/bash

# MR NODE PVT LTD - WELCOME SCREEN

# Colors for MOTD
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
echo "   ║       Enterprise Server Solution           ║"
echo "   ╚═══════════════════════════════════════════╝"
echo -e "${NC}"

# Server Information
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
printf "${WHITE}▶ Hostname:${NC}     %s\n" "$(hostname)"
printf "${WHITE}▶ Domain:${NC}       mrnode.in\n"
printf "${WHITE}▶ IP Address:${NC}   %s\n" "$(hostname -I | awk '{print $1}')"
printf "${WHITE}▶ OS Version:${NC}   %s\n" "$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
printf "${WHITE}▶ Kernel:${NC}       %s\n" "$(uname -r)"
printf "${WHITE}▶ Uptime:${NC}       %s\n" "$(uptime -p | sed 's/up //')"
printf "${WHITE}▶ Users:${NC}        %s\n" "$(who | wc -l)"
printf "${WHITE}▶ Load:${NC}         %s\n" "$(uptime | awk -F'load average:' '{print $2}')"
printf "${WHITE}▶ Memory:${NC}       %s\n" "$(free -h | grep Mem | awk '{print $3"/"$2}')"
printf "${WHITE}▶ Disk:${NC}         %s\n" "$(df -h / | awk 'NR==2 {print $3"/"$2}')"
printf "${WHITE}▶ Date:${NC}         %s\n" "$(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Security Notice
echo -e "${YELLOW}⚠  UNAUTHORIZED ACCESS IS PROHIBITED${NC}"
echo -e "${WHITE}   All activities are monitored and logged${NC}"
echo -e "${WHITE}   Report issues: ${CYAN}support@mrnode.in${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
MRNODE_MOTD

# Set permissions
sudo chmod +x /etc/update-motd.d/99-mrnode

echo -e "${GREEN}✅ MrNode MOTD installed${NC}\n"
sleep 1

# ===========================================
# STEP 8: SHOW PREVIEW
# ===========================================
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${YELLOW}📌 MR NODE SERVER - PREVIEW${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}\n"

/etc/update-motd.d/99-mrnode
sleep 2

# ===========================================
# COMPLETION
# ===========================================
echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ MR NODE SERVER SETUP COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}\n"

echo -e "${WHITE}📋 CONFIGURATION SUMMARY:${NC}"
echo -e "   • Hostname: ${CYAN}mrnode.in${NC}"
echo -e "   • Root Password: ${GREEN}Configured${NC}"
echo -e "   • SSH Port: ${CYAN}22${NC}"
echo -e "   • SSH Keys: ${GREEN}Enabled${NC}"
echo -e "   • SSH Password: ${GREEN}Enabled${NC}"
echo -e "   • Root Login: ${GREEN}Allowed${NC}"
echo -e "   • MOTD: ${GREEN}MrNode Custom${NC}"
echo -e "   • Backup: ${YELLOW}$BACKUP_FILE${NC}\n"

echo -e "${YELLOW}🔑 LOGIN TEST COMMAND:${NC}"
echo -e "${WHITE}   ssh root@$(hostname -I | awk '{print $1}')${NC}\n"

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎉 Welcome to MrNode PVT LTD!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"