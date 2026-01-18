# Shell Assistant - Development Steps

## MVP (v0.1) - Basic Command Generation
**Goal:** Type `sa!` in shell, get a command from LLM, execute it manually

### Testable Goals
- ✅ Daemon starts and listens on Unix socket
- ✅ ZSH plugin triggers on `sa!` input
- ✅ User can type a prompt after `sa!`
- ✅ Daemon sends prompt to OpenRouter and gets response
- ✅ Command is displayed in terminal
- ✅ User can copy/paste and execute command manually

### Implementation Steps

#### 1. Daemon Setup (Days 1-2)
```bash
# Create project structure
mkdir -p shell-assistant/daemon/shell_assistant
cd shell-assistant/daemon
```

**Tasks:**
- [ ] Create `pyproject.toml` with dependencies: `httpx`, `pyyaml`, `click`
- [ ] Create `shell_assistant/__init__.py`
- [ ] Create `shell_assistant/config.py`
  - Load config from `~/.config/shell-assistant/config.yaml`
  - Environment variable support for API key
- [ ] Create `shell_assistant/llm_client.py`
  - Simple OpenRouter API client
  - Method: `get_command(prompt: str) -> dict`
  - Return format: `{"command": "...", "explanation": "..."}`
- [ ] Create `shell_assistant/server.py`
  - HTTP server using `http.server` (simple for MVP)
  - Listen on `http://localhost:5738`
  - Endpoint: `POST /complete`
  - Accept JSON: `{"prompt": "..."}`
  - Return JSON: `{"command": "...", "explanation": "..."}`
- [ ] Create `shell_assistant/cli.py`
  - Entry point: `shell-assistant-daemon start`
  - Start server, handle Ctrl+C gracefully

**Test:**
```bash
# Terminal 1: Start daemon
python -m shell_assistant.cli start

# Terminal 2: Test with curl
curl -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": "show disk usage"}'

# Expected: {"command": "du -sh *", "explanation": "Shows disk usage..."}
```

#### 1.5 Test Scripts for Daemon (Day 2)
**Tasks:**
- [ ] Create `daemon/tests/test_health.sh`
  - Test daemon health endpoint
  - Verify daemon is running
  - Exit code 0 if healthy, 1 if not
- [ ] Create `daemon/tests/test_complete.sh`
  - Test /complete endpoint with various prompts
  - Verify JSON response format
  - Check for required fields
- [ ] Create `daemon/tests/test_errors.sh`
  - Test error handling (invalid JSON, missing fields, API failures)
  - Verify appropriate error responses
- [ ] Create `daemon/tests/run_all_tests.sh`
  - Master test script that runs all tests
  - Reports pass/fail for each test
  - Overall test summary

**Test Scripts:**

**tests/test_health.sh:**
```bash
#!/bin/bash
set -e

echo "Testing daemon health..."

# Check if daemon is running
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5738/health)

if [ "$response" = "200" ]; then
    echo "✅ Health check passed"
    exit 0
else
    echo "❌ Health check failed (HTTP $response)"
    exit 1
fi
```

**tests/test_complete.sh:**
```bash
#!/bin/bash
set -e

echo "Testing /complete endpoint..."

# Test 1: Simple prompt
echo "  Test 1: Simple disk usage prompt"
response=$(curl -s -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": "show disk usage"}')

# Check if response contains required fields
if echo "$response" | jq -e '.command' > /dev/null && \
   echo "$response" | jq -e '.explanation' > /dev/null; then
    echo "  ✅ Response has required fields"
else
    echo "  ❌ Response missing required fields"
    echo "  Response: $response"
    exit 1
fi

# Test 2: Complex prompt
echo "  Test 2: Complex git prompt"
response=$(curl -s -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": "create a new git branch called feature/test"}')

if echo "$response" | jq -e '.command' > /dev/null; then
    command=$(echo "$response" | jq -r '.command')
    if [[ "$command" == *"git"* ]]; then
        echo "  ✅ Git command generated correctly"
    else
        echo "  ⚠️  Command doesn't contain 'git': $command"
    fi
else
    echo "  ❌ Failed to generate command"
    exit 1
fi

echo "✅ All /complete tests passed"
```

