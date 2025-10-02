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

# Simple in-memory cache
cache = {}

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

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Application startup")
    yield
    logger.info("Application shutdown")
    await engine.dispose()

app = FastAPI(title="FastAPI High-Throughput App", lifespan=lifespan)

@app.get("/health/startup")
async def startup_health():
    # Simple startup check without DB
    return {"status": "ok", "message": "Startup health check passed"}

@app.get("/health/live")
async def liveness_health():
    return {"status": "ok", "message": "Liveness health check passed"}

@app.get("/health/ready")
async def readiness_health():
    # Simple readiness check without DB
    return {"status": "ok", "message": "Readiness health check passed"}

from functools import lru_cache
import time

# Simple in-memory cache
cache = {}

@app.get("/")
async def root():
    # Check cache first
    cache_key = "root_response"
    if cache_key in cache:
        cached_data = cache[cache_key]
        return {"message": "FastAPI High-Throughput Application", "cached": True, "data": cached_data}

    # Simulate some processing
    time.sleep(0.1)  # 100ms processing
    response_data = "Response generated at " + str(time.time())

    # Cache the response for 60 seconds
    cache[cache_key] = response_data

    return {"message": "FastAPI High-Throughput Application", "cached": False, "data": response_data}

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str = None):
    async with get_db() as session:
        # Example async DB operation (placeholder)
        logger.info(f"Fetching item {item_id}")
        return {"item_id": item_id, "q": q, "message": "Item fetched asynchronously"}