# Redis
docker stop redis1
docker stop redis2
docker stop redis3

docker remove redis1
docker remove redis2
docker remove redis3

docker network rm redis-cluster-network

# Cassandra
docker stop cassandra1
docker stop cassandra2

docker remove cassandra1
docker remove cassandra2

docker network rm cassandra-cluster-network
