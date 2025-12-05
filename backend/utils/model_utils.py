"""
PyTorch model utilities for fraud detection in federated learning setting.
Implements neural network architectures optimized for tabular fraud detection data.
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import List, Dict, Any, Optional, Tuple
import numpy as np
import logging
import os
from collections import OrderedDict

logger = logging.getLogger(__name__)

class FraudDetectionMLP(nn.Module):
    """
    Multi-layer perceptron for fraud detection with configurable architecture.
    Optimized for tabular data with batch normalization and dropout regularization.
    """
    
    def __init__(self, input_dim: int, hidden_layers: List[int] = [256, 128, 64], 
                 dropout_rate: float = 0.3, activation: str = "relu", 
                 batch_norm: bool = True, output_dim: int = 1):
        """
        Initialize the fraud detection MLP.
        
        Args:
            input_dim: Number of input features
            hidden_layers: List of hidden layer sizes
            dropout_rate: Dropout probability
            activation: Activation function ('relu', 'leaky_relu', 'elu', 'gelu')
            batch_norm: Whether to use batch normalization
            output_dim: Number of output units (1 for binary classification)
        """
        super(FraudDetectionMLP, self).__init__()
        
        self.input_dim = input_dim
        self.hidden_layers = hidden_layers
        self.dropout_rate = dropout_rate
        self.activation = activation
        self.batch_norm = batch_norm
        self.output_dim = output_dim
        
        # Build the network layers
        layers = []
        prev_dim = input_dim
        
        # Hidden layers
        for i, hidden_dim in enumerate(hidden_layers):
            # Linear layer
            layers.append((f'linear_{i}', nn.Linear(prev_dim, hidden_dim)))
            
            # Batch normalization
            if batch_norm:
                layers.append((f'bn_{i}', nn.BatchNorm1d(hidden_dim)))
            
            # Activation function
            if activation == "relu":
                layers.append((f'activation_{i}', nn.ReLU()))
            elif activation == "leaky_relu":
                layers.append((f'activation_{i}', nn.LeakyReLU(0.1)))
            elif activation == "elu":
                layers.append((f'activation_{i}', nn.ELU()))
            elif activation == "gelu":
                layers.append((f'activation_{i}', nn.GELU()))
            else:
                raise ValueError(f"Unknown activation function: {activation}")
            
            # Dropout
            if dropout_rate > 0:
                layers.append((f'dropout_{i}', nn.Dropout(dropout_rate)))
            
            prev_dim = hidden_dim
        
        # Output layer
        layers.append(('output', nn.Linear(prev_dim, output_dim)))
        
        # Create sequential model
        self.network = nn.Sequential(OrderedDict(layers))
        
        # Initialize weights
        self._initialize_weights()
        
        logger.info(f"Created FraudDetectionMLP with {self.count_parameters()} parameters")
        logger.info(f"Architecture: {input_dim} -> {' -> '.join(map(str, hidden_layers))} -> {output_dim}")
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Forward pass through the network.
        
        Args:
            x: Input tensor of shape (batch_size, input_dim)
            
        Returns:
            Output tensor of shape (batch_size, output_dim)
        """
        return self.network(x)
    
    def _initialize_weights(self) -> None:
        """Initialize network weights using Xavier/Glorot initialization."""
        for module in self.modules():
            if isinstance(module, nn.Linear):
                nn.init.xavier_uniform_(module.weight)
                if module.bias is not None:
                    nn.init.constant_(module.bias, 0)
            elif isinstance(module, nn.BatchNorm1d):
                nn.init.constant_(module.weight, 1)
                nn.init.constant_(module.bias, 0)
    
    def count_parameters(self) -> int:
        """Count the total number of trainable parameters."""
        return sum(p.numel() for p in self.parameters() if p.requires_grad)
    
    def get_feature_importance(self, X: torch.Tensor) -> np.ndarray:
        """
        Compute feature importance using gradient-based method.
        
        Args:
            X: Input tensor
            
        Returns:
            Feature importance scores
        """
        self.eval()
        X.requires_grad_(True)
        
        output = self.forward(X)
        output = torch.sigmoid(output)  # Convert to probabilities
        
        # Compute gradients
        gradients = torch.autograd.grad(
            outputs=output.sum(),
            inputs=X,
            create_graph=False,
            retain_graph=False
        )[0]
        
        # Feature importance as absolute gradient magnitude
        importance = torch.abs(gradients).mean(dim=0).detach().cpu().numpy()
        
        return importance

