#!/bin/bash

# GitHub SSH Key Generator Script
# This script generates an SSH key pair and adds the public key to your GitHub account

set -e  # Exit on any error

# Configuration
DEFAULT_KEY_NAME="github_key_$(date +%Y%m%d_%H%M%S)"
SSH_DIR="$HOME/.ssh"
GITHUB_API_URL="https://api.github.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v ssh-keygen &> /dev/null; then
        print_error "ssh-keygen is not installed"
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed. JSON responses will be shown raw."
    fi
    
    print_success "All dependencies are available"
}

# Function to get user input
get_user_input() {
    # Get GitHub token
    if [ -z "$GITHUB_TOKEN" ]; then
        echo
        print_status "GitHub Personal Access Token is required."
        print_status "You can create one at: https://github.com/settings/tokens"
        print_status "Required scopes: 'admin:public_key' or 'write:public_key'"
        echo
        read -s -p "Enter your GitHub Personal Access Token: " GITHUB_TOKEN
        echo
        
        if [ -z "$GITHUB_TOKEN" ]; then
            print_error "GitHub token is required"
            exit 1
        fi
    fi
    
    # Get key name
    echo
    read -p "Enter SSH key name (default: $DEFAULT_KEY_NAME): " KEY_NAME
    KEY_NAME=${KEY_NAME:-$DEFAULT_KEY_NAME}
    
    # Get email
    read -p "Enter your email address: " EMAIL
    if [ -z "$EMAIL" ]; then
        print_error "Email address is required"
        exit 1
    fi
    
    # Get key title for GitHub
    read -p "Enter title for the key on GitHub (default: $KEY_NAME): " KEY_TITLE
    KEY_TITLE=${KEY_TITLE:-$KEY_NAME}
}

# Function to generate SSH key
generate_ssh_key() {
    print_status "Generating SSH key pair..."
    
    # Create SSH directory if it doesn't exist
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    
    # Full path to key files
    PRIVATE_KEY="$SSH_DIR/$KEY_NAME"
    PUBLIC_KEY="$SSH_DIR/$KEY_NAME.pub"
    
    # Check if key already exists
    if [ -f "$PRIVATE_KEY" ] || [ -f "$PUBLIC_KEY" ]; then
        print_error "SSH key with name '$KEY_NAME' already exists"
        exit 1
    fi
    
    # Generate the key
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$PRIVATE_KEY" -N ""
    
    if [ $? -eq 0 ]; then
        print_success "SSH key pair generated successfully"
        print_status "Private key: $PRIVATE_KEY"
        print_status "Public key: $PUBLIC_KEY"
    else
        print_error "Failed to generate SSH key"
        exit 1
    fi
}

# Function to add key to GitHub
add_key_to_github() {
    print_status "Adding public key to GitHub..."
    
    # Read the public key
    if [ ! -f "$PUBLIC_KEY" ]; then
        print_error "Public key file not found: $PUBLIC_KEY"
        exit 1
    fi
    
    PUBLIC_KEY_CONTENT=$(cat "$PUBLIC_KEY")
    
    # Prepare JSON payload
    JSON_PAYLOAD=$(cat <<EOF
{
    "title": "$KEY_TITLE",
    "key": "$PUBLIC_KEY_CONTENT"
}
EOF
)
    
    # Make API request to add the key
    print_status "Making API request to GitHub..."
    
    RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        -d "$JSON_PAYLOAD" \
        "$GITHUB_API_URL/user/keys")
    
    # Extract HTTP status code
    HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
    RESPONSE_BODY=$(echo "$RESPONSE" | head -n -1)
    
    # Check response
    case $HTTP_CODE in
        201)
            print_success "SSH key successfully added to GitHub!"
            if command -v jq &> /dev/null; then
                KEY_ID=$(echo "$RESPONSE_BODY" | jq -r '.id')
                print_status "Key ID: $KEY_ID"
            fi
            ;;
        401)
            print_error "Authentication failed. Please check your GitHub token."
            exit 1
            ;;
        422)
            print_error "Key already exists on GitHub or invalid key format."
            if command -v jq &> /dev/null; then
                echo "$RESPONSE_BODY" | jq -r '.message'
            else
                echo "$RESPONSE_BODY"
            fi
            exit 1
            ;;
        *)
            print_error "Failed to add key to GitHub (HTTP $HTTP_CODE)"
            echo "$RESPONSE_BODY"
            exit 1
            ;;
    esac
}

# Function to update SSH config
update_ssh_config() {
    print_status "Updating SSH configuration..."
    
    SSH_CONFIG="$SSH_DIR/config"
    
    # Create backup of existing config
    if [ -f "$SSH_CONFIG" ]; then
        cp "$SSH_CONFIG" "$SSH_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
        print_status "Backup created: $SSH_CONFIG.backup.*"
    fi
    
    # Add GitHub configuration
    cat >> "$SSH_CONFIG" <<EOF

# GitHub SSH key - $KEY_NAME
Host github.com
    HostName github.com
    User git
    IdentityFile $PRIVATE_KEY
    IdentitiesOnly yes

EOF
    
    chmod 600 "$SSH_CONFIG"
    print_success "SSH config updated"
}

# Function to test SSH connection
test_ssh_connection() {
    print_status "Testing SSH connection to GitHub..."
    
    # Test the connection
    ssh -T git@github.com -o StrictHostKeyChecking=no -o ConnectTimeout=10 2>&1 | head -n 5
    
    print_status "If you see 'successfully authenticated' above, the setup is working!"
}

