include("config.jl")
include("rpc.jl")
include("detection.jl")
include("utils.jl")

using HTTP
using Sockets
using JSON3
using Dates
using .Config
using .SolanaRPC
using .Detection
using .Utils
using Base.Threads
using Logging

"""
    Agent metadata for JuliaOS swarm
"""
const AGENT_METADATA = Dict(
    "name" => "SolanaLiquidityMirageAgent",
    "version" => "1.0.0",
    "description" => "Detects liquidity mirage patterns in Solana pools using live RPC data.",
    "author" => "Your Name",
    "license" => "MIT"
)

"""
    Agent.init()
JuliaOS agent initialization hook (stub).
"""
function Agent_init()
    Config.load_config()
    Utils.log_info("Agent initialized with config: $(Config.CONFIG)")
end

"""
    Agent.serve()
JuliaOS agent serve hook (starts HTTP server).
"""
function Agent_serve()
    port = parse(Int, Config.CONFIG["SERVICE_PORT"])
    threads = parse(Int, Config.CONFIG["THREADS"])
    Utils.log_info("Starting server on 127.0.0.1:$port with $threads threads...")
    HTTP.serve(handle_request, ip"127.0.0.1", port)
end

"""
    handle_request(req::HTTP.Request)
Handles incoming HTTP requests for the agent.
"""
function handle_request(req::HTTP.Request)
    try
        if req.method == "GET" && req.target == "/status"
            status_data = Dict(
                "status" => "ok",
                "time" => string(now()),
                "agent" => AGENT_METADATA
            )
            return HTTP.Response(200, JSON3.write(status_data))
        elseif req.method == "POST" && req.target == "/check"
            body = String(req.body)
            payload = Utils.safe_json_parse(body)
            if haskey(payload, "error")
                Utils.log_error("Invalid JSON payload: $(payload["details"])")
                return HTTP.Response(400, JSON3.write(payload))
            end
            if !haskey(payload, "pool_address")
                err = Dict("error" => "Missing 'pool_address' in payload")
                Utils.log_error("Missing pool_address in request payload")
                return HTTP.Response(400, JSON3.write(err))
            end
            pool_address = payload["pool_address"]
            fut = Threads.@spawn begin
                Utils.log_info("Starting detection for pool: $pool_address")
                result = Detection.detect_liquidity_mirage(pool_address)
                Utils.log_info("Detection result: $(result)")
                return result
            end
            result = fetch(fut)
            return HTTP.Response(200, JSON3.write(result))
        else
            return HTTP.Response(404, "Not Found")
        end
    catch e
        Utils.log_error("Internal server error: $(sprint(showerror, e))")
        err = Dict("error" => "Internal server error", "details" => sprint(showerror, e))
        return HTTP.Response(500, JSON3.write(err))
    end
end

# JuliaOS agent entrypoint
if abspath(PROGRAM_FILE) == @__FILE__
    Agent_init()
    Agent_serve()
end
