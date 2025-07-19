module SwarmCoordinator

using Distributed
using Base.Threads
using Logging
using Dates
using JSON3
using DataStructures
using ..Config: CONFIG
using ..Utils: log_info, log_error
using ..TokenScanner: scan_wallet_tokens
using ..TxScanner: scan_wallet_transactions
using ..RiskEvaluator: evaluate_wallet_risk
using Statistics

"""
    SwarmTask
Represents a task that can be distributed across the swarm
"""
struct SwarmTask
    id::String
    task_type::String
    wallet_address::String
    parameters::Dict
    priority::Int
    created_at::DateTime
    assigned_worker::Union{String, Nothing}
    status::String  # "PENDING", "ASSIGNED", "RUNNING", "COMPLETED", "FAILED"
end

"""
    SwarmWorker
Represents a worker in the swarm
"""
struct SwarmWorker
    id::String
    worker_type::String
    capabilities::Vector{String}
    status::String  # "IDLE", "BUSY", "OFFLINE"
    current_task::Union{String, Nothing}
    last_heartbeat::DateTime
    performance_metrics::Dict
end

"""
    SwarmCoordinator
Main coordinator for the swarm system
"""
mutable struct SwarmCoordinatorState
    workers::Dict{String, SwarmWorker}
    task_queue::Vector{SwarmTask}
    completed_tasks::Dict{String, Dict}
    failed_tasks::Dict{String, Dict}
    performance_stats::Dict
    is_running::Bool
end

# Global coordinator state
const COORDINATOR_STATE = SwarmCoordinatorState(
    Dict{String, SwarmWorker}(),
    Vector{SwarmTask}(),
    Dict{String, Dict}(),
    Dict{String, Dict}(),
    Dict("tasks_processed" => 0, "average_completion_time" => 0.0),
    false
)

"""
    swarm_task_to_dict(task::SwarmTask)::Dict
Converts a SwarmTask struct to a dictionary for JSON serialization
"""
function swarm_task_to_dict(task::SwarmTask)::Dict
    return Dict(
        "task_id" => task.id,
        "task_type" => task.task_type,
        "wallet_address" => task.wallet_address,
        "parameters" => task.parameters,
        "priority" => task.priority,
        "created_at" => string(task.created_at),
        "assigned_worker" => task.assigned_worker,
        "status" => task.status
    )
end

"""
    start_swarm_coordinator()
Starts the swarm coordinator
"""
function start_swarm_coordinator()
    log_info("Starting ChainGuardian Swarm Coordinator...")
    
    COORDINATOR_STATE.is_running = true
    
    # Initialize default workers
    initialize_default_workers()
    
    # Start coordinator loop
    @async coordinator_main_loop()
    
    log_info("Swarm Coordinator started successfully")
end

"""
    stop_swarm_coordinator()
Stops the swarm coordinator
"""
function stop_swarm_coordinator()
    log_info("Stopping Swarm Coordinator...")
    COORDINATOR_STATE.is_running = false
end

"""
    initialize_default_workers()
Initializes default workers for the swarm
"""
function initialize_default_workers()
    # Token scanner workers
    for i in 1:3
        worker = SwarmWorker(
            "token_scanner_$i",
            "token_scanner",
            ["token_analysis", "liquidity_check", "rugpull_detection"],
            "IDLE",
            nothing,
            now(),
            Dict("tasks_completed" => 0, "average_duration" => 0.0, "success_rate" => 1.0)
        )
        COORDINATOR_STATE.workers[worker.id] = worker
    end
    
    # Transaction scanner workers
    for i in 1:2
        worker = SwarmWorker(
            "tx_scanner_$i",
            "tx_scanner",
            ["transaction_analysis", "mev_detection", "risk_pattern_analysis"],
            "IDLE",
            nothing,
            now(),
            Dict("tasks_completed" => 0, "average_duration" => 0.0, "success_rate" => 1.0)
        )
        COORDINATOR_STATE.workers[worker.id] = worker
    end
    
    # Risk evaluator workers
    for i in 1:2
        worker = SwarmWorker(
            "risk_evaluator_$i",
            "risk_evaluator",
            ["risk_aggregation", "comprehensive_analysis", "report_generation"],
            "IDLE",
            nothing,
            now(),
            Dict("tasks_completed" => 0, "average_duration" => 0.0, "success_rate" => 1.0)
        )
        COORDINATOR_STATE.workers[worker.id] = worker
    end
    
    log_info("Initialized $(length(COORDINATOR_STATE.workers)) workers")
end