**tests/test_errors.sh:**
```bash
#!/bin/bash

echo "Testing error handling..."

# Test 1: Invalid JSON
echo "  Test 1: Invalid JSON"
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d 'invalid json')

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
    echo "  ✅ Correctly rejected invalid JSON (HTTP $http_code)"
else
    echo "  ❌ Should reject invalid JSON (got HTTP $http_code)"
fi

# Test 2: Missing required field
echo "  Test 2: Missing prompt field"
response=$(curl -s -w "\n%{http_code}" -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"wrong_field": "value"}')

http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "400" ] || [ "$http_code" = "422" ]; then
    echo "  ✅ Correctly rejected missing field (HTTP $http_code)"
else
    echo "  ❌ Should reject missing field (got HTTP $http_code)"
fi

# Test 3: Empty prompt
echo "  Test 3: Empty prompt"
response=$(curl -s -X POST http://localhost:5738/complete \
  -H "Content-Type: application/json" \
  -d '{"prompt": ""}')

# Should either reject or handle gracefully
if echo "$response" | jq -e '.error' > /dev/null 2>&1; then
    echo "  ✅ Handled empty prompt with error message"
elif echo "$response" | jq -e '.command' > /dev/null 2>&1; then
    echo "  ⚠️  Accepted empty prompt (may want to validate)"
fi

echo "✅ Error handling tests completed"
```

**tests/run_all_tests.sh:**
```bash
#!/bin/bash

echo "=========================================="
echo "Shell Assistant Daemon - Test Suite"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

total_tests=0
passed_tests=0
failed_tests=0

run_test() {
    local test_name=$1
    local test_script=$2
    
    total_tests=$((total_tests + 1))
    echo ""
    echo "Running: $test_name"
    echo "----------------------------------------"
    
    if bash "$test_script"; then
        echo -e "${GREEN}✅ PASSED${NC}: $test_name"
        passed_tests=$((passed_tests + 1))
    else
        echo -e "${RED}❌ FAILED${NC}: $test_name"
        failed_tests=$((failed_tests + 1))
    fi
}

# Check if daemon is running
if ! curl -s http://localhost:5738/health > /dev/null 2>&1; then
    echo -e "${RED}❌ Daemon is not running!${NC}"
    echo "Please start the daemon first:"
    echo "  python -m shell_assistant.cli start"
    exit 1
fi

# Run all tests
run_test "Health Check" "tests/test_health.sh"
run_test "Complete Endpoint" "tests/test_complete.sh"
run_test "Error Handling" "tests/test_errors.sh"

# Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total:  $total_tests"
echo -e "${GREEN}Passed: $passed_tests${NC}"
if [ $failed_tests -gt 0 ]; then
    echo -e "${RED}Failed: $failed_tests${NC}"
else
    echo -e "${GREEN}Failed: $failed_tests${NC}"
fi
echo ""

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
```

**Make scripts executable:**
```bash
chmod +x daemon/tests/*.sh
```

**Usage:**
```bash
# Run all tests
./daemon/tests/run_all_tests.sh

# Run individual test
./daemon/tests/test_health.sh
./daemon/tests/test_complete.sh
./daemon/tests/test_errors.sh
```

#### 2. ZSH Plugin (Days 2-3)
```bash
# Create plugin structure
mkdir -p shell-assistant/zsh-plugin
```

**Tasks:**
- [ ] Create `zsh-plugin/shell-assistant.plugin.zsh`
  - Define `sa-prompt()` function
  - Read user input with `vared`
  - Call daemon using `curl`
  - Parse JSON response (use `jq` or plain `grep`)
  - Print command and explanation
- [ ] Create alias/binding for `sa!`
  - Use ZSH's `alias -s` or key binding
  - Trigger `sa-prompt` function

**Code:**
```bash
# shell-assistant.plugin.zsh
sa-prompt() {
  echo -n "Shell Assistant> "
  read prompt
  
  response=$(curl -s -X POST http://localhost:5738/complete \
    -H "Content-Type: application/json" \
    -d "{\"prompt\": \"$prompt\"}")
  
  command=$(echo $response | grep -o '"command":"[^"]*"' | cut -d'"' -f4)
  explanation=$(echo $response | grep -o '"explanation":"[^"]*"' | cut -d'"' -f4)
  
  echo "\n📝 Command:"
  echo "  $command"
  echo "\n💡 Explanation:"
  echo "  $explanation"
  echo ""
}

alias sa!='sa-prompt'
```

**Test:**
```bash
# In ZSH terminal
source zsh-plugin/shell-assistant.plugin.zsh
sa!
# Prompt: show disk usage
# Expect: Command and explanation printed
```

