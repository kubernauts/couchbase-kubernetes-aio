# -------------------------------------------------
# general best practice make flags - see http://clarkgrubb.com/makefile-style-guide
# -------------------------------------------------
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
.SHELLFLAGS := -e -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

# -------------------------------------------------
# build variables
# -------------------------------------------------

APP_VERSION := 0.1.0
APPLICATION := couchbase-backup

image := $(APPLICATION)
tag := v$(APP_VERSION)
push_registry := registry.localdomain:443

work_dir := ${HOME}/${image}.work
build_dir := ${work_dir}/build
deploy_dir := ${work_dir}/deploy

# -------------------------------------------------
# kubernetes variables
# -------------------------------------------------

couchbase_username                          := admin
couchbase_password                          := password

os_auth_url                                 :=
os_username                                 :=
os_password                                 :=
os_tenant_name                              :=
os_region                                   := RegionOne

# -------------------------------------------------
# MAKE all
# -------------------------------------------------

.PHONY: all
all:
	@echo "Cloud Makefile"
	@echo ""
	@echo "Possible Targets:"
	@less Makefile | grep .PHONY[:] | cut -f2 -d ' ' | xargs -n1 -r echo " - "

# -------------------------------------------------
# MAKE build targets
# -------------------------------------------------

installdirs:
	@mkdir -p ${build_dir}
	@mkdir -p ${deploy_dir}

.PHONY: build
build: installdirs
	@cp -ar ./build/. ${build_dir}
	@echo "finished build to ${build_dir}"

.PHONY: check
check:
	@[ -f ${build_dir}/.dockerignore ] && echo ".dockerignore exists" || (echo ".dockerignore doesnt exist" && false)
	@[ -f ${build_dir}/Dockerfile ] && echo "Dockerfile exists" || (echo "Dockerfile doesnt exist" && false)
	@echo "finished check"

.PHONY: distcheck
distcheck:
	@curl -ks --fail https://${push_registry}/v2/${image}/tags/list | grep -vo "${tag}" || \
	    (echo "${push_registry}/${image}:${tag} already exists in repository" && false)
	@echo "finished dist check"

.PHONY: dist
dist: check distcheck
	@docker build -t ${push_registry}/${image}:${tag} ${build_dir}
	@docker tag ${push_registry}/${image}:${tag} ${push_registry}/${image}:latest
	@docker push ${push_registry}/${image}:${tag}
	@docker push ${push_registry}/${image}:latest
	@echo "created dist ${push_registry}/${image}:${tag} and latest"

# -------------------------------------------------
# MAKE generate targets
# -------------------------------------------------

.PHONY: secrets
secrets: secrets_swift secrets_couchbase

.PHONY: secrets_swift
secrets_swift: installdirs
	@./make-scripts/generate_swift_secrets.sh -w=${deploy_dir} \
	    --os-auth-url=${os_auth_url} \
	    --os-username=${os_username} \
	    --os-password=${os_password} \
	    --os-tenant-name=${os_tenant_name} \
	    --os-region=${os_region} \
	    --os-container=${os_container}
	@echo "finished generating openstack swift secrets manifest"

.PHONY: secrets_couchbase
secrets_couchbase: installdirs
	@./make-scripts/generate_couchbase_secrets.sh -w=${deploy_dir} \
	    -u=${couchbase_username} \
	    -p=${couchbase_password}
	@echo "finished generating secrets manifest"

# -------------------------------------------------
# MAKE deploy targets
# -------------------------------------------------

.PHONY: deploy
deploy: deploy_namespaces deploy_secrets  deploy_application
	@echo "finished deployment"

.PHONY: deploy_namespaces
deploy_namespaces:
	@kubectl apply -f ./deploy/namespaces --record
	@echo "finished namespaces deployment"

.PHONY: deploy_secrets
deploy_secrets: secrets
	@-kubectl create -f ${deploy_dir}/ngwsa-couchbase-secrets.yaml  --namespace ngwsa-performance
	@-kubectl create -f ${deploy_dir}/swift-secrets.yaml            --namespace ngwsa-performance

	@-kubectl create -f ${deploy_dir}/ngwsa-couchbase-secrets.yaml  --namespace ngwsa-content
	@-kubectl create -f ${deploy_dir}/swift-secrets.yaml            --namespace ngwsa-content

	@-kubectl create -f ${deploy_dir}/ngwsa-couchbase-secrets.yaml  --namespace ngwsa-stage
	@-kubectl create -f ${deploy_dir}/swift-secrets.yaml            --namespace ngwsa-stage

	@-kubectl create -f ${deploy_dir}/ngwsa-couchbase-secrets.yaml  --namespace ngwsa-production
	@-kubectl create -f ${deploy_dir}/swift-secrets.yaml            --namespace ngwsa-production
	@echo "finished secrets deployment"

.PHONY: deploy_application
deploy_application:
	@kubectl apply -f ./deploy/application -R --record
	@echo "finished application deployment"

# -------------------------------------------------
# MAKE main targets
# -------------------------------------------------

.PHONY: install
install: mostlyclean build dist deploy

.PHONY: uninstall_warning
uninstall_warning:
	@echo "-------------------------------------------------"
	@kubectl config get-contexts | grep "*"
	@echo "-------------------------------------------------"
	@while [ -z "$$CONTINUE" ]; do \
		read -r -p "WARNING: Do you want to uninstall from the current selected context? [y/n]: " CONTINUE; \
	done ; \
	[ $$CONTINUE = "y" ] || [ $$CONTINUE = "Y" ] || (echo "Aborted deployment (don't mind the error)."; exit 1;)

.PHONY: uninstall
uninstall: uninstall_warning clean deployclean

	@echo "finished uninstall"

.PHONY: mostlyclean
mostlyclean:
	@rm -rf ${work_dir}
	@echo "finished mostly cleaning"

.PHONY: distclean
distclean:
	@-docker rmi ${push_registry}/${image}:latest
	@-docker rmi ${push_registry}/${image}:${tag}
	@echo "finished dist cleaning"

.PHONY: deployclean
deployclean:
	@kubectl delete -f ./deploy/application -R
	@echo "finished deploy cleaning"

.PHONY: clean
clean: mostlyclean distclean
	@echo "finished cleaning"