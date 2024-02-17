# Kubernetes Cluster Setup with KIND

This project provides a set of scripts to easily create and destroy Kubernetes clusters using KIND (Kubernetes IN Docker), which allows for running Kubernetes clusters within Docker containers. It's an excellent way to set up isolated Kubernetes environments for development and testing.

## Prerequisites

Before you can run the scripts, you need to have the following installed:

- Docker Desktop: Ensure Docker is installed and running on your machine. These scripts check for Docker's availability before attempting to create or destroy a Kubernetes cluster.
- KIND: KIND must be installed. KIND is a tool for running local Kubernetes clusters using Docker container "nodes".
- Kubernetes CLI (kubectl): Although not directly required by the scripts, `kubectl` is useful for interacting with your KIND clusters once they are up and running.

## Getting Started

1. **Clone the Repository**: First, clone this repository to your local machine to get started.

   ```sh
   git clone <repository-url>
   cd <repository-folder>

