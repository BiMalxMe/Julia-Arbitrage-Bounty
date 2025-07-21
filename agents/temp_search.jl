
      using Pkg
      Pkg.activate("/Users/bimalchalise/Desktop/All/julia-liquidity-mirage/agents")
      
      include("/Users/bimalchalise/Desktop/All/julia-liquidity-mirage/agents/swarm_coordinator.jl")
      
      result = search_collections("CryptoPunks")
      
      using JSON3
      println(JSON3.write(result))
    