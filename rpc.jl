module SolanaRPC

using HTTP
using JSON3
using ..Config: CONFIG

"""
    solana_rpc_request(method::String, params::Vector; rpc_url=CONFIG["SOLANA_RPC_URL"])
Send a JSON-RPC request to the Solana endpoint. Returns a Dict with the parsed response.
"""
function solana_rpc_request(method::String, params::Vector; rpc_url=CONFIG["SOLANA_RPC_URL"])
    payload = Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => method,
        "params" => params
    )
    headers = ["Content-Type" => "application/json"]
    if !isempty(CONFIG["API_KEY"])
        push!(headers, "Authorization" => "Bearer $(CONFIG["API_KEY"])")
    end
    resp = HTTP.post(rpc_url, headers, JSON3.write(payload))
    return JSON3.read(String(resp.body))
end

"""
    fetch_pool_state(pool_address::String)::Dict
Fetch the state of a liquidity pool using getAccountInfo.
"""
function fetch_pool_state(pool_address::String)::Dict
    return solana_rpc_request("getAccountInfo", [pool_address, Dict("encoding" => "jsonParsed")])
end

"""
    fetch_token_accounts_by_owner(owner_address::String)::Dict
Fetch all token accounts owned by the given address using getTokenAccountsByOwner.
"""
function fetch_token_accounts_by_owner(owner_address::String)::Dict
    params = [owner_address, Dict("programId" => "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"), Dict("encoding" => "jsonParsed")]
    return solana_rpc_request("getTokenAccountsByOwner", params)
end

export solana_rpc_request, fetch_pool_state, fetch_token_accounts_by_owner

end # module 