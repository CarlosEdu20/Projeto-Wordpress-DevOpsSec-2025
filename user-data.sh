#!/bin/bash
sleep 25
apt update -y

apt install -y apt-transport-https ca-certificates curl software-properties-common nfs-common


install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update -y

apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu 


apt install docker-compose-plugin -y


EFS_ID="fs-0b340dbc5e8755c0a"
AWS_REGION="us-east-2"
EFS_MOUNT_POINT="/mnt/efs-wordpress"

mkdir -p ${EFS_MOUNT_POINT}
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${EFS_ID}.efs.${AWS_REGION}.amazonaws.com:/ ${EFS_MOUNT_POINT}
echo "${EFS_ID}.efs.${AWS_REGION}.amazonaws.com:/ ${EFS_MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,_netdev 0 0" >> /etc/fstab


PROJECT_DIR="/home/ubuntu/wordpress-project"
mkdir -p ${PROJECT_DIR}
WORDPRESS_FILES_PATH="${EFS_MOUNT_POINT}/html"
mkdir -p ${WORDPRESS_FILES_PATH}

DB_HOST="wordpress-db.cd4k44mq0kyk.us-east-2.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="carlos10"
DB_NAME="wordpress-db"

cat <<EOF > ${PROJECT_DIR}/docker-compose.yml
version: '3.8'
services:
  wordpress:
    image: wordpress:php8.3-apache
    container_name: wordpress
    restart: always
    ports:
      - "80:80"
    environment:
      WORDPRESS_DB_HOST: ${DB_HOST}
      WORDPRESS_DB_USER: ${DB_USER}
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
      WORDPRESS_DB_NAME: ${DB_NAME}
    volumes:
      - ${WORDPRESS_FILES_PATH}:/var/www/html/

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: phpmyadmin
    restart: always
    ports:
      - "8080:80"
    environment:
      PMA_HOST: ${DB_HOST}
      PMA_PORT: 3306
EOF

sudo chown -R 33:33 ${WORDPRESS_FILES_PATH}
cd ${PROJECT_DIR}
docker compose up -d
