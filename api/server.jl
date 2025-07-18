module ChainGuardianAPI

using HTTP
using Sockets
using JSON3
using Dates
using Logging
using Base.Threads
using ..Config
using ..Utils: log_info, log_error, safe_json_parse
using ..SwarmCoordinator: start_swarm_coordinator, stop_swarm_coordinator, 
                          submit_wallet_analysis_task, submit_token_analysis_task,
                          submit_transaction_analysis_task, get_task_status, get_swarm_status
using ..RiskEvaluator: evaluate_wallet_risk

"""
    ChainGuardian API Server
Enhanced API server with swarm integration
"""

const AGENT_METADATA = Dict(
    "name" => "ChainGuardian",
    "version" => "2.0.0",
    "description" => "Comprehensive Solana wallet risk analysis with swarm orchestration",
    "author" => "ChainGuardian Team",
    "license" => "MIT",
    "capabilities" => [
        "token_risk_analysis",
        "transaction_risk_analysis", 
        "rugpull_detection",
        "airdrop_discovery",
        "comprehensive_risk_assessment",
        "swarm_orchestration"
    ]
)

"""
    start_chainguardian_server()
Starts the ChainGuardian API server with swarm integration
"""
function start_chainguardian_server()
    log_info("Starting ChainGuardian API Server...")
    
    # Load configuration
    Config.load_config()
    
    # Start swarm coordinator
    start_swarm_coordinator()
    
    # Start HTTP server
    port = parse(Int, CONFIG["SERVICE_PORT"])
    log_info("Starting HTTP server on 127.0.0.1:$port")
    
    try
        HTTP.serve(handle_request, ip"127.0.0.1", port)
    catch e
        log_error("Failed to start server: $e")
        stop_swarm_coordinator()
        rethrow(e)
    end
end

"""
    stop_chainguardian_server()
Stops the ChainGuardian API server
"""
function stop_chainguardian_server()
    log_info("Stopping ChainGuardian API Server...")
    stop_swarm_coordinator()
end

"""
    handle_request(req::HTTP.Request)::HTTP.Response
Main request handler for the API
"""
function handle_request(req::HTTP.Request)::HTTP.Response
    try
        # Add CORS headers
        headers = [
            "Access-Control-Allow-Origin" => "*",
            "Access-Control-Allow-Methods" => "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers" => "Content-Type, Authorization",
            "Content-Type" => "application/json"
        ]
        
        # Handle preflight requests
        if req.method == "OPTIONS"
            return HTTP.Response(200, headers, "")
        end
        
        # Route requests
        if req.method == "GET" && req.target == "/status"
            return handle_status_request(headers)
        elseif req.method == "GET" && req.target == "/swarm/status"
            return handle_swarm_status_request(headers)
        elseif req.method == "GET" && startswith(req.target, "/risk/")
            return handle_risk_analysis_request(req, headers)
        elseif req.method == "POST" && req.target == "/risk/analyze"
            return handle_risk_analysis_post(req, headers)
        elseif req.method == "POST" && req.target == "/swarm/submit"
            return handle_swarm_submit_request(req, headers)
        elseif req.method == "GET" && startswith(req.target, "/task/")
            return handle_task_status_request(req, headers)
        elseif req.method == "GET" && req.target == "/health"
            return handle_health_check(headers)
        else
            return HTTP.Response(404, headers, JSON3.write(Dict("error" => "Not Found")))
        end
        
    catch e
        log_error("Request handling error: $e")
        error_response = Dict(
            "error" => "Internal server error",
            "details" => sprint(showerror, e),
            "timestamp" => string(now())
        )
        return HTTP.Response(500, ["Content-Type" => "application/json"], JSON3.write(error_response))
    end
end

"""
    handle_status_request(headers::Vector{Pair{String, String}})::HTTP.Response
Handles status endpoint requests
"""
function handle_status_request(headers::Vector{Pair{String, String}})::HTTP.Response
    swarm_status = get_swarm_status()
    
    status_data = Dict(
        "status" => "ok",
        "timestamp" => string(now()),
        "agent" => AGENT_METADATA,
        "swarm" => swarm_status,
        "config" => Dict(
            "solana_rpc_url" => CONFIG["SOLANA_RPC_URL"],
            "service_port" => CONFIG["SERVICE_PORT"],
            "threads" => CONFIG["THREADS"]
        )
    )
    
    return HTTP.Response(200, headers, JSON3.write(status_data))
end

"""
    handle_swarm_status_request(headers::Vector{Pair{String, String}})::HTTP.Response
Handles swarm status requests
"""
function handle_swarm_status_request(headers::Vector{Pair{String, String}})::HTTP.Response
    swarm_status = get_swarm_status()
    return HTTP.Response(200, headers, JSON3.write(swarm_status))
end

