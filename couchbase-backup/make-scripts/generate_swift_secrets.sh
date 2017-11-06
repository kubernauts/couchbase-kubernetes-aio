#!/bin/sh

WORK_DIR=${WORK_DIR:="$HOME"}
OS_AUTH_URL=${OS_AUTH_URL:=""}
OS_USERNAME=${OS_USERNAME:=""}
OS_PASSWORD=${OS_PASSWORD:=""}
OS_TENANT_NAME=${OS_TENANT_NAME:=""}
OS_REGION=${OS_REGION:=""}
OS_CONTAINER=${CONTAINER:=""}

yell() { echo "$0: $*" >&2; }
die() { yell "$*"; exit 111; }
try() { "$@" || die "cannot $*"; }

generate() {

cat <<EOF > ${WORK_DIR}/swift-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: swift-secrets
type: Opaque
data:
  os_auth_url: $(echo -n ${OS_AUTH_URL} | base64 -w 0)
  os_username: $(echo -n ${OS_USERNAME} | base64 -w 0)
  os_password: $(echo -n ${OS_PASSWORD} | base64 -w 0)
  os_tenant_name: $(echo -n ${OS_TENANT_NAME} | base64 -w 0)
  os_region: $(echo -n ${OS_REGION} | base64 -w 0)
  os_container: $(echo -n ${OS_CONTAINER} | base64 -w 0)
EOF

}

usage() {
    echo "\
    Usage: $0
        -w, --work-dir
            directory were to put the generated yaml. defaults to home folder
        --os-auth-url
            os auth-url
        --os-username
            os username
        --os-password
            os password
        --os-tenant-name
            os tenant name
        --os-region
            os region
        --os-container
            os container

    Output:
        swift-secrets.yaml" 1>&2;
    exit 1;
}

for i in "$@"
do
case $i in
    -w=*|--work-dir=*)
    WORK_DIR="${i#*=}"
    shift
    ;;
    --os-auth-url=*)
    OS_AUTH_URL="${i#*=}"
    shift
    ;;
    --os-username=*)
    OS_USERNAME="${i#*=}"
    shift
    ;;
    --os--password=*)
    OS_PASSWORD="${i#*=}"
    shift
    ;;
    --os-tenant-name=*)
    OS_TENANT_NAME="${i#*=}"
    shift
    ;;
    --os-region=*)
    OS_REGION="${i#*=}"
    shift
    ;;
    --os-container=*)
    OS_CONTAINER="${i#*=}"
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