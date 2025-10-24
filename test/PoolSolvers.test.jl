using Test
using UniswapTools

@testset "PoolSolvers" begin
    amount_dollar::Real = 18500000
    amount_token::Real = 4900
    @testset "UniswapV2PoolPriceUpdate" begin
        @testset "Scenario 1" begin
            target_price = 3500
            expected_dollar = 1.781e7
            expected_token = 5089.204 

            d = @UniswapV2Position Dict(
                :poolDollarAmount => amount_dollar,
                :targetPrice => target_price,
                :poolTokenAmount => amount_token
            )
        
            new_state = UniswapV2PoolPositionState(d)
            @test new_state.poolDollarAmount ≈ expected_dollar rtol=1e-3
            @test new_state.poolTokenAmount ≈ expected_token rtol=1e-3
        end
    end
end