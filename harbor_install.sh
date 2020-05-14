#!/bin/bash
# harbor_install.sh
# CenOS7+
# WXG

set -e

HARBOR_FQDN=reg.sre.im
# must be full path and filename is start with $HARBOR_FQDN
CERT_PUB=
# must be full path and filename is start with $HARBOR_FQDN
CERT_KEY=

INSTALL_DIR=/usr/local/harbor
HARBOR_VERSION=$(curl -s https://github.com/goharbor/harbor/releases/latest/download |
    grep -Po [0-9]+\.[0-9]+\.[0-9]+)


[[ -d $INSTALL_DIR ]] && [[ $(ls -A $INSTALL_DIR) != "" ]] && {
    echo "install dir $INSTALL_DIR already exsit, exit." >&2
    exit 1
}

mkdir -p $INSTALL_DIR/certs && cd $INSTALL_DIR

self_sign_cert(){
    # self-signed cert
    openssl req \
        -newkey rsa:4096 -nodes -sha256 -keyout certs/${HARBOR_FQDN}.key \
        -x509 -days 365 -out certs/${HARBOR_FQDN}.crt <<EOF
CN
BJ
BJ
LTD
ORG
$HARBOR_FQDN
admin@sre.im

EOF

    # for docker cli request https://$HARBOR_FQDN if use self-signed cert
    mkdir -p /etc/docker/certs.d/$HARBOR_FQDN
    cp $INSTALL_DIR/certs/${HARBOR_FQDN}.crt $_
}

# if authorized cert not provided, use self-signed cert
if [[ ! -f "$CERT_PUB" ]] || [[ ! -f "$CERT_KEY" ]]; then
    self_sign_cert
else
    cp $CERT_PUB $CERT_KEY certs/
fi

# download harbor latest version
curl -s https://api.github.com/repos/goharbor/harbor/releases/latest |
    grep browser_download_url.*online | cut -d '"' -f 4 | wget -qi -

tar xf harbor-online-installer-v${HARBOR_VERSION}.tgz

# configure
cd harbor
cp harbor.yml.tmpl harbor.yml
sed -i "s/reg.mydomain.com/$HARBOR_FQDN/g;
    s#/your/certificate/path#$INSTALL_DIR/certs/${HARBOR_FQDN}.crt#;
    s#/your/private/key/path#$INSTALL_DIR/certs/${HARBOR_FQDN}.key#;" harbor.yml

# install harbor
./install.sh --with-clair --with-chartmuseum

# systemd service 
cat > /usr/lib/systemd/system/harbor.service <<EOF
[Unit]
Description=Harbor
After=docker.service systemd-networkd.service systemd-resolved.service
Requires=docker.service
Documentation=https://github.com/goharbor/harbor

[Service]
Type=simple
Restart=on-failure
RestartSec=5
ExecStart=/usr/local/bin/docker-compose -f $INSTALL_DIR/harbor/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose -f $INSTALL_DIR/harbor/docker-compose.yml down

[Install]
WantedBy=multi-user.target
EOF

# start on reboot
systemctl enable harbor

echo "
Harbor installation complete, and harbor already running...

Stop harbor:
sudo systemctl stop harbor

Start harbor:
sudo systemctl start harbor

Login to your harbor instance on linux terminal:
docker login -u admin -p Harbor12345 $HARBOR_FQDN

Docker image push:
docker image tag python:3.8 reg.sre.im/library/python:3.8
docker image push \$_

Web UI(login: admin/Harbor12345):
https://$HARBOR_FQDN
"

exit 0
