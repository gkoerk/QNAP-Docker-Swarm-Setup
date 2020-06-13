<a href="https://liberapay.com/gkoerk/donate"><img alt="Donate using Liberapay" src="https://liberapay.com/assets/widgets/donate.svg"></a>

<img src="http://img.shields.io/liberapay/patrons/gkoerk.svg?logo=liberapay">

Please consider joining and contributing to the [QNAP Unofficial Discord](https://discord.gg/rnxUPMd).
- You gain access to a community built around advice on everything QNAP.
- Additional community resources: Subreddit, Blog, Wiki, FAQs, CI/CD, Community Docker images, etc.

---------------------------------------

# QNAP Docker Swarm Setup

  A guide for configuring the docker swarm stack on QNAP devices with Container Station

---------------------------------------

## 1. Preparation

- **Ports 80, 443, and 8080 *must be _unused_ by your NAS.*** 
  - By default, QTS assigns ports 8080 and 443 as the default HTTP and HTTPS ports for the QNAP Web Admin Console, and assigns 80 as the default HTTP port for the native "Web Server" application. Each of these must be modified to proceed with this guide.
- Modify these ports as follows to ensure there will be no port conflicts with docker stacks:
  - **Change default System ports:** In QNAP Web GUI, `Control Panel >> System >> General Settings`, change the default HTTP port to `8880`, and the default HTTPS port to `8443`. 
  - **Change default Web Application ports:** In QNAP Web GUI, `Control Panel >> Applications >> Web Server`, change the default HTTP port to `9880`, and the default HTTPS port to `9443`.
  - Unless currently in use, consider disabling both the Web Server and MySQL applications in the QNAP GUI Settings.
- **Ports 80 and 443 must be forwarded from your router to your NAS**. This is *possible* using UPNP in the QNAP GUI, but ***is not recommended!***
  - **Instead, disable UPNP at the router and manually forward ports 80 and 443 to your NAS.**
  - ***NOTE:*** There are too many possible routers to cover how to forward ports on each, but there are some good guides here if you don't know how to do it for your router: (https://portforward.com/router.htm) or (https://www.howtogeek.com/66214/how-to-forward-ports-on-your-router/)

---------------------------------------

## 2. Container Station Steps

1. Backup what you have running now (if you don't have anything running yet, skip to Step 3 or 5)

2. Shutdown and remove all Containers:
  - Open SSH terminal to your NAS and run: 
    `docker system prune`
  - To ensure the network topography is reset, run:
    `docker network prune`
  - To be sure you don't have a swarm left hanging around, run:
    `docker swarm leave --force`

3. Remove Container Station:
   - In App Center, click the dropdown for Container Station and choose `Remove`
   - In Control Panel >> Shared Folders, check the box next to the `Container` shared folder and click "Remove"  ([IMAGE](https://i.imgur.com/s1jXNNs.png))
      - In the pop-up box, check "Also delete the data" and click "Yes" ([IMAGE](https://i.imgur.com/WXML3fl.png))

4. Reboot NAS ([IMAGE](https://i.imgur.com/voFkAt9.png))

5. Install Container Station, then launch once installed. 
  - Accept and create the `/Container` folder suggested when CS is launched for the first time.

6. Create a new user called _dockeruser_ 

7. Create the following folder shares *using the QTS web-GUI* at `ControlPanel >> Privilege >> Shared Folders` and give _dockeruser_ Read/Write permissions:
  - `/share/swarm/appdata`
    - Here we will add folders named `< stack name >`. This is where your application files live... libraries, artifacts, internal application configuration, etc. Think of this directory much like a combination of `C:\Windows\Program Files` and `C:\Users\<UserName>\AppData` in Windows.
  - `/share/swarm/configs`
    - Here we will also add folders named `< stack name >`. Inside this structure, we will keep our actual _stack_name.yml_ files and any other necessary config files used to configure the docker stacks and images we want to run. This folder makes an excellent GitHub repository for this reason.
  - `/share/swarm/runtime`
    - This is a shared folder on a volume that does not get backed up. It is where living DB files and transcode files reside, so it would appreciate running on the fastest storage group you have or in cache mode or in Qtier (if you use it). Think of this like the `C:\Temp\` in Windows.
  - `/share/swarm/secrets`
    - This folder contains secret (sensitive) configuration data that should _NOT_ be shared publicly. This could be stored in a _PRIVATE_ Git repository, but should never be publicized or made available to anyone you don't implicitly trust with passwords, auth tokens, etc.

8. Install the `entware-std` package from the third-party QNAP Club repository. This is necessary in order to setup the shortcuts/aliases in Steps 18 & 19 by editing a permanent profile.
  - The preferred way to do this is to add the QNAP Club Repository to the App Center. Follow the [walkthrough instructions here](https://www.qnapclub.eu/en/howto/1). Note that I use the English translation of the QNAP Club website, but you may change languages (and urls) in the upper right language dropdown.
  - If you don't need the walkthrough, add the repository. (For English, go to App Center, Settings, App Repository, Add, `https://www.qnapclub.eu/en/repo.xml`).
  - If you have trouble locating the correct package below, the correct description begins `entware-3x and entware-ng merged to become entware.` The working link (as of publication) is here: https://www.qnapclub.eu/en/qpkg/556. 
    - If you **cannot** add the QNAP Club store to the App Center, you may manually download the qpkg file from that link and use it to manually install via the App Center, "Install Manually" button. This is **not preferred** as QNAP cannot check for and notify you of updates to the package.
  - Search for `entware-std` and install that package.

  - **Important:** *DO NOT* CHOOSE either the `entware-ng` or `entware-3x-std` packages. These have merged and been superceded by `entware-std`.

---------------------------------------

## 3. QNAP CLI Steps

1. Open/Connect an SSH Terminal session to your QNAP NAS. 
    * You can use [PuTTY](https://putty.org/) 
    * I prefer to use [BitVise](https://www.bitvise.com/ssh-client-download) because this also has an SFTP remove file browser interface.

2. Install nano or vi, whichever you are more comfortable with (only one needed)
    - **RUN:** `opkg install nano`
    - **RUN:** `opkg install vim`
    - ***NOTE:*** You must have installed the `entware-std` package as detailed above in Section-2 Step-8 to be able to use the "opkg" installer.

3. **TYPE:** `nano /opt/etc/profile` (or `vi /opt/etc/profile` if that is your thing)
    - ***NOTE:*** If you use a Windows client to save the profile (or the scripts below), they will be saved with CR LF and will error.
    - ***NOTE:*** **You MUST set the end of line format to UNIX (LF) in order for the profile and scripts to work correctly.**
  
  - Add the following lines to the end of the file and save.
    - ***NOTE:*** You will need to restart your ssh or cli session in order to make the profile changes effective.

```bash
# docker_commands_list -- lists the below custom docker commands
dlist(){
  bash /share/swarm/scripts/docker_commands_list.sh
}
# docker_compose_dn -- stops the entered container
dcd(){
  bash /share/swarm/scripts/docker_compose_dn.sh "$1" 
}
# docker_compose_up -- starts the entered container using preconfigured docker_compose files
dcu(){
  bash /share/swarm/scripts/docker_compose_up.sh "$1" 
}
# docker_compose_logs -- displays 50 log entries for the indicated docker-compose container
dcl(){
  bash /share/swarm/scripts/docker_compose_logs.sh "$1" 
}
# docker_stack_bounce -- removes then (re)deployes the listed stacks or '-all' stacks with config files in the folder structure
dsb(){
  bash /share/swarm/scripts/docker_stack_bounce.sh "$1" 
}
bounce(){
  bash /share/swarm/scripts/docker_stack_bounce.sh -all
}
# docker_stack_deploy -- deploys a single stack as defind in the configs folder structure
dsd(){
  bash /share/swarm/scripts/docker_stack_deploy.sh "$1" 
}
# docker_stack_up -- starts all containers in the stack (same as 'dsd -all')
dsu(){
  bash /share/swarm/scripts/docker_stack_deploy.sh -all
}
# docker_stack_folders -- creates the folder structure required for each listed stack name (up to 9 per command)
dsf(){
  bash /share/swarm/scripts/docker_stack_folders.sh "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" 
}
# docker_stack_remove -- removes a single stack
dsr(){
  bash /share/swarm/scripts/docker_stack_remove.sh "$1" 
}
# docker_stack_clear -- removes all containers in the stack (same as 'dsr -all')
dsc(){
  bash /share/swarm/scripts/docker_stack_remove.sh -all
}
# docker_system_prune -- prunes the docker system (removes unused images and containers)
dprn(){
  bash /share/swarm/scripts/docker_system_prune.sh 
}
# docker_swarm_setup -- creates a new swarm and overlay network, then starts all declared stacks if desired
dwup(){
  bash /share/swarm/scripts/docker_swarm_setup.sh "$1"
}
# docker_swarm_leave -- REMOVES all stack containers, REMOVES the overlay network, and LEAVES the docker swarm. USE WITH CAUTION!
dwlv(){
  bash /share/swarm/scripts/docker_swarm_leave.sh "$1"
}
# docker_swarm_remove -- REMOVES all stack containers, REMOVES the overlay network, and LEAVES the swarm. USE WITH CAUTION!
dwrm(){
  bash /share/swarm/scripts/docker_swarm_leave.sh -all
}
dwinit(){
  bash mkdir -pm 777 /share/swarm/{appdata,configs,runtime,scripts,secrets}
}
```

- Remember these shortcut names, (defined by the above shortcuts which point to required scripts, listed below):

  - In general, this is the scheme for how the shortcut acronyms are composed:
    - `dc...` refers to `Docker Compose` commands, for use outside of a swarm setup
    - `dl...` refers to `Docker List` commands (i.e. docker processes, docker networks, etc)
    - `ds...` refers to `Docker Stack` commands (groupls of containers in a swarm setup)
    - `dv...` refers to `Docker serVice` commands (mostly error and logs related)
    - `dw...` refers to `Docker sWarm` initialization/removal commands (the whole swarm)
  
  - `dlist` -- docker_commands_list - lists the custom Docker Swarm commands created for managing a QNAP Docker Swarm"

  - `dcd` -- docker_compose_dn - stops (brings 'down') a docker-compose container
      - **SYNTAX:** `dcd traefik`
  - `dcu` -- docker_compose_up - starts (brings 'up') a docker-compose container
      - **SYNTAX:** `dcu traefik`
  - `dcl` -- docker_compose_logs -- displays 50 log entries for the indicated docker-compose container
      - **SYNTAX:** `dcl traefik`

  - `dsb` -- docker_stack_bounce - removes a single stack then recreates it using $config_folder/stackname/stackname.yml
      - **SYNTAX:** `dsb privatebin`
      - **SYNTAX:** `dsb -all`
  - `bounce` -- docker_stack_bounce - removes then recreates all stacks using $config_folder/stackname/stackname.yml
      - **SYNTAX:** `bounce` (same as `dsb -all`)
  - `dsd` -- docker_stack_deploy - deployes a single stack, or a default list of stacks defined in the 'docker_stack_deploy.sh' script
      - **SYNTAX:** `dsd traefik`
      - **SYNTAX:** `dsd -default`
      - **SYNTAX:** `dsd -all`
  - `dsu` -- docker_stack_up - deploys all stacks defined in `/share/swarm/configs/swarm_stacks.conf`
      - **SYNTAX:** `dsu` (same as `dsd -all`)
  - `dsf` -- docker_stack_folders - creates the folder structure for (1 - 9 listed) stacks
    - **SYNTAX:** `dsf plex sonarr radarr lidarr bazarr ombi`
      - creates the below three folders for each listed stack:
        - `/share/swarm/appdata/appname`
        - `/share/swarm/configs/appname`
        - `/share/swarm/runtime/appname`
  - `dsr` -- docker_stack_remove - removes a single stack, or all stacks listed via `docker stack ls`
    - **SYNTAX:** `dsr openvpn`
    - **SYNTAX:** `dsr -all`
  - `dsc` -- docker_stack_clear - removes all stacks
    - **SYNTAX:** `dsc` (same as `dsr -all`)

  - `dwup` -- docker_swarm_setup - creates a new swarm, and overlay network, then starts all stacks declared in $configs_folder
      - **SYNTAX:** `dwup`
  - `dwlv` -- docker_swarm_leave - prunes docker system, leaves swarm - USE WITH CAUTION!
      - **SYNTAX:** `dwlv`
  - `dwrm` -- docker_swarm_remove - removes all stacks, prunes docker system, leaves swarm - USE WITH CAUTION!
      - **SYNTAX:** `dwrm` (same as `dwlv -all`)

  - `dprn` -- docker_system_prune - prunes the Docker system of unused images, networks, and containers
      - **SYNTAX:** `dprn`

  **See below** in Section-6 and Section-7 for script files that need to be created and added to `/share/swarm/scripts` folder.
      * These script files are required in order to utilize the above shortcut commands.

4. **TYPE:** `id dockeruser` in terminal and note the 'uid' and 'gid'
    - Enter the discovered userid and groupid into the variables file from Section-6 below.

5. **TYPE:** `docker network ls` The networks shown should match the following (except the generated NETWORK ID):

```
[~] # docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
XXXXXXXXXXXX        bridge              bridge              local
XXXXXXXXXXXX        host                host                local
XXXXXXXXXXXX        none                null                local
```

6. If you successfully edited the bash `profile` above, _AND_ saved the scripts from Section-7 below, you can use the shortcut command `dwup` instead of manually performing steps 7 - 9 just below.
    - **TYPE:** `dwup`
    - **NOTE:** It is very important to read steps 7 - 9, and make sure the proper networks _were_ created.

7. Run: `docker swarm init --advertise-addr <YOUR NAS IP HERE>` - Use ***YOUR*** nas internal LAN IP address

8. **CHECKPOINT:** Run `docker network ls`. Does the list of networks contain one named `docker_gwbridge`?
    * The networks should match the following (except the generated NETWORK ID):

```
[~] # docker network ls
NETWORK ID          NAME                   DRIVER              SCOPE
XXXXXXXXXXXX        bridge                 bridge              local
XXXXXXXXXXXX        docker_gwbridge        bridge              local
XXXXXXXXXXXX        host                   host                local
XXXXXXXXXXXX        ingress                overlay             swarm
XXXXXXXXXXXX        none                   null                local
```

- **IMPORTANT: If your configuration is lacking the `docker_gwbridge` network, or differs from this list**, please contact someone on the [QNAP Unofficial Discord](https://discord.gg/rnxUPMd) (ideally in the [#docker-stack channel](https://discord.gg/MzTNQkV)). Do not proceed beyond this point unless your configuration matches the one above, unless you embrace pain and failure and love very complicated problems that could be QNAP's fault.

9. Create the docker network overlay:
    - **TYPE:** `docker network create --driver=overlay --subnet=172.1.1.0/22 --attachable traefik_public`

---------------------------------------

## 4. Traefik Setup Steps

1. Create the Traefik specific folders (listed below) by typing `dsf traefik`
    - Alternatively, you can manually type these commands into a terminal:
        - **TYPE:** `mkdir -p /share/swarm/appdata/traefik`
        - **TYPE:** `mkdir -p /share/swarm/configs/traefik`
        - **TYPE:** `mkdir -p /share/swarm/runtime/traefik`

2. Add the three provided traefik files from the git repository folder "/config/traefik/" to `/share/swarm/configs/traefik` 
    - `application.yaml`, `traefik-static.yaml`, `traefik.yml`

3. **EDIT:** _traefik.yml_ and put your cloudflare email and GLOBAL API KEY in lines 7 & 8 
    **NOTE:** If you are not using cloudflare you will need to check with the Traefik documentation to add the correct environment settings to your _traefik.yml_ file.

4. **EDIT:** _application.yaml_ and _traefik.yml_ to include your domain name.

5. In an SSH Terminal with your QNAP, run the below commands to set traefik folder/file permissions:
    - **TYPE:** `rm /share/swarm/configs/traefik/acme.json`
    - **TYPE:** `touch /share/swarm/configs/traefik/acme.json`
    - **TYPE:** `chmod 600 /share/swarm/configs/traefik/acme.json`

6. Check that `traefik.<yourdomain.com>` resolves to your WAN IP:
    - **TYPE:** `ping traefik.<yourdomain.com>` 
    - **Press:** `ctrl+c` to stop the ping
    **NOTE:** If you don't get the proper IP during this ping operation, update your DNS settings with your domain provider.

7. **TYPE:** `dsd traefik` to start the traefik container

* Enjoy Traefik and add more containers.

---------------------------------------

## 5. ForwardAuth Setup Steps

1. Navigate to https://auth0.com 
    - Sign in or register for an account
    - Note the Tenant Domain provided by Auth0

2. Navigate to https://github.com 
    - Sign in or register an account using OAuth

    - Go to _Settings -> Developer Settings - OAuth Apps_
        - Create a new app (call it something to recognize it is linked to Auth0)
        - Add homepage URL as `https://<yourauth0accounthere>.auth0.com/`
        - Add authorization callback URL as `https://<yourauth0accounthere>.auth0.com/login/callback`
        - Click "Register appliction" button
        - Note the "Client ID" and "Client Secret"

3. Navigate back to Auth0
    - Go to _Connections -> Social_
        - CLICK the _Github_ slider
            - Enter your GitHub app "ClientID" and "Client Secret" from the previous step
        **NOTE:** Ensure the Attribute _"Email Address"_ is ticked
        - Click the "Save" button
        **NOTE:** Make sure the gray/green slider for _GitHub_ is "green"

    - Go to _Applications_
        - Click on the "Create Application" button
        - Name the new app something recognizable
        - Select the "Regular Web Applications" box
        - Click the "Create" button
        - Once the app is created, click on the "Settings" tab
            - Use the Auth0 "Client ID" and "Client Secret" in your _application.yaml_ file
            **NOTE:** Enter these in Lines 22 & 23, replacing the < redacted > tag
            - Ensure "Token Endpoint Authentication Method" drop down box shows as "Post"
            - Enter in your Callback URL(s), for example:
            ```
            https://<service>.<domain>/signin,
            https://<service>.<domain>/oauth/signin
            ```
        - In the "Allowed Web Origins" field, enter your origin URL:
            `https://<your URL here>`
        - Click the "Save changes" button

    - Go to _Users & Roles -> Users_
        - Create a user with a real email address and password
        **NOTE:** _You will use this later so remember it!_

    - Go to _Rules_
        - Click the _Create Rule_ button (top right)
        - Under the _Access Control_ section, select the _Whitelist_ type 
        - Enter in your email address into the whitelist field on Line 8:
        `const whitelist = [ 'your email here', '2nd email here' ]; //authorized users`

4. Open an SSH Terminal to your QNAP
    - **TYPE:** `dsr traefik` to remove the Traefik stack
        - Wait 10 seconds
    - **TYPE:** `dsd traefik` to deploy the Traefik stack
        - Wait 30 seconds
    - Launch `https://traefik.<yourdomainhere>`
    - Enter Auth0 authentication login to reach traefik dashboard

---------------------------------------

## 6. Docker Script Variables Setup
These variable/config files need to be filled in with your information in order to allow the below scripts to properly function.

  * **NOTE:** `docker_swarm_setup.sh` requires your NAS IP to function, which is entered in the `/share/swarm/conrfigs/swarm_vars.conf` file.
  * **NOTE:** `docker_stack_deploy.sh` uses the pre-defined stack lists in the `/share/swarm/configs/swarm_stacks.conf` file.
      * If you do not edit these stack lists, nothing blows up, no bunnies die, just a big pile of nothingness in your swarm.
  
  * **IMPORTANT!!** Please ensure you save these files in UNIX (LF) format.  Windows (CR LF) format _will_ break these scripts.
      * If you are a Windows user, please download the files from the scripts folder above, or be certain your text editor can properly save UNIX (LF) formatted text files.

##### swarm_stacks.conf
  * This is the list of _all_ stacks you might deploy in your swarm
      * Add a stack name here each time you add a new stack 
      * the `stacks_default` array only lists your 'core' stacks, do not include all stack names
```
# List desired services inside the 'stacks' array parentheses (each service name separated by at least a space)
## Each listed stack will require a corresponding '/stackname/stackname.yml' folder/file in the 'configs' folder defined below
## NOTE: Leave Traefik off the list as it will be started seperately
stacks_default=(
  bitwarden
  ddclient
  docker-cleanup
  graylog
  nextcloud
  portainer
  shepherd
  )
stacks_listed=(
  bookstack
  calibre
  calibre-web
  deluge
  discourse
  filebot
  ghost
  nextcloud
  openvpn
  plex
  privatebin
  syncthing
  )
stacks_all=(
  autopirate
  bitwarden
  bookstack
  calibre
  ddclient
  diskover
  docker-cleanup
  dozzle
  filebrowser
  ghost
  gollum
  graylog
  nextcloud
  ouroboros
  plex
  portainer
  privatebin
  syncthing
  wetty
  )

```

##### swarm_vars.conf
  * These variables are used in the scripts found in `/share/swarm/scripts/` and `/share/swarm/configs/`

```
# Variables list for Drauku's QNAP Docker Swarm stack scripts.
# These variables must be filled in with your network, architecture, etc, information.

# Ensure this file name variable exactly references THIS file
  variables_file=swarm_vars.env

# Folder paths for Drauku's folder structure, modified from gkoerk's famously awesome folder structure for stacks
  swarm_folder=/share/swarm
  appdata_folder=${swarm_folder}/appdata
  configs_folder=${swarm_folder}/configs
  runtime_folder=${swarm_folder}/runtime
  secrets_folder=${swarm_folder}/secrets
  scripts_folder=${swarm_folder}/scripts
  stacks_folder=${swarm_folder}/stacks

# Internal network and docker system variables
  var_nas_ip=NASLANIP
  var_usr=1000
  var_grp=100
  var_tz_region=America
  var_tz_city=Chicago

# Domain and user information variables
  var_nas_name=NASNAME #THIS MIGHT NOT WORK FOR CREATING A 'SERVICE' NAME USING Traefik
  var_domain=PERSONALDOMAIN.TLD
  var_email=PERSONAL@EMAIL.ADDRESS
  var_target_email=EMAIL.ADDRESS@FOR.LOGS

# External network resolution and access variables
  var_certresolver=cloudflare
  # If your 'certresolver' and 'dns' services are through cloudflare, fill in the below variables:
  var_cf_user=CLOUDFLAREUSERNAME
  #var_cf_api=<secret>
  # If your 'certresolver' and 'dns' services are through namecheap, fill in the below variables:
  var_namecheap_email=NAMECHEAP@EMAIL.ADDRESS

# Database names, usernames, etc
  var_mongo_db_usr=dockmongo
  #var_mongo_db_pwd=<secret>
  var_mysql_db_usr=dockmysql
  #var_mysql_db_pwd=<secret>

# The below variables are service specific, and can be modified directly in the 'service.yaml' config files.
# I find it easier to maintain them in one location.

# SERVICENAME specific config variables

```
---------------------------------------

## 7. Scripts Setup
Please create these scripts and save them to `/share/swarm/scripts` if you want to use the cli shortcuts we created in earlier steps.


All the stack scripts (`xxx_stack.sh`) require you to edit the stacks list to match your setup.  If you do not edit them they will fail to deploy the stacks you did not list... 

**NOTE:** 

##### docker_compose_dn (dcd)
  * stops the entered container
```

#!/bin/bash
# This script STOPS (bring 'down') a single Docker container using a pre-written compose file.

# Load config variables from file
  source /share/swarm/configs/swarm_vars.conf

# Perform scripted action(s)
docker-compose -f ${configs_folder}/"$1"/"$1".yml down
```

##### docker_compose_up (dcu)
  * starts the entered container using preconfigured docker_compose files
```
#!/bin/bash
# This script STARTS (bring 'up') a single Docker container using a pre-written compose file.
=======
dsd(){
  if [[ $1 = "-default" ]]; then
      list=( traefik portainer docker-cleanup ouroboros nextcloud privatebin ); 
    else
      list="$@"
  fi
  for i in "${list[@]}"; do
    docker stack deploy "$i" -c /share/appdata/config/"$i"/"$i".yml
  done
  unset list IFS
}
dsr(){
  if [[ $1 = "-all" ]]; then
      IFS=$'\n'; 
      list=( $(docker stack ls --format {{.Name}}) ); 
    else
      list="$@"
  fi
  for i in "${list[@]}"; do
    docker stack rm "$i"
  done
  unset list IFS
}
bounce(){
  if [[ $1 = "-all" ]]; then
      IFS=$'\n'; 
      list=( $(docker stack ls --format {{.Name}}) ); 
    else
      list="$@"
  fi
  for i in "${list[@]}"; do
    docker stack rm "$i"
  done
  for i in "${list[@]}"; do
    while [ "$(docker service ls --filter label=com.docker.stack.namespace=$i -q)" ] || [ "$(docker network ls --filter label=com.docker.stack.namespace=$i -q)" ]; do sleep 1; done
  done
  for i in "${list[@]}"; do
    docker stack deploy "$i" -c /share/appdata/config/"$i"/"$i".yml
  done
  unset list IFS
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
23. Create and correctly set permissions on the acme.json file:
 - `rm /share/appdata/config/traefik/acme.json`
 - `touch /share/appdata/config/traefik/acme.json`
 - `chmod 600 /share/appdata/config/traefik/acme.json`
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
 - For an entire domain, the values should look like this example:
 
17. Enter your origin URL (`https://<your URL here>`) and save changes
18. Go to Users & Roles and Create a user with a real email address.  You will use this later so remember it
19. Click on _Rules -> Whitelist_
20. Enter in your email address into the whitelist field (e.g. `Line 8 "const whitelist = [ '<your email here>']; //authorized users"`)
21. Open ssh and `dsr traefik`, wait 10 seconds and `dsd traefik`
22. Wait 30 seconds and then launch `https://traefik.<yourdomainhere>`
23. Enter Auth0 authentication login to reach traefik dashboard
---

# Load config variables from file
source /share/swarm/scripts/swarm_vars.conf

# Perform scripted action(s)
docker-compose -f ${configs_folder}/"$1"/"$1".yml up -d
```

##### docker_stack_bounce (dsb)
  * removes then (re)deployes the listed stacks or '-all' stacks with config files in the folder structure
```
#!/bin/bash

# Help message for script
helpFunction(){
  echo 
  echo "This script bounces (removes then re-deploys) a single or pre-defined list of Docker Swarm stack"
  echo
  echo "SYNTAX: # dsb stack_name"
  echo "SYNTAX: # dsb -option"
  echo "  VALID OPTIONS:"
  echo "        -all          Re-deploys all stacks with a corresponding folder inside the '../configs/' path."
  echo "        -listed       Re-deploys stacks listed in the '../configs/swarm_stacks.conf' config file 'stacks_listed' array."
  echo "        -default      Re-deploys a default list of stacks defined in the '../configs/swarm_vars.conf' variable file."
  echo "        -h || -help   Displays this help message."
  echo
  exit 1 # Exit script after printing help
  }

# Load config variables from file
  source /share/swarm/configs/swarm_stacks.conf
  source /share/swarm/configs/swarm_vars.conf
  bounce_list=""

  if [[ $1 = "-all" ]]; then
    IFS=$'\n' bounce_list=( $(docker stack ls --format {{.Name}}) ); 
  elif [[ $1 = "-listed" ]]; then
    IFS=$'\n' bounce_list=( "${stacks_listed[@]}" );
  elif [[ $1 = "-default" ]]; then
    IFS=$'\n' bounce_list=( "${stacks_default[@]}" );
  elif [[ $1 = "" ]] || [[ $1 = "-h" ]] || [[ $1 = "-help" ]] ; then
    helpFunction
  else
    bounce_list=("$@")
  fi

# Remove all stacks in list defined above
  . ${scripts_folder}/docker_stack_remove.sh "${bounce_list[@]}"

# Deploy all stacks in list defined above
  . ${scripts_folder}/docker_stack_deploy.sh "${bounce_list[@]}"

# Clear the 'bounce_list' array now that we are done with it
  unset bounce_list IFS

  echo "****** BOUNCE (REMOVE & REDEPLOY) STACK SCRIPT COMPLETE ******"
  echo
```

##### docker_stack_deploy (dsd)
  * deploys a single stack as defind in the configs folder structure
```
#!/bin/bash

# Help message for script
helpFunction(){
  echo 
  echo "This script deploys a single or pre-defined list of Docker Swarm stack"
  echo
  echo "SYNTAX: # dsd stack_name"
  echo "SYNTAX: # dsd -option"
  echo "  VALID OPTIONS:"
  echo "        -all          Deploys all stacks with a corresponding folder inside the '../configs/' path."
  echo "        -listed       Deploys stacks listed in the '../configs/swarm_stacks.conf' config file 'stacks_listed' array."
  echo "        -default      Deploys the 'default' list of stacks defined in the '../configs/swarm_vars.conf' variable file"
  echo "        -h || -help   Displays this help message."
  echo
  exit 1 # Exit script after printing help
  }

# Load config variables from file
  source /share/swarm/configs/swarm_stacks.conf
  source /share/swarm/configs/swarm_vars.conf
  source /share/swarm/scripts/docker_stack_bounce.sh
  deploy_list=""

# Define which stack(s) to load using command options
  if [[ $1 = "-all" ]]; then
    if [[ "${bounce_list[@]}" = "" ]]; then
      IFS=$'\n' deploy_list=( "${stacks_all[@]}" );
    else
      IFS=$'\n' deploy_list=( "${bounce_list[@]}" );
    fi
  elif [[ $1 = "-listed" ]]; then
    IFS=$'\n' deploy_list=( "${stacks_listed[@]}" );
  elif [[ $1 = "-default" ]]; then
    IFS=$'\n' deploy_list=( "${stacks_default[@]}" );
  elif [[ $1 = "" ]] || [[ $1 = "-h" ]] || [[ $1 = "-help" ]] ; then
    # Print helpFunction in case parameters are empty
    helpFunction
  else
    deploy_list=("$@")
  fi

# Display list of stacks to be deployed
  echo "*** DEPLOYING LISTED STACK(S) ***"
  # Remove duplicate entries in deploy_list
    deploy_list=(`for stack in "${deploy_list[@]}" ; do echo "$stack" ; done | sort -u`)
  # Remove 'traefik' from the deploy_list array
    for i in "${!deploy_list[@]}"; do
      if [[ "${deploy_list[i]}" = [tT][rR][aA][eE][fF][iI][kK] ]]; then
        unset 'deploy_list[i]'
      fi
    done
  # Add 'traefik' stack as first item in deploy_list array
    if [ "$(docker service ls --filter name=traefik -q)" = "" ]; then
      deploy_list=( "traefik" "${deploy_list[@]}" )
      echo " -> ${deploy_list[@]}"
      echo
      echo "*** TRAEFIK MUST BE THE FIRST DEPLOYED SWARM STACK ***"
      echo
    else
      echo " -> ${deploy_list[@]}"
      echo
    fi
  # Create the 'traefik_public' overlay network if it does not already exist
    if [ "$(docker network ls --filter name=traefik -q)" = "" ]; then
      echo "*** CREATING OVERLAY NETWORK ***"
      docker network create --driver=overlay --subnet=172.1.1.0/22 --attachable traefik_public
      echo "***** OVERLAY NETWORK CREATED, WAITING 15 SECONDS *****"
      sleep 15
      echo
    fi

# Deploy indicated stack(s)
  for stack in "${deploy_list[@]}"; do
    echo "*** DEPLOYING '$stack' ***"
    docker stack deploy $stack -c ${configs_folder}/${stack}/${stack}.yml
    echo "**** '$stack' DEPLOYED, WAITING 10 SECONDS ****"
    sleep 10
  done

# Clear the 'deploy_list' array now that we are done with it
  unset deploy_list IFS

# Print script complete message
  echo
  echo "****** STACK DEPLOY SCRIPT COMPLETE ******"
  echo
```

##### docker_stack_folders (dsf)
  * creates the folder structure required for each listed stack name (up to 9 per command)
```
#!/bin/bash

# Help message for script
helpFunction(){
  echo
  echo "Script to create Drauku's folder structure, modified from gkoerk's famously awesome folder structure for stacks."
  echo
  echo "SYNTAX: dsf <folder-name1> <folder-name2> ... <folder-name9>"
  echo "  Enter up to nine(9) folder names in a single command, separated by a 'space' character: "
  echo "SYNTAX: dsf -option"
  echo "  VALID OPTIONS:"
  echo "        -h || -help   Displays this help message."
  echo
  echo "The below folder structure is created for each 'folder-name' entered in this command:"
  echo "    /share/swarm/appdate/<folder-name>"
  echo "    /share/swarm/configs/<folder-name>"
  echo "    /share/swarm/runtime/<folder-name>"
  echo "    /share/swarm/secrets/<folder-name>"
  echo
  exit 1 # Exit script after printing help
}

# Load config variables from file
  source /share/swarm/configs/swarm_stacks.conf
  source /share/swarm/configs/swarm_vars.conf

# Print helpFunction in case parameters are empty, or -h option entered
  if [[ -z "$1" ]] || [[ $1 = "" ]] || [[ $1 = "-h" ]] || [[ $1 = "-help" ]] ; then
    helpFunction
  fi

# Create folder structure
  mkdir -p $appdata_folder/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
  mkdir -p $configs_folder/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
  mkdir -p $runtime_folder/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
  mkdir -p $secrets_folder/{$1,$2,$3,$4,$5,$6,$7,$8,$9}
  echo "DOCKER SWARM FOLDER STRUCTURE CREATED FOR LISTED STACKS"
  echo " - $@"
  echo

# Change all swarm folders to the 'user:group' to the 'dockuser' and appropriate group number
  chown -R $var_user:$var_group $swarm_folder
  echo "FOLDER OWNERSHIP UPDATED"
  echo 

# Print script complete message
  echo "DOCKER SWARM STACKS FOLDER STRUCTURE CREATION SCRIPT COMPLETE"
  echo
```

##### docker_stack_list (dsl)
  * lists all current swarm stacks and the number of services in each stack
```
#!/bin/bash

# Listing the currently active docker stacks and number of services per stack
  echo "*** LISTING CURRENT DOCKER SWARM STACKS AND SERVICES ***"
  docker stack ls
  echo
```

##### docker_stack_remove (dsr)
  * removes a single stack
```
#!/bin/bash

# Help message for script
helpFunction(){
  echo 
  echo "This script removes a single or pre-defined list of Docker Swarm stack"
  echo
  echo "SYNTAX: # dsr stack_name"
  echo "SYNTAX: # dsr -option"
  echo "  VALID OPTIONS:"
  echo "        -all          Removes all stacks with a corresponding folder inside the '../configs/' path."
  echo "        -listed       Removes stacks listed in the '../configs/swarm_stacks.conf' config file 'stacks_listed' array."
  echo "        -default      Removes a default list of stacks defined in the '../configs/swarm_vars.conf' variable file."
  echo "        -h || -help   Displays this help message."
  echo
  exit 1 # Exit script after printing help
  }

# Load config variables from file
  source /share/swarm/configs/swarm_stacks.conf
  source /share/swarm/configs/swarm_vars.conf
  source /share/swarm/scripts/docker_stack_bounce.sh
  remove_list=""

# Define which stack to remove using command options
  if [[ $1 = "-all" ]]; then
    IFS=$'\n' remove_list=( $(docker stack ls --format {{.Name}}) ); 
  elif [[ $1 = "-listed" ]]; then
    IFS=$'\n' remove_list=( "${stacks_listed[@]}" );
  elif [[ $1 = "-default" ]]; then
    IFS=$'\n' remove_list=( "${stacks_default[@]}" );
  elif [[ $1 = "" ]] || [[ $1 = "-h" ]] || [[ $1 = "-help" ]] ; then
    helpFunction
  else
      remove_list=("$@")
  fi

# Display list of stacks to be removed
  echo "****** REMOVING LISTED STACK(S) ******"
  # Remove duplicate entries in remove_list
    remove_list=(`for stack in "${remove_list[@]}" ; do echo "$stack" ; done | sort -u`)
  # Remove 'traefik' from the remove_list array
    for i in "${!remove_list[@]}"; do
      if [[ "${remove_list[i]}" = [tT][rR][aA][eE][fF][iI][kK] ]]; then
        unset 'remove_list[i]'
      fi
    done
  # If removing '-all' stacks, add 'traefik' back in as last stack in remove_list
    if [[ $1 = "-all" ]]; then
      if [ "$(docker service ls --filter name=traefik -q)" != "" ]; then
        remove_list=( "${remove_list[@]}" "traefik" )
        echo " -> ${remove_list[@]}"
        echo
        echo "*** 'Traefik' MUST BE THE LAST REMOVED SWARM STACK ***"
        echo
      fi
    elif [[ $1 = "traefik" ]]; then
      read -r -p "Are you sure you want to remove the 'Traefik' stack? This could cause apps to be inaccessible. [Y/n] " input
      case $input in
        [yY][eE][sS]|[yY])
          remove_list=( "${remove_list[@]}" "traefik" )
          echo " -> ${remove_list[@]}"
          echo
          ;;
        [nN][oO]|[nN])
          echo "** 'Traefik' STACK WILL NOT BE REMOVED **";
          ;;
        *)
          echo "INVALID INPUT: Must be any case-insensitive variation of '(y)es' or '(n)o'."
          exit 1
          ;;
      esac
    else
      echo " -> ${remove_list[@]}"
      echo
    fi

# Remove indicated stack(s)
  for stack in "${remove_list[@]}"; do
    echo "**** REMOVING '$stack' ****"
    docker stack rm "$stack"
    echo "*** '$stack' REMOVED, WAITING 10 SECONDS ***"
    sleep 10
  done

# Clear the 'remove_list' array now that we are done with it
  unset remove_list IFS
  echo

# Pruning the system is optional but recommended
  . ${scripts_folder}/docker_system_prune.sh -f

# Print script complete message
  echo "****** STACK REMOVE SCRIPT COMPLETE ******"
  echo
```

##### docker_swarm_leave (dwlv)
  * LEAVES the docker swarm. USE WITH CAUTION!
      * Will also remove all stacks unless you specify the '-noremove' command option
```
#!/bin/bash

# Help message for script
helpFunction(){
  echo 
  echo "This script leaves a Docker Swarm environment and removes a list of stacks on QNAP Container Station architecture."
  echo
  echo "SYNTAX: # dwlv"
  echo "SYNTAX: # dwlv -option"
  echo "  VALID OPTIONS:"
  echo "        -all          Removes all stacks with a corresponding folder inside the '../configs/' path, then laves the Docker Swarm."
  echo "        -h || -help   Displays this help message."
  echo
  exit 1 # Exit script after printing help
  }

# Load config variables from file
  source /share/swarm/configs/swarm_vars.conf

# Check for '-noremove' command options
  if [[ "$1" = "-noremove" ]] ; then
    input=no;
  elif [[ $1 = "" ]] || [[ $1 = "-h" ]] || [[ $1 = "-help" ]] ; then
    helpFunction
  else
    # Query if all stacks should be removed before leaving swarm
    read -r -p "Do you want to remove all Docker Swarm stacks (it is highly recommended)? [Yes/No] " input
    echo
  fi

# Remove stacks if input is Yes
  case $input in
    [yY][eE][sS]|[yY])
      # remove all services in docker swarm
      . ${scripts_folder}/docker_stack_remove.sh -all
      ;;
    [nN][oO]|[nN])
      echo "** DOCKER SWARM STACKS WILL NOT BE REMOVED **";
      # Pruning the system is optional but recommended
        . ${scripts_folder}/docker_system_prune.sh -f
      ;;
    *)
      echo "** INVALID INPUT: Must be any case-insensitive variation of 'yes' or 'no'.";
      exit 1
      ;;
  esac

# Leave the swarm
  docker swarm leave -f

  echo
  echo "******* DOCKER SWARM LEAVE SCRIPT COMPLETE *******"
  echo
```

##### docker_swarm_setup (dwup)
  * creates a new swarm and overlay network, then starts all declared stacks if desired
```
#!/bin/bash

# Help message for script
helpFunction(){
  echo 
  echo "This script creates a Docker Swarm environment and deploys a list of stacks on QNAP Container Station architecture."
  echo
  echo "SYNTAX: # dwup"
  echo "SYNTAX: # dwup -option"
  echo "  VALID OPTIONS:"
  echo "        -all          Creates the Docker Swarm, then deploys all stacks with a corresponding folder inside the '../configs/' path."
  echo "        -listed       Creates the Docker Swarm, then deploys stacks listed in the '../configs/swarm_stacks.conf' config file 'stacks_listed' array."
  echo "        -default      Creates the Docker Swarm, then deploys a default list of stacks defined in the '../configs/swarm_vars.conf' variable file."
  echo "        -h || -help   Displays this help message."
  echo
  exit 1 # Exit script after printing help
  }

# Load config variables from file
  source /share/swarm/configs/swarm_vars.conf

# Query which list of stacks the user wants to load.
  if [[ "$1" = "" ]]; then
    read -r -p "Do you want to deploy the '-default' list of Docker Swarm stacks? [Y/n] " input
    echo
  fi

# Swarm initialization
  echo "*** INITIALIZING SWARM ***"
  docker swarm init --advertise-addr $var_nas_ip
  echo "***** SWARM INITIALIZED, WAITING 10 SECONDS *****"
  sleep 10
  echo

# Overlay network creation
  echo "*** CREATING OVERLAY NETWORK ***"
  docker network create --driver=overlay --subnet=172.1.1.0/22 --attachable traefik_public
  echo "***** OVERLAY NETWORK CREATED, WAITING 15 SECONDS *****"
  sleep 15
  echo

# Deploy the list of pre-defined stacks
  if [[ "$1" = "" ]]; then
    case $input in
      [yY][eE][sS]|[yY])
        . ${scripts_folder}/docker_stack_deploy.sh -default
        ;;
      [nN][oO]|[nN])
        echo "** DOCKER SWARM STACKS WILL NOT BE DEPLOYED **";
        ;;
      *)
        echo "INVALID INPUT: Must be any case-insensitive variation of 'yes' or 'no'."
        exit 1
        ;;
    esac
  elif [[ $1 = "" ]] || [[ $1 = "-h" ]] || [[ $1 = "-help" ]] ; then
    helpFunction
  else
    . ${scripts_folder}/docker_stack_deploy.sh "$1"
  fi

# List out current docker networks to ensure required networks were created
  if [ "$(docker network ls --filter name=traefik -q)" = "" ] || [ "$(docker network ls --filter name=gwbridge -q)" = "" ]; then
    docker network ls
    echo
    echo "*** THE ABOVE LIST MUST HAVE 'docker_gwbridge' AND 'traefik_public' LISTED ***"
    echo "*** IF EITHER OF THOSE NETWORKS ARE NOT LISTED, YOU MUST RE-INITIALIZE THE SWARM ***"
    echo "*** IF YOU HAVE ALREADY ATTEMPTED TO RE-INITIALIZE, ASK FOR HELP HERE: https://discord.gg/KekSYUE ***"
  fi

  echo
  echo "******* DOCKER SWARM SETUP SCRIPT COMPLETE *******"
  echo
```

##### docker_system_prune (dprn)
  * prunes the docker system (removes unused images and containers)
```
#!/bin/bash

# Perform prune operation with/without '-f' option
  echo "*** PRUNING THE DOCKER SYSTEM ***"
  if [[ $1 = "-f" ]]; then
    docker system prune -f
  elif [[ $1 = "" ]]; then
    docker system prune
  fi
  echo "***** DOCKER SYSTEM PRUNE COMPLETE *****"
  echo
```
