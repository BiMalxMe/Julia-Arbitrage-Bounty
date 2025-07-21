#!/usr/bin/env julia

"""
JuliaOS Example Usage

This script demonstrates how to use the JuliaOS module with the existing
agent files for NFT data collection and analysis.
"""

println("🚀 JuliaOS Example Usage")
println("========================")

# Load the JuliaOS module
include("src/JuliaOS.jl")
using .JuliaOS

# Load the agent modules
include("data_collector.jl")
include("ai_analyzer.jl")
include("price_predictor.jl")
include("swarm_coordinator.jl")

println("\n1. Creating and starting agents...")

# Create data collector agent
data_collector_config = Dict(
    "name" => "DataCollector",
    "description" => "Collects NFT collection data from multiple sources",
    "capabilities" => ["opensea_api", "alchemy_api", "onchain_data"],
    "rate_limits" => Dict(
        "opensea" => 100,
        "alchemy" => 300000000,
        "coingecko" => 10000
    ),
    "max_retries" => 3,
    "timeout" => 30.0
)

data_agent = JuliaOS.Agent(data_collector_config)
JuliaOS.start_agent(data_agent)

# Create AI analyzer agent
ai_analyzer_config = Dict(
    "name" => "AIAnalyzer",
    "description" => "Analyzes NFT data using AI models",
    "capabilities" => ["sentiment_analysis", "trend_analysis", "pattern_recognition"],
    "rate_limits" => Dict("ai_analysis" => 50),
    "max_retries" => 3,
    "timeout" => 60.0
)

ai_agent = JuliaOS.Agent(ai_analyzer_config)
JuliaOS.start_agent(ai_agent)

# Create price predictor agent
price_predictor_config = Dict(
    "name" => "PricePredictor",
    "description" => "Predicts NFT prices using ML models",
    "capabilities" => ["price_prediction", "market_analysis", "risk_assessment"],
    "rate_limits" => Dict("prediction" => 100),
    "max_retries" => 3,
    "timeout" => 45.0
)

price_agent = JuliaOS.Agent(price_predictor_config)
JuliaOS.start_agent(price_agent)

println("✅ All agents created and started successfully")

println("\n2. Demonstrating agent capabilities...")

# Example: Collect data for a test collection
test_collection = "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d"  # BAYC contract

println("📊 Collecting data for collection: $test_collection")

try
    # Use the data collector's function
    collection_data = collect_collection_data(test_collection)
    
    if collection_data["success"]
        println("✅ Data collection successful")
        println("   Sources: $(keys(collection_data["data"]["sources"]))")
        println("   Metadata keys: $(keys(collection_data["data"]["metadata"]))")
        println("   Market data keys: $(keys(collection_data["data"]["market_data"]))")
    else
        println("❌ Data collection failed: $(collection_data["error"])")
    end
    
catch e
    println("❌ Error during data collection: $e")
end

println("\n3. Agent monitoring and metrics...")

# Check agent status
agents = [data_agent, ai_agent, price_agent]
agent_names = ["DataCollector", "AIAnalyzer", "PricePredictor"]

for (agent, name) in zip(agents, agent_names)
    status = JuliaOS.get_agent_status(agent)
    metrics = JuliaOS.get_agent_metrics(agent)
    
    println("📈 $name Status:")
    println("   Running: $(status["is_running"])")
    println("   Messages: $(status["message_count"])")
    println("   Errors: $(status["error_count"])")
    println("   Capabilities: $(length(status["capabilities"]))")
    println("   Error rate: $(round(metrics["error_rate"] * 100, digits=2))%")
end

println("\n4. Demonstrating custom capabilities...")

# Register a custom capability for data processing
function custom_data_processor(agent::JuliaOS.Agent, data::Dict{String, Any})
    println("🔄 Processing data with custom capability...")
    
    # Add processing timestamp
    data["processed_at"] = now()
    data["processor"] = agent.config.name
    
    # Simulate some processing
    if haskey(data, "market_data")
        data["market_data"]["processed"] = true
    end
    
    return data
end

# Register the custom capability
JuliaOS.register_capability(data_agent, "custom_processor", custom_data_processor, 
                           "Custom data processing capability", 100)

# Execute the custom capability
try
    test_data = Dict("test" => "data", "market_data" => Dict("price" => 100))
    processed_data = JuliaOS.execute_capability(data_agent, "custom_processor", test_data)
    println("✅ Custom capability executed successfully")
    println("   Processed data keys: $(keys(processed_data))")
catch e
    println("❌ Custom capability failed: $e")
end

println("\n5. Error handling demonstration...")

# Demonstrate error handling with invalid capability
try
    JuliaOS.execute_capability(data_agent, "nonexistent_capability")
    println("❌ Should have thrown an error")
catch e
    println("✅ Error handling works correctly: $(e.msg)")
end

println("\n6. Rate limiting demonstration...")

# Demonstrate rate limiting by making multiple rapid requests
println("🔄 Testing rate limiting...")

for i in 1:5
    try
        JuliaOS.execute_capability(data_agent, "log_event", "rate_test_$i", Dict("iteration" => i))
        println("   Request $i: Success")
    catch e
        println("   Request $i: Rate limited - $(e.msg)")
    end
end

println("\n7. Stopping agents...")

# Stop all agents
for (agent, name) in zip(agents, agent_names)
    JuliaOS.stop_agent(agent)
    println("✅ $name stopped")
end

println("\n🎉 Example completed successfully!")
println("\n📚 Key takeaways:")
println("   • JuliaOS provides a robust agent framework")
println("   • Agents can be easily created, configured, and managed")
println("   • Built-in capabilities for common tasks")
println("   • Comprehensive error handling and rate limiting")
println("   • Easy monitoring and metrics collection")
println("   • Extensible with custom capabilities")

println("\n🚀 Ready for production use!")