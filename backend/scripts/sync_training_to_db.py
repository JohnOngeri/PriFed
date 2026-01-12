"""
DEPRECATED: Use sync_training_to_api.py instead!

This script requires Prisma Python client which adds complexity.
The new sync_training_to_api.py uses REST API and is much simpler.

Usage (OLD - requires Prisma Python client):
    python scripts/sync_training_to_db.py --results results/federated_results.json

Usage (NEW - uses REST API, recommended):
    python scripts/sync_training_to_api.py --results results/federated_results.json
"""

import sys
import os
import json
import argparse
from datetime import datetime
from pathlib import Path

# Add parent directory to path for imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from prisma import Prisma
    from prisma.models import TrainingRound, ClassificationMetrics, BankMetrics, BankTrainingRound, PrivacyMetrics, Bank
    import asyncio
except ImportError:
    print("ERROR: Prisma Python client not installed!")
    print("Please install: pip install prisma")
    print("Then generate client: prisma generate --generator python")
    sys.exit(1)

async def sync_training_results(results_file: str, dry_run: bool = False):
    """
    Sync training results to PostgreSQL database.
    
    Args:
        results_file: Path to training results JSON file
        dry_run: If True, only print what would be done without writing to DB
    """
    # Load training results
    if not os.path.exists(results_file):
        print(f"ERROR: Results file not found: {results_file}")
        return False
    
    with open(results_file, 'r') as f:
        data = json.load(f)
    
    # Extract results structure
    # Expected format: { 'history': [...], 'round_metrics': [...] }
    history = data.get('history', [])
    round_metrics = data.get('round_metrics', [])
    config = data.get('config', {})
    
    if not history:
        print("WARNING: No training history found in results file")
        print(f"Available keys: {list(data.keys())}")
        return False
    
    print(f"Found {len(history)} training rounds to sync")
    
    if dry_run:
        print("\n[DRY RUN] Would sync the following rounds:")
        for i, round_data in enumerate(history[:5]):  # Show first 5
            print(f"  Round {i+1}: {round_data.get('round', 'unknown')}")
        if len(history) > 5:
            print(f"  ... and {len(history) - 5} more rounds")
        return True
    
    # Connect to database
    prisma = Prisma()
    await prisma.connect()
    
    try:
        synced_count = 0
        skipped_count = 0
        
        for round_data in history:
            try:
                # Extract round information
                round_num = round_data.get('round', 0)
                metrics = round_data.get('metrics', {})
                
                # Check if round already exists
                existing = await prisma.traininground.find_unique({
                    where: { roundNumber: round_num }
                })
                
                if existing:
                    print(f"Round {round_num} already exists, skipping...")
                    skipped_count += 1
                    continue
                
                # Create global metrics
                global_metrics = await prisma.classificationmetrics.create({
                    data={
                        'auc': float(metrics.get('auc', 0.0)),
                        'accuracy': float(metrics.get('accuracy', 0.0)),
                        'precision': float(metrics.get('precision', 0.0)),
                        'recall': float(metrics.get('recall', 0.0)),
                        'f1': float(metrics.get('f1', 0.0)),
                        'loss': float(metrics.get('loss', 0.0)),
                        'specificity': float(metrics.get('specificity', 0.0)) if metrics.get('specificity') is not None else None,
                        'timestamp': datetime.now()
                    }
                })
                
                # Create training round
                started_at = datetime.fromisoformat(round_data.get('started_at', datetime.now().isoformat())) if isinstance(round_data.get('started_at'), str) else round_data.get('started_at', datetime.now())
                completed_at = datetime.fromisoformat(round_data.get('completed_at', datetime.now().isoformat())) if isinstance(round_data.get('completed_at'), str) else round_data.get('completed_at')
                
                training_round = await prisma.traininground.create({
                    data={
                        'roundNumber': round_num,
                        'status': 'COMPLETED',
                        'globalMetricsId': global_metrics.id,
                        'startedAt': started_at,
                        'completedAt': completed_at,
                        'duration': round_data.get('duration')
                    }
                })
                
                # Create bank-specific metrics if available
                bank_metrics_data = round_data.get('bank_metrics', {}) or round_data.get('client_metrics', {})
                
                for bank_id, bank_metrics in bank_metrics_data.items():
                    # Find bank by human-readable bankId
                    bank = await prisma.bank.find_unique({
                        where: { bankId: bank_id }
                    })
                    
                    if not bank:
                        print(f"WARNING: Bank {bank_id} not found in database, skipping bank metrics")
                        continue
                    
                    # Create metrics for this bank
                    bank_classification_metrics = await prisma.classificationmetrics.create({
                        data={
                            'auc': float(bank_metrics.get('auc', 0.0)),
                            'accuracy': float(bank_metrics.get('accuracy', 0.0)),
                            'precision': float(bank_metrics.get('precision', 0.0)),
                            'recall': float(bank_metrics.get('recall', 0.0)),
                            'f1': float(bank_metrics.get('f1', 0.0)),
                            'loss': float(bank_metrics.get('loss', 0.0)) if bank_metrics.get('loss') is not None else None,
                            'timestamp': datetime.now()
                        }
                    })
                    
                    # Create bank training round record
                    await prisma.banktraininground.create({
                        data={
                            'roundId': training_round.id,
                            'bankId': bank.id,  # Use UUID
                            'metricsId': bank_classification_metrics.id,
                            'samples': int(bank_metrics.get('num_samples', 0)) if bank_metrics.get('num_samples') is not None else None,
                            'fraudRate': float(bank_metrics.get('fraud_rate', 0.0)) if bank_metrics.get('fraud_rate') is not None else None
                        }
                    })
                
                # Create privacy metrics if available
                privacy_metrics_data = round_data.get('privacy_metrics')
                if privacy_metrics_data:
                    privacy_metrics = await prisma.privacymetrics.create({
                        data={
                            'currentEpsilon': float(privacy_metrics_data.get('current_epsilon', 0.0)),
                            'targetEpsilon': float(privacy_metrics_data.get('target_epsilon', 8.0)),
                            'delta': float(privacy_metrics_data.get('delta', 1e-5)),
                            'noiseMultiplier': float(privacy_metrics_data.get('noise_multiplier', 1.1)),
                            'privacyStrength': str(privacy_metrics_data.get('privacy_strength', 'Moderate')),
                            'budgetUsedPercentage': float(privacy_metrics_data.get('budget_used_percentage', 0.0)),
                            'timestamp': datetime.now()
                        }
                    })
                    
                    # Link privacy metrics to training round
                    await prisma.traininground.update({
                        where: { id: training_round.id },
                        data: { privacyMetricsId: privacy_metrics.id }
                    })
                
                synced_count += 1
                print(f"✅ Synced round {round_num} to database")
                
            except Exception as e:
                print(f"❌ Error syncing round {round_data.get('round', 'unknown')}: {str(e)}")
                import traceback
                traceback.print_exc()
                continue
        
        print(f"\n✅ Sync complete!")
        print(f"   Synced: {synced_count} rounds")
        print(f"   Skipped: {skipped_count} rounds (already exist)")
        
        return True
        
    except Exception as e:
        print(f"❌ Error during sync: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
        
    finally:
        await prisma.disconnect()

def main():
    parser = argparse.ArgumentParser(description='Sync training results to PostgreSQL database')
    parser.add_argument('--results', type=str, default='results/federated_results.json',
                       help='Path to training results JSON file')
    parser.add_argument('--dry-run', action='store_true',
                       help='Show what would be synced without actually writing to database')
    args = parser.parse_args()
    
    # Resolve path relative to script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    results_path = os.path.join(script_dir, '..', args.results) if not os.path.isabs(args.results) else args.results
    results_path = os.path.normpath(results_path)
    
    print(f"Syncing training results from: {results_path}")
    
    if args.dry_run:
        print("[DRY RUN MODE - No changes will be made]")
    
    # Run async function
    success = asyncio.run(sync_training_results(results_path, dry_run=args.dry_run))
    
    if success:
        print("\n✅ Done! You can now query training results via the Node.js API:")
        print("   curl http://localhost:8000/api/metrics/global")
        print("   curl http://localhost:8000/api/metrics/banks")
        print("   curl http://localhost:8000/api/rounds")
    else:
        print("\n❌ Sync failed. Check error messages above.")
        sys.exit(1)

if __name__ == '__main__':
    main()
