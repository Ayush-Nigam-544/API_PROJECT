#!/bin/bash
# Setup script for Student API Production Environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}$1${NC}"
}

# Function to install Docker
install_docker() {
    print_header "🐳 Installing Docker..."
    
    # Update package index
    sudo apt-get update -y
    
    # Install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        apt-transport-https \
        software-properties-common
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Set up Docker repository
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker vagrant
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    print_status "Docker installed successfully"
}

# Function to install Docker Compose
install_docker_compose() {
    print_header "📦 Installing Docker Compose..."
    
    # Install docker-compose standalone
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for easier access
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_status "Docker Compose installed successfully"
}

# Function to install system dependencies
install_dependencies() {
    print_header "📚 Installing system dependencies..."
    
    sudo apt-get update -y
    sudo apt-get install -y \
        curl \
        wget \
        git \
        make \
        python3 \
        python3-pip \
        python3-venv \
        nginx \
        htop \
        tree \
        vim \
        unzip \
        software-properties-common
    
    print_status "System dependencies installed successfully"
}

# Function to configure firewall
configure_firewall() {
    print_header "🔥 Configuring firewall..."
    
    # Install and configure UFW
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow 22/tcp
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow API port
    sudo ufw allow 8080/tcp
    
    # Allow PostgreSQL
    sudo ufw allow 5432/tcp
    
    # Enable firewall
    sudo ufw --force enable
    
    print_status "Firewall configured successfully"
}

# Function to setup development tools
setup_dev_tools() {
    print_header "🛠️ Setting up development tools..."
    
    # Install Python packages
    pip3 install --user --upgrade pip
    pip3 install --user flask pytest requests
    
    # Create useful aliases
    cat >> /home/vagrant/.bashrc << 'EOF'

# Custom aliases for development
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias grep='grep --color=auto'
alias dc='docker-compose'
alias dcp='docker-compose -f production/docker-compose.prod.yaml'
alias logs='docker-compose logs -f'
alias logsp='docker-compose -f production/docker-compose.prod.yaml logs -f'

# Project shortcuts
alias api='cd /vagrant'
alias prod='cd /vagrant && make deploy-prod'
alias dev='cd /vagrant && make run-api'
alias health='cd /vagrant && make health-check-all'

# Show useful info on login
echo "🚀 Student API Development Environment"
echo "📁 Project location: /vagrant"
echo "🔧 Useful commands:"
echo "   api     - Go to project directory"
echo "   prod    - Deploy production environment"
echo "   dev     - Start development environment"
echo "   health  - Check all services health"
echo "   make help - Show all available commands"
echo ""
EOF

    print_status "Development tools setup completed"
}

# Function to setup project environment
setup_project() {
    print_header "📁 Setting up project environment..."
    
    cd /vagrant
    
    # Create necessary directories
    sudo mkdir -p instance logs
    sudo chown -R vagrant:vagrant instance logs
    
    # Make scripts executable
    chmod +x vagrant/setup.sh
    
    print_status "Project environment setup completed"
}

# Function to optimize system
optimize_system() {
    print_header "⚡ Optimizing system..."
    
    # Update system
    sudo apt-get update -y && sudo apt-get upgrade -y
    
    # Clean up
    sudo apt-get autoremove -y
    sudo apt-get autoclean
    
    # Set timezone
    sudo timedatectl set-timezone UTC
    
    print_status "System optimization completed"
}

# Function to test installation
test_installation() {
    print_header "🧪 Testing installation..."
    
    # Test Docker
    if docker --version > /dev/null 2>&1; then
        print_status "✅ Docker is working"
    else
        print_error "❌ Docker installation failed"
        exit 1
    fi
    
    # Test Docker Compose
    if docker-compose --version > /dev/null 2>&1; then
        print_status "✅ Docker Compose is working"
    else
        print_error "❌ Docker Compose installation failed"
        exit 1
    fi
    
    # Test Python
    if python3 --version > /dev/null 2>&1; then
        print_status "✅ Python is working"
    else
        print_error "❌ Python installation failed"
        exit 1
    fi
    
    print_status "All tests passed!"
}

# Main execution function
main() {
    print_header "🎉 Starting Student API Production Environment Setup"
    print_status "This will take a few minutes..."
    
    install_dependencies
    install_docker
    install_docker_compose
    configure_firewall
    setup_dev_tools
    setup_project
    optimize_system
    test_installation
    
    print_header "🎉 Setup completed successfully!"
    print_warning "Please logout and login again for Docker group changes to take effect"
    print_status "Or run: newgrp docker"
    
    echo -e "\n${GREEN}Next steps:${NC}"
    echo "1. logout && vagrant ssh"
    echo "2. cd /vagrant"
    echo "3. make deploy-prod"
    echo "4. make health-check-all"
}

# Execute main function
main "$@"
