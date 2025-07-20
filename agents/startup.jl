#!/usr/bin/env julia

"""
JuliaOS NFT Predictor - Agent Startup Script

This script initializes the Julia environment and starts the agent swarm.
Run this before starting the backend server for full functionality.
"""

using Pkg

# Activate the project environment
println("🚀 Activating JuliaOS NFT Predictor environment...")
Pkg.activate(@__DIR__)

# Install dependencies if needed
println("📦 Checking and installing dependencies...")
try
    Pkg.instantiate()
    println("✅ Dependencies installed successfully")
catch e
    println("❌ Failed to install dependencies: $e")
    exit(1)
end

# Precompile packages for faster startup
println("⚡ Precompiling packages...")
try
    Pkg.precompile()
    println("✅ Precompilation completed")
catch e
    println("⚠️  Precompilation warning: $e")
end

# Test basic functionality
println("🧪 Testing agent functionality...")
try
    include("swarm_coordinator.jl")
    
    # Test agent health
    health = get_agent_health()
    println("✅ Agent health check passed: $(length(health)) agents available")
    
    # Test search functionality
    search_results = search_collections("test")
    println("✅ Search functionality test passed")
    
    println("🎉 JuliaOS NFT Predictor agents are ready!")
    println("📡 Backend can now connect to Julia agents")
    
catch e
    println("❌ Agent test failed: $e")
    println("🔧 Please check your Julia environment and dependencies")
    exit(1)
end

# Keep the process alive for backend connections
println("🔄 Agents running and ready for connections...")
println("   Press Ctrl+C to stop")

try
    while true
        sleep(1)
    end
catch InterruptException
    println("\n👋 Shutting down agents...")
    exit(0)
end