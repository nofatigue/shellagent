# ShellAgent Installation Guide

This guide provides detailed installation instructions for ShellAgent.

## Quick Start

### Prerequisites

- **Python 3.8+** (for daemon mode)
- **ZSH** (for the shell plugin)
- **curl** and **jq** (for API communication)
- An API key from OpenAI, Anthropic, or a local Ollama installation

### Installation Steps

1. **Clone the repository:**
```bash
git clone https://github.com/nofatigue/shellagent
cd shellagent
```

2. **Install the daemon (recommended):**
```bash
cd daemon
pip install -e .
```

3. **Configure your API key:**
```bash
# Add to ~/.zshrc
export SHELLAGENT_API_KEY="your-api-key-here"
export SHELLAGENT_PROVIDER="openai"  # or "claude", "ollama"
export SHELLAGENT_MODEL="gpt-4o-mini"
```

4. **Install the ZSH plugin:**
```bash
# Add to ~/.zshrc
export SHELLAGENT_DIR="/path/to/shellagent"
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"
```

5. **Start the daemon:**
```bash
shell-assistant-daemon start
```

6. **Test it:**
```bash
exec zsh
sa "list files sorted by size"
```

## Detailed Installation

### Option 1: Daemon Mode (Recommended)

Daemon mode provides faster response times, better context awareness, and enhanced features.

#### Step 1: Install Python Dependencies

```bash
cd daemon
pip install -e .

# Verify installation
shell-assistant-daemon --help
```

#### Step 2: Configure API Access

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

Or use environment variables:

```bash
# Add to ~/.zshrc or ~/.bashrc
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_PROVIDER="openai"
export SHELLAGENT_MODEL="gpt-4o-mini"
```

#### Step 3: Install ZSH Plugin

Add to your `~/.zshrc`:

```bash
# ShellAgent Configuration
export SHELLAGENT_DIR="/path/to/shellagent"
export SHELLAGENT_MODE="auto"  # auto, daemon, or direct
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"
```

Reload your shell:
```bash
exec zsh
```

#### Step 4: Start the Daemon

**Foreground (for testing):**
```bash
shell-assistant-daemon start
```

**Background:**
```bash
nohup shell-assistant-daemon start > ~/.shell-assistant/daemon.log 2>&1 &
```

**As a system service (Linux/macOS):**
```bash
# Install service
sudo shell-assistant-daemon install-service  # Linux
# or
shell-assistant-daemon install-service  # macOS

# Enable and start
sudo systemctl enable shell-assistant  # Linux
sudo systemctl start shell-assistant   # Linux
# or
launchctl load ~/Library/LaunchAgents/com.shell-assistant.daemon.plist  # macOS
```

#### Step 5: Verify Installation

```bash
# Check daemon status
shell-assistant-daemon status

# Test with a prompt
shell-assistant-daemon test "show disk usage"

# Test ZSH plugin
sa "list files"
```

### Option 2: Direct Mode (Simple)

Direct mode is simpler but slower, calling the LLM API directly without a daemon.

#### Step 1: Make Script Executable

```bash
chmod +x shellagent.sh
```

#### Step 2: Configure API Access

Add to your `~/.zshrc`:

```bash
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_PROVIDER="openai"
export SHELLAGENT_MODEL="gpt-4o-mini"
export SHELLAGENT_MODE="direct"  # Force direct mode
```

#### Step 3: Install ZSH Plugin

Add to your `~/.zshrc`:

```bash
export SHELLAGENT_DIR="/path/to/shellagent"
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"
```

#### Step 4: Test

```bash
exec zsh
sa "list files"
```

## Provider-Specific Setup

### OpenAI

1. Get API key from https://platform.openai.com/api-keys
2. Configure:
```bash
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_PROVIDER="openai"
export SHELLAGENT_MODEL="gpt-4o-mini"  # or gpt-4o, gpt-3.5-turbo
```

### Claude (Anthropic)

1. Get API key from https://console.anthropic.com/
2. Configure:
```bash
export SHELLAGENT_API_KEY="sk-ant-..."
export SHELLAGENT_PROVIDER="claude"
export SHELLAGENT_MODEL="claude-3-haiku-20240307"  # or claude-3-sonnet, claude-3-opus
```

### Ollama (Local, Free)

1. Install Ollama from https://ollama.ai
2. Start Ollama server:
```bash
ollama serve
```
3. Pull a model:
```bash
ollama pull llama2
# or
ollama pull codellama
```
4. Configure:
```bash
export SHELLAGENT_PROVIDER="ollama"
export SHELLAGENT_MODEL="llama2"
export SHELLAGENT_OLLAMA_HOST="http://localhost:11434"
# No API key needed!
```

## oh-my-zsh Integration

### As a Custom Plugin

