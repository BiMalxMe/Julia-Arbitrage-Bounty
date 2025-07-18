module Utils

using JSON3
using Logging

"""
    safe_json_parse(str::AbstractString)
Safely parse a JSON string, returning a Dict or an error Dict.
"""
function safe_json_parse(str::AbstractString)
    try
        return JSON3.read(str)
    catch e
        return Dict("error" => "Invalid JSON", "details" => sprint(showerror, e))
    end
end

"""
    log_info(msg)
Log an info message using Julia's Logging module.
"""
function log_info(msg)
    @info msg
end

"""
    log_error(msg)
Log an error message using Julia's Logging module.
"""
function log_error(msg)
    @error msg
end

export safe_json_parse, log_info, log_error

end # module 