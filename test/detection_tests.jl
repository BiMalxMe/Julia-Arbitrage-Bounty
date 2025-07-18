using Test
using ..Detection
using ..Config
using ..Utils

Config.load_config()

"""
    Test Detection.detect_liquidity_mirage with live Solana data
"""
@testset "Detection" begin
    @testset "detect_liquidity_mirage" begin
        pool_address = "11111111111111111111111111111111"
        result = Detection.detect_liquidity_mirage(pool_address)
        Utils.log_info("Detection result: $(result)")
        @test haskey(result, "pool_address")
        @test haskey(result, "mirage_detected")
        @test haskey(result, "details")
    end
end 