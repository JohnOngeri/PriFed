"""
Pydantic schemas for PrivFed API.
Defines request and response models with comprehensive validation.
"""

from pydantic import BaseModel, Field, validator
from typing import Dict, List, Optional, Any, Union
from datetime import datetime
from enum import Enum

class PrivacyStrength(str, Enum):
    """Privacy strength levels."""
    VERY_STRONG = "Very Strong"
    STRONG = "Strong"
    MODERATE = "Moderate"
    WEAK = "Weak"
    VERY_WEAK = "Very Weak"

class TrainingStatus(str, Enum):
    """Training status options."""
    NOT_STARTED = "not_started"
    RUNNING = "running"
    PAUSED = "paused"
    COMPLETED = "completed"
    FAILED = "failed"

class FairnessLevel(str, Enum):
    """Fairness assessment levels."""
    EXCELLENT = "Excellent"
    GOOD = "Good"
    FAIR = "Fair"
    POOR = "Poor"

# Base response model
class BaseResponse(BaseModel):
    """Base response model with common fields."""
    timestamp: datetime = Field(default_factory=datetime.now)
    success: bool = Field(default=True)

# Error response
class ErrorResponse(BaseModel):
    """Error response model."""
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional error details")
    timestamp: datetime = Field(default_factory=datetime.now)

# Health check
class HealthCheckResponse(BaseResponse):
    """Health check response."""
    status: str = Field(..., description="Service status")
    version: str = Field(..., description="API version")
    uptime_seconds: float = Field(..., description="Service uptime in seconds")

# System status
class SystemStatusResponse(BaseResponse):
    """System status response."""
    training_status: TrainingStatus = Field(..., description="Current training status")
    current_round: int = Field(..., description="Current training round")
    total_rounds: int = Field(..., description="Total planned rounds")
    participating_banks: int = Field(..., description="Number of participating banks")
    privacy_enabled: bool = Field(..., description="Whether differential privacy is enabled")
    last_update: datetime = Field(..., description="Last system update timestamp")

# Metrics models
class ClassificationMetrics(BaseModel):
    """Classification metrics model."""
    accuracy: float = Field(..., ge=0, le=1, description="Accuracy score")
    precision: float = Field(..., ge=0, le=1, description="Precision score")
    recall: float = Field(..., ge=0, le=1, description="Recall score")
    f1: float = Field(..., ge=0, le=1, description="F1 score")
    auc: float = Field(..., ge=0, le=1, description="AUC-ROC score")
    specificity: Optional[float] = Field(None, ge=0, le=1, description="Specificity score")
    
    @validator('*', pre=True)
    def validate_metrics(cls, v):
        """Ensure metrics are valid numbers."""
        if isinstance(v, (int, float)):
            return max(0.0, min(1.0, float(v)))
        return v

class GlobalMetricsResponse(BaseResponse):
    """Global metrics response."""
    round: int = Field(..., description="Training round number")
    metrics: ClassificationMetrics = Field(..., description="Global model metrics")
    loss: Optional[float] = Field(None, description="Training loss")
    convergence_rate: Optional[float] = Field(None, description="Convergence rate")

class BankMetrics(ClassificationMetrics):
    """Bank-specific metrics."""
    bank_id: str = Field(..., description="Bank identifier")
    samples_count: int = Field(..., ge=0, description="Number of training samples")
    fraud_rate: float = Field(..., ge=0, le=1, description="Fraud rate in bank's data")

class BankMetricsResponse(BaseResponse):
    """Bank metrics response."""
    round: int = Field(..., description="Training round number")
    bank_metrics: Dict[str, BankMetrics] = Field(..., description="Metrics for each bank")
    fairness_score: Optional[float] = Field(None, description="Overall fairness score")

# Privacy metrics
class PrivacyMetrics(BaseModel):
    """Privacy metrics model."""
    current_epsilon: float = Field(..., ge=0, description="Current privacy budget (epsilon)")
    target_epsilon: float = Field(..., ge=0, description="Target privacy budget")
    delta: float = Field(..., ge=0, le=1, description="Privacy parameter delta")
    noise_multiplier: float = Field(..., ge=0, description="Noise multiplier for DP-SGD")
    privacy_strength: PrivacyStrength = Field(..., description="Privacy strength assessment")
    budget_used_percentage: float = Field(..., ge=0, le=100, description="Percentage of privacy budget used")

