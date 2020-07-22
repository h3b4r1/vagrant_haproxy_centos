# provision-haproxy.sh

set -e # Stop script execution on any error
echo ""; echo "---- Provisioning Environment ----"

# Set system name
MYHOST=haproxy
echo "- Set name to $MYHOST -"
hostnamectl set-hostname $MYHOST
cat >> /etc/hosts <<EOF
10.0.0.17	$MYHOST $MYHOST.localdomain
EOF


# Install App
echo "- Installing App -"
yum -y -q -e 3 install haproxy ftp

# Configure firewall
echo "- Update Firewall -"
systemctl enable --now firewalld.service
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=ftp
firewall-cmd --permanent --add-port=10000-10020/tcp
firewall-cmd --reload

echo "- Selinux to Permissive -"
sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
setenforce 0

cat <<EOF > /etc/haproxy/haproxy.cfg
global
    log         127.0.0.1 local2

    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    maxconn     1000
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

    # utilize system-wide crypto-policies
    ssl-default-bind-ciphers PROFILE=SYSTEM
    ssl-default-server-ciphers PROFILE=SYSTEM

defaults
    timeout connect 10s
    timeout client 30s
    timeout server 30s
	mode tcp
    log global
    maxconn 3000

# Front End configs
frontend ftp_balancer
    bind 10.0.2.15:21 transparent
	bind 10.0.2.15:10000-10020 transparent
    use_backend     ftpservers

frontend http_balancer
    bind 10.0.2.15:80
    use_backend     httpservers

frontend https_balancer
    bind 10.0.2.15:443
    use_backend     httpsservers
	
frontend ssh_balancer
    bind 10.0.2.15:65222
    use_backend     sshservers

# Back end configs
backend ftpservers
    balance roundrobin
    stick on src
    stick-table type ip size 10240k expire 30m
    server target 10.0.0.18:21 check
    server target 10.0.0.18:10000-10020 check

backend httpservers
    balance     roundrobin
    server  ftp-iinet  10.0.0.18:80  check

backend httpsservers
    balance     roundrobin
    server  ftp-iinet  10.0.0.18:443  check

backend sshservers
    balance     roundrobin
    server  ftp-iinet  10.0.0.18:22  check

EOF

cat <<EOF >> /etc/rsyslog.conf

local2.*                       /var/log/haproxy.log
EOF



echo "- Start HAproxy -"
systemctl enable --now haproxy

echo "---- Environment setup complete ----"; echo ""
echo "------------------------------------------"
echo " With great power, comes great opportunity"
echo "------------------------------------------"
