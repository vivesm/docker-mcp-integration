# Docker MCP Integration for Claude

This repository contains tools and documentation for integrating Docker with Claude AI through the Model Context Protocol (MCP).

## What's Included

- **[DOCKER-MCP-INTEGRATION.md](./DOCKER-MCP-INTEGRATION.md)**: Comprehensive documentation on the integration
- **[setup-docker-mcp.sh](./setup-docker-mcp.sh)**: Automated setup script to configure the integration

## Quick Start

1. Clone this repository
2. Run the setup script:
   ```bash
   ./setup-docker-mcp.sh
   ```
3. Restart Claude
4. Verify the integration with `claude mcp`

## How It Works

This integration allows Claude to directly control Docker through natural language by:

1. Setting up a Docker Socket Proxy using alpine/socat
2. Installing the MCP Server Kubernetes package
3. Configuring Claude to use Docker via MCP

For detailed information, refer to [DOCKER-MCP-INTEGRATION.md](./DOCKER-MCP-INTEGRATION.md).

## Example Usage

Once configured, you can use Claude to manage Docker containers with natural language:

- "List all running containers"
- "Create a new Nginx container with port 8080 mapped to 80"
- "Show me the logs for my database container"

## Security Considerations

This integration exposes the Docker daemon via TCP. By default, it only exposes Docker on localhost. For production environments, consider implementing additional security measures as described in the documentation.

## Requirements

- Docker
- Node.js and npm
- Claude (Desktop or Code)