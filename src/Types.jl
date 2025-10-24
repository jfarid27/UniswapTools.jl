module Types
    export @UniswapV2Position, UniswapV2PriceTarget, UniswapV2ReservesTarget, UniswapV2Reserves

    # allowed keys
    const ALLOWED = Set([:poolTokenAmount, :poolDollarAmount, :targetPrice])

    # concrete struct for the full set
    struct UniswapV2ReservesTarget{Ttok<:Real, Tdol<:Real, TCap<:Real, Tpx<:Real}
        poolTokenAmount  :: Ttok
        poolDollarAmount :: Tdol
        totalCapital     :: TCap
        price            :: Tpx
    end

    struct UniswapV2PriceTarget{Ttok<:Real, Tdol<:Real, Tpx<:Real}
        poolTokenAmount  :: Ttok
        poolDollarAmount :: Tdol
        targetPrice      :: Tpx
    end

    struct UniswapV2Reserves{Tdol<:Real, Ttok<:Real, TCap<:Real, Tpx<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
        totalCapital     :: TCap
        targetPrice      :: Tpx
    end

    # validate + canonicalize to a NamedTuple with sorted keys
    _check_allowed(nt::NamedTuple) = begin
        bad = filter(k -> k ∉ ALLOWED, keys(nt))
        isempty(bad) || error("Unknown keys: $(Tuple(bad)) — allowed: $(collect(ALLOWED))")
        nt
    end
    _canon_nt(x::NamedTuple) = begin
        nt = _check_allowed(x)
        ks = collect(keys(nt)); sort!(ks)
        NamedTuple{Tuple(ks)}(nt)
    end
    _canon_nt(d::Dict) = _canon_nt((; d...))  # Dict → kwargs → NT

    # macro: normalize, then choose struct or NT
    macro UniswapV2Position(ex)
        mod = @__MODULE__
    
        # gensyms for hygienic temps
        x_sym  = gensym(:x)
        nt_sym = gensym(:nt)
        keys_sym = gensym(:keys)
    
        # canonical key tuples we recognize
        priceTargetK    = (:poolDollarAmount, :poolTokenAmount, :targetPrice)
        reservesTargetK = (:poolDollarAmount, :poolTokenAmount, :price, :totalCapital)
    
        return quote
            # evaluate user expression once
            local $(x_sym) = $(esc(ex))
    
            # step 1: normalize to canonical NamedTuple (sort keys, check allowed)
            # NOTE: we call the module's helpers with full qualification
            local $(nt_sym) = $mod._canon_nt($(x_sym))
    
            # collect its keys (a tuple)
            local $(keys_sym) = keys($(nt_sym))
    
            if $(keys_sym) === $priceTargetK
                # build UniswapV2PriceTarget
                $mod.UniswapV2PriceTarget(
                    getproperty($(nt_sym), :poolTokenAmount),
                    getproperty($(nt_sym), :poolDollarAmount),
                    getproperty($(nt_sym), :targetPrice),
                )
    
            elseif $(keys_sym) === $reservesTargetK
                # build UniswapV2ReservesTarget
                $mod.UniswapV2ReservesTarget(
                    getproperty($(nt_sym), :poolTokenAmount),
                    getproperty($(nt_sym), :poolDollarAmount),
                    getproperty($(nt_sym), :price),
                    getproperty($(nt_sym), :totalCapital),
                )
    
            else
                # graceful error with actual keyset
                throw(ArgumentError(
                    "Unrecognized key combination $(Tuple($(keys_sym))). " *
                    "Allowed symbols are $(collect($mod.ALLOWED)). " *
                    "Expected keysets like $priceTargetK or $reservesTargetK."
                ))
            end
        end
    end

end # module
