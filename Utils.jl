
module Utils

using Logging
using JSON3

export log_info, log_error, safe_json_parse

"""
    log_info(msg)
Log an informational message.
"""
function log_info(msg)
    @info msg
end

"""
    log_error(msg)
Log an error message.
"""
function log_error(msg)
    @error msg
end

"""
    safe_json_parse(json_str::AbstractString)
Safely parse a JSON string, returning a Dict or an error Dict.
"""
function safe_json_parse(json_str::AbstractString)
    try
        return JSON3.read(json_str)
    catch e
        log_error("JSON parse error: $e")
        return Dict("error" => "JSON parse error: $e")
    end
end

end # module Utils
