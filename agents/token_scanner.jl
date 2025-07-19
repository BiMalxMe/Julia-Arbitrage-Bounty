module TokenScanner

using HTTP
using JSON3
using Logging
using Statistics
using DataStructures
using ..Config: CONFIG
using ..SolanaRPC: solana_rpc_request, fetch_token_accounts_by_owner
using ..Utils: log_info, log_error, safe_json_parse
using Dates

"""
    TokenRisk
Structure to represent risk assessment for a token
"""
struct TokenRisk
    token_address::String
    mint_address::String
    balance::Float64
    is_verified::Bool
    liquidity_score::Float64
    rugpull_indicators::Vector{String}
    risk_level::String  # "LOW", "MEDIUM", "HIGH", "CRITICAL"
    confidence::Float64
end

"""
    scan_wallet_tokens(wallet_address::String)::Dict
Scans all SPL tokens in a wallet and returns risk assessment
"""
function scan_wallet_tokens(wallet_address::String)::Dict
    log_info("Starting token scan for wallet: $wallet_address")
    
    try
        # Fetch all token accounts for the wallet
        token_accounts_resp = fetch_token_accounts_by_owner(wallet_address)
        
        if !haskey(token_accounts_resp, "result") || !haskey(token_accounts_resp["result"], "value")
            return Dict(
                "wallet_address" => wallet_address,
                "error" => "Failed to fetch token accounts",
                "tokens_analyzed" => 0,
                "risks_found" => []
            )
        end
        
        token_accounts = token_accounts_resp["result"]["value"]
        risks = Vector{TokenRisk}()
        
        # Analyze each token account
        for account in token_accounts
            try
                risk = analyze_token_account(account)
                if !isnothing(risk)
                    push!(risks, risk)
                end
            catch e
                log_error("Error analyzing token account: $e")
                continue
            end
        end
        
        # Calculate overall wallet risk score
        wallet_risk_score = calculate_wallet_risk_score(risks)
        
        # Categorize risks by severity
        critical_risks = filter(r -> r.risk_level == "CRITICAL", risks)
        high_risks = filter(r -> r.risk_level == "HIGH", risks)
        medium_risks = filter(r -> r.risk_level == "MEDIUM", risks)
        low_risks = filter(r -> r.risk_level == "LOW", risks)
        
        return Dict(
            "wallet_address" => wallet_address,
            "tokens_analyzed" => length(token_accounts),
            "wallet_risk_score" => wallet_risk_score,
            "total_risks_found" => length(risks),
            "critical_risks" => length(critical_risks),
            "high_risks" => length(high_risks),
            "medium_risks" => length(medium_risks),
            "low_risks" => length(low_risks),
            "detailed_risks" => [token_risk_to_dict(r) for r in risks],
            "recommendations" => generate_recommendations(risks),
            "scan_timestamp" => string(now())
        )
        
    catch e
        log_error("Error in token scan: $e")
        return Dict(
            "wallet_address" => wallet_address,
            "error" => "Token scan failed: $(sprint(showerror, e))",
            "tokens_analyzed" => 0,
            "risks_found" => []
        )
    end
end

"""
    analyze_token_account(account::Dict)::Union{TokenRisk, Nothing}
Analyzes a single token account for risk factors
"""
function analyze_token_account(account::Dict)::Union{TokenRisk, Nothing}
    try
        account_info = account["account"]
        parsed_info = account_info["data"]["parsed"]["info"]
        
        mint_address = parsed_info["mint"]
        balance = parse(Float64, parsed_info["tokenAmount"]["amount"]) / 
                 (10 ^ parsed_info["tokenAmount"]["decimals"])
        
        # Skip if balance is zero
        if balance == 0.0
            return nothing
        end
        
        # Check if token is verified
        is_verified = check_token_verification(mint_address)
        
        # Calculate liquidity score
        liquidity_score = calculate_liquidity_score(mint_address)
        
        # Check for rugpull indicators
        rugpull_indicators = check_rugpull_indicators(mint_address)
        
        # Calculate risk level
        risk_level, confidence = calculate_risk_level(is_verified, liquidity_score, rugpull_indicators)
        
        return TokenRisk(
            account["pubkey"],
            mint_address,
            balance,
            is_verified,
            liquidity_score,
            rugpull_indicators,
            risk_level,
            confidence
        )
        
    catch e
        log_error("Error analyzing token account: $e")
        return nothing
    end
