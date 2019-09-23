#!/bin/bash

echo "***** Setting up Swarm *****"
# setup Swarm
docker swarm init --advertise-addr 10.0.0.24

echo "***** Sleeping for a bit*****"
sleep 10

echo "***** Setting up overlay network *****"
# setup the overlay network
docker network create --driver=overlay --subnet=172.1.1.0/22 --attachable traefik_public


# define services - Add stacks to this list between the brackets
# Leave Traefik out of the list as it will be started seperately
stacks=( portainer docker-cleanup
        shepherd nextcloud graylog wetty
        plex privatebin autopirate cloudflare
        syncthing
        )
# define config folder
config_folder=/share/appdata/config

echo "**** Starting Traefik ****"
# Traefik needs to be the first stack deployed
docker stack deploy traefik -c ${config_folder}/traefik/traefik.yml

echo "**** Starting Other Stacks ****"
# restart all services in docker swarm

# loop through stacks defined above
for stack in "${stacks[@]}" ; do
  echo "**** Starting $stack ****"
  docker stack deploy $stack -c ${config_folder}/${stack}/${stack}.yml
  echo "***** Sleeping for a bit*****"
  sleep 10
  echo "**** $stack has been started ****"
done

echo "**** All Stacks have been started ****"
