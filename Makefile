.DEFAULT_GOAL := up
## GENERAL ##

export PROJET_FOLDER= one
export U_ID := $(shell id -u)

update-composer:
	cd user && ./all-composer-update.sh ${PROJET_FOLDER}

update-all:
	cd user && ./update-all.sh

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

testbf:
	@#export $$(cat application/.env | xargs)
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} ./bin/console cache:clear
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer csf
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer behatbf

tools:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec ${PROJET_FOLDER} composer test

up:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml up

down:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml down

restart:
	cd user && ./restart.sh

install:
	./user/setup_dev_env.sh

log:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml logs -f ${PROJET_FOLDER}
	#tail -f ${PROJET_FOLDER}/framework/var/log/dev.log || true


log-traefik:
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml logs -f traefik

ssh:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec php bash

container-ssh:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml run --rm --entrypoint "bash -c" ${PROJET_FOLDER} bash

ssh-user:
	docker compose -f ${PROJET_FOLDER}/docker-compose.yml exec user bash

ps:
	@docker compose -f ${PROJET_FOLDER}/docker-compose.yml ps

build:
	@#docker builder prune
	docker build --build-arg UID=${U_ID} -t learn:php746 docker/php746
	docker build --build-arg UID=${U_ID} -t learn:nginx docker/nginx

docker-kill:
	@make down
	@docker rm -f $$(docker ps -a -q) || true
	@docker volume prune -f
	@docker network prune -f

help:
	@printf "\033[31m%-16s %-59s %s\033[0m\n" "Target" "Help" "Usage"; \
	printf "\033[31m%-16s %-59s %s\033[0m\n" "------" "----" "-----"; \
	grep -hE '^\S+:.## .$$' $(MAKEFILE_LIST) | sed -e 's/:.##\s/:/' | sort | awk 'BEGIN {FS = ":"}; {printf "\033[32m%-16s\033[0m %-58s \033[34m%s\033[0m\n", $$1, $$2, $$3}'