end

"""
    check_token_verification(mint_address::String)::Bool
Checks if a token is verified using Solana token lists
"""
function check_token_verification(mint_address::String)::Bool
    try
        # Check against Solana Labs token list
        solana_token_list_url = "https://raw.githubusercontent.com/solana-labs/token-list/main/src/tokens/solana.tokenlist.json"
        
        headers = ["User-Agent" => "ChainGuardian/1.0"]
        response = HTTP.get(solana_token_list_url, headers)
        
        if response.status == 200
            token_list = JSON3.read(String(response.body))
            tokens = get(token_list, "tokens", [])
            
            for token in tokens
                if get(token, "address", "") == mint_address
                    return true
                end
            end
        end
        
        return false
        
    catch e
        log_error("Error checking token verification: $e")
        return false
    end
end

"""
    calculate_liquidity_score(mint_address::String)::Float64
Calculates liquidity score using Birdeye API
"""
function calculate_liquidity_score(mint_address::String)::Float64
    try
        # Use Birdeye API to get token liquidity data
        birdeye_url = "https://public-api.birdeye.so/defi/token_overview"
        
        headers = [
            "X-API-KEY" => get(CONFIG, "BIRDEYE_API_KEY", ""),
            "Content-Type" => "application/json"
        ]
        
        params = Dict("address" => mint_address)
        
        if !isempty(CONFIG["BIRDEYE_API_KEY"])
            response = HTTP.get(birdeye_url, headers, query=params)
            
            if response.status == 200
                data = JSON3.read(String(response.body))
                
                if haskey(data, "data") && haskey(data["data"], "liquidity")
                    liquidity = data["data"]["liquidity"]
                    
                    # Normalize liquidity score (0-1 scale)
                    if liquidity > 1000000  # > $1M liquidity
                        return 1.0
                    elseif liquidity > 100000  # > $100K liquidity
                        return 0.8
                    elseif liquidity > 10000   # > $10K liquidity
                        return 0.6
                    elseif liquidity > 1000    # > $1K liquidity
                        return 0.4
                    else
                        return 0.2
                    end
                end
            end
        end
        
        # Default to medium-low liquidity score if API unavailable
        return 0.3
        
    catch e
        log_error("Error calculating liquidity score: $e")
        return 0.3
    end
end

"""
    check_rugpull_indicators(mint_address::String)::Vector{String}
Checks for various rugpull indicators
"""
function check_rugpull_indicators(mint_address::String)::Vector{String}
    indicators = String[]
    
    try
        # Get token account info
        account_info = solana_rpc_request("getAccountInfo", [mint_address, Dict("encoding" => "jsonParsed")])
        
        if haskey(account_info, "result") && haskey(account_info["result"], "value")
            token_data = account_info["result"]["value"]["data"]["parsed"]["info"]
            
            # Check for freeze authority
            if haskey(token_data, "freezeAuthority") && !isnothing(token_data["freezeAuthority"])
                push!(indicators, "HAS_FREEZE_AUTHORITY")
            end
            
            # Check for mint authority
            if haskey(token_data, "mintAuthority") && !isnothing(token_data["mintAuthority"])
                push!(indicators, "HAS_MINT_AUTHORITY")
            end
            
            # Check supply
            supply = parse(Float64, token_data["supply"])
            if supply > 1e12  # Very high supply
                push!(indicators, "EXCESSIVE_SUPPLY")
            end
            
            # Check decimals (unusual decimal places can be suspicious)
            decimals = token_data["decimals"]
            if decimals > 9 || decimals < 6
                push!(indicators, "UNUSUAL_DECIMALS")
            end
        end
        
        # Check for suspicious token name patterns (if available)
        # This would require additional API calls to get metadata
        
    catch e
        log_error("Error checking rugpull indicators: $e")
    end
    
    return indicators
end