1. Clone into oh-my-zsh custom plugins:
```bash
git clone https://github.com/nofatigue/shellagent \
  ~/.oh-my-zsh/custom/plugins/shellagent
```

2. Add to plugins array in `~/.zshrc`:
```bash
plugins=(
  git
  # ... other plugins
  shellagent
)
```

3. Configure API keys in `~/.zshrc` (before oh-my-zsh is sourced):
```bash
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_PROVIDER="openai"
```

4. Reload:
```bash
exec zsh
```

## Verification

### Check Installation

```bash
# Check if plugin is loaded
type shellagent
type sa

# Check if daemon command is available (daemon mode)
which shell-assistant-daemon

# Check configuration
echo $SHELLAGENT_API_KEY  # Should show your API key (or part of it)
echo $SHELLAGENT_PROVIDER
echo $SHELLAGENT_MODE
```

### Test Functionality

```bash
# Test daemon (if using daemon mode)
shell-assistant-daemon status

# Test command generation
sa "list files sorted by size"

# Should see:
# 📝 Generated Command:
#    ls -lhS
# 💡 Explanation:
#    Lists files with sizes, sorted by size
# Action? [E]xecute / [C]opy / [Q]uit:
```

## Troubleshooting

### "Command not found: shell-assistant-daemon"

**Problem:** Daemon not in PATH

**Solutions:**
1. Ensure pip installation completed successfully:
```bash
cd daemon && pip install -e .
```

2. Check if it's installed:
```bash
which shell-assistant-daemon
```

3. Add pip binaries to PATH:
```bash
export PATH="$HOME/.local/bin:$PATH"
```

### "Failed to connect to daemon"

**Problem:** Daemon not running

**Solutions:**
1. Check if daemon is running:
```bash
shell-assistant-daemon status
```

2. Start the daemon:
```bash
shell-assistant-daemon start
```

3. Check if port is in use:
```bash
lsof -i :5738
```

4. Use direct mode instead:
```bash
export SHELLAGENT_MODE="direct"
```

### "SHELLAGENT_API_KEY not set"

**Problem:** API key not configured

**Solutions:**
1. Set in your shell config:
```bash
echo 'export SHELLAGENT_API_KEY="sk-..."' >> ~/.zshrc
source ~/.zshrc
```

2. Or create config file:
```bash
mkdir -p ~/.config/shell-assistant
cat > ~/.config/shell-assistant/config.yaml << EOF
openrouter:
  api_key: "sk-..."
  provider: "openai"
  model: "gpt-4o-mini"
EOF
```

### "Failed to parse API response"

**Problem:** Invalid API key or provider misconfiguration

**Solutions:**
1. Verify API key is correct
2. Check provider setting matches your key type
3. Test API access:
```bash
shell-assistant-daemon test "hello"
```
4. Enable debug mode:
```bash
export SHELLAGENT_DEBUG=1
```

### Plugin not loading

**Problem:** Plugin file not found or not sourced

**Solutions:**
1. Verify path is correct:
```bash
echo $SHELLAGENT_DIR
ls -la $SHELLAGENT_DIR/shellagent.plugin.zsh
```

2. Source the plugin:
```bash
source $SHELLAGENT_DIR/shellagent.plugin.zsh
```

3. Check for shell errors:
```bash
zsh -x ~/.zshrc
```

## Uninstallation

### Remove Daemon

```bash
# Stop daemon
pkill -f shell-assistant-daemon

# Uninstall service (if installed)
sudo shell-assistant-daemon uninstall-service  # Linux
# or
shell-assistant-daemon uninstall-service  # macOS

# Uninstall Python package
cd daemon
pip uninstall shell-assistant
```

### Remove Plugin

Remove from `~/.zshrc`:
```bash
# Remove these lines:
# export SHELLAGENT_DIR="..."
# source "$SHELLAGENT_DIR/shellagent.plugin.zsh"
```

Reload shell:
```bash
exec zsh
```

### Remove Configuration

```bash
rm -rf ~/.config/shell-assistant
rm -f ~/.shell-assistant/daemon.log
```

## Next Steps

After installation:

1. Read the [README.md](README.md) for usage instructions
2. Review the [daemon/README.md](daemon/README.md) for daemon-specific info
3. Check [PLAN.md](PLAN.md) and [STEPS.md](STEPS.md) for architecture details
4. Run tests: `cd daemon/tests && ./run_all_tests.sh`

## Getting Help

If you encounter issues:

1. Check this guide's troubleshooting section
2. Enable debug mode: `export SHELLAGENT_DEBUG=1`
3. Check daemon logs (if using daemon mode)
4. Review test output: `cd daemon/tests && ./run_all_tests.sh`
5. Open an issue on GitHub with:
   - Your OS and shell version
   - Installation method used
   - Full error messages
   - Output of `shell-assistant-daemon status` (if applicable)
