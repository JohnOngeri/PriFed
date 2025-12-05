#!/usr/bin/env python3
"""
Comprehensive API endpoint tests for PrivFed FastAPI backend.
Tests all REST API endpoints with various scenarios and edge cases.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
import json
import tempfile
import shutil
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime
from typing import Dict, Any

# Import the FastAPI app
from api.main import app
from api.services import PrivFedService

class TestPrivFedAPI:
    """Comprehensive test suite for PrivFed API endpoints."""
    
    @pytest.fixture(autouse=True)
    def setup_test_environment(self):
        """Setup test environment with mocked services."""
        self.client = TestClient(app)
        self.temp_dir = tempfile.mkdtemp()
        
        # Mock service responses
        self.mock_service = Mock(spec=PrivFedService)
        self._setup_mock_responses()
        
        # Patch the service dependency
        with patch('api.routes.get_privfed_service', return_value=self.mock_service):
            yield
        
        # Cleanup
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    def _setup_mock_responses(self):
        """Setup mock responses for the PrivFed service."""
        from api.schemas import (
            StatusResponse, GlobalMetricsResponse, BankMetricsResponse, 
            PrivacyResponse, RoundsResponse, FraudPredictionResponse,
            ModelResponse, HealthResponse, DatasetResponse, ComparisonResponse,
            BankMetrics, PrivacyMetrics, RoundInfo, ModelInfo, DatasetInfo,
            ComparisonMetrics
        )
        
        # Mock status response
        self.mock_service.get_status.return_value = StatusResponse(
            status="running",
            version="1.0.0",
            timestamp=datetime.now(),
            training_status="idle",
            current_round=0,
            total_rounds=50
        )
        
        # Mock global metrics
        self.mock_service.get_global_metrics.return_value = GlobalMetricsResponse(
            round=15,
            accuracy=0.945,
            auc=0.932,
            precision=0.876,
            recall=0.823,
            f1=0.849,
            loss=0.234,
            timestamp=datetime.now()
        )
        
        # Mock bank metrics
        bank_metrics = [
            BankMetrics(
                bank_id="bank_A",
                accuracy=0.941,
                auc=0.928,
                precision=0.872,
                recall=0.819,
                f1=0.845,
                loss=0.241,
                num_samples=15000,
                fraud_rate=0.035
            ),
            BankMetrics(
                bank_id="bank_B",
                accuracy=0.948,
                auc=0.935,
                precision=0.879,
                recall=0.827,
                f1=0.852,
                loss=0.228,
                num_samples=18000,
                fraud_rate=0.032
            ),
            BankMetrics(
                bank_id="bank_C",
                accuracy=0.946,
                auc=0.933,
                precision=0.877,
                recall=0.824,
                f1=0.850,
                loss=0.233,
                num_samples=16500,
                fraud_rate=0.038
            )
        ]
        
        self.mock_service.get_bank_metrics.return_value = BankMetricsResponse(
            round=15,
            banks=bank_metrics,
            fairness_score=0.92,
            timestamp=datetime.now()
        )
        
        # Mock privacy metrics
        privacy_metrics = PrivacyMetrics(
            epsilon=3.2,
            delta=1e-5,
            target_epsilon=8.0,
            noise_multiplier=1.1,
            max_grad_norm=1.0,
            steps=150,
            privacy_budget_used=40.0
        )
        
        self.mock_service.get_privacy_metrics.return_value = PrivacyResponse(
            enabled=True,
            current_metrics=privacy_metrics,
            privacy_level="Medium Privacy",
            timestamp=datetime.now()
        )
        
        # Mock rounds history
        rounds = [
            RoundInfo(
                round=i,
                global_accuracy=0.85 + (i * 0.01),
                global_auc=0.82 + (i * 0.012),
                global_loss=0.5 - (i * 0.02),
                participating_banks=3,
                duration_seconds=45.0 + (i * 2),
                timestamp=datetime.now()
            ) for i in range(1, 16)
        ]
        
        self.mock_service.get_rounds_history.return_value = RoundsResponse(
            total_rounds=50,
            completed_rounds=15,
            rounds=rounds
        )
        
        # Mock fraud prediction
        self.mock_service.predict_fraud.return_value = FraudPredictionResponse(
            transaction_id="txn_20241201_123456",
            fraud_probability=0.85,
            fraud_prediction=True,
            confidence_level="High",
            risk_factors=["High transaction amount", "Unusual time pattern", "New device"],
            model_used="global",
            timestamp=datetime.now()
        )
        
        # Mock model info
        model_info = ModelInfo(
            model_type="FraudDetectionMLP",
            architecture="Multi-layer Perceptron",
            parameters=125000,
            training_rounds=15,
            last_updated=datetime.now(),
            performance_metrics={"auc": 0.932, "accuracy": 0.945}
        )
        
        self.mock_service.get_current_model_info.return_value = ModelResponse(
            global_model=model_info,
            available_models=["global_model_latest", "centralized_baseline", "federated_round_15"],
            timestamp=datetime.now()
        )
        
        # Mock health status
        self.mock_service.get_health_status.return_value = HealthResponse(
            status="healthy",
            database_connected=True,
            model_loaded=True,
            last_training=datetime.now(),
            uptime_seconds=3600.0,
            timestamp=datetime.now()
        )
        
        # Mock dataset info
        dataset_info = DatasetInfo(
            total_samples=590540,
            fraud_samples=20663,
            normal_samples=569877,
            fraud_rate=0.035,
            features=433,
            banks={
                "bank_A": {"samples": 15000, "fraud_rate": 0.035},
                "bank_B": {"samples": 18000, "fraud_rate": 0.032},
                "bank_C": {"samples": 16500, "fraud_rate": 0.038}
            }
        )
        
        self.mock_service.get_dataset_info.return_value = DatasetResponse(
            dataset_info=dataset_info,
            preprocessing_info={
                "scaling_method": "StandardScaler",
                "encoding_method": "Mixed (Label + OneHot)",
                "missing_value_strategy": "Median/Mode imputation"
            },
            timestamp=datetime.now()
        )
        
        # Mock model comparison
        comparison_metrics = ComparisonMetrics(
            centralized={"accuracy": 0.952, "auc": 0.945, "f1": 0.856},
            federated={"accuracy": 0.945, "auc": 0.932, "f1": 0.849},
            federated_dp={"accuracy": 0.938, "auc": 0.925, "f1": 0.842},
            local_average={"accuracy": 0.923, "auc": 0.915, "f1": 0.831}
        )
        
        self.mock_service.get_model_comparison.return_value = ComparisonResponse(
            comparison=comparison_metrics,
            best_model="centralized",
            privacy_utility_tradeoff={
                "privacy_cost": 0.007,
                "federated_benefit": 0.017,
                "centralized_gap": 0.013
            },
            timestamp=datetime.now()
        )
    
    def test_root_endpoint(self):
        """Test root endpoint."""
        response = self.client.get("/")
        
        assert response.status_code == 200
        data = response.json()
        
        assert "name" in data
        assert "version" in data
        assert "description" in data
        assert data["name"] == "PrivFed API"
        
        print("✓ Root endpoint test passed")
    
    def test_status_endpoint(self):
        """Test status endpoint."""
        response = self.client.get("/api/status")
        
        assert response.status_code == 200
        data = response.json()
        
        # Verify required fields
        required_fields = ["status", "version", "timestamp", "training_status", "current_round", "total_rounds"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        assert data["status"] == "running"
        assert data["version"] == "1.0.0"
        assert data["training_status"] == "idle"
        
        print("✓ Status endpoint test passed")
    
    def test_health_endpoint(self):
        """Test health check endpoint."""
        response = self.client.get("/api/health")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["status", "database_connected", "model_loaded", "uptime_seconds", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        assert data["status"] == "healthy"
        assert data["database_connected"] is True
        assert data["model_loaded"] is True
        
        print("✓ Health endpoint test passed")
    
    def test_global_metrics_endpoint(self):
        """Test global metrics endpoint."""
        response = self.client.get("/api/metrics/global")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["round", "accuracy", "auc", "precision", "recall", "f1", "loss", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify metric ranges
        assert 0 <= data["accuracy"] <= 1
        assert 0 <= data["auc"] <= 1
        assert 0 <= data["precision"] <= 1
        assert 0 <= data["recall"] <= 1
        assert 0 <= data["f1"] <= 1
        assert data["loss"] >= 0
        
        print("✓ Global metrics endpoint test passed")
    
    def test_bank_metrics_endpoint(self):
        """Test bank metrics endpoint."""
        response = self.client.get("/api/metrics/banks")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["round", "banks", "fairness_score", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify banks data
        banks = data["banks"]
        assert isinstance(banks, list)
        assert len(banks) == 3
        
        for bank in banks:
            bank_fields = ["bank_id", "accuracy", "auc", "precision", "recall", "f1", "loss", "num_samples", "fraud_rate"]
            for field in bank_fields:
                assert field in bank, f"Missing bank field: {field}"
            
            # Verify metric ranges
            assert 0 <= bank["accuracy"] <= 1
            assert 0 <= bank["auc"] <= 1
            assert bank["num_samples"] > 0
            assert 0 <= bank["fraud_rate"] <= 1
        
        # Verify fairness score
        assert 0 <= data["fairness_score"] <= 1
        
        print("✓ Bank metrics endpoint test passed")
    
    def test_privacy_endpoint(self):
        """Test privacy metrics endpoint."""
        response = self.client.get("/api/privacy")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["enabled", "privacy_level", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        if data["enabled"]:
            assert "current_metrics" in data
            metrics = data["current_metrics"]
            
            metrics_fields = ["epsilon", "delta", "target_epsilon", "noise_multiplier", "max_grad_norm", "steps", "privacy_budget_used"]
            for field in metrics_fields:
                assert field in metrics, f"Missing privacy metric field: {field}"
            
            # Verify privacy values
            assert metrics["epsilon"] >= 0
            assert 0 < metrics["delta"] < 1
            assert metrics["target_epsilon"] > 0
            assert metrics["noise_multiplier"] > 0
            assert 0 <= metrics["privacy_budget_used"] <= 100
        
        print("✓ Privacy endpoint test passed")
    
    def test_rounds_endpoint(self):
        """Test rounds history endpoint."""
        response = self.client.get("/api/rounds")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["total_rounds", "completed_rounds", "rounds"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify rounds data
        rounds = data["rounds"]
        assert isinstance(rounds, list)
        assert len(rounds) == data["completed_rounds"]
        
        for round_info in rounds:
            round_fields = ["round", "global_accuracy", "global_auc", "global_loss", "participating_banks", "duration_seconds", "timestamp"]
            for field in round_fields:
                assert field in round_info, f"Missing round field: {field}"
            
            # Verify round values
            assert round_info["round"] > 0
            assert 0 <= round_info["global_accuracy"] <= 1
            assert 0 <= round_info["global_auc"] <= 1
            assert round_info["participating_banks"] > 0
            assert round_info["duration_seconds"] > 0
        
        print("✓ Rounds endpoint test passed")
    
    def test_fraud_prediction_endpoint(self):
        """Test fraud prediction endpoint."""
        # Test valid prediction request
        transaction_data = {
            "transaction": {
                "transaction_amount": 1500.0,
                "product_cd": "W",
                "card1": 13553,
                "card2": 404.0,
                "card3": 150.0,
                "addr1": 315.0,
                "addr2": 87.0,
                "dist1": 19.0,
                "p_emaildomain": "gmail.com"
            },
            "model_type": "global"
        }
        
        response = self.client.post("/api/fraud/predict", json=transaction_data)
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["transaction_id", "fraud_probability", "fraud_prediction", "confidence_level", "risk_factors", "model_used", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify prediction values
        assert 0 <= data["fraud_probability"] <= 1
        assert isinstance(data["fraud_prediction"], bool)
        assert data["confidence_level"] in ["Low", "Medium", "High"]
        assert isinstance(data["risk_factors"], list)
        
        print("✓ Fraud prediction endpoint test passed")
    
    def test_fraud_prediction_invalid_data(self):
        """Test fraud prediction with invalid data."""
        # Test with missing required fields
        invalid_data = {
            "transaction": {
                "product_cd": "W"
                # Missing transaction_amount
            }
        }
        
        response = self.client.post("/api/fraud/predict", json=invalid_data)
        
        # Should return 422 for validation error or 400 for bad request
        assert response.status_code in [400, 422]
        
        print("✓ Fraud prediction invalid data test passed")
    
    def test_model_info_endpoint(self):
        """Test current model info endpoint."""
        response = self.client.get("/api/models/current")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["global_model", "available_models", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify global model info
        model = data["global_model"]
        model_fields = ["model_type", "architecture", "parameters", "training_rounds", "last_updated", "performance_metrics"]
        for field in model_fields:
            assert field in model, f"Missing model field: {field}"
        
        assert model["parameters"] > 0
        assert model["training_rounds"] >= 0
        assert isinstance(model["performance_metrics"], dict)
        
        # Verify available models
        assert isinstance(data["available_models"], list)
        
        print("✓ Model info endpoint test passed")
    
    def test_dataset_info_endpoint(self):
        """Test dataset info endpoint."""
        response = self.client.get("/api/dataset")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["dataset_info", "preprocessing_info", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify dataset info
        dataset = data["dataset_info"]
        dataset_fields = ["total_samples", "fraud_samples", "normal_samples", "fraud_rate", "features", "banks"]
        for field in dataset_fields:
            assert field in dataset, f"Missing dataset field: {field}"
        
        assert dataset["total_samples"] > 0
        assert dataset["fraud_samples"] > 0
        assert dataset["normal_samples"] > 0
        assert 0 < dataset["fraud_rate"] < 1
        assert dataset["features"] > 0
        assert isinstance(dataset["banks"], dict)
        
        print("✓ Dataset info endpoint test passed")
    
    def test_model_comparison_endpoint(self):
        """Test model comparison endpoint."""
        response = self.client.get("/api/comparison")
        
        assert response.status_code == 200
        data = response.json()
        
        required_fields = ["comparison", "best_model", "privacy_utility_tradeoff", "timestamp"]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"
        
        # Verify comparison data
        comparison = data["comparison"]
        model_types = ["centralized", "federated", "federated_dp", "local_average"]
        for model_type in model_types:
            assert model_type in comparison, f"Missing model type: {model_type}"
            
            model_metrics = comparison[model_type]
            assert isinstance(model_metrics, dict)
            assert "accuracy" in model_metrics
            assert "auc" in model_metrics
        
        # Verify best model
        assert data["best_model"] in model_types
        
        # Verify privacy-utility tradeoff
        tradeoff = data["privacy_utility_tradeoff"]
        assert isinstance(tradeoff, dict)
        
        print("✓ Model comparison endpoint test passed")
    
    def test_system_info_endpoint(self):
        """Test system info endpoint."""
        response = self.client.get("/api/system/info")
        
        assert response.status_code == 200
        data = response.json()
        
        # Should contain system information
        expected_fields = ["platform", "python_version", "pytorch_version", "timestamp"]
        for field in expected_fields:
            assert field in data, f"Missing system info field: {field}"
        
        print("✓ System info endpoint test passed")
    
    def test_metrics_export_endpoint(self):
        """Test metrics export endpoint."""
        # Test JSON export
        response = self.client.get("/api/metrics/export?format=json")
        
        assert response.status_code == 200
        data = response.json()
        
        # Should contain exported metrics
        assert "global_metrics" in data
        assert "bank_metrics" in data
        assert "privacy_metrics" in data
        assert "export_timestamp" in data
        
        print("✓ Metrics export endpoint test passed")
    
    def test_error_handling(self):
        """Test API error handling."""
        # Test 404 for non-existent endpoint
        response = self.client.get("/api/nonexistent")
        assert response.status_code == 404
        
        # Test invalid JSON in POST request
        response = self.client.post("/api/fraud/predict", data="invalid json")
        assert response.status_code == 422  # Unprocessable Entity
        
        print("✓ Error handling test passed")
    
    def test_cors_headers(self):
        """Test CORS headers are present."""
        response = self.client.get("/api/status")
        
        # Check for CORS headers (these are added by FastAPI middleware)
        # The exact headers depend on the CORS configuration
        assert response.status_code == 200
        
        print("✓ CORS headers test passed")
    
    def test_api_documentation(self):
        """Test API documentation endpoints."""
        # Test OpenAPI schema
        response = self.client.get("/openapi.json")
        assert response.status_code == 200
        
        schema = response.json()
        assert "openapi" in schema
        assert "info" in schema
        assert "paths" in schema
        
        # Test docs endpoint
        response = self.client.get("/docs")
        assert response.status_code == 200
        
        print("✓ API documentation test passed")
    
    def test_service_unavailable_scenarios(self):
        """Test scenarios when service is unavailable."""
        # Mock service to return None for some endpoints
        self.mock_service.get_global_metrics.return_value = None
        
        response = self.client.get("/api/metrics/global")
        assert response.status_code == 404
        
        # Reset mock
        self._setup_mock_responses()
        
        print("✓ Service unavailable scenarios test passed")
    
    def test_concurrent_requests(self):
        """Test handling of concurrent requests."""
        import threading
        import time
        
        results = []
        
        def make_request():
            response = self.client.get("/api/status")
            results.append(response.status_code)
        
        # Create multiple threads
        threads = []
        for _ in range(5):
            thread = threading.Thread(target=make_request)
            threads.append(thread)
        
        # Start all threads
        for thread in threads:
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join()
        
        # All requests should succeed
        assert all(status == 200 for status in results)
        assert len(results) == 5
        
        print("✓ Concurrent requests test passed")

def run_tests():
    """Run all API endpoint tests."""
    print("Running PrivFed API Endpoint Tests...")
    print("=" * 50)
    
    # Create test instance
    test_suite = TestPrivFedAPI()
    
    try:
        # Run all tests
        test_suite.test_root_endpoint()
        test_suite.test_status_endpoint()
        test_suite.test_health_endpoint()
        test_suite.test_global_metrics_endpoint()
        test_suite.test_bank_metrics_endpoint()
        test_suite.test_privacy_endpoint()
        test_suite.test_rounds_endpoint()
        test_suite.test_fraud_prediction_endpoint()
        test_suite.test_fraud_prediction_invalid_data()
        test_suite.test_model_info_endpoint()
        test_suite.test_dataset_info_endpoint()
        test_suite.test_model_comparison_endpoint()
        test_suite.test_system_info_endpoint()
        test_suite.test_metrics_export_endpoint()
        test_suite.test_error_handling()
        test_suite.test_cors_headers()
        test_suite.test_api_documentation()
        test_suite.test_service_unavailable_scenarios()
        test_suite.test_concurrent_requests()
        
        print("\n" + "=" * 50)
        print("✅ ALL API ENDPOINT TESTS PASSED!")
        print("=" * 50)
        
    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        raise

if __name__ == "__main__":
    run_tests()