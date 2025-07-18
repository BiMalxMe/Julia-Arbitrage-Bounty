using JuliaOS

# Include all agents
include("agents/LiquidityMonitor.jl")
include("agents/MirageDetector.jl")
include("agents/AlertAgent.jl")
include("swarm/SwarmCoordinator.jl")

# Start Swarm
println("🚀 Starting Liquidity Mirage Detector Swarm...")
SwarmCoordinator.start()
