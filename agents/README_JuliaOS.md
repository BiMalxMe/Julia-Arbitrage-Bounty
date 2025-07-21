# JuliaOS - Production-Level Agent Framework

JuliaOS is a robust, production-ready agent framework for Julia that provides a comprehensive system for building autonomous AI agents with capabilities for data collection, analysis, prediction, and coordination.

## 🚀 Features

- **Agent Management**: Create, start, stop, and monitor agents
- **Capability System**: Register and execute custom capabilities with rate limiting
- **Error Handling**: Comprehensive error handling and logging
- **Metrics Collection**: Built-in metrics and monitoring
- **Rate Limiting**: Configurable rate limits for API calls and operations
- **HTTP Utilities**: Rate-limited HTTP requests with retry logic
- **Data Processing**: Built-in data validation and processing capabilities
- **Production Ready**: Designed for production environments with proper logging and error handling

## 📦 Installation

1. **Clone the repository**:
```bash
git clone <repository-url>
cd agents
```

2. **Install Julia dependencies**:
```bash
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

3. **Test the installation**:
```bash
julia test_julios.jl
```

## 🏗️ Quick Start

### Basic Agent Creation

```julia
using JuliaOS

# Create agent configuration
config = Dict(
    "name" => "MyAgent",
    "description" => "A custom agent for data processing",
    "capabilities" => ["http_request", "data_processing"],
    "rate_limits" => Dict("http_request" => 100),
    "max_retries" => 3,
    "timeout" => 30.0
)

# Create and start agent
agent = JuliaOS.Agent(config)
JuliaOS.start_agent(agent)

# Use the agent
result = JuliaOS.execute_capability(agent, "http_request", "https://api.example.com/data")

# Stop the agent
JuliaOS.stop_agent(agent)
```

### Custom Capabilities

```julia
# Define a custom capability
function my_custom_capability(agent::JuliaOS.Agent, input_data::String)
    # Your custom logic here
    processed_data = uppercase(input_data)
    return Dict("result" => processed_data, "timestamp" => now())
end

# Register the capability
JuliaOS.register_capability(agent, "custom_processor", my_custom_capability, 
                           "Processes input data", 50)

