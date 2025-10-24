module PoolSolvers
    using ModelingToolkit, NonlinearSolve, Symbolics
    using ..Types
    const UTT = Types 

    export UniswapV2PoolPositionState

    """Liquidity Position target given current reserves and the current price."""
    function UniswapV2PoolPositionState(
        state::UniswapV2ReservesTarget{Ttok,Tdol,TCap,Tpx}
    ) where {Ttok<:Real,Tdol<:Real,TCap<:Real,Tpx<:Real}

        @variables  amount_token  amount_dollar pool_constant
        @parameters target_price total_capital

        eqs = [
            pool_constant ~ amount_dollar * amount_token,
            target_price  ~ amount_dollar / amount_token,
            total_capital ~ amount_dollar + amount_token * target_price
        ]

        subs = Dict(
            target_price  => state.targetPrice,
            total_capital => state.totalCapital
        )
        eqs_sub = Symbolics.substitute.(eqs, Ref(subs))

        @named sys = NonlinearSystem(eqs_sub, [amount_dollar, amount_token, pool_constant], [])
        sys_simpl = structural_simplify(sys)

        # Initial guess from the provided state
        u0 = [
            amount_dollar => state.poolDollarAmount,
            amount_token  => state.poolTokenAmount,
        ]

        prob = NonlinearProblem(sys_simpl, u0)
        sol  = solve(prob, NewtonRaphson())

        newAmountDollar = sol[amount_dollar]
        newAmountToken  = sol[amount_token]
        newTotalCapital = sol[pool_constant]
        newTargetPrice  = sol[target_price]

        return UniswapV2Reserves(newAmountDollar, newAmountToken, newTotalCapital, newTargetPrice)


    end

    """Price target to current reserves function to predict the new reserves state.
    """
    function UniswapV2PoolPositionState(
        state::UniswapV2PriceTarget{Ttok,Tdol,Tpx}
    ) where {Ttok<:Real,Tdol<:Real,Tpx<:Real}

        @variables  amount_token  amount_dollar
        @parameters pool_constant target_price

        # Model: x*y = k,  y/x = p
        eqs = [
            pool_constant ~ amount_dollar * amount_token,
            target_price  ~ amount_dollar / amount_token
        ]

        # Use the VALUES from the state (not Symbols)
        current_constant = state.poolDollarAmount * state.poolTokenAmount
        subs = Dict(
            pool_constant => current_constant,
            target_price  => state.targetPrice
        )
        eqs_sub = Symbolics.substitute.(eqs, Ref(subs))

        @named sys = NonlinearSystem(eqs_sub, [amount_dollar, amount_token], [])
        sys_simpl = structural_simplify(sys)

        # Initial guess from the provided state
        u0 = [
            amount_dollar => state.poolDollarAmount,
            amount_token  => state.poolTokenAmount
        ]

        prob = NonlinearProblem(sys_simpl, u0)
        sol  = solve(prob, NewtonRaphson())

        newAmountDollar = sol[amount_dollar]
        newAmountToken  = sol[amount_token]
        newTargetPrice  = newAmountDollar / newAmountToken
        newTotalCapital = newAmountDollar + newAmountToken * newTargetPrice

        return UniswapV2Reserves(newAmountDollar, newAmountToken, newTotalCapital, newTargetPrice)
    end

end # module
