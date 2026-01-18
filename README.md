# ShellAgent - LLM-Powered Shell Command Generator

A zsh plugin and daemon service that transforms natural language descriptions into executable shell commands using an LLM (OpenAI, Claude, Ollama, etc.).

**🎯 Type what you want, get the command, execute it—that simple.**

## Features

- 🤖 **Natural language to shell commands** - Describe what you want, get shell commands
- 🔒 **Safe execution** - Review commands before execution with warnings for dangerous operations
- 🎯 **Multiple LLM providers** - OpenAI, Claude, Ollama, and more
- ⚡ **Fast daemon mode** - Persistent connections for quick responses
- 🧠 **Context awareness** - Includes current directory, shell type, and OS in prompts
- 🎨 **Colored output** - Clear visual feedback with severity levels
- 📋 **Interactive execution** - Execute, copy, or cancel commands easily
- 🔧 **System service** - Auto-start daemon with systemd/launchd

## Quick Start

### 5-Minute Setup

```bash
# 1. Clone and install
git clone https://github.com/nofatigue/shellagent
cd shellagent/daemon
pip install -e .

# 2. Configure (add to ~/.zshrc)
export SHELLAGENT_API_KEY="sk-..."      # Your OpenAI/Claude API key
export SHELLAGENT_PROVIDER="openai"     # or "claude", "ollama"
export SHELLAGENT_DIR="$HOME/shellagent"
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"

# 3. Start daemon
shell-assistant-daemon start

# 4. Try it!
exec zsh
sa "list files sorted by size"
```

📖 **For detailed installation:** See [INSTALLATION.md](INSTALLATION.md)

## Usage Examples

```bash
# Interactive mode (type without quotes)
sa
🤖 ShellAgent> find large files

# Or with quotes
sa "compress all log files older than 30 days"

# Daemon will show:
📝 Generated Command:
   find . -name "*.log" -mtime +30 -exec gzip {} \;
   
💡 Explanation:
   Finds log files older than 30 days and compresses them with gzip
   
Action? [E]xecute / [C]opy / [Q]uit: e
```

### More Examples

```bash
sa "show me the 10 largest files in this directory"
sa "create a Python virtual environment and install requests"
sa "find all TODO comments in Python files"
sa "git commit all changes with message 'update docs'"
sa "start a simple HTTP server on port 8000"
```

## Architecture

ShellAgent runs in two modes:

1. **Daemon Mode (Recommended)** - Python daemon maintains persistent LLM connections
   - Faster response times
   - Better context awareness
   - Safety checks for dangerous commands
   - System service integration

2. **Direct Mode** - Simple script calls LLM directly
   - No daemon required
   - Simpler setup
   - Good for testing

The ZSH plugin auto-detects the daemon and falls back to direct mode if unavailable.

## Installation

See [INSTALLATION.md](INSTALLATION.md) for detailed installation instructions including:
- Step-by-step setup for daemon mode
- Direct mode (no daemon) setup
- Provider-specific configuration (OpenAI, Claude, Ollama)
- oh-my-zsh integration
- Troubleshooting guide

## Configuration

### Quick Configuration

Add to `~/.zshrc`:

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SHELLAGENT_API_KEY` | (required) | Your LLM API key |
| `SHELLAGENT_PROVIDER` | `openai` | Provider: `openai`, `claude`, `ollama` |
| `SHELLAGENT_MODEL` | `gpt-4o-mini` | Model name |
| `SHELLAGENT_MODE` | `auto` | Mode: `auto`, `daemon`, `direct` |
| `SHELLAGENT_DAEMON_HOST` | `localhost` | Daemon host |
| `SHELLAGENT_DAEMON_PORT` | `5738` | Daemon port |

### Configuration File (Daemon)

Create `~/.config/shell-assistant/config.yaml`:

```yaml
openrouter:
  api_key: ${SHELLAGENT_API_KEY}
  model: "gpt-4o-mini"
  provider: "openai"

daemon:
  host: "localhost"
  port: 5738
