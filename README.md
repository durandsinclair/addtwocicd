# addtwocicd

FastAPI service that adds two numbers. CI/CD with Docker, Terraform (AWS App Runner), and GitHub Actions. Uses uv for Python package management.

## Local development

- Install deps:

```bash
make install
```

- Run tests and lint:

```bash
make test
make lint
```

- Start API locally:

```bash
make run
```

API will be at `http://localhost:8000`. Try:

```bash
curl -X POST localhost:8000/add -H 'content-type: application/json' -d '{"a":2, "b":3}'
```

- Logs: local logs written to `logs/app.log` (ignored by git).

## Docker

```bash
make docker-build
make docker-run
```

## CI/CD (GitHub Actions)

- Lint, test, secret scanning run on every push/PR.
- On `main`, image is built and pushed to ECR and Terraform applies infra changes.
- Secret scan uses gitleaks and a defensive grep for AWS keys.

## AWS deployment (Terraform + App Runner)

Prereqs:
- An AWS account and credentials with permissions to create ECR, IAM, App Runner.
- OIDC role for GitHub Actions is created by Terraform.

Deploy:

```bash
make aws_spinup
```

Destroy:

```bash
make aws_spindown
```

Outputs will include the App Runner service URL.

### GitHub OIDC role
After `make aws_spinup`, copy the `github_oidc_role_arn` output into a repo secret `AWS_ROLE_TO_ASSUME`. Set `AWS_REGION` secret to match your region.

## Configuration

Terraform variables:
- `github_org` and `github_repo` are auto-filled in CI on deploy. Locally, pass via `-var` flags or a `terraform.tfvars`.

## Security
- `.gitignore` excludes `logs/`, `.env`, and Terraform state.
- CI fails if AWS key patterns are detected.
