#!/bin/bash
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

# Pruning the stack is optional ... comment out if you dont want to do this step
echo "***** Pruning the stack *****"
docker system prune -f
echo "**** System pruned ****"

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
