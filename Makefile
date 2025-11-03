PROJECT_NAME=addtwocicd
INFRA_DIR=infra

.PHONY: install test lint aws_spinup aws_spindown run docker-build docker-run

install:
	uv sync --group dev --all-extras

test:
	PYTHONPATH=. uv run pytest -q -vv

test_github:
	gh run view

lint:
	uv run ruff check . --fix

aws_spinup:
	@echo "🚀 Spinning up AWS infrastructure..."
	@echo ""
	@echo "⚠️  Checking AWS credentials..."
	@aws sts get-caller-identity >/dev/null 2>&1 || (echo ""; echo "❌ AWS credentials not configured!"; echo ""; echo "Please configure AWS credentials first:"; echo "   1. Run: aws configure"; echo "   2. Or set: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY"; echo "   3. Or login with: aws sso login (if using SSO)"; echo ""; exit 1)
	terraform -chdir=$(INFRA_DIR) init -upgrade
	@echo ""
	@echo "📋 Getting GitHub repository info..."
	@GITHUB_REPO=$$(git remote get-url origin 2>/dev/null | sed -E 's/.*[:/]([^/]+)\/([^/]+)(\.git)?$$/\1\/\2/' | sed 's/\.git$$//' || echo ""); \
	if [ -z "$$GITHUB_REPO" ]; then \
		echo "⚠️  Could not detect GitHub repo from git remote. Please provide github_org and github_repo manually:"; \
		echo "   terraform -chdir=$(INFRA_DIR) apply -var 'github_org=YOUR_ORG' -var 'github_repo=YOUR_REPO'"; \
		exit 1; \
	fi; \
	GITHUB_ORG=$$(echo $$GITHUB_REPO | cut -d'/' -f1); \
	GITHUB_REPO_NAME=$$(echo $$GITHUB_REPO | cut -d'/' -f2); \
	echo "   Detected: $$GITHUB_REPO"; \
	echo ""; \
	echo "🔨 Running terraform apply..."; \
	if terraform -chdir=$(INFRA_DIR) apply -auto-approve -var "github_org=$$GITHUB_ORG" -var "github_repo=$$GITHUB_REPO_NAME"; then \
		echo ""; \
		echo "✅ Infrastructure deployed successfully!"; \
		echo ""; \
		echo "📝 GitHub Secrets Setup Required:"; \
		echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
		ROLE_ARN=$$(terraform -chdir=$(INFRA_DIR) output -raw github_oidc_role_arn 2>/dev/null); \
		AWS_REGION=$$(terraform -chdir=$(INFRA_DIR) output -raw aws_region 2>/dev/null || echo "us-east-1"); \
		if [ -n "$$ROLE_ARN" ] && [ "$$ROLE_ARN" != "" ]; then \
			echo ""; \
			echo "1️⃣  Go to: https://github.com/$$GITHUB_REPO/settings/secrets/actions"; \
			echo ""; \
			echo "2️⃣  Add these two secrets:"; \
			echo ""; \
			echo "   Secret 1:"; \
			echo "   Name:  AWS_ROLE_TO_ASSUME"; \
			echo "   Value: $$ROLE_ARN"; \
			echo ""; \
			echo "   Secret 2:"; \
			echo "   Name:  AWS_REGION"; \
			echo "   Value: $$AWS_REGION"; \
			echo ""; \
			echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"; \
			echo ""; \
			echo "💡 After adding secrets, push to main branch to trigger deployment!"; \
		else \
			echo ""; \
			echo "⚠️  Could not retrieve role ARN. Check terraform output manually:"; \
			echo "   terraform -chdir=$(INFRA_DIR) output github_oidc_role_arn"; \
		fi; \
	else \
		echo ""; \
		echo "❌ Terraform apply failed! Check the error messages above."; \
		echo ""; \
		echo "Common issues:"; \
		echo "  • AWS credentials expired or invalid"; \
		echo "  • Insufficient AWS permissions"; \
		echo "  • Network connectivity issues"; \
		exit 1; \
	fi

aws_spindown:
	terraform -chdir=$(INFRA_DIR) destroy -auto-approve

run:
	PYTHONPATH=. uv run uvicorn src.app.main:app --host 0.0.0.0 --port 8000 --reload

docker-build:
	docker build -t $(PROJECT_NAME):latest .

docker-run:
	docker run --rm -p 8000:8000 $(PROJECT_NAME):latest


