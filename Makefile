# Detect OS and set DOCKER command appropriately:
OS := $(shell uname -s)
ifeq ($(OS), Darwin)
	DOCKER := docker
else
	DOCKER := sudo docker
endif

APP_NAME ?= clf-poe
APP_VERSION := $(shell grep "version:" bundles/$(APP_NAME)/appbundle.yml | head -n 1 | awk '{print $$2}')

.PHONY: docker package appbundle clean

all: docker package appbundle

docker:
	$(DOCKER) build --no-cache -t $(APP_NAME):$(APP_VERSION) .

package: docker
	$(DOCKER) save $(APP_NAME):$(APP_VERSION) | gzip > $(APP_NAME)-$(APP_VERSION).tar.gz

appbundle:
	@echo "Removing old $(APP_NAME).tar.gz and dist/ folder..."
	@rm -f $(APP_NAME)-$(APP_VERSION).tar.gz
	@rm -rf dist
	@echo "Creating temporary folder dist/$(APP_NAME)..."
	@mkdir -p dist/$(APP_NAME)
	@echo "Copying roles/ and actions/..."
	@cp -r bundles/${APP_NAME}/roles dist/$(APP_NAME)/
	@cp -r bundles/${APP_NAME}/actions dist/$(APP_NAME)/
	@cp bundles/${APP_NAME}/appbundle.yml dist/$(APP_NAME)/
	@cp bundles/${APP_NAME}/ansible.cfg dist/$(APP_NAME)/ansible.cfg
	@echo "Building Docker image via existing docker target..."
	@$(MAKE) docker
	@echo "Saving Docker image tar..."
	@$(DOCKER) save $(APP_NAME):$(APP_VERSION) | gzip > dist/docker-image.tar.gz
	@mkdir -p dist/$(APP_NAME)/images
	@mv dist/docker-image.tar.gz dist/$(APP_NAME)/images/$(APP_NAME).tar.gz
	@echo "Creating final tarball $(APP_NAME)-$(APP_VERSION).tar.gz..."
	@cd dist/${APP_NAME} && find . -type f -name '*.tgz' -o -name '*.tar.gz' -o -name '*.yml' -o -name 'ansible.cfg' | tar czf ../$(APP_NAME)-$(APP_VERSION).tar.gz -T -
	@echo "Appbundle created at dist/$(APP_NAME)-$(APP_VERSION).tar.gz"

clean:
	rm -f $(APP_NAME) $(APP_NAME)-$(APP_VERSION).tar.gz
	rm -rf dist