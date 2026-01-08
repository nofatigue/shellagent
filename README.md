# ShellAgent - LLM-Powered Shell Command Generator

A zsh plugin and standalone script that transforms natural language descriptions into executable shell commands using an LLM (OpenAI, Claude, Ollama, etc.).

## Features

- 🤖 **Natural language to shell commands** - Describe what you want, get shell commands
- 🔒 **Safe execution** - Review commands before execution
- 🎯 **Multiple LLM providers** - OpenAI, Claude, Ollama, and more
- ⚡ **Easy integration** - Works as a zsh plugin or standalone script
- 🎨 **Colored output** - Clear visual feedback

## Installation

### 1. Add to your zsh configuration

Add this to your `~/.zshrc`:

```bash
# Option A: If you cloned shellagent to a specific location
export SHELLAGENT_DIR="/home/user/code/shellagent"
source "$SHELLAGENT_DIR/shellagent.plugin.zsh"

# Option B: If using oh-my-zsh
# Clone into oh-my-zsh plugins directory:
# git clone https://github.com/yourusername/shellagent ~/.oh-my-zsh/custom/plugins/shellagent
# Then add 'shellagent' to the plugins array in ~/.zshrc
plugins=(... shellagent)
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
```

### 3. Make scripts executable
```bash
chmod +x /home/user/code/shellagent/shellagent.sh
```

## Usage

### Basic Usage
```bash
# Simple command generation
shellagent "install python3 and pip"

# Shorter alias
sa "create a backup of my home directory"

# Interactive mode
sa!
```

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

### Enable Inline Expansion (Optional)

For more experimental inline expansion where you can prefix commands with `#!`:

Edit `shellagent.plugin.zsh` and uncomment:
```bash
add-zsh-hook preexec shellagent_hook_preexec
```

Then you can type:
```bash
#! install docker and run hello-world container
```

And it will be expanded to actual commands.

## Configuration

Set these environment variables in your `~/.zshrc`:

| Variable | Default | Description |
|----------|---------|-------------|
| `SHELLAGENT_API_KEY` | (required) | Your LLM API key |
| `SHELLAGENT_PROVIDER` | `openai` | LLM provider: `openai`, `claude`, `ollama` |
| `SHELLAGENT_MODEL` | `gpt-4o-mini` | Model name to use |
| `SHELLAGENT_API_BASE` | OpenAI default | Custom API endpoint |
| `SHELLAGENT_OLLAMA_HOST` | `http://localhost:11434` | Ollama server address |
| `SHELLAGENT_DEBUG` | `0` | Set to `1` for debug output |

### Example Configuration

Add to `~/.zshrc`:
```bash
# ShellAgent Configuration
export SHELLAGENT_DIR="/home/user/code/shellagent"
export SHELLAGENT_PROVIDER="openai"
export SHELLAGENT_API_KEY="sk-..."
export SHELLAGENT_MODEL="gpt-4o-mini"

# Optional: Enable debug mode
# export SHELLAGENT_DEBUG="1"

source "$SHELLAGENT_DIR/shellagent.plugin.zsh"
```

## Standalone Usage

You can also use the script directly without sourcing the plugin:

```bash
# Set required environment variables
export SHELLAGENT_API_KEY="your-api-key"
export SHELLAGENT_PROVIDER="openai"

# Run directly
bash /path/to/shellagent.sh "your description"
```

## Safety Features

- **Confirmation required** - You review all commands before execution
- **Error handling** - Clear error messages for misconfiguration
- **API validation** - Checks for valid API keys and endpoints

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

### Commands not executing
- Check that the generated commands are safe
- Verify all required tools are installed
- Review the commands carefully before confirming execution

## Development

To modify or extend shellagent:

1. Edit `shellagent.sh` for the main logic
2. Edit `shellagent.plugin.zsh` for zsh integration
3. Test with: `SHELLAGENT_DEBUG="1" shellagent "test description"`

## License

MIT - Feel free to use and modify!

## Contributing

Improvements welcome! Consider supporting additional providers or features.
