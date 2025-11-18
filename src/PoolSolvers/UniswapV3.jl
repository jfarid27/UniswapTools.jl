module UniswapV3
    using ModelingToolkit, NonlinearSolve, Symbolics, Chain
    using ...Types
    const UTT = Types 

    export UniswapV3PoolPositionState, 
           liquidityToken, liquidityDollar,
           price_to_sqrtp

    const Q96::Int128 = (Int128(2))^96
    const eth = Int128(1e18)

    function price_to_sqrtp(p::P)::Real where {P<:Real}
        return sqrt(p) * Q96
    end

    function liquidityToken(amount::A, pCurrent::C, pUpper::U)::Real where {A<:Real, C<:Real, U<:Real}
        pC = price_to_sqrtp(pCurrent)
        pU = price_to_sqrtp(pUpper)
        return (amount * eth * (pC * pU) / Q96) / (pU - pC)
    end

    function liquidityDollar(amount::A, pCurrent::C, pLower::L)::Real where {A<:Real, C<:Real, L<:Real}
        pC = price_to_sqrtp(pCurrent)
        pL = price_to_sqrtp(pLower)
        return amount * eth * Q96 / (pC - pL)
    end

    function computeLiquidity(amountToken, amountDollar, price, upperPriceBound, lowerPriceBound)
        token_liquidity = liquidityToken(amountToken, price, upperPriceBound)
        dollar_liquidity = liquidityDollar(amountDollar, price, lowerPriceBound)

        return min(token_liquidity, dollar_liquidity)
    end

    """Amount of token to add to the pool to reach the target price.
    
       Assumes prices and liquidity are in Q96 format.
    """
    function amountTokenDel(liq::L, pUpper::U, pCurrent::C)::Real where {L<:Real, U<:Real, C<:Real}
        if pCurrent > pUpper
            pCurrent, pUpper = pUpper, pCurrent
        end
        return liq * Q96 * (pUpper - pCurrent) / (pUpper * pCurrent)
    end

    """Amount of dollars to add to the pool to reach the target price.
    
       Assumes prices and liquidity are in Q96 format.
    """
    function amountDollarDel(liq::L, pLower::U, pCurrent::C)::Real where {L<:Real, U<:Real, C<:Real}
        if pCurrent < pLower
            pCurrent, pLower = pLower, pCurrent
        end
        return liq * (pCurrent - pLower) / Q96 
    end

    """Liquidity Position target given current reserves and the current price."""
    function UniswapV3PoolPositionState(
        state::UniswapV3ReservesTarget{Tlow, Ttok, Tdol, TCap, Tpx, Tupp}
    )::UniswapV3Reserves where {Tlow<:Real, Ttok<:Real, Tdol<:Real, TCap<:Real, Tpx<:Real, Tupp<:Real}

        @variables  amount_token amount_dollar
        @parameters current_price lower_bound upper_bound total_capital

        eqs = [
            total_capital ~ amount_dollar + amount_token * current_price,
            amount_token * (
                (sqrt(current_price) * sqrt(upper_bound)) / (sqrt(upper_bound) - sqrt(current_price))
            ) ~ 
            amount_dollar / (sqrt(current_price) - sqrt(lower_bound))
        ]

        # Use the VALUES from the state (not Symbols)
        subs = Dict(
            total_capital => state.totalCapital,
            current_price => state.price,
            lower_bound => state.lowerPriceBound,
            upper_bound => state.upperPriceBound
        )
        eqs_sub = Symbolics.substitute.(eqs, Ref(subs))

        @named sys = NonlinearSystem(eqs_sub, [amount_dollar, amount_token], [])
        sys_simpl = structural_simplify(sys)

        # Initial guess from the provided state

        initial_dollar = state.totalCapital / 2;
        initial_token = (state.totalCapital / 2) / state.price;
        u0 = [
            amount_dollar => initial_dollar,
            amount_token  => initial_token
        ]

        prob = NonlinearProblem(sys_simpl, u0)
        sol  = solve(prob, NewtonRaphson())

        newAmountDollar = sol[amount_dollar]
        newAmountToken  = sol[amount_token]

        liquidity = computeLiquidity(newAmountToken, newAmountDollar, state.price, state.upperPriceBound, state.lowerPriceBound)
        upper_sqrt_price = price_to_sqrtp(state.upperPriceBound)
        lower_sqrt_price = price_to_sqrtp(state.lowerPriceBound)
        token_out_of_bound = amountTokenDel(liquidity, lower_sqrt_price, upper_sqrt_price) / eth
        dollar_out_of_bound = amountDollarDel(liquidity, upper_sqrt_price, lower_sqrt_price) / eth

        return UniswapV3Reserves(
            state.lowerPriceBound,
            dollar_out_of_bound,
            token_out_of_bound,
            newAmountDollar,
            newAmountToken,
            state.price,
            state.totalCapital,
            state.upperPriceBound
        )

    end


    """Price target to current reserves function to predict the new reserves state.
    """
    function UniswapV3PoolPositionState(
        state::UniswapV3PriceTarget{Tlow, Ttok, Tdol, Tpx, Tupp}
    )::UniswapV3Reserves where {Tlow<:Real, Ttok<:Real,Tdol<:Real,Tpx<:Real,Tupp<:Real}

        upper_sqrt_price = price_to_sqrtp(state.upperPriceBound)
        lower_sqrt_price = price_to_sqrtp(state.lowerPriceBound)
        target_sqrt_price = price_to_sqrtp(state.targetPrice)
        current_sqrt_price = price_to_sqrtp(state.price)
        change_sqrt_price = target_sqrt_price - current_sqrt_price
        inv_change_sqrt_price = Q96 * ((1/target_sqrt_price) - (1/current_sqrt_price))

        liquidity = computeLiquidity(state.poolTokenAmount, state.poolDollarAmount, state.price, state.upperPriceBound, state.lowerPriceBound) 

        amount_token_del = amountTokenDel(liquidity, target_sqrt_price, current_sqrt_price) / eth 
        amount_dollar_del = amountDollarDel(liquidity, target_sqrt_price, current_sqrt_price) / eth

        token_out_of_bound = amountTokenDel(liquidity, lower_sqrt_price, upper_sqrt_price) / eth
        dollar_out_of_bound = amountDollarDel(liquidity, upper_sqrt_price, lower_sqrt_price) / eth

        if change_sqrt_price > 0
            amount_token_del *= -1
        else
            amount_dollar_del *= -1
        end

        tokens = state.poolTokenAmount + amount_token_del
        dollars = state.poolDollarAmount + amount_dollar_del
        capital = tokens * state.targetPrice + dollars

        return UniswapV3Reserves(
            state.lowerPriceBound,
            dollar_out_of_bound,
            token_out_of_bound,
            dollars,
            tokens,
            state.targetPrice,
            capital,
            state.upperPriceBound
        )
    end

end # module
