source "./assert.sh"

CLUSTER_NETWORK_NAME="cassandra-cluster-network"

# Check that docker is installed
if [ -x "$(command -v docker)" ]; then
  log_success "Docker is installed"
else
  log_failure "Docker is not installed"
  exit
fi

# Clear previous Cassandra docker containers that might be running
docker stop cassandra1
docker stop cassandra2
docker stop cassandra3

docker container rm -v cassandra1
docker container rm -v cassandra2
docker container rm -v cassandra3

docker network rm $CLUSTER_NETWORK_NAME

log_success "Cleared previous Cassandra cluster containers"

# Set up Cassandra containers
docker network create $CLUSTER_NETWORK_NAME

docker run -d --name cassandra1 --net $CLUSTER_NETWORK_NAME -e CASSANDRA_SEEDS=cassandra1,cassandra2,cassandra3 -e CASSANDRA_INITIAL_TOKEN=-9223372036854775808 cassandra:latest
docker run -d --name cassandra2 --net $CLUSTER_NETWORK_NAME -e CASSANDRA_SEEDS=cassandra1,cassandra2,cassandra3 -e CASSANDRA_INITIAL_TOKEN=-3074457345618258602 cassandra:latest
docker run -d --name cassandra3 --net $CLUSTER_NETWORK_NAME -e CASSANDRA_SEEDS=cassandra1,cassandra2,cassandra3 -e CASSANDRA_INITIAL_TOKEN=3074457345618258602 cassandra:latest

# Disable hinted-handoff in cassandra1
docker exec cassandra1 bash -c "sed -i '/^hinted_handoff_enabled:/c\hinted_handoff_enabled: false' /etc/cassandra/cassandra.yaml"
docker exec cassandra2 bash -c "sed -i '/^hinted_handoff_enabled:/c\hinted_handoff_enabled: false' /etc/cassandra/cassandra.yaml"
docker exec cassandra3 bash -c "sed -i '/^hinted_handoff_enabled:/c\hinted_handoff_enabled: false' /etc/cassandra/cassandra.yaml"

docker restart cassandra1
docker restart cassandra2
docker restart cassandra3

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
