# provision-haproxy.sh

set -e # Stop script execution on any error
echo ""; echo "---- Provisioning Environment ----"

# Set system name
MYHOST=haproxy
echo "- Set name to $MYHOST -"
hostnamectl set-hostname $MYHOST
cat >> /etc/hosts <<EOF
10.0.0.18	$MYHOST $MYHOST.localdomain
EOF


# Install App
echo "- Installing App -"
dnf -yqe 3 install vsftp httpd

# Configure firewall
echo "- Update Firewall -"
systemctl enable --now firewalld.service
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ftp
firewall-cmd --permanent --add-port=10000-10020/tcp
firewall-cmd --reload

systemctl enable --now httpd
systemctl enable --now vsftpd

echo "---- Environment setup complete ----"; echo ""
echo "------------------------------------------"
echo " With great power, comes great opportunity"
echo "------------------------------------------"
