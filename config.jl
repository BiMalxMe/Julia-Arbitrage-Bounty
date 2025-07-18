module Config

using DotEnv

const CONFIG = Dict{String, String}()

function load_config()
    DotEnv.config()
    CONFIG["SOLANA_RPC_URL"] = get(ENV, "SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com")
    CONFIG["API_KEY"] = get(ENV, "API_KEY", "")
    CONFIG["SERVICE_PORT"] = get(ENV, "SERVICE_PORT", "8080")
    CONFIG["THREADS"] = get(ENV, "THREADS", "8")
    CONFIG["LIQUIDITY_THRESHOLD"] = get(ENV, "LIQUIDITY_THRESHOLD", "0.2")
    
    # External API Keys
    CONFIG["BIRDEYE_API_KEY"] = get(ENV, "BIRDEYE_API_KEY", "X-API-KEY")
    CONFIG["HELIUS_API_KEY"] = get(ENV, "HELIUS_API_KEY", "4a7f200a-f03a-420a-840e-fb37d981c2bf")
    CONFIG["QUICKNODE_API_KEY"] = get(ENV, "QUICKNODE_API_KEY", "QN_7263baf5b559443da665604f0cc82009")
    
    # Swarm Configuration
    CONFIG["SWARM_WORKERS"] = get(ENV, "SWARM_WORKERS", "7")
    CONFIG["TASK_TIMEOUT"] = get(ENV, "TASK_TIMEOUT", "300")
    CONFIG["WORKER_HEARTBEAT_INTERVAL"] = get(ENV, "WORKER_HEARTBEAT_INTERVAL", "30")
    
    # Risk Analysis Configuration
    CONFIG["TOKEN_ANALYSIS_ENABLED"] = get(ENV, "TOKEN_ANALYSIS_ENABLED", "true")
    CONFIG["TX_ANALYSIS_ENABLED"] = get(ENV, "TX_ANALYSIS_ENABLED", "true")
    CONFIG["AIRDROP_ANALYSIS_ENABLED"] = get(ENV, "AIRDROP_ANALYSIS_ENABLED", "true")
    CONFIG["MAX_TX_HISTORY"] = get(ENV, "MAX_TX_HISTORY", "100")
    
    return CONFIG
end

export CONFIG, load_config

end # module 