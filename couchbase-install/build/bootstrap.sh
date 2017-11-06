#!/bin/bash

CONFIG_DIR=${CONFIG_DIR:="/config"}
SECRETS_DIR=${SECRETS_DIR:="/secrets"}

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

loadconfig() {

    # load from configmap if exists
    if [ -d ${CONFIG_DIR} ]; then
        echo "Found configmap: ${CONFIG_DIR}"
        if [ -f ${CONFIG_DIR}/master ]; then MASTER_HOST=${MASTER_HOST:="$(cat ${CONFIG_DIR}/master)"}; fi;
        if [ -f ${CONFIG_DIR}/autoRebalance ]; then AUTO_REBALANCE=${AUTO_REBALANCE:="$(cat ${CONFIG_DIR}/autoRebalance)"}; fi;
        if [ -f ${CONFIG_DIR}/memoryQuota ]; then MEMORY_QUOTA=${MEMORY_QUOTA:="$(cat ${CONFIG_DIR}/memoryQuota)"}; fi;
        if [ -f ${CONFIG_DIR}/indexMemoryQuota ]; then INDEX_MEMORY_QUOTA=${INDEX_MEMORY_QUOTA:="$(cat ${CONFIG_DIR}/indexMemoryQuota)"}; fi;
        if [ -f ${CONFIG_DIR}/ftsMemoryQuota ]; then FTS_MEMORY_QUOTA=${FTS_MEMORY_QUOTA:="$(cat ${CONFIG_DIR}/ftsMemoryQuota)"}; fi;
        if [ -f ${CONFIG_DIR}/services ]; then SERVICES=${SERVICES:="$(cat ${CONFIG_DIR}/services)"}; fi;
        if [ -f ${CONFIG_DIR}/storageMode ]; then STORAGE_MODE=${STORAGE_MODE:="$(cat ${CONFIG_DIR}/storageMode)"}; fi;
    else
        echo "No configmap found"
    fi

    # load from secret if exists
    if [ -d ${SECRETS_DIR} ]; then
        echo "Found secrets: ${SECRETS_DIR}"
        if [ -f ${SECRETS_DIR}/adminUsername ]; then ADMIN_USERNAME=${ADMIN_USERNAME:-$(cat ${SECRETS_DIR}/adminUsername)}; fi;
        if [ -f ${SECRETS_DIR}/adminPassword ]; then ADMIN_PASSWORD=${ADMIN_PASSWORD:-$(cat ${SECRETS_DIR}/adminPassword)}; fi;
        if [ -f ${SECRETS_DIR}/readOnlyUsername ]; then READ_USERNAME=${READ_USERNAME:-$(cat ${SECRETS_DIR}/readOnlyUsername)}; fi;
        if [ -f ${SECRETS_DIR}/readOnlyPassword ]; then READ_PASSWORD=${READ_PASSWORD:-$(cat ${SECRETS_DIR}/readOnlyPassword)}; fi;
    else
        echo "No secrets found"
    fi

    # assigning default if no env or config map was present
    MASTER_HOST=${MASTER_HOST:="couchbase-stateset-0"}
    AUTO_REBALANCE=${AUTO_REBALANCE:="false"}
    MEMORY_QUOTA=${MEMORY_QUOTA:="300"}
    INDEX_MEMORY_QUOTA=${INDEX_MEMORY_QUOTA:="300"}
    FTS_MEMORY_QUOTA=${FTS_MEMORY_QUOTA:="512"}
    SERVICES=${SERVICES:="kv%2Cn1ql%2Cindex"}
    STORAGE_MODE=${STORAGE_MODE:="memory_optimized"}

    ADMIN_USERNAME=${ADMIN_USERNAME:="Administrator"}
    ADMIN_PASSWORD=${ADMIN_PASSWORD:="password"}

    READ_USERNAME=${READ_USERNAME:="user"}
    READ_PASSWORD=${READ_PASSWORD:="password"}

    echo "Master Host: ${MASTER_HOST}"
    echo "Auto Rebalance: ${AUTO_REBALANCE}"
    echo "Memory Quota: ${MEMORY_QUOTA}"
    echo "Index Memory Quota: ${INDEX_MEMORY_QUOTA}"
    echo "Fts Memory Quota: ${FTS_MEMORY_QUOTA}"
    echo "Services: ${SERVICES}"
    echo "Storage mode: ${STORAGE_MODE}"
    echo "Admin Username: ${ADMIN_USERNAME}"
    echo "Admin Password: ${ADMIN_PASSWORD}"
    echo "ReadOnly Username: ${READ_USERNAME}"
    echo "ReadOnly Password: ${READ_PASSWORD}"
}

