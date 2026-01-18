"""Command-line interface for shell assistant daemon."""

import click
import logging
import sys

from .config import Config
from .server import ShellAssistantServer


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


@click.group()
def main():
    """Shell Assistant Daemon - LLM-powered command generation service."""
    pass


@main.command()
@click.option("--host", default="localhost", help="Host to bind to")
@click.option("--port", default=5738, type=int, help="Port to bind to")
@click.option("--config", default=None, help="Path to config file")
def start(host, port, config):
    """Start the shell assistant daemon."""
    try:
        # Load configuration
        cfg = Config(config)
        
        # Override host/port if specified
        if host:
            cfg.set("daemon.host", host)
        if port:
            cfg.set("daemon.port", port)
        
        # Validate API key is set
        api_key = cfg.get("openrouter.api_key")
        if not api_key:
            logger.error("API key not configured!")
            logger.error("Set SHELLAGENT_API_KEY or OPENROUTER_API_KEY environment variable")
            logger.error("Or create config file at ~/.config/shell-assistant/config.yaml")
            sys.exit(1)
        
        # Create and start server
        server = ShellAssistantServer(
            cfg,
            host=cfg.get("daemon.host"),
            port=cfg.get("daemon.port")
        )
        
        click.echo(f"🚀 Starting Shell Assistant Daemon...")
        click.echo(f"   Host: {cfg.get('daemon.host')}")
        click.echo(f"   Port: {cfg.get('daemon.port')}")
        click.echo(f"   Provider: {cfg.get('openrouter.provider')}")
        click.echo(f"   Model: {cfg.get('openrouter.model')}")
        click.echo(f"\n✨ Daemon is ready! Press Ctrl+C to stop.\n")
        
        server.start()
        
    except KeyboardInterrupt:
        click.echo("\n\n👋 Goodbye!")
    except Exception as e:
        logger.error(f"Failed to start daemon: {e}")
        sys.exit(1)


@main.command()
def status():
    """Check daemon status."""
    import httpx
    
    try:
        with httpx.Client(timeout=2.0) as client:
            response = client.get("http://localhost:5738/health")
            response.raise_for_status()
            data = response.json()
            
            click.echo("✅ Daemon is running")
            click.echo(f"   Status: {data.get('status')}")
            click.echo(f"   Provider: {data.get('provider')}")
            click.echo(f"   Model: {data.get('model')}")
            
    except httpx.ConnectError:
        click.echo("❌ Daemon is not running")
        click.echo("   Start with: shell-assistant-daemon start")
        sys.exit(1)
    except Exception as e:
        click.echo(f"❌ Error checking status: {e}")
        sys.exit(1)


@main.command()
@click.argument("prompt")
def test(prompt):
    """Test the daemon with a prompt."""
    import httpx
    
    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.post(
                "http://localhost:5738/complete",
                json={"prompt": prompt}
            )
            response.raise_for_status()
            result = response.json()
            
            click.echo("\n📝 Generated Command:")
            click.echo(f"   {result.get('command')}")
            if 'explanation' in result:
                click.echo(f"\n💡 Explanation:")
                click.echo(f"   {result.get('explanation')}")
            if 'warning' in result:
                click.echo(f"\n⚠️  Warning:")
                click.echo(f"   {result.get('warning')}")
            click.echo()
            
    except httpx.ConnectError:
        click.echo("❌ Daemon is not running")
        click.echo("   Start with: shell-assistant-daemon start")
        sys.exit(1)
    except Exception as e:
        click.echo(f"❌ Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
