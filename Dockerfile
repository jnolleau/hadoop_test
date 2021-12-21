FROM ubuntu:latest

WORKDIR /root

# install openssh-server, openjdk and wget
RUN apt-get update && apt-get install -y openssh-server openjdk-17-jdk wget vim

# install hadoop 3.3.1
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.1/hadoop-3.3.1.tar.gz && \
    tar -xzvf hadoop-3.3.1.tar.gz && \
    mv hadoop-3.3.1 /usr/local/hadoop && \
    rm hadoop-3.3.1.tar.gz

# install spark 3.2.0
RUN wget https://dlcdn.apache.org/spark/spark-3.2.0/spark-3.2.0-bin-hadoop3.2.tgz && \
    tar -xvf spark-3.2.0-bin-hadoop3.2.tgz && \
    mv spark-3.2.0-bin-hadoop3.2 /usr/local/spark && \
    rm spark-3.2.0-bin-hadoop3.2.tgz

# install kafka
RUN wget https://dlcdn.apache.org/kafka/3.0.0/kafka_2.13-3.0.0.tgz && \
    tar -xzvf kafka_2.13-3.0.0.tgz && \
    mv kafka_2.13-3.0.0 /usr/local/kafka && \
    rm kafka_2.13-3.0.0.tgz

# install hbase
RUN wget https://dlcdn.apache.org/hbase/2.4.8/hbase-2.4.8-bin.tar.gz  && \ 
    tar -zxvf hbase-2.4.8-bin.tar.gz && \
    mv hbase-2.4.8 /usr/local/hbase && \
    rm hbase-2.4.8-bin.tar.gz

# copy purchases.txt
COPY purchases.txt.gz .
RUN gzip -d purchases.txt.gz
# && rm purchases.txt.gz

# set environment variables
ENV USER=root
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 
ENV HADOOP_HOME=/usr/local/hadoop 
ENV SPARK_HOME=/usr/local/spark
ENV KAFKA_HOME=/usr/local/kafka
ENV HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
ENV LD_LIBRARY_PATH=/usr/local/hadoop/lib/native:$LD_LIBRARY_PATH
ENV HBASE_HOME=/usr/local/hbase
ENV CLASSPATH=$CLASSPATH:/usr/local/hbase/lib/*
ENV PATH=$PATH:/usr/local/hadoop/bin:/usr/local/hadoop/sbin:/usr/local/spark/bin:/usr/local/kafka/bin:/usr/local/hbase/bin 

# ssh without key
RUN ssh-keygen -t rsa -f ~/.ssh/id_rsa -P '' && \
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

RUN mkdir -p ~/hdfs/namenode && \
    mkdir -p ~/hdfs/datanode && \
    mkdir $HADOOP_HOME/logs

COPY config/* /tmp/

RUN mv /tmp/ssh_config ~/.ssh/config && \
    mv /tmp/hadoop-env.sh /usr/local/hadoop/etc/hadoop/hadoop-env.sh && \
    # mv /tmp/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml && \
    # mv /tmp/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml && \
    # mv /tmp/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml && \
    # # mv /tmp/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml && \
    mv /tmp/slaves $HADOOP_HOME/etc/hadoop/slaves && \
    mv /tmp/start-kafka-zookeeper.sh ~/start-kafka-zookeeper.sh && \
    mv /tmp/start-hadoop.sh ~/start-hadoop.sh && \
    mv /tmp/run-wordcount.sh ~/run-wordcount.sh && \
    mv /tmp/spark-defaults.conf $SPARK_HOME/conf/spark-defaults.conf && \
    mv /tmp/hbase-env.sh $HBASE_HOME/conf/hbase-env.sh && \
    # mv /tmp/hbase-site.xml $HBASE_HOME/conf/hbase-site.xml

RUN chmod +x ~/start-hadoop.sh && \
    chmod +x ~/start-kafka-zookeeper.sh && \
    chmod +x ~/run-wordcount.sh && \
    chmod +x $HADOOP_HOME/sbin/start-dfs.sh && \
    chmod +x $HADOOP_HOME/sbin/start-yarn.sh 

# format namenode
RUN /usr/local/hadoop/bin/hdfs namenode -format

CMD [ "sh", "-c", "service ssh start; bash"]


