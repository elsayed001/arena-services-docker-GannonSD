#!/bin/bash

echo -e "\n### Creating secret.env (with secret keys, admin password). This will replace old secret.env (if exists; backup will be in secret.env.bak)."
read -p "Continue? (y/N) " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  SECRET_KEY=$(LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c40)
  SECRET_KEY_BASE64=$(echo $SECRET_KEY | base64)
  ACCOUNT_SU_PASSWORD=$(LC_ALL=C tr -dc '[:alnum:]' < /dev/urandom | head -c15)
  cp secret.env secret.env.bak
  echo "SECRET_KEY="$SECRET_KEY > secret.env
  echo "SECRET_KEY_BASE64="$SECRET_KEY_BASE64 >> secret.env
  echo "ACCOUNT_ADMIN_PASSWORD="$ACCOUNT_SU_PASSWORD >> secret.env

  chown $OWNER secret.env # change ownership of file created
fi

echo -e "\n### Contents of .env:\n"
cat .env
echo

echo -e "Please edit the file .env (shown above) to reflect your setup (hostname, email, ...). \n(this will generate certificates, nginx config, ...)."
read -p "Continue? (y/N)" -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Stopped."
    exit 1
fi

echo -e "\n### Creating data folders\n"
data_folders=( "data/arena-store" "data/grafana"  "data/mongodb"  "data/prometheus" "data/account")
mkdir data
for d in "${data_folders[@]}"
do
  echo $d
  [ ! -d "$d" ] && mkdir $d && chown $OWNER $d
done

# make sure account db file exists
touch data/account/db.sqlite3 

# setup escape var for envsubst templates
export ESC="$"

echo -e "\n### Creating config files (conf/*) from templates (conf-templates/*)"
[ ! -d conf ] && mkdir conf && chown $OWNER conf
for t in $(ls conf-templates/)
do
  f="${t%.*}"
  cp conf/$f conf/$f.bak >/dev/null 2>&1
  echo -e "\t conf-templates/$t -> conf/$f"
  envsubst < conf-templates/$t > conf/$f
  chown $OWNER conf/$f
done
