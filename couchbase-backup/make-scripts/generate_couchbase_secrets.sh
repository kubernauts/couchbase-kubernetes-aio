#!/bin/sh

WORK_DIR=${WORK_DIR:="$HOME"}
USERNAME=${USERNAME:=""}
PASSWORD=${PASSWORD:=""}

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

generate() {

cat <<EOF > ${WORK_DIR}/ngwsa-couchbase-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ngwsa-couchbase-secrets
type: Opaque
data:
  couchbase.username: $(echo -n ${USERNAME} | base64 -w 0)
  couchbase.password: $(echo -n ${PASSWORD} | base64 -w 0)
EOF

}

usage() {
    echo "\
    Usage: $0
        -w, --work-dir
            directory were to put the generated yaml. defaults to home folder
        -u, --username
            username
        -p, --password
            password

    Output:
        ngwsa-couchbase-secrets.yaml" 1>&2;
    exit 1;
}

for i in "$@"
do
case $i in
    -w=*|--work-dir=*)
    WORK_DIR="${i#*=}"
    shift
    ;;
    -u=*|--username=*)
    BUCKET="${i#*=}"
    shift
    ;;
    -p=*|--password=*)
    PASSWORD="${i#*=}"
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