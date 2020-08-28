#
# Copyright (c) 2020, Arm Limited. All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause
#

# Makefile rules to help creating docker images based on a fvp model tarballs

# allow user to possible define other dir for model tarballs
TGZ_DIR ?= .

# directory for docker build work
WORKSPACE ?= workspace

# find all tarballs located at TGZ_DIR
tgzs=$(shell ls $(TGZ_DIR)/F*.tgz 2>/dev/null)

define create-docker-image
# tag varible is used so uniquely identify a model
# and it is used to workspace directory and docker tag
	tag=$(shell ./create-model-tag.sh $@) && \
	tarball=$(shell basename $@) && \
	rm -rf $(WORKSPACE)/$${tag} && \
	mkdir -p $(WORKSPACE)/$${tag} && \
	cp $@ $(WORKSPACE)/$${tag} && \
	./create-model-dockerfile.sh $${tarball} $(WORKSPACE)/$${tag} && \
	docker build --tag fvp:$${tag} $(WORKSPACE)/$${tag} > /dev/null && \
	echo "Docker image created" && \
	echo "Docker image name: (fvp:$${tag})" && \
	echo "Docker Model files:" && \
	echo "$$(docker run fvp:$${tag} ls)" && \
	echo "Dockerfile: $(WORKSPACE)/$${tag}/Dockerfile"
endef

ifeq ($(tgzs),)
all:
	@echo No model tarballs found && exit 0
else
all: $(tgzs)
$(tgzs):
	$(create-docker-image)
endif

clean:
	rm -rf $(WORKSPACE)

.PHONY: $(tgzs)
