"""
FastAPI main application for PrivFed fraud detection system.
Configures and runs the API server with all middleware and routes.
"""

from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from fastapi.openapi.docs import get_swagger_ui_html
from fastapi.openapi.utils import get_openapi
from fastapi.staticfiles import StaticFiles
import uvicorn
import logging
import time
from datetime import datetime
from contextlib import asynccontextmanager
import os
import sys

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from .routes import router
from .services import preload_benchmark_models
from .schemas import ErrorResponse
try:
    from utils.data_utils import load_config
except ImportError:
    def load_config():
        return {'api': {'host': '0.0.0.0', 'port': 8000, 'allow_origins': ['*'], 'allow_credentials': True, 'allow_methods': ['*'], 'allow_headers': ['*']}}

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/api.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# Load configuration
try:
    config = load_config()
    api_config = config.get('api', {})
except Exception as e:
    logger.error(f"Failed to load configuration: {e}")
    api_config = {
        'host': '0.0.0.0',
        'port': 8000,
        'allow_origins': ['*'],
        'allow_credentials': True,
        'allow_methods': ['*'],
        'allow_headers': ['*']
    }

@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Application lifespan manager.
    Handles startup and shutdown events.
    """
    # Startup
    logger.info("Starting PrivFed API server...")
    
    try:
        # Define absolute paths relative to this file
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        plots_path = os.path.join(base_dir, "results", "plots")

        # Create necessary directories
        os.makedirs(os.path.join(base_dir, "logs"), exist_ok=True)
        os.makedirs(plots_path, exist_ok=True)
        os.makedirs(os.path.join(base_dir, "models"), exist_ok=True)

        # [DEMO-CRITICAL] Preload all four benchmark models once (feature alignment + four-model Lab).
        # Avoids degraded status and slow first request; model_cache reused for /predict and /fraud/benchmark.
        try:
            await preload_benchmark_models()
        except Exception as e:
            logger.warning("Model preload failed (will load on first request): %s", e)
        
        logger.info("PrivFed API server started successfully")
        
    except Exception as e:
        logger.error("Failed to initialize PrivFed service: %s", e)
        raise
    
    yield
    
    # Shutdown
    logger.info("Shutting down PrivFed API server...")

# Create FastAPI application
app = FastAPI(
    title="PrivFed API",
    description="Privacy-Preserving Federated Learning for Fraud Detection",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=api_config.get('allow_origins', ['*']),
    allow_credentials=api_config.get('allow_credentials', True),
    allow_methods=api_config.get('allow_methods', ['*']),
    allow_headers=api_config.get('allow_headers', ['*']),
)

# Add trusted host middleware (optional, for production)
if os.getenv('ENVIRONMENT') == 'production':
    app.add_middleware(
        TrustedHostMiddleware,
        allowed_hosts=["localhost", "127.0.0.1", "*.privfed.com"]
    )

# Request logging middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all HTTP requests."""
    start_time = time.time()
    
    # Log request
    logger.info(f"Request: {request.method} {request.url}")
    
    # Process request
    response = await call_next(request)
    
    # Log response
    process_time = time.time() - start_time
    logger.info(f"Response: {response.status_code} - {process_time:.4f}s")
    
    # Add timing header
    response.headers["X-Process-Time"] = str(process_time)
    
    return response

# Error handling middleware
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Handle HTTP exceptions."""
    logger.warning(f"HTTP {exc.status_code}: {exc.detail}")
    
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": f"HTTP {exc.status_code}",
            "message": str(exc.detail),
            "timestamp": datetime.now().isoformat()
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions."""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal Server Error",
            "message": str(exc) if exc else "An unexpected error occurred",
            "details": {"type": type(exc).__name__},
            "timestamp": datetime.now().isoformat()
        }
    )

# Include API routes
app.include_router(router)

# Mount static files so they are reachable via URL /api/plots/
app.mount("/api/plots", StaticFiles(directory=plots_path), name="plots")

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "name": "PrivFed API",
        "version": "1.0.0",
        "description": "Privacy-Preserving Federated Learning for Fraud Detection",
        "docs": "/docs",
        "health": "/api/health",
        "timestamp": datetime.now().isoformat()
    }

# Custom OpenAPI schema
def custom_openapi():
    """Generate custom OpenAPI schema."""
    if app.openapi_schema:
        return app.openapi_schema
    
    openapi_schema = get_openapi(
        title="PrivFed API",
        version="1.0.0",
        description="""
        ## Privacy-Preserving Federated Learning for Fraud Detection
        
        This API provides endpoints for a federated learning system that enables multiple banks 
        to collaboratively train fraud detection models while preserving data privacy through 
        differential privacy techniques.
        
        ### Key Features:
        - **Federated Learning**: Train models across multiple banks without sharing raw data
        - **Differential Privacy**: Strong privacy guarantees with configurable privacy budgets
        - **Real-time Fraud Detection**: Predict fraud probability for new transactions
        - **Fairness Analysis**: Monitor and ensure fairness across different client banks
        - **Comprehensive Metrics**: Track training progress, privacy consumption, and model performance
        
        ### API Sections:
        - **Status & Health**: Monitor system status and health
        - **Metrics**: Access training metrics, privacy metrics, and fairness analysis
        - **Fraud Detection**: Predict fraud for new transactions
        - **Model Management**: Information about trained models
        - **System Information**: Dataset info, model comparisons, and system details
        """,
        routes=app.routes,
    )
    
    # Add custom tags
    openapi_schema["tags"] = [
        {
            "name": "Status & Health",
            "description": "System status and health monitoring endpoints"
        },
        {
            "name": "Metrics",
            "description": "Training metrics, privacy metrics, and performance analysis"
        },
        {
            "name": "Fraud Detection",
            "description": "Fraud prediction and risk assessment"
        },
        {
            "name": "Model Management",
            "description": "Model information and management"
        },
        {
            "name": "System Information",
            "description": "Dataset information and system details"
        }
    ]
    
    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi

# Custom documentation
@app.get("/docs", include_in_schema=False)
async def custom_swagger_ui_html():
    """Custom Swagger UI with enhanced styling."""
    return get_swagger_ui_html(
        openapi_url=app.openapi_url,
        title=f"{app.title} - Interactive Documentation",
        swagger_js_url="https://cdn.jsdelivr.net/npm/swagger-ui-dist@4.15.5/swagger-ui-bundle.js",
        swagger_css_url="https://cdn.jsdelivr.net/npm/swagger-ui-dist@4.15.5/swagger-ui.css",
        swagger_ui_parameters={
            "deepLinking": True,
            "displayRequestDuration": True,
            "docExpansion": "none",
            "operationsSorter": "method",
            "filter": True,
            "tryItOutEnabled": True
        }
    )

# Development server configuration
def run_dev_server():
    """Run development server."""
    uvicorn.run(
        "api.main:app",
        host=api_config.get('host', '0.0.0.0'),
        port=api_config.get('port', 8000),
        reload=api_config.get('reload', True),
        log_level="info",
        access_log=True
    )

# Production server configuration
def run_prod_server():
    """Run production server."""
    uvicorn.run(
        "api.main:app",
        host=api_config.get('host', '0.0.0.0'),
        port=api_config.get('port', 8000),
        reload=False,
        log_level="warning",
        access_log=False,
        workers=4
    )

if __name__ == "__main__":
    # Check environment
    environment = os.getenv('ENVIRONMENT', 'development')
    
    if environment == 'production':
        logger.info("Starting PrivFed API in production mode")
        run_prod_server()
    else:
        logger.info("Starting PrivFed API in development mode")
        run_dev_server()