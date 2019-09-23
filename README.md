# QNAP-Docker-Swarm-Setup
A guide for configuring the docker swarm stack on QNAP devices with Container Station
###  Docker Swarm Setup
#### Preparation
- Ports 80 and 443 must be unused on your NAS. By default, QTS assigns both ports to the Web Server application. Please change this (in QNAP GUI Settings, Applications, Web Server) to 9080 and 9443 to ensure no port conflicts with docker stacks. You should consider disabling both the Web Server and MySQL applications in the QNAP GUI Settings.
- Ports 80 and 443 must be forwarded from your router to your NAS. This is *possible* using UPNP in the QNAP GUI, but **this is not recommended. Instead, disable UPNP at the router and manually forward ports 80 and 443 to your NAS.**

Steps:

1. Backup what you have running now (if you don't have anything running yet, skip to Step 3 or 5)

2. Shutdown and remove all Containers:
   - Open terminal and run `docker system prune`
   - Run `docker network prune` for good measure
   - Run `docker swarm leave --force` (just to be sure you don't have a swarm left hanging around)

3. Remove Container Station

4. Reboot NAS

5. Install Container Station and launch once installed, creating the Container folder suggested when opening

6. Create a new user called _dockeruser_

7. Create the following folder shares and give _dockeruser_ Read/Write permissions:
   - `/share/appdata` - Here we will add a folder <stack name>. This is where your application files live... libraries, artifacts, internal application configuration, etc. Think of this directory much like a combination of `C:/Windows/Program Files` and `C:\Users\<UserName>/AppData` in Windows.
   - `/share/appdata/config` - Here we will also add a folder <stack name>. Inside this structure, we will keep our actual _stack_name.yml_ files and any other necessary config files used to configure the docker stacks and images we want to run. This folder makes an excellent GitHub repository for this reason.
   - `/share/runtime` - This is a shared folder on a volume that does not get backed up. It is where living DB files and transcode files reside, so it would appreciate running on the fastest storage group you have or in cache mode or in Qtier (if you use it). Think of this like the `C:\Temp\` in Windows.

8. Run `id dockeruser` in terminal and note the uid and gid

9. Run `docker network ls`. You should see 3 networks, bridge, host, and null

10. Run `docker swarm init --advertise-addr <YOUR NAS IP HERE>` - Use ***YOUR*** nas IP

11. Run `docker network create --driver=overlay --subnet=172.1.1.0/22 --attachable traefik_public`

12. **Checkpoint:** Run `docker network ls`. Does the list of networks contain one named `docker_gwbridge`?
The networks should match the following (except the generated NETWORK ID):

```[~] # docker network ls
NETWORK ID          NAME                   DRIVER              SCOPE
c4419b39cef0        bridge                 bridge              local
637ba589dd70        docker_gwbridge        bridge              local
5bd5c1601ef7        host                   host                local
kr4kpxr5a72x        ingress                overlay             swarm
a0982a1fc7f6        none                   null                local
```

**Important: If your configuration is lacking a docker_gwbridge or differs from this list**, please contact someone on the [QNAP Unofficial Discord](https://discord.gg/rnxUPMd) (ideally in the [#docker-stack channel](https://discord.gg/MzTNQkV)). Do not proceed beyond this point unless your configuration matches the one above, unless you embrace pain and failure and love very complicated problems that could be QNAP's fault.

13. Install the `entware-std` package from the third-party QNAP Club repository. This is necessary in order to setup the shortcuts/aliases in Steps 18 & 19 by editing a permanent profile.
    - The preferred way to do this is to add the QNAP Club Repository to the App Center. Follow the [walkthrough instructions here](https://www.qnapclub.eu/en/howto/1). Note that I use the English translation of the QNAP Club website, but you may change languages (and urls) in the upper right language dropdown.
    - If you don't need the walkthrough, add the repository. (For English, go to App Center, Settings, App Repository, Add, `https://www.qnapclub.eu/en/repo.xml`).
    - If you have trouble locating the correct package below, the correct description begins `entware-3x and entware-ng merged to become entware.` The working link (as of publication) is here: https://www.qnapclub.eu/en/qpkg/556. If you **cannot** add the QNAP Club store to the App Center, you may manually download the qpkg file from that link and use it to install manually via the App Center, "Install Manually" button. This is **not preferred** as QNAP cannot check for and notify you of updates to the package.
    - Search for `entware-std` and install that package.

**Important: DO NOT CHOOSE either the `entware-ng` or `entware-3x-std` packages. These have merged and been superceded by `entware-std`.**

14.  Run `mkdir -p /share/appdata/traefik`

15.  Run `mkdir -p /share/appdata/config/traefik`

16.  Run `mkdir -p /share/runtime/traefik`

17.  Install nano or vi, whichever you are more comfortable with (e.g. Run `opkg install nano` or `opkg install vim`)

18.  Run `nano /opt/etc/profile` (or `vi /opt/etc/profile` if that is your thing)

19.  Add the following lines to the end of the file and save

```
dsd() {
	docker stack deploy "$1" -c /share/appdata/config/"$1"/"$1".yml
}
dsr() {
	docker stack rm "$1"
}
bounce(){
 docker stack rm "$1"
 sleep 15
 docker stack deploy "$1" -c /share/appdata/config/"$1"/"$1".yml
}
dcu(){
 docker-compose -f /share/appdata/config/"$1"/"$1".yml up -d
}
dcd(){
 docker-compose -f /share/appdata/config/"$1"/"$1".yml down
}
dfc() {
	bash /share/appdata/scripts/folder_setup.sh "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
}
dup() {
	bash /share/appdata/scripts/restart_stack.sh
}
dsp() {
	bash docker system prune -f
}
dsrms() {
	bash /share/appdata/scripts/remove_stack.sh
}
dss() {
	bash /share/appdata/scripts/setup_stack.sh
}
```

Remember these shortcut names:
- **dsd** deploys a single stack - e.g. `dsd traefik`
- **dsr** removes a single stack - e.g. `dsr traefik`
- **bounce** removes a single stack and recreates it - e.g. `bounce traefik`
- **dfc** creates the folder structure for a single (or multiple) stack. If you want to setup multiple stack folders use `dfc plex ombi PiHole` (up to 9 stacks at a time). Simplest example: e.g. `dfc plex` would create:
  - /share/appdata/plex
  - /share/appdata/config/plex
  - /share/runtime/plex
- **dup** starts existing stacks declared in `/share/appdata/scripts/restart_stack.sh`
- **dsp** prunes the docker system.  Any containers or networks not running will be removed -e.g. `dsp`
- **dsrms** will remove all stacks, prune the docker system, remove any overlay networks, and leave the swarm - e.g. `dsrms` (use with care!)
- **dss** will create a new swarm, create a new overlay network, start all stacks declared in `/share/appdata/scripts/setup_stack.sh`

** See below for scripts that need to be created and added to `/share/appdata/scripts` folder

***NOTE:*** You will need to restart your ssh or cli session in order to make the profile changes effective.

***NOTE:*** If you use a Windows client to save the profile (or the scripts), they will be saved with CR LF and will error.  Please set the file format to UNIX (LF) in order for the profile and scripts to work correctly.

20. Edit _traefik.env_ and put your cloudflare email and GLOBAL API KEY in lines 7&8 (If you are not using cloudflare you will need to check with the Traefik documentation to add the correct environment settings to your _traefik.env_ file)
21. Edit _traefik.yml_ and _traefik.toml_ to include your domain name
22. Add the provided 3 traefik files to `/share/appdata/config/traefik` (.yml, .toml, .env)
23. ``touch acme.json`` in the folder and set permissions to 600
24. Check `traefik.<yourdomain.com>` resolves to your WAN IP (Run `ping traefik.<yourdomain.com>` - Press `ctrl+c` to stop the ping)
25. Run `dsd traefik` to start the traefik container
26. Follow _ForwardAuth Setup Steps_ below
27. Enjoy Traefik and add more containers.
---
### ForwardAuth Setup Steps
1. Go to https://auth0.com
2. Sign in or register an account
3. Note Tenant Domain provided by Auth0
4. Login or create an account with https://github.com
5. Go to _Settings -> Developer Settings - OAuth Apps_
6. Create a new app (call it something to recognize it is linked to Auth0)
7. Note the client Id and Secret
8. Add homepage URL as `https://<yourauth0accounthere>.auth0.com/`
9. Add authorization callback URL as `https://<yourauth0accounthere>.auth0.com/login/callback`
10. Go back to Auth0
11. Go to _Connections -> Social_
12. Select _Github_ and enter in your Github app ClientID and secret Credentials - **NOTE:** ENSURE _Attribute "Email Address"_ is ticked
13. Create an application on Auth0 (regular web app)
14. Use the Auth0 clientID and Client Secret in your _application.yaml_ file
15. Make sure to specify POST method of token endpoint authentication (Drop down box)
16. Enter in your Callback URL (`https://<service>.<domain>/signin` & `https://<service>.<domain>/oauth/signin`)
17. Enter your origin URL (`https://<your URL here>`) and save changes
18. Go to Users & Roles and Create a user with a real email address.  You will use this later so remember it
19. Click on _Rules -> Whitelist_
20. Enter in your email address into the whitelist field (e.g. `Line 8 "const whitelist = [ '<your email here>']; //authorized users"`)
21. Open ssh and `dsr traefik`, wait 10 seconds and `dsd traefik`
22. Wait 30 seconds and then launch `https://traefik.<yourdomainhere>`
23. Enter Auth0 authentication login to reach traefik dashboard
---
### Scripts Setup
Please create these scripts and save them to `/share/appdata/scripts` if you want to use the cli shortcuts we created in earlier steps.  **NOTE:** `setup_stack.sh` requires you to add your NAS IP for it to work.
All the stack scripts (`xxx_stack.sh`) require you to edit the stacks list to match your setup.  If you do not edit them they will fail to deploy the stacks you don't have .. nothing blows up, no bunnies die, just a big pile of nothingness in your swarm.
***NOTE:*** Please ensure you save these files in UNIX (LF) format.  Windows (CR LF) format will break these scripts.  If you are a Windows user, please download the files in the scripts folder above.

##### folder_setup.sh

```
#!/bin/bash
# Script to create gkoerk's famously awesome folder structure for stacks

# Set folder paths here (you should not need to change these, but if you do, it will save a load of typing)
appdata=/share/appdata
config=/share/appdata/config
runtime=/share/runtime

# Help message for script
helpFunction() {
    echo ""
    echo "Usage: $0 -f <folder name>"
    echo -f "-f name of folder(s) you wish to add. For more than one folder, use -f <folder name 1> <folder name 2> ... <folder name 9>. You can have 9 folder names in a single command"
    exit 1 # Exit script after printing help
}

# Print helpFunction in case parameters are empty
if [ -z "$1" ]; then
    echo "Please enter at least one folder name"
    helpFunction
fi

# Create folder structure

mkdir -p $appdata/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
mkdir -p $config/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
mkdir -p $runtime/{$1,$2,$3,$4,$5,$6,$7,$8,$9}

echo "The following folders were setup:"
echo " - $@"

```

##### restart_stack.sh

```
#!/bin/bash
# define services - Add stacks to this list between the brackets
# Leave Traefik out of the list as it will be started separately
stacks=(portainer docker-cleanup
    shepherd wetty guacamole
    emby privatebin autopirate hackmd
)
# define config folder
config_folder=/share/appdata/config

echo "**** Starting Traefik ****"
# Traefik needs to be the first stack deployed
docker stack deploy traefik -c ${config_folder}/traefik/traefik.yml

# Pruning the stack is optional ... comment out if you don't want to do this step
echo "***** Pruning the stack *****"
docker system prune -f
echo "**** System pruned ****"

echo "**** Starting Other Stacks ****"
# restart all services in docker swarm

# loop through stacks defined above
for stack in "${stacks[@]}"; do
    echo "**** Starting $stack ****"
    docker stack deploy $stack -c ${config_folder}/${stack}/${stack}.yml
    echo "***** Sleeping for a bit*****"
    sleep 10
    echo "**** $stack has been started ****"
done

echo "**** All Stacks have been started ****"

```

##### remove_stack.sh

```
#!/bin/bash
# define services - Add stacks to this list between the brackets
stacks=(portainer docker-cleanup
    shepherd wetty guacamole
    emby privatebin autopirate hackmd
)
# define config folder
config_folder=/share/appdata/config

echo "**** Removing Stacks ****"
# remove all services in docker swarm

# loop through stacks defined above
for stack in "${stacks[@]}"; do
    echo "**** Removing $stack ****"
    docker stack rm $stack
    echo "***** Sleeping for a bit*****"
    sleep 15
    echo "**** $stack has been removed ****"
done
echo "**** Removing Traefik ****"
# traefik needs to be last
docker stack rm traefik
echo "**** All Stacks have been removed ****"
echo "***** Sleeping for a bit *****"
sleep 15
echo "***** Pruning the stack *****"
docker system prune -f
echo "**** System pruned ****"
docker swarm leave -f
echo "***** Swarm Left *****"

```

##### setup_stack.sh

```
#!/bin/bash
# NOTE YOU NEED TO SET YOUR NAS IP BELOW FOR THE SWARM!!
echo "***** Setting up Swarm *****"
# setup Swarm
docker swarm init --advertise-addr <ENTER YOUR NAS IP HERE>

echo "***** Sleeping for a bit*****"
sleep 15

echo "***** Setting up overlay network *****"
# setup the overlay network
docker network create --driver=overlay --subnet=172.1.1.0/22 --attachable traefik_public

# define services - Add stacks to this list between the brackets
# Leave Traefik out of the list as it will be started seperately
stacks=(portainer docker-cleanup
    shepherd nextcloud graylog wetty
    plex privatebin autopirate
)
# define config folder
config_folder=/share/appdata/config

echo "**** Starting Traefik ****"
# Traefik needs to be the first stack deployed
docker stack deploy traefik -c ${config_folder}/traefik/traefik.yml

echo "**** Starting Other Stacks ****"
# restart all services in docker swarm

# loop through stacks defined above
for stack in "${stacks[@]}"; do
    echo "**** Starting $stack ****"
    docker stack deploy $stack -c ${config_folder}/${stack}/${stack}.yml
    echo "***** Sleeping for a bit*****"
    sleep 15
    echo "**** $stack has been started ****"
done

echo "**** All Stacks have been started ****"

```
