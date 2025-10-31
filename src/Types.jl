module Types
    export @UniswapV2Position, @UniswapV3Position,
           UniswapV2PriceTarget, UniswapV2ReservesTarget, UniswapV2Reserves,
           UniswapV3PriceTarget, UniswapV3ReservesTarget, UniswapV3Reserves

    # allowed keys
    const ALLOWEDV2 = Set([:price, :totalCapital, :poolTokenAmount, :poolDollarAmount, :targetPrice])
    const ALLOWEDV3 = Set([:lowerPriceBound, :upperPriceBound, :price,
                           :totalCapital, :poolTokenAmount, :poolDollarAmount, :targetPrice])

    # concrete struct for the full set
    struct UniswapV2ReservesTarget{Tdol<:Real, Ttok<:Real, TCap<:Real, Tpx<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
    end

    struct UniswapV3ReservesTarget{Tlow<:Real, Tdol<:Real, Ttok<:Real, TCap<:Real, Tpx<:Real, Tupp<:Real}
        lowerPriceBound  :: Tlow
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
        upperPriceBound  :: Tupp
    end

    struct UniswapV2PriceTarget{Tdol<:Real, Ttok<:Real, Tpx<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        targetPrice      :: Tpx
    end

    struct UniswapV3ReservesTarget{Tlow<:Real, Tdol<:Real, Ttok<:Real, TCap<:Real, Tpx<:Real, Tupp<:Real}
        lowerPriceBound  :: Tlow
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
        upperPriceBound  :: Tupp
    end

    struct UniswapV3PriceTarget{Tlow<:Real, Tdol<:Real, Ttok<:Real, Tcpx<:Real,  Tpx<:Real, Tupp<:Real}
        lowerPriceBound  :: Tlow
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tcpx
        targetPrice      :: Tpx
        upperPriceBound  :: Tupp
    end

    struct UniswapV2Reserves{Tdol<:Real, Ttok<:Real, Tpx<:Real, TCap<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
    end

    struct UniswapV3Reserves{Tlow<:Real, Tdol<:Real, Ttok<:Real, Tpx<:Real, TCap<:Real, Tupp<:Real}
        lowerPriceBound  :: Tlow
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        price            :: Tpx
        totalCapital     :: TCap
        upperPriceBound  :: Tupp
    end

    # validate + canonicalize to a NamedTuple with sorted keys
    _check_allowed_v2(nt::NamedTuple) = begin
        bad = filter(k -> k ∉ ALLOWEDV2, keys(nt))
        isempty(bad) || error("Unknown keys: $(Tuple(bad)) — allowed: $(collect(ALLOWED))")
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
        isempty(bad) || error("Unknown keys: $(Tuple(bad)) — allowed: $(collect(ALLOWED))")
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