"""
    handle_risk_analysis_request(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
Handles GET requests for risk analysis
"""
function handle_risk_analysis_request(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
    # Extract wallet address from URL path
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Invalid request path")))
    end
    
    wallet_address = path_parts[3]
    
    # Validate wallet address format (basic validation)
    if length(wallet_address) < 32 || length(wallet_address) > 44
        return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Invalid wallet address format")))
    end
    
    log_info("Processing risk analysis request for wallet: $wallet_address")
    
    # Submit to swarm for processing
    task_id = submit_wallet_analysis_task(wallet_address, 2)  # High priority
    
    # Wait for completion (with timeout)
    result = wait_for_task_completion(task_id, 60.0)  # 60 second timeout
    
    if isnothing(result)
        # Task still running, return task ID for polling
        response = Dict(
            "status" => "processing",
            "task_id" => task_id,
            "message" => "Analysis in progress. Use task_id to check status.",
            "estimated_completion" => "30-60 seconds"
        )
        return HTTP.Response(202, headers, JSON3.write(response))
    else
        # Task completed, return result
        return HTTP.Response(200, headers, JSON3.write(result))
    end
end

"""
    handle_risk_analysis_post(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
Handles POST requests for risk analysis
"""
function handle_risk_analysis_post(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
    # Parse request body
    body = String(req.body)
    payload = safe_json_parse(body)
    
    if haskey(payload, "error")
        return HTTP.Response(400, headers, JSON3.write(payload))
    end
    
    # Validate required fields
    if !haskey(payload, "wallet_address")
        return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Missing 'wallet_address' field")))
    end
    
    wallet_address = payload["wallet_address"]
    analysis_type = get(payload, "analysis_type", "comprehensive")
    priority = get(payload, "priority", 1)
    async_mode = get(payload, "async", false)
    
    log_info("Processing $analysis_type analysis for wallet: $wallet_address")
    
    # Submit appropriate task based on analysis type
    task_id = if analysis_type == "tokens"
        submit_token_analysis_task(wallet_address, priority)
    elseif analysis_type == "transactions"
        submit_transaction_analysis_task(wallet_address, priority)
    else
        submit_wallet_analysis_task(wallet_address, priority)
    end
    
    if async_mode
        # Return task ID immediately
        response = Dict(
            "status" => "submitted",
            "task_id" => task_id,
            "message" => "Analysis submitted. Use task_id to check status."
        )
        return HTTP.Response(202, headers, JSON3.write(response))
    else
        # Wait for completion
        result = wait_for_task_completion(task_id, 90.0)
        
        if isnothing(result)
            response = Dict(
                "status" => "timeout",
                "task_id" => task_id,
                "message" => "Analysis timed out. Use task_id to check status."
            )
            return HTTP.Response(202, headers, JSON3.write(response))
        else
            return HTTP.Response(200, headers, JSON3.write(result))
        end
    end
end

"""
    handle_swarm_submit_request(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
Handles swarm task submission requests
"""
function handle_swarm_submit_request(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
    body = String(req.body)
    payload = safe_json_parse(body)
    
    if haskey(payload, "error")
        return HTTP.Response(400, headers, JSON3.write(payload))
    end
    
    # Validate required fields
    required_fields = ["task_type", "wallet_address"]
    for field in required_fields
        if !haskey(payload, field)
            return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Missing required field: $field")))
        end
    end
    
    task_type = payload["task_type"]
    wallet_address = payload["wallet_address"]
    priority = get(payload, "priority", 1)
    
    # Submit task based on type
    task_id = if task_type == "token_analysis"
        submit_token_analysis_task(wallet_address, priority)
    elseif task_type == "transaction_analysis"
        submit_transaction_analysis_task(wallet_address, priority)
    elseif task_type == "comprehensive_analysis"
        submit_wallet_analysis_task(wallet_address, priority)
    else
        return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Invalid task_type: $task_type")))
    end
    
    response = Dict(
        "status" => "submitted",
        "task_id" => task_id,
        "task_type" => task_type,
        "wallet_address" => wallet_address,
        "priority" => priority
    )
    
    return HTTP.Response(200, headers, JSON3.write(response))
end

"""
    handle_task_status_request(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
Handles task status requests
"""
function handle_task_status_request(req::HTTP.Request, headers::Vector{Pair{String, String}})::HTTP.Response
    # Extract task ID from URL
    path_parts = split(req.target, "/")
    if length(path_parts) < 3
        return HTTP.Response(400, headers, JSON3.write(Dict("error" => "Invalid request path")))
    end
    
    task_id = path_parts[3]
    
    # Get task status
    task_info = get_task_status(task_id)
    
    if isnothing(task_info)
        return HTTP.Response(404, headers, JSON3.write(Dict("error" => "Task not found")))
    end
    
    return HTTP.Response(200, headers, JSON3.write(task_info))
end

"""
    handle_health_check(headers::Vector{Pair{String, String}})::HTTP.Response
Handles health check requests
"""
function handle_health_check(headers::Vector{Pair{String, String}})::HTTP.Response
    health_data = Dict(
        "status" => "healthy",
        "timestamp" => string(now()),
        "uptime" => "N/A",  # Would track actual uptime
        "version" => AGENT_METADATA["version"],
        "swarm_healthy" => get_swarm_status()["is_running"]
    )
    
    return HTTP.Response(200, headers, JSON3.write(health_data))
end

"""
    wait_for_task_completion(task_id::String, timeout_seconds::Float64)::Union{Dict, Nothing}
Waits for a task to complete with timeout
"""
function wait_for_task_completion(task_id::String, timeout_seconds::Float64)::Union{Dict, Nothing}
    start_time = time()
    
    while time() - start_time < timeout_seconds
        task_info = get_task_status(task_id)
        
        if !isnothing(task_info)
            if haskey(task_info, "result")
                return task_info["result"]
            elseif haskey(task_info, "error")
                return Dict("error" => task_info["error"])
            end
        end
        
        sleep(1.0)  # Check every second
    end
    
    return nothing  # Timeout
end

# JuliaOS agent lifecycle hooks
function Agent_init()
    Config.load_config()
    log_info("ChainGuardian agent initialized")
end

function Agent_serve()
    start_chainguardian_server()
end

export start_chainguardian_server, stop_chainguardian_server, Agent_init, Agent_serve

end # module

# Main execution
if abspath(PROGRAM_FILE) == @__FILE__
    using .ChainGuardianAPI
    Agent_init()
    Agent_serve()
end