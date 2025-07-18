using Test
using ..SolanaRPC
using ..Config
using ..Utils

Config.load_config()

"""
    Test SolanaRPC.solana_rpc_request and fetch_token_accounts_by_owner
"""
@testset "SolanaRPC" begin
    @testset "solana_rpc_request" begin
        resp = SolanaRPC.solana_rpc_request("getHealth", [])
        Utils.log_info("getHealth response: $(resp)")
        @test haskey(resp, "result") || haskey(resp, "error")
    end
    @testset "fetch_token_accounts_by_owner" begin
        # Use a known public address (e.g., System Program)
        owner_address = "11111111111111111111111111111111"
        resp = SolanaRPC.fetch_token_accounts_by_owner(owner_address)
        Utils.log_info("Token accounts for owner: $(resp)")
        @test haskey(resp, "result") || haskey(resp, "error")
    end
end 