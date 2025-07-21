"""
JuliaOS NFT Data Collector Agent

This agent is responsible for collecting NFT collection data from various sources
including OpenSea API, Alchemy NFT API, and onchain data.
"""

include("src/JuliaOS.jl")
using .JuliaOS
using HTTP
using JSON3

# Add at the top of the file, after using statements:
 CONTRACT_TO_SLUG = Dict(
    "0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d" => "boredapeyachtclub",
    "0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb" => "cryptopunks",
    # Add more mappings as needed
)

# Add at the top of the file, after CONTRACT_TO_SLUG:
 OPENSEA_CACHE = Dict{String, Tuple{DateTime, Dict}}()
 CACHE_TTL_SECONDS = 120  # 2 minutes

# Agent configuration
 DATA_COLLECTOR_CONFIG = Dict(
    "name" => "DataCollector",
    "description" => "Collects NFT collection data from multiple sources",
    "capabilities" => ["opensea_api", "alchemy_api", "onchain_data"],
    "rate_limits" => Dict(
        "opensea" => 100,  # requests per hour
        "alchemy" => 300000000,  # compute units per month
        "coingecko" => 10000  # requests per day
    )
)

# Initialize agent
agent = JuliaOS.Agent(DATA_COLLECTOR_CONFIG)

"""
Collect comprehensive data for an NFT collection
"""
function collect_collection_data(collection_address::String)
    try
        @info "Starting data collection for $collection_address"
        
        # Initialize data structure
        data = Dict(
            "collection_address" => collection_address,
            "timestamp" => now(),
            "sources" => Dict(),
            "metadata" => Dict(),
            "market_data" => Dict(),
            "social_data" => Dict()
        )
        
        # Collect from multiple sources with fallbacks
        data["sources"]["opensea"] = collect_opensea_data(collection_address)
        data["sources"]["alchemy"] = collect_alchemy_data(collection_address)
        data["sources"]["onchain"] = collect_onchain_data(collection_address)
        data["sources"]["social"] = collect_social_data(collection_address)
        
        # Aggregate and clean data
        data["metadata"] = aggregate_metadata(data["sources"])
        data["market_data"] = aggregate_market_data(data["sources"])
        data["social_data"] = aggregate_social_data(data["sources"])
        println("Collected market data: ", data["market_data"])
        @info "Data collection completed successfully"
        return Dict("success" => true, "data" => data)
        
    catch e
        @error "Data collection failed: $e"
        return Dict("success" => false, "error" => string(e))
    end
end

"""
Collect data from OpenSea API (free tier)
"""
function collect_opensea_data(collection_address::String)
    try
        now_time = now()
        cache_key = lowercase(collection_address)
        # Check cache
        if haskey(OPENSEA_CACHE, cache_key)
            cached_time, cached_data = OPENSEA_CACHE[cache_key]
            if (now_time - cached_time).value < CACHE_TTL_SECONDS * 1000
                @info "Returning cached OpenSea data for $collection_address"
                return cached_data
            else
                delete!(OPENSEA_CACHE, cache_key)
            end
        end
        headers = Dict(
            "Accept" => "application/json",
            "X-API-KEY" => get(ENV, "OPENSEA_API_KEY", "")
        )
        # Map contract address to slug if possible
        slug = get(CONTRACT_TO_SLUG, lowercase(collection_address), collection_address)
        url = "https://api.opensea.io/api/v1/collection/$slug/stats"
        response = HTTP.get(url, headers=headers)
        
        if response.status == 200
            data = JSON3.read(response.body)
            result = Dict(
                "floor_price" => get(data.stats, "floor_price", 0),
                "market_cap" => get(data.stats, "market_cap", 0),
                "volume_24h" => get(data.stats, "one_day_volume", 0),
                "volume_7d" => get(data.stats, "seven_day_volume", 0),
                "total_supply" => get(data.stats, "total_supply", 0),
                "num_owners" => get(data.stats, "num_owners", 0),
                "source" => "opensea"
            )
            OPENSEA_CACHE[cache_key] = (now_time, result)
            return result
        else
            @warn "OpenSea API returned status $(response.status)"
            return Dict("error" => "API error", "status" => response.status)
        end
        
    catch e
        @warn "OpenSea data collection failed: $e"
        return Dict("error" => string(e))
    end
end

