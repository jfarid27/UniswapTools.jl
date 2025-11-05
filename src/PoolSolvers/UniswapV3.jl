module UniswapV3
    using ModelingToolkit, NonlinearSolve, Symbolics, Chain
    using ...Types
    const UTT = Types 

    export UniswapV3PoolPositionState, 
           ConvertV3ReservesToNewPrice,
           liquidityToken, liquidityDollar,
           price_to_sqrtp, MapAcrossV3Prices

    const Q96::Int128 = (Int128(2))^96
    const eth = Int128(1e18)

    """Monadic Utility to take a given reserve position and map new positions across a range of prices.
    """
    function MapAcrossV3Prices(
        reserves::UniswapV3Reserves,
        lower_price::Real,
        upper_price::Real,
        step::Real
    )::Vector{UniswapV3Reserves}
        @chain begin
            reserves
            map(price -> _ => price, range(start=lower_price, stop=upper_price, step=step))   #map over a few target prices
            map(pos -> ConvertV3ReservesToNewPrice(pos.first, pos.second), _) # convert each new reserve price target to a new position
        end
    end

    """Utility to convert a given reserve position to a new price.
    """
    function ConvertV3ReservesToNewPrice(
        reserves::UniswapV3Reserves{Tlow, Ttok, Tdol, TCap, Tpx, Tupp},
        target_price::Real
    )::UniswapV3Reserves where {Tlow<:Real, Ttok<:Real, Tdol<:Real, TCap<:Real, Tpx<:Real, Tupp<:Real}

        new_reserves = UniswapV3PriceTarget(
            reserves.lowerPriceBound,
            reserves.poolDollarAmount,
            reserves.poolTokenAmount,
            reserves.price,
            target_price,
            reserves.upperPriceBound
        )

        return UniswapV3PoolPositionState(new_reserves)
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

        return UniswapV3Reserves(
            state.lowerPriceBound, newAmountDollar, newAmountToken, state.price, state.totalCapital, state.upperPriceBound
        )

    end

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

        token_liquidity = liquidityToken(state.poolTokenAmount, state.price, state.upperPriceBound)
        dollar_liquidity = liquidityDollar(state.poolDollarAmount, state.price, state.lowerPriceBound)

        liquidity = min(token_liquidity, dollar_liquidity)

        amount_token_del = amountTokenDel(liquidity, target_sqrt_price, current_sqrt_price) / eth 
        amount_dollar_del = amountDollarDel(liquidity, target_sqrt_price, current_sqrt_price) / eth

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
            dollars,
            tokens,
            state.targetPrice,
            capital,
            state.upperPriceBound
        )
    end

end # module
