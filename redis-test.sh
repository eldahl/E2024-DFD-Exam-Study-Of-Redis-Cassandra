source "./assert.sh"

NORMAL=$(echo -en "\e[00m")
STATUS=$(echo -en "\e[0;35m")
RED=$(echo -en "\e[31m")
GREEN=$(echo -en "\e[32m")

CLUSTER_NETWORK_NAME="redis-cluster-network"

# insert a key into the Redis cluster before partition
printf "${STATUS}Inserting data before partition... ${NORMAL}"
docker exec -it redis1 redis-cli -c -p 6379 SET key1 "Before Partition"

printf "${STATUS}Querying data from redis2 (before-disconnect node)...: ${NORMAL}\n"
docker exec -it redis2 redis-cli -c -p 6379 GET key1
docker exec -it redis2 redis-cli -c -p 6379 GET key2

# simulate network partition (disconnect a master node)
printf "\n${RED}Simulating network partition... ${NORMAL}\n"
docker network disconnect $CLUSTER_NETWORK_NAME redis2

# demonstrate AP (Partition Tolerance + Availability)
printf "${STATUS}Demonstrating AP: Writing data during partition... ${NORMAL}"
docker exec -it redis1 redis-cli -c -p 6379 SET key2 "During Partition"

printf "${STATUS}Querying data from redis2 (disconnected node)... ${NORMAL}\n"
docker exec -it redis2 redis-cli -c -p 6379 GET key1
docker exec -it redis2 redis-cli -c -p 6379 GET key2

# reconnect the network and check for inconsistencies
printf "\n${GREEN}Reconnecting network... ${NORMAL}\n"
docker network connect $CLUSTER_NETWORK_NAME redis2

printf "${STATUS}Querying data from redis1 (master)... ${NORMAL}\n"
docker exec -it redis1 redis-cli -c -p 6379 GET key1
docker exec -it redis1 redis-cli -c -p 6379 GET key2

printf "${STATUS}Querying data from redis2 (reconnected node)... ${NORMAL}\n"
docker exec -it redis2 redis-cli -c -p 6379 GET key1
docker exec -it redis2 redis-cli -c -p 6379 GET key2
