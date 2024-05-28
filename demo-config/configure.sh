#!/bin/bash

# This file configures and builds local containers to run this Helm example. 
# The containers are built using the GREN Mapping Project development environment
# with some config from this project for settings.
#
# The containers are build with appropriate SSO configuration for bi-lateral trust
# between the SP and IdP.  

GREEN='\033[0;32m'
RED='\033[0;31m'
OFF='\033[0m'
SPACE='echo -e \n'
AUTO=AUTO_ADDED_BY_CONFIGURE
ENV_FILE=env

# Constants for the development environment code
GREN_MAP_DEV_DIR=GREN-Map-DB-Node
GREN_MAP_REPO=https://github.com/grenmap/GREN-Map-DB-Node.git

if ! grep -q DOCKER_DEFAULT_PLATFORM $ENV_FILE; then
  echo -e "${GREEN}Adding DOCKER_DEFAULT_PLATFORM environment variable to build environment (./$ENV_FILE)${OFF}"
  # Update the environment file 
  echo "# Autodetected platform linux/$(uname -m) for container builds. $AUTO" >> $ENV_FILE
  echo "# If this is incorrect for your system then manually replace with your platform. $AUTO" >> $ENV_FILE
  echo "DOCKER_DEFAULT_PLATFORM=linux/$(uname -m) # $AUTO" >> $ENV_FILE
else
  echo -e "${GREEN}DOCKER_DEFAULT_PLATFORM already exists in build environment (./$ENV_FILE)${OFF}"
fi

if [ ! -d "$GREN_MAP_DEV_DIR" ]; then
  echo -e "${GREEN}Cloning the GREN Mapping Project development environment from $GREN_MAP_REPO.${OFF}"
  git clone $GREN_MAP_REPO
else
  echo -e "${GREEN}GREN Mapping Project development directory already exists, continuing.${OFF}"
fi
$SPACE

echo -e "${GREEN}Copying over the environment files for the container configuration.${OFF}"
$SPACE
cp ./env $GREN_MAP_DEV_DIR/.env
cp ./env.dev $GREN_MAP_DEV_DIR/env/.env.dev

echo -e "${GREEN}Copying over the sample user file for the demonstration.${OFF}"
$SPACE
cp ./users.ldif $GREN_MAP_DEV_DIR/openldap/container_files/ldif/

echo -e "${GREEN}Running the helper script to generate keys and perform bi-lateral trust exchange with the IdP${OFF}"
$SPACE
cd $GREN_MAP_DEV_DIR
./config_sso.sh
$SPACE

echo -e "${GREEN}Copying the SP certificates and keys for use in the Helm deployment.${OFF}"
$SPACE
cp ./websp/configs_and_secrets/*.pem ../../

echo -e "${GREEN}Build development environment containers locally for use by the Helm example. As it is a development container the SP is built pre-trusting the IdP.${OFF}"
# Make sure the IdP is down before we start
$SPACE
docker compose -f docker-compose.idp.yml down
docker compose -f docker-compose.yml -f docker-compose.dev.yml -f docker-compose.idp.yml build --no-cache
$SPACE
docker image ls
$SPACE 

# Print instructions to start idp
echo -e "${GREEN}The GREN Mapping Project development containers have now been built with matching config from this Helm example and the bi-lateral metadata has been exchanged."
echo -e "Please run: docker ps -a to ensure the IdP is running ad healthy before attempting to login to the map." 
echo -e "Follow the instructions in the main README.md for running the map via Helm.${OFF}"
echo -e "To stop the IdP instance run: docker compose -f docker-compose.idp.yml down"

echo -e "${GREEN}Running the IdP and LDAP containers using docker compose.${OFF}"
$SPACE
docker compose -f docker-compose.idp.yml up -d
