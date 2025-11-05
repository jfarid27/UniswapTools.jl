# Uniswap Tools

![](https://github.com/jfarid27/UniswapTools.jl/actions/workflows/CI.yml/badge.svg)

# Introduction

This project serves as a set of functions useful in analyzing [Uniswap](https://uniswap.org/)
positions. Uniswap is notable as a programmatic way to generate
market making positions across the Ethereum space. Each position
is governed by a constraint parameter. Mathematically, there
is a dual space for the position's price and associated token
reserves.

The code utilizes Julia macros to allow users to simulate overall
reserves given a target price, and a valid reserve set given a users
available capital (reserves). Models will find valid pool state as
long as users supply appropriate fields necessary to constrain the
pool.

The main idea is to utilize a macro like `@UniswapV2Position` which
will appropriately generate a datatype that can be used to find a
valid state optimization dataset.

This is generally useful for modeling future position values, and also
hedging Uniswap positions.

## Installation

### Github

With a Julia installation locally installed, you can install the package directly from
a git repo URL. Switch to package mode and simply add the URL for this project.

```
pkg> add https://github.com/jfarid27/UniswapTools.jl
```

Now you should be able to use the package with `using UniswapTools` in your REPL.

### Source

To use, simply download the code and navigate to the project.
Open julia REPL and click "]" to switch to package mode, then
activate and instantiate the project. Then click backspace
and import the code via using .Uniswap.

```
Pkg> activate .
Pkg> instantiate
using UniswapTools
```

Alternatively, you can navigate to the package folder and start julia
with the project specification.

```
julia --project=.

julia> using UniswapTools
```

After this, available macros and functions will be in your
environment for use.


## Usage

### Quick and Dirty using Point-Free Programming

There are a number of helper functions to allow for users to do common
data analytics in a point-free style. The functions are designed to work
with [Chain.jl](https://www.juliapackages.com/p/chain), a popular functional
library in the Julia ecosystem.

Add Chain and UniswapTools to your environemnt and you can use the code below to
simulate creating a V3 position, then seeing what the total capital of reserves will
be across multiple prices. Note "dollars" and "tokens" are referencing one reserve type
and another, but "dollars" is specifically used as the units for price. For example,
in the ETH - USDC pool you can use USDC amounts for dollars, and ETH amounts for tokens,
and prices in USDC terms. If you wish, you can subsititute dollars for WETH and simulate
reserves across arbitrary token to WETH pairs, but note prices and "totalCapital" must be
in ETH terms.

```julia

    const v3_position = @UniswapV3Position Dict(
        :poolDollarAmount => 18500000,    # Initialize with the global V3 pool's total dollars
        :poolTokenAmount => 4900,         # Also initialized with the global V3 pool's total tokens
        :price => 3965.75,
        :totalCapital => 10000,
        :upperPriceBound => 4500,
        :lowerPriceBound => 3800 
    )

    mapped_positions = @chain begin
        v3_position                        # start a new reserve target
        UniswapV3PoolPositionState         # Give me a new reserve position at this target
        MapAcrossPrices(4545.1, 5500, 200)   # map over a range target prices and give me the reserves
        getindex(_, :totalCapital)         # Return the total capital in USD across each price
    end
```

With `mapped_positions` you should now have a vector of the TVL in dollars of your position
across a range of prices. You can fetch other values like `:poolDollarAmount` and `:poolTokenAmount`
if you wish, and use these in packages like [Plots.jl](https://docs.juliaplots.org/latest/)
to visualize them.

See the pool positions docs below to learn how to create a v3_price_target.

### On Numbers

Because julia has excellent floating point operation math, it is
recommended to use `Float64` in inputs to maintain threshold precision
during calculations. If using a token or dollar position with digits,
just include the digits in the computation.


### PoolPositions

In general the main theme of the code is to start with a `Target` type representing
a user's intention to create a position, and a `Reserves` type representing a live
position. The code takes a target and computes a reserve while optimizing for
constraints defined in the Uniswap pool system. Each pool type comes with it's
own contructors for appropriate Reserve types given a Target type.

#### @UniswapV2Position

The `@UniswapV2Position` macro generates a type depending on whether
a user is trying to find valid reserves at a different price, or
valid reserves given a total amount of capital.

If a user has a total amount of capital in dollars, and inputs the
current pool's reserves of tokens and dollars as well as it's price,
the code below will return how much in tokens and dollars one needs
to supply into the pool by generating a fully specified pool position.

```julia
    position = @UniswapV2Position Dict(
        :poolDollarAmount => current_dollar,
        :poolTokenAmount => current_token,
        :price => current_price,
        :totalCapital => total_capital
    );
    positionState = UniswapV2PoolPositionState(position)
```

The `positionState` has properties that will return how much in tokens
and dollars one needs to enter a new position.

Likewise, one can predict reserves at a new price by specifying
the current pool or position's reserves, and it's target price.

```julia
    position = @UniswapV2Position Dict(
        :poolDollarAmount => amount_dollar,
        :poolTokenAmount => amount_token,
        :targetPrice => target_price
    );
    positionState = UniswapV2PoolPositionState(position)
```

The returned value will simulate altering the price to the target
price and generate a valid reserve set. Note since we are in the
reserve space, we don't need to specify the pool's current price
as that's defined by the reserves themselves.

The macro's (and julia's type dispatch system) allows users to have
one interface for specifying whether the user is in the space of price
or the dual space of reserves. One should think about the API of
this code as `pool state with unknown parameters` and
`functions that find unknown parameters`.

#### @UniswapV3Position

Similarly for Uniswap V3 positions, there is a generic macro to create
a position and get the total token reserves of the position given a total
amount of capital in dollars. Calling the result of the macro on the
UniswapV3PoolPositionState function will return a valid pool state.

```julia
    position = @UniswapV3Position Dict(
        :poolDollarAmount => amount_dollar,
        :poolTokenAmount => amount_token,
        :price => current_price,
        :totalCapital => total_capital,
        :upperPriceBound => upper_bound,
        :lowerPriceBound => lower_bound
    )

    positionState = UniswapV3PoolPositionState(position)
```

Similarly to V2, if the user supplies a `:targetPrice` instead of
`:totalCapital` and current position values, the function will
compute the new position reserves at the target price.

```julia

    position = @UniswapV3Position Dict(
        :poolDollarAmount => current_dollar,
        :price => current_price,
        :targetPrice => target_price,
        :poolTokenAmount => current_token,
        :upperPriceBound => upper_bound,
        :lowerPriceBound => lower_bound
    )
    positionState = UniswapV3PoolPositionState(position)

```

## Testing

In the project folder, run the below code to run tests.

`julia --project -e 'using Revise, Pkg; Pkg.test()'

## License

`LGPL-3.0-or-later`

1. Copy modify as you wish provided you post attribution.
2. You may integrate this into a closed-source system provided you attribute and share this code's
   source.
3. There are no guarantees of warranty or liability. (Don't ask me to fix it, and I don't care if
   you use this and lose all your money. dyor nfa)

Please read the `LICENSE.md` file for more information.

## Readings

This project is motivated from the research of Zhang and Lambert.
Their research treats Uniswap positions like options by analyzing
the payoff curves, and suggests delta hedging methods. Much of the
logic was also translated from Kuznetsov's excellent UniswapV3Book.

[Zhang - Automated Market Making and Loss-Versus-Rebalancing](https://arxiv.org/abs/2208.06046)

[Lambert - How to deploy delta-neutral liquidity in Uniswap](https://lambert-guillaume.medium.com/how-to-deploy-delta-neutral-liquidity-in-uniswap-or-why-euler-finance-is-a-game-changer-for-lps-1d91efe1e8ac)

[Kuznetsov - Uniswap Development Book](https://uniswapv3book.com/index.html)