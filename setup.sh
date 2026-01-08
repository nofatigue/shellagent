#!/bin/bash
# ShellAgent Quick Setup

set -e

SHELLAGENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 ShellAgent Quick Setup"
echo "=========================="
echo ""

# Make scripts executable
chmod +x "$SHELLAGENT_DIR/shellagent.sh"

echo "✅ Made shellagent.sh executable"
echo ""

# Check for curl and jq
if ! command -v curl &> /dev/null; then
    echo "❌ curl is required. Install with: apt-get install curl (or brew install curl)"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq is required. Install with: apt-get install jq (or brew install jq)"
    exit 1
fi

echo "✅ curl and jq are installed"
echo ""

# Show configuration instructions
echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. Choose your LLM provider:"
echo ""
echo "   OpenAI (Recommended for most users):"
echo "   - Get API key from: https://platform.openai.com/api-keys"
echo "   - Add to ~/.zshrc:"
echo "       export SHELLAGENT_API_KEY='sk-...'"
echo "       export SHELLAGENT_PROVIDER='openai'"
echo "       export SHELLAGENT_MODEL='gpt-4o-mini'"
echo ""
echo "   Claude:"
echo "   - Get API key from: https://console.anthropic.com/"
echo "   - Add to ~/.zshrc:"
echo "       export SHELLAGENT_API_KEY='sk-ant-...'"
echo "       export SHELLAGENT_PROVIDER='claude'"
echo "       export SHELLAGENT_MODEL='claude-3-haiku-20240307'"
echo ""
echo "   Ollama (Free, local - no API key needed):"
echo "   - Install from: https://ollama.ai"
echo "   - Add to ~/.zshrc:"
echo "       export SHELLAGENT_PROVIDER='ollama'"
echo "       export SHELLAGENT_MODEL='llama2'"
echo ""

echo "2. Add to ~/.zshrc:"
echo ""
echo "   export SHELLAGENT_DIR='$SHELLAGENT_DIR'"
echo "   source \$SHELLAGENT_DIR/shellagent.plugin.zsh"
echo ""

echo "3. Reload zsh:"
echo ""
echo "   exec zsh"
echo ""

echo "4. Test it:"
echo ""
echo "   shellagent \"install curl\""
echo "   # or shorter:"
echo "   sa \"create a test file\""
echo ""

echo "For more information, see README.md"
