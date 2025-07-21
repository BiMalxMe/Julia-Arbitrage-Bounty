
        using Pkg
        Pkg.activate("/Users/bimalchalise/Desktop/All/julia-liquidity-mirage/agents")
        
        include("/Users/bimalchalise/Desktop/All/julia-liquidity-mirage/agents/swarm_coordinator.jl")
        
        # Execute prediction pipeline
        result = execute_prediction_pipeline("0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB")
        
        # Output JSON result
        using JSON3
        println(JSON3.write(result))
      