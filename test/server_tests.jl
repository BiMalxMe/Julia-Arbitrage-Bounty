using Test
using HTTP
using JSON3
include("../utils.jl")

"""
    Test server endpoints with live Solana data
"""
@testset "Server Endpoints" begin
    @testset "/status endpoint" begin
        resp = HTTP.get("http://127.0.0.1:8080/status")
        @test resp.status == 200
        data = JSON3.read(String(resp.body))
        Utils.log_info("/status response: $(data)")
        @test haskey(data, "status")
        @test haskey(data, "time")
        @test haskey(data, "agent")
    end
    @testset "/check endpoint" begin
        payload = JSON3.write(Dict("pool_address" => "11111111111111111111111111111111"))
        resp = HTTP.post("http://127.0.0.1:8080/check"; body=payload, headers=["Content-Type" => "application/json"])
        @test resp.status == 200
        data = JSON3.read(String(resp.body))
        Utils.log_info("/check response: $(data)")
        @test haskey(data, "pool_address")
        @test haskey(data, "mirage_detected")
        @test haskey(data, "details")
    end
end 