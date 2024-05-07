#!/bin/bash

RS='\033[0m'
CY='\033[0;36m'
GR='\033[0;32m'

set -e

if [ -z $KAFKA_CLUSTER_ID ]; then
  UUID=$(bin/kafka-storage.sh random-uuid);
  echo "😅 You must set KAFKA_CLUSTER_ID: $UUID"
  exit 1
fi

echo "📌 Setting up Kafka configuration"
cat /opt/kafka/config/kraft/server.properties.template | sed \
  -e "s|{{KAFKA_NODE_ID}}|${KAFKA_NODE_ID:-0}|g" \
  -e "s|{{KAFKA_BROKER_ID}}|${KAFKA_BROKER_ID:-0}|g" \
  -e "s|{{KAFKA_ROLES}}|${KAFKA_ROLES:-}|g" \
  -e "s|{{KAFKA_QUORUM}}|${KAFKA_QUORUM:-}|g" \
  -e "s|{{KAFKA_LISTENERS}}|${KAFKA_LISTENERS:-}|g" \
  -e "s|{{KAFKA_ADVERTISED_LISTENERS}}|${KAFKA_ADVERTISED_LISTENERS:-}|g" \
  -e "s|{{KAFKA_LISTENERS_PROTOCOLS}}|${KAFKA_LISTENERS_PROTOCOLS:-}|g" \
  -e "s|{{KAFKA_PARTITIONS}}|${KAFKA_PARTITIONS:-1}|g" \
  -e "s|{{KAFKA_DEFAULT_REPLICAS}}|${KAFKA_DEFAULT_REPLICAS:-1}|g" \
  -e "s|{{KAFKA_REPLICAS}}|${KAFKA_REPLICAS:-1}|g" \
  -e "s|{{KAFKA_MIN_ISR}}|${KAFKA_MIN_ISR:-1}|g" \
  > $NODE_PROPERTIES
echo "✅ Kafka config generated"

echo "📌 Setting up Kafka storage"
echo -e "Running command: "$CY"bin/kafka-storage.sh format -t "$KAFKA_CLUSTER_ID" -c "$NODE_PROPERTIES$RS
if bin/kafka-storage.sh format -t $KAFKA_CLUSTER_ID -c $NODE_PROPERTIES; then
    echo "✅ Kafka storage formatted"
fi

echo "🚀 Running Kafka with generated configuration $NODE_PROPERTIES:"
for line in `cat $NODE_PROPERTIES | grep -v "#" | awk 'NF'`
do
  echo -e $GR"$line"$RS
done

bin/kafka-server-start.sh $NODE_PROPERTIES
