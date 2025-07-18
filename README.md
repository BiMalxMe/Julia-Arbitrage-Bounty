# Solana Liquidity Mirage Detection Agent (JuliaOS Swarm dApp)

## Overview
This JuliaOS swarm agent detects liquidity mirage patterns in Solana-based decentralized pools by monitoring token account activity in real time. It fetches live on-chain data from the Solana JSON-RPC API and exposes a RESTful API for agent logic. Designed for high concurrency, modularity, and seamless JuliaOS integration.

## Features
- **Live Solana RPC integration** (configurable endpoint)
- **Modular Julia code**: config, RPC, detection, utils, server
- **REST API**: `/status` and `/check` endpoints
- **Multi-threaded** for high concurrency (Julia Threads)
- **Environment-based configuration** via `.env`
- **Graceful error handling and logging**
- **Unit and integration tests**
- **JuliaOS agent lifecycle hooks and metadata**

## Agent Metadata
```
name: SolanaLiquidityMirageAgent
version: 1.0.0
description: Detects liquidity mirage patterns in Solana pools using live RPC data.
author: Your Name
license: MIT
```

## JuliaOS Integration
- Implements agent lifecycle hooks: `Agent_init()` and `Agent_serve()`
- Exposes agent metadata in `/status` endpoint
- Ready for swarm deployment and coordination (add swarm APIs as needed)

## Environment Setup
1. **Install Julia (v1.6 or newer recommended)**
2. **Clone this repository**
3. **Create a `.env` file in the project root:**

```ini
SOLANA_RPC_URL=https://api.mainnet-beta.solana.com
API_KEY=
SERVICE_PORT=8080
THREADS=8
LIQUIDITY_THRESHOLD=0.2
```
- `SOLANA_RPC_URL`: Solana JSON-RPC endpoint
- `API_KEY`: (optional, for private endpoints)
- `SERVICE_PORT`: HTTP server port
- `THREADS`: Number of Julia threads for concurrency
- `LIQUIDITY_THRESHOLD`: (optional) Threshold for suspicious liquidity change (e.g., 0.2 = 20%)

## Installation
```julia
import Pkg
Pkg.instantiate()
```

## Running the Agent Server
```sh
julia --project server.jl
```

## API Endpoints
### `GET /status`
- Returns: `{ "status": "ok", "time": "<server_time>", "agent": { ...metadata... } }`

### `POST /check`
- Request body: `{ "pool_address": "<SPL_POOL_ADDRESS>" }`
- Response: 
  ```json
  {
    "pool_address": "...",
    "mirage_detected": true|false,
    "details": { ... }
  }
  ```
- The detection logic fetches live token account data from Solana and analyzes for suspicious liquidity mirage patterns.

## Testing
Run tests with:
```sh
julia --project -e 'using Test; include("test/rpc_tests.jl")'
julia --project -e 'using Test; include("test/detection_tests.jl")'
julia --project -e 'using Test; include("test/server_tests.jl")'
```

## Example Test Scenario
- Use a known Solana pool address in `/check` to see live detection results.
- Try with both healthy and suspicious pools to observe detection logic.

## License
MIT License. See [LICENSE](LICENSE) file.

## Demo/Deployment
- (Optional) Deploy on JuliaOS swarm or cloud. Add your demo link here if available.

## Contributing
- Follow JuliaOS and Julia style guidelines.
- PRs and issues welcome!

## Resources
- [JuliaOS GitHub](https://github.com/julia-os)
- [Solana JSON-RPC Docs](https://docs.solana.com/developing/clients/jsonrpc-api)
- [Julia Documentation](https://docs.julialang.org/)