"""
    coordinator_main_loop()
Main coordinator loop that manages task distribution and worker monitoring
"""
function coordinator_main_loop()
    while COORDINATOR_STATE.is_running
        try
            # Process pending tasks
            process_pending_tasks()
            
            # Monitor worker health
            monitor_worker_health()
            
            # Update performance metrics
            update_performance_metrics()
            
            # Clean up completed tasks (keep last 100)
            cleanup_old_tasks()
            
            # Sleep for a short interval
            sleep(1.0)
            
        catch e
            log_error("Error in coordinator main loop: $e")
            sleep(5.0)
        end
    end
end

"""
    submit_wallet_analysis_task(wallet_address::String, priority::Int=1)::String
Submits a comprehensive wallet analysis task to the swarm
"""
function submit_wallet_analysis_task(wallet_address::String, priority::Int=1)::String
    task_id = "wallet_analysis_$(wallet_address)_$(round(Int, time()))"
    
    # Create comprehensive analysis task
    task = SwarmTask(
        task_id,
        "comprehensive_wallet_analysis",
        wallet_address,
        Dict("include_tokens" => true, "include_transactions" => true, "include_airdrops" => true),
        priority,
        now(),
        nothing,
        "PENDING"
    )
    
    # Add to task queue
    push!(COORDINATOR_STATE.task_queue, task)
    
    # Sort by priority (higher priority first)
    sort!(COORDINATOR_STATE.task_queue, by = t -> t.priority, rev = true)
    
    log_info("Submitted wallet analysis task: $task_id for wallet: $wallet_address")
    
    return task_id
end

"""
    submit_token_analysis_task(wallet_address::String, priority::Int=1)::String
Submits a token analysis task to the swarm
"""
function submit_token_analysis_task(wallet_address::String, priority::Int=1)::String
    task_id = "token_analysis_$(wallet_address)_$(round(Int, time()))"
    
    task = SwarmTask(
        task_id,
        "token_analysis",
        wallet_address,
        Dict(),
        priority,
        now(),
        nothing,
        "PENDING"
    )
    
    push!(COORDINATOR_STATE.task_queue, task)
    sort!(COORDINATOR_STATE.task_queue, by = t -> t.priority, rev = true)
    
    log_info("Submitted token analysis task: $task_id")
    return task_id
end

"""
    submit_transaction_analysis_task(wallet_address::String, priority::Int=1)::String
Submits a transaction analysis task to the swarm
"""
function submit_transaction_analysis_task(wallet_address::String, priority::Int=1)::String
    task_id = "tx_analysis_$(wallet_address)_$(round(Int, time()))"
    
    task = SwarmTask(
        task_id,
        "transaction_analysis",
        wallet_address,
        Dict("tx_limit" => 100),
        priority,
        now(),
        nothing,
        "PENDING"
    )
    
    push!(COORDINATOR_STATE.task_queue, task)
    sort!(COORDINATOR_STATE.task_queue, by = t -> t.priority, rev = true)
    
    log_info("Submitted transaction analysis task: $task_id")
    return task_id
end

"""
    process_pending_tasks()
Processes pending tasks by assigning them to available workers
"""
function process_pending_tasks()
    pending_tasks = filter(t -> t.status == "PENDING", COORDINATOR_STATE.task_queue)
    
    for task in pending_tasks
        # Find suitable worker
        worker = find_suitable_worker(task)
        
        if !isnothing(worker)
            # Assign task to worker
            assign_task_to_worker(task, worker)
            
            # Execute task asynchronously
            @async execute_task(task, worker)
        end
    end
end

"""
    find_suitable_worker(task::SwarmTask)::Union{SwarmWorker, Nothing}
Finds a suitable worker for a given task
"""
function find_suitable_worker(task::SwarmTask)::Union{SwarmWorker, Nothing}
    # Get required capabilities based on task type
    required_capabilities = get_required_capabilities(task.task_type)
    
    # Find idle workers with required capabilities
    suitable_workers = [
        worker for worker in values(COORDINATOR_STATE.workers)
        if worker.status == "IDLE" && 
           all(cap in worker.capabilities for cap in required_capabilities)
    ]
    
    if isempty(suitable_workers)
        return nothing
    end
    
    # Select worker with best performance metrics
    return sort(suitable_workers, by = w -> w.performance_metrics["success_rate"], rev = true)[1]
end

"""
    get_required_capabilities(task_type::String)::Vector{String}
Returns required capabilities for a task type
"""
function get_required_capabilities(task_type::String)::Vector{String}
    capability_map = Dict(
        "token_analysis" => ["token_analysis"],
        "transaction_analysis" => ["transaction_analysis"],
        "comprehensive_wallet_analysis" => ["risk_aggregation"],
        "risk_evaluation" => ["risk_aggregation"]
    )
    
    return get(capability_map, task_type, String[])
end

