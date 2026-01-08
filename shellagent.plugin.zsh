# ShellAgent ZSH Plugin
# Add special syntax support to zsh for LLM-powered commands

# Make the main script executable and discoverable
if [[ -z "$SHELLAGENT_DIR" ]]; then
    export SHELLAGENT_DIR="${0:h}"
fi

# Create alias for easy access
alias sa='shellagent'

# Function to handle comments with special prefix
# Usage: shellagent "#install python and create a test script"
# Or: sa "#install python and create a test script"
shellagent() {
    local script_path="${SHELLAGENT_DIR}/shellagent.sh"
    
    if [[ ! -f "$script_path" ]]; then
        echo "Error: shellagent.sh not found at $script_path" >&2
        echo "Set SHELLAGENT_DIR to the directory containing shellagent.sh" >&2
        return 1
    fi
    
    # Pass all arguments to the shell script
    bash "$script_path" "$@"
}

# Interactive mode: type 'sa!' to open an interactive prompt
shellagent_interactive() {
    local description
    
    read -p "Describe what you want to do: " description
    
    if [[ -n "$description" ]]; then
        shellagent "$description"
    fi
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