bootstrap() {

    echo -e "\n\n##################\n"
    echo -e "Waiting for Couchbase to come up...\n" 

    until curl http://127.0.0.1:8091/pools
    do
      echo -n "."
      sleep 1
    done
    echo -e "\n\n##################\n"
   # TODO: Load bucket list

    if [ "${HOSTNAME}" != "${MASTER_HOST}" ]; then
      echo "Hello I am worker: ${HOSTNAME} with autorebalance: ${AUTO_REBALANCE}..."
      SERVER=`hostname -I | cut -d ' ' -f1`

        echo -e "\n\n##################\n"
        echo -e "Waiting for Couchbase Master to come up...\n" 

        until curl -u ${ADMIN_USERNAME}:${ADMIN_PASSWORD} \
            http://${MASTER_HOST}.couchbase:8091/pools
        do
          echo -n "."
          sleep 1
        done
        echo -e "\n\n##################\n"

      echo "Auto Rebalance: ${AUTO_REBALANCE}"
      if [ "${AUTO_REBALANCE}" = "true" ]; then
          couchbase-cli rebalance \
                --cluster=${MASTER_HOST}.couchbase:8091 \
                --user=${ADMIN_USERNAME} \
                --password=${ADMIN_PASSWORD} \
                --server-add=${SERVER} \
                --server-add-username=${ADMIN_USERNAME} \
                --server-add-password=${ADMIN_PASSWORD}
      else
           # Add node
        echo -e "\n\n##################\n"
           echo "Add node..."
           curl -u ${ADMIN_USERNAME}:${ADMIN_PASSWORD} -X POST  \
                http://${MASTER_HOST}.couchbase:8091/controller/addNode \
                -d hostname=${SERVER} \
                -d user=${ADMIN_USERNAME} \
                -d password=${ADMIN_PASSWORD} \
                -d services=${SERVICES}
             echo -e "\n\n##################\n"

            # get knownNodes
            knownNodes=$( curl -u ${ADMIN_USERNAME}:${ADMIN_PASSWORD} http://127.0.0.1:8091/pools/nodes | /work-dir/jq --raw-output '[ .nodes[].otpNode ] | join(",")' )

            echo -e "\n\nFound knownNodes: ${knownNodes}. Going to Rebalance... \n\n"

            # Try to rebalance


           curl -u ${ADMIN_USERNAME}:${ADMIN_PASSWORD} -X POST  \
               http://${MASTER_HOST}.couchbase:8091/controller/rebalance \
               -d ejectedNodes="" \
               -d knownNodes="${knownNodes}"
            
           if [ $? == 0 ]; then
            echo "Rebalanced node successfully"
           else
            echo "Rebalancing node failed!!!"
           fi
       
      fi;
    else
       echo "Hello I am master: ${HOSTNAME}"

        # Setup index and memory quota
        curl -X POST http://127.0.0.1:8091/pools/default \
                -d memoryQuota=${MEMORY_QUOTA} \
                -d indexMemoryQuota=${INDEX_MEMORY_QUOTA} \
                -d ftsMemoryQuota=${FTS_MEMORY_QUOTA}

        # Setup services
        curl -X POST http://127.0.0.1:8091/node/controller/setupServices \
                -d services=${SERVICES}

        # Setup credentials
        curl -X POST http://127.0.0.1:8091/settings/web \
                -d port=8091 \
                -d username=${ADMIN_USERNAME} \
                -d password=${ADMIN_PASSWORD}

        # Setup Memory Optimized Indexes
         curl -u ${ADMIN_USERNAME}:${ADMIN_PASSWORD} -X POST  \
            http://127.0.0.1:8091/settings/indexes \
                -d storageMode=${STORAGE_MODE} \
                -d username=${ADMIN_USERNAME} \
                -d password=${ADMIN_PASSWORD}

       couchbase-cli user-manage -c 127.0.0.1:8091 --set \
                --ro-username=${READ_USERNAME} \
                --ro-password=${READ_PASSWORD} \
                -u ${ADMIN_USERNAME} \
                -p ${ADMIN_PASSWORD}

        # Create Test bucket
        curl -u ${ADMIN_USERNAME}:${ADMIN_PASSWORD} -X POST  \
            http://127.0.0.1:8091/pools/default/buckets \
            -d name=test \
            -d authType=sasl \
            -d saslPassword=test \
            -d bucketType=couchbase \
            -d flushEnabled=1 \
            -d proxyPort=11211 \
            -d ramQuotaMB=${MEMORY_QUOTA}
    fi;
}

usage() {
    echo "\
    Usage: $0
        -c, --config-dir
            configuration directory
        -s, --secrets-dir
            secrets directory
        --master
            master host of the cluster
        --autorebalance
            auto rebalance nodes: true/false
        --memory
            memory quota
        --index-memory
            index memory quota
        --fts-memory
            fts memory quota
        --services
            couchbase services
        --storage-mode
            storage mode
        -u, --admin-username
            admin username
        -p, --admin-password
            admin password
        --readonly-username
            readonly username
        --readonly-password
            readonly password" 1>&2;
    exit 1;
}

for i in "$@"
do
case $i in
    -c=*|--config-dir=*)
    CONFIG_DIR="${i#*=}"
    shift
    ;;
    -s=*|--secrets-dir=*)
    SECRETS_DIR="${i#*=}"
    shift
    ;;
    --master=*)
    MASTER_HOST="${i#*=}"
    shift
    ;;
    --autorebalance)
    AUTO_REBALANCE="true"
    shift
    ;;
    --memory=*)
    MEMORY_QUOTA="${i#*=}"
    shift
    ;;
    --index-memory=*)
    INDEX_MEMORY_QUOTA="${i#*=}"
    shift
    ;;
    --fts-memory=*)
    FTS_MEMORY_QUOTA="${i#*=}"
    shift
    ;;
    --services=*)
    SERVICES="${i#*=}"
    shift
    ;;
    --storage-mode=*)
    STORAGE_MODE="${i#*=}"
    shift
    ;;
    -u=*|--admin-username=*)
    ADMIN_USERNAME="${i#*=}"
    shift
    ;;
    -p=*|--admin-password=*)
    ADMIN_PASSWORD="${i#*=}"
    shift
    ;;
    --readonly-username=*)
    READ_USERNAME="${i#*=}"
    shift
    ;;
    --readonly-password=*)
    READ_PASSWORD="${i#*=}"
    shift
    ;;
    -h|--help)
    usage
    ;;
    *)
    # unknown option
    ;;
esac
done

set -e
set -m
set -x

try loadconfig
/entrypoint.sh couchbase-server &
#sleep 15
try bootstrap
fg 1