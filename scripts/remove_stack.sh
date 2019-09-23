#!/bin/bash
# define services - Add stacks to this list between the brackets
stacks=( portainer docker-cleanup
        shepherd nextcloud graylog wetty
        plex privatebin autopirate cloudflare
        )
# define config folder
config_folder=/share/appdata/config



echo "**** Removing Stacks ****"
# remove all services in docker swarm

# loop through stacks defined above
for stack in "${stacks[@]}" ; do
  echo "**** Removing $stack ****"
  docker stack rm $stack
  echo "***** Sleeping for a bit*****"
  sleep 10
  echo "**** $stack has been removed ****"
done
echo "**** Removing Traefik ****"
# traefik needs to be last
docker stack rm traefik
echo "**** All Stacks have been removed ****"
echo "***** Sleeping for a bit *****"
sleep 10
echo "***** Pruning the stack *****"
docker system prune -f
echo "**** System pruned ****"
docker swarm leave -f
echo "***** Swarm Left *****"
