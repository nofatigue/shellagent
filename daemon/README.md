# Shell Assistant Daemon

Python daemon service for the Shell Assistant plugin that maintains persistent connections to LLM providers.

## Installation

```bash
cd daemon
pip install -e .
```

## Configuration

Create `~/.config/shell-assistant/config.yaml`:

```yaml
openrouter:
  api_key: ${OPENROUTER_API_KEY}
  model: "anthropic/claude-3.5-sonnet"
  base_url: "https://openrouter.ai/api/v1"
  provider: "openai"  # or "claude", "ollama"

daemon:
  host: "localhost"
  port: 5738

preferences:
  auto_execute: false
  context_aware: true
  explain_commands: true
  max_tokens: 500
```

Or use environment variables:
```bash
export SHELLAGENT_API_KEY="your-api-key"
export SHELLAGENT_PROVIDER="openai"  # or "claude", "ollama"
export SHELLAGENT_MODEL="gpt-4o-mini"
```

## Usage

### Start the daemon
```bash
shell-assistant-daemon start
```

### Check daemon status
```bash
shell-assistant-daemon status
```

### Test with a prompt
```bash
shell-assistant-daemon test "show disk usage"
```

## API Endpoints

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "model": "gpt-4o-mini",
  "provider": "openai",
  "connected": true
}
```

### POST /complete
Generate shell command from natural language prompt.

**Request:**
```json
{
  "prompt": "show disk usage",
  "cwd": "/home/user",
  "shell": "zsh",
  "os": "Linux"
}
```

**Response:**
```json
{
  "command": "du -sh * | sort -h",
  "explanation": "Shows disk usage of all items in current directory, sorted by size"
}
```

## Development

### Install dependencies
```bash
pip install -e ".[dev]"
```

### Run tests
```bash
# Start daemon in one terminal
shell-assistant-daemon start

# Run tests in another terminal
cd tests
./run_all_tests.sh
```

## Testing

The `tests/` directory contains shell scripts for testing the daemon:

- `test_health.sh` - Tests the health endpoint
- `test_complete.sh` - Tests command generation
- `test_errors.sh` - Tests error handling
- `run_all_tests.sh` - Runs all tests

Make sure the daemon is running before executing tests.
