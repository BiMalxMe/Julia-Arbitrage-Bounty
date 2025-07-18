module SwarmCoordinator

using JuliaOS
include("../agents/LiquidityMonitor.jl")

function start()
    @async LiquidityMonitor.run()
end

end # module
