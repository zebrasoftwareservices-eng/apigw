.PHONY: validate deploy smoke backup logs status

validate:
	./scripts/validate.sh

deploy:
	./scripts/deploy.sh

smoke:
	./scripts/smoke.sh

backup:
	./scripts/backup.sh

logs:
	docker compose logs --tail=200 -f

status:
	docker compose ps
