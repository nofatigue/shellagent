"""Safety checks for potentially dangerous shell commands."""

import re
from typing import Tuple, List


class SafetyChecker:
    """Check shell commands for potentially dangerous operations."""
    
    # Patterns for dangerous commands
    DANGEROUS_PATTERNS = [
        # Destructive file operations
        (r'\brm\s+(-[rf]+\s+)?/', "Removes files/directories"),
        (r'\brm\s+-rf', "Recursively removes files without confirmation"),
        (r'\bdd\b', "Direct disk access - can destroy data"),
        (r'\bmkfs\b', "Formats filesystem - destroys all data"),
        (r'\b>/dev/sd[a-z]', "Writes directly to disk - can destroy data"),
        (r'\bshred\b', "Securely deletes files"),
        (r'\bwipe\b', "Securely deletes files"),
        
        # System modifications
        (r'\bchmod\s+777', "Makes files world-writable"),
        (r'\bchown\s+.*root', "Changes ownership to root"),
        (r'\bsudo\s+rm', "Removes files with elevated privileges"),
        (r'\bsudo\s+dd', "Direct disk access with elevated privileges"),
        
        # Network/remote operations
        (r'\bcurl\s+.*\|\s*bash', "Executes remote script without review"),
        (r'\bwget\s+.*\|\s*bash', "Executes remote script without review"),
        (r'\bcurl\s+.*\|\s*sh', "Executes remote script without review"),
        (r'\bwget\s+.*\|\s*sh', "Executes remote script without review"),
        
        # Fork bombs and system stress
        (r':\(\)\s*\{.*:\|:', "Fork bomb - crashes system"),
        (r'\bkill\s+-9\s+1', "Kills init process - crashes system"),
        (r'\bkillall\b', "Kills all processes of a type"),
        
        # Privilege escalation
        (r'\bsu\s+-', "Switches to root user"),
        (r'\bsudo\s+su', "Switches to root user with sudo"),
        
        # Database operations
        (r'\bDROP\s+DATABASE\b', "Deletes entire database"),
        (r'\bDROP\s+TABLE\b', "Deletes database table"),
        (r'\bTRUNCATE\b', "Deletes all data from table"),
        (r'\bDELETE\s+FROM.*WHERE\s+1=1', "Deletes all rows from table"),
    ]
    
    # Patterns for moderately risky commands
    WARNING_PATTERNS = [
        (r'\brm\s+', "Deletes files"),
        (r'\bmv\s+.*\s+/', "Moves files"),
        (r'\bchmod\b', "Changes file permissions"),
        (r'\bchown\b', "Changes file ownership"),
        (r'\bsudo\b', "Executes with elevated privileges"),
        (r'\bapt-get\s+remove', "Removes packages"),
        (r'\byum\s+remove', "Removes packages"),
        (r'\bpip\s+uninstall', "Uninstalls Python packages"),
        (r'\bnpm\s+uninstall', "Uninstalls Node packages"),
        (r'\bgit\s+push\s+.*--force', "Force pushes to git repository"),
        (r'\bgit\s+reset\s+--hard', "Discards all uncommitted changes"),
        (r'\bdocker\s+rm', "Removes Docker containers"),
        (r'\bdocker\s+rmi', "Removes Docker images"),
    ]
    
    def __init__(self):
        """Initialize safety checker."""
        self.dangerous_compiled = [
            (re.compile(pattern, re.IGNORECASE), desc)
            for pattern, desc in self.DANGEROUS_PATTERNS
        ]
        self.warning_compiled = [
            (re.compile(pattern, re.IGNORECASE), desc)
            for pattern, desc in self.WARNING_PATTERNS
        ]
    
    def check_command(self, command: str) -> Tuple[str, List[str]]:
        """Check if command is dangerous.
        
        Args:
            command: Shell command to check
            
        Returns:
            Tuple of (severity, [descriptions])
            severity: "dangerous", "warning", or "safe"
            descriptions: List of matched warning descriptions
        """
        if not command or not command.strip():
            return ("safe", [])
        
        # Check for dangerous patterns
        dangerous_matches = []
        for pattern, desc in self.dangerous_compiled:
            if pattern.search(command):
                dangerous_matches.append(desc)
        
        if dangerous_matches:
            return ("dangerous", dangerous_matches)
        
        # Check for warning patterns
        warning_matches = []
        for pattern, desc in self.warning_compiled:
            if pattern.search(command):
                warning_matches.append(desc)
        
        if warning_matches:
            return ("warning", warning_matches)
        
        return ("safe", [])
    
    def get_warning_message(self, severity: str, descriptions: List[str]) -> str:
        """Generate warning message based on severity.
        
        Args:
            severity: "dangerous", "warning", or "safe"
            descriptions: List of matched warning descriptions
            
        Returns:
            Warning message string
        """
        if severity == "dangerous":
            warnings = ", ".join(descriptions)
            return f"⚠️  DANGEROUS: This command is potentially destructive! {warnings}. Review carefully before executing."
        elif severity == "warning":
            warnings = ", ".join(descriptions)
            return f"⚠️  Warning: {warnings}. Please review before executing."
        else:
            return ""
