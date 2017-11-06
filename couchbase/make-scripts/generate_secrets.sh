#!/bin/sh

WORK_DIR=${WORK_DIR:="$HOME"}
ADMIN_USERNAME=${ADMIN_USERNAME:="admin"}
ADMIN_PASSWORD=${ADMIN_PASSWORD:="password"}
READ_USERNAME=${READ_USERNAME:="user"}
READ_PASSWORD=${READ_PASSWORD:="password"}

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

generate() {

# generate user auth secret
cat <<EOF > ${WORK_DIR}/couchbase-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: couchbase-secrets
type: Opaque
data:
  adminUsername: $(echo -n ${ADMIN_USERNAME} | base64)
  adminPassword: $(echo -n ${ADMIN_PASSWORD} | base64)
  readOnlyUsername: $(echo -n ${READ_USERNAME} | base64)
  readOnlyPassword: $(echo -n ${READ_PASSWORD} | base64)
EOF

}

usage() {
    echo "\
    Usage: $0
        --work-dir
            directory were to put the generated yaml. defaults to home folder
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
    -w=*|--work-dir=*)
    WORK_DIR="${i#*=}"
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

try generate
