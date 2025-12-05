#!/usr/bin/env python3
"""
Simple startup script for PrivFed API server.
Runs the backend without requiring trained models.
"""

import os
import sys
import logging
from pathlib import Path

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def setup_directories():
    """Create necessary directories if they don't exist."""
    directories = ['logs', 'results', 'models', 'data']
    for directory in directories:
        Path(directory).mkdir(exist_ok=True)
        print(f"Directory '{directory}' ready")

def setup_logging():
    """Setup basic logging configuration."""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

def main():
    """Main startup function."""
    print("Starting PrivFed API Server...")
    
    # Setup environment
    setup_directories()
    setup_logging()
    
    try:
        # Import and run the FastAPI app
        import uvicorn
        from api.main import app
        
        print("FastAPI app imported successfully")
        print("Starting server on http://localhost:8000")
        print("API Documentation: http://localhost:8000/docs")
        print("Health Check: http://localhost:8000/api/health")
        
        # Run the server
        uvicorn.run(
            "api.main:app",
            host="0.0.0.0",
            port=8000,
            reload=True,
            log_level="info"
        )
        
    except ImportError as e:
        print(f"Import error: {e}")
        print("Make sure all dependencies are installed: pip install -r requirements.txt")
        sys.exit(1)
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()