# ShellAgent Project Plan

## Project Overview

ShellAgent is an intelligent shell command generator that bridges the gap between natural language and shell commands. It leverages Large Language Models (LLMs) to transform user descriptions into executable shell commands, making command-line operations more accessible and intuitive.

## Architecture

### Component Structure

```
shellagent/
├── shellagent.sh           # Core logic and LLM API integration
├── shellagent.plugin.zsh   # ZSH plugin wrapper and user interface
├── setup.sh                # Installation and setup script
├── README.md               # User documentation
├── STEPS.md                # Implementation guide
└── PLAN.md                 # This file - project architecture
```

### Core Components

#### 1. shellagent.sh (Standalone Script)
**Purpose**: Core command generation and execution engine

**Responsibilities**:
- Handle LLM API communication (OpenAI, Claude, Ollama)
- Parse natural language input
- Generate shell commands via LLM
- Display commands with colored output
- Handle user confirmation
- Execute confirmed commands safely

**Key Functions**:
- `call_openai()`: OpenAI API integration
- `call_claude()`: Anthropic Claude API integration
- `call_ollama()`: Local Ollama integration
- `main()`: Orchestrates the flow from input to execution

**Dependencies**:
- `curl`: HTTP requests to LLM APIs
- `jq`: JSON parsing
- `zsh`: Shell environment

#### 2. shellagent.plugin.zsh (ZSH Plugin)
**Purpose**: User-friendly interface and shell integration

**Responsibilities**:
- Provide convenient command aliases (`sa`, `sa!`)
- Implement interactive prompt mode
- Handle plugin initialization
- Provide command completion
- (Optional) Enable inline command expansion with `#!` prefix

**Key Functions**:
- `shellagent()`: Main wrapper function
- `_shellagent_read_and_execute()`: Interactive mode handler
- `shellagent_interactive()`: Direct interactive mode trigger
- `shellagent_hook_preexec()`: Inline expansion hook (optional)
- `_shellagent_completion()`: Auto-completion support

#### 3. setup.sh (Setup Utility)
**Purpose**: Simplify installation and configuration

**Responsibilities**:
- Make scripts executable
- Verify required dependencies
- Display configuration instructions
- Guide users through provider setup

## Data Flow

```
User Input → shellagent.plugin.zsh → shellagent.sh → LLM API
                                                         ↓
User Confirmation ← Display Commands ← Parse Response ←─┘
        ↓
    Execute
```

### Detailed Flow

1. **Input Phase**
   - User invokes `shellagent "description"` or `sa` (interactive)
   - Plugin validates and passes to core script

2. **Processing Phase**
   - Core script receives description
   - Selects appropriate LLM provider
   - Constructs API request with system prompt
   - Sends request to LLM API

3. **Response Phase**
   - Receives JSON response from API
   - Parses and extracts command text
   - Displays formatted commands to user

4. **Confirmation Phase**
   - Prompts user to review commands
   - Waits for y/n confirmation
   - Exits if declined

5. **Execution Phase**
   - Executes commands using `eval`
   - Displays success/failure message

## LLM Provider Support

### OpenAI
- **Default provider** for reliability and quality
- Models: `gpt-4o-mini` (fast, cheap), `gpt-4o` (high quality)
- API: Standard REST endpoint
- Authentication: Bearer token

### Claude (Anthropic)
- **Alternative provider** for different AI perspective
- Models: `claude-3-haiku-20240307` (fast), `claude-3-opus-20240229` (best)
- API: Anthropic-specific format
- Authentication: API key header

### Ollama
- **Local option** for privacy and offline use
- Models: Any locally installed (llama2, mistral, etc.)
- API: Local REST server
- Authentication: None required

## Configuration System

### Environment Variables

| Variable | Purpose | Default | Required |
|----------|---------|---------|----------|
| `SHELLAGENT_API_KEY` | LLM API authentication | None | Yes (except Ollama) |
| `SHELLAGENT_PROVIDER` | Which LLM to use | `openai` | No |
| `SHELLAGENT_MODEL` | Specific model name | `gpt-4o-mini` | No |
| `SHELLAGENT_API_BASE` | Custom API endpoint | OpenAI default | No |
| `SHELLAGENT_OLLAMA_HOST` | Ollama server URL | `http://localhost:11434` | No (Ollama only) |
| `SHELLAGENT_DEBUG` | Enable debug output | `0` | No |
| `SHELLAGENT_DIR` | Plugin installation path | Auto-detected | No |

### Configuration Loading
- Environment variables loaded at script startup
- Plugin auto-detects installation directory
- User configuration in `~/.zshrc`
- No persistent config file (environment-only)

## Security Model

### Safety Principles

1. **No Auto-Execution**
   - All commands require explicit user confirmation
   - Full command display before execution
   - Easy to decline (any key except 'y')

