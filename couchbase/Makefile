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
# check for basic environment - NO indentation
# -------------------------------------------------

ifeq ($(BIN_FILE),)
bin := ""
else
bin := ${BIN_FILE}
$(info BIN_FILE set to ${bin}. Will reuse)
endif

ifeq ($(CLOUD_PROVIDER),aws)
$(info CLOUD_PROVIDER set to AWS)
cloud_provider                              := aws
else
$(info no CLOUD_PROVIDER set, using default OS)
cloud_provider                              := os
endif

# -------------------------------------------------
# build variables
# -------------------------------------------------

work_dir := ${HOME}/couchbase.work
build_dir := ${work_dir}/build
deploy_dir := ${work_dir}/deploy

# -------------------------------------------------
# kubernetes variables
# -------------------------------------------------

admin_username := admin
admin_password := password
read_username := user
read_password := password

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
	@mkdir -p ${deploy_dir}

# -------------------------------------------------
# MAKE generate targets
# -------------------------------------------------

.PHONY: secrets
secrets: secrets_couchbase

.PHONY: secrets_couchbase
secrets_couchbase: installdirs
	@./make-scripts/generate_secrets.sh -w=${deploy_dir} -u=${admin_username} -p=${admin_password} \
		--readonly-username=${read_username} --readonly-password=${read_password}
	@echo "finished generating secrets manifest"

.PHONY: certificates
certificates: installdirs
	@openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
		-keyout ${deploy_dir}/performance-tls.key -out ${deploy_dir}/performance-tls.crt -subj "/CN=performance.couchbase.ngwskunkworks.de"
	@openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
		-keyout ${deploy_dir}/content-tls.key -out ${deploy_dir}/content-tls.crt -subj "/CN=content.couchbase.ngwskunkworks.de"
	@openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
		-keyout ${deploy_dir}/stage-tls.key -out ${deploy_dir}/stage-tls.crt -subj "/CN=stage.couchbase.ngwskunkworks.de"
	@openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 \
		-keyout ${deploy_dir}/production-tls.key -out ${deploy_dir}/production-tls.crt -subj "/CN=prod.couchbase.ngwskunkworks.de"
	@echo "finished generating certificates"

# -------------------------------------------------
# MAKE deploy targets
# -------------------------------------------------

.PHONY: deploy
deploy: deploy_namespaces deploy_secrets deploy_certificates deploy_application
	@echo "finished deployment"

.PHONY: deploy_namespaces
deploy_namespaces:
	@kubectl apply -f ./deploy/${cloud_provider}/namespaces --record
	@echo "finished namespaces deployment"

.PHONY: deploy_secrets
deploy_secrets: secrets
	@-kubectl create -f ${deploy_dir}/couchbase-secrets.yaml       --namespace ngwsa-performance

	@-kubectl create -f ${deploy_dir}/couchbase-secrets.yaml       --namespace ngwsa-content

	@-kubectl create -f ${deploy_dir}/couchbase-secrets.yaml       --namespace ngwsa-stage

	@-kubectl create -f ${deploy_dir}/couchbase-secrets.yaml       --namespace ngwsa-production
	@echo "finished secrets deployment"

.PHONY: deploy_certificates
deploy_certificates: certificates
	@-kubectl create secret generic couchbase-performance-certs \
		--from-file=tls.crt=${deploy_dir}/performance-tls.crt \
		--from-file=tls.key=${deploy_dir}/performance-tls.key \
		--namespace ngwsa-performance

	@-kubectl create secret generic couchbase-content-certs \
		--from-file=tls.crt=${deploy_dir}/content-tls.crt \
		--from-file=tls.key=${deploy_dir}/content-tls.key \
		--namespace ngwsa-content

	@-kubectl create secret generic couchbase-stage-certs \
		--from-file=tls.crt=${deploy_dir}/stage-tls.crt \
		--from-file=tls.key=${deploy_dir}/stage-tls.key \
		--namespace ngwsa-stage

	@-kubectl create secret generic couchbase-production-certs \
		--from-file=tls.crt=${deploy_dir}/production-tls.crt \
		--from-file=tls.key=${deploy_dir}/production-tls.key \
		--namespace ngwsa-production
	@echo "finished certificates deployment"


.PHONY: deploy_application
deploy_application:
	@kubectl apply -f ./deploy/${cloud_provider}/application -R --record
	@echo "finished application deployment on ${cloud_provider}"

# -------------------------------------------------
# MAKE main targets
# -------------------------------------------------

.PHONY: install
install: mostlyclean deploy

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

.PHONY: deployclean
deployclean:
	@kubectl delete -f ./deploy/${cloud_provider}/application -R
	@kubectl delete secret couchbase-performance-certs      --namespace ngwsa-performance
	@kubectl delete secret couchbase-stage-certs            --namespace ngwsa-stage
	@kubectl delete secret couchbase-content-certs          --namespace ngwsa-content
	@kubectl delete secret couchbase-production-certs       --namespace ngwsa-production
	@echo "finished deploy cleaning"

.PHONY: clean
clean: mostlyclean
	@echo "finished cleaning"