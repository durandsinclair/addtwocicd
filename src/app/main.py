import logging
import os

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel


class AddRequest(BaseModel):
    a: float
    b: float


def configure_logging() -> None:
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)

    for handler in list(logger.handlers):
        logger.removeHandler(handler)

    # Determine environment: local (file) vs AWS (stdout)
    running_in_aws = any(
        os.getenv(name)
        for name in (
            "ECS_CONTAINER_METADATA_URI",
            "ECS_CONTAINER_METADATA_URI_V4",
            "AWS_EXECUTION_ENV",
            "APP_RUNNER_SERVICE_ARN",
        )
    )

    if running_in_aws:
        handler: logging.Handler = logging.StreamHandler()
    else:
        os.makedirs("logs", exist_ok=True)
        handler = logging.FileHandler("logs/app.log")

    formatter = logging.Formatter(
        fmt="%(asctime)s %(levelname)s %(name)s - %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S%z",
    )
    handler.setFormatter(formatter)
    logger.addHandler(handler)


def add_numbers(a: float, b: float) -> float:
    return a + b


configure_logging()
app = FastAPI()


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/add")
def add(body: AddRequest) -> dict:
    try:
        result = add_numbers(body.a, body.b)
        logger = logging.getLogger(__name__)
        logger.info("add called with a=%s b=%s result=%s", body.a, body.b, result)
        return {"result": result}
    except Exception as exc:  # pragma: no cover
        raise HTTPException(status_code=400, detail=str(exc)) from exc


