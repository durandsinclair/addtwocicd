PROJECT_NAME=addtwocicd
INFRA_DIR=infra

.PHONY: install test lint aws_spinup aws_spindown run docker-build docker-run

install:
	uv sync --group dev --all-extras

test:
	PYTHONPATH=. uv run pytest -q -vv

lint:
	uv run ruff check . --fix

aws_spinup:
	terraform -chdir=$(INFRA_DIR) init -upgrade
	terraform -chdir=$(INFRA_DIR) apply -auto-approve

aws_spindown:
	terraform -chdir=$(INFRA_DIR) destroy -auto-approve

run:
	PYTHONPATH=. uv run uvicorn src.app.main:app --host 0.0.0.0 --port 8000 --reload

docker-build:
	docker build -t $(PROJECT_NAME):latest .

docker-run:
	docker run --rm -p 8000:8000 $(PROJECT_NAME):latest


