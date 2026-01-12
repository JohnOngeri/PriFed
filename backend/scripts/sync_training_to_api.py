"""
Sync training results to Node.js API endpoint.

This script reads training results from JSON files and sends them to the Node.js backend
via REST API, which then stores them in PostgreSQL. This avoids needing Prisma Python client.

Usage:
    python scripts/sync_training_to_api.py --results results/federated_results.json
    python scripts/sync_training_to_api.py --results results/federated_results.json --api-url http://localhost:8000
    python scripts/sync_training_to_api.py --results results/federated_results.json --batch-size 10
"""

import sys
import os
import json
import argparse
import requests
from pathlib import Path
from typing import Dict, List, Any

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def load_training_results(results_file: str) -> Dict[str, Any]:
    """Load training results from JSON file."""
    if not os.path.exists(results_file):
        raise FileNotFoundError(f"Results file not found: {results_file}")
    
    with open(results_file, 'r') as f:
        data = json.load(f)
    
    return data

def transform_round_data(round_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Transform training round data to match API expectations.
    
    Args:
        round_data: Raw training round data from Python scripts
        
    Returns:
        Transformed data ready for API
    """
    # Extract round number
    round_num = round_data.get('round', 0)
    
    # Extract global metrics
    metrics = round_data.get('metrics', {})
    global_metrics = {
        'auc': float(metrics.get('auc', 0.0)),
        'accuracy': float(metrics.get('accuracy', 0.0)),
        'precision': float(metrics.get('precision', 0.0)),
        'recall': float(metrics.get('recall', 0.0)),
        'f1': float(metrics.get('f1', 0.0)),
        'loss': float(metrics.get('loss', 0.0)) if metrics.get('loss') is not None else None,
        'specificity': float(metrics.get('specificity', 0.0)) if metrics.get('specificity') is not None else None
    }
    
    # Extract bank/client metrics
    # Handle different possible keys: client_metrics, bank_metrics, bank_rounds, etc.
    client_metrics = {}
    
    if 'client_metrics' in round_data:
        client_metrics = round_data['client_metrics']
    elif 'bank_metrics' in round_data:
        client_metrics = round_data['bank_metrics']
    elif 'bank_rounds' in round_data:
        # Transform bank_rounds array to dictionary
        for bank_round in round_data['bank_rounds']:
            bank_id = bank_round.get('bank_id') or bank_round.get('bankId')
            if bank_id:
                client_metrics[bank_id] = {
                    'auc': float(bank_round.get('auc', 0.0)),
                    'accuracy': float(bank_round.get('accuracy', 0.0)),
                    'precision': float(bank_round.get('precision', 0.0)),
                    'recall': float(bank_round.get('recall', 0.0)),
                    'f1': float(bank_round.get('f1', 0.0)),
                    'loss': float(bank_round.get('loss', 0.0)) if bank_round.get('loss') is not None else None,
                    'num_samples': int(bank_round.get('num_samples', 0)) if bank_round.get('num_samples') is not None else None,
                    'fraud_rate': float(bank_round.get('fraud_rate', 0.0)) if bank_round.get('fraud_rate') is not None else None
                }
    
    # Transform client_metrics to ensure proper format
    transformed_client_metrics = {}
    for bank_id, bank_metrics in client_metrics.items():
        transformed_client_metrics[bank_id] = {
            'auc': float(bank_metrics.get('auc', 0.0)),
            'accuracy': float(bank_metrics.get('accuracy', 0.0)),
            'precision': float(bank_metrics.get('precision', 0.0)),
            'recall': float(bank_metrics.get('recall', 0.0)),
            'f1': float(bank_metrics.get('f1', 0.0)),
            'loss': float(bank_metrics.get('loss', 0.0)) if bank_metrics.get('loss') is not None else None,
            'num_samples': int(bank_metrics.get('num_samples', 0)) if bank_metrics.get('num_samples') is not None else None,
            'fraud_rate': float(bank_metrics.get('fraud_rate', 0.0)) if bank_metrics.get('fraud_rate') is not None else None
        }
    
    # Extract privacy metrics if available
    privacy_metrics = None
    if 'privacy_metrics' in round_data:
        privacy_data = round_data['privacy_metrics']
        privacy_metrics = {
            'current_epsilon': float(privacy_data.get('current_epsilon', 0.0)),
            'target_epsilon': float(privacy_data.get('target_epsilon', 8.0)),
            'delta': float(privacy_data.get('delta', 1e-5)),
            'noise_multiplier': float(privacy_data.get('noise_multiplier', 1.1)),
            'privacy_strength': str(privacy_data.get('privacy_strength', 'Moderate')),
            'budget_used_percentage': float(privacy_data.get('budget_used_percentage', 0.0))
        }
    
    # Build final payload
    payload = {
        'round': round_num,
        'global_metrics': global_metrics,
        'client_metrics': transformed_client_metrics if transformed_client_metrics else None,
        'privacy_metrics': privacy_metrics,
        'timestamp': round_data.get('timestamp') or round_data.get('started_at'),
        'duration': round_data.get('duration')
    }
    
    # Remove None values for cleaner payload
    payload = {k: v for k, v in payload.items() if v is not None}
    
    return payload

def sync_single_round(round_data: Dict[str, Any], api_url: str) -> bool:
    """Sync a single training round to the API."""
    try:
        payload = transform_round_data(round_data)
        
        response = requests.post(
            f'{api_url}/api/training/rounds',
            json=payload,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        if response.status_code == 201:
            result = response.json()
            print(f"✅ Round {round_data.get('round', 'unknown')} synced successfully (Banks: {result.get('banks_count', 0)})")
            return True
        elif response.status_code == 409:
            print(f"⏭️  Round {round_data.get('round', 'unknown')} already exists, skipping")
            return True  # Not an error, just already exists
        else:
            print(f"❌ Round {round_data.get('round', 'unknown')} failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error syncing round {round_data.get('round', 'unknown')}: {str(e)}")
        return False

def sync_batch_rounds(rounds: List[Dict[str, Any]], api_url: str, batch_size: int = 10) -> Dict[str, int]:
    """Sync multiple training rounds in batches."""
    results = {'successful': 0, 'failed': 0, 'skipped': 0}
    
    # Process in batches
    for i in range(0, len(rounds), batch_size):
        batch = rounds[i:i + batch_size]
        transformed_batch = [transform_round_data(round_data) for round_data in batch]
        
        try:
            response = requests.post(
                f'{api_url}/api/training/rounds/batch',
                json=transformed_batch,
                headers={'Content-Type': 'application/json'},
                timeout=60
            )
            
            if response.status_code == 201:
                result = response.json()
                results['successful'] += result.get('successful', 0)
                results['failed'] += result.get('failed', 0)
                results['skipped'] += result.get('skipped', 0)
                print(f"✅ Batch {i//batch_size + 1}: {result.get('successful', 0)} synced, {result.get('failed', 0)} failed, {result.get('skipped', 0)} skipped")
            else:
                print(f"❌ Batch {i//batch_size + 1} failed: {response.status_code} - {response.text}")
                results['failed'] += len(batch)
                
        except Exception as e:
            print(f"❌ Error syncing batch {i//batch_size + 1}: {str(e)}")
            results['failed'] += len(batch)
    
    return results

def main():
    parser = argparse.ArgumentParser(description='Sync training results to Node.js API')
    parser.add_argument('--results', type=str, default='results/federated_results.json',
                       help='Path to training results JSON file')
    parser.add_argument('--api-url', type=str, default='http://localhost:8000',
                       help='Node.js API base URL')
    parser.add_argument('--batch', action='store_true',
                       help='Use batch endpoint (faster for many rounds)')
    parser.add_argument('--batch-size', type=int, default=10,
                       help='Number of rounds per batch (default: 10)')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be synced without actually sending to API')
    args = parser.parse_args()
    
    # Resolve path relative to script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    results_path = os.path.join(script_dir, '..', args.results) if not os.path.isabs(args.results) else args.results
    results_path = os.path.normpath(results_path)
    
    print(f"Loading training results from: {results_path}")
    print(f"API URL: {args.api_url}")
    
    try:
        # Load results
        data = load_training_results(results_path)
        
        # Extract rounds from different possible structures
        history = data.get('history', [])
        if not history:
            history = data.get('rounds', [])
        if not history and 'results' in data:
            history = data['results'].get('history', [])
        
        if not history:
            print("ERROR: No training rounds found in results file")
            print(f"Available keys: {list(data.keys())}")
            sys.exit(1)
        
        print(f"Found {len(history)} training rounds to sync")
        
        if args.dry_run:
            print("\n[DRY RUN] Would sync the following rounds:")
            for i, round_data in enumerate(history[:10]):  # Show first 10
                round_num = round_data.get('round', f'unknown_{i}')
                print(f"  Round {round_num}")
            if len(history) > 10:
                print(f"  ... and {len(history) - 10} more rounds")
            return
        
        # Test API connection
        try:
            health_response = requests.get(f'{args.api_url}/api/health', timeout=5)
            if health_response.status_code != 200:
                print(f"WARNING: API health check failed (status {health_response.status_code})")
                print("Proceeding anyway, but API may not be available...")
        except requests.exceptions.RequestException as e:
            print(f"ERROR: Cannot connect to API at {args.api_url}")
            print(f"Error: {str(e)}")
            print("\nMake sure the Node.js backend is running:")
            print("  cd backend && npm run dev")
            sys.exit(1)
        
        # Sync rounds
        if args.batch and len(history) > 1:
            print(f"\nSyncing {len(history)} rounds in batches of {args.batch_size}...")
            results = sync_batch_rounds(history, args.api_url, args.batch_size)
            print(f"\n✅ Sync complete!")
            print(f"   Successful: {results['successful']}")
            print(f"   Failed: {results['failed']}")
            print(f"   Skipped: {results['skipped']}")
        else:
            print(f"\nSyncing {len(history)} rounds individually...")
            successful = 0
            failed = 0
            skipped = 0
            
            for round_data in history:
                result = sync_single_round(round_data, args.api_url)
                if result:
                    successful += 1
                else:
                    failed += 1
            
            print(f"\n✅ Sync complete!")
            print(f"   Successful: {successful}")
            print(f"   Failed: {failed}")
        
        print("\n✅ Done! You can now query training results via the Node.js API:")
        print(f"   curl {args.api_url}/api/metrics/global")
        print(f"   curl {args.api_url}/api/metrics/banks")
        print(f"   curl {args.api_url}/api/rounds")
        
    except FileNotFoundError as e:
        print(f"ERROR: {str(e)}")
        sys.exit(1)
    except Exception as e:
        print(f"ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