"""
    assign_task_to_worker(task::SwarmTask, worker::SwarmWorker)
Assigns a task to a worker
"""
function assign_task_to_worker(task::SwarmTask, worker::SwarmWorker)
    # Update task status
    task_index = findfirst(t -> t.id == task.id, COORDINATOR_STATE.task_queue)
    if !isnothing(task_index)
        COORDINATOR_STATE.task_queue[task_index] = SwarmTask(
            task.id, task.task_type, task.wallet_address, task.parameters,
            task.priority, task.created_at, worker.id, "ASSIGNED"
        )
    end
    
    # Update worker status
    COORDINATOR_STATE.workers[worker.id] = SwarmWorker(
        worker.id, worker.worker_type, worker.capabilities, "BUSY",
        task.id, now(), worker.performance_metrics
    )
    
    log_info("Assigned task $(task.id) to worker $(worker.id)")
end

"""
    execute_task(task::SwarmTask, worker::SwarmWorker)
Executes a task using the assigned worker
"""
function execute_task(task::SwarmTask, worker::SwarmWorker)
    start_time = time()
    
    try
        # Update task status to running
        update_task_status(task.id, "RUNNING")
        
        log_info("Worker $(worker.id) starting execution of task $(task.id)")
        
        # Execute task based on type
        result = if task.task_type == "token_analysis"
            scan_wallet_tokens(task.wallet_address)
        elseif task.task_type == "transaction_analysis"
            tx_limit = get(task.parameters, "tx_limit", 100)
            scan_wallet_transactions(task.wallet_address, tx_limit)
        elseif task.task_type == "comprehensive_wallet_analysis"
            evaluate_wallet_risk(task.wallet_address)
        else
            Dict("error" => "Unknown task type: $(task.task_type)")
        end
        
        # Calculate execution time
        execution_time = time() - start_time
        
        # Store result
        COORDINATOR_STATE.completed_tasks[task.id] = Dict(
            "task" => swarm_task_to_dict(task),
            "result" => result,
            "execution_time" => execution_time,
            "worker_id" => worker.id,
            "completed_at" => now()
        )
        
        # Update task status
        update_task_status(task.id, "COMPLETED")
        
        # Update worker performance metrics
        update_worker_performance(worker.id, execution_time, true)
        
        log_info("Task $(task.id) completed successfully in $(round(execution_time, digits=2))s")
        
    catch e
        execution_time = time() - start_time
        
        log_error("Task $(task.id) failed: $e")
        
        # Store failed task info
        COORDINATOR_STATE.failed_tasks[task.id] = Dict(
            "task" => swarm_task_to_dict(task),
            "error" => sprint(showerror, e),
            "execution_time" => execution_time,
            "worker_id" => worker.id,
            "failed_at" => now()
        )
        
        # Update task status
        update_task_status(task.id, "FAILED")
        
        # Update worker performance metrics
        update_worker_performance(worker.id, execution_time, false)
        
    finally
        # Free up worker
        COORDINATOR_STATE.workers[worker.id] = SwarmWorker(
            worker.id, worker.worker_type, worker.capabilities, "IDLE",
            nothing, now(), worker.performance_metrics
        )
    end
end

"""
    update_task_status(task_id::String, status::String)
Updates the status of a task
"""
function update_task_status(task_id::String, status::String)
    task_index = findfirst(t -> t.id == task_id, COORDINATOR_STATE.task_queue)
    if !isnothing(task_index)
        task = COORDINATOR_STATE.task_queue[task_index]
        COORDINATOR_STATE.task_queue[task_index] = SwarmTask(
            task.id, task.task_type, task.wallet_address, task.parameters,
            task.priority, task.created_at, task.assigned_worker, status
        )
    end
end

"""
    update_worker_performance(worker_id::String, execution_time::Float64, success::Bool)
Updates worker performance metrics
"""
function update_worker_performance(worker_id::String, execution_time::Float64, success::Bool)
    if haskey(COORDINATOR_STATE.workers, worker_id)
        worker = COORDINATOR_STATE.workers[worker_id]
        metrics = worker.performance_metrics
        
        # Update metrics
        tasks_completed = get(metrics, "tasks_completed", 0) + 1
        total_time = get(metrics, "total_time", 0.0) + execution_time
        successful_tasks = get(metrics, "successful_tasks", 0) + (success ? 1 : 0)
        
        updated_metrics = Dict(
            "tasks_completed" => tasks_completed,
            "total_time" => total_time,
            "successful_tasks" => successful_tasks,
            "average_duration" => total_time / tasks_completed,
            "success_rate" => successful_tasks / tasks_completed
        )
        
        # Update worker
        COORDINATOR_STATE.workers[worker_id] = SwarmWorker(
            worker.id, worker.worker_type, worker.capabilities, worker.status,
            worker.current_task, worker.last_heartbeat, updated_metrics
        )
    end
end

