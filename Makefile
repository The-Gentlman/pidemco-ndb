up:
	docker compose up -d

down:
	docker compose down

exec-app:
	docker compose exec app sh

exec-db:
	docker compose exec db sh


backup:
	@bash backup.sh

restore:
	@bash restore.sh