# Execute the capability
result = JuliaOS.execute_capability(agent, "custom_processor", "hello world")
```

## 📚 API Reference

### Core Types

#### `AgentConfig`
Configuration structure for agents:
- `name::String`: Agent name
- `description::String`: Agent description
- `capabilities::Vector{String}`: List of capability names
- `rate_limits::Dict{String, Int}`: Rate limits per capability
- `max_retries::Int`: Maximum retry attempts
- `timeout::Float64`: Request timeout in seconds
- `log_level::LogLevel`: Logging level

#### `Agent`
Main agent structure containing:
- `config::AgentConfig`: Agent configuration
- `state::AgentState`: Current agent state
- `capabilities::Dict{String, AgentCapability}`: Registered capabilities
- `message_queue::Vector{Dict{String, Any}}`: Message queue
- `error_log::Vector{Dict{String, Any}}`: Error log

### Core Functions

#### Agent Lifecycle
- `Agent(config_dict::Dict{String, Any})`: Create a new agent
- `start_agent(agent::Agent)`: Start the agent
- `stop_agent(agent::Agent)`: Stop the agent
- `get_agent_status(agent::Agent)`: Get current agent status

#### Capability Management
- `register_capability(agent::Agent, name::String, func::Function, description::String, rate_limit::Int)`: Register a new capability
- `execute_capability(agent::Agent, capability_name::String, args...; kwargs...)`: Execute a capability

#### Communication
- `send_message(agent::Agent, message::Dict{String, Any})`: Send a message to the agent

#### Monitoring
- `get_agent_metrics(agent::Agent)`: Get agent metrics
- `log_error(agent::Agent, capability::String, error::Exception)`: Log an error

### Built-in Capabilities

#### HTTP Request Capability
```julia
result = JuliaOS.execute_capability(agent, "http_request", "https://api.example.com/data")
```

#### Data Processing Capability
```julia
result = JuliaOS.execute_capability(agent, "process_data", Dict("key" => "value"))
```

#### Logging Capability
```julia
JuliaOS.execute_capability(agent, "log_event", "user_action", Dict("user_id" => 123))
```

#### Metrics Collection Capability
```julia
JuliaOS.execute_capability(agent, "collect_metrics", "api_calls", 42)
```

### Utility Functions

#### HTTP Utilities
- `rate_limited_request(url::String; rate_limit::Int=100, headers::Dict{String, String}=Dict{String, String}(), timeout::Float64=30.0)`: Make rate-limited HTTP requests
- `validate_api_response(response::HTTP.Messages.Response)`: Validate API responses

#### Data Processing
- `safe_json_parse(response_body::String)`: Safely parse JSON responses
- `format_error_response(error::Exception, context::String="")`: Format error responses
- `format_success_response(data::Any, context::String="")`: Format success responses

## 🔧 Configuration

### Environment Variables

Set these environment variables for API access:

```bash
export OPENSEA_API_KEY="your_opensea_api_key"
export ALCHEMY_API_KEY="your_alchemy_api_key"
export COINGECKO_API_KEY="your_coingecko_api_key"
```

### Rate Limiting

Configure rate limits in your agent configuration:

```julia
config = Dict(
    "rate_limits" => Dict(
        "opensea" => 100,      # 100 requests per hour
        "alchemy" => 300000000, # 300M compute units per month
        "coingecko" => 10000   # 10K requests per day
    )
)
```

## 📊 Monitoring and Metrics

### Agent Status
```julia
status = JuliaOS.get_agent_status(agent)
println("Agent running: $(status["is_running"])")
println("Message count: $(status["message_count"])")
println("Error count: $(status["error_count"])")
```

### Agent Metrics
```julia
metrics = JuliaOS.get_agent_metrics(agent)
println("Uptime: $(metrics["uptime_seconds"]) seconds")
println("Messages per minute: $(metrics["messages_per_minute"])")
println("Error rate: $(metrics["error_rate"])")
```

## 🛠️ Production Best Practices

### 1. Error Handling
Always wrap capability executions in try-catch blocks:

```julia
try
    result = JuliaOS.execute_capability(agent, "http_request", url)
    # Process result
catch e
    @error "Capability execution failed" exception=(e, catch_backtrace())
    # Handle error appropriately
end
```

### 2. Rate Limiting
Respect API rate limits and configure appropriate limits:

```julia
# Conservative rate limiting for production
config = Dict(
    "rate_limits" => Dict(
        "http_request" => 50,  # Conservative limit
        "api_call" => 10       # Very conservative for external APIs
    )
)
```

### 3. Logging
Use structured logging for better observability:

```julia
JuliaOS.execute_capability(agent, "log_event", "data_collection_started", Dict(
    "collection_id" => "123",
    "source" => "opensea",
    "timestamp" => now()
))
```

### 4. Monitoring
Regularly check agent health and metrics:

```julia
# Health check function
function health_check(agent::JuliaOS.Agent)
    status = JuliaOS.get_agent_status(agent)
    metrics = JuliaOS.get_agent_metrics(agent)
    
    # Alert if error rate is too high
    if metrics["error_rate"] > 0.1
        @warn "High error rate detected" error_rate=metrics["error_rate"]
    end
    
    # Alert if agent is not running
    if !status["is_running"]
        @error "Agent is not running" agent_name=agent.config.name
    end
end
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
julia test_julios.jl
```

The test suite covers:
- Module loading
- Agent creation and lifecycle
- Capability execution
- Error handling
- Metrics collection
- Utility functions

## 📝 Examples

See the agent files in this directory for complete examples:
- `data_collector.jl`: Data collection agent
- `ai_analyzer.jl`: AI analysis agent
- `price_predictor.jl`: Price prediction agent
- `swarm_coordinator.jl`: Swarm coordination agent

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
1. Check the documentation
2. Run the test suite
3. Review the examples
4. Open an issue on GitHub

---

**JuliaOS** - Building the future of autonomous agents in Julia 🚀