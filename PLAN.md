# Shell Assistant Plugin - Design Plan

## Architecture Overview

**Components:**
1. **Daemon Service** (Python recommended)
2. **ZSH Plugin** (Shell script)
3. **Communication Layer** (Unix socket or HTTP)

## Technology Recommendations

### Daemon Service: **Python**
**Why Python:**
- Excellent HTTP client libraries (`httpx`, `requests`)
- Easy async support for maintaining persistent connections
- Simple daemon/service creation
- Great JSON handling
- Cross-platform compatibility
- Rich ecosystem for API integrations

**Alternative:** Go (if you want a single binary with no dependencies, but Python is faster to develop)

### Communication: **Unix Domain Socket**
**Why:**
- Fast local IPC
- No network overhead
- Automatic cleanup
- Secure (filesystem permissions)

## Detailed Design

### 1. Daemon Service (`shell-assistant-daemon`)

**Responsibilities:**
- Maintain persistent/pooled connections to OpenRouter
- Expose local API (Unix socket)
- Manage conversation context (optional)
- Handle rate limiting and retries
- Log requests/responses

**API Endpoints:**
```
POST /complete
  Body: { "prompt": "Show me disk usage", "shell": "zsh", "cwd": "/path" }
  Response: { "command": "du -sh * | sort -h", "explanation": "..." }

GET /health
  Response: { "status": "ok", "model": "...", "connected": true }

POST /configure
  Body: { "model": "...", "api_key": "..." }
```

**Key Features:**
- System prompt engineering: Include shell type, OS, current directory
- Command validation/safety checks
- Multi-turn context (optional: remember previous commands in session)

### 2. ZSH Plugin

**Responsibilities:**
- Bind `sa!` to trigger assistant mode
- Capture user input
- Send to daemon API
- Display results with syntax highlighting
- Allow user to:
  - Execute command directly (press Enter)
  - Edit command (press 'e')
  - Copy to clipboard (press 'c')
  - Ask follow-up (press 'f')
  - Cancel (press Esc/Ctrl+C)

**Widget Implementation:**
```bash
sa-assistant-widget() {
  # Capture input after sa!
  # Call daemon API
  # Display formatted result
  # Handle user interaction
}

zle -N sa-assistant-widget
bindkey '^[!' sa-assistant-widget  # Alt+! or custom binding
```

### 3. Configuration

**~/.config/shell-assistant/config.yaml:**
```yaml
daemon:
  socket: /tmp/shell-assistant.sock
  
openrouter:
  api_key: ${OPENROUTER_API_KEY}
  model: "anthropic/claude-3.5-sonnet"
  base_url: "https://openrouter.ai/api/v1"
  
preferences:
  auto_execute: false  # Require confirmation
  context_aware: true  # Send cwd, recent history
  explain_commands: true
  max_tokens: 500
```

## Implementation Plan

### Phase 1: Core Daemon (Week 1)
- [ ] Set up Python project structure
- [ ] Implement OpenRouter client
- [ ] Create Unix socket server
- [ ] Implement `/complete` endpoint
- [ ] Add configuration loading
- [ ] Create systemd/launchd service files

### Phase 2: ZSH Plugin (Week 1-2)
- [ ] Create basic ZSH widget
- [ ] Implement `sa!` trigger
- [ ] Add API client (curl/http calls)
- [ ] Display formatted results
- [ ] Add interactive command selection

### Phase 3: Enhancement (Week 2-3)
- [ ] Add conversation context
- [ ] Implement command history
- [ ] Add safety checks (dangerous commands)
- [ ] Syntax highlighting
- [ ] Error handling and retries
- [ ] Add alternative LLM providers

### Phase 4: Polish (Week 3-4)
- [ ] Documentation
- [ ] Installation script
- [ ] Unit tests
- [ ] Performance optimization
- [ ] Package for distribution (pip, brew, oh-my-zsh)

## Project Structure

```
shell-assistant/
├── daemon/
│   ├── shell_assistant/
│   │   ├── __init__.py
│   │   ├── server.py          # Unix socket server
│   │   ├── llm_client.py      # OpenRouter integration
│   │   ├── prompt_builder.py  # System prompt engineering
│   │   └── config.py          # Configuration management
│   ├── pyproject.toml
│   ├── README.md
│   └── shell-assistant.service  # systemd service
│
├── zsh-plugin/
│   ├── shell-assistant.plugin.zsh
│   ├── functions/
│   │   ├── _sa_widget
│   │   ├── _sa_api_call
│   │   └── _sa_display
│   └── README.md
│
├── config/
│   └── config.example.yaml
│
└── docs/
    ├── installation.md
    ├── configuration.md
    └── development.md
```

## Key Design Decisions

### Prompt Engineering Strategy
```
System Prompt Template:
"You are a shell command assistant for {shell} on {os}.
Current directory: {cwd}
User request: {prompt}

Provide a single command that accomplishes the task.
Include brief explanation if complex.
Consider safety and ask for confirmation if destructive.
Current shell aliases: {aliases}"
```

### Safety Features
1. **Dangerous command detection**: `rm -rf`, `dd`, `mkfs`, etc.
2. **Confirmation prompts**: For destructive operations
3. **Dry-run suggestions**: Offer `--dry-run` flags when available
4. **Explanation**: Always explain what command does

### User Experience
- Fast response time (<500ms for daemon communication)
- Syntax highlighting for commands
- Easy to execute or modify
- Visual feedback (spinner while waiting)
- Graceful degradation if daemon is down

## Next Steps

1. **Choose your starting point**: Daemon or ZSH plugin?
   - I recommend: Start with daemon (it's the core)
   
2. **Set up development environment**:
   - Python virtual environment
   - ZSH for testing
   - OpenRouter API key

3. **Create MVP**: Simple version with just `sa!` → command response