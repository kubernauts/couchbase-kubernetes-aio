#!/bin/sh

WORK_DIR=${WORK_DIR:="/work-dir"}
COUCHBASE_USERNAME=${COUCHBASE_USERNAME:=""}
COUCHBASE_PASSWORD=${COUCHBASE_PASSWORD:=""}

OS_AUTH_URL=${OS_AUTH_URL:=""}
OS_USERNAME=${OS_USERNAME:=""}
OS_PASSWORD=${OS_PASSWORD:=""}
OS_TENANT_NAME=${OS_TENANT_NAME:=""}
OS_REGION=${OS_REGION:=""}
OS_CONTAINER=${CONTAINER:=""}

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

backup() {
    echo "hello, I am Backup !"
    # TODO: use couchbase cli to generate backup
    cbbackup --bucket-source couchbase://Administrator:password@HOST:8091
    # TODO: use openstack cli to upload to swift
}

usage() {
    echo "\
    Usage: $0
        -w, --work-dir
            bootstrap script directory
        -h, --help
            help" 1>&2;
    exit 1;
}

for i in "$@"
do
case $i in
    -w=*|--work-dir=*)
    WORK_DIR="${i#*=}"
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

try backup