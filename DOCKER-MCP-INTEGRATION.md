# Docker Integration with Claude: Complete Implementation Guide

This document details how to integrate Docker with Claude using the Model Context Protocol (MCP), allowing Claude to directly control Docker through natural language commands.

## Overview

This integration creates a powerful bridge between Claude's AI capabilities and Docker container management, enabling natural language control of your Docker infrastructure. The setup consists of three core components:

1. **Docker Socket Proxy** - Exposes the Docker daemon via TCP
2. **MCP Server Kubernetes Package** - Handles protocol translation
3. **Claude Configuration** - Connects Claude to the Docker environment

## Detailed Implementation Steps

### 1. Setting Up the Docker Socket Proxy

The Docker Socket Proxy exposes the Docker daemon's Unix socket as a TCP endpoint, making it network-accessible.

```bash
# Create the Docker Socket Proxy container
sudo docker run -d --restart=always --name=docker-socket-proxy \
  -p 2375:2375 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  alpine/socat \
  tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
```

This container:
- Uses the lightweight `alpine/socat` image
- Maps container port 2375 to host port 2375
- Mounts the Docker Unix socket from the host
- Configures socat to listen on TCP port 2375 and forward connections to the Unix socket
- Sets `--restart=always` for persistence across reboots

To verify it's working correctly:
```bash
# Test the Docker Socket Proxy
curl -s http://localhost:2375/version | jq
```

### 2. Installing the MCP Server Kubernetes Package

The MCP Server Kubernetes package bridges Claude's MCP protocol with Docker CLI commands.

```bash
# Install the package globally
npm install -g mcp-server-kubernetes

# Verify installation
npm list -g mcp-server-kubernetes

# Ensure the command is accessible
which mcp-server-kubernetes
```

This globally installed package:
- Accepts requests from Claude in MCP format
- Constructs appropriate Docker CLI commands
- Formats the results back to Claude in JSON format
- Handles the necessary protocol translation automatically

### 3. Configuring Claude

#### For Claude Code

```bash
# Create the Claude Code configuration directory if it doesn't exist
mkdir -p ~/.claude-code/

# Create the configuration file
cat > ~/.claude-code/config.json << EOF
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
```

#### For Claude Desktop (if installed)

```bash
# Edit the Claude Desktop configuration (location may vary)
# For macOS, typically in ~/Library/Application Support/Claude/claude-desktop.json
# For Windows, typically in %APPDATA%\Claude\claude-desktop.json
# For Linux, typically in ~/.config/Claude/claude-desktop.json

# Add this configuration to the file:
{
  "docker": {
    "command": "npx",
    "args": ["-y", "mcp-server-kubernetes"],
    "env": {
      "DOCKER_HOST": "tcp://localhost:2375"
    }
  }
}
```

### 4. Remote Docker Setup (Optional)

To connect to a remote Docker host (like a Synology NAS):

1. Set up the Docker Socket Proxy on the remote host:
```bash
sudo docker run -d --restart=always --name=docker-socket-proxy \
  -p 2375:2375 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  alpine/socat \
  tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock
```

2. Update your Claude configuration to point to the remote host:
```json
"env": {
  "DOCKER_HOST": "tcp://192.168.1.100:2375"  // Replace with your remote host IP
}
```

## How It Works

The integration works through the following flow:

1. **User Request** → You ask Claude to perform a Docker operation
2. **Claude MCP** → Claude processes your request and sends an MCP command
3. **MCP Server** → The MCP server constructs a Docker CLI command
4. **Socket Proxy** → The command connects through the Socket Proxy
5. **Docker Daemon** → Docker processes the command and returns results
6. **Response Path** → Results flow back through the same components
7. **Claude Output** → Claude displays the results to you

The key innovation is using the `mcp-server-kubernetes` package to handle protocol translation between Claude's JSON-based MCP format and Docker's CLI interface.

## Verification

To verify the integration is working:

```bash
# Check MCP server status in Claude CLI
claude mcp
```

You should see output indicating the Docker MCP server is connected:
```
MCP Server Status
• docker: connected
```

## Usage Examples

Once configured, you can interact with Docker through natural language:

- **Container Management**:
  - "List all running containers"
  - "Create a new Nginx container with port 8080 mapped to 80"
  - "Stop the container named webserver"
  
- **Image Operations**:
  - "Show all Docker images"
  - "Pull the latest Ubuntu image"
  - "Remove unused images to free up space"
  
- **Monitoring and Inspection**:
  - "Show me the logs for the database container"
  - "Display resource usage statistics for all containers"
  - "Inspect the network settings of the frontend container"

- **Advanced Operations**:
  - "Create a Docker network for my application stack"
  - "Set up a volume for persistent data storage"
  - "Generate a docker-compose.yml file for a LAMP stack"

## Security Considerations

This implementation exposes the Docker daemon over TCP. For improved security:

1. **Use TLS**: Configure the Docker daemon with TLS certificates
2. **Network Restrictions**: Use firewall rules to limit access to the Docker socket
3. **Bind to Localhost**: Only expose the socket on localhost (127.0.0.1)
4. **Container Isolation**: Run the Socket Proxy with appropriate security constraints
5. **Regular Updates**: Keep Docker and all components updated to address vulnerabilities

## Troubleshooting

If you encounter issues:

| Problem | Solution |
|---------|----------|
| Connection refused | Check if the Socket Proxy container is running |
| MCP server not found | Verify the global installation of mcp-server-kubernetes |
| Permission denied | Check Docker socket permissions and proxy container access |
| Command not found | Ensure Docker CLI is installed and accessible |
| Incorrect results | Check your DOCKER_HOST environment variable |

## Additional Functionality

This integration can be extended to support more complex Docker operations:

- **Docker Compose**: Deploy multi-container applications
- **Docker Swarm**: Manage container orchestration
- **Docker Volumes**: Handle persistent storage needs
- **Custom Docker Networks**: Configure advanced networking

## Conclusion

This integration represents a powerful advancement in infrastructure management through natural language. By connecting Docker directly to Claude via MCP, you gain the ability to control your containerized applications through conversational interfaces, making Docker operations more accessible and intuitive.

The approach described here establishes a pattern for connecting AI systems to operational technologies, demonstrating the potential for further integrations between Claude and infrastructure tools.