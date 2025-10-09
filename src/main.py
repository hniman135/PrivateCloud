import logging
import os
import time
from contextlib import asynccontextmanager
from typing import AsyncGenerator, List

import asyncpg
from fastapi import FastAPI, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import Column, Integer, String, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.future import select
from pydantic import BaseModel
from prometheus_fastapi_instrumentator import Instrumentator

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# SQLAlchemy Base
Base = declarative_base()

# Database Models
class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), index=True)
    email = Column(String(100), unique=True, index=True)
    created_at = Column(String(50))

# Pydantic Schemas
class UserCreate(BaseModel):
    name: str
    email: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    created_at: str = None
    
    class Config:
        from_attributes = True

# Database configuration
DATABASE_URL = os.getenv('DATABASE_URL', f"postgresql://{os.getenv('DATABASE_USER')}:{os.getenv('DATABASE_PASSWORD')}@{os.getenv('DATABASE_HOST')}:{os.getenv('DATABASE_PORT')}/{os.getenv('DATABASE_NAME')}")

# SQLAlchemy async engine with proper connection pooling
engine = create_async_engine(
    DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://"),
    pool_size=20,           # Number of persistent connections
    max_overflow=10,        # Additional connections when pool is full
    pool_pre_ping=True,     # Verify connections before using
    pool_recycle=3600,      # Recycle connections after 1 hour
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
    
    # Create database tables on startup
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables created/verified")
        
        # Add sample data if table is empty
        async with get_db() as session:
            result = await session.execute(select(User))
            if not result.scalars().first():
                logger.info("Adding sample users...")
                sample_users = [
                    User(name="Alice Smith", email="alice@example.com", created_at=time.strftime("%Y-%m-%d %H:%M:%S")),
                    User(name="Bob Johnson", email="bob@example.com", created_at=time.strftime("%Y-%m-%d %H:%M:%S")),
                    User(name="Charlie Brown", email="charlie@example.com", created_at=time.strftime("%Y-%m-%d %H:%M:%S")),
                    User(name="Diana Prince", email="diana@example.com", created_at=time.strftime("%Y-%m-%d %H:%M:%S")),
                    User(name="Eve Wilson", email="eve@example.com", created_at=time.strftime("%Y-%m-%d %H:%M:%S")),
                ]
                session.add_all(sample_users)
                await session.commit()
                logger.info("Sample users added successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
    
    yield
    
    logger.info("Application shutdown")
    await engine.dispose()

app = FastAPI(title="FastAPI High-Throughput App", lifespan=lifespan)

# Initialize Prometheus metrics
Instrumentator().instrument(app).expose(app)

@app.get("/health/startup")
async def startup_health():
    return {"status": "ok", "message": "Startup health check passed"}

@app.get("/health/live")
async def liveness_health():
    return {"status": "ok", "message": "Liveness health check passed"}

@app.get("/health/ready")
async def readiness_health():
    """
    Readiness probe - checks if app can handle traffic.
    Includes database connectivity check.
    """
    try:
        # Test database connection
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return {"status": "ok", "message": "Readiness health check passed", "database": "connected"}
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise HTTPException(status_code=503, detail=f"Database unavailable: {str(e)}")

@app.get("/")
async def root():
    """
    Root endpoint - optimized for high throughput.
    Returns static response for maximum performance.
    """
    return {
        "message": "FastAPI High-Throughput Application",
        "status": "running",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health/live",
            "ready": "/health/ready",
            "startup": "/health/startup",
            "users": "/users/",
            "user_by_id": "/users/{id}",
            "items": "/items/{item_id}",
            "metrics": "/metrics",
            "docs": "/docs"
        }
    }

@app.get("/items/{item_id}")
async def read_item(item_id: int, q: str = None):
    async with get_db() as session:
        # Example async DB operation (placeholder)
        logger.info(f"Fetching item {item_id}")
        return {"item_id": item_id, "q": q, "message": "Item fetched asynchronously"}

# ===== USER ENDPOINTS =====

@app.get("/users/", response_model=List[UserResponse])
async def get_users(skip: int = 0, limit: int = 100):
    """
    Get list of users from database.
    
    - **skip**: Number of records to skip (pagination)
    - **limit**: Maximum number of records to return
    """
    try:
        async with get_db() as session:
            result = await session.execute(
                select(User).offset(skip).limit(limit)
            )
            users = result.scalars().all()
            return [
                UserResponse(
                    id=u.id, 
                    name=u.name, 
                    email=u.email,
                    created_at=u.created_at or "N/A"
                ) 
                for u in users
            ]
    except Exception as e:
        logger.error(f"Error fetching users: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.get("/users/{user_id}", response_model=UserResponse)
async def get_user(user_id: int):
    """
    Get a specific user by ID.
    """
    try:
        async with get_db() as session:
            result = await session.execute(
                select(User).where(User.id == user_id)
            )
            user = result.scalar_one_or_none()
            
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            return UserResponse(
                id=user.id,
                name=user.name,
                email=user.email,
                created_at=user.created_at or "N/A"
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.post("/users/", response_model=UserResponse, status_code=201)
async def create_user(user: UserCreate):
    """
    Create a new user.
    
    - **name**: User's full name
    - **email**: User's email (must be unique)
    """
    try:
        async with get_db() as session:
            # Check if email already exists
            result = await session.execute(
                select(User).where(User.email == user.email)
            )
            if result.scalar_one_or_none():
                raise HTTPException(status_code=400, detail="Email already registered")
            
            # Create new user
            new_user = User(
                name=user.name,
                email=user.email,
                created_at=time.strftime("%Y-%m-%d %H:%M:%S")
            )
            session.add(new_user)
            await session.commit()
            await session.refresh(new_user)
            
            logger.info(f"Created user: {new_user.name} ({new_user.email})")
            
            return UserResponse(
                id=new_user.id,
                name=new_user.name,
                email=new_user.email,
                created_at=new_user.created_at
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating user: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

@app.delete("/users/{user_id}", status_code=204)
async def delete_user(user_id: int):
    """
    Delete a user by ID.
    """
    try:
        async with get_db() as session:
            result = await session.execute(
                select(User).where(User.id == user_id)
            )
            user = result.scalar_one_or_none()
            
            if not user:
                raise HTTPException(status_code=404, detail="User not found")
            
            await session.delete(user)
            await session.commit()
            logger.info(f"Deleted user: {user.name} (ID: {user_id})")
            
            return None
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")