"""
Collect data from Alchemy NFT API (free tier)
"""
function collect_alchemy_data(collection_address::String)
    try
        api_key = get(ENV, "ALCHEMY_API_KEY", "")
        base_url = "https://eth-mainnet.g.alchemy.com/nft/v2/$api_key"
        
        # Get collection metadata
        url = "$base_url/getContractMetadata?contractAddress=$collection_address"
        response = HTTP.get(url)
        
        if response.status == 200
            data = JSON3.read(response.body)
            return Dict(
                "name" => get(data.contractMetadata, "name", ""),
                "symbol" => get(data.contractMetadata, "symbol", ""),
                "total_supply" => get(data.contractMetadata, "totalSupply", 0),
                "contract_type" => get(data.contractMetadata, "tokenType", ""),
                "description" => get(data.contractMetadata, "description", ""),
                "image" => get(data.contractMetadata, "image", ""),
                "source" => "alchemy"
            )
        else
            @warn "Alchemy API returned status $(response.status)"
            return Dict("error" => "API error", "status" => response.status)
        end
        
    catch e
        @warn "Alchemy data collection failed: $e"
        return Dict("error" => string(e))
    end
end

"""
Collect onchain data using ETH RPC
"""
function collect_onchain_data(collection_address::String)
    try
        # Use Alchemy or Infura for ETH RPC calls
        rpc_url = "https://eth-mainnet.g.alchemy.com/v2/$(get(ENV, "ALCHEMY_API_KEY", ""))"
        
        # Get contract balance and transaction count
        balance_payload = Dict(
            "jsonrpc" => "2.0",
            "method" => "eth_getBalance",
            "params" => [collection_address, "latest"],
            "id" => 1
        )
        
        response = HTTP.post(rpc_url, 
            ["Content-Type" => "application/json"],
            JSON3.write(balance_payload)
        )
        
        if response.status == 200
            data = JSON3.read(response.body)
            balance = get(data, "result", "0x0")
            
            return Dict(
                "contract_balance" => balance,
                "last_updated" => now(),
                "source" => "onchain"
            )
        else
            return Dict("error" => "RPC error", "status" => response.status)
        end
        
    catch e
        @warn "Onchain data collection failed: $e"
        return Dict("error" => string(e))
    end
end

"""
Collect social sentiment data
"""
function collect_social_data(collection_address::String)
    try
        # For demo purposes, return mock social data
        # In production, would integrate with Twitter API, Discord, etc.
        return Dict(
            "twitter_mentions" => rand(100:1000),
            "sentiment_score" => rand(0.0:0.01:1.0),
            "social_volume_24h" => rand(50:500),
            "influencer_mentions" => rand(0:10),
            "source" => "social_mock"
        )
        
    catch e
        @warn "Social data collection failed: $e"
        return Dict("error" => string(e))
    end
end

"""
Aggregate metadata from multiple sources
"""
function aggregate_metadata(sources::Dict)
    metadata = Dict()
    
    # Priority order: Alchemy -> OpenSea -> Onchain
    for source in ["alchemy", "opensea", "onchain"]
        if haskey(sources, source) && haskey(sources[source], "name")
            metadata["name"] = sources[source]["name"]
            break
        end
    end
    
    # Aggregate other fields with fallbacks
    metadata["description"] = get(get(sources, "alchemy", Dict()), "description", "")
    metadata["image"] = get(get(sources, "alchemy", Dict()), "image", "")
    metadata["total_supply"] = get(get(sources, "opensea", Dict()), "total_supply", 0)
    
    return metadata
end

"""
Aggregate market data from multiple sources
"""
function aggregate_market_data(sources::Dict)
    market_data = Dict()
    
    if haskey(sources, "opensea")
        opensea = sources["opensea"]
        market_data["floor_price"] = get(opensea, "floor_price", 0)
        market_data["volume_24h"] = get(opensea, "volume_24h", 0)
        market_data["volume_7d"] = get(opensea, "volume_7d", 0)
        market_data["market_cap"] = get(opensea, "market_cap", 0)
        market_data["num_owners"] = get(opensea, "num_owners", 0)
    end
    
    return market_data
end

"""
Aggregate social data from multiple sources
"""
function aggregate_social_data(sources::Dict)
    social_data = Dict()
    
    if haskey(sources, "social")
        social = sources["social"]
        social_data["twitter_mentions"] = get(social, "twitter_mentions", 0)
        social_data["sentiment_score"] = get(social, "sentiment_score", 0.5)
        social_data["social_volume_24h"] = get(social, "social_volume_24h", 0)
        social_data["influencer_mentions"] = get(social, "influencer_mentions", 0)
    end
    
    return social_data
end

# Export main function for agent coordinator
export collect_collection_data