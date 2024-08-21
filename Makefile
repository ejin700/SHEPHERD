# Typical usages of make for this project are listed below. 
# 
# Environment management: 
#   make install-env        : install the development environment used by this project 
#   make install-env-clean  : perform clean install of development environment used by this project (delete old env first) 
#   make lock-env           : update conda lock environment files 
# 
# Software development (testing and linting): 
#   make                : run all linters rules (including suggestions) and all tests 
#   make ci             : run most checks required for completing pull requests 
#   make ci-lint        : run all linter rules required for completing pull requests 
#   make lint           : run all linter rules (including suggestions) 
#   make test           : run all tests and generate coverage report 
# 
# Secrets management: 
#   make secrets        : Generate secrets files in the .secrets directory 
# 
# Docker management: 
#   make aml-env        : locally build the Docker image, push it to the Azure Container Registry, 
#                         and create an Azure Machine Learning (AML) environment from the image 
#   make docker-run     : locally build the docker image and then run it interactively 
#   make docker-build   : locally build the docker image for the annotation pipeline 
ENV_MGMT_DIR := ../.envmgmt
MICROMAMBA_VERSION := 1.5.7-0
INSTALL_ENV_ARGS := -v $(MICROMAMBA_VERSION) -p ../.micromamba
UPDATE_CONDA_LOCK_ARGS :=
DOCKER_IMG := shepherd-main
DOCKER_TAG := $(shell date -u '+%Y-%m-%d')
FULL_DOCKER_IMG := $(DOCKER_IMG):$(DOCKER_TAG)
DOCKER_BUILD_CONTEXT := .docker
########################## 
# Environment management # 
########################## 
.PHONY: install-env
install-env:
	@$(ENV_MGMT_DIR)/install-env.sh $(INSTALL_ENV_ARGS)
.PHONY: install-env-clean
install-env-clean:
	@$(ENV_MGMT_DIR)/install-env.sh -R $(INSTALL_ENV_ARGS)
# Lock environment files.
.PHONY: lock-env
lock-env:
	@$(ENV_MGMT_DIR)/update-conda-lock.sh $(UPDATE_CONDA_LOCK_ARGS)
# Lock environment files, but return an error code if they are not up-to-date.
.PHONY: check-lock-env
check-lock-env:
	@$(ENV_MGMT_DIR)/update-conda-lock.sh -E $(UPDATE_CONDA_LOCK_ARGS)

######################
# Secrets management #
######################
.PHONY: secrets
secrets:
	@./generate_secrets.sh

#####################
# Docker management #
#####################
# # Build the docker image, push it to the ACR, and create an AML environment from the image.
# .PHONY: aml-env
# aml-env: docker-build
#   @./resources/create_aml_env.sh $(FULL_DOCKER_IMG)
# Run docker image interactively.
# Add back in -e "SECRETS_DIR=/work/.secrets" if needed.
.PHONY: docker-run
docker-run: docker-build
	docker run --rm -it -u nobody -w /work --mount type=bind,src=$$(pwd),target=/work $(FULL_DOCKER_IMG) /bin/bash
# Build the docker image.
.PHONY: docker-build
docker-build: docker-build-context
	docker build -t $(FULL_DOCKER_IMG) $(DOCKER_BUILD_CONTEXT)
# Delete old build context to ensure a clean build and then copy the necessary files to the build context.
.PHONY: docker-build-context
docker-build-context:
	@rm -rf $(DOCKER_BUILD_CONTEXT)
	@mkdir $(DOCKER_BUILD_CONTEXT)
	@cp Dockerfile $(DOCKER_BUILD_CONTEXT)
	@cp install_pyg.sh $(DOCKER_BUILD_CONTEXT)
	@cp environment.yml $(DOCKER_BUILD_CONTEXT)