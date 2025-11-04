module MockData

    using UniswapTools

    export v3_position_data, v3_global_data, v3_position

    const v3_position_data = (
        current_price   = 3965.75,
        total_capital   = 10000, 
        upper_bound     = 4500,
        lower_bound     =  3800
    )

    const v3_global_data = (
        amount_dollar = 18500000,
        amount_token  = 4900
    )

    const v3_position = @UniswapV3Position Dict(
        :poolDollarAmount => v3_global_data.amount_dollar,
        :poolTokenAmount => v3_global_data.amount_token,
        :price => v3_position_data.current_price,
        :totalCapital => v3_position_data.total_capital,
        :upperPriceBound => v3_position_data.upper_bound,
        :lowerPriceBound => v3_position_data.lower_bound
    )

end