class PrivacyMetricsResponse(BaseResponse):
    """Privacy metrics response."""
    privacy_metrics: PrivacyMetrics = Field(..., description="Current privacy metrics")
    privacy_guarantee: str = Field(..., description="Privacy guarantee status")
    recommendations: List[str] = Field(default_factory=list, description="Privacy recommendations")

# Training rounds
class RoundMetrics(BaseModel):
    """Single round metrics."""
    round: int = Field(..., description="Round number")
    global_metrics: ClassificationMetrics = Field(..., description="Global metrics for this round")
    bank_metrics: Dict[str, BankMetrics] = Field(..., description="Bank metrics for this round")
    privacy_metrics: Optional[PrivacyMetrics] = Field(None, description="Privacy metrics for this round")
    duration_seconds: Optional[float] = Field(None, description="Round duration in seconds")
    timestamp: datetime = Field(..., description="Round completion timestamp")

class RoundsHistoryResponse(BaseResponse):
    """Rounds history response."""
    rounds: List[RoundMetrics] = Field(..., description="List of round metrics")
    total_rounds: int = Field(..., description="Total number of rounds")
    has_more: bool = Field(..., description="Whether more rounds are available")

# Fraud prediction
class FraudPredictionRequest(BaseModel):
    """Fraud prediction request with Model Router support for thesis-grade routing."""
    transaction_features: Dict[str, Union[float, int, str]] = Field(
        ..., 
        description="Transaction features for prediction",
        example={
            "TransactionAmt": 100.50,
            "ProductCD": "W",
            "card1": 13553,
            "card2": 150.0,
            "card3": 150.0,
            "addr1": 315.0,
            "addr2": 87.0,
            "dist1": 19.0,
            "P_emaildomain": "gmail.com",
            "R_emaildomain": "gmail.com"
        }
    )
    bank_id: Optional[str] = Field(
        None, 
        description="Bank identifier (Bank_A, Bank_B, Bank_C). Used for fairness routing: Bank_C gets specialist model."
    )
    high_privacy_mode: Optional[bool] = Field(
        False, 
        description="If True, use Differential Privacy model (Config 4) for privacy-sensitive predictions."
    )
    
    @validator('transaction_features')
    def validate_features(cls, v):
        """Validate transaction features."""
        if not v:
            raise ValueError("Transaction features cannot be empty")
        return v

class FraudPredictionResponse(BaseResponse):
    """Fraud prediction response."""
    fraud_probability: float = Field(..., ge=0, le=1, description="Probability of fraud")
    is_fraud: bool = Field(..., description="Binary fraud prediction")
    confidence: float = Field(..., ge=0, le=1, description="Prediction confidence")
    risk_level: str = Field(..., description="Risk level (Low, Medium, High)")
    explanation: Optional[Dict[str, Any]] = Field(None, description="Prediction explanation")

# Model information
class ModelArchitecture(BaseModel):
    """Model architecture information."""
    type: str = Field(..., description="Model architecture type")
    input_dim: int = Field(..., description="Input dimension")
    hidden_layers: List[int] = Field(..., description="Hidden layer sizes")
    output_dim: int = Field(..., description="Output dimension")
    total_parameters: int = Field(..., description="Total number of parameters")

class ModelInfoResponse(BaseResponse):
    """Model information response."""
    model_id: str = Field(..., description="Model identifier")
    architecture: ModelArchitecture = Field(..., description="Model architecture")
    training_round: int = Field(..., description="Training round when model was created")
    performance: ClassificationMetrics = Field(..., description="Model performance metrics")
    created_at: datetime = Field(..., description="Model creation timestamp")
    size_bytes: int = Field(..., description="Model size in bytes")

# Dataset information
class DatasetStats(BaseModel):
    """Dataset statistics."""
    total_samples: int = Field(..., description="Total number of samples")
    fraud_samples: int = Field(..., description="Number of fraud samples")
    safe_samples: int = Field(..., description="Number of safe samples")
    fraud_rate: float = Field(..., ge=0, le=1, description="Overall fraud rate")
    features_count: int = Field(..., description="Number of features")

class BankDataStats(BaseModel):
    """Bank-specific data statistics."""
    bank_id: str = Field(..., description="Bank identifier")
    samples: int = Field(..., description="Number of samples")
    fraud_rate: float = Field(..., ge=0, le=1, description="Fraud rate")
    features: int = Field(..., description="Number of features")

