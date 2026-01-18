"""LLM client for generating shell commands."""

import httpx
import json
from typing import Dict, Any


class LLMClient:
    """Client for communicating with LLM APIs."""
    
    def __init__(self, config):
        """Initialize LLM client with configuration.
        
        Args:
            config: Configuration object
        """
        self.config = config
        self.provider = config.get("openrouter.provider", "openai")
        self.api_key = config.get("openrouter.api_key")
        self.model = config.get("openrouter.model")
        self.base_url = config.get("openrouter.base_url")
        self.max_tokens = config.get("preferences.max_tokens", 500)
        
        if not self.api_key:
            raise ValueError("API key not configured. Set SHELLAGENT_API_KEY or OPENROUTER_API_KEY")
    
    def get_command(self, prompt: str, context: Dict[str, Any] = None) -> Dict[str, str]:
        """Generate shell command from natural language prompt.
        
        Args:
            prompt: Natural language description of desired command
            context: Optional context (cwd, shell, os, etc.)
            
        Returns:
            Dict with 'command' and 'explanation' keys
        """
        if self.provider == "openai" or self.provider == "openrouter":
            return self._call_openai(prompt, context)
        elif self.provider == "claude":
            return self._call_claude(prompt, context)
        elif self.provider == "ollama":
            return self._call_ollama(prompt, context)
        else:
            raise ValueError(f"Unknown provider: {self.provider}")
    
    def _build_system_prompt(self, context: Dict[str, Any] = None) -> str:
        """Build system prompt with optional context."""
        base_prompt = (
            "You are a shell command assistant. "
            "When given a natural language description, respond with the shell commands needed. "
            "Respond in JSON format with 'command' and 'explanation' fields. "
            "The 'command' should be the exact shell command(s) to run. "
            "The 'explanation' should briefly describe what the command does. "
            "If the command is potentially dangerous, add a 'warning' field."
        )
        
        if context:
            context_parts = []
            if "cwd" in context:
                context_parts.append(f"Current directory: {context['cwd']}")
            if "shell" in context:
                context_parts.append(f"Shell: {context['shell']}")
            if "os" in context:
                context_parts.append(f"OS: {context['os']}")
            
            if context_parts:
                base_prompt += "\n\nContext:\n" + "\n".join(context_parts)
        
        return base_prompt
    
    def _call_openai(self, prompt: str, context: Dict[str, Any] = None) -> Dict[str, str]:
        """Call OpenAI-compatible API."""
        system_prompt = self._build_system_prompt(context)
        
        # Determine the correct base URL
        if self.provider == "openai":
            api_url = "https://api.openai.com/v1/chat/completions"
        else:
            api_url = f"{self.base_url}/chat/completions"
        
        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.3,
            "max_tokens": self.max_tokens,
        }
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        
        try:
            with httpx.Client(timeout=30.0) as client:
                response = client.post(api_url, json=payload, headers=headers)
                response.raise_for_status()
                
                data = response.json()
                content = data["choices"][0]["message"]["content"]
                
                # Try to parse as JSON
                try:
                    result = json.loads(content)
                    if "command" in result:
                        return result
                except json.JSONDecodeError:
                    pass
                
                # If not JSON, treat as raw command
                return {
                    "command": content.strip(),
                    "explanation": "Generated command"
                }
                
        except httpx.HTTPError as e:
            raise RuntimeError(f"API request failed: {e}")
    
    def _call_claude(self, prompt: str, context: Dict[str, Any] = None) -> Dict[str, str]:
        """Call Claude API."""
        system_prompt = self._build_system_prompt(context)
        
        payload = {
            "model": self.model,
            "max_tokens": self.max_tokens,
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "system": system_prompt,
        }
        
        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        }
        
        try:
            with httpx.Client(timeout=30.0) as client:
                response = client.post(
                    "https://api.anthropic.com/v1/messages",
                    json=payload,
                    headers=headers
                )
                response.raise_for_status()
                
                data = response.json()
                content = data["content"][0]["text"]
                
                # Try to parse as JSON
                try:
                    result = json.loads(content)
                    if "command" in result:
                        return result
                except json.JSONDecodeError:
                    pass
                
                # If not JSON, treat as raw command
                return {
                    "command": content.strip(),
                    "explanation": "Generated command"
                }
                
        except httpx.HTTPError as e:
            raise RuntimeError(f"API request failed: {e}")
    
    def _call_ollama(self, prompt: str, context: Dict[str, Any] = None) -> Dict[str, str]:
        """Call Ollama local API."""
        system_prompt = self._build_system_prompt(context)
        ollama_host = self.base_url or "http://localhost:11434"
        
        full_prompt = f"{system_prompt}\n\nUser request: {prompt}"
        
        payload = {
            "model": self.model,
            "prompt": full_prompt,
            "stream": False,
        }
        
        try:
            with httpx.Client(timeout=30.0) as client:
                response = client.post(
                    f"{ollama_host}/api/generate",
                    json=payload
                )
                response.raise_for_status()
                
                data = response.json()
                content = data.get("response", "")
                
                # Try to parse as JSON
                try:
                    result = json.loads(content)
                    if "command" in result:
                        return result
                except json.JSONDecodeError:
                    pass
                
                # If not JSON, treat as raw command
                return {
                    "command": content.strip(),
                    "explanation": "Generated command"
                }
                
        except httpx.HTTPError as e:
            raise RuntimeError(f"API request failed: {e}")
