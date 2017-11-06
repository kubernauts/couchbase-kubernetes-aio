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

PROXY_USERNAME                              ?= ungwprx
PROXY_PASSWORD                              ?= A3545255

aws_push_registry                           := 461453766186.dkr.ecr.eu-central-1.amazonaws.com
os_push_registry                            := registry.localdomain:443

ifeq ($(CLOUD_PROVIDER),aws)
$(info CLOUD_PROVIDER set to AWS)
cloud_provider                              := aws
cloud_proxy                                 :=
hosted_zone                                 := ngwskunkworks.de
else
$(info no CLOUD_PROVIDER set, using default OS)
cloud_provider                              := os
cloud_proxy                                 := http://${PROXY_USERNAME}:${PROXY_PASSWORD}@143.163.8.73:3128
hosted_zone                                 := ngwskunkworks.de
endif


# -------------------------------------------------
# build variables
# -------------------------------------------------

APP_VERSION := 0.1.29
APPLICATION := couchbase-install

image := $(APPLICATION)
tag := v$(APP_VERSION)

work_dir := ${HOME}/${image}.work
build_dir := ${work_dir}/build

# -------------------------------------------------
# MAKE all
# -------------------------------------------------

.PHONY: all
all:
	@echo "Cloud Makefile"
	@echo ""
	@echo "Possible Targets:"
	@less Makefile | grep .PHONY[:] | cut -f2 -d ' ' | xargs -n1 -r echo " - "

.PHONY: help
help: all

# -------------------------------------------------
# MAKE build targets
# -------------------------------------------------

installdirs:
	@mkdir -p ${build_dir}

.PHONY: build
build: installdirs
	@cp -ar ./build/. ${build_dir}
	@echo "finished build to ${build_dir}"

.PHONY: check
check:
	@[ -f ${build_dir}/.dockerignore ] && echo ".dockerignore exists" || (echo ".dockerignore doesnt exist" && false)
	@[ -f ${build_dir}/Dockerfile ] && echo "Dockerfile exists" || (echo "Dockerfile doesnt exist" && false)
	@echo "finished check"


.PHONY: dist
dist: check
	@docker build --no-cache -t ${image}:${tag} ${build_dir}


.PHONY: push
push: push_os push_aws

.PHONY: push_os
push_os:
	@docker tag ${image}:${tag} ${os_push_registry}/${image}:${tag}
	@docker tag ${image}:${tag} ${os_push_registry}/${image}:latest
	@docker push ${os_push_registry}/${image}:${tag}
	@docker push ${os_push_registry}/${image}:latest
	@echo "created dist ${os_push_registry}/${image}:${tag} and latest"

.PHONY: push_aws
push_aws:
	@$(shell aws ecr get-login --region eu-central-1)
	@docker tag ${image}:${tag} ${aws_push_registry}/${image}:${tag}
	@docker tag ${image}:${tag} ${aws_push_registry}/${image}:latest
	@docker push ${aws_push_registry}/${image}:${tag}
	@docker push ${aws_push_registry}/${image}:latest
	@echo "created dist ${aws_push_registry}/${image}:${tag} and latest"


# -------------------------------------------------
# MAKE main targets
# -------------------------------------------------

.PHONY: install
install: mostlyclean build dist push

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
uninstall: uninstall_warning clean
	@echo "finished uninstall"

.PHONY: mostlyclean
mostlyclean:
	@rm -rf ${work_dir}
	@echo "finished mostly cleaning"

.PHONY: distclean
distclean:
	@-docker rmi ${image}:latest
	@-docker rmi ${image}:${tag}
	@echo "finished dist cleaning"

.PHONY: clean
clean: mostlyclean distclean
	@echo "finished cleaning"