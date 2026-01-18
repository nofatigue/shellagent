"""HTTP server for shell assistant daemon."""

import json
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
from typing import Dict, Any

from .llm_client import LLMClient
from .safety import SafetyChecker


logger = logging.getLogger(__name__)


class ShellAssistantHandler(BaseHTTPRequestHandler):
    """HTTP request handler for shell assistant endpoints."""
    
    # Class variables to hold LLM client and safety checker (set by server)
    llm_client: LLMClient = None
    safety_checker: SafetyChecker = None
    
    def log_message(self, format, *args):
        """Override to use logging instead of printing."""
        logger.info(format % args)
    
    def _send_json_response(self, status_code: int, data: Dict[str, Any]):
        """Send JSON response."""
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())
    
    def _send_error_response(self, status_code: int, message: str):
        """Send error response."""
        self._send_json_response(status_code, {"error": message})
    
    def do_GET(self):
        """Handle GET requests."""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == "/health":
            self._handle_health()
        else:
            self._send_error_response(404, "Not found")
    
    def do_POST(self):
        """Handle POST requests."""
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == "/complete":
            self._handle_complete()
        else:
            self._send_error_response(404, "Not found")
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests (CORS preflight)."""
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()
    
    def _handle_health(self):
        """Handle health check endpoint."""
        health_data = {
            "status": "ok",
            "model": self.llm_client.model if self.llm_client else "unknown",
            "provider": self.llm_client.provider if self.llm_client else "unknown",
            "connected": True,
        }
        self._send_json_response(200, health_data)
    
    def _handle_complete(self):
        """Handle command completion endpoint."""
        try:
            # Read request body
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length == 0:
                self._send_error_response(400, "Empty request body")
                return
            
            body = self.rfile.read(content_length)
            
            # Parse JSON
            try:
                data = json.loads(body)
            except json.JSONDecodeError as e:
                self._send_error_response(400, f"Invalid JSON: {e}")
                return
            
            # Validate required fields
            if "prompt" not in data:
                self._send_error_response(400, "Missing required field: prompt")
                return
            
            prompt = data["prompt"]
            if not prompt or not prompt.strip():
                self._send_error_response(400, "Prompt cannot be empty")
                return
            
            # Extract optional context
            context = {}
            for key in ["cwd", "shell", "os", "user"]:
                if key in data:
                    context[key] = data[key]
            
            # Generate command
            try:
                result = self.llm_client.get_command(prompt, context if context else None)
                
                # Check command safety and add severity/warning fields
                if "command" in result:
                    severity, descriptions = self.safety_checker.check_command(result["command"])
                    result["severity"] = severity
                    if severity != "safe":
                        warning_msg = self.safety_checker.get_warning_message(severity, descriptions)
                        result["warning"] = warning_msg
                
                self._send_json_response(200, result)
            except Exception as e:
                logger.error(f"Error generating command: {e}")
                self._send_error_response(500, f"Failed to generate command: {str(e)}")
        
        except Exception as e:
            logger.error(f"Error handling request: {e}")
            self._send_error_response(500, f"Internal server error: {str(e)}")


class ShellAssistantServer:
    """Shell assistant HTTP server."""
    
    def __init__(self, config, host: str = "localhost", port: int = 5738):
        """Initialize server.
        
        Args:
            config: Configuration object
            host: Host to bind to
            port: Port to bind to
        """
        self.config = config
        self.host = host
        self.port = port
        self.llm_client = LLMClient(config)
        self.safety_checker = SafetyChecker()
        
        # Set class variables so handler can access them
        ShellAssistantHandler.llm_client = self.llm_client
        ShellAssistantHandler.safety_checker = self.safety_checker
        
        self.httpd = HTTPServer((self.host, self.port), ShellAssistantHandler)
    
    def start(self):
        """Start the server."""
        logger.info(f"Starting shell assistant daemon on {self.host}:{self.port}")
        logger.info(f"Using provider: {self.llm_client.provider}")
        logger.info(f"Using model: {self.llm_client.model}")
        
        try:
            self.httpd.serve_forever()
        except KeyboardInterrupt:
            logger.info("Shutting down server...")
            self.stop()
    
    def stop(self):
        """Stop the server."""
        self.httpd.shutdown()
        logger.info("Server stopped")
