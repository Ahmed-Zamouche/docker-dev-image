IMG_VER:=1.0.0
IMG_NAME:=ahmedz/debian-base:${IMG_VER}

USER:=developer

CONT_NAME:=devcontainer

WORKSPACE:=$(shell pwd)/workspace

ifeq ($(NO_CACHE),1)
 _NO_CACHE:=--no-cache
else
 _NO_CACHE:=
endif

CMD?=bash

.PHONY:build
build:
	docker build ${_NO_CACHE} \
		--build-arg DISPLAY=${DISPLAY} \
		-t '${IMG_NAME}' .

.PHONY:run
run:
	docker run -ti \
		--name ${CONT_NAME} \
		--privileged \
		--detach \
		-v "${WORKSPACE}:/home/${USER}/workspace" \
		-v /tmp/.X11-unix:/tmp/.X11-unix \
		'${IMG_NAME}' \
		/bin/bash
	docker ps --quiet --filter "name=${CONT_NAME}" > container.id

.PHONY:exec
exec:
	docker exec -it $(shell cat container.id) ${CMD}

.PHONY:start
start:
	docker start  $(shell cat container.id)

.PHONY:attach
attach:
	docker attach $(shell cat container.id)

.PHONY:stop
stop:
	docker container stop $(shell cat container.id)

.PHONY:remove
remove:
	docker container rm $(shell cat container.id)

.PHONY:clean
clean:
	docker rmi --force `docker images --quiet --filter "dangling=true"`

