# Study of Redis & Apache Cassandra
This repository is the practical part of an examination in the subject Databases For Developers, and holds demonstration scripts for the adherence to the CAP theorem principles.

## Running demonstration scripts
Both databases has a setup and test script. They are made such that the whole procedure for both databases can be run as follows:
#### Redis:
```
./redis-setup.sh && ./redis-test.sh
```
#### Apache Cassandra:
```
./cassandra-setup.sh && ./cassandra-test.sh
```

## Results
Listed here are the outputs of the test procedures.

#### Redis:
```
Performing Redis test.
Inserting data into redis1 before partition... OK
Data in redis1...: 
"Before partition"
(nil)
(nil)
Data in redis2...: 
"Before partition"
(nil)
(nil)
Data in redis3...: 
"Before partition"
(nil)
(nil)

Simulating network partition (disconnect redis3)... 
Demonstrating AP: Writing data to redis1 during partition... 
OK
Data in redis1...: 
"Before partition"
"During partition"
(nil)
Data in redis2...: 
"Before partition"
"During partition"
(nil)
Data in redis3...: 
(error) CLUSTERDOWN The cluster is down
(error) CLUSTERDOWN The cluster is down
(error) CLUSTERDOWN The cluster is down
✔ Writing to majority partition during outage is possible.
  Availability has been chosen over full consistency across the cluster. 

Reconnecting network (connecting redis3)... 
Writing data to redis1 after resolvoing partition... OK
Data in redis1...: 
"Before partition"
"During partition"
"After partition"
Data in redis2...: 
"Before partition"
"During partition"
"After partition"
Data in redis3...: 
"Before partition"
"During partition"
"After partition"
✔ Data is replicated to minority partition nodes when a stable connection is held.
```
#### Apache Cassandra:
```
Creating Keyspace with SimpleStrategy & replication_factor of 3 | Setup test_table table. 
Demonstrating AP: Writing data to test_table during partition with consistency level ONE... 
Consistency level set to ONE.
Data in Cassandra1... 

 id                                   | value
--------------------------------------+--------------
 86520438-70f8-4010-9495-b44b3a5f752e | Initial data

(1 rows)
Data in Cassandra2... 

 id                                   | value
--------------------------------------+--------------
 86520438-70f8-4010-9495-b44b3a5f752e | Initial data

(1 rows)
Data in Cassandra3... 

 id                                   | value
--------------------------------------+--------------
 86520438-70f8-4010-9495-b44b3a5f752e | Initial data

(1 rows)
Simulating network partition (disconnecting cassandra2 & cassandra3)... 
Attempting write during partition... 
Data in Cassandra1... 

 id                                   | value
--------------------------------------+----------------------------------
 4e8a97e7-433d-4069-b9b2-7a7388f878c6 | During Consistency ONE partition
 86520438-70f8-4010-9495-b44b3a5f752e |                     Initial data

(2 rows)
Data in Cassandra2... 

 id                                   | value
--------------------------------------+--------------
 86520438-70f8-4010-9495-b44b3a5f752e | Initial data

(1 rows)
Data in Cassandra3... 

 id                                   | value
--------------------------------------+--------------
 86520438-70f8-4010-9495-b44b3a5f752e | Initial data

(1 rows)
✔ Data is written to Cassandra1, a partition in the table accross the cluster has been created due to prioritizing availability over consistency.
Reconnecting network to cassandra2 & cassandra3... 
Data in Cassandra1... 

 id                                   | value
--------------------------------------+----------------------------------
 4e8a97e7-433d-4069-b9b2-7a7388f878c6 | During Consistency ONE partition
 86520438-70f8-4010-9495-b44b3a5f752e |                     Initial data

(2 rows)
Data in Cassandra2... 

 id                                   | value
--------------------------------------+----------------------------------
 4e8a97e7-433d-4069-b9b2-7a7388f878c6 | During Consistency ONE partition
 86520438-70f8-4010-9495-b44b3a5f752e |                     Initial data

(2 rows)
Data in Cassandra3... 

 id                                   | value
--------------------------------------+----------------------------------
 4e8a97e7-433d-4069-b9b2-7a7388f878c6 | During Consistency ONE partition
 86520438-70f8-4010-9495-b44b3a5f752e |                     Initial data

(2 rows)
✔ Data is synchronized on network reconnection.
Demonstrating CP: Writing during partition with consistency level QUORUM... 
Consistency level set to QUORUM.
Simulating network partition (disconnecting cassandra2 & cassandra3)... 
Attempting write during partition... 
<stdin>:1:NoHostAvailable: ('Unable to complete the operation against any hosts', {<Host: 127.0.0.1:9042 datacenter1>: Unavailable('Error from server: code=1000 [Unavailable exception] message="Cannot achieve consistency level QUORUM" info={\'consistency\': \'QUORUM\', \'required_replicas\': 2, \'alive_replicas\': 1}')})
Consistency level set to QUORUM.
Data in Cassandra1... 

 id                                   | value
--------------------------------------+----------------------------------
 4e8a97e7-433d-4069-b9b2-7a7388f878c6 | During Consistency ONE partition
 86520438-70f8-4010-9495-b44b3a5f752e |                     Initial data

(2 rows)
Data in Cassandra2... 

 id                                   | value
--------------------------------------+----------------------------------
 4e8a97e7-433d-4069-b9b2-7a7388f878c6 | During Consistency ONE partition
 86520438-70f8-4010-9495-b44b3a5f752e |                     Initial data

(2 rows)
Data in Cassandra3... 

 id                                   | value
--------------------------------------+----------------------------------
 4e8a97e7-433d-4069-b9b2-7a7388f878c6 | During Consistency ONE partition
 86520438-70f8-4010-9495-b44b3a5f752e |                     Initial data

(2 rows)
✔ Data is NOT written to Cassandra1 (and therefore not synchronized), a partition in the table has been avoided by sacrificing availability over consistency.
```
