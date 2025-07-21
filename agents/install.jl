#!/usr/bin/env julia

"""
JuliaOS Installation Script

This script sets up the JuliaOS agent framework environment and installs
all necessary dependencies for production use.
"""

println("🚀 Installing JuliaOS Agent Framework...")

# Activate the project environment
using Pkg
Pkg.activate(".")

println("📦 Installing dependencies...")

# Add required packages if not already present
required_packages = [
    "HTTP",
    "JSON3", 
    "Dates",
    "Statistics",
    "Logging",
    "Random",
    "LinearAlgebra",
    "StatsBase"
]

for pkg in required_packages
    try
        Pkg.add(pkg)
        println("✅ Added $pkg")
    catch e
        println("⚠️  $pkg may already be installed or failed: $e")
    end
end

println("\n🔧 Setting up JuliaOS module...")

# Check if JuliaOS module can be loaded
try
    include("src/JuliaOS.jl")
    using .JuliaOS
    println("✅ JuliaOS module loaded successfully")
catch e
    println("❌ Failed to load JuliaOS module: $e")
    exit(1)
end

println("\n🧪 Running tests...")

# Run the test suite
try
    include("test_julios.jl")
    println("✅ All tests passed!")
catch e
    println("❌ Tests failed: $e")
    println("Please check the error messages above and fix any issues.")
    exit(1)
end

println("\n🎉 JuliaOS installation completed successfully!")
println("\n📚 Next steps:")
println("   1. Read the documentation: README_JuliaOS.md")
println("   2. Check the examples in the agent files")
println("   3. Set up your environment variables for API access")
println("   4. Start building your agents!")

println("\n🔑 Environment variables to set (optional):")
println("   export OPENSEA_API_KEY=\"your_opensea_api_key\"")
println("   export ALCHEMY_API_KEY=\"your_alchemy_api_key\"")
println("   export COINGECKO_API_KEY=\"your_coingecko_api_key\"")

println("\n🚀 JuliaOS is ready for production use!")