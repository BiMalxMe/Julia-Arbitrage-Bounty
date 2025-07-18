# ChainGuardian - Solana Wallet Risk Analysis dApp

A comprehensive decentralized application for analyzing Solana wallet risks, including token analysis, transaction analysis, rugpull detection, and airdrop discovery using JuliaOS agent framework and swarm orchestration.

## 🛡️ Features

### Core Analysis
- **Token Risk Analysis**: Detect suspicious tokens, rugpulls, and low-liquidity assets
- **Transaction Analysis**: Analyze transaction patterns and identify risky behaviors
- **Comprehensive Risk Assessment**: Multi-factor risk scoring and recommendations
- **Airdrop Discovery**: Identify potential airdrop opportunities

### Advanced Capabilities
- **Swarm Orchestration**: Distributed task processing with worker nodes
- **Dynamic Configuration**: Runtime configuration updates without restarts
- **Real-time Monitoring**: Live system health and performance metrics
- **REST API**: Full-featured API for integration and automation
- **Modern Web UI**: Beautiful React frontend with real-time updates

## 🏗️ Architecture

```
ChainGuardian/
├── chainguardian.jl          # Main entry point
├── config.jl                 # Configuration management
├── SolanaRPC.jl             # Solana blockchain integration
├── Utils.jl                 # Utility functions
├── agents/                  # Analysis agents
│   ├── token_scanner.jl     # Token analysis
│   ├── tx_scanner.jl        # Transaction analysis
│   └── risk_evaluator.jl    # Risk assessment
├── swarm/                   # Distributed processing
│   ├── coordinator.jl       # Task coordination
│   └── worker.jl           # Worker nodes
├── api/                     # REST API server
│   └── server.jl           # HTTP server
└── frontend/               # React web interface
    ├── src/
    │   ├── components/     # React components
    │   ├── services/       # API integration
    │   └── App.js         # Main app
    └── package.json       # Frontend dependencies
```

## 🚀 Quick Start

### Prerequisites

- Julia 1.8+
- Node.js 16+ (for frontend)
- Solana RPC access

### Backend Setup

1. **Install Julia dependencies**:
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

2. **Configure environment**:
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Start the backend**:
```bash
julia chainguardian.jl
```

### Frontend Setup

1. **Install dependencies**:
```bash
cd frontend
npm install
```

2. **Start the frontend**:
```bash
npm start
```

3. **Access the application**:
- Backend API: http://localhost:8080
- Frontend UI: http://localhost:3000

## 📊 API Endpoints

### System
- `GET /status` - System status and metadata
- `GET /health` - Health check
- `GET /config` - Current configuration
- `PUT /config` - Update configuration

### Analysis
- `GET /risk/{wallet_address}` - Quick risk analysis
- `POST /risk/analyze` - Comprehensive analysis
- `GET /task/{task_id}` - Task status

### Swarm
- `GET /swarm/status` - Swarm status
- `POST /swarm/submit` - Submit swarm task

## 🔧 Configuration

### Environment Variables

```bash
# Solana Configuration
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
API_KEY=your_api_key

# Service Configuration
SERVICE_PORT=8080
THREADS=8

# Swarm Configuration
SWARM_WORKERS=7
TASK_TIMEOUT=300

# Analysis Configuration
TOKEN_ANALYSIS_ENABLED=true
TX_ANALYSIS_ENABLED=true
AIRDROP_ANALYSIS_ENABLED=true
MAX_TX_HISTORY=100
```

### Dynamic Configuration

The system supports runtime configuration updates:

```bash
# Update rate limits
curl -X PUT http://localhost:8080/config \
  -H "Content-Type: application/json" \
  -d '{"api_rate_limit": 200, "max_concurrent_tasks": 15}'
```

## 🎯 Usage Examples

### Analyze a Wallet

```bash
# Quick analysis
curl http://localhost:8080/risk/9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM

# Comprehensive analysis
curl -X POST http://localhost:8080/risk/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "wallet_address": "9WzDXwBbmkg8ZTbNMqUxvQRAyrZzDsGYdLVL9zYtAWWM",
    "analysis_type": "comprehensive",
    "async": true
  }'
```

### Check System Status

```bash
curl http://localhost:8080/status
```

## 🏛️ Architecture Details

### Agent Framework

ChainGuardian uses a modular agent architecture:

- **TokenScanner**: Analyzes token holdings and detects risks
- **TxScanner**: Processes transaction history and patterns
- **RiskEvaluator**: Combines analysis for comprehensive assessment
- **SwarmCoordinator**: Manages distributed task processing
- **SwarmWorker**: Executes analysis tasks

### Swarm Orchestration

The swarm system provides:

- **Distributed Processing**: Multiple worker nodes
- **Task Queuing**: Priority-based task management
- **Fault Tolerance**: Automatic retry and recovery
- **Load Balancing**: Dynamic worker allocation

### Dynamic Configuration

Runtime configuration management:

- **Hot Reloading**: Changes take effect immediately
- **Validation**: Type-safe configuration updates
- **Persistence**: Configuration state management
- **API Access**: RESTful configuration management

## 🎨 Frontend Features

### Dashboard
- System health overview
- Quick action buttons
- Real-time metrics
- Recent activity feed

### Wallet Analyzer
- Address input with validation
- Analysis type selection
- Real-time progress tracking
- Comprehensive results display

### System Status
- Health monitoring
- Swarm status
- Configuration display
- Performance metrics

### Configuration
- Dynamic settings management
- Real-time updates
- Validation and error handling
- Default value restoration

## 🔒 Security Features

- **Input Validation**: Comprehensive address and parameter validation
- **Rate Limiting**: Configurable API rate limits
- **Error Handling**: Graceful error recovery
- **Logging**: Comprehensive audit trails
- **CORS Support**: Cross-origin request handling

## 📈 Performance

- **Concurrent Processing**: Multi-threaded analysis
- **Caching**: Intelligent result caching
- **Async Operations**: Non-blocking API responses
- **Resource Management**: Efficient memory and CPU usage

## 🧪 Testing

### Backend Tests

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

### Frontend Tests

```bash
cd frontend
npm test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- Solana Labs for the blockchain infrastructure
- Julia Computing for the programming language
- The open-source community for various dependencies

## 📞 Support

For support and questions:
- Create an issue on GitHub
- Check the documentation
- Review the API reference

---

**ChainGuardian** - Protecting Solana users through advanced risk analysis and monitoring.