#!/bin/bash

# ===========================================
# SAFE SSH Setup - MrNode PVT LTD
# ===========================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No color

clear
echo -e "${CYAN}🔐 MrNode PVT LTD - SSH Configuration${NC}"
echo -e "${BLUE}======================================${NC}\n"

# Check if running on AWS
if curl -s http://169.254.169.254/latest/meta-data/ > /dev/null 2>&1; then
    echo -e "${GREEN}✓ AWS instance detected${NC}"
    IS_AWS=true
else
    echo -e "${YELLOW}⚠ Non-AWS environment detected${NC}"
    IS_AWS=false
fi

# ===========================================
# 🌐 SET HOSTNAME TO mrnode.in
# ===========================================
echo -e "${BLUE}▶ Setting hostname to mrnode.in...${NC}"

OLD_HOSTNAME=$(hostname)
echo -e "${YELLOW}  Current hostname: $OLD_HOSTNAME${NC}"

# Set new hostname
sudo hostnamectl set-hostname mrnode.in

# Update /etc/hosts
sudo sed -i "s/127.0.1.1.*/127.0.1.1 mrnode.in/g" /etc/hosts
if ! grep -q "127.0.1.1 mrnode.in" /etc/hosts; then
    echo "127.0.1.1 mrnode.in" | sudo tee -a /etc/hosts > /dev/null
fi

# Update /etc/hostname
echo "mrnode.in" | sudo tee /etc/hostname > /dev/null

echo -e "${GREEN}✓ Hostname changed to: $(hostname)${NC}\n"

# ===========================================
# 🔐 SSH CONFIGURATION
# ===========================================
echo -e "${BLUE}▶ Creating backup of current SSH config...${NC}"
BACKUP_FILE="/etc/ssh/sshd_config.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp /etc/ssh/sshd_config $BACKUP_FILE
echo -e "${GREEN}✓ Backup created at: $BACKUP_FILE${NC}\n"

# Create new SSH config
echo -e "${BLUE}▶ Applying safe SSH configuration...${NC}"

sudo tee /etc/ssh/sshd_config > /dev/null <<EOF
# ============================================
# MrNode PVT LTD - Production Server SSH Config
# Generated: $(date)
# ============================================

# 🔑 AUTHENTICATION
PubkeyAuthentication yes
PasswordAuthentication no
PermitRootLogin prohibit-password
ChallengeResponseAuthentication no
UsePAM yes
AuthenticationMethods publickey

# 🌐 NETWORK
Port 22
AddressFamily any
ListenAddress 0.0.0.0
ListenAddress ::

# ⏱️ SESSION MANAGEMENT
ClientAliveInterval 300
ClientAliveCountMax 2
MaxSessions 10
MaxAuthTries 3
LoginGraceTime 30

# 🔒 SECURITY
PermitEmptyPasswords no
IgnoreRhosts yes
HostbasedAuthentication no
PermitUserEnvironment no
X11Forwarding no
AllowTcpForwarding yes
AllowAgentForwarding no
PrintMotd yes
PrintLastLog yes
TCPKeepAlive yes

# 📁 SFTP
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo -e "${GREEN}✓ SSH configuration applied${NC}\n"

# Test configuration
echo -e "${BLUE}▶ Testing SSH configuration...${NC}"
sudo sshd -t
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Configuration test passed${NC}\n"
else
    echo -e "${RED}✘ Configuration test FAILED! Restoring backup...${NC}"
    sudo cp $BACKUP_FILE /etc/ssh/sshd_config
    echo -e "${YELLOW}⚠ Original config restored.${NC}"
    exit 1
fi

# Restart SSH
echo -e "${BLUE}▶ Restarting SSH service...${NC}"
sudo systemctl restart ssh || sudo service ssh restart

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ SSH service restarted successfully${NC}\n"
else
    echo -e "${RED}✘ Failed to restart SSH!${NC}"
fi

# ===========================================
# 🎨 INSTALL MR NODE MOTD
# ===========================================
echo -e "${BLUE}▶ Installing MrNode custom MOTD...${NC}"

sudo tee /etc/update-motd.d/99-mrnode-welcome > /dev/null <<'EOF'
#!/bin/bash
echo ""
echo "======================================"
echo "  🚀 Welcome to MrNode PVT LTD"
echo "======================================"
echo "  Hostname: $(hostname)"
echo "  Domain: mrnode.in"
echo "  IP: $(hostname -I | awk '{print $1}')"
echo "  Kernel: $(uname -r)"
echo "  Uptime: $(uptime -p)"
echo "  Users: $(who | wc -l)"
echo "  Date: $(date)"
echo "======================================"
echo "  🔒 Secure Server - Authorized Only"
echo "  📧 support@mrnode.in"
echo "======================================"
echo ""
EOF

sudo chmod +x /etc/update-motd.d/99-mrnode-welcome

# Remove default MOTD files
sudo rm -f /etc/update-motd.d/00-header
sudo rm -f /etc/update-motd.d/10-help-text

echo -e "${GREEN}✓ MrNode MOTD installed${NC}\n"

# ===========================================
# ✅ FINAL STATUS
# ===========================================
echo -e "${CYAN}✨ MrNode Server Setup Complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Hostname: ${YELLOW}mrnode.in${NC}"
echo -e "  SSH Keys: ${GREEN}Enabled${NC}"
echo -e "  SSH Password: ${RED}Disabled${NC}"
echo -e "  Backup: ${YELLOW}$BACKUP_FILE${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Show MOTD preview
/etc/update-motd.d/99-mrnode-welcome