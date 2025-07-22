"""
JuliaOS NFT Data Collector Agent

This agent is responsible for collecting NFT collection data from various sources
including OpenSea API, Alchemy NFT API, and onchain data.
"""

include("src/JuliaOS.jl")
using .JuliaOS
using HTTP
using JSON3

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
agent = JuliaOS.create_agent(DATA_COLLECTOR_CONFIG)

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
        
        @info "Data collection completed successfully"
        return Dict("success" => true, "data" => data)
        
    catch e
        @error "Data collection failed: $e"
        return Dict("success" => false, "error" => string(e))
    end
end

"""
Collect data from OpenSea API (v2)
"""
function collect_opensea_data(collection_address::String)
    try
        # Special case for CryptoPunks, which has a different API structure
        if collection_address == "0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB"
            @info "Using CryptoPunks-specific logic for OpenSea data."
            # For CryptoPunks, we can often rely on Alchemy or other sources,
            # but we can also use a simplified OpenSea call or a different dedicated API.
            # For now, we will return a result that lets Alchemy take precedence.
            return Dict("source" => "opensea_v2", "floor_price" => nothing)
        end

        headers = Dict(
            "Accept" => "application/json",
            "X-API-KEY" => get(ENV, "OPENSEA_API_KEY", "")
        )
        
        # --- Step 1: Get the collection slug from the contract address ---
        # The v2 API uses a 'slug' to identify collections, not the contract address.
        slug_url = "https://api.opensea.io/api/v2/chain/ethereum/contract/$(collection_address)/nfts"
        slug_response = HTTP.get(slug_url, headers=headers)
        
        collection_slug = ""
        if slug_response.status == 200
            slug_data = JSON3.read(slug_response.body)
            if !isempty(get(slug_data, :nfts, []))
                collection_slug = get(slug_data.nfts[1], :collection, "")
            end
        else
            @warn "OpenSea v2 NFT endpoint returned status $(slug_response.status). Could not retrieve collection slug."
            return Dict("error" => "API error", "status" => slug_response.status)
        end
        
        if isempty(collection_slug)
            @warn "Could not determine collection slug for $collection_address"
            return Dict("error" => "Could not determine collection slug")
        end

        # --- Step 2: Get collection stats using the slug ---
        stats_url = "https://api.opensea.io/api/v2/collections/$(collection_slug)/stats"
        stats_response = HTTP.get(stats_url, headers=headers)
        
        if stats_response.status == 200
            data = JSON3.read(stats_response.body)
            total = get(data, :total, Dict())
            return Dict(
                "floor_price" => get(total, :floor_price, 0),
                "market_cap" => get(total, :market_cap, 0),
                "volume_24h" => get(total, :volume, 0),
                "volume_7d" => get(get(data, :intervals, [])[1], :volume, 0), # Assuming first interval is 7d
                "total_supply" => get(total, :supply, 0),
                "num_owners" => get(total, :owner_count, 0),
                "source" => "opensea_v2"
            )
        else
            @warn "OpenSea v2 stats endpoint returned status $(stats_response.status)"
            return Dict("error" => "API error", "status" => stats_response.status)
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
        
        alchemy_data = Dict("source" => "alchemy")

        # --- Get collection metadata ---
        metadata_url = "$base_url/getContractMetadata?contractAddress=$collection_address"
        metadata_response = HTTP.get(metadata_url)
        
        if metadata_response.status == 200
            metadata = JSON3.read(metadata_response.body)
            alchemy_data["name"] = get(get(metadata, :contractMetadata, Dict()), :name, "")
            alchemy_data["symbol"] = get(get(metadata, :contractMetadata, Dict()), :symbol, "")
            alchemy_data["total_supply"] = get(get(metadata, :contractMetadata, Dict()), :totalSupply, 0)
            alchemy_data["contract_type"] = get(get(metadata, :contractMetadata, Dict()), :tokenType, "")
            alchemy_data["description"] = get(get(metadata, :contractMetadata, Dict()), :description, "")
            alchemy_data["image"] = get(get(metadata, :contractMetadata, Dict()), :image, "")
        else
            @warn "Alchemy getContractMetadata API returned status $(metadata_response.status)"
        end

        # --- Get floor price ---
        floor_price_url = "$base_url/getFloorPrice?contractAddress=$collection_address"
        floor_price_response = HTTP.get(floor_price_url)

        if floor_price_response.status == 200
            floor_data = JSON3.read(floor_price_response.body)
            
            opensea_fp = get(get(floor_data, :openSea, Dict()), :floorPrice, nothing)
            looksrare_fp = get(get(floor_data, :looksRare, Dict()), :floorPrice, nothing)

            # Prioritize OpenSea floor price from Alchemy, fallback to LooksRare
            if !isnothing(opensea_fp) && opensea_fp > 0
                alchemy_data["floor_price"] = opensea_fp
            elseif !isnothing(looksrare_fp) && looksrare_fp > 0
                alchemy_data["floor_price"] = looksrare_fp
            end
        else
             @warn "Alchemy getFloorPrice API returned status $(floor_price_response.status)"
        end
        
        return alchemy_data
        
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
    # Try OpenSea first
    if haskey(sources, "opensea") && !haskey(sources["opensea"], "error")
        opensea = sources["opensea"]
        market_data["floor_price"] = get(opensea, "floor_price", 0)
        market_data["volume_24h"] = get(opensea, "volume_24h", 0)
        market_data["volume_7d"] = get(opensea, "volume_7d", 0)
        market_data["market_cap"] = get(opensea, "market_cap", 0)
        market_data["num_owners"] = get(opensea, "num_owners", 0)
    end
    # Fallback: If floor_price is missing/zero, try Alchemy
    if !haskey(market_data, "floor_price") || isnothing(market_data["floor_price"]) || market_data["floor_price"] <= 0
        if haskey(sources, "alchemy") && haskey(sources["alchemy"], "floor_price") && !isnothing(sources["alchemy"]["floor_price"]) && sources["alchemy"]["floor_price"] > 0
            market_data["floor_price"] = sources["alchemy"]["floor_price"]
        else
            @warn "No valid floor_price from OpenSea or Alchemy."
            # Set to nothing to indicate that no valid price was found
            market_data["floor_price"] = nothing
        end
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