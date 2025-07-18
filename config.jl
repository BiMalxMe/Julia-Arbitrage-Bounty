module Config

using DotEnv

const CONFIG = Dict{String, String}()

function load_config()
    DotEnv.config()
    CONFIG["SOLANA_RPC_URL"] = get(ENV, "SOLANA_RPC_URL", "https://api.mainnet-beta.solana.com")
    # No API key is required for public Solana RPC endpoints, but you can set one via the environment if needed.
    CONFIG["API_KEY"] = get(ENV, "API_KEY", "")
    CONFIG["SERVICE_PORT"] = get(ENV, "SERVICE_PORT", "8080")
    CONFIG["THREADS"] = get(ENV, "THREADS", "8")
    CONFIG["LIQUIDITY_THRESHOLD"] = get(ENV, "LIQUIDITY_THRESHOLD", "0.2")
    # Add more keys here as needed
    return CONFIG
end

export CONFIG, load_config

end # module 