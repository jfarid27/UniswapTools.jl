module Types
    export @UniswapV2Position, UniswapV2ReservesTarget, UniswapV2Reserves

    # allowed keys
    const ALLOWED = Set([:poolTokenAmount, :poolDollarAmount, :targetPrice])

    # concrete struct for the full set
    struct UniswapV2ReservesTarget{Ttok<:Real, Tdol<:Real, Tpx<:Real}
        poolTokenAmount  :: Ttok
        poolDollarAmount :: Tdol
        targetPrice      :: Tpx
    end

    struct UniswapV2Reserves{Tdol<:Real, Ttok<:Real}
        poolDollarAmount :: Tdol
        poolTokenAmount  :: Ttok
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
        # capture the defining module so calls are qualified
        mod = @__MODULE__

        nt = gensym(:nt)
        x  = gensym(:x)

        # sorted full-key tuple
        fullK = (:poolDollarAmount, :poolTokenAmount, :targetPrice)

        return quote
            # evaluate user expr once
            local $(x)  = $(esc(ex))
            # normalize to canonical NamedTuple in the defining module
            local $(nt) = $(mod)._canon_nt($(x))

            if keys($(nt)) === $(fullK)
                # build the concrete struct from the canonical NT
                $(mod).UniswapV2ReservesTarget(
                    getproperty($(nt), :poolTokenAmount),
                    getproperty($(nt), :poolDollarAmount),
                    getproperty($(nt), :targetPrice),
                )
            else
                $(nt)
            end
        end
    end

end # module
