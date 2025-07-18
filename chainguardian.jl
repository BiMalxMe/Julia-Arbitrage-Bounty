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

using .Config
using .TokenScanner
using .TxScanner
using .RiskEvaluator
using .SwarmCoordinator
using .SwarmWorker
using .ChainGuardianAPI
using .SolanaRPC
using .Utils
using Logging

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
        Config.load_config()
        println(Config)

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
        println()

        # Display API endpoints
        println("📡 Available API Endpoints:")
        println("  • GET  /status - System status")
        println("  • GET  /health - Health check")
        println("  • GET  /risk/{wallet_address} - Quick risk analysis")
        println("  • POST /risk/analyze - Comprehensive analysis")
        println("  • GET  /swarm/status - Swarm status")
        println("  • POST /swarm/submit - Submit swarm task")
        println("  • GET  /task/{task_id} - Task status")
        println()

        # Start the system
        println("🔄 Initializing ChainGuardian agent...")
        Agent_init()

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
            println("✅ ChainGuardian stopped successfully")
        else
            println("❌ Error starting ChainGuardian: $e")
            @error "ChainGuardian startup failed" exception=(e, catch_backtrace())
            exit(1)
        end
    end
end

# Run main function if this file is executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end