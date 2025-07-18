#!/usr/bin/env julia

"""
    ChainGuardian - Comprehensive Solana Wallet Risk Analysis dApp

    A full-stack decentralized application for analyzing Solana wallet risks
    including token analysis, transaction analysis, rugpull detection, and
    airdrop discovery using JuliaOS agent framework and swarm orchestration.
"""

# Load all modules
include("SolanaRPC.jl")
include("Utils.jl")
include("config.jl")
include("agents/token_scanner.jl")
include("agents/tx_scanner.jl")
include("agents/risk_evaluator.jl")
include("swarm/coordinator.jl")
include("swarm/worker.jl")
include("api/server.jl")

# Import modules with proper namespace
using .Config: CONFIG, load_config
using .TokenScanner: scan_wallet_tokens, TokenRisk
using .TxScanner: scan_wallet_transactions, TransactionRisk
using .RiskEvaluator: evaluate_wallet_risk, WalletRiskAssessment
using .SwarmCoordinator: start_swarm_coordinator, stop_swarm_coordinator, 
                          submit_wallet_analysis_task, submit_token_analysis_task,
                          submit_transaction_analysis_task, get_task_status, get_swarm_status
using .SwarmWorker: start_worker, stop_worker
using .ChainGuardianAPI: start_chainguardian_server, stop_chainguardian_server, Agent_init, Agent_serve
using .SolanaRPC: solana_rpc_request, fetch_token_accounts_by_owner
using .Utils: log_info, log_error, safe_json_parse
using Logging

# Global state for dynamic configuration
const DYNAMIC_CONFIG = Dict{String, Any}()
const SYSTEM_STATUS = Dict{String, Any}(
    "is_running" => false,
    "start_time" => nothing,
    "active_tasks" => 0,
    "total_requests" => 0
)

"""
    update_dynamic_config(key::String, value::Any)
Update dynamic configuration at runtime
"""
function update_dynamic_config(key::String, value::Any)
    global DYNAMIC_CONFIG
    DYNAMIC_CONFIG[key] = value
    log_info("Updated dynamic config: $key = $value")
end

"""
    get_dynamic_config(key::String, default::Any=nothing)
Get dynamic configuration value
"""
function get_dynamic_config(key::String, default::Any=nothing)
    return get(DYNAMIC_CONFIG, key, default)
end

"""
    update_system_status(key::String, value::Any)
Update system status
"""
function update_system_status(key::String, value::Any)
    global SYSTEM_STATUS
    SYSTEM_STATUS[key] = value
end

"""
    get_system_status()
Get current system status
"""
function get_system_status()
    return copy(SYSTEM_STATUS)
end

"""
    main()
Main entry point for ChainGuardian
"""
function main()
    println("🛡️  ChainGuardian - Solana Wallet Risk Analysis dApp")
    println("=" ^ 60)

    try
        # Initialize logging
        global_logger(ConsoleLogger(stderr, Logging.Info))

        # Load configuration
        load_config()
        println("Configuration loaded successfully")

        # Initialize dynamic configuration
        update_dynamic_config("api_rate_limit", 100)
        update_dynamic_config("max_concurrent_tasks", 10)
        update_dynamic_config("cache_enabled", true)
        update_dynamic_config("debug_mode", false)

        # Display startup information
        println("🚀 Starting ChainGuardian...")
        println("📊 Version: 2.0.0")
        println("🔗 Solana RPC: $(CONFIG["SOLANA_RPC_URL"])")
        println("🌐 Service Port: $(CONFIG["SERVICE_PORT"])")
        println("⚡ Threads: $(CONFIG["THREADS"])")
        println("🤖 Swarm Workers: $(CONFIG["SWARM_WORKERS"])")
        println()

        # Display enabled features
        println("🎯 Enabled Features:")
        println("  • Token Risk Analysis: $(CONFIG["TOKEN_ANALYSIS_ENABLED"])")
        println("  • Transaction Analysis: $(CONFIG["TX_ANALYSIS_ENABLED"])")
        println("  • Airdrop Discovery: $(CONFIG["AIRDROP_ANALYSIS_ENABLED"])")
        println("  • Swarm Orchestration: ✅")
        println("  • REST API: ✅")
        println("  • Dynamic Configuration: ✅")
        println()

        # Display API endpoints
        println("📡 Available API Endpoints:")
        println("  • GET  /status - System status")
        println("  • GET  /health - Health check")
        println("  • GET  /config - Current configuration")
        println("  • PUT  /config - Update configuration")
        println("  • GET  /risk/{wallet_address} - Quick risk analysis")
        println("  • POST /risk/analyze - Comprehensive analysis")
        println("  • GET  /swarm/status - Swarm status")
        println("  • POST /swarm/submit - Submit swarm task")
        println("  • GET  /task/{task_id} - Task status")
        println()

        # Start the system
        println("🔄 Initializing ChainGuardian agent...")
        Agent_init()

        # Update system status
        update_system_status("is_running", true)
        update_system_status("start_time", now())

        println("✅ ChainGuardian is ready!")
        println("🌐 Server running at: http://127.0.0.1:$(CONFIG["SERVICE_PORT"])")
        println()
        println("Press Ctrl+C to stop the server")
        println("=" ^ 60)

        # Start the server (this will block)
        Agent_serve()

    catch e
        if isa(e, InterruptException)
            println("\n🛑 Received interrupt signal, shutting down gracefully...")
            stop_chainguardian_server()
            update_system_status("is_running", false)
            println("✅ ChainGuardian stopped successfully")
        else
            println("❌ Error starting ChainGuardian: $e")
            @error "ChainGuardian startup failed" exception=(e, catch_backtrace())
            exit(1)
        end
    end
end

# Export main functions for external use
export main, update_dynamic_config, get_dynamic_config, update_system_status, get_system_status

# Run main function if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end