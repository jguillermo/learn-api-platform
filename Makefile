.DEFAULT_GOAL := up
## GENERAL ##

export PROJET_FOLDER= one
OS := $(shell uname)

ifeq ($(OS),Darwin)
	UID = $(shell id -u)
else ifeq ($(OS),Linux)
	UID = $(shell id -u)
else
	UID = 1000
endif


behat-custom:
	@docker-compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer behat features/Product/toggleStatus.feature
	@docker-compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer behat features/Product/list_product.feature

test-prepare:
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} ./bin/console cache:clear
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer csf
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} rm var/log/dev.log || true
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} bin/console messenger:setup-transports
	@make behat-custom || true
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} cat var/log/dev.log | grep -n --color ".CRITICAL" || true

test:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} ./bin/console cache:clear
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer csf
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer behat


up:
	docker network create learn-network || true
	U_ID=${UID} docker compose -f ${PROJET_FOLDER}/docker-compose.yml up

down:
	U_ID=${UID} docker compose -f ${PROJET_FOLDER}/docker-compose.yml down

log:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml logs -f ${PROJET_FOLDER}
	#tail -f ${PROJET_FOLDER}/framework/var/log/dev.log || true

ssh:
	U_ID=${UID} docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec --user ${UID} php bash

ps:
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml ps

build:
	@#docker builder prune
	docker build --build-arg UID=${UID} -t learn:php746 docker/php746
	docker build --build-arg UID=${UID} -t learn:nginx docker/nginx

docker-kill:
	@make down
	@docker rm -f $$(docker ps -a -q) || true
	@docker volume prune -f
	@docker network prune -f

help:
	@printf "\033[31m%-16s %-59s %s\033[0m\n" "Target" "Help" "Usage"; \
	printf "\033[31m%-16s %-59s %s\033[0m\n" "------" "----" "-----"; \
	grep -hE '^\S+:.## .$$' $(MAKEFILE_LIST) | sed -e 's/:.##\s/:/' | sort | awk 'BEGIN {FS = ":"}; {printf "\033[32m%-16s\033[0m %-58s \033[34m%s\033[0m\n", $$1, $$2, $$3}'