"""
Extract scaler parameters for API prediction preprocessing.

Reads from preprocessed_datasets.pkl (or a loaded model) and writes scaler_params.json
so the API can normalize incoming features the same way the model was trained.

Usage:
    python scripts/extract_scaler_params.py
    # Output: models/scaler_params.json
"""

import json
import os
import sys

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

BACKEND_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MODELS_DIR = os.path.join(BACKEND_ROOT, 'models')
OUTPUT_PATH = os.path.join(MODELS_DIR, 'scaler_params.json')


def get_input_dim_from_model():
    """Get input_dim from a saved .pth model."""
    import torch
    for name in ['centralized_baseline.pth', 'local_baseline_bank_A.pth']:
        path = os.path.join(MODELS_DIR, name)
        if os.path.exists(path):
            try:
                save_dict = torch.load(path, map_location='cpu')
                if 'model_config' in save_dict:
                    dim = save_dict['model_config'].get('input_dim')
                    if dim is not None:
                        return dim
            except Exception:
                continue
    return None


def extract_from_preprocessed_datasets():
    """Extract RobustScaler params from preprocessed_datasets.pkl."""
    for rel_path in ['models/preprocessed_datasets.pkl', 'cache/preprocessed_datasets.pkl']:
        path = os.path.join(BACKEND_ROOT, rel_path)
        if not os.path.exists(path):
            continue
        try:
            import pickle
            import numpy as np
            from sklearn.preprocessing import RobustScaler

            with open(path, 'rb') as f:
                data = pickle.load(f)

            X = None
            if 'X_TEST' in data:
                xt = data['X_TEST']
                X = xt[0] if isinstance(xt, tuple) else xt
            elif 'BANK_DATASETS' in data:
                for bank_name, (X_train, _, _, _) in data['BANK_DATASETS'].items():
                    X = X_train
                    break

            if X is None or not hasattr(X, 'shape'):
                return None

            X = np.asarray(X, dtype=np.float64)
            n_features = X.shape[1]

            scaler = RobustScaler()
            scaler.fit(X)

            # RobustScaler: center_ = median, scale_ = IQR
            medians = scaler.center_.tolist()
            scales = scaler.scale_.tolist()
            # Avoid division by zero
            scales = [s if s > 1e-9 else 1.0 for s in scales]

            return {
                'scaler_type': 'robust',
                'medians': medians,
                'scales': scales,
                'feature_count': n_features,
                'feature_order': [f'f{i}' for i in range(n_features)]
            }
        except Exception as e:
            print(f"Could not extract from {path}: {e}")
            continue
    return None


def create_fallback_params(input_dim: int):
    """Create identity scaler (no scaling) when extraction fails."""
    return {
        'scaler_type': 'robust',
        'medians': [0.0] * input_dim,
        'scales': [1.0] * input_dim,
        'feature_count': input_dim,
        'feature_order': [f'f{i}' for i in range(input_dim)],
        '_note': 'Generated fallback (no scaling). Run data prep or extract from notebook for correct values.'
    }


def main():
    os.makedirs(MODELS_DIR, exist_ok=True)

    params = extract_from_preprocessed_datasets()

    if params is None:
        input_dim = get_input_dim_from_model()
        if input_dim is None:
            # Last resort: use README's ~432
            input_dim = 432
            print(f"Warning: Could not determine input_dim, using {input_dim}")
        params = create_fallback_params(input_dim)
        print(f"Created fallback scaler_params (input_dim={input_dim})")

    with open(OUTPUT_PATH, 'w') as f:
        json.dump(params, f, indent=2)

    print(f"Wrote {OUTPUT_PATH}")


if __name__ == '__main__':
    main()
