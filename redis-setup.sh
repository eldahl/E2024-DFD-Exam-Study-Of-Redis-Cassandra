source "./assert.sh"

CLUSTER_NETWORK_NAME="redis-cluster-network"

# Check that docker is installed
if [ -x "$(command -v docker)" ]; then
  log_success "Docker is installed"
else
  log_failure "Docker is not installed"
  exit
fi

# Clear previous Redis docker containers that might be running
docker stop redis1
docker stop redis2
docker stop redis3

docker container rm -v redis1
docker container rm -v redis2
docker container rm -v redis3

docker network rm $CLUSTER_NETWORK_NAME

log_success "Cleared previous Redis cluster containers"

# Setup redis cluster
docker network create $CLUSTER_NETWORK_NAME

docker run -d --name redis1 --net $CLUSTER_NETWORK_NAME redis:latest redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000
docker run -d --name redis2 --net $CLUSTER_NETWORK_NAME redis:latest redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000
docker run -d --name redis3 --net $CLUSTER_NETWORK_NAME redis:latest redis-server --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000

log_success "Set up Redis cluster containers"

## Sleep 5 seconds
sleep 5

## Connect nodes to form a cluster
docker exec -it redis1 redis-cli --cluster-yes --cluster create \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis1):6379 \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis2):6379 \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis3):6379 \
--cluster-replicas 0

## Sleep for another 5 seconds for the cluster to form
sleep 5

## Get cluster info
redis_cluster_info="$(docker exec -it redis1 redis-cli cluster info)"
echo "${redis_cluster_info}"

if grep -Fq "cluster_known_nodes:6" <<< "${redis_cluser_info}"; then
  log_failure "Unable to set up Redis cluster"
else
  log_success "Successfully set up Redis cluster"
fi
