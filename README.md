# Compose arena services

The [docker-compose.yaml](docker-compose.yaml) creates several containers with ARENA services:

* Web server for ARENA (Nginx)
* Database (MongoDB)
* Pubsub (mosquitto)
* Persistence service
* Auth service
* ARTS
* File Store
* Certbot

Source repositories (such as ARENA-core, ARENA-auth, arena-persist) are submodules of this repo. Containers are created from these files. ARENA-core is served by the nginx container.

Nginx and mosquitto are configured with TLS/SSL using certificates created by certbot (running as a service in a container), which will periodically attempt to renew the certificates. On the first execution, the configuration files must be initialized by running **init.sh**.

## Quick Setup

1. We need [docker](https://docs.docker.com/get-docker/),  [docker-compose](https://docs.docker.com/compose/install/) and [envsubst](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html) installed. The [init](init.sh) script needs a bash shell. See [Dependencies](dependencies-assumptions) section for details.

2. Clone this repo (with ```--recurse-submodules``` to make sure you get the contents of the repositories added as submodules):

```bash
git clone git@github.com:conix-center/arena-services-docker.git --recurse-submodules
```

If ```recurse-submodules``` fails, or you forget to add it in the first clone, you can enter the repo folder and:

```bash
git submodule update --init
```

3. Modify configuration:

- Edit hostname and email addresses in [environment.env](environment.env). This should reflect your setup.

```bash
HOSTNAME="arena.andrew.cmu.edu"
EMAIL="wiselab.develop@gmail.com"
```

4. Run init script:

```bash
 ./init.sh
```

* Note: you might need to execute ```sudo ./init.sh``` if your user does not have permissions to access the docker service.

5. If you see no errors; you are good to start all services:

```bash
 ./start-prod.sh
```

Or, for development,:
```bash
 ./start-dev.sh
```

* Note: you might need to execute using ```sudo``` if your user does not have permissions to access the docker service.

For more details, see [Init Config](init-config) Section below.

4. Open the file store management interface and change the default admin password (**user**:admin;**pass**:admin). To open the file store, point to ```/storemng``` (e.g. ```https://arena.andrew.cmu.edu/storemng```) in your browser. See details in the [File Store](file-store) Section below.

## Dependencies/Assumptions

###Install:

* **docker:**	https://docs.docker.com/get-docker/
* **docker-compose:**	https://docs.docker.com/compose/install/
* **envsubst:**	utility part of [gettext](https://www.gnu.org/software/gettext/manual/html_node/envsubst-Invocation.html). See instructions on how to install in different OSes [here](https://www.drupal.org/docs/8/modules/potion/how-to-install-setup-gettext).

###Assumptions:

* **init.sh:** assumes a bash shell
* **backup user:**	The ```backup``` service tries to change to owner of the files backed up to a user indicated in [environment.env](environment.env). This is the ```user:group``` of the *host machine user* that needs to access the files backed up.

## Init Config

Before starting services, we need to create the configuration files for the services with the right domains and initialize letsencrypt.

1. Modify configuration:

- Edit hostname, email address and backup user (```user:group``` of the *host machine user* that needs to access the files backed up by the backup container configured in [docker-compose.prod.yaml](docker-compose.prod.yaml)) in [environment.env](environment.env). This should reflect your setup.
- **Localhost setup**: If you want a local development setup, you can setup a hostname that resolves locally (for example ```arena-local```) by add the following line to your hosts file (```/etc/hosts```):
```bash
127.0.0.1       arena-local
```

2. Run the init script:

```bash
 ./init.sh
```

The init script will generate configuration files (from the templates in [conf/templates](conf/templates)) for the services using the hostname and email configured in [environment.env](environment.env), and attempt to create certificates using letsencrypt. **If letsencrypt fails, it will create a self-signed certificate that can be used for testing purposes**.

* Note: you might need to execute ```sudo  docker-compose up -d``` if your user does not have permissions to access the docker service.

3. Start all services:

- For production:
```bash
  docker-compose -f docker-compose.yaml -f docker-compose.prod.yaml up -d
```

- For development (no monitoring/backups):
```bash
 docker-compose up -d
```

* Note: you might need to execute the above commands with ```sudo``` if your user does not have permissions to access the docker service. You can also use the ```start-prod.sh``` and ```start-dev.sh``` utility scripts.

## File Store

The web server files under ```/store``` (e.g. ```https://arena.andrew.cmu.edu/store```) can be uploaded via a web interface available at ```/storemng```  (e.g. ```https://arena.andrew.cmu.edu/storemng```) . The store admin password should be changed on the first execution and other users can then be added.

**Be sure to open the ```/storemng``` URL on your browser and change the *admin* user default password (*admin*).**

## Update Submodules

To update the repositories added as submodules (**ARENA-core** and **arena-persist**), run:

```bash
./update-submodules.sh
```

After updating the submodules, to have the updates of built containers (persist, arts, python-rt) reflected live, you will need to restart the services and rebuild the containers as follows.

- For production:
```bash
docker-compose -f docker-compose.yaml -f docker-compose.prod.yaml down; docker-compose -f docker-compose.yaml -f docker-compose.prod.yaml up -d --force-build
```

- For development:
```bash
docker-compose down; docker-compose up -d --force-build
```

* Note: you might need to execute the above commands with ```sudo``` if your user does not have permissions to access the docker service.

*  See [Compose Quick Reference](compose-quick-reference) for the description of these commands.

## Files/Folders Description

* **ARENA-core:**	Contents of the ARENA-core repository (submodule).
* **arena-persist:**	Contents of the arena-persist repository (submodule).
* **arena-runtime-simulated:**	Contents of the arena-runtime-simulated repository (submodule).
* **ARENA-auth:**	Contents of the ARENA-auth repository (submodule).
* **arts:**	Contents of the arts repository (submodule).
* **conf:** Configuration files for the services (e.g. certificates, mosquito, nginx, persistence). Most files are generated at init time, using the files in the **templates** folder. Some important files described below
  * *templates/mosquitto.tmpl*: used to generate **mosquitto.conf**. Configures listeners on ports 8833 (mqtt), 9001 (mqtt-ws), 8083 (mqtt-wss) and 8883 (mqtt-tls); certificate files under ```/data/certbot/conf``` are mapped to ```/etc/letsencrypt``` in the container.
  * *templates/arena-web.tmpl*: used to generate **nginx-conf/arena-web.conf**. Configures the web server to serve a proxy to port 9001 under ```/mqtt/```, forwards requests to```/persist/``` to the **arena-persist** service and requests tp ```/storemng``` to the **store** service;  certificate files under ```/data/certbot/conf``` are mapped to ```/etc/letsencrypt``` in the container.
  * *persist-config.json*: configures the mongodb uri to the container service name.
  * *templates/arts-settings.tmpl*: used to generate **arts-settings.py**, the configuration of arts.
  * *templates/auth-config.tmpl*: used to generate **auth-config.json**, the configuration of the auth service.
* **data:** Data files (e,g, certificates generated by certbot, mongodb database, ...).
* **docker-compose.override.yaml:** Compose file that describes services. This is the file used by default by ```docker-compose``` and is intended for development purposes
* **docker-compose.yaml:** Compose file that describes the base services. Use this with the ```docker-compose.prod.yaml``` to create the production config.
* **docker-compose.prod.yaml:** Compose file that describes production services. Relies on the base config in ```docker-compose.yaml``` to create the final production config.
* **init-letsencrypt.sh:** Initialize certbot. Called by **init.sh**.
* **init.sh:** Initialize config files. See [Init Config](init-config) Section.
* **update-submodules.sh:** Run this to get the latest updates from the repositories added as submodules (**ARENA-core**, **arena-persist**). You will need to restart the services to have the changes live (see [Update Submodules](update-submodules)).

## Compose Quick Reference

**NOTE**: By default, docker-compose will use the configuration in [docker-compose.override.yaml](docker-compose.override.yaml). To start the production config, you need to indicate ```-f docker-compose.yaml -f docker-compose.prod.yaml```. See details about using multiple configuration files in the [docker the documentation](https://docs.docker.com/compose/extends/). *You might need to execute the docker commands with ```sudo``` if your user does not have permissions to access the docker service*.

**Start services and see their output/logs**

- ```docker-compose up``` (add ```--force-build  ``` to build containers after updating submodules)

**Start the services in "detached" (daemon) mode (-d)**

- ```docker-compose up -d``` (add ```--force-recreate  ``` to recreate containers after updating submodules)

**Start just a particular service**

- ```docker-compose start <service name in docker-compose.yaml>```

**Stop services**

- ```docker-compose down```

**Restart the services**

- ```docker-compose restart```

**See logs**

- ```docker-compose logs```
