# ShellAgent Implementation Steps

This document outlines the implementation steps and architecture of the ShellAgent project.

## Overview

ShellAgent is a zsh plugin that transforms natural language descriptions into executable shell commands using LLM APIs (OpenAI, Claude, Ollama). It provides both a standalone script and zsh plugin integration.

## Implementation Steps

### 1. Core Script Implementation (shellagent.sh)

#### 1.1 Configuration Setup
- Define configuration variables for API keys, models, and providers
- Set default values for `SHELLAGENT_API_KEY`, `SHELLAGENT_MODEL`, `SHELLAGENT_API_BASE`, and `SHELLAGENT_PROVIDER`
- Implement debug mode flag (`SHELLAGENT_DEBUG`)

#### 1.2 Utility Functions
- `debug()`: Output debug messages when debug mode is enabled
- `error()`: Display error messages in red and exit
- `info()`: Display informational messages in blue
- `success()`: Display success messages in green

#### 1.3 LLM Provider Integration

##### OpenAI Integration (`call_openai`)
- Validate API key is set
- Construct JSON payload with:
  - System prompt instructing the model to return only shell commands
  - User prompt with the natural language description
  - Temperature set to 0.3 for consistent results
- Make HTTP POST request to OpenAI API endpoint
- Parse response using `jq` to extract command content
- Handle errors gracefully

##### Claude Integration (`call_claude`)
- Validate API key is set
- Construct JSON payload for Anthropic's API format:
  - System message as separate field
  - User message with description
  - Max tokens limit set to 1024
- Make HTTP POST request to Claude API endpoint
- Parse response to extract text from content array
- Handle errors gracefully

##### Ollama Integration (`call_ollama`)
- Support local Ollama installation (no API key needed)
- Use configurable host URL (`SHELLAGENT_OLLAMA_HOST`)
- Construct prompt with system instructions inline
- Make HTTP POST request to Ollama generate endpoint
- Parse response to extract generated text
- Handle errors gracefully

#### 1.4 Main Execution Flow
- Accept natural language description as argument
- Validate input is provided
- Display "Generating commands" message
- Call appropriate LLM provider based on `SHELLAGENT_PROVIDER`
- Display generated commands in yellow/green
- Prompt user for confirmation (y/n)
- Execute commands using `eval` if confirmed
- Display success message

### 2. ZSH Plugin Implementation (shellagent.plugin.zsh)

#### 2.1 Environment Setup
- Auto-detect plugin directory if `SHELLAGENT_DIR` not set
- Create `sa` alias for `shellagent` command

#### 2.2 Main Function Wrapper
- Implement `shellagent()` function that:
  - Validates script path exists
  - Handles no-argument case for interactive mode
  - Passes arguments to main script

#### 2.3 Interactive Mode
- Implement `_shellagent_read_and_execute()` helper:
  - Display "🤖 ShellAgent>" prompt
  - Read user input
  - Execute shellagent script with input
- Create `sa!` alias for direct interactive mode

#### 2.4 Preexec Hook (Optional)
- Implement `shellagent_hook_preexec()` for inline expansion
- Detect commands starting with `#!` prefix
- Extract description and pass to shellagent
- Hook is commented out by default for safety

#### 2.5 Completion Support
- Implement `_shellagent_completion()` function
- Provide common task suggestions:
  - "install packages"
  - "create file"
  - "setup project"
  - "install and configure"
  - "run tests"
  - "build project"
  - "deploy application"
- Register completion for both `shellagent` and `sa` commands

### 3. Setup Script Implementation (setup.sh)

#### 3.1 Auto-configuration
- Detect script directory
- Make main script executable (`chmod +x`)
- Validate required dependencies (curl, jq)

#### 3.2 User Guidance
- Display setup instructions for each provider:
  - OpenAI: API key location and example config
  - Claude: API key location and example config
  - Ollama: Installation instructions (no API key needed)
- Show zshrc configuration example
- Provide testing commands

### 4. Safety Features

#### 4.1 Command Review
- Always display generated commands before execution
- Require explicit user confirmation (y/n)
- Exit safely if user declines

#### 4.2 Error Handling
- Validate API keys are set before making requests
- Check API response parsing succeeds
- Provide clear error messages for common issues:
  - Missing API key
  - Invalid API response
  - Network errors
  - Missing dependencies

#### 4.3 Security Considerations
- Never auto-execute commands without confirmation
- Use `set -euo pipefail` for safe script execution
- Escape special characters in API requests

### 5. Testing and Validation

#### 5.1 Manual Testing
```bash
# Test with different providers
export SHELLAGENT_PROVIDER="openai"
shellagent "list all files"

# Test interactive mode
sa
# Then type: install curl

# Test alias
sa "create a test directory"

# Test debug mode
SHELLAGENT_DEBUG=1 sa "show disk usage"
```

#### 5.2 Provider-Specific Testing
- Test OpenAI with valid/invalid API keys
- Test Claude with valid/invalid API keys
- Test Ollama with server running/not running
- Test each provider with various command types:
  - Simple commands (list files)
  - Complex commands (install and configure)
  - Piped commands (find and process)

### 6. Documentation

#### 6.1 README.md
- Feature overview
- Installation instructions
- Configuration examples for each provider
- Usage examples
- Troubleshooting guide

#### 6.2 Inline Documentation
- Comment complex logic
- Document function parameters
- Explain provider-specific quirks

## Key Design Decisions

1. **Multiple Provider Support**: Designed to be provider-agnostic with a simple switch statement
2. **Safety First**: Always require confirmation before executing commands
3. **User Experience**: Interactive mode for natural command entry without quotes
4. **Extensibility**: Easy to add new providers by implementing a new `call_*` function
5. **Minimal Dependencies**: Only requires curl and jq, both widely available

## Future Enhancements

- Add more LLM providers (e.g., Google Gemini, local models)
- Command history and learning from user feedback
- Context awareness (current directory, environment)
- Multi-step command planning
- Dry-run mode to see commands without execution
- Configuration file support (~/.shellagentrc)
- Shell script validation before execution
