import logging
import os
import time
from contextlib import asynccontextmanager
from typing import AsyncGenerator

import asyncpg
from fastapi import FastAPI, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = os.getenv('DATABASE_URL', f"postgresql://{os.getenv('DATABASE_USER')}:{os.getenv('DATABASE_PASSWORD')}@{os.getenv('DATABASE_HOST')}:{os.getenv('DATABASE_PORT')}/{os.getenv('DATABASE_NAME')}")

# SQLAlchemy async engine with NullPool (connection pooling via PgBouncer)
engine = create_async_engine(
    DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    poolclass=None,  # NullPool
    echo=False,
)

async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

@asynccontextmanager
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Application startup")
    yield
    logger.info("Application shutdown")
    await engine.dispose()

app = FastAPI(title="FastAPI High-Throughput App", lifespan=lifespan)

@app.get("/health/startup")
async def startup_health():
    return {"status": "ok", "message": "Startup health check passed"}

@app.get("/health/live")
async def liveness_health():
    return {"status": "ok", "message": "Liveness health check passed"}

@app.get("/health/ready")
async def readiness_health():
    return {"status": "ok", "message": "Readiness health check passed"}

@app.get("/")
async def root():
    # Simulate CPU-intensive processing instead of sleep
    import math
    result = 0
    for i in range(10000):  # CPU-intensive calculation
        result += math.sin(i) * math.cos(i)

    response_data = f"Response generated at {time.time()} with CPU work result: {result}"

    return {"message": "FastAPI High-Throughput Application", "cached": False, "data": response_data}

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str = None):
    async with get_db() as session:
        # Example async DB operation (placeholder)
        logger.info(f"Fetching item {item_id}")
        return {"item_id": item_id, "q": q, "message": "Item fetched asynchronously"}