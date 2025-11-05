module Types
    export @UniswapV2Position, @UniswapV3Position,
           UniswapReserves, UniswapReserveTarget, UniswapPriceTarget,
           UniswapV2PriceTarget, UniswapV2ReservesTarget, UniswapV2Reserves,
           UniswapV3PriceTarget, UniswapV3ReservesTarget, UniswapV3Reserves

    # allowed keys
    const ALLOWEDV2 = Set([:price, :totalCapital, :poolTokenAmount, :poolDollarAmount, :targetPrice])
    const ALLOWEDV3 = Set([:lowerPriceBound, :upperPriceBound, :price,
                           :totalCapital, :poolTokenAmount, :poolDollarAmount, :targetPrice])

    # concrete struct for the full set
    """
        UniswapV2ReservesTarget(dollars, tokens, price, totalCapital)

        Represent an intention to deposit into a pool with a specied amount of total capital in
        dollars. Given the current state of the pool with tokens, dollars, and a price, a user with
        "totalCapital" in dollars can use this to model what their position will be after depositing
        into the pool. Will convert variables into Float64 when constructed to allow for higher
        precision in future calculations.
    """
    struct UniswapV2ReservesTarget{Tdol<:Real, Ttok<:Real, TCap<:Real, Tpx<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
        function UniswapV2ReservesTarget(poolDollarAmount, poolTokenAmount, price, totalCapital)
            new{Float64,Float64,Float64,Float64}(
                float(poolDollarAmount), float(poolTokenAmount), float(price), float(totalCapital)

            )
        end
    end

    """
        UniswapV2PriceTarget(dollars, tokens, targetPrice)

        Represent an intention to fetch a position's reserves given a user's current position and
        a new price. The data specifies a current pool state with tokens, dollars, and a target
        price. Will convert variables into Float64 when constructed to allow for higher precision
        in future calculations.
    """
    struct UniswapV2PriceTarget{Tdol<:Real, Ttok<:Real, Tpx<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        targetPrice      :: Tpx
        function UniswapV2PriceTarget(poolDollarAmount, poolTokenAmount, targetPrice)
            new{Float64,Float64,Float64}(
                float(poolDollarAmount), float(poolTokenAmount), float(targetPrice)

            )
        end
    end

    """
        UniswapV3ReservesTarget(lowerBound, dollars, tokens, price, totalCapital, upperBound)

        Represent an intention to deposit into a pool. Given the current state of the overall pool with
        tokens, dollars, and a price, a user with "totalCapital" in dollars can use this to model what
        their position will be after depositing into the pool. Will convert variables into Float64 when
        constructed to allow for higher precision in future calculations.
        
        Note the user should specify the overall pool's token and dollar amount, as this is used in initial
        conditions, and should not be a single position's reserves.
    """
    struct UniswapV3ReservesTarget{Tlow<:Real, Tdol<:Real, Ttok<:Real, TCap<:Real, Tpx<:Real, Tupp<:Real}
        lowerPriceBound  :: Tlow
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
        upperPriceBound  :: Tupp
        function UniswapV3ReservesTarget(lowerPriceBound, poolDollarAmount, poolTokenAmount, price, totalCapital, upperPriceBound)
            new{Float64,Float64,Float64,Float64,Float64,Float64}(
                float(lowerPriceBound),float(poolDollarAmount), float(poolTokenAmount), float(price), float(totalCapital), float(upperPriceBound)

            )
        end
    end

    """
        UniswapV3PriceTarget(lowerBound, dollars, tokens, price, targetPrice, upperBound)

        Represent an intention to fetch a position's reserves given a user's current position and a new price.
        The data specifies a position with tokens, dollars, upper and lower bounds, current price, and
        a price target. Will convert variables into Float64 when constructed to allow for higher precision
        in future calculations.
    """
    struct UniswapV3PriceTarget{Tlow<:Real, Tdol<:Real, Ttok<:Real, Tcpx<:Real,  Tpx<:Real, Tupp<:Real}
        lowerPriceBound  :: Tlow
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tcpx
        targetPrice      :: Tpx
        upperPriceBound  :: Tupp

        function UniswapV3PriceTarget(lowerPriceBound, poolDollarAmount, poolTokenAmount, price, targetPrice, upperPriceBound)
            new{Float64,Float64,Float64,Float64,Float64,Float64}(
                float(lowerPriceBound),float(poolDollarAmount), float(poolTokenAmount), float(price), float(targetPrice), float(upperPriceBound)

            )
        end
    end

    """
        UniswapV2Reserves(dollars, tokens, price, totalCapital)

        Represent a current V2 position state. Will convert variables into Float64 when constructed to
        allow for higher precision in future calculations.
    """
    struct UniswapV2Reserves{Tdol<:Real, Ttok<:Real, Tpx<:Real, TCap<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap

        function UniswapV2Reserves(poolDollarAmount, poolTokenAmount, price, totalCapital)
            new{Float64,Float64,Float64,Float64}(
                float(poolDollarAmount), float(poolTokenAmount), float(price), float(totalCapital)
            )
        end
    end

    """
        UniswapV3Reserves(lowerBound, dollars, tokens, price, totalCapital, upperBound)

        Represent a current V3 position state. Will convert variables into Float64 when constructed to
        allow for higher precision in future calculations.
    """
    struct UniswapV3Reserves{Tlow<:Real, Tdol<:Real, Ttok<:Real, Tpx<:Real, TCap<:Real, Tupp<:Real}
        lowerPriceBound  :: Tlow
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
        upperPriceBound  :: Tupp

        function UniswapV3Reserves(lower, usd, tok, price, cap, upper)
            new{Float64,Float64,Float64,Float64,Float64,Float64}(
                float(lower), float(usd), float(tok), float(price), float(cap), float(upper)
            )
        end
    end

    UniswapReserves = Union{UniswapV2Reserves, UniswapV3Reserves};
    UniswapReserveTarget = Union{UniswapV2ReservesTarget, UniswapV3ReservesTarget};
    UniswapPriceTarget = Union{UniswapV2PriceTarget, UniswapV3PriceTarget};


    # validate + canonicalize to a NamedTuple with sorted keys
    _check_allowed_v2(nt::NamedTuple) = begin
        bad = filter(k -> k ∉ ALLOWEDV2, keys(nt))
        isempty(bad) || error("Unknown keys: $(Tuple(bad)) — allowed: $(collect(ALLOWEDV2))")
        nt
    end
    _canon_nt_v2(x::NamedTuple) = begin
        nt = _check_allowed_v2(x)
        ks = collect(keys(nt)); sort!(ks)
        NamedTuple{Tuple(ks)}(nt)
    end
    _canon_nt_v2(d::Dict) = _canon_nt_v2((; d...))  # Dict → kwargs → NT

    _check_allowed_v3(nt::NamedTuple) = begin
        bad = filter(k -> k ∉ ALLOWEDV3, keys(nt))
        isempty(bad) || error("Unknown keys: $(Tuple(bad)) — allowed: $(collect(ALLOWEDV3))")
        nt
    end
    _canon_nt_v3(x::NamedTuple) = begin
        nt = _check_allowed_v3(x)
        ks = collect(keys(nt)); sort!(ks)
        NamedTuple{Tuple(ks)}(nt)
    end
    _canon_nt_v3(d::Dict) = _canon_nt_v3((; d...))  # Dict → kwargs → NT

    macro UniswapV2Position(ex)
        mod = @__MODULE__
    
        # gensyms for hygienic temps
        x_sym  = gensym(:x)
        nt_sym = gensym(:nt)
        keys_sym = gensym(:keys)
    
        # canonical key tuples we recognize
        priceTargetK_sym    = gensym(:priceTargetK) 
        reservesTargetK_sym = gensym(:reservesTargetK) 
    
        return quote
            local $(priceTargetK_sym) = (:poolDollarAmount, :poolTokenAmount, :targetPrice)
            local $(reservesTargetK_sym)  = (:poolDollarAmount, :poolTokenAmount, :price, :totalCapital)
            # evaluate user expression once
            local $(x_sym) = $(esc(ex))
    
            # step 1: normalize to canonical NamedTuple (sort keys, check allowed)
            # NOTE: we call the module's helpers with full qualification
            local $(nt_sym) = $mod._canon_nt_v2($(x_sym))
    
            # collect its keys (a tuple)
            local $(keys_sym) = keys($(nt_sym))
    
            if $(keys_sym) === $(priceTargetK_sym)
                # build UniswapV2PriceTarget
                $mod.UniswapV2PriceTarget(
                    getproperty($(nt_sym), :poolDollarAmount),
                    getproperty($(nt_sym), :poolTokenAmount),
                    getproperty($(nt_sym), :targetPrice),
                )
    
            elseif $(keys_sym) === $(reservesTargetK_sym)
                # build UniswapV2ReservesTarget
                $mod.UniswapV2ReservesTarget(
                    getproperty($(nt_sym), :poolDollarAmount),
                    getproperty($(nt_sym), :poolTokenAmount),
                    getproperty($(nt_sym), :price),
                    getproperty($(nt_sym), :totalCapital),
                )
    
            else
                # graceful error with actual keyset
                throw(ArgumentError(
                    "Unrecognized key combination $(Tuple($(keys_sym))). " *
                    "Allowed symbols are $(collect($mod.ALLOWEDV2)). " *
                    "Expected keysets like $priceTargetK or $reservesTargetK."
                ))
            end
        end
    end

    macro UniswapV3Position(ex)
        mod = @__MODULE__
    
        # gensyms for hygienic temps
        x_sym  = gensym(:x)
        nt_sym = gensym(:nt)
        keys_sym = gensym(:keys)
    
        # canonical key tuples we recognize
        priceTargetK_sym    = gensym(:priceTargetK) 
        reservesTargetK_sym = gensym(:reservesTargetK) 
    
        return quote
            local $(priceTargetK_sym) = (:lowerPriceBound, :poolDollarAmount, :poolTokenAmount, :price, :targetPrice, :upperPriceBound)
            local $(reservesTargetK_sym)  = (:lowerPriceBound, :poolDollarAmount, :poolTokenAmount, :price, :totalCapital, :upperPriceBound)
            # evaluate user expression once
            local $(x_sym) = $(esc(ex))
    
            # step 1: normalize to canonical NamedTuple (sort keys, check allowed)
            # NOTE: we call the module's helpers with full qualification
            local $(nt_sym) = $mod._canon_nt_v3($(x_sym))
    
            # collect its keys (a tuple)
            local $(keys_sym) = keys($(nt_sym))
    
            if $(keys_sym) === $(priceTargetK_sym)
                # build UniswapV2PriceTarget
                $mod.UniswapV3PriceTarget(
                    getproperty($(nt_sym), :lowerPriceBound),
                    getproperty($(nt_sym), :poolDollarAmount),
                    getproperty($(nt_sym), :poolTokenAmount),
                    getproperty($(nt_sym), :price),
                    getproperty($(nt_sym), :targetPrice),
                    getproperty($(nt_sym), :upperPriceBound)
                )
    
            elseif $(keys_sym) === $(reservesTargetK_sym)
                # build UniswapV2ReservesTarget
                $mod.UniswapV3ReservesTarget(
                    getproperty($(nt_sym), :lowerPriceBound),
                    getproperty($(nt_sym), :poolDollarAmount),
                    getproperty($(nt_sym), :poolTokenAmount),
                    getproperty($(nt_sym), :price),
                    getproperty($(nt_sym), :totalCapital),
                    getproperty($(nt_sym), :upperPriceBound)
                )
    
            else
                # graceful error with actual keyset
                throw(ArgumentError(
                    "Unrecognized key combination $(Tuple($(keys_sym))). " *
                    "Allowed symbols are $(collect($mod.ALLOWEDV3)). " *
                    "Expected keysets like $priceTargetK or $reservesTargetK."
                ))
            end
        end
    end

end # module
