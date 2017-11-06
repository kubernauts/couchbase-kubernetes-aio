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

.PHONY: build
build:
	@$(MAKE) -C ./couchbase-install build
	@$(MAKE) -C ./couchbase-backup build
	@echo "finished build"

.PHONY: check
check:
	@$(MAKE) -C ./couchbase-install check
	@$(MAKE) -C ./couchbase-backup check
	@echo "finished check"

.PHONY: distcheck
distcheck:
	@-$(MAKE) -C ./couchbase-backup distcheck
	@echo "finished distcheck"

.PHONY: dist
dist:
	@$(MAKE) -C ./couchbase-install distcheck
	@$(MAKE) -C ./couchbase-backup distcheck
	@echo "created dist ${push_registry}"

# -------------------------------------------------
# MAKE deploy targets
# -------------------------------------------------

.PHONY: deploy
deploy:
	@$(MAKE) -C ./couchbase deploy
	@echo "finished deployment"


# -------------------------------------------------
# MAKE main targets
# -------------------------------------------------

.PHONY: install
install:
	@$(MAKE) -C ./couchbase-install install
	@$(MAKE) -C ./couchbase-backup install
	@$(MAKE) -C ./couchbase install
	@echo "finished installing"

.PHONY: uninstall
uninstall:
	@$(MAKE) -C ./couchbase-install uninstall
	@$(MAKE) -C ./couchbase-backup uninstall
	@$(MAKE) -C ./couchbase install
	@echo "finished uninstalling"

.PHONY: mostlyclean
mostlyclean:
	@$(MAKE) -C ./couchbase-install mostlyclean
	@$(MAKE) -C ./couchbase-backup mostlyclean
	@$(MAKE) -C ./couchbase mostlyclean
	@echo "finished mostly cleaning"

.PHONY: distclean
distclean:
	@$(MAKE) -C ./couchbase-install distclean
	@$(MAKE) -C ./couchbase-backup distclean
	@echo "finished dist cleaning"

.PHONY: deployclean
deployclean:
	@$(MAKE) -C ./couchbase deployclean
	@echo "finished deploy cleaning"

.PHONY: clean
clean: mostlyclean distclean
	@echo "finished cleaning"