class DatasetInfoResponse(BaseResponse):
    """Dataset information response."""
    dataset_name: str = Field(..., description="Dataset name")
    dataset_stats: DatasetStats = Field(..., description="Overall dataset statistics")
    bank_stats: List[BankDataStats] = Field(..., description="Per-bank statistics")
    partitioning_strategy: str = Field(..., description="Data partitioning strategy used")
    preprocessing_info: Dict[str, Any] = Field(..., description="Preprocessing information")

# Fairness analysis
class FairnessMetrics(BaseModel):
    """Fairness metrics model."""
    auc_variance: float = Field(..., description="Variance in AUC across banks")
    auc_range: float = Field(..., description="Range of AUC values across banks")
    demographic_parity: float = Field(..., description="Demographic parity measure")
    equalized_odds: float = Field(..., description="Equalized odds measure")
    overall_fairness_score: float = Field(..., description="Overall fairness score")
    fairness_level: FairnessLevel = Field(..., description="Fairness assessment level")

class FairnessAnalysisResponse(BaseResponse):
    """Fairness analysis response."""
    fairness_metrics: FairnessMetrics = Field(..., description="Fairness metrics")
    bank_count: int = Field(..., description="Number of banks analyzed")
    recommendations: List[str] = Field(default_factory=list, description="Fairness recommendations")

# Privacy-utility analysis
class PrivacyUtilityMetrics(BaseModel):
    """Privacy-utility tradeoff metrics."""
    epsilon: float = Field(..., description="Privacy parameter epsilon")
    utility_loss: float = Field(..., description="Utility loss compared to baseline")
    utility_loss_percentage: float = Field(..., description="Utility loss as percentage")
    privacy_strength: PrivacyStrength = Field(..., description="Privacy strength level")
    tradeoff_score: float = Field(..., description="Privacy-utility tradeoff score")

class PrivacyUtilityResponse(BaseResponse):
    """Privacy-utility analysis response."""
    baseline_metrics: ClassificationMetrics = Field(..., description="Baseline metrics without privacy")
    private_metrics: ClassificationMetrics = Field(..., description="Metrics with differential privacy")
    privacy_utility_metrics: PrivacyUtilityMetrics = Field(..., description="Privacy-utility analysis")
    recommendations: List[str] = Field(default_factory=list, description="Optimization recommendations")

# Training control
class TrainingConfig(BaseModel):
    """Training configuration."""
    num_rounds: Optional[int] = Field(None, ge=1, le=1000, description="Number of training rounds")
    local_epochs: Optional[int] = Field(None, ge=1, le=100, description="Local epochs per round")
    learning_rate: Optional[float] = Field(None, gt=0, le=1, description="Learning rate")
    batch_size: Optional[int] = Field(None, ge=1, le=10000, description="Batch size")
    privacy_enabled: Optional[bool] = Field(None, description="Enable differential privacy")
    target_epsilon: Optional[float] = Field(None, gt=0, description="Target privacy budget")

class TrainingControlRequest(BaseModel):
    """Training control request."""
    action: str = Field(..., description="Training action (start, stop, pause, resume)")
    config_override: Optional[TrainingConfig] = Field(None, description="Configuration overrides")

class TrainingControlResponse(BaseResponse):
    """Training control response."""
    action: str = Field(..., description="Action performed")
    status: TrainingStatus = Field(..., description="New training status")
    message: str = Field(..., description="Status message")

# Export all schemas
__all__ = [
    'BaseResponse', 'ErrorResponse', 'HealthCheckResponse', 'SystemStatusResponse',
    'ClassificationMetrics', 'GlobalMetricsResponse', 'BankMetrics', 'BankMetricsResponse',
    'PrivacyMetrics', 'PrivacyMetricsResponse', 'RoundMetrics', 'RoundsHistoryResponse',
    'FraudPredictionRequest', 'FraudPredictionResponse', 'ModelArchitecture', 'ModelInfoResponse',
    'DatasetStats', 'BankDataStats', 'DatasetInfoResponse', 'FairnessMetrics', 'FairnessAnalysisResponse',
    'PrivacyUtilityMetrics', 'PrivacyUtilityResponse', 'TrainingConfig', 'TrainingControlRequest',
    'TrainingControlResponse', 'PrivacyStrength', 'TrainingStatus', 'FairnessLevel'
]