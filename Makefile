# Variables
IMAGE_NAME = cloud-design-image
AWS_DIR = $(HOME)/.aws
WORKSPACE_DIR = $(shell pwd)
DIR ?= .  # <--- Defaults to current directory if not specified

.PHONY: all build run clean docker  destroy apply init plan

all: docker build run  

# Build the Docker image
build:
	@echo "Building Docker image $(IMAGE_NAME)..."
	docker build -t $(IMAGE_NAME) .

# Run the container with mounted volumes for AWS config and workspace
run:
	@echo "Launching $(IMAGE_NAME) workspace..."
	@mkdir -p $(AWS_DIR)
	docker run -it --rm \
		--net=host \
		-v "$(AWS_DIR):/root/.aws" \
		-v "$(WORKSPACE_DIR):/workspace" \
		$(IMAGE_NAME)
		
# install docker rootless
docker: 
	@echo "Installing Docker..."
	bash scripts/install_docker_rootless.sh

# Clean up the Docker image if you want to rebuild fresh later
clean:
	@echo "Removing Docker image $(IMAGE_NAME)..."
	docker rmi $(IMAGE_NAME)

# Updated Terraform targets using -chdir
destroy:
	@terraform -chdir=$(DIR) destroy -auto-approve

apply:
	@terraform -chdir=$(DIR) apply -auto-approve

init:
	@terraform -chdir=$(DIR) init

plan:
	@terraform -chdir=$(DIR) plan
