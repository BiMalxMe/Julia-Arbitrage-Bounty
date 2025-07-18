module SolanaRPC

using HTTP
using JSON3

export solana_rpc_request, fetch_token_accounts_by_owner

"""
    solana_rpc_request(method::String, params::Vector; endpoint::String=CONFIG["solana_rpc_url"])
Send a JSON-RPC request to the Solana endpoint and return the parsed response.
"""
function solana_rpc_request(method::String, params::Vector; endpoint::String="https://api.mainnet-beta.solana.com")
    body = JSON3.write(Dict(
        "jsonrpc" => "2.0",
        "id" => 1,
        "method" => method,
        "params" => params
    ))
    headers = ["Content-Type" => "application/json"]
    try
        resp = HTTP.post(endpoint, headers, body)
        return JSON3.read(String(resp.body))
    catch e
        return Dict("error" => string(e))
    end
end

"""
    fetch_token_accounts_by_owner(wallet_address::String; endpoint::String=CONFIG["solana_rpc_url"])
Fetch all SPL token accounts owned by the given wallet address.
"""
function fetch_token_accounts_by_owner(wallet_address::String; endpoint::String="https://api.mainnet-beta.solana.com")
    params = [
        wallet_address,
        Dict("programId" => "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"),
        Dict("encoding" => "jsonParsed")
    ]
    return solana_rpc_request("getTokenAccountsByOwner", params; endpoint=endpoint)
end

end # module SolanaRPC