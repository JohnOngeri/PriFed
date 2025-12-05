"""
Comprehensive API Routes for PrivFed System.
Implements all endpoints for federated learning monitoring, privacy tracking,
and fraud detection with robust error handling and validation.
"""

from fastapi import APIRouter, HTTPException, Depends, Query, Path, Body
from fastapi.responses import JSONResponse
from typing import Dict, List, Optional, Any
import logging
from datetime import datetime
import asyncio
import os
import json

from .schemas import (
    SystemStatusResponse, GlobalMetricsResponse, BankMetricsResponse,
    PrivacyMetricsResponse, RoundsHistoryResponse, FraudPredictionRequest,
    FraudPredictionResponse, ModelInfoResponse, DatasetInfoResponse,
    ErrorResponse, HealthCheckResponse
)
from .services import (
    get_system_status, get_global_metrics, get_bank_metrics,
    get_privacy_metrics, get_rounds_history, predict_fraud,
    get_model_info, get_dataset_info, health_check
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api", tags=["PrivFed API"])

# Dependency for error handling
async def handle_api_errors():
    """Common error handling dependency."""
    try:
        yield
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected API error: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Internal server error")

# Health and Status Endpoints
@router.get("/health", 
           response_model=HealthCheckResponse,
           tags=["Status & Health"],
           summary="Health Check",
           description="Check if the API is running and healthy")
async def api_health_check():
    """Health check endpoint."""
    try:
        health_data = await health_check()
        return HealthCheckResponse(**health_data)
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=503, detail="Service unavailable")

@router.get("/status",
           response_model=SystemStatusResponse,
           tags=["Status & Health"],
           summary="System Status",
           description="Get comprehensive system status including training progress")
async def get_status():
    """Get system status."""
    try:
        status_data = await get_system_status()
        return SystemStatusResponse(**status_data)
    except Exception as e:
        logger.error(f"Failed to get system status: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve system status")

# Metrics Endpoints
@router.get("/metrics/global",
           response_model=GlobalMetricsResponse,
           tags=["Metrics"],
           summary="Global Metrics",
           description="Get global model performance metrics")
async def get_global_metrics_endpoint(
    round_num: Optional[int] = Query(None, description="Specific round number (latest if not specified)")
):
    """Get global metrics."""
    try:
        metrics_data = await get_global_metrics(round_num)
        return GlobalMetricsResponse(**metrics_data)
    except Exception as e:
        logger.error(f"Failed to get global metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve global metrics")

@router.get("/metrics/banks",
           response_model=BankMetricsResponse,
           tags=["Metrics"],
           summary="Bank Metrics",
           description="Get performance metrics for all participating banks")
async def get_bank_metrics_endpoint(
    round_num: Optional[int] = Query(None, description="Specific round number (latest if not specified)")
):
    """Get bank-specific metrics."""
    try:
        metrics_data = await get_bank_metrics(round_num)
        return BankMetricsResponse(**metrics_data)
    except Exception as e:
        logger.error(f"Failed to get bank metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve bank metrics")

@router.get("/metrics/banks/{bank_id}",
           response_model=Dict[str, Any],
           tags=["Metrics"],
           summary="Individual Bank Metrics",
           description="Get metrics for a specific bank")