```

See `config/config.example.yaml` for all options.

## Usage

## Usage

### Interactive Mode

```bash
sa
🤖 ShellAgent> find large files

# Shows:
📝 Generated Command:
   find . -type f -size +100M
   
💡 Explanation:
   Finds files larger than 100MB in current directory
   
Action? [E]xecute / [C]opy / [Q]uit:
```

### Direct Mode

```bash
sa "compress all log files"
shellagent "create Python virtual environment"
```

### Actions

After command generation:
- **E** - Execute immediately
- **C** - Copy to clipboard
- **Q** - Cancel

Dangerous commands require typing "yes" to confirm.

## Daemon Management

### Starting

```bash
# Foreground
shell-assistant-daemon start

# Background
nohup shell-assistant-daemon start > ~/.shell-assistant/daemon.log 2>&1 &

# As system service
sudo shell-assistant-daemon install-service  # Linux
shell-assistant-daemon install-service       # macOS
```

### Status & Testing

```bash
shell-assistant-daemon status
shell-assistant-daemon test "list files"
```

See [daemon/README.md](daemon/README.md) for more details.

## Safety Features

- **Command review** - All commands reviewed before execution
- **Danger detection** - 3 severity levels (safe/warning/dangerous)
- **Color coding** - Visual indicators for risk level
- **Confirmation prompts** - Required for destructive operations
- **Context awareness** - Commands aware of current directory and environment

## Testing

```bash
# Start daemon
shell-assistant-daemon start

# Run test suite
cd daemon/tests
./run_all_tests.sh
```

## Documentation

- [INSTALLATION.md](INSTALLATION.md) - Detailed installation guide
- [daemon/README.md](daemon/README.md) - Daemon service details
- [PLAN.md](PLAN.md) - Architecture design
- [STEPS.md](STEPS.md) - Implementation steps

## Troubleshooting

### Daemon not connecting
```bash
shell-assistant-daemon status  # Check if running
shell-assistant-daemon start   # Start it
export SHELLAGENT_MODE="direct"  # Or use direct mode
```

### API errors
```bash
echo $SHELLAGENT_API_KEY  # Verify key is set
export SHELLAGENT_DEBUG=1  # Enable debug mode
```

See [INSTALLATION.md](INSTALLATION.md) for complete troubleshooting guide.

## Project Structure

```
shellagent/
├── daemon/                  # Python daemon service
│   ├── shell_assistant/     # Core daemon code
│   └── tests/              # Test suite
├── config/                 # Configuration examples
├── shellagent.sh          # Direct mode script
├── shellagent.plugin.zsh  # ZSH plugin
├── INSTALLATION.md        # Installation guide
├── PLAN.md               # Architecture design
└── STEPS.md              # Implementation steps
```
  model: "gpt-4o-mini"
  base_url: "https://api.openai.com/v1"
  provider: "openai"

daemon:
  host: "localhost"
  port: 5738

preferences:
  auto_execute: false
  context_aware: true
  explain_commands: true
  max_tokens: 500
```

See `config/config.example.yaml` for a complete example.

## Daemon Management

### Starting the Daemon

```bash
# Start in foreground (see logs)
shell-assistant-daemon start

# Start in background
nohup shell-assistant-daemon start > ~/.shell-assistant/daemon.log 2>&1 &

# Start with custom host/port
shell-assistant-daemon start --host 0.0.0.0 --port 8080

# Start with custom config
shell-assistant-daemon start --config /path/to/config.yaml
```

### Checking Status

```bash
# Check if daemon is running
shell-assistant-daemon status

# Test with a prompt
shell-assistant-daemon test "list files"
```

### Stopping the Daemon

```bash
# If running in foreground, press Ctrl+C

# If running in background
pkill -f shell-assistant-daemon
```

## Safety Features

- **Confirmation required** - You review all commands before execution
- **Dangerous command warnings** - Detects potentially destructive operations
- **Context awareness** - Commands are generated with knowledge of your current directory and environment
- **Error handling** - Clear error messages for misconfiguration
- **API validation** - Checks for valid API keys and endpoints

