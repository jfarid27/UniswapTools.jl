using Test
using UniswapTools

@testset "PoolSolvers UniswapV2" begin
    amount_dollar::Real = 18500000
    amount_token::Real = 4900
    @testset "UniswapV2PoolReservesUpdate" begin
        @testset "Scenario 1: Solve for pool reserves given price and target total capital." begin
            current_price = 3939.99 
            current_dollar = 25_000_000
            current_token = 18_500
            total_capital = 1000 
            expected_dollar = 500
            expected_token = 0.1269038 

            f = @UniswapV2Position Dict(
                :poolDollarAmount => current_dollar,
                :poolTokenAmount => current_token,
                :price => current_price,
                :totalCapital => total_capital
            )
        
            new_state = UniswapV2PoolPositionState(f)
            @testset "should properly update the dollar amount" begin
                @test new_state.poolDollarAmount ≈ expected_dollar rtol=1e-3
            end
            @testset "should properly update the token amount" begin
                @test new_state.poolTokenAmount ≈ expected_token rtol=1e-3
            end
            @testset "should properly update the total capital" begin
                @test new_state.totalCapital ≈ total_capital rtol=1e-3
            end
            @testset "should properly set the target price" begin
                @test new_state.price ≈ current_price rtol=1e-3
            end
        end
    end
    @testset "UniswapV2PoolPriceUpdate" begin
        @testset "Scenario 2: Solve for pool reserves given existing position and target price" begin
            target_price = 3500
            expected_dollar = 1.781e7
            expected_token = 5089.204 
            expected_total_capital = expected_dollar + expected_token * target_price

            d = @UniswapV2Position Dict(
                :poolDollarAmount => amount_dollar,
                :targetPrice => target_price,
                :poolTokenAmount => amount_token
            )
        
            new_state = UniswapV2PoolPositionState(d)
            @testset "should properly update the dollar amount" begin
                @test new_state.poolDollarAmount ≈ expected_dollar rtol=1e-3
            end
            @testset "should properly update the token amount" begin
                @test new_state.poolTokenAmount ≈ expected_token rtol=1e-3
            end
            @testset "should properly update the total capital" begin
                @test new_state.totalCapital ≈ expected_total_capital rtol=1e-3
            end
            @testset "should properly set the target price" begin
                @test new_state.price ≈ target_price rtol=1e-3
            end
        end
    end
end