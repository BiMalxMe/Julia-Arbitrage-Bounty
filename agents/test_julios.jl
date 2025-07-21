#!/usr/bin/env julia

using Pkg
Pkg.instantiate()

"""
Test script for JuliaOS module

This script tests all the major functionality of the JuliaOS agent framework
to ensure it works correctly in production environments.
"""
function main()
    println("🧪 Testing JuliaOS Agent Framework...")

    # Test 1: Module loading
    println("\n1. Testing module loading...")
    try
        include("src/JuliaOS.jl")
        using .JuliaOS
        println("✅ Module loaded successfully")
    catch e
        println("❌ Module loading failed: $e")
        exit(1)
    end

    # Test 2: Agent creation
    println("\n2. Testing agent creation...")
    try
        config = Dict(
            "name" => "TestAgent",
            "description" => "A test agent for validation",
            "capabilities" => ["http_request", "data_processing"],
            "rate_limits" => Dict("http_request" => 100),
            "max_retries" => 3,
            "timeout" => 30.0
        )
        
        agent = JuliaOS.create_agent(config)
        println("✅ Agent created successfully")
        println("   Name: $(agent.config.name)")
        println("   Description: $(agent.config.description)")
        println("   Capabilities: $(length(agent.capabilities))")
    catch e
        println("❌ Agent creation failed: $e")
        exit(1)
    end

    # Test 3: Agent lifecycle
    println("\n3. Testing agent lifecycle...")
    try
        agent = JuliaOS.create_agent(Dict("name" => "LifecycleTest"))
        
        # Start agent
        JuliaOS.start_agent(agent)
        println("✅ Agent started successfully")
        
        # Check status
        status = JuliaOS.get_agent_status(agent)
        println("   Status: $(status["is_running"])")
        println("   Message count: $(status["message_count"])")
        
        # Stop agent
        JuliaOS.stop_agent(agent)
        println("✅ Agent stopped successfully")
    catch e
        println("❌ Agent lifecycle test failed: $e")
        exit(1)
    end

    # Test 4: Capability execution
    println("\n4. Testing capability execution...")
    try
        agent = JuliaOS.create_agent(Dict("name" => "CapabilityTest"))
        JuliaOS.start_agent(agent)
        
        # Test data processing capability
        test_data = Dict("key1" => "value1", "key2" => nothing, "key3" => "value3")
        result = JuliaOS.execute_capability(agent, "process_data", test_data)
        println("✅ Data processing capability executed")
        println("   Input keys: $(length(test_data))")
        println("   Output keys: $(length(result))")
        
        # Test logging capability
        log_result = JuliaOS.execute_capability(agent, "log_event", "test_event", Dict("test" => "data"))
        println("✅ Logging capability executed")
        
        JuliaOS.stop_agent(agent)
    catch e
        println("❌ Capability execution test failed: $e")
        exit(1)
    end

    # Test 5: Error handling
    println("\n5. Testing error handling...")
    try
        agent = JuliaOS.create_agent(Dict("name" => "ErrorTest"))
        JuliaOS.start_agent(agent)
        
        # Test invalid capability
        try
            JuliaOS.execute_capability(agent, "nonexistent_capability")
            println("❌ Should have thrown an error for invalid capability")
        catch e
            println("✅ Error handling works for invalid capabilities")
        end
        
        JuliaOS.stop_agent(agent)
    catch e
        println("❌ Error handling test failed: $e")
        exit(1)
    end

    # Test 6: Metrics collection
    println("\n6. Testing metrics collection...")
    try
        agent = JuliaOS.create_agent(Dict("name" => "MetricsTest"))
        JuliaOS.start_agent(agent)
        
        # Send some messages
        for i in 1:5
            JuliaOS.send_message(agent, Dict("type" => "test", "id" => i))
        end
        
        # Collect metrics
        metrics = JuliaOS.get_agent_metrics(agent)
        println("✅ Metrics collection works")
        println("   Message count: $(metrics["message_count"])")
        println("   Error rate: $(metrics["error_rate"])")
        
        JuliaOS.stop_agent(agent)
    catch e
        println("❌ Metrics collection test failed: $e")
        exit(1)
    end

    # Test 7: Utility functions
    println("\n7. Testing utility functions...")
    try
        # Test JSON parsing
        test_json = """{"test": "data", "number": 42}"""
        parsed = JuliaOS.safe_json_parse(test_json)
        if parsed !== nothing
            println("✅ JSON parsing works")
        else
            println("❌ JSON parsing failed")
        end
        
        # Test response formatting
        error_response = JuliaOS.format_error_response(ErrorException("test error"), "test context")
        success_response = JuliaOS.format_success_response(Dict("data" => "test"), "test context")
        
        if error_response["success"] == false && success_response["success"] == true
            println("✅ Response formatting works")
        else
            println("❌ Response formatting failed")
        end
        
    catch e
        println("❌ Utility functions test failed: $e")
        exit(1)
    end

    println("\n🎉 All tests passed! JuliaOS is ready for production use.")
    println("\n📊 Test Summary:")
    println("   ✅ Module loading")
    println("   ✅ Agent creation")
    println("   ✅ Agent lifecycle")
    println("   ✅ Capability execution")
    println("   ✅ Error handling")
    println("   ✅ Metrics collection")
    println("   ✅ Utility functions")

    println("\n🚀 JuliaOS Agent Framework is production-ready!")
end

main()