#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
OFF='\033[0m'

SPACE='echo -e \n\n'

echo 'Normal text'
echo -e "${GREEN}Green text ${OFF}"

$SPACE
echo 'Normal text'
echo -e "${RED}Red text ${OFF}"
$SPACE
echo 'Normal text'

GREN_MAP_DEV_DIR=GREN-Map-DB-Node
GREN_MAP_REPO=https://github.com/grenmap/GREN-Map-DB-Node.git

echo -e "${GREEN}Copying over the environment files for the container configuration.${OFF}"
cp ./env $GREN_MAP_DEV_DIR/.env
cp ./env.dev $GREN_MAP_DEV_DIR/env/.env.dev
cp ./users.ldif $GREN_MAP_DEV_DIR/openldap/container_files/ldif/