#### 3. Configuration (Day 3)
**Tasks:**
- [ ] Create `config/config.example.yaml`
- [ ] Document environment variables
- [ ] Create install script for config

**config.example.yaml:**
```yaml
openrouter:
  api_key: ${OPENROUTER_API_KEY}
  model: "anthropic/claude-3.5-sonnet"
  base_url: "https://openrouter.ai/api/v1"

daemon:
  host: "localhost"
  port: 5738
```

### MVP Acceptance Test
1. Start daemon: `shell-assistant-daemon start`
2. Source plugin: `source ~/.zsh/plugins/shell-assistant/shell-assistant.plugin.zsh`
3. Type: `sa!`
4. Enter: `"show me largest files in current directory"`
5. See command: `du -ah . | sort -rh | head -20`
6. Copy and execute command
7. Success ✅

---

## v0.2 - Interactive Execution
**Goal:** Execute commands directly from the plugin, add basic safety checks

### Testable Goals
- ✅ After displaying command, prompt user: [E]xecute, [C]opy, [Q]uit
- ✅ 'E' executes the command immediately
- ✅ 'C' copies to clipboard (if available)
- ✅ Dangerous commands show warning before execution
- ✅ Command history is saved locally

### Implementation Steps

#### 1. Enhanced ZSH Plugin (Days 4-5)
**Tasks:**
- [ ] Add interactive prompt after displaying command
- [ ] Implement execute option
  - Use `eval` to run command
  - Display output
- [ ] Implement copy option
  - Try `pbcopy` (macOS), `xclip` (Linux), or `clip` (Windows)
  - Fallback: just select text
- [ ] Add command history
  - Save to `~/.shell-assistant/history.json`
  - Format: `[{"timestamp": "...", "prompt": "...", "command": "..."}]`

**Code:**
```bash
sa-prompt() {
  echo -n "Shell Assistant> "
  read prompt
  
  # ... get response ...
  
  echo "\n📝 Command: $command"
  echo "💡 Explanation: $explanation"
  echo ""
  echo -n "Action? [E]xecute / [C]opy / [Q]uit: "
  read -k 1 action
  echo ""
  
  case $action in
    e|E)
      echo "Executing..."
      eval $command
      ;;
    c|C)
      echo $command | pbcopy 2>/dev/null || echo $command | xclip -selection clipboard 2>/dev/null
      echo "Copied to clipboard!"
      ;;
    *)
      echo "Cancelled"
      ;;
  esac
}
```

#### 2. Safety Checks in Daemon (Day 5-6)
**Tasks:**
- [ ] Create `shell_assistant/safety.py`
  - Define dangerous patterns: `rm -rf`, `dd`, `mkfs`, `:(){ :|:& };:`
  - Method: `is_dangerous(command: str) -> tuple[bool, str]`
  - Return: `(True, "This command will delete files")` or `(False, "")`
- [ ] Update `/complete` endpoint
  - Check command safety
  - Add `"warning": "..."` field if dangerous
- [ ] Update ZSH plugin to show warnings
  - Display warning in red
  - Require explicit confirmation (type "yes")

**Test:**
```bash
sa!
# Prompt: delete all files
# Expected: Warning message, require "yes" to execute
```

### v0.2 Acceptance Test
1. **Run test suite:** `./daemon/tests/run_all_tests.sh` - all tests pass ✅
2. Type: `sa!`
3. Enter: `"list all running docker containers"`
4. See command: `docker ps`
5. Press: `E` (Execute)
6. See: Docker container list
7. Type: `sa!`
8. Enter: `"remove all docker images"`
9. See: Warning about dangerous operation
10. Must type: `"yes"` to confirm
11. Success ✅

---

## v0.3 - Context Awareness & Polish
**Goal:** Make commands smarter with context, add better UX

### Testable Goals
- ✅ Daemon includes current directory in prompt to LLM
- ✅ Daemon includes OS/shell type in prompt
- ✅ Commands are syntax-highlighted in terminal
- ✅ Loading spinner shows while waiting for LLM
- ✅ Error messages are user-friendly
- ✅ Daemon can be installed as system service

### Implementation Steps

#### 1. Context-Aware Prompts (Days 7-8)
**Tasks:**
- [ ] Create `shell_assistant/prompt_builder.py`
  - Build system prompt with context
  - Include: OS, shell, cwd, current user
