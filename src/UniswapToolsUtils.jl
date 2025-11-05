module UniswapToolsUtils
    import Base: getindex, setindex!, Fix2
    using ..Types, ..PoolSolvers, Chain

    export ConvertReservesToNewPrice

    export MapAcrossPrices

    ## Version 3

    """Utility to convert a given V3 reserve position to a new price.
    """
    function ConvertReservesToNewPrice(
        reserves::UniswapV3Reserves,
        target_price::Real
    )::UniswapV3Reserves

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

    ## Version 2

    """Utility to convert a given V2 reserve position to a new price.
    """
    function ConvertReservesToNewPrice(
        reserves::UniswapV2Reserves,
        target_price::Real
    )::UniswapV2Reserves

        new_reserves = UniswapV2PriceTarget(
            reserves.poolDollarAmount,
            reserves.poolTokenAmount,
            target_price,
        )

        return UniswapV2PoolPositionState(new_reserves)
    end

    ## Mixed 

    getindex(u::S, k::Symbol) where S<:UniswapReserves = hasfield(typeof(u), k) ?
        getfield(u, k) : 
        throw(KeyError(k));

    getindex(us::Vector{S}, k::Symbol) where S<:UniswapReserves = [getindex(u, k) for u in us];

    """Monadic Utility to take a given reserve position and map new positions across a range of prices.
    """
    function MapAcrossPrices(
        reserves::S,
        lower_price::Real,
        upper_price::Real,
        step::Real
    )::Vector{S} where S<:UniswapReserves
        @chain reserves begin
            map(price -> _ => price, range(start=lower_price, stop=upper_price, step=step))   #map over a few target prices
            map(pos -> ConvertReservesToNewPrice(pos.first, pos.second), _) # convert each new reserve price target to a new position
        end
    end

    ## Curries

    """Curriable method as a monadic Utility to take a given reserve position and map new positions across a range of prices.
    """
    function MapAcrossPrices(
        lower_price::Real,
        upper_price::Real,
        step::Real
    )
        return (reserves -> MapAcrossPrices(reserves, lower_price, upper_price, step))
    end


    """Curried method utility to convert a given reserve position to a new price.
    """
    function ConvertReservesToNewPrice(
        target_price::Real
    )
        return (reserves -> ConvertReservesToNewPrice(reserves, target_price))
    end

end