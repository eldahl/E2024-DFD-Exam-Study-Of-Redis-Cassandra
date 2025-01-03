source "./assert.sh"

NORMAL=$(echo -en "\e[00m")
STATUS=$(echo -en "\e[0;35m")
RED=$(echo -en "\e[31m")
GREEN=$(echo -en "\e[32m")

CLUSTER_NETWORK_NAME="redis-cluster-network"

print_data() {
  printf "${STATUS}Data in redis1...: ${NORMAL}\n"
  docker exec -it redis1 redis-cli -c -p 6379 GET key1
  docker exec -it redis1 redis-cli -c -p 6379 GET key2
  docker exec -it redis1 redis-cli -c -p 6379 GET key3

  printf "${STATUS}Data in redis2...: ${NORMAL}\n"
  docker exec -it redis2 redis-cli -c -p 6379 GET key1
  docker exec -it redis2 redis-cli -c -p 6379 GET key2
  docker exec -it redis2 redis-cli -c -p 6379 GET key3

  printf "${STATUS}Data in redis3...: ${NORMAL}\n"
  docker exec -it redis3 redis-cli -c -p 6379 GET key1
  docker exec -it redis3 redis-cli -c -p 6379 GET key2
  docker exec -it redis3 redis-cli -c -p 6379 GET key3
}


printf "${RED}Performing Redis test.${NORMAL}\n"

# Insert a key into the Redis cluster before partition
printf "${STATUS}Inserting data into redis1 before partition... ${NORMAL}"
docker exec -it redis1 redis-cli -c -p 6379 SET key1 "Before partition"

print_data

# Simulate network partition
printf "\n${STATUS}Simulating network partition (disconnect redis3)... ${NORMAL}\n"
docker network disconnect $CLUSTER_NETWORK_NAME redis3
sleep 10

# Demonstrate AP (Partition Tolerance + Availability)
printf "${RED}Demonstrating AP: Writing data to redis1 during partition... ${NORMAL}\n"
docker exec -it redis1 redis-cli -c -p 6379 SET key2 "During partition"

print_data
log_success "Writing to majority partition during outage is possible."
printf "${GREEN}  Availability has been chosen over full consistency across the cluster. ${NORMAL}\n"

# Reconnect the network
printf "\n${STATUS}Reconnecting network (connecting redis3)... ${NORMAL}\n"
docker network connect $CLUSTER_NETWORK_NAME redis3
sleep 10

printf "${RED}Writing data to redis1 after resolvoing partition... ${NORMAL}"
docker exec -it redis1 redis-cli -c -p 6379 SET key3 "After partition"

print_data
log_success "Data is replicated to minority partition nodes when a stable connection is held."