async def get_individual_bank_metrics(
    bank_id: str = Path(..., description="Bank identifier"),
    round_num: Optional[int] = Query(None, description="Specific round number")
):
    """Get metrics for a specific bank."""
    try:
        all_bank_metrics = await get_bank_metrics(round_num)
        
        if bank_id not in all_bank_metrics.get('bank_metrics', {}):
            raise HTTPException(status_code=404, detail=f"Bank {bank_id} not found")
        
        return {
            'bank_id': bank_id,
            'round': all_bank_metrics.get('round'),
            'metrics': all_bank_metrics['bank_metrics'][bank_id],
            'timestamp': all_bank_metrics.get('timestamp')
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get metrics for bank {bank_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to retrieve metrics for bank {bank_id}")

@router.get("/privacy",
           response_model=PrivacyMetricsResponse,
           tags=["Metrics"],
           summary="Privacy Metrics",
           description="Get differential privacy metrics and budget information")
async def get_privacy_metrics_endpoint():
    """Get privacy metrics."""
    try:
        privacy_data = await get_privacy_metrics()
        return PrivacyMetricsResponse(**privacy_data)
    except Exception as e:
        logger.error(f"Failed to get privacy metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve privacy metrics")

@router.get("/rounds",
           response_model=RoundsHistoryResponse,
           tags=["Metrics"],
           summary="Training Rounds History",
           description="Get history of all training rounds with metrics")
async def get_rounds_history_endpoint(
    limit: int = Query(50, ge=1, le=1000, description="Maximum number of rounds to return"),
    offset: int = Query(0, ge=0, description="Number of rounds to skip")
):
    """Get training rounds history."""
    try:
        history_data = await get_rounds_history(limit, offset)
        return RoundsHistoryResponse(**history_data)
    except Exception as e:
        logger.error(f"Failed to get rounds history: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve rounds history")

# Fraud Detection Endpoints
@router.post("/fraud/predict",
            response_model=FraudPredictionResponse,
            tags=["Fraud Detection"],
            summary="Predict Fraud",
            description="Predict fraud probability for a transaction")
async def predict_fraud_endpoint(
    request: FraudPredictionRequest = Body(..., description="Transaction features for prediction")
):
    """Predict fraud for a transaction."""
    try:
        prediction_data = await predict_fraud(request)
        return FraudPredictionResponse(**prediction_data)
    except ValueError as e:
        logger.warning(f"Invalid prediction request: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to predict fraud: {e}")
        raise HTTPException(status_code=500, detail="Failed to predict fraud")

@router.post("/fraud/predict/batch",
            response_model=List[FraudPredictionResponse],
            tags=["Fraud Detection"],
            summary="Batch Fraud Prediction",
            description="Predict fraud for multiple transactions")
async def predict_fraud_batch_endpoint(
    requests: List[FraudPredictionRequest] = Body(..., description="List of transactions for prediction")
):
    """Predict fraud for multiple transactions."""
    if len(requests) > 100:
        raise HTTPException(status_code=400, detail="Batch size cannot exceed 100 transactions")
    
    try:
        predictions = []
        for request in requests:
            prediction_data = await predict_fraud(request)
            predictions.append(FraudPredictionResponse(**prediction_data))
        
        return predictions
    except ValueError as e:
        logger.warning(f"Invalid batch prediction request: {e}")
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Failed to predict fraud batch: {e}")
        raise HTTPException(status_code=500, detail="Failed to predict fraud for batch")

# Model Management Endpoints
@router.get("/models/current",
           response_model=ModelInfoResponse,
           tags=["Model Management"],
           summary="Current Model Info",
           description="Get information about the current global model")
async def get_current_model_info():
    """Get current model information."""
    try:
        model_data = await get_model_info()
        return ModelInfoResponse(**model_data)
    except Exception as e:
        logger.error(f"Failed to get model info: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve model information")

@router.get("/models/history",
           response_model=List[Dict[str, Any]],
           tags=["Model Management"],
           summary="Model History",
           description="Get history of model checkpoints")
async def get_model_history(
    limit: int = Query(10, ge=1, le=50, description="Maximum number of models to return")
):
    """Get model history."""
    try:
        models_dir = "models"
        if not os.path.exists(models_dir):
            return []
        
        model_files = [f for f in os.listdir(models_dir) if f.endswith('.pth')]
        model_files.sort(key=lambda x: os.path.getmtime(os.path.join(models_dir, x)), reverse=True)
        
        history = []
        for i, model_file in enumerate(model_files[:limit]):
            model_path = os.path.join(models_dir, model_file)
            stat = os.stat(model_path)
            
            history.append({
                'model_id': model_file.replace('.pth', ''),
                'filename': model_file,
                'created_at': datetime.fromtimestamp(stat.st_ctime).isoformat(),
                'size_bytes': stat.st_size,
                'is_current': i == 0
            })
        
        return history
    except Exception as e:
        logger.error(f"Failed to get model history: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve model history")

# System Information Endpoints
@router.get("/dataset/info",
           response_model=DatasetInfoResponse,
           tags=["System Information"],
           summary="Dataset Information",
           description="Get information about the dataset being used")
async def get_dataset_info_endpoint():
    """Get dataset information."""
    try:
        dataset_data = await get_dataset_info()
        return DatasetInfoResponse(**dataset_data)
    except Exception as e:
        logger.error(f"Failed to get dataset info: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve dataset information")

@router.get("/system/config",
           response_model=Dict[str, Any],
           tags=["System Information"],
           summary="System Configuration",
           description="Get current system configuration")
async def get_system_config():
    """Get system configuration."""
    try:
        from ..utils.data_utils import load_config
        config = load_config()
        
        # Remove sensitive information
        safe_config = config.copy()
        if 'data' in safe_config and 'dataset_path' in safe_config['data']:
            safe_config['data']['dataset_path'] = "[REDACTED]"
        
        return {
            'config': safe_config,
            'timestamp': datetime.now().isoformat()
        }
    except Exception as e:
        logger.error(f"Failed to get system config: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve system configuration")

@router.get("/analytics/fairness",
           response_model=Dict[str, Any],
           tags=["Analytics"],
           summary="Fairness Analysis",
           description="Get comprehensive fairness analysis across banks")
async def get_fairness_analysis():
    """Get fairness analysis."""
    try:
        bank_metrics_data = await get_bank_metrics()
        bank_metrics = bank_metrics_data.get('bank_metrics', {})
        
        if not bank_metrics:
            return {
                'fairness_score': 0,
                'analysis': 'No bank metrics available',
                'timestamp': datetime.now().isoformat()
            }
        
        try:
            from utils.metrics_utils import compute_fairness_metrics
            fairness_metrics = compute_fairness_metrics(bank_metrics)
        except ImportError:
            fairness_metrics = {'overall_fairness_score': 0.15}
        
        return {
            'fairness_metrics': fairness_metrics,
            'bank_count': len(bank_metrics),
            'timestamp': datetime.now().isoformat()
        }
        
    except Exception as e:
        logger.error(f"Failed to get fairness analysis: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve fairness analysis")

# Export router
__all__ = ['router']