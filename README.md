# ShellAgent - LLM-Powered Shell Command Generator

A zsh plugin and daemon service that transforms natural language descriptions into executable shell commands using an LLM (OpenAI, Claude, Ollama, etc.).

## Architecture

ShellAgent can run in two modes:

1. **Daemon Mode (Recommended)** - A Python daemon service maintains persistent connections to LLM providers for faster response times and better context awareness
2. **Direct Mode** - Standalone shell script that calls the LLM API directly (simpler but slower)

The ZSH plugin automatically detects and uses the daemon if available, falling back to direct mode otherwise.

## Features

- 🤖 **Natural language to shell commands** - Describe what you want, get shell commands
- 🔒 **Safe execution** - Review commands before execution with warnings for dangerous operations
- 🎯 **Multiple LLM providers** - OpenAI, Claude, Ollama, and more
- ⚡ **Fast daemon mode** - Persistent connections for quick responses
- 🧠 **Context awareness** - Includes current directory, shell type, and OS in prompts
- 🎨 **Colored output** - Clear visual feedback
- 📋 **Interactive execution** - Execute, copy, or cancel commands easily

## Quick Start

### Option 1: Daemon Mode (Recommended)

1. **Install the daemon:**
```bash
cd daemon
pip install -e .
```

2. **Configure your API key:**
```bash
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_PROVIDER="openai"  # or "claude", "ollama"
export SHELLAGENT_MODEL="gpt-4o-mini"
```

3. **Start the daemon:**
```bash
shell-assistant-daemon start
```

4. **Add to your `~/.zshrc`:**
```bash
export SHELLAGENT_DIR="/path/to/shellagent"
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"
```

5. **Reload and test:**
```bash
exec zsh
sa "list files sorted by size"
```

### Option 2: Direct Mode (Simple)

1. **Add to your `~/.zshrc`:**
```bash
export SHELLAGENT_DIR="/path/to/shellagent"
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_PROVIDER="openai"
export SHELLAGENT_MODEL="gpt-4o-mini"
export SHELLAGENT_MODE="direct"  # Force direct mode
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"
```

2. **Make script executable:**
```bash
chmod +x "$SHELLAGENT_DIR/shellagent.sh"
```

3. **Reload and test:**
```bash
exec zsh
sa "list files sorted by size"
```

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/shellagent
cd shellagent
```

### 2. Install daemon (optional but recommended)
```bash
cd daemon
pip install -e .
```

### 3. Add to your zsh configuration

Add this to your `~/.zshrc`:

```bash
export SHELLAGENT_DIR="/path/to/shellagent"
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"

# For oh-my-zsh users, alternatively:
# Clone into oh-my-zsh plugins directory:
# git clone https://github.com/yourusername/shellagent ~/.oh-my-zsh/custom/plugins/shellagent
# Then add 'shellagent' to the plugins array in ~/.zshrc
# plugins=(... shellagent)
```

### 2. Configure your LLM provider

#### OpenAI (Default)
```bash
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_PROVIDER="openai"
export SHELLAGENT_MODEL="gpt-4o-mini"
```

#### Claude (Anthropic)
```bash
export SHELLAGENT_API_KEY="sk-ant-..."
export SHELLAGENT_PROVIDER="claude"
export SHELLAGENT_MODEL="claude-3-haiku-20240307"
```

#### Ollama (Local)
```bash
export SHELLAGENT_PROVIDER="ollama"
export SHELLAGENT_MODEL="llama2"  # or your preferred model
export SHELLAGENT_OLLAMA_HOST="http://localhost:11434"
# No API key needed for Ollama!
```

### 3. Start the daemon (if using daemon mode)

```bash
# Start in foreground
shell-assistant-daemon start

# Or start in background
shell-assistant-daemon start &

# Check status
shell-assistant-daemon status

# Test it
shell-assistant-daemon test "show disk usage"
```

## Usage Modes

ShellAgent supports multiple usage modes:

### Mode Configuration

Set `SHELLAGENT_MODE` to control behavior:
- `auto` (default) - Use daemon if available, fallback to direct mode
- `daemon` - Always use daemon (fails if daemon not running)
- `direct` - Always use direct script (no daemon)

```bash
export SHELLAGENT_MODE="auto"  # or "daemon" or "direct"
```

## Usage

### Basic Usage
```bash
# Simple command generation (with quotes)
shellagent "install python3 and pip"

# Shorter alias (with quotes)
sa "create a backup of my home directory"

# Interactive prompt mode (NO quotes needed!)
sa
# You'll see: 🤖 ShellAgent> 
# Then type: install python3 and pip

# Or use shellagent
shellagent
# Then type your request without quotes

# Alternative interactive mode
sa!
```

### Interactive Actions

After a command is generated, you'll see:
```
📝 Generated Command:
   du -sh * | sort -h

💡 Explanation:
   Shows disk usage of all items, sorted by size

Action? [E]xecute / [C]opy / [Q]uit:
```

- Press **E** to execute the command immediately
- Press **C** to copy to clipboard (requires pbcopy, xclip, or xsel)
- Press **Q** or any other key to cancel

If a command is potentially dangerous, you'll see a warning and need to confirm with "yes".

### Examples

```bash
# Install and setup
sa "install nodejs and initialize a new npm project"

# System administration
sa "check disk usage and list largest directories"

# Development
sa "create a Python virtual environment and install requests"

# File operations
sa "find all .log files modified in the last 7 days and compress them"

# Application deployment
sa "pull latest changes, install dependencies, run tests, and restart the service"
```

## Configuration

### Environment Variables

Core settings:
| Variable | Default | Description |
|----------|---------|-------------|
| `SHELLAGENT_API_KEY` | (required) | Your LLM API key |
| `SHELLAGENT_PROVIDER` | `openai` | LLM provider: `openai`, `claude`, `ollama` |
| `SHELLAGENT_MODEL` | `gpt-4o-mini` | Model name to use |
| `SHELLAGENT_MODE` | `auto` | Mode: `auto`, `daemon`, `direct` |

Daemon settings:
| Variable | Default | Description |
|----------|---------|-------------|
| `SHELLAGENT_DAEMON_HOST` | `localhost` | Daemon host |
| `SHELLAGENT_DAEMON_PORT` | `5738` | Daemon port |

Provider-specific:
| Variable | Default | Description |
|----------|---------|-------------|
| `SHELLAGENT_API_BASE` | OpenAI default | Custom API endpoint |
| `SHELLAGENT_OLLAMA_HOST` | `http://localhost:11434` | Ollama server address |
| `SHELLAGENT_DEBUG` | `0` | Set to `1` for debug output |

### Configuration File (Daemon Mode)

Create `~/.config/shell-assistant/config.yaml`:

```yaml
openrouter:
  api_key: ${SHELLAGENT_API_KEY}
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