2. **Input Validation**
   - Validate API keys exist before requests
   - Check response parsing succeeds
   - Handle network errors gracefully

3. **Error Isolation**
   - Use `set -euo pipefail` for strict error handling
   - Exit cleanly on errors
   - No partial command execution

4. **Transparency**
   - Debug mode for full request/response visibility
   - Clear error messages
   - Colored output for easy scanning

### Known Limitations

- LLM may generate incorrect or dangerous commands
- User must review all commands before execution
- No command history or learning mechanism
- No syntax validation before execution
- Relies on user judgment for safety

## User Experience

### Usage Modes

1. **Direct Command Mode**
   ```bash
   shellagent "install nodejs"
   ```
   - Explicit, clear syntax
   - Good for scripting

2. **Interactive Mode**
   ```bash
   sa
   # Prompts for input
   ```
   - No quotes needed
   - More natural for exploration

3. **Quick Alias**
   ```bash
   sa "create backup"
   ```
   - Shortest syntax
   - Familiar to CLI users

4. **Inline Expansion** (Optional)
   ```bash
   #! install docker
   ```
   - Most experimental
   - Disabled by default

### Color Coding

- **Blue**: Informational messages
- **Yellow**: Generated commands (warning)
- **Green**: Success messages and command display
- **Red**: Error messages

## Extension Points

### Adding New LLM Providers

To add a new provider:

1. Create `call_<provider>()` function in `shellagent.sh`
2. Follow existing patterns for API calls
3. Parse response to extract command text
4. Add case to provider switch statement
5. Document in README.md

Example structure:
```bash
call_newprovider() {
    local prompt="$1"
    # API call logic
    # Response parsing
    echo "$extracted_command"
}
```

### Adding New Features

Potential extension points:
- Command history tracking
- Learning from feedback
- Context awareness (git repo, language, etc.)
- Multi-step workflows
- Dry-run simulation
- Shell syntax validation

## Testing Strategy

### Manual Testing Checklist

- [ ] OpenAI integration with valid key
- [ ] Claude integration with valid key
- [ ] Ollama integration with local server
- [ ] Interactive mode (`sa` without args)
- [ ] Direct mode (`sa "command"`)
- [ ] Alias functionality
- [ ] Error handling (missing key, bad network)
- [ ] User confirmation (accept/decline)
- [ ] Debug mode output
- [ ] Command execution
- [ ] Setup script
- [ ] Tab completion

### Provider-Specific Tests

Each provider should be tested with:
- Simple commands (e.g., "list files")
- Complex commands (e.g., "install and configure nginx")
- Piped commands (e.g., "find logs and compress them")
- Error conditions (invalid key, network failure)

## Development Workflow

### Making Changes

1. **Edit Code**
   - Modify `shellagent.sh` for core logic
   - Modify `shellagent.plugin.zsh` for UX
   - Update `README.md` for user-facing changes

2. **Test Locally**
   - Source plugin: `source shellagent.plugin.zsh`
   - Test all modes
   - Enable debug: `SHELLAGENT_DEBUG=1`

3. **Document**
   - Update README for new features
   - Update STEPS.md for implementation changes
   - Add inline comments for complex logic

### Debug Mode

Enable with `SHELLAGENT_DEBUG=1` to see:
- Full API requests
- Raw API responses
- Internal state
- Decision points

## Deployment

### Installation Methods

1. **Manual Installation**
   - Clone repository
   - Run `setup.sh`
   - Configure `~/.zshrc`

2. **Oh-My-Zsh Plugin**
   - Clone to plugins directory
   - Add to plugins array
   - Reload shell

### Updates

- Pull latest changes: `git pull`
- Reload shell: `exec zsh`
- No additional configuration needed

## Future Roadmap

### Short-term Enhancements
- Add more LLM providers (Google Gemini, etc.)
- Improve error messages
- Add command history
- Better completion suggestions

### Medium-term Features
- Context awareness (current directory, git status)
- Multi-step command planning
- Command validation before execution
- Configuration file support

### Long-term Vision
- Learning from user feedback
- Personalized command suggestions
- Integration with other tools
- Cross-shell support (bash, fish)
- Web interface for command generation

## Success Metrics

### User Adoption
- Easy installation (< 5 minutes)
- Clear documentation
- Multiple LLM options
- Safe by default

### User Satisfaction
- Accurate command generation
- Fast response time
- Intuitive interface
- Reliable execution

### Code Quality
- Minimal dependencies
- Clear error handling
- Well-documented
- Easy to extend

## Contributing

### Areas for Contribution
- New LLM provider integrations
- UI/UX improvements
- Documentation enhancements
- Bug fixes
- Performance optimizations
- Test coverage

### Guidelines
- Follow existing code style
- Test with multiple providers
- Update documentation
- Maintain backward compatibility