- [ ] Update ZSH plugin to send context
  - Modify API call to include: `{"prompt": "...", "cwd": "$PWD", "shell": "zsh"}`
- [ ] Update daemon to use context
  - Build richer system prompt for LLM

**System Prompt Template:**
```
You are a shell command assistant.

Context:
- OS: {os_name} ({os_version})
- Shell: {shell}
- Current directory: {cwd}
- User: {user}

User request: {prompt}

Provide a single, executable command that accomplishes this task.
Be concise. Include brief explanation only if complex.
If the command is destructive, mention it.

Respond in JSON format:
{
  "command": "the exact command to run",
  "explanation": "brief explanation",
  "warning": "optional warning for dangerous commands"
}
```

#### 2. Better UX (Days 8-9)
**Tasks:**
- [ ] Add loading spinner to ZSH plugin
  - Show "⠋ Thinking..." animation while waiting
  - Use ZSH background jobs
- [ ] Add syntax highlighting
  - Use `bat` if available, or basic ANSI colors
  - Highlight command differently from explanation
- [ ] Improve error messages
  - Handle daemon offline gracefully
  - Show helpful message: "Daemon not running. Start with: shell-assistant-daemon start"
  - Handle API errors from OpenRouter

**Code:**
```bash
# Spinner function
show-spinner() {
  local pid=$1
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  while kill -0 $pid 2>/dev/null; do
    i=$(( (i+1) %10 ))
    printf "\r${spin:$i:1} Thinking..."
    sleep 0.1
  done
  printf "\r"
}
```

#### 3. System Service (Day 10)
**Tasks:**
- [ ] Create `daemon/shell-assistant.service` (systemd)
- [ ] Create `daemon/com.shell-assistant.plist` (launchd for macOS)
- [ ] Add install/uninstall commands to CLI
  - `shell-assistant-daemon install-service`
  - `shell-assistant-daemon uninstall-service`
- [ ] Auto-start daemon on shell initialization

**systemd service:**
```ini
[Unit]
Description=Shell Assistant Daemon
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/shell-assistant-daemon start
Restart=always

[Install]
WantedBy=default.target
```

#### 4. Health Check (Day 10)
**Tasks:**
- [ ] Add `GET /health` endpoint
- [ ] ZSH plugin checks health before prompt
- [ ] Auto-start daemon if not running (optional)

### v0.3 Acceptance Test
1. **Run test suite:** `./daemon/tests/run_all_tests.sh` - all tests pass ✅
2. Install service: `shell-assistant-daemon install-service`
3. Reboot/re-login
4. Daemon is running automatically
5. Type: `sa!`
6. See: Loading spinner
7. Enter: `"compress this folder"`
8. See: Context-aware command (uses actual folder name)
9. See: Syntax-highlighted output
10. Command works correctly for current directory
11. Test error: Stop daemon, try `sa!`
12. See: User-friendly error message
13. Success ✅

---

## Success Metrics

### MVP (v0.1)
- [ ] Can generate command from natural language
- [ ] Less than 3 seconds response time
- [ ] 80%+ of generated commands are correct

### v0.2
- [ ] Can execute commands with 1 keystroke
- [ ] Dangerous commands always show warnings
- [ ] Command history persists between sessions

### v0.3
- [ ] Commands are context-aware (use actual file/directory names)
- [ ] Daemon starts automatically on system boot
- [ ] Graceful error handling in 100% of failure cases
- [ ] Professional UX (spinner, colors, formatting)

---

## Development Timeline

| Version | Duration | Focus |
|---------|----------|-------|
| v0.1 MVP | 3 days | Core functionality |
| v0.2 | 3 days | Interactive execution & safety |
| v0.3 | 4 days | Context & polish |
| **Total** | **10 days** | **End-to-end working system** |

---

## Testing Checklist

### After Each Version
- [ ] Run automated test suite: `./daemon/tests/run_all_tests.sh`
- [ ] Manual testing of all features
- [ ] Test on clean environment
- [ ] Test error cases (daemon down, API failure, network issues)
- [ ] Document any bugs in GitHub issues
- [ ] Update README with current capabilities
- [ ] Tag release in git: `git tag v0.X`

### Adding New Tests
As you develop new features, add corresponding test scripts:
- Create `tests/test_<feature>.sh` for each major feature
- Add the test to `run_all_tests.sh`
- Ensure tests are idempotent (can run multiple times)
- Include both positive and negative test cases
