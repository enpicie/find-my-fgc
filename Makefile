.PHONY: dev down build logs backend-dev backend-dev-clean frontend-dev

# --- Full stack (Docker) ---

dev: ## Build and run the full stack (backend + frontend)
	docker compose up --build

down: ## Tear down all containers
	docker compose down

build: ## Build images without starting
	docker compose build

logs: ## Follow logs from all services
	docker compose logs -f

# --- Individual service dev ---

backend-dev: ## Build and run backend (uses layer + BuildKit cache for incremental rebuilds)
	docker compose --progress=plain up --force-recreate --build backend

backend-dev-clean: ## Full backend rebuild from scratch (bypasses all caches)
	docker compose --progress=plain build --no-cache backend

frontend-dev: ## Run frontend Vite dev server with hot reload
	npm run dev --prefix frontend || npm run dev
