using Test
using UniswapTools
using Chain

include("./MockData.jl")
using .MockData

@testset "PoolSolvers UniswapV3" begin
    @testset "UniswapV3LiquidityCalculation" begin
        @testset "should properly calculate sqrt price in q96 format." begin
            let pa::Float64=5000, expected_price = 5.602277e30
                result = price_to_sqrtp(pa);
                @test isapprox(result, expected_price, rtol=1e-3)
            end
        end
        @testset "should properly calculate the left token liquidity." begin
            let price::Float64=5000, upper::Float64=5500,
                expectedL=1.5194373080147697e21, amount::Float64 = 1
                @test isapprox(liquidityToken(amount, price, upper), expectedL, rtol=1e-3)
            end
        end
        @testset "should properly calculate the left dollar liquidity." begin
            let price::Float64=5000, lower::Float64=4545,
                expectedL::Float64=1.5178823437515099e21, amount::Float64=5000
                @test isapprox(liquidityDollar(amount, price, lower), expectedL, rtol=1e-3)
            end
        end
    end

    @testset "UniswapV3PositionUpdate" begin
        @testset "Scenario 1: Solve for pool reserves given bounds, price, and target capital." begin

            expected_dollar = 2564.54
            expected_token = 1.8749 

            new_state = UniswapV3PoolPositionState(v3_position)
            @testset "should properly update the dollar amount" begin
                @test new_state.poolDollarAmount ≈ expected_dollar rtol=1e-3
            end
            @testset "should properly update the token amount" begin
                @test new_state.poolTokenAmount ≈ expected_token rtol=1e-3
            end
            @testset "should properly update the total capital" begin
                @test new_state.totalCapital ≈ v3_position_data.total_capital rtol=1e-3
            end
            @testset "should properly set the target price" begin
                @test new_state.price ≈ v3_position_data.current_price rtol=1e-3
            end
        end
    end

    @testset "UniswapV3PoolPriceUpdate" begin
        @testset "Scenario 2: Solve for pool reserves given existing position and target price." begin
            let expected_dollar_del::Float64 = 42,
                expected_token_del::Float64 = -0.0083967142;

                expected_tokens = v3_reserves_data.current_token + expected_token_del
                expected_dollars = v3_reserves_data.current_dollar + expected_dollar_del
                expected_total_capital = expected_dollars + expected_tokens * v3_reserves_data.target_price

                new_state = UniswapV3PoolPositionState(v3_reserves)
                @testset "should properly update the dollar amount" begin
                    @test new_state.poolDollarAmount ≈ expected_dollars rtol=1e-3
                end
                @testset "should properly update the token amount" begin
                    @test new_state.poolTokenAmount ≈ expected_tokens rtol=1e-3
                end
                @testset "should properly update the total capital" begin
                    @test new_state.totalCapital ≈ expected_total_capital rtol=1e-3
                end
                @testset "should properly set the target price" begin
                    @test new_state.price ≈ v3_reserves_data.target_price rtol=1e-3
                end
            end
        end
    end
    @testset "UniswapV3ConvertReservesToNewPrice" begin
        @testset "Scenario 3: Convert reserves point to new price." begin
            let expected_total_capital = v3_reserves_data.current_dollar + v3_reserves_data.current_token * v3_reserves_data.target_price,
                reserves = UniswapV3PoolPositionState(v3_reserves)

                new_state = ConvertReservesToNewPrice(reserves, v3_reserves_data.current_price)

                @testset "should properly update the dollar amount" begin
                    @test new_state.poolDollarAmount ≈ v3_reserves_data.current_dollar rtol=1e-3
                end
                @testset "should properly update the token amount" begin
                    @test new_state.poolTokenAmount ≈ v3_reserves_data.current_token rtol=1e-3
                end
                @testset "should properly update the total capital" begin
                    @test new_state.totalCapital ≈ expected_total_capital rtol=1e-3
                end
                @testset "should properly set the target price" begin
                    @test new_state.price ≈ v3_reserves_data.current_price rtol=1e-3
                end
            end
        end
    end
    @testset "UniswapV3 Macros Test" begin
        @testset "should properly convert reserves to new price" begin
            let expected_total_capital = v3_reserves_data.current_dollar + v3_reserves_data.current_token * v3_reserves_data.target_price

                new_state = @chain begin
                    v3_reserves
                    UniswapV3PoolPositionState
                    ConvertReservesToNewPrice(v3_reserves_data.current_price)
                end
                @testset "should properly update the dollar amount" begin
                    @test new_state.poolDollarAmount ≈ v3_reserves_data.current_dollar rtol=1e-3
                end
                @testset "should properly update the token amount" begin
                    @test new_state.poolTokenAmount ≈ v3_reserves_data.current_token rtol=1e-3
                end
                @testset "should properly update the total capital" begin
                    @test new_state.totalCapital ≈ expected_total_capital rtol=1e-3
                end
                @testset "should properly set the target price" begin
                    @test new_state.price ≈ v3_reserves_data.current_price rtol=1e-3
                end
            end
        end

        @testset "MapAcrossV3Prices should work with price values expansion" begin

            total_capitals = @chain begin
                v3_reserves                        # start a new reserve target
                UniswapV3PoolPositionState         # Give me a new position
                MapAcrossPrices(4545.1, 5500, 200)(_)   #map over a few target prices
                map(res -> res.totalCapital, _)
            end

            expected_total_capital = 9312.28

            @show total_capitals

            @testset "should return solved total capitals" begin
                @test total_capitals[1] ≈ expected_total_capital rtol=1e-4
            end
        end
    end
end