module TxScanner

using HTTP
using JSON3
using Logging
using Dates
using Statistics
using DataStructures
using ..Config: CONFIG
using ..SolanaRPC: solana_rpc_request
using ..Utils: log_info, log_error, safe_json_parse

"""
    TransactionRisk
Structure to represent risk assessment for a transaction
"""
struct TransactionRisk
    signature::String
    slot::Int64
    timestamp::DateTime
    risk_type::String
    severity::String
    description::String
    involved_addresses::Vector{String}
    confidence::Float64
end

"""
    scan_wallet_transactions(wallet_address::String, limit::Int=100)::Dict
Scans transaction history for suspicious patterns and risky interactions
"""
function scan_wallet_transactions(wallet_address::String, limit::Int=100)::Dict
    log_info("Starting transaction scan for wallet: $wallet_address")
    
    try
        # Fetch transaction signatures
        signatures_resp = fetch_transaction_signatures(wallet_address, limit)
        
        if !haskey(signatures_resp, "result")
            return Dict(
                "wallet_address" => wallet_address,
                "error" => "Failed to fetch transaction signatures",
                "transactions_analyzed" => 0,
                "risks_found" => []
            )
        end
        
        signatures = signatures_resp["result"]
        risks = Vector{TransactionRisk}()
        
        # Analyze each transaction (in batches to avoid rate limits)
        batch_size = 10
        for i in 1:batch_size:length(signatures)
            batch_end = min(i + batch_size - 1, length(signatures))
            batch_signatures = signatures[i:batch_end]
            
            # Process batch concurrently
            batch_risks = analyze_transaction_batch(batch_signatures)
            append!(risks, batch_risks)
            
            # Small delay to respect rate limits
            sleep(0.1)
        end
        
        # Calculate risk metrics
        risk_summary = calculate_transaction_risk_summary(risks)
        
        return Dict(
            "wallet_address" => wallet_address,
            "transactions_analyzed" => length(signatures),
            "risks_found" => length(risks),
            "risk_summary" => risk_summary,
            "detailed_risks" => [transaction_risk_to_dict(r) for r in risks],
            "recommendations" => generate_transaction_recommendations(risks),
            "scan_timestamp" => string(now())
        )
        
    catch e
        log_error("Error in transaction scan: $e")
        return Dict(
            "wallet_address" => wallet_address,
            "error" => "Transaction scan failed: $(sprint(showerror, e))",
            "transactions_analyzed" => 0,
            "risks_found" => []
        )
    end
end

"""
    fetch_transaction_signatures(wallet_address::String, limit::Int)::Dict
Fetches transaction signatures for a wallet
"""
function fetch_transaction_signatures(wallet_address::String, limit::Int)::Dict
    return solana_rpc_request("getSignaturesForAddress", [
        wallet_address,
        Dict("limit" => limit)
    ])
end

"""
    analyze_transaction_batch(signatures::Vector)::Vector{TransactionRisk}
Analyzes a batch of transactions for risks
"""
function analyze_transaction_batch(signatures::Vector)::Vector{TransactionRisk}
    risks = Vector{TransactionRisk}()
    
    for sig_info in signatures
        try
            signature = sig_info["signature"]
            slot = sig_info["slot"]
            
            # Fetch full transaction details
            tx_resp = solana_rpc_request("getTransaction", [
                signature,
                Dict("encoding" => "jsonParsed", "maxSupportedTransactionVersion" => 0)
            ])
            
            if haskey(tx_resp, "result") && !isnothing(tx_resp["result"])
                tx_risks = analyze_single_transaction(tx_resp["result"], signature, slot)
                append!(risks, tx_risks)
            end
            
        catch e
            log_error("Error analyzing transaction $(get(sig_info, "signature", "unknown")): $e")
            continue
        end
    end
    
    return risks
end

"""
    analyze_single_transaction(tx_data::Dict, signature::String, slot::Int64)::Vector{TransactionRisk}
Analyzes a single transaction for various risk patterns
"""
function analyze_single_transaction(tx_data::Dict, signature::String, slot::Int64)::Vector{TransactionRisk}
    risks = Vector{TransactionRisk}()
    
    try
        # Extract transaction timestamp
        timestamp = DateTime(1970, 1, 1) + Millisecond(tx_data["blockTime"] * 1000)
        
        # Extract account keys and instructions
        message = tx_data["transaction"]["message"]
        account_keys = message["accountKeys"]
        instructions = message["instructions"]
        
        # Check for risky program interactions
        program_risks = check_risky_program_interactions(instructions, account_keys, signature, slot, timestamp)
        append!(risks, program_risks)
        
        # Check for suspicious token transfers
        token_risks = check_suspicious_token_transfers(instructions, account_keys, signature, slot, timestamp)
        append!(risks, token_risks)
        
        # Check for MEV/sandwich attacks
        mev_risks = check_mev_patterns(tx_data, signature, slot, timestamp)
        append!(risks, mev_risks)
        
        # Check for unusual transaction patterns
        pattern_risks = check_unusual_patterns(tx_data, signature, slot, timestamp)
        append!(risks, pattern_risks)
        
    catch e
        log_error("Error analyzing transaction details: $e")
    end
    
    return risks
