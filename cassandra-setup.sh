source "./assert.sh"

CLUSTER_NETWORK_NAME="cassandra-cluster-network"

# Check that docker is installed
if [ -x "$(command -v docker)" ]; then
  log_success "Docker is installed"
else
  log_failure "Docker is not installed"
fi

# Clear previous Cassandra docker containers that might be running
docker stop cassandra1
docker stop cassandra2

docker remove cassandra1
docker remove cassandra2

docker network rm $CLUSTER_NETWORK_NAME

log_success "Cleared previous Cassandra cluster containers"

# Set up Cassandra containers
docker network create $CLUSTER_NETWORK_NAME
docker run -d --name cassandra1 --net $CLUSTER_NETWORK_NAME cassandra:latest
docker run -d --name cassandra2 --net $CLUSTER_NETWORK_NAME -e CASSANDRA_SEEDS=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' cassandra1) cassandra:latest
log_success "Set up Cassandra cluster containers."

## Sleep for 5 seconds
echo "Waiting for Cassandra instances to form the cluster"
sleep 120

## Get cluster info
cassandra_cluster_info="$(docker exec -it cassandra1 nodetool status)"
echo "${cassandra_cluster_info}"

if echo "${cassandra_cluster_info}" | grep -Fq "UN  "; then
  log_success "Successfully set up Cassandra cluster"
else
  log_failure "Unable to set up Cassandra cluster"
fi
