#!/bin/bash

# JuliaOS NFT Predictor Setup Script
echo "🚀 Setting up JuliaOS NFT Price Predictor..."

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

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    print_error "Node.js version 18+ is required. Current version: $(node --version)"
    exit 1
fi

print_success "Node.js version check passed: $(node --version)"

# Check if Julia is installed
if ! command -v julia &> /dev/null; then
    print_warning "Julia is not installed. Installing Julia..."
    
    # Install Julia based on OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        wget https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.4-linux-x86_64.tar.gz
        tar zxvf julia-1.9.4-linux-x86_64.tar.gz
        sudo mv julia-1.9.4 /opt/
        sudo ln -s /opt/julia-1.9.4/bin/julia /usr/local/bin/julia
        rm julia-1.9.4-linux-x86_64.tar.gz
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install julia
        else
            print_error "Homebrew not found. Please install Julia manually from https://julialang.org/downloads/"
            exit 1
        fi
    else
        print_error "Unsupported OS. Please install Julia manually from https://julialang.org/downloads/"
        exit 1
    fi
fi

print_success "Julia check passed: $(julia --version)"

# Install Ollama for local LLM
print_status "Installing Ollama for local LLM support..."
if ! command -v ollama &> /dev/null; then
    if [[ "$OSTYPE" == "linux-gnu"* ]] || [[ "$OSTYPE" == "darwin"* ]]; then
        curl -fsSL https://ollama.ai/install.sh | sh
        print_success "Ollama installed successfully"
    else
        print_warning "Ollama installation not supported on this OS. Please install manually."
    fi
else
    print_success "Ollama already installed"
fi

# Start Ollama service
print_status "Starting Ollama service..."
if command -v ollama &> /dev/null; then
    ollama serve &
    sleep 2
    
    # Download recommended models
    print_status "Downloading recommended LLM models..."
    ollama pull llama2 &
    ollama pull mistral &
    wait
    print_success "LLM models downloaded"
fi

# Install Node.js dependencies
print_status "Installing Node.js dependencies..."
npm install
cd backend && npm install
cd ..
print_success "Node.js dependencies installed"

# Setup Julia environment
print_status "Setting up Julia environment..."
cd agents
julia --project=. -e '
    using Pkg
    Pkg.add("HTTP")
    Pkg.add("JSON3")
    Pkg.precompile()
    println("Julia environment setup complete")
'
cd ..
print_success "Julia environment configured"

# Create environment file
print_status "Creating environment configuration..."
if [ ! -f backend/.env ]; then
    cp backend/.env.example backend/.env
    cp .env.example .env
    print_warning "Created backend/.env from template. Please add your API keys!"
    print_warning "Created .env from template. Please add your API keys!"
else
    print_success "Environment file already exists"
fi

# Verify setup
print_status "Verifying installation..."

# Check Node.js modules
if [ -d node_modules ] && [ -d backend/node_modules ]; then
    print_success "Node.js modules installed correctly"
else
    print_error "Node.js modules missing"
fi

# Check Julia packages
julia --project=agents -e 'using HTTP, JSON3; println("Julia packages verified")' > /dev/null 2>&1
if [ $? -eq 0 ]; then
    print_success "Julia packages installed correctly"
else
    print_warning "Julia packages may need manual installation"
fi

# Create startup scripts
print_status "Creating startup scripts..."

# Frontend startup script
cat > start-frontend.sh << 'EOF'
#!/bin/bash
echo "Starting NFT Predictor Frontend..."
npm run dev
EOF

# Backend startup script
cat > start-backend.sh << 'EOF'
#!/bin/bash
echo "Starting NFT Predictor Backend..."
cd backend && npm run dev
EOF

# Combined startup script
cat > start-all.sh << 'EOF'
#!/bin/bash
echo "Starting JuliaOS NFT Predictor (Full Stack)..."

# Start Ollama if not running
if ! pgrep -x "ollama" > /dev/null; then
    echo "Starting Ollama service..."
    ollama serve &
    sleep 2
fi

# Start backend in background
echo "Starting backend..."
cd backend && npm run dev &
BACKEND_PID=$!

# Wait for backend to start
sleep 3

# Start frontend
echo "Starting frontend..."
cd .. && npm run dev &
FRONTEND_PID=$!

echo "🚀 JuliaOS NFT Predictor is starting up!"
echo "📊 Frontend: http://localhost:5173"
echo "🔧 Backend: http://localhost:3001"
echo "🧠 Ollama: http://localhost:11434"
echo ""
echo "Press Ctrl+C to stop all services"

# Wait for processes
wait $BACKEND_PID $FRONTEND_PID
EOF

chmod +x start-frontend.sh start-backend.sh start-all.sh

print_success "Startup scripts created"

# Final instructions
echo ""
echo "🎉 Setup complete! Next steps:"
echo ""
echo "1. Configure API keys in backend/.env:"
echo "   - Get free OpenSea API key: https://docs.opensea.io/reference/api-keys"
echo "   - Get free Alchemy API key: https://www.alchemy.com/"
echo "   - Get free Hugging Face token: https://huggingface.co/settings/tokens"
echo ""
echo "2. Start the application:"
echo "   ./start-all.sh     # Start everything"
echo "   ./start-frontend.sh # Frontend only"
echo "   ./start-backend.sh  # Backend only"
echo ""
echo "3. Open your browser:"
echo "   Frontend: http://localhost:5173"
echo "   Backend API: http://localhost:3001"
echo ""
echo "🧠 JuliaOS agents are ready to predict NFT prices!"
print_success "Setup completed successfully!"