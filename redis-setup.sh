source "./assert.sh"

# Check that docker is installed
if [ -x "$(command -v docker)" ]; then
  log_success "Docker is installed"
else
  log_failure "Docker is not installed"
fi


# Clear previous Redis docker containers that might be running
docker stop redis1
docker stop redis2
docker stop redis3
docker stop redis4
docker stop redis5
docker stop redis6

docker remove redis1
docker remove redis2
docker remove redis3
docker remove redis4
docker remove redis5
docker remove redis6

docker network rm redis-cluster-network

log_success "Cleared previous Redis cluster containers..."

# Setup redis cluster
docker network create redis-cluster-network

docker run -d --name redis1 --net redis-cluster-network redis:latest redis-server --port 6379 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000
docker run -d --name redis2 --net redis-cluster-network redis:latest redis-server --port 6380 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000
docker run -d --name redis3 --net redis-cluster-network redis:latest redis-server --port 6381 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000
docker run -d --name redis4 --net redis-cluster-network redis:latest redis-server --port 6382 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000
docker run -d --name redis5 --net redis-cluster-network redis:latest redis-server --port 6383 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000
docker run -d --name redis6 --net redis-cluster-network redis:latest redis-server --port 6384 --cluster-enabled yes --cluster-config-file nodes.conf --cluster-node-timeout 5000

## Sleep 5 seconds
sleep 5

## Connect nodes to form a cluster
docker exec -it redis1 redis-cli --cluster create \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis1):6379 \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis2):6380 \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis3):6381 \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis4):6382 \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis5):6383 \
$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' redis6):6384 \
--cluster-replicas 1

## Sleep for another 5 seconds for the cluster to form
sleep 5

## Get cluster info
redis_cluster_info="$(docker exec -it redis1 redis-cli cluster info)"
echo "${redis_cluster_info}"

if grep -Fq "cluster_known_nodes:6" <<< "${redis_cluser_info}"; then
  log_failure "Unable to set up Redis cluster."
else
  log_success "Successfully set up Redis cluster."
fi
