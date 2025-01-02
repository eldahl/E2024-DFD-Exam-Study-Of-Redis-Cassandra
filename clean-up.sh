# Redis
docker stop redis1
docker stop redis2
docker stop redis3

docker container rm -v redis1
docker container rm -v redis2
docker container rm -v redis3

docker network rm redis-cluster-network

# Cassandra
docker stop cassandra1
docker stop cassandra2
docker stop cassandra3

docker container rm -v cassandra1
docker container rm -v cassandra2
docker container rm -v cassandra3

docker network rm cassandra-cluster-network
