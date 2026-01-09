#!/bin/zsh
# ShellAgent - LLM-powered shell command generator
# Usage: shellagent "description of what you want to do"
# Or enable the plugin for special syntax support

set -euo pipefail

# Configuration
SHELLAGENT_API_KEY="${SHELLAGENT_API_KEY:-}"
SHELLAGENT_MODEL="${SHELLAGENT_MODEL:-gpt-4o-mini}"
SHELLAGENT_API_BASE="${SHELLAGENT_API_BASE:-https://api.openai.com/v1}"
SHELLAGENT_PROVIDER="${SHELLAGENT_PROVIDER:-openai}"  # openai, claude, ollama, etc.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Debug mode
SHELLAGENT_DEBUG="${SHELLAGENT_DEBUG:-0}"

debug() {
    if [[ $SHELLAGENT_DEBUG == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

error() {
    echo -e "${RED}[ERROR] $*${NC}" >&2
    exit 1
}

info() {
    echo -e "${BLUE}[INFO] $*${NC}" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS] $*${NC}" >&2
}

# Function to call OpenAI API
call_openai() {
    local prompt="$1"
    
    [[ -z "$SHELLAGENT_API_KEY" ]] && error "SHELLAGENT_API_KEY not set. Set it with: export SHELLAGENT_API_KEY='your-key-here'"
    
    debug "Calling OpenAI API with model: $SHELLAGENT_MODEL"
    
    local response
    response=$(curl -s -X POST "$SHELLAGENT_API_BASE/chat/completions" \
        -H "Authorization: Bearer $SHELLAGENT_API_KEY" \
        -H "Content-Type: application/json" \
        -d @- <<EOF
{
    "model": "$SHELLAGENT_MODEL",
    "messages": [
        {
            "role": "system",
            "content": "You are a helpful shell command assistant. When given a natural language description, respond with ONLY the shell commands needed to accomplish the task. No explanations, no markdown code blocks, just the raw shell commands. If multiple commands are needed, put each on a new line or use && or | as appropriate."
        },
        {
            "role": "user",
            "content": "$prompt"
        }
    ],
    "temperature": 0.3
}
EOF
)
    
    debug "API Response: $response"
    
    # Extract the command from the response
    echo "$response" | jq -r '.choices[0].message.content' 2>/dev/null || error "Failed to parse API response"
}

# Function to call Claude API
call_claude() {
    local prompt="$1"
    
    [[ -z "$SHELLAGENT_API_KEY" ]] && error "SHELLAGENT_API_KEY not set for Claude. Set it with: export SHELLAGENT_API_KEY='your-claude-key'"
    
    debug "Calling Claude API with model: $SHELLAGENT_MODEL"
    
    local response
    response=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
        -H "x-api-key: $SHELLAGENT_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "Content-Type: application/json" \
        -d @- <<EOF
{
    "model": "$SHELLAGENT_MODEL",
    "max_tokens": 1024,
    "messages": [
        {
            "role": "user",
            "content": "$prompt"
        }
    ],
    "system": "You are a helpful shell command assistant. When given a natural language description, respond with ONLY the shell commands needed to accomplish the task. No explanations, no markdown code blocks, just the raw shell commands."
}
EOF
)
    
    debug "API Response: $response"
    
    # Extract the command from the response
    echo "$response" | jq -r '.content[0].text' 2>/dev/null || error "Failed to parse Claude API response"
}

# Function to call Ollama (local)
call_ollama() {
    local prompt="$1"
    local ollama_host="${SHELLAGENT_OLLAMA_HOST:-http://localhost:11434}"
    
    debug "Calling Ollama at $ollama_host with model: $SHELLAGENT_MODEL"
    
    local response
    response=$(curl -s -X POST "$ollama_host/api/generate" \
        -H "Content-Type: application/json" \
        -d @- <<EOF
{
    "model": "$SHELLAGENT_MODEL",
    "prompt": "You are a shell command assistant. Respond with ONLY the shell commands needed. No explanation.\n\n$prompt",
    "stream": false
}
EOF
)
    
    debug "API Response: $response"
    
    # Extract the response
    echo "$response" | jq -r '.response' 2>/dev/null || error "Failed to parse Ollama response"
}

# Main function
main() {
    local description="$1"
    
    [[ -z "$description" ]] && error "Usage: shellagent \"description of what you want to do\""
    
    info "Generating commands for: $description"
    
    # Call the appropriate API
    local commands
    case "$SHELLAGENT_PROVIDER" in
        openai)
            commands=$(call_openai "$description")
            ;;
        claude)
            commands=$(call_claude "$description")
            ;;
        ollama)
            commands=$(call_ollama "$description")
            ;;
        *)
            error "Unknown provider: $SHELLAGENT_PROVIDER"
            ;;
    esac
    
    debug "Generated commands:\n$commands"
    
    # Display commands and ask for confirmation
    echo ""
    echo -e "${YELLOW}Generated commands:${NC}"
    echo -e "${GREEN}$commands${NC}"
    echo ""
    
    # Ask for confirmation
    read "confirm?Execute these commands? (y/n) "
    echo ""
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && {
        error "Cancelled by user"
    }
    echo ""
    
    # Execute the commands
    eval "$commands"
    
    success "Done!"
}

# Run main function with all arguments
main "$@"
