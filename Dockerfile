FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt update && apt install -y \
    openjdk-11-jdk \
    openssh-server \
    rsync \
    wget \
    pdsh \
    curl \
    nano \
    net-tools \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*


# Disable root login
# RUN echo "PermitRootLogin no" >> /etc/ssh/sshd_config \
#     && echo "PasswordAuthentication no" >> /etc/ssh/sshd_config


# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin


# Download Hadoop 3.4.2 (use required version from assignment!)
RUN wget https://downloads.apache.org/hadoop/common/hadoop-3.4.2/hadoop-3.4.2.tar.gz \
    && tar -xzf hadoop-3.4.2.tar.gz \
    && mv hadoop-3.4.2 /opt/hadoop \
    && rm hadoop-3.4.2.tar.gz

# Set Hadoop variables
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin

# Create Hadoop storage directories
RUN mkdir -p /opt/hadoop/dfs/name \
    /opt/hadoop/dfs/data \
    /opt/hadoop/dfs/journal


# Download and install ZooKeeper 3.8.1
RUN wget https://downloads.apache.org/zookeeper/zookeeper-3.8.6/apache-zookeeper-3.8.6-bin.tar.gz \
    && tar -xzf apache-zookeeper-3.8.6-bin.tar.gz \
    && mv apache-zookeeper-3.8.6-bin /opt/zookeeper \
    && rm apache-zookeeper-3.8.6-bin.tar.gz

# Set Zookeeper environment variables
ENV ZOOKEEPER_HOME=/opt/zookeeper
ENV PATH=$PATH:$ZOOKEEPER_HOME/bin

# ZooKeeper data directories
RUN mkdir -p /var/lib/zookeeper/data
RUN mkdir -p /var/lib/zookeeper/logs
RUN mkdir -p $ZOOKEEPER_HOME/conf

# Create zoo.cfg
RUN echo "tickTime=2000" > $ZOOKEEPER_HOME/conf/zoo.cfg \
    && echo "dataDir=/var/lib/zookeeper/data" >> $ZOOKEEPER_HOME/conf/zoo.cfg \
    && echo "clientPort=2181" >> $ZOOKEEPER_HOME/conf/zoo.cfg \
    && echo "initLimit=5" >> $ZOOKEEPER_HOME/conf/zoo.cfg \
    && echo "syncLimit=2" >> $ZOOKEEPER_HOME/conf/zoo.cfg \
    && echo "server.1=master01:2888:3888" >> $ZOOKEEPER_HOME/conf/zoo.cfg \
    && echo "server.2=master02:2888:3888" >> $ZOOKEEPER_HOME/conf/zoo.cfg \
    && echo "server.3=worker01:2888:3888" >> $ZOOKEEPER_HOME/conf/zoo.cfg

# Copy Startup Script
COPY start-hadoop.sh /start-hadoop.sh
RUN chmod +x /start-hadoop.sh


CMD ["/start-hadoop.sh"]