class FraudDetectionCNN(nn.Module):
    """
    Convolutional Neural Network for fraud detection.
    Treats tabular data as 1D sequences for pattern detection.
    """
    
    def __init__(self, input_dim: int, num_filters: List[int] = [64, 128, 256],
                 kernel_sizes: List[int] = [3, 5, 7], dropout_rate: float = 0.3,
                 hidden_dim: int = 128, output_dim: int = 1):
        """
        Initialize the fraud detection CNN.
        
        Args:
            input_dim: Number of input features
            num_filters: Number of filters for each conv layer
            kernel_sizes: Kernel sizes for each conv layer
            dropout_rate: Dropout probability
            hidden_dim: Hidden dimension for final layers
            output_dim: Number of output units
        """
        super(FraudDetectionCNN, self).__init__()
        
        self.input_dim = input_dim
        
        # Convolutional layers
        self.conv_layers = nn.ModuleList()
        for i, (num_filter, kernel_size) in enumerate(zip(num_filters, kernel_sizes)):
            conv_layer = nn.Sequential(
                nn.Conv1d(1 if i == 0 else num_filters[i-1], num_filter, kernel_size, padding=kernel_size//2),
                nn.BatchNorm1d(num_filter),
                nn.ReLU(),
                nn.MaxPool1d(2),
                nn.Dropout(dropout_rate)
            )
            self.conv_layers.append(conv_layer)
        
        # Calculate the size after convolutions
        conv_output_size = input_dim
        for _ in num_filters:
            conv_output_size = conv_output_size // 2  # Due to MaxPool1d(2)
        
        self.conv_output_size = conv_output_size * num_filters[-1]
        
        # Fully connected layers
        self.fc_layers = nn.Sequential(
            nn.Linear(self.conv_output_size, hidden_dim),
            nn.BatchNorm1d(hidden_dim),
            nn.ReLU(),
            nn.Dropout(dropout_rate),
            nn.Linear(hidden_dim, output_dim)
        )
        
        self._initialize_weights()
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Forward pass through the CNN.
        
        Args:
            x: Input tensor of shape (batch_size, input_dim)
            
        Returns:
            Output tensor of shape (batch_size, output_dim)
        """
        # Reshape for 1D convolution: (batch_size, 1, input_dim)
        x = x.unsqueeze(1)
        
        # Apply convolutional layers
        for conv_layer in self.conv_layers:
            x = conv_layer(x)
        
        # Flatten for fully connected layers
        x = x.view(x.size(0), -1)
        
        # Apply fully connected layers
        x = self.fc_layers(x)
        
        return x
    
    def _initialize_weights(self) -> None:
        """Initialize network weights."""
        for module in self.modules():
            if isinstance(module, (nn.Conv1d, nn.Linear)):
                nn.init.xavier_uniform_(module.weight)
                if module.bias is not None:
                    nn.init.constant_(module.bias, 0)
            elif isinstance(module, nn.BatchNorm1d):
                nn.init.constant_(module.weight, 1)
                nn.init.constant_(module.bias, 0)

class FraudDetectionTransformer(nn.Module):
    """
    Transformer-based model for fraud detection.
    Uses self-attention to capture feature interactions.
    """
    
    def __init__(self, input_dim: int, d_model: int = 128, nhead: int = 8,
                 num_layers: int = 3, dim_feedforward: int = 512,
                 dropout_rate: float = 0.1, output_dim: int = 1):
        """
        Initialize the fraud detection Transformer.
        
        Args:
            input_dim: Number of input features
            d_model: Model dimension
            nhead: Number of attention heads
            num_layers: Number of transformer layers
            dim_feedforward: Feedforward network dimension
            dropout_rate: Dropout probability
            output_dim: Number of output units
        """
        super(FraudDetectionTransformer, self).__init__()
        
        self.input_dim = input_dim
        self.d_model = d_model
        
        # Input projection
        self.input_projection = nn.Linear(input_dim, d_model)
        
        # Positional encoding (for feature positions)
        self.pos_encoding = nn.Parameter(torch.randn(1, input_dim, d_model))
        
        # Transformer encoder
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=d_model,
            nhead=nhead,
            dim_feedforward=dim_feedforward,
            dropout=dropout_rate,
            batch_first=True
        )
        self.transformer = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        
        # Output layers
        self.output_layers = nn.Sequential(
            nn.Linear(d_model, d_model // 2),
            nn.ReLU(),
            nn.Dropout(dropout_rate),
            nn.Linear(d_model // 2, output_dim)
        )
        
        self._initialize_weights()
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Forward pass through the Transformer.
        
        Args:
            x: Input tensor of shape (batch_size, input_dim)
            
        Returns:
            Output tensor of shape (batch_size, output_dim)
        """
        batch_size = x.size(0)
        
        # Reshape to treat each feature as a token: (batch_size, input_dim, 1)
        x = x.unsqueeze(-1)
        
        # Project to model dimension: (batch_size, input_dim, d_model)
        x = self.input_projection(x)
        
        # Add positional encoding
        x = x + self.pos_encoding
        
        # Apply transformer
        x = self.transformer(x)
        
        # Global average pooling
        x = x.mean(dim=1)  # (batch_size, d_model)
        
        # Output layers
        x = self.output_layers(x)
        
        return x
    
    def _initialize_weights(self) -> None:
        """Initialize network weights."""
        for module in self.modules():
            if isinstance(module, nn.Linear):
                nn.init.xavier_uniform_(module.weight)
                if module.bias is not None:
                    nn.init.constant_(module.bias, 0)

def build_model(input_dim: int, config: Dict[str, Any]) -> nn.Module:
    """
    Build a fraud detection model based on configuration.
    
    Args:
        input_dim: Number of input features
        config: Model configuration dictionary
        
    Returns:
        PyTorch model
    """
    model_config = config.get('model', {})
    architecture = model_config.get('architecture', 'mlp')
    
    if architecture == 'mlp':
        model = FraudDetectionMLP(
            input_dim=input_dim,
            hidden_layers=model_config.get('hidden_layers', [256, 128, 64]),
            dropout_rate=model_config.get('dropout_rate', 0.3),
            activation=model_config.get('activation', 'relu'),
            batch_norm=model_config.get('batch_norm', True)
        )
    elif architecture == 'cnn':
        model = FraudDetectionCNN(
            input_dim=input_dim,
            num_filters=model_config.get('num_filters', [64, 128, 256]),
            kernel_sizes=model_config.get('kernel_sizes', [3, 5, 7]),
            dropout_rate=model_config.get('dropout_rate', 0.3),
            hidden_dim=model_config.get('hidden_dim', 128)
        )
    elif architecture == 'transformer':
        model = FraudDetectionTransformer(
            input_dim=input_dim,
            d_model=model_config.get('d_model', 128),
            nhead=model_config.get('nhead', 8),
            num_layers=model_config.get('num_layers', 3),
            dim_feedforward=model_config.get('dim_feedforward', 512),
            dropout_rate=model_config.get('dropout_rate', 0.1)
        )
    else:
        raise ValueError(f"Unknown architecture: {architecture}")
    
    logger.info(f"Built {architecture} model with {model.count_parameters() if hasattr(model, 'count_parameters') else 'unknown'} parameters")
    
    return model

def save_model(model: nn.Module, filepath: str, metadata: Optional[Dict[str, Any]] = None) -> None:
    """
    Save a PyTorch model with metadata.
    
    Args:
        model: PyTorch model to save
        filepath: Path to save the model
        metadata: Optional metadata to save with the model
    """
    # Create directory if it doesn't exist
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    # Prepare save dictionary
    save_dict = {
        'model_state_dict': model.state_dict(),
        'model_class': model.__class__.__name__,
        'model_config': {
            'input_dim': getattr(model, 'input_dim', None),
            'hidden_layers': getattr(model, 'hidden_layers', None),
            'dropout_rate': getattr(model, 'dropout_rate', None),
            'activation': getattr(model, 'activation', None),
            'batch_norm': getattr(model, 'batch_norm', None),
            'output_dim': getattr(model, 'output_dim', 1)
        }
    }
    
    if metadata:
        save_dict['metadata'] = metadata
    
    torch.save(save_dict, filepath)
    logger.info(f"Model saved to: {filepath}")

def load_model(filepath: str, device: Optional[torch.device] = None) -> Tuple[nn.Module, Dict[str, Any]]:
    """
    Load a PyTorch model with metadata.
    
    Args:
        filepath: Path to load the model from
        device: Device to load the model on
        
    Returns:
        Tuple of (model, metadata)
    """
    if device is None:
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    
    # Load the saved dictionary
    save_dict = torch.load(filepath, map_location=device)
    
    # Extract model configuration
    model_class = save_dict['model_class']
    model_config = save_dict['model_config']
    
    # Recreate the model
    if model_class == 'FraudDetectionMLP':
        model = FraudDetectionMLP(
            input_dim=model_config['input_dim'],
            hidden_layers=model_config['hidden_layers'],
            dropout_rate=model_config['dropout_rate'],
            activation=model_config['activation'],
            batch_norm=model_config['batch_norm'],
            output_dim=model_config['output_dim']
        )
    elif model_class == 'FraudDetectionCNN':
        model = FraudDetectionCNN(
            input_dim=model_config['input_dim'],
            dropout_rate=model_config['dropout_rate'],
            output_dim=model_config['output_dim']
        )
    elif model_class == 'FraudDetectionTransformer':
        model = FraudDetectionTransformer(
            input_dim=model_config['input_dim'],
            dropout_rate=model_config['dropout_rate'],
            output_dim=model_config['output_dim']
        )
    else:
        raise ValueError(f"Unknown model class: {model_class}")
    
    # Load the state dict
    model.load_state_dict(save_dict['model_state_dict'])
    model.to(device)
    
    # Extract metadata
    metadata = save_dict.get('metadata', {})
    
    logger.info(f"Model loaded from: {filepath}")
    
    return model, metadata

def get_model_summary(model: nn.Module, input_shape: Tuple[int, ...]) -> str:
    """
    Get a summary of the model architecture.
    
    Args:
        model: PyTorch model
        input_shape: Shape of input tensor (without batch dimension)
        
    Returns:
        Model summary string
    """
    def count_parameters(model):
        return sum(p.numel() for p in model.parameters() if p.requires_grad)
    
    summary = []
    summary.append(f"Model: {model.__class__.__name__}")
    summary.append(f"Input shape: {input_shape}")
    summary.append(f"Trainable parameters: {count_parameters(model):,}")
    summary.append("\nArchitecture:")
    
    for name, module in model.named_modules():
        if len(list(module.children())) == 0:  # Leaf modules only
            summary.append(f"  {name}: {module}")
    
    return "\n".join(summary)

def initialize_model_weights(model: nn.Module, init_type: str = "xavier") -> None:
    """
    Initialize model weights with specified initialization scheme.
    
    Args:
        model: PyTorch model
        init_type: Initialization type ('xavier', 'kaiming', 'normal')
    """
    for module in model.modules():
        if isinstance(module, (nn.Linear, nn.Conv1d)):
            if init_type == "xavier":
                nn.init.xavier_uniform_(module.weight)
            elif init_type == "kaiming":
                nn.init.kaiming_uniform_(module.weight, nonlinearity='relu')
            elif init_type == "normal":
                nn.init.normal_(module.weight, mean=0, std=0.02)
            
            if module.bias is not None:
                nn.init.constant_(module.bias, 0)
        elif isinstance(module, nn.BatchNorm1d):
            nn.init.constant_(module.weight, 1)
            nn.init.constant_(module.bias, 0)
    
    logger.info(f"Model weights initialized with {init_type} initialization")

def freeze_layers(model: nn.Module, layer_names: List[str]) -> None:
    """
    Freeze specified layers in the model.
    
    Args:
        model: PyTorch model
        layer_names: List of layer names to freeze
    """
    for name, param in model.named_parameters():
        if any(layer_name in name for layer_name in layer_names):
            param.requires_grad = False
            logger.info(f"Frozen layer: {name}")

def unfreeze_layers(model: nn.Module, layer_names: List[str]) -> None:
    """
    Unfreeze specified layers in the model.
    
    Args:
        model: PyTorch model
        layer_names: List of layer names to unfreeze
    """
    for name, param in model.named_parameters():
        if any(layer_name in name for layer_name in layer_names):
            param.requires_grad = True
            logger.info(f"Unfrozen layer: {name}")

def get_device(config: Dict[str, Any]) -> torch.device:
    """
    Get the appropriate device based on configuration.
    
    Args:
        config: Configuration dictionary
        
    Returns:
        PyTorch device
    """
    device_config = config.get('experiment', {}).get('device', 'auto')
    
    if device_config == 'auto':
        device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    elif device_config == 'cuda':
        if torch.cuda.is_available():
            device = torch.device('cuda')
        else:
            logger.warning("CUDA requested but not available, using CPU")
            device = torch.device('cpu')
    else:
        device = torch.device(device_config)
    
    logger.info(f"Using device: {device}")
    return device