## Testing

### Test the Daemon

The daemon includes a comprehensive test suite:

```bash
# Start the daemon
shell-assistant-daemon start

# In another terminal, run tests
cd daemon/tests
./run_all_tests.sh
```

Individual tests:
```bash
./test_health.sh      # Test health endpoint
./test_complete.sh    # Test command generation
./test_errors.sh      # Test error handling
```

### Manual Testing

```bash
# Test daemon directly
shell-assistant-daemon test "show disk usage"

# Test ZSH plugin
sa "list files"
```

## Getting API Keys

### OpenAI
1. Go to https://platform.openai.com/api-keys
2. Create new secret key
3. Use `gpt-4o-mini` for cost-effective option or `gpt-4o` for better quality

### Claude (Anthropic)
1. Go to https://console.anthropic.com/
2. Generate new API key
3. Use `claude-3-haiku-20240307` for fast/cheap or `claude-3-opus-20240229` for best quality

### Ollama (Free, Local)
1. Install from https://ollama.ai
2. Run `ollama serve` in one terminal
3. Pull a model: `ollama pull llama2`
4. No API key needed!

## Troubleshooting

### "SHELLAGENT_API_KEY not set"
Make sure you've set your API key:
```bash
export SHELLAGENT_API_KEY="your-key-here"
```

### "Failed to parse API response"
- Check your API key is valid
- Check your provider is set correctly
- If debugging, enable debug mode: `export SHELLAGENT_DEBUG="1"`

### Plugin not loading
- Verify the path to `shellagent.plugin.zsh` is correct
- Check that `SHELLAGENT_DIR` is set
- Reload zsh: `exec zsh`

### Daemon not connecting
- Check if daemon is running: `shell-assistant-daemon status`
- Start the daemon: `shell-assistant-daemon start`
- Check daemon logs if running in background
- Verify port 5738 is not in use: `lsof -i :5738`

### Commands not executing
- Check that the generated commands are safe
- Verify all required tools are installed
- Review the commands carefully before confirming execution

### "Failed to connect to daemon"
- Ensure daemon is running: `shell-assistant-daemon status`
- Check firewall settings
- Try direct mode: `export SHELLAGENT_MODE="direct"`

## Development

### Project Structure

```
shellagent/
├── daemon/                      # Python daemon service
│   ├── shell_assistant/
│   │   ├── __init__.py
│   │   ├── cli.py              # CLI entry point
│   │   ├── config.py           # Configuration management
│   │   ├── llm_client.py       # LLM API client
│   │   └── server.py           # HTTP server
│   ├── tests/                  # Test scripts
│   │   ├── run_all_tests.sh
│   │   ├── test_health.sh
│   │   ├── test_complete.sh
│   │   └── test_errors.sh
│   ├── pyproject.toml
│   └── README.md
├── config/
│   └── config.example.yaml     # Example configuration
├── shellagent.sh               # Direct mode script
├── shellagent.plugin.zsh       # ZSH plugin
├── setup.sh                    # Setup script
├── PLAN.md                     # Architecture design
├── STEPS.md                    # Implementation steps
└── README.md                   # This file
```

### Contributing

To modify or extend shellagent:

1. **For daemon changes:**
   - Edit files in `daemon/shell_assistant/`
   - Test with `shell-assistant-daemon start`
   - Run test suite: `cd daemon/tests && ./run_all_tests.sh`

2. **For ZSH plugin changes:**
   - Edit `shellagent.plugin.zsh`
   - Test with: `source shellagent.plugin.zsh && sa "test"`

3. **For direct mode changes:**
   - Edit `shellagent.sh`
   - Test with: `SHELLAGENT_MODE=direct sa "test"`

### Running Tests

```bash
# Install daemon
cd daemon && pip install -e .

# Start daemon
shell-assistant-daemon start

# Run tests (in another terminal)
cd daemon/tests
./run_all_tests.sh
```

## License

MIT - Feel free to use and modify!

## Contributing

Improvements welcome! Consider supporting additional providers or features.
