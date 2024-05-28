#!/bin/bash

# This file will clean up after the ./configure script by stopping the containers (if running), 
# deleteing the dev repository and removing any changes made to the environment file.
#
# It will additionally remove the secrets from kubectl.

GREEN='\033[0;32m'
RED='\033[0;31m'
OFF='\033[0m'
AUTO=AUTO_ADDED_BY_CONFIGURE
ENV_FILE=env

GREN_MAP_DEV_DIR=GREN-Map-DB-Node

echo -e "${RED}WARNING, this will delete the devlopment environment directory and remove all secrets.${OFF}"
read -p "Are you sure? Y or N " -n 1 -r REPLY
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${GREEN}Removing Kubernetes secrets.${OFF}"
    kubectl delete secret websp-keys-certs
    kubectl delete secret postgres-passwd-and-secret-key 

    echo -e "${GREEN}Delete Certificates and Keys.${OFF}"
    rm -f ../host-cert.pem ../host-key.pem ../sp-cert.pem ../sp-key.pem

    if [ -d "$GREN_MAP_DEV_DIR" ]; then
        echo -e "${GREEN}Stopping the docker compose IdP.${OFF}"
        cd $GREN_MAP_DEV_DIR
        docker compose -f docker-compose.idp.yml down
        cd ..

        echo -e "${GREEN}Removing GREN Map DB Node code.${OFF}"
        rm -rf $GREN_MAP_DEV_DIR
    fi

    echo -e "${GREEN}Cleaning autodetected DOCKER_DEFAULT_PLATFORM from $ENV_FILE.${OFF}"
    grep -v "$AUTO" $ENV_FILE > tmp_file && mv tmp_file $ENV_FILE

    echo -e "${GREEN}Done.${OFF}"
fi
