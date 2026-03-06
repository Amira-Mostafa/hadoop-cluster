#!/bin/bash

ROLE=$(hostname)

echo "Starting node role: $ROLE"

#start the ssh server and allow simple communication between nodes for Hadoop daemons
# /usr/sbin/sshd 

#starting zookeeper
case "$ROLE" in
    master01) echo "1" > /var/lib/zookeeper/data/myid ;;
    master02) echo "2" > /var/lib/zookeeper/data/myid ;;
    worker01) echo "3" > /var/lib/zookeeper/data/myid ;;
esac

if [[ "$ROLE" == "master01" || "$ROLE" == "master02" || "$ROLE" == "worker01" ]]; then
    echo "Starting ZooKeeper..."
    zkServer.sh start
fi

sleep 5

# Starting JournalNodes
if [[ "$ROLE" == "worker01" || "$ROLE" == "worker02" || "$ROLE" == "worker03" ]]; then
    echo "Starting JournalNode..."
    hdfs --daemon start journalnode
fi

sleep 5

#starging active namenode and resourcemanager
if [[ "$ROLE" == "master01" ]]; then
    if [ ! -d "/opt/hadoop/dfs/name/current" ]; then
        echo "Formatting Active NameNode..."
        hdfs namenode -format -force

        echo "Initializing shared edits..."
        hdfs namenode -initializeSharedEdits -force
    else
        echo "NameNode already formatted, skipping format..."
    fi

    echo "Checking ZooKeeper format..."
    /opt/zookeeper/bin/zkCli.sh -server master01:2181 ls /hadoop-ha/hadoop-cluster &> /dev/null

    if [ $? -ne 0 ]; then
        echo "Formatting ZK..."
        hdfs zkfc -formatZK -force
    else
        echo "ZK already formatted."
    fi

    echo "Starting Active NameNode..."
    hdfs --daemon start namenode
    sleep 10

    echo "Starting ZKFC..."
    hdfs --daemon start zkfc
    sleep 5

    echo "Starting ResourceManager..."
    yarn --daemon start resourcemanager
fi

#starting standby namenode and resourcemanager
if [[ "$ROLE" == "master02" ]]; then
    sleep 10
    if [ ! -d "/opt/hadoop/dfs/name/current" ]; then
        echo "Bootstrapping Standby NameNode..."
        hdfs namenode -bootstrapStandby
    fi

    echo "Starting Standby NameNode..."
    hdfs --daemon start namenode
    sleep 5
    hdfs --daemon start zkfc
    sleep 5

    echo "Starting Standby ResourceManager..."
    yarn --daemon start resourcemanager
fi

# Starting DataNodes and NodeManagers on worker nodes
if [[ "$ROLE" == "worker01" || "$ROLE" == "worker02" || "$ROLE" == "worker03" ]]; then
    echo "Starting DataNode..."
    hdfs --daemon start datanode

    echo "Starting NodeManager..."
    yarn --daemon start nodemanager
fi

echo "Node $ROLE fully started."

# Keep container alive
tail -f /dev/null