"""
    monitor_worker_health()
Monitors worker health and handles failures
"""
function monitor_worker_health()
    current_time = now()
    
    for (worker_id, worker) in COORDINATOR_STATE.workers
        # Check if worker hasn't reported in too long
        if current_time - worker.last_heartbeat > Minute(5)
            log_error("Worker $worker_id appears to be offline")
            
            # If worker was busy, mark task as failed
            if worker.status == "BUSY" && !isnothing(worker.current_task)
                update_task_status(worker.current_task, "FAILED")
            end
            
            # Mark worker as offline
            COORDINATOR_STATE.workers[worker_id] = SwarmWorker(
                worker.id, worker.worker_type, worker.capabilities, "OFFLINE",
                nothing, worker.last_heartbeat, worker.performance_metrics
            )
        end
    end
end

"""
    update_performance_metrics()
Updates global performance metrics
"""
function update_performance_metrics()
    total_completed = length(COORDINATOR_STATE.completed_tasks)
    total_failed = length(COORDINATOR_STATE.failed_tasks)
    
    if total_completed > 0
        avg_time = mean([
            task_info["execution_time"] 
            for task_info in values(COORDINATOR_STATE.completed_tasks)
        ])
        
        COORDINATOR_STATE.performance_stats = Dict(
            "tasks_processed" => total_completed + total_failed,
            "successful_tasks" => total_completed,
            "failed_tasks" => total_failed,
            "success_rate" => total_completed / (total_completed + total_failed),
            "average_completion_time" => avg_time
        )
    end
end

"""
    cleanup_old_tasks()
Cleans up old completed and failed tasks
"""
function cleanup_old_tasks()
    # Keep only last 100 completed tasks
    if length(COORDINATOR_STATE.completed_tasks) > 100
        sorted_tasks = sort(
            collect(COORDINATOR_STATE.completed_tasks),
            by = pair -> pair[2]["completed_at"],
            rev = true
        )
        
        COORDINATOR_STATE.completed_tasks = Dict(sorted_tasks[1:100])
    end
    
    # Keep only last 50 failed tasks
    if length(COORDINATOR_STATE.failed_tasks) > 50
        sorted_tasks = sort(
            collect(COORDINATOR_STATE.failed_tasks),
            by = pair -> pair[2]["failed_at"],
            rev = true
        )
        
        COORDINATOR_STATE.failed_tasks = Dict(sorted_tasks[1:50])
    end
    
    # Remove completed/failed tasks from queue
    COORDINATOR_STATE.task_queue = filter(
        t -> t.status ∉ ["COMPLETED", "FAILED"],
        COORDINATOR_STATE.task_queue
    )
end

"""
    get_task_status(task_id::AbstractString)::Union{Dict, Nothing}
Gets the status of a task
"""
function get_task_status(task_id::AbstractString)::Union{Dict, Nothing}
    # Check completed tasks
    if haskey(COORDINATOR_STATE.completed_tasks, task_id)
        return COORDINATOR_STATE.completed_tasks[task_id]
    end

    # Check failed tasks
    if haskey(COORDINATOR_STATE.failed_tasks, task_id)
        return COORDINATOR_STATE.failed_tasks[task_id]
    end

    # Check pending/running/assigned tasks
    task_index = findfirst(t -> t.id == task_id, COORDINATOR_STATE.task_queue)
    if !isnothing(task_index)
        task = COORDINATOR_STATE.task_queue[task_index]
        return Dict(
            "task_id" => task.id,
            "task_type" => task.task_type,
            "wallet_address" => task.wallet_address,
            "priority" => task.priority,
            "created_at" => string(task.created_at),
            "assigned_worker" => task.assigned_worker,
            "status" => task.status,
            "parameters" => task.parameters
        )
    end
    return nothing
end

"""
    get_swarm_status()::Dict
Gets the current status of the swarm
"""
function get_swarm_status()::Dict
    return Dict(
        "is_running" => COORDINATOR_STATE.is_running,
        "workers" => length(COORDINATOR_STATE.workers),
        "idle_workers" => count(w -> w.status == "IDLE", values(COORDINATOR_STATE.workers)),
        "busy_workers" => count(w -> w.status == "BUSY", values(COORDINATOR_STATE.workers)),
        "offline_workers" => count(w -> w.status == "OFFLINE", values(COORDINATOR_STATE.workers)),
        "pending_tasks" => count(t -> t.status == "PENDING", COORDINATOR_STATE.task_queue),
        "running_tasks" => count(t -> t.status == "RUNNING", COORDINATOR_STATE.task_queue),
        "completed_tasks" => length(COORDINATOR_STATE.completed_tasks),
        "failed_tasks" => length(COORDINATOR_STATE.failed_tasks),
        "performance_stats" => COORDINATOR_STATE.performance_stats
    )
end


export get_task_status, start_swarm_coordinator, stop_swarm_coordinator, 
       submit_wallet_analysis_task, submit_token_analysis_task,
       submit_transaction_analysis_task, get_swarm_status
end # module