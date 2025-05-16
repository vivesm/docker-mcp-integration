#!/bin/bash
# Setup script for Docker MCP integration with Claude
# This script automates the setup process for integrating Docker with Claude via MCP

# Exit on any error
set -e

# Print colorful messages
function print_message() {
  local color="\033[0;32m"  # Green
  local nc="\033[0m"  # No color
  echo -e "${color}$1${nc}"
}

function print_error() {
  local color="\033[0;31m"  # Red
  local nc="\033[0m"  # No color
  echo -e "${color}ERROR: $1${nc}"
}

function print_warning() {
  local color="\033[0;33m"  # Yellow
  local nc="\033[0m"  # No color
  echo -e "${color}WARNING: $1${nc}"
}

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
  print_error "Docker is not installed. Please install Docker first."
  exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
  print_error "npm is not installed. Please install Node.js and npm first."
  exit 1
fi

print_message "Starting Docker MCP integration setup..."

# Step 1: Set up Docker Socket Proxy
print_message "\n1. Setting up Docker Socket Proxy..."

# Check if the container already exists
if docker ps -a | grep -q "docker-socket-proxy"; then
  print_warning "Docker Socket Proxy container already exists."
  
  # Check if it's running
  if ! docker ps | grep -q "docker-socket-proxy"; then
    print_message "Starting existing Docker Socket Proxy container..."
    docker start docker-socket-proxy
  else
    print_message "Docker Socket Proxy container is already running."
  fi
else
  print_message "Creating new Docker Socket Proxy container..."
  docker run -d --restart=always --name=docker-socket-proxy \
    -p 2375:2375 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    alpine/socat \
    tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
fi

# Test the connection
print_message "Testing Docker Socket Proxy connection..."
if curl -s http://localhost:2375/version > /dev/null; then
  print_message "Docker Socket Proxy is working correctly."
else
  print_error "Docker Socket Proxy is not working properly. Please check Docker setup."
  exit 1
fi

# Step 2: Install MCP Server Kubernetes package
print_message "\n2. Installing MCP Server Kubernetes package..."

# Check if already installed
if npm list -g mcp-server-kubernetes 2>/dev/null | grep -q "mcp-server-kubernetes"; then
  print_message "MCP Server Kubernetes package is already installed."
else
  print_message "Installing MCP Server Kubernetes package globally..."
  npm install -g mcp-server-kubernetes
fi

# Verify installation
if ! command -v mcp-server-kubernetes &> /dev/null; then
  print_error "MCP Server Kubernetes installation failed. Check npm setup."
  exit 1
fi

print_message "MCP Server Kubernetes is properly installed."

# Step 3: Configure Claude
print_message "\n3. Configuring Claude..."

# Check for Claude Code
CLAUDE_CODE_CONFIG_DIR="$HOME/.claude-code"
CLAUDE_CODE_CONFIG_FILE="$CLAUDE_CODE_CONFIG_DIR/config.json"

# Create directory if it doesn't exist
if [ ! -d "$CLAUDE_CODE_CONFIG_DIR" ]; then
  print_message "Creating Claude Code configuration directory..."
  mkdir -p "$CLAUDE_CODE_CONFIG_DIR"
fi

# Check if config file exists
if [ -f "$CLAUDE_CODE_CONFIG_FILE" ]; then
  print_message "Claude Code configuration file exists. Checking MCP configuration..."
  
  # Check if docker MCP is already configured
  if grep -q '"docker"' "$CLAUDE_CODE_CONFIG_FILE"; then
    print_message "Docker MCP is already configured in Claude Code."
  else
    print_message "Updating Claude Code configuration with Docker MCP..."
    # Create a backup
    cp "$CLAUDE_CODE_CONFIG_FILE" "${CLAUDE_CODE_CONFIG_FILE}.bak"
    
    # Update the config
    TEMP_FILE=$(mktemp)
    jq '. * {"mcpServers": {"docker": {"command": "mcp-server-kubernetes", "args": [], "env": {"DOCKER_HOST": "tcp://localhost:2375"}}}}' "$CLAUDE_CODE_CONFIG_FILE" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$CLAUDE_CODE_CONFIG_FILE"
    print_message "Updated Claude Code configuration."
  fi
else
  print_message "Creating new Claude Code configuration file..."
  
  # Create a new config file
  cat > "$CLAUDE_CODE_CONFIG_FILE" << EOF
{
  "mcpServers": {
    "docker": {
      "command": "mcp-server-kubernetes",
      "args": [],
      "env": {
        "DOCKER_HOST": "tcp://localhost:2375"
      }
    }
  }
}
EOF
  print_message "Created Claude Code configuration file."
fi

# Check for Claude Desktop
CLAUDE_DESKTOP_CONFIG_LOCATIONS=(
  "$HOME/.config/Claude/claude-desktop.json"
  "$HOME/Library/Application Support/Claude/claude-desktop.json"
  "$APPDATA/Claude/claude-desktop.json"
)

CLAUDE_DESKTOP_FOUND=0

for CONFIG_PATH in "${CLAUDE_DESKTOP_CONFIG_LOCATIONS[@]}"; do
  if [ -f "$CONFIG_PATH" ]; then
    print_message "Found Claude Desktop configuration at $CONFIG_PATH"
    CLAUDE_DESKTOP_FOUND=1
    CLAUDE_DESKTOP_CONFIG_FILE="$CONFIG_PATH"
    
    # Check if docker is already configured
    if grep -q '"docker"' "$CLAUDE_DESKTOP_CONFIG_FILE"; then
      print_message "Docker is already configured in Claude Desktop."
    else
      print_message "Updating Claude Desktop configuration with Docker MCP..."
      # Create a backup
      cp "$CLAUDE_DESKTOP_CONFIG_FILE" "${CLAUDE_DESKTOP_CONFIG_FILE}.bak"
      
      # Update the config
      TEMP_FILE=$(mktemp)
      jq '. * {"docker": {"command": "npx", "args": ["-y", "mcp-server-kubernetes"], "env": {"DOCKER_HOST": "tcp://localhost:2375"}}}' "$CLAUDE_DESKTOP_CONFIG_FILE" > "$TEMP_FILE"
      mv "$TEMP_FILE" "$CLAUDE_DESKTOP_CONFIG_FILE"
      print_message "Updated Claude Desktop configuration."
    fi
    
    break
  fi
done

if [ $CLAUDE_DESKTOP_FOUND -eq 0 ]; then
  print_warning "Claude Desktop configuration not found. Only Claude Code has been configured."
fi

# Final output
print_message "\n✅ Docker MCP integration setup is complete!"
print_message "You can now use Docker commands with Claude through natural language."
print_message "Verify the integration by running 'claude mcp' in your terminal."
print_message "For more information, refer to DOCKER-MCP-INTEGRATION.md"

echo ""
print_message "IMPORTANT: For security reasons, this setup exposes Docker on localhost only."
print_message "If you need to connect to a remote Docker host, edit the configuration files"
print_message "and change 'localhost' to the IP address of your remote Docker host."

exit 0