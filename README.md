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

## License

MIT - Feel free to use and modify!

## Contributing

Improvements welcome! Consider supporting additional providers or features.