"""
    calculate_risk_level(is_verified::Bool, liquidity_score::Float64, rugpull_indicators::Vector{String})::Tuple{String, Float64}
Calculates overall risk level and confidence
"""
function calculate_risk_level(is_verified::Bool, liquidity_score::Float64, rugpull_indicators::Vector{String})::Tuple{String, Float64}
    risk_score = 0.0
    confidence = 0.8
    
    # Verification factor
    if !is_verified
        risk_score += 0.3
    end
    
    # Liquidity factor
    if liquidity_score < 0.2
        risk_score += 0.4
    elseif liquidity_score < 0.5
        risk_score += 0.2
    end
    
    # Rugpull indicators
    critical_indicators = ["HAS_FREEZE_AUTHORITY", "HAS_MINT_AUTHORITY"]
    warning_indicators = ["EXCESSIVE_SUPPLY", "UNUSUAL_DECIMALS"]
    
    for indicator in rugpull_indicators
        if indicator in critical_indicators
            risk_score += 0.3
        elseif indicator in warning_indicators
            risk_score += 0.1
        end
    end
    
    # Determine risk level
    if risk_score >= 0.8
        return ("CRITICAL", confidence)
    elseif risk_score >= 0.6
        return ("HIGH", confidence)
    elseif risk_score >= 0.3
        return ("MEDIUM", confidence)
    else
        return ("LOW", confidence)
    end
end

"""
    calculate_wallet_risk_score(risks::Vector{TokenRisk})::Float64
Calculates overall wallet risk score
"""
function calculate_wallet_risk_score(risks::Vector{TokenRisk})::Float64
    if isempty(risks)
        return 0.0
    end
    
    # Weight by token balance and risk level
    total_weighted_risk = 0.0
    total_weight = 0.0
    
    for risk in risks
        weight = risk.balance  # Use balance as weight
        risk_value = risk.risk_level == "CRITICAL" ? 1.0 :
                    risk.risk_level == "HIGH" ? 0.8 :
                    risk.risk_level == "MEDIUM" ? 0.5 : 0.2
        
        total_weighted_risk += weight * risk_value
        total_weight += weight
    end
    
    return total_weight > 0 ? total_weighted_risk / total_weight : 0.0
end

"""
    token_risk_to_dict(risk::TokenRisk)::Dict
Converts TokenRisk struct to dictionary
"""
function token_risk_to_dict(risk::TokenRisk)::Dict
    return Dict(
        "token_address" => risk.token_address,
        "mint_address" => risk.mint_address,
        "balance" => risk.balance,
        "is_verified" => risk.is_verified,
        "liquidity_score" => risk.liquidity_score,
        "rugpull_indicators" => risk.rugpull_indicators,
        "risk_level" => risk.risk_level,
        "confidence" => risk.confidence
    )
end

"""
    generate_recommendations(risks::Vector{TokenRisk})::Vector{String}
Generates actionable recommendations based on risks found
"""
function generate_recommendations(risks::Vector{TokenRisk})::Vector{String}
    recommendations = String[]
    
    critical_risks = filter(r -> r.risk_level == "CRITICAL", risks)
    high_risks = filter(r -> r.risk_level == "HIGH", risks)
    
    if !isempty(critical_risks)
        push!(recommendations, "⚠️ URGENT: Consider immediately selling or transferring tokens with CRITICAL risk levels")
        push!(recommendations, "🔍 Investigate tokens with freeze/mint authority - they can be manipulated by developers")
    end
    
    if !isempty(high_risks)
        push!(recommendations, "⚡ HIGH PRIORITY: Review tokens with HIGH risk levels for potential exit strategy")
        push!(recommendations, "📊 Monitor liquidity levels of high-risk tokens closely")
    end
    
    unverified_tokens = filter(r -> !r.is_verified, risks)
    if !isempty(unverified_tokens)
        push!(recommendations, "✅ Verify legitimacy of unverified tokens through official channels")
    end
    
    low_liquidity_tokens = filter(r -> r.liquidity_score < 0.3, risks)
    if !isempty(low_liquidity_tokens)
        push!(recommendations, "💧 Be cautious with low-liquidity tokens - they may be difficult to sell")
    end
    
    if isempty(recommendations)
        push!(recommendations, "✅ No immediate action required - wallet appears to have low risk exposure")
    end
    
    return recommendations
end

export scan_wallet_tokens, TokenRisk

end # module