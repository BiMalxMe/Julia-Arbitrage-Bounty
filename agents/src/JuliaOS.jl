"""
JuliaOS - A production-level agent framework for Julia

This module provides a robust agent system for building autonomous AI agents
with capabilities for data collection, analysis, prediction, and coordination.
"""

module JuliaOS

using HTTP
using JSON3
using Dates
using Statistics
using Logging
using Random
using LinearAlgebra
using StatsBase

export Agent, AgentConfig, AgentState, AgentCapability
export start_agent, stop_agent, send_message, get_agent_status
export register_capability, execute_capability, get_agent_metrics
export rate_limited_request, safe_json_parse, validate_api_response
export format_error_response, format_success_response

"""
Agent configuration structure
"""
struct AgentConfig
    name::String
    description::String
    capabilities::Vector{String}
    rate_limits::Dict{String, Int}
    max_retries::Int
    timeout::Float64
    log_level::LogLevel
end

"""
Agent state structure
"""
mutable struct AgentState
    is_running::Bool
    start_time::DateTime
    message_count::Int
    error_count::Int
    last_activity::DateTime
    capabilities::Dict{String, Function}
    metrics::Dict{String, Any}
end

"""
Agent capability structure
"""
mutable struct AgentCapability
    name::String
    func::Function
    description::String
    rate_limit::Int
    last_execution::DateTime
    execution_count::Int
end

"""
Main Agent structure
"""
mutable struct Agent
    config::AgentConfig
    state::AgentState
    capabilities::Dict{String, AgentCapability}
    message_queue::Vector{Dict{String, Any}}
    error_log::Vector{Dict{String, Any}}
end

"""
Create a new agent with the given configuration
"""
function Agent(config_dict::Dict{String, Any})
    config = AgentConfig(
        get(config_dict, "name", "UnnamedAgent"),
        get(config_dict, "description", "A JuliaOS agent"),
        get(config_dict, "capabilities", String[]),
        get(config_dict, "rate_limits", Dict{String, Int}()),
        get(config_dict, "max_retries", 3),
        get(config_dict, "timeout", 30.0),
        get(config_dict, "log_level", Logging.Info)
    )
    
    state = AgentState(
        false,
        now(),
        0,
        0,
        now(),
        Dict{String, Function}(),
        Dict{String, Any}()
    )
    
    agent = Agent(config, state, Dict{String, AgentCapability}(), [], [])
    
    # Initialize default capabilities
    initialize_default_capabilities(agent)
    
    return agent
end

"""
Initialize default capabilities for the agent
"""
function initialize_default_capabilities(agent::Agent)
    # HTTP request capability
    register_capability(agent, "http_request", http_request_capability, 
                       "Make HTTP requests with rate limiting and retries", 100)
    
    # Data processing capability
    register_capability(agent, "process_data", process_data_capability,
                       "Process and validate data structures", 1000)
    
    # Logging capability
    register_capability(agent, "log_event", log_event_capability,
                       "Log events with structured data", 10000)
    
    # Metrics collection capability
    register_capability(agent, "collect_metrics", collect_metrics_capability,
                       "Collect and store agent metrics", 100)
end

"""
Register a new capability for the agent
"""
function register_capability(agent::Agent, name::String, func::Function, 
                           description::String, rate_limit::Int)
    capability = AgentCapability(name, func, description, rate_limit, now(), 0)
    agent.capabilities[name] = capability
    @info "Registered capability: $name - $description"
end

"""
Execute a capability with rate limiting and error handling
"""
function execute_capability(agent::Agent, capability_name::String, args...; kwargs...)
    if !haskey(agent.capabilities, capability_name)
        error("Capability '$capability_name' not found")
    end
    
    capability = agent.capabilities[capability_name]
    
    # Check rate limiting
    if !check_rate_limit(capability)
        error("Rate limit exceeded for capability '$capability_name'")
    end
    
    try
        # Update execution count and timestamp
        capability.execution_count += 1
        capability.last_execution = now()
        
        # Execute the capability
        result = capability.func(agent, args...; kwargs...)
        
        # Update agent state
        agent.state.message_count += 1
        agent.state.last_activity = now()
        
        return result
        
    catch e
        agent.state.error_count += 1
        log_error(agent, capability_name, e)
        rethrow(e)
    end
end

"""
Check if a capability is within its rate limit
"""
function check_rate_limit(capability::AgentCapability)
    if capability.rate_limit <= 0
        return true  # No rate limit
    end
    
    # Simple rate limiting based on time window
    time_window = Minute(1)  # 1 minute window
    if now() - capability.last_execution < time_window
        return capability.execution_count < capability.rate_limit
    else
        # Reset counter if outside time window
        capability.execution_count = 0
        return true
    end
end

"""
Start the agent
"""
function start_agent(agent::Agent)
    if agent.state.is_running
        @warn "Agent $(agent.config.name) is already running"
        return false
    end
    
    agent.state.is_running = true
    agent.state.start_time = now()
    agent.state.last_activity = now()
    
    @info "Agent $(agent.config.name) started successfully"
    return true
end

"""
Stop the agent
"""
function stop_agent(agent::Agent)
    if !agent.state.is_running
        @warn "Agent $(agent.config.name) is not running"
        return false
    end
    
    agent.state.is_running = false
    
    @info "Agent $(agent.config.name) stopped successfully"
    return true