end

"""
    check_risky_program_interactions(instructions::Vector, account_keys::Vector, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
Checks for interactions with known risky programs
"""
function check_risky_program_interactions(instructions::Vector, account_keys::Vector, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
    risks = Vector{TransactionRisk}()
    
    # Known risky program IDs (this would be maintained from threat intelligence)
    risky_programs = Set([
        # Add known scam/risky program IDs here
        # These would be maintained from community reports and threat intelligence
    ])
    
    # Suspicious program patterns
    suspicious_patterns = [
        "pump" => "Potential pump and dump scheme",
        "drain" => "Potential wallet drainer",
        "rug" => "Potential rug pull mechanism",
        "fake" => "Potential fake token program"
    ]
    
    for instruction in instructions
        try
            program_id = instruction["programId"]
            
            # Check against known risky programs
            if program_id in risky_programs
                push!(risks, TransactionRisk(
                    signature,
                    slot,
                    timestamp,
                    "RISKY_PROGRAM_INTERACTION",
                    "HIGH",
                    "Interaction with known risky program: $program_id",
                    [program_id],
                    0.9
                ))
            end
            
            # Check for suspicious program name patterns
            # This would require additional metadata lookup
            
        catch e
            log_error("Error checking program interaction: $e")
            continue
        end
    end
    
    return risks
end

"""
    check_suspicious_token_transfers(instructions::Vector, account_keys::Vector, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
Checks for suspicious token transfer patterns
"""
function check_suspicious_token_transfers(instructions::Vector, account_keys::Vector, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
    risks = Vector{TransactionRisk}()
    
    token_transfers = []
    
    for instruction in instructions
        try
            if instruction["programId"] == "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
                # This is a token program instruction
                if haskey(instruction, "parsed") && haskey(instruction["parsed"], "info")
                    info = instruction["parsed"]["info"]
                    
                    # Check for large token transfers to unknown addresses
                    if haskey(info, "amount") && haskey(info, "destination")
                        amount = parse(Float64, info["amount"])
                        destination = info["destination"]
                        
                        # Flag unusually large transfers
                        if amount > 1e9  # This threshold would be configurable
                            push!(risks, TransactionRisk(
                                signature,
                                slot,
                                timestamp,
                                "LARGE_TOKEN_TRANSFER",
                                "MEDIUM",
                                "Large token transfer of $amount to $destination",
                                [destination],
                                0.7
                            ))
                        end
                    end
                end
            end
            
        catch e
            log_error("Error checking token transfer: $e")
            continue
        end
    end
    
    return risks
end

"""
    check_mev_patterns(tx_data::Dict, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
Checks for MEV (Maximal Extractable Value) attack patterns
"""
function check_mev_patterns(tx_data::Dict, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
    risks = Vector{TransactionRisk}()
    
    try
        # Check for high priority fees (potential MEV)
        if haskey(tx_data, "meta") && haskey(tx_data["meta"], "fee")
            fee = tx_data["meta"]["fee"]
            
            # Flag unusually high fees (potential MEV attack)
            if fee > 10000  # 0.01 SOL - this threshold would be configurable
                push!(risks, TransactionRisk(
                    signature,
                    slot,
                    timestamp,
                    "HIGH_PRIORITY_FEE",
                    "MEDIUM",
                    "Transaction used high priority fee ($fee lamports), possible MEV",
                    String[],
                    0.6
                ))
            end
        end
        
        # Check for sandwich attack patterns
        # This would require analyzing surrounding transactions in the same block
        
    catch e
        log_error("Error checking MEV patterns: $e")
    end
    
    return risks
end

"""
    check_unusual_patterns(tx_data::Dict, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
Checks for unusual transaction patterns
"""
function check_unusual_patterns(tx_data::Dict, signature::String, slot::Int64, timestamp::DateTime)::Vector{TransactionRisk}
    risks = Vector{TransactionRisk}()
    
    try
        message = tx_data["transaction"]["message"]
        
        # Check for unusual number of instructions
        if haskey(message, "instructions")
            instruction_count = length(message["instructions"])
            
            if instruction_count > 20  # Unusually complex transaction
                push!(risks, TransactionRisk(
                    signature,
                    slot,
                    timestamp,
                    "COMPLEX_TRANSACTION",
                    "LOW",
                    "Transaction has unusually high number of instructions ($instruction_count)",
                    String[],
                    0.4
                ))
            end
        end
        
        # Check for failed transactions (might indicate attack attempts)
        if haskey(tx_data, "meta") && haskey(tx_data["meta"], "err") && !isnothing(tx_data["meta"]["err"])
            push!(risks, TransactionRisk(
                signature,
                slot,
                timestamp,
                "FAILED_TRANSACTION",
                "LOW",
                "Transaction failed: $(tx_data["meta"]["err"])",
                String[],
                0.3
            ))
        end
        
    catch e
        log_error("Error checking unusual patterns: $e")
    end
    
    return risks
end

"""
    calculate_transaction_risk_summary(risks::Vector{TransactionRisk})::Dict
Calculates summary statistics for transaction risks
"""
function calculate_transaction_risk_summary(risks::Vector{TransactionRisk})::Dict
    if isempty(risks)
        return Dict(
            "total_risks" => 0,
            "by_severity" => Dict(),
            "by_type" => Dict(),
            "recent_risks" => 0,
            "overall_risk_score" => 0.0
        )
    end
    
    # Count by severity
    severity_counts = Dict{String, Int}()
    for risk in risks
        severity_counts[risk.severity] = get(severity_counts, risk.severity, 0) + 1
    end
    
    # Count by type
    type_counts = Dict{String, Int}()
    for risk in risks
        type_counts[risk.risk_type] = get(type_counts, risk.risk_type, 0) + 1
    end
    
    # Count recent risks (last 24 hours)
    recent_cutoff = now() - Day(1)
    recent_risks = count(r -> r.timestamp > recent_cutoff, risks)
    
    # Calculate overall risk score
    risk_score = 0.0
    for risk in risks
        severity_weight = risk.severity == "HIGH" ? 0.8 :
                         risk.severity == "MEDIUM" ? 0.5 :
                         risk.severity == "LOW" ? 0.2 : 0.1
        risk_score += severity_weight * risk.confidence
    end
    risk_score = min(risk_score / length(risks), 1.0)
    
    return Dict(
        "total_risks" => length(risks),
        "by_severity" => severity_counts,
        "by_type" => type_counts,
        "recent_risks" => recent_risks,
        "overall_risk_score" => risk_score
    )
end

"""
    transaction_risk_to_dict(risk::TransactionRisk)::Dict
Converts TransactionRisk struct to dictionary
"""
function transaction_risk_to_dict(risk::TransactionRisk)::Dict
    return Dict(
        "signature" => risk.signature,
        "slot" => risk.slot,
        "timestamp" => string(risk.timestamp),
        "risk_type" => risk.risk_type,
        "severity" => risk.severity,
        "description" => risk.description,
        "involved_addresses" => risk.involved_addresses,
        "confidence" => risk.confidence
    )
end

"""
    generate_transaction_recommendations(risks::Vector{TransactionRisk})::Vector{String}
Generates recommendations based on transaction risks
"""
function generate_transaction_recommendations(risks::Vector{TransactionRisk})::Vector{String}
    recommendations = String[]
    
    high_risks = filter(r -> r.severity == "HIGH", risks)
    recent_risks = filter(r -> r.timestamp > now() - Day(1), risks)
    
    if !isempty(high_risks)
        push!(recommendations, "🚨 HIGH RISK: Wallet has interacted with potentially dangerous programs")
        push!(recommendations, "🔍 Review recent transactions for unauthorized activities")
    end
    
    if !isempty(recent_risks)
        push!(recommendations, "⚠️ Recent suspicious activity detected - monitor wallet closely")
    end
    
    mev_risks = filter(r -> r.risk_type == "HIGH_PRIORITY_FEE", risks)
    if !isempty(mev_risks)
        push!(recommendations, "💰 High priority fees detected - possible MEV activity")
    end
    
    failed_txs = filter(r -> r.risk_type == "FAILED_TRANSACTION", risks)
    if length(failed_txs) > 5
        push!(recommendations, "❌ Multiple failed transactions - possible attack attempts")
    end
    
    if isempty(recommendations)
        push!(recommendations, "✅ Transaction history appears normal - no significant risks detected")
    end
    
    return recommendations
end

export scan_wallet_transactions, TransactionRisk

end # module