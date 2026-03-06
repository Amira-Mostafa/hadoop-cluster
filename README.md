
**Project:** Development Hadoop Cluster with HDFS & YARN High Availability  

# Table of Contents

1. [Executive Summary](#executive-summary)  
2. [Cluster Architecture](#cluster-architecture)  
3. [Node Roles and Responsibilities](#node-roles-and-responsibilities)  
4. [Installation and Setup](#installation-and-setup)  
5. [Challenges and Solutions](#challenges-and-solutions)  
6. [Checking failover](#checking-failover)  
7. [References](#references)  
---
# 1. Executive Summary
This document describes the implementation of a highly available Hadoop cluster consisting of 5 nodes running on Docker containers. The cluster features:
- **HDFS High Availability (HA)** using Quorum Journal Manager
- **YARN High Availability** with Zookeeper integration
- Replication factor set to **1** (as per project requirements)

---

# 2. Cluster Architecture

## 2.1 Overview Diagram

![Overview Diagram](/Capture.PNG)

---

# 3. Node Roles and Responsibilities

The cluster setup consists of:
- **2 Master Nodes**
- **3 Worker Nodes** 

Each Master node hosts essential services to maintain Hadoop high availability. 
## 3.1 Nodes Distribution Table

| Node     | HDFS Roles         | YARN Roles                | ZooKeeper | JournalNode |
| -------- | ------------------ | ------------------------- | --------- | ----------- |
| master01 | NameNode (Active)  | ResourceManager (Active)  | ✓         | -           |
| master02 | NameNode (Standby) | ResourceManager (Standby) | ✓         | -           |
| worker01 | DataNode           | NodeManager               | ✓         | ✓           |
| worker02 | DataNode           | NodeManager               | -         | ✓           |
| worker03 | DataNode           | NodeManager               | -         | ✓           |
|          |                    |                           |           |             |

## 3.2 Architecture Justification

| Node     | Role Justification                                                                                                                                                                                                                                                                   |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| master01 | hosts Active hdfs NameNode to handle metadata and Active ResourceManager to handle yarn job scheduling during computations, and zookeeper for failover control                                                                                                                       |
| master02 | Secondary master - hosts Standby NameNode and Standby ResourceManager to take over if the active failed                                                                                                                                                                              |
| worker01 | DataNode (storing data blocks), NodeManager (providing data locality for compution), JournalNode (edit log quorum for the active namenode to write and standby to read), and ZooKeeper (monitoring namenodes and  failover control), this node completes the 3 zookeeper requirement |
| worker02 | DataNode, NodeManager, and JournalNode - provides storage and computation with JournalNode quorum participation                                                                                                                                                                      |
| worker03 | DataNode, NodeManager, and JournalNode - completes the 3-node JournalNode quorum requirement                                                                                                                                                                                         |
|          |                                                                                                                                                                                                                                                                                      |

## 3.3 Daemon Port Mapping

| Service                   | Container Port | Host Access                             |
| ------------------------- | -------------- | --------------------------------------- |
| HDFS Web UI (master01)    | 9870           | [localhost:9871](http://localhost:9871) |
| HDFS Web UI (master02)    | 9870           | [localhost:9872](http://localhost:9872) |
| YARN Web UI (master01)    | 8088           | [localhost:8081](http://localhost:8081) |
| YARN Web UI (master02)    | 8088           | [localhost:8082](http://localhost:8082) |
| JournalNode UI (worker01) | 8485           | [localhost:8483](http://localhost:8483) |
| JournalNode UI (worker02) | 8485           | [localhost:8484](http://localhost:8484) |
| JournalNode UI (worker03) | 8485           | [localhost:8485](http://localhost:8485) |

---

# 4. Installation and Setup

## 4.1 Instructions

1. Navigate to the project root.
2. Build and start the cluster using Docker Compose:

```bash
docker-compose up --build
```

  3. Verify services using:

```shell
docker exec -it <container_id> bash
```

## 4.2 Directory Structure

```
hadoop-cluster/
├── Dockerfile
├── docker-compose.yml
├── start-hadoop.sh
├── shared/
│   ├── hadoop/           # Configuration files
│   ├── master01/         # NameNode data
│   ├── master02/         # NameNode data
│   ├── worker01/         # JournalNode data + data blocks
│   ├── worker02/         # JournalNode data + data blocks
│   ├── worker03/         # JournalNode data + data blocks
│   └── data/             # Input/output data for ingestion
```


# 6. Checking failover

## 6.1 HDFS HA Test
  
```bash
# Check initial status in any of the masters
hdfs haadmin -getAllServiceState

# stop active or standby NameNode daemon
hdfs --daemon stop namenode

# Verify failover
hdfs haadmin -getAllServiceState
  
```

## 6.2 YARN HA Test
```bash
# Check ResourceManager status in any of the masters
yarn rmadmin -getAllServiceState 

# stop active ResourceManager
yarn --daemon stop resourcemanager

# Verify failover
yarn rmadmin -getAllServiceState

```

```bash
# Test YARN by running a job
yarn node -list
```

## 6.3 Data Ingestion Test

```bash
# I already have prepared a folder /data for ingestion and mapreduce jobs
# and you can access this folder from any worker node
docker exec -it worker01 bash

# Create HDFS directory
hdfs dfs -mkdir -p /ingest

# Ingest data from the input-data folder inside /data into the new dir
hdfs dfs -put /data/input-data/* /ingest/

# to re ingest
hdfs dfs -put -f /data/input-data/* /ingest/ 

# Verify ingestion
hdfs dfs -ls /ingest/ 
hdfs dfs -cat /ingest/1
```

## 6.4 MapReduce Test

```bash

# Run mapreduce
hadoop jar /data/MR/mr_max_temperature/mr_max_temperature.jar mr.example.MaxTemperatureMapperCombinerPartitionerReducer /ingest /output/output_1

# Check results
hdfs dfs -ls /output/output_1
hdfs dfs -cat /output/output_1/part-r-00000

# result should be like this:
Found 2 items
-rw-r--r--   1 root supergroup          0 2026-03-04 10:22 /output/_SUCCESS
-rw-r--r--   1 root supergroup         60 2026-03-04 10:22 /output/part-r-00000

```

---

# 7. References

1. Apache Hadoop Set up: https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/ClusterSetup.html

2. HDFS High Availability: [https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html)

3. YARN High Availability: [https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html)