# Function to setup ssh-agent in .bashrc
setup_ssh_agent() {
    echo
    print_status "SSH Agent Configuration"
    read -p "Would you like to start ssh-agent automatically on login? (y/n): " setup_agent
    
    case $setup_agent in
        [Yy]|[Yy][Ee][Ss])
            print_status "Setting up ssh-agent in .bashrc..."
            
            # Create backup of .bashrc
            BASHRC_BACKUP="$HOME/.bashrc.backup.$(date +%Y%m%d_%H%M%S)"
            if [ -f "$HOME/.bashrc" ]; then
                cp "$HOME/.bashrc" "$BASHRC_BACKUP"
                print_success "Backup created: $BASHRC_BACKUP"
            fi
            
            # Check if ssh-agent is already configured
            if grep -q "ssh-agent" "$HOME/.bashrc" 2>/dev/null; then
                print_warning "ssh-agent appears to already be configured in .bashrc"
                read -p "Continue anyway? (y/n): " continue_setup
                case $continue_setup in
                    [Nn]|[Nn][Oo])
                        print_status "Skipping ssh-agent setup"
                        return
                        ;;
                esac
            fi
            
            # Add ssh-agent configuration to .bashrc
            cat >> "$HOME/.bashrc" <<'EOF'

# SSH Agent Configuration - Added by GitHub SSH Setup Script
start_ssh_agent() {
    # Kill any existing ssh-agent instances for this user
    pkill -u $USER ssh-agent 2>/dev/null || true
    
    # Start new ssh-agent and capture output
    echo "Starting ssh-agent..."
    eval $(ssh-agent -s)
    
    # Save agent info to file for reference
    echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > $HOME/.ssh-agent
    echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> $HOME/.ssh-agent
}

# Check if ssh-agent is running and accessible
if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
    # Try to load existing agent info
    if [ -f "$HOME/.ssh-agent" ]; then
        source "$HOME/.ssh-agent" >/dev/null 2>&1
    fi
    
    # Test if the agent is actually working
    if [ -z "$SSH_AUTH_SOCK" ] || ! ssh-add -l >/dev/null 2>&1; then
        start_ssh_agent
    fi
fi
EOF
            
            print_success "ssh-agent startup added to .bashrc"
            
            # Ask about auto-adding the key
            echo
            read -p "Would you like to automatically add your SSH key on login? (y/n): " auto_add_key
            
            case $auto_add_key in
                [Yy]|[Yy][Ee][Ss])
                    print_status "Adding automatic key loading to .bashrc..."
                    
                    cat >> "$HOME/.bashrc" <<EOF

# Auto-add SSH key - Added by GitHub SSH Setup Script
if [ -f "$PRIVATE_KEY" ]; then
    ssh-add -l | grep -q "$PRIVATE_KEY" || ssh-add "$PRIVATE_KEY" 2>/dev/null
fi
EOF
                    
                    print_success "Automatic key loading added to .bashrc"
                    ;;
                [Nn]|[Nn][Oo])
                    print_status "Skipping automatic key loading"
                    print_status "You'll need to run 'ssh-add $PRIVATE_KEY' manually after each login"
                    ;;
                *)
                    print_warning "Invalid input. Skipping automatic key loading."
                    ;;
            esac
            
            # Add cleanup trap
            echo "" >> "$HOME/.bashrc"
            echo "# Cleanup ssh-agent on shell exit" >> "$HOME/.bashrc"
            echo "trap 'ssh-agent -k >/dev/null 2>&1' EXIT" >> "$HOME/.bashrc"
            
            # Start ssh-agent for current session
            print_status "Starting ssh-agent for current session..."
            if [ -z "$SSH_AUTH_SOCK" ]; then
                eval $(ssh-agent -s)
                ssh-add "$PRIVATE_KEY" 2>/dev/null && print_success "Key added to current session"
            fi
            
            print_success "ssh-agent configuration complete!"
            print_status "Changes will take effect on next login or run: source ~/.bashrc"
            ;;
        [Nn]|[Nn][Oo])
            print_status "Skipping ssh-agent setup"
            print_status "You'll need to manage ssh-agent manually"
            ;;
        *)
            print_warning "Invalid input. Skipping ssh-agent setup."
            ;;
    esac
}

# Function to display summary
display_summary() {
    echo
    print_success "=== Setup Complete ==="
    echo "Private Key: $PRIVATE_KEY"
    echo "Public Key: $PUBLIC_KEY"
    echo "GitHub Key Title: $KEY_TITLE"
    echo
    print_status "Next steps:"
    echo "1. Reload your shell: source ~/.bashrc"
    echo "2. Test with: ssh -T git@github.com"
    echo "3. Clone repositories with: git clone git@github.com:username/repository.git"
    echo "4. Set up git user: git config --global user.email \"$EMAIL\""
    echo
    print_status "Manual ssh-agent commands (if needed):"
    echo "- Start agent: eval \$(ssh-agent -s)"
    echo "- Add key: ssh-add $PRIVATE_KEY"
    echo "- List keys: ssh-add -l"
    echo "- Kill agent: ssh-agent -k"
    echo
}

# Main execution
main() {
    echo "GitHub SSH Key Generator"
    echo "========================"
    
    check_dependencies
    get_user_input
    generate_ssh_key
    add_key_to_github
    update_ssh_config
    setup_ssh_agent
    test_ssh_connection
    display_summary
}

# Run the script
main "$@"