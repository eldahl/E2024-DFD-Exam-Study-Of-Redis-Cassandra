source "./assert.sh"

NORMAL=$(echo -en "\e[00m")
STATUS=$(echo -en "\e[0;35m")
RED=$(echo -en "\e[31m")
GREEN=$(echo -en "\e[32m")

CLUSTER_NETWORK_NAME="cassandra-cluster-network"

## Show data in test_table
print_data() {
  printf "${STATUS}Data in Cassandra1... ${NORMAL}\n"
  docker exec cassandra1 cqlsh -e "USE testks; SELECT * FROM test_table;"
  printf "${STATUS}Data in Cassandra2... ${NORMAL}\n"
  docker exec cassandra2 cqlsh -e "USE testks; SELECT * FROM test_table;"
  printf "${STATUS}Data in Cassandra3... ${NORMAL}\n"
  docker exec cassandra3 cqlsh -e "USE testks; SELECT * FROM test_table;"
}

# Setup keyspace with SimpleStrategy & replication factor 3 and create test_table table
printf "${STATUS}Creating Keyspace with SimpleStrategy & replication_factor of 3 | Setup test_table table. ${NORMAL}\n"
docker exec cassandra1 cqlsh -e "CREATE KEYSPACE IF NOT EXISTS testks WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};"
docker exec cassandra1 cqlsh -e "USE testks; CREATE TABLE IF NOT EXISTS test_table (id UUID PRIMARY KEY, value TEXT);"


# Demonstrate AP (Partition Tolerance + Availability)
printf "${RED}Demonstrating AP: Writing data to test_table during partition with consistency level ONE... ${NORMAL}\n"
docker exec cassandra1 cqlsh -e "USE testks; CONSISTENCY ONE;"
docker exec cassandra1 cqlsh -e "USE testks; INSERT INTO test_table (id, value) VALUES (uuid(), 'Initial data');"

## Show data in test_table
print_data

## Simulate network partition by disconnecting cassandra2 and cassandra3
printf "${STATUS}Simulating network partition... ${NORMAL}\n"
sleep 5
docker network disconnect $CLUSTER_NETWORK_NAME cassandra2
docker network disconnect $CLUSTER_NETWORK_NAME cassandra3

## Insert data during partition
printf "${STATUS}Attempting write during partition... ${NORMAL}\n"
docker exec cassandra1 cqlsh -e "USE testks; INSERT INTO test_table (id, value) VALUES (uuid(), 'During Consistency ONE partition');"

## Show data in test_table
print_data
log_success "Data is written to Cassandra1, a partition in the table accross the cluster has been created."

## Reconnect the network
printf "${STATUS}Reconnecting network and demonstrating eventual consistency... ${NORMAL}\n"
docker network connect $CLUSTER_NETWORK_NAME cassandra2
docker network connect $CLUSTER_NETWORK_NAME cassandra3
sleep 30  # Wait for Cassandra nodes to synchronize

## Show data in test_table
print_data
log_failure "Data is NOT synchronized on network reconnection."



# Demonstrate CP (Partition Tolerance + Consistency)
printf "${RED}Demonstrating CP: Writing during partition with consistency level QUORUM... ${NORMAL}\n"

## Set consistency to quorum
docker exec cassandra1 cqlsh -e "USE testks; CONSISTENCY QUORUM;"

## Disconnect network
printf "${STATUS}Simulating network partition... ${NORMAL}\n"
sleep 5
docker network disconnect $CLUSTER_NETWORK_NAME cassandra2
docker network disconnect $CLUSTER_NETWORK_NAME cassandra3

## Write to Cassandra1
printf "${STATUS}Attempting write during partition... ${NORMAL}\n"
docker exec cassandra1 cqlsh -e "USE testks; INSERT INTO test_table (id, value) VALUES (uuid(), 'During Consistency QUORUM partition');"

## Show data in test_table
print_data
log_success "Data is written to Cassandra1, a partition in the table accross the cluster has been created."

## weconnect cassandra2 cassandra3
printf "${STATUS}Reconnecting network... ${NORMAL}\n"
docker network connect $CLUSTER_NETWORK_NAME cassandra2
docker network connect $CLUSTER_NETWORK_NAME cassandra3
sleep 30

## Show data in test_table
print_data
log_success "Data is synchronized on network reconnection."
