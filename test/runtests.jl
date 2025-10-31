using Test
using UniswapTools

@testset "UniswapTools" begin
    include("./test_PoolSolvers_UniswapV2.jl")
    include("./test_PoolSolvers_UniswapV3.jl")
end