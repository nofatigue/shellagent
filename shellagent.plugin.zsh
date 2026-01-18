# ShellAgent ZSH Plugin
# Add special syntax support to zsh for LLM-powered commands

# Make the main script executable and discoverable
if [[ -z "$SHELLAGENT_DIR" ]]; then
    export SHELLAGENT_DIR="${0:h}"
fi

# Configuration
SHELLAGENT_MODE="${SHELLAGENT_MODE:-auto}"  # auto, daemon, direct
SHELLAGENT_DAEMON_HOST="${SHELLAGENT_DAEMON_HOST:-localhost}"
SHELLAGENT_DAEMON_PORT="${SHELLAGENT_DAEMON_PORT:-5738}"

# Create alias for easy access
alias sa='shellagent'

# Check if daemon is available
_shellagent_check_daemon() {
    curl -s -o /dev/null -w "%{http_code}" "http://${SHELLAGENT_DAEMON_HOST}:${SHELLAGENT_DAEMON_PORT}/health" 2>/dev/null | grep -q "200"
}

# Call daemon API
_shellagent_call_daemon() {
    local prompt="$1"
    local cwd="$PWD"
    local shell_type="$SHELL"
    local os_type="$(uname)"
    
    # Build JSON payload with proper escaping using jq
    local json_payload=$(jq -n \
        --arg prompt "$prompt" \
        --arg cwd "$cwd" \
        --arg shell "$shell_type" \
        --arg os "$os_type" \
        '{prompt: $prompt, cwd: $cwd, shell: $shell, os: $os}')
    
    # Call daemon
    local response=$(curl -s -X POST "http://${SHELLAGENT_DAEMON_HOST}:${SHELLAGENT_DAEMON_PORT}/complete" \
        -H "Content-Type: application/json" \
        -d "$json_payload" 2>&1)
    
    if [[ $? -ne 0 ]]; then
        echo "❌ Failed to connect to daemon" >&2
        return 1
    fi
    
    # Parse response
    local command=$(echo "$response" | jq -r '.command' 2>/dev/null)
    local explanation=$(echo "$response" | jq -r '.explanation' 2>/dev/null)
    local warning=$(echo "$response" | jq -r '.warning' 2>/dev/null)
    local severity=$(echo "$response" | jq -r '.severity' 2>/dev/null)
    
    if [[ -z "$command" || "$command" == "null" ]]; then
        echo "❌ Failed to generate command" >&2
        echo "Response: $response" >&2
        return 1
    fi
    
    # Display results
    echo ""
    echo -e "\033[1;33m📝 Generated Command:\033[0m"
    
    # Color code based on severity
    if [[ "$severity" == "dangerous" ]]; then
        echo -e "\033[1;31m$command\033[0m"  # Bright red for dangerous
    elif [[ "$severity" == "warning" ]]; then
        echo -e "\033[0;33m$command\033[0m"  # Yellow for warning
    else
        echo -e "\033[0;32m$command\033[0m"  # Green for safe
    fi
    
    if [[ -n "$explanation" && "$explanation" != "null" ]]; then
        echo ""
        echo -e "\033[1;34m💡 Explanation:\033[0m"
        echo "   $explanation"
    fi
    
    if [[ -n "$warning" && "$warning" != "null" ]]; then
        echo ""
        echo -e "\033[1;31m$warning\033[0m"
    fi
    
    echo ""
    echo -n "Action? [E]xecute / [C]opy / [Q]uit: "
    read -k 1 action
    echo ""
    
    case $action in
        e|E)
            if [[ "$severity" == "dangerous" ]]; then
                echo -e "\033[1;31m⚠️  DANGER: This command is potentially destructive!\033[0m"
                echo -n "Type 'yes' to confirm execution: "
                read confirm
                if [[ "$confirm" != "yes" ]]; then
                    echo "Cancelled"
                    return 0
                fi
            elif [[ -n "$warning" && "$warning" != "null" ]]; then
                echo -n "⚠️  Confirm execution (y/n): "
                read -k 1 confirm
                echo ""
                if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
                    echo "Cancelled"
                    return 0
                fi
            fi
            echo "Executing..."
            eval "$command"
            ;;
        c|C)
            if command -v pbcopy &> /dev/null; then
                echo "$command" | pbcopy
                echo "✅ Copied to clipboard (pbcopy)"
            elif command -v xclip &> /dev/null; then
                echo "$command" | xclip -selection clipboard
                echo "✅ Copied to clipboard (xclip)"
            elif command -v xsel &> /dev/null; then
                echo "$command" | xsel --clipboard
                echo "✅ Copied to clipboard (xsel)"
            else
                echo "Command: $command"
                echo "(No clipboard tool available)"
            fi
            ;;
        *)
            echo "Cancelled"
            ;;
    esac
}

# Function to handle comments with special prefix
# Usage: shellagent "install python and create a test script"
# Or: sa "install python and create a test script"
# Or: sa (without arguments to enter interactive prompt mode)
shellagent() {
    # If no arguments provided, enter interactive prompt mode
    if [[ $# -eq 0 ]]; then
        _shellagent_read_and_execute
        return $?
    fi
    
    local prompt="$@"
    
    # Determine which mode to use
    local use_daemon=false
    
    if [[ "$SHELLAGENT_MODE" == "daemon" ]]; then
        use_daemon=true
    elif [[ "$SHELLAGENT_MODE" == "auto" ]]; then
        if _shellagent_check_daemon; then
            use_daemon=true
        fi
    fi
    
    # Use daemon if available
    if [[ "$use_daemon" == "true" ]]; then
        _shellagent_call_daemon "$prompt"
        return $?
    fi
    
    # Fallback to direct script
    local script_path="${SHELLAGENT_DIR}/shellagent.sh"
    
    if [[ ! -f "$script_path" ]]; then
        echo "❌ Error: Neither daemon nor direct script available" >&2
        echo "   - Start daemon: shell-assistant-daemon start" >&2
        echo "   - Or check SHELLAGENT_DIR is set correctly" >&2
        return 1
    fi
    
    "$script_path" "$prompt"
}

# Helper function to read user input and execute
_shellagent_read_and_execute() {
    local description
    
    # Display prompt indicator
    read -r "description?🤖 ShellAgent> "
    
    if [[ -n "$description" ]]; then
        shellagent "$description"
    fi
}

# Interactive mode: type 'sa!' to open an interactive prompt
shellagent_interactive() {
    _shellagent_read_and_execute
}

alias 'sa!'='shellagent_interactive'

# Function to expand inline comments
# This is more experimental - intercepts commands with #! prefix
# Usage: type a command like: #! install nodejs
# And it will be expanded to actual commands before execution
shellagent_hook_preexec() {
    local cmd="$1"
    
    # Check if command starts with #!
    if [[ "$cmd" =~ ^#!(.+)$ ]]; then
        local description="${BASH_REMATCH[1]}"
        echo "Processing: $description" >&2
        shellagent "$description"
        return
    fi
}

# Optional: Enable the preexec hook if you want inline expansion
# Uncomment the next line if you want #! to trigger LLM expansion
# add-zsh-hook preexec shellagent_hook_preexec

# Setup completion for shellagent
_shellagent_completion() {
    local -a common_tasks=(
        "install packages"
        "create file"
        "setup project"
        "install and configure"
        "run tests"
        "build project"
        "deploy application"
    )
    
    _describe 'task' common_tasks
}

compdef _shellagent_completion shellagent
compdef _shellagent_completion sa
