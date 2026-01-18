"""Configuration management for shell assistant daemon."""

import os
import yaml
import logging
from pathlib import Path
from typing import Dict, Any


logger = logging.getLogger(__name__)


class Config:
    """Configuration loader and manager."""
    
    def __init__(self, config_path: str = None):
        """Initialize configuration.
        
        Args:
            config_path: Optional path to config file. If not provided,
                        looks for ~/.config/shell-assistant/config.yaml
        """
        if config_path is None:
            config_path = os.path.expanduser("~/.config/shell-assistant/config.yaml")
        
        self.config_path = config_path
        self.config = self._load_config()
    
    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from file or use defaults."""
        config = {
            "openrouter": {
                "api_key": os.getenv("OPENROUTER_API_KEY", os.getenv("SHELLAGENT_API_KEY", "")),
                "model": os.getenv("SHELLAGENT_MODEL", "anthropic/claude-3.5-sonnet"),
                "base_url": os.getenv("SHELLAGENT_API_BASE", "https://openrouter.ai/api/v1"),
                "provider": os.getenv("SHELLAGENT_PROVIDER", "openai"),
            },
            "daemon": {
                "host": "localhost",
                "port": 5738,
            },
            "preferences": {
                "auto_execute": False,
                "context_aware": True,
                "explain_commands": True,
                "max_tokens": 500,
            }
        }
        
        # Try to load from file if it exists
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r') as f:
                    file_config = yaml.safe_load(f)
                    if file_config:
                        # Deep merge file config with defaults
                        self._merge_config(config, file_config)
            except Exception as e:
                logger.warning(f"Failed to load config from {self.config_path}: {e}")
        
        return config
    
    def _merge_config(self, base: Dict, override: Dict):
        """Recursively merge override config into base config."""
        for key, value in override.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._merge_config(base[key], value)
            else:
                base[key] = value
    
    def get(self, path: str, default=None):
        """Get configuration value by dot-separated path.
        
        Args:
            path: Dot-separated path like "openrouter.api_key"
            default: Default value if path not found
            
        Returns:
            Configuration value or default
        """
        keys = path.split(".")
        value = self.config
        
        for key in keys:
            if isinstance(value, dict) and key in value:
                value = value[key]
            else:
                return default
        
        return value
    
    def set(self, path: str, value: Any):
        """Set configuration value by dot-separated path."""
        keys = path.split(".")
        config = self.config
        
        for key in keys[:-1]:
            if key not in config:
                config[key] = {}
            config = config[key]
        
        config[keys[-1]] = value
    
    def save(self):
        """Save current configuration to file."""
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        with open(self.config_path, 'w') as f:
            yaml.dump(self.config, f, default_flow_style=False)
