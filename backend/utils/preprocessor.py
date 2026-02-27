"""
Transaction preprocessor for API fraud prediction.

Loads scaler_params.json and transforms raw feature values into the normalized
format expected by the trained model. Supports RobustScaler (median/IQR) and
StandardScaler (mean/std) style parameters.
"""

import json
import os
import logging
from typing import List, Union, Dict, Any, Optional

logger = logging.getLogger(__name__)


class TransactionScaler:
    """
    Normalizes transaction features using stored scaler parameters.
    Compatible with RobustScaler (median/scale) and StandardScaler (mean/std).
    """

    def __init__(self, params_path: str = None):
        if params_path is None:
            # Default: backend/models/scaler_params.json
            base = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            params_path = os.path.join(base, 'models', 'scaler_params.json')

        self.params_path = params_path
        self.scaler_type = 'robust'
        self.medians = None
        self.scales = None
        self.means = None
        self.stds = None
        self.feature_count = None
        self.feature_order = None
        self._load_params()

    def _load_params(self) -> None:
        if not os.path.exists(self.params_path):
            raise FileNotFoundError(f"Scaler params not found: {self.params_path}")

        with open(self.params_path, 'r') as f:
            params = json.load(f)

        self.scaler_type = params.get('scaler_type', 'robust').lower()
        self.feature_count = params.get('feature_count', 0)
        self.feature_order = params.get('feature_order', [])

        if self.scaler_type == 'robust':
            self.medians = params.get('medians', [])
            self.scales = params.get('scales', [])
            if not self.scales:
                self.scales = [1.0] * len(self.medians)
            # Avoid division by zero
            self.scales = [s if abs(s) > 1e-9 else 1.0 for s in self.scales]
        else:
            self.means = params.get('means', [])
            self.stds = params.get('stds', [])
            if not self.stds:
                self.stds = [1.0] * len(self.means)
            self.stds = [s if abs(s) > 1e-9 else 1.0 for s in self.stds]

    def transform(self, raw_features: Union[List[float], Dict[str, Any]]) -> List[float]:
        """
        Normalize raw features for model input.

        Args:
            raw_features: List of N float values (in feature_order), or dict
                         of feature names to values (will be converted to list
                         using feature_order or expected keys).

        Returns:
            Normalized list of floats with length = feature_count.
        """
        if isinstance(raw_features, dict):
            raw_list = self._dict_to_list(raw_features)
        else:
            raw_list = list(raw_features)

        n = len(raw_list)
        target = self.feature_count or n

        # Pad or truncate to match expected size. Use scaler center (median/mean) for padding
        # so the model doesn't see arbitrary zeros and "flatline" to zero prediction.
        if n < target:
            centers = self.medians if self.scaler_type == 'robust' else self.means
            if centers and len(centers) >= target:
                for i in range(n, target):
                    raw_list.append(float(centers[i]) if i < len(centers) else 0.0)
            else:
                raw_list = raw_list + [0.0] * (target - n)
        elif n > target:
            raw_list = raw_list[:target]

        # Apply scaling
        result = []
        centers = self.medians if self.scaler_type == 'robust' else self.means
        scales = self.scales if self.scaler_type == 'robust' else self.stds

        if not centers or not scales:
            return raw_list

        for i, val in enumerate(raw_list):
            try:
                x = float(val) if val is not None else 0.0
            except (TypeError, ValueError):
                x = 0.0
            c = centers[i] if i < len(centers) else 0.0
            s = scales[i] if i < len(scales) else 1.0
            result.append((x - c) / s)

        return result

    def _dict_to_list(self, d: Dict[str, Any]) -> List[float]:
        """Convert feature dict to ordered list."""
        # Use feature_order only if it has real feature names (not f0, f1, ...)
        if self.feature_order and not all(
            k.startswith('f') and k[1:].isdigit() for k in self.feature_order[:5]
        ):
            return [
                float(d.get(k, 0)) if isinstance(d.get(k), (int, float)) else 0.0
                for k in self.feature_order
            ]
        # Fallback: request-driven order so amount/hour/day drive inference (demo fix)
        # First 3 = amount, hour, day from API; then card/addr defaults
        expected = [
            'TransactionAmt', 'hour', 'day', 'card1', 'card2', 'card3',
            'addr1', 'addr2', 'dist1', 'P_emaildomain', 'R_emaildomain'
        ]
        out = []
        for k in expected:
            v = d.get(k, 0)
            if isinstance(v, str):
                out.append(hash(v) % 1000 / 1000.0)
            else:
                try:
                    out.append(float(v))
                except (TypeError, ValueError):
                    out.append(0.0)
        return out