end

"""
Send a message to the agent
"""
function send_message(agent::Agent, message::Dict{String, Any})
    if !agent.state.is_running
        error("Agent $(agent.config.name) is not running")
    end
    
    push!(agent.message_queue, message)
    agent.state.message_count += 1
    agent.state.last_activity = now()
    
    @debug "Message received by agent $(agent.config.name): $(get(message, "type", "unknown"))"
end

"""
Get agent status
"""
function get_agent_status(agent::Agent)
    return Dict(
        "name" => agent.config.name,
        "is_running" => agent.state.is_running,
        "uptime" => agent.state.is_running ? now() - agent.state.start_time : Second(0),
        "message_count" => agent.state.message_count,
        "error_count" => agent.state.error_count,
        "last_activity" => agent.state.last_activity,
        "capabilities" => collect(keys(agent.capabilities)),
        "queue_size" => length(agent.message_queue)
    )
end

"""
Get agent metrics
"""
function get_agent_metrics(agent::Agent)
    return merge(agent.state.metrics, Dict(
        "uptime_seconds" => agent.state.is_running ? 
            (now() - agent.state.start_time).value / 1000 : 0,
        "messages_per_minute" => calculate_messages_per_minute(agent),
        "error_rate" => agent.state.message_count > 0 ? 
            agent.state.error_count / agent.state.message_count : 0
    ))
end

"""
Calculate messages per minute
"""
function calculate_messages_per_minute(agent::Agent)
    if !agent.state.is_running || agent.state.message_count == 0
        return 0.0
    end
    
    uptime = now() - agent.state.start_time
    minutes = uptime.value / (1000 * 60)  # Convert to minutes
    return agent.state.message_count / minutes
end

"""
Log an error event
"""
function log_error(agent::Agent, capability::String, error::Exception)
    error_entry = Dict(
        "timestamp" => now(),
        "capability" => capability,
        "error" => string(error),
        "backtrace" => string(stacktrace())
    )
    
    push!(agent.error_log, error_entry)
    
    # Keep only last 100 errors
    if length(agent.error_log) > 100
        deleteat!(agent.error_log, 1)
    end
    
    @error "Error in capability '$capability': $error"
end

# Default capability implementations

"""
HTTP request capability
"""
function http_request_capability(agent::Agent, url::String; 
                               method="GET", headers=Dict{String, String}(), 
                               body="", timeout=agent.config.timeout)
    try
        response = HTTP.request(method, url, headers, body; 
                              readtimeout=timeout, retries=agent.config.max_retries)
        return Dict(
            "status" => response.status,
            "body" => String(response.body),
            "headers" => Dict(response.headers)
        )
    catch e
        @error "HTTP request failed: $e"
        rethrow(e)
    end
end

"""
Data processing capability
"""
function process_data_capability(agent::Agent, data::Dict{String, Any})
    # Basic data validation and processing
    processed = Dict{String, Any}()
    
    for (key, value) in data
        if value !== nothing && value !== missing
            processed[key] = value
        end
    end
    
    return processed
end

"""
Logging capability
"""
function log_event_capability(agent::Agent, event_type::String, data::Dict{String, Any})
    log_entry = Dict(
        "timestamp" => now(),
        "agent" => agent.config.name,
        "event_type" => event_type,
        "data" => data
    )
    
    @info "Agent event: $event_type" log_entry
    return log_entry
end

"""
Metrics collection capability
"""
function collect_metrics_capability(agent::Agent, metric_name::String, value::Any)
    agent.state.metrics[metric_name] = Dict(
        "value" => value,
        "timestamp" => now()
    )
    
    # Keep only last 1000 metrics
    if length(agent.state.metrics) > 1000
        # Remove oldest metrics
        keys_to_remove = collect(keys(agent.state.metrics))[1:end-1000]
        for key in keys_to_remove
            delete!(agent.state.metrics, key)
        end
    end
    
    return agent.state.metrics[metric_name]
end

# Utility functions

"""
Make a rate-limited HTTP request
"""
function rate_limited_request(url::String; 
                            rate_limit::Int=100, 
                            headers::Dict{String, String}=Dict{String, String}(),
                            timeout::Float64=30.0)
    # Simple rate limiting implementation
    # In production, you'd want a more sophisticated rate limiter
    sleep(1.0 / rate_limit)  # Basic rate limiting
    
    return HTTP.get(url, headers; readtimeout=timeout)
end

"""
Parse JSON response safely
"""
function safe_json_parse(response_body::String)
    try
        return JSON3.read(response_body)
    catch e
        @error "JSON parsing failed: $e"
        return nothing
    end
end

"""
Validate API response
"""
function validate_api_response(response::HTTP.Messages.Response)
    if response.status >= 200 && response.status < 300
        return true
    else
        @warn "API returned status $(response.status): $(String(response.body))"
        return false
    end
end

"""
Format error response
"""
function format_error_response(error::Exception, context::String="")
    return Dict(
        "success" => false,
        "error" => string(error),
        "context" => context,
        "timestamp" => now()
    )
end

"""
Format success response
"""
function format_success_response(data::Any, context::String="")
    return Dict(
        "success" => true,
        "data" => data,
        "context" => context,
        "timestamp" => now()
    )
end

end # module JuliaOS