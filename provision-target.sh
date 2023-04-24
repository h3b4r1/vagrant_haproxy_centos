# provision-haproxy.sh

set -e # Stop script execution on any error
echo ""; echo "---- Provisioning Environment ----"

# Set system name
MYHOST=target
echo "- Set name to $MYHOST -"
hostnamectl set-hostname $MYHOST
cat >> /etc/hosts <<EOF
10.0.0.18	$MYHOST $MYHOST.localdomain
EOF

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

# Install App
echo "- Installing App -"
yum -y -q -e 3 install vsftpd httpd mod_ssl openssl

echo "- Configure VSFTPD -"
mkdir /home/ftp
touch /home/ftp/testfile.txt

cat <<EOF >> /etc/vsftpd/vsftpd.conf
pasv_enable=Yes
pasv_min_port=10000
pasv_max_port=10020

no_anon_password=YES
anon_root=/home/ftp
EOF

echo "- Configure httpd -"
openssl genrsa -out ca.key 2048
openssl req -new -key ca.key -out ca.csr -subj "/C=AU/ST=NSW/L=Sydney/O=Dis/CN=target.local"
openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt
cp ca.crt /etc/pki/tls/certs/
cp ca.key /etc/pki/tls/private/
cp ca.csr /etc/pki/tls/private/

cat <<EOF > /var/www/html/index.html
<html>
	<head>
		<title>HA Proxy Test Page</title>
		<style type="text/css">
		<!--
		h1	{text-align:center;
		font-family:Arial, Helvetica, Sans-Serif;
			}

		p	{text-indent:20px;
				}
		-->
		</style>
	</head>
	<body bgcolor = "#ffffff" text = "#000000">
		<h1>HA Proxy Test Page</h1>
		<p>You can modify the text in the box to the left any way you like, and then click the "Show Page" button below the box to display the result here. Go ahead and do this as often and as long as you like.</p>
	</body>
</html>
EOF

cat<<EOF > /etc/httpd/conf.d/ssl.conf

LoadModule ssl_module modules/mod_ssl.so

Listen 443

SSLPassPhraseDialog  builtin
SSLSessionCache         shmcb:/var/cache/mod_ssl/scache(512000)
SSLSessionCacheTimeout  300
SSLRandomSeed startup file:/dev/urandom  256
SSLRandomSeed connect builtin
#SSLRandomSeed startup file:/dev/random  512
#SSLRandomSeed connect file:/dev/random  512
#SSLRandomSeed connect file:/dev/urandom 512

SSLCryptoDevice builtin

<VirtualHost _default_:443>

	# General setup for the virtual host, inherited from global configuration
	DocumentRoot "/var/www/html"
	ServerName target.test:443

	ErrorLog logs/ssl_error_log
	TransferLog logs/ssl_access_log
	LogLevel warn

	SSLEngine on
	SSLProtocol all -SSLv2
	SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:RC4+RSA:+HIGH:+MEDIUM:+LOW
	SSLCertificateFile /etc/pki/tls/certs/ca.crt
	SSLCertificateKeyFile /etc/pki/tls/private/ca.key
	#SSLCertificateChainFile /etc/pki/tls/certs/server-chain.crt
	#SSLCACertificateFile /etc/pki/tls/certs/ca-bundle.crt

	#SSLVerifyClient require
	#SSLVerifyDepth  10

	<Files ~ "\.(cgi|shtml|phtml|php3?)$">
		SSLOptions +StdEnvVars
	</Files>
	<Directory "/var/www/cgi-bin">
		SSLOptions +StdEnvVars
	</Directory>

	SetEnvIf User-Agent ".*MSIE.*" \
         nokeepalive ssl-unclean-shutdown \
         downgrade-1.0 force-response-1.0

	CustomLog logs/ssl_request_log \
          "%t %h %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b"

</VirtualHost> 
EOF


systemctl enable --now httpd
systemctl enable --now vsftpd

echo "---- Environment setup complete ----"; echo ""
echo "------------------------------------------"
echo " With great power, comes great opportunity"
echo "------------------------------------------"
