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

To use, simply download the code and navigate to the project.
Open julia REPL and click "]" to switch to package mode, then
activate and instantiate the project. Then click backspace
and import the code via using .Uniswap.

```
Pkg> activate .
Pkg> instantiate
using .Uniswap
```

After this, available macros and functions will be in your
environment for use.

## Usage

### PoolPositions

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


## Testing

In the project folder, run the below code to run tests.

`julia --project -e 'using Revise, Pkg; Pkg.test()'

## Readings

This project is motivated from the research of Zhang and Lambert.
Their research treats Uniswap positions like options by analyzing
the payoff curves, and suggests delta hedging methods.

[Zhang - Automated Market Making and Loss-Versus-Rebalancing](https://arxiv.org/abs/2208.06046)

[Lambert - How to deploy delta-neutral liquidity in Uniswap](https://lambert-guillaume.medium.com/how-to-deploy-delta-neutral-liquidity-in-uniswap-or-why-euler-finance-is-a-game-changer-for-lps-1d91efe1e8ac)