#!/bin/sh

WORK_DIR=${WORK_DIR:="/work-dir"}

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

generate() {
    cp /bootstrap.sh ${WORK_DIR}
    cp /jq ${WORK_DIR}
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

try generate