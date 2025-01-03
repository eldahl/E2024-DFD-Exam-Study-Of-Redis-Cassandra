source "./assert.sh"

CLUSTER_NETWORK_NAME="cassandra-cluster-network"

# $1 is node/container name
start_cluster_node() {
  docker run -d --name $1 --net $CLUSTER_NETWORK_NAME -e CASSANDRA_SEEDS=cassandra1 -e CASSANDRA_CLUSTER_NAME=my-cluster -e CASSANDRA_DC=my-datacenter-1 cassandra:latest
  
  ## Sleep for 5 seconds
  echo "Waiting for ${1} to start up."
  do_loop=true
  while [ $do_loop == true ]
  do
    sleep 10

    ## Get cluster info
    cassandra_cluster_info="$(docker exec -it $1 nodetool status)"

    if echo "${cassandra_cluster_info}" | grep -Fq "UN  "; then
      printf "\n"
      echo "${cassandra_cluster_info}"
      log_success "Successfully set up ${1} instance."
      do_loop=false
    else
      printf "..."
    fi
  done
}

# Clear previous Cassandra docker containers that might be running
clean_up() {
  docker stop cassandra1
  docker stop cassandra2
  docker stop cassandra3

  docker container rm -v cassandra1
  docker container rm -v cassandra2
  docker container rm -v cassandra3

  docker network rm $CLUSTER_NETWORK_NAME

  log_success "Cleared previous Cassandra cluster containers"
}

start_cluster() {
  # Set up Cassandra containers
  docker network create $CLUSTER_NETWORK_NAME

  start_cluster_node cassandra1
  start_cluster_node cassandra2
  start_cluster_node cassandra3
}

# Check that docker is installed
if [ -x "$(command -v docker)" ]; then
  log_success "Docker is installed"
else
  log_failure "Docker is not installed"
  exit
fi

# Build dockerfile with custom configuration
docker build -t custom-cassandra -f Cassandra.Dockerfile .

clean_up
start_cluster
log_success "Set up Cassandra cluster containers."
sleep 5
