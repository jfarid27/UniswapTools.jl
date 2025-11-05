module MockData

    using UniswapTools

    export v3_position_data, v3_global_data, v3_position
    export v3_reserves_data, v3_reserves

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

    const v3_reserves_data = (
        target_price   = 5003.913912782393,
        current_price  = 5000,
        current_dollar = 5000,
        current_token  = 1,
        upper_bound    = 5500,
        lower_bound    =  4545
    )

    const v3_reserves = @UniswapV3Position Dict(
        :poolDollarAmount => v3_reserves_data.current_dollar,
        :price => v3_reserves_data.current_price,
        :targetPrice => v3_reserves_data.target_price,
        :poolTokenAmount => v3_reserves_data.current_token,
        :upperPriceBound => v3_reserves_data.upper_bound,
        :lowerPriceBound => v3_reserves_data.lower_bound
    )

end