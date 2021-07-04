# review

## 学习资料

- [uniswap v3 白皮书](https://www.jinse.com/news/blockchain/1057182.html)

- [uniswap v3 白皮书中文版](https://shimo.im/docs/DCxd8VJGgV3yVjpp/read)

- [详解Uniswap V3创新细节](https://www.ccvalue.cn/article/955516.html)

- [Uniswap V3 详细讲解](https://liaoph.com/uniswap-v3-1/)

- [uniswap - V3源代码导读](https://zhuanlan.zhihu.com/p/372685243)

- [uniswap-graph](https://towardsdatascience.com/graphql-walkthrough-how-to-query-crypto-with-uniswap-defi-e0cbe2035290)

- [graph uniswap上查询体验](https://thegraph.com/explorer/subgraph/uniswap/uniswap-v2?selected=playground)

- [graph中设置教程](https://thegraph.com/docs/quick-start#2.-run-a-local-graph-node)

- [b站 uniswap V3技术白皮书和源代码介绍](https://www.bilibili.com/video/BV1C54y1L77r?from=search&seid=8631222436965615759)


## 目录
uniswap-v3-core

```
UniswapV3Pool.sol 实现流动性管理以及一个交易池中swap功能实现。每个Pool中的Position都做成了ERC721的Token。也就是说，每个Position都有独立的ERC721的Token ID。
```
```
├── contracts
│   ├── NoDelegateCall.sol                      // 防止以delegatecall方式执行
│   ├── UniswapV3Factory.sol                    // factory合约 交易池(UniswapV3Pool)统一创建的接口
│   ├── UniswapV3Pool.sol                       // pool合约 核心逻辑 由UniswapV3PoolDeploye 
│   ├── UniswapV3PoolDeployer.sol               // pool合约部署器
│   ├── interfaces
│   │   ├── IERC20Minimal.sol
│   │   ├── IUniswapV3Factory.sol
│   │   ├── IUniswapV3Pool.sol
│   │   ├── IUniswapV3PoolDeployer.sol
│   │   ├── LICENSE
│   │   ├── callback
│   │   └── pool
│   ├── libraries
│   │   ├── BitMath.sol
│   │   ├── FixedPoint128.sol
│   │   ├── FixedPoint96.sol
│   │   ├── FullMath.sol
│   │   ├── LICENSE_GPL
│   │   ├── LICENSE_MIT
│   │   ├── LiquidityMath.sol
│   │   ├── LowGasSafeMath.sol
│   │   ├── Oracle.sol
│   │   ├── Position.sol
│   │   ├── SafeCast.sol
│   │   ├── SqrtPriceMath.sol
│   │   ├── SwapMath.sol
│   │   ├── Tick.sol
│   │   ├── TickBitmap.sol
│   │   ├── TickMath.sol
│   │   ├── TransferHelper.sol
│   │   └── UnsafeMath.sol
```


uniswap-v3-periphery
```
├── contracts
│   ├── NonfungiblePositionManager.sol          // position管理合约 负责交易池的创建以及流动性的添加删除
│   ├── NonfungibleTokenPositionDescriptor.sol  // position token(NFT)合约
│   ├── SwapRouter.sol                          // router合约 swap路由的管理
│   ├── V3Migrator.sol                          // 流动性迁移合约
│   ├── base
│   │   ├── BlockTimestamp.sol
│   │   ├── ERC721Permit.sol
│   │   ├── LiquidityManagement.sol
│   │   ├── Multicall.sol
│   │   ├── PeripheryImmutableState.sol
│   │   ├── PeripheryPayments.sol
│   │   ├── PeripheryPaymentsWithFee.sol
│   │   ├── PeripheryValidation.sol
│   │   ├── PoolInitializer.sol
│   │   └── SelfPermit.sol
│   ├── interfaces
│   │   ├── IERC20Metadata.sol
│   │   ├── IERC721Permit.sol
│   │   ├── IMulticall.sol
│   │   ├── INonfungiblePositionManager.sol
│   │   ├── INonfungibleTokenPositionDescriptor.sol
│   │   ├── IPeripheryImmutableState.sol
│   │   ├── IPeripheryPayments.sol
│   │   ├── IPeripheryPaymentsWithFee.sol
│   │   ├── IPoolInitializer.sol
│   │   ├── IQuoter.sol
│   │   ├── ISelfPermit.sol
│   │   ├── ISwapRouter.sol
│   │   ├── ITickLens.sol
│   │   ├── IV3Migrator.sol
│   │   └── external
│   ├── lens
│   │   ├── Quoter.sol
│   │   ├── README.md
│   │   └── TickLens.sol
│   ├── libraries
│   │   ├── BytesLib.sol
│   │   ├── CallbackValidation.sol
│   │   ├── ChainId.sol
│   │   ├── HexStrings.sol
│   │   ├── LiquidityAmounts.sol
│   │   ├── NFTDescriptor.sol
│   │   ├── NFTSVG.sol
│   │   ├── Path.sol
│   │   ├── PoolAddress.sol
│   │   ├── PositionKey.sol
│   │   ├── TokenRatioSortOrder.sol
│   │   └── TransferHelper.sol
```

## 代码分析



### 创建交易对

./uniswap-v3-periphery/contracts/NonfungiblePositionManager.sol

```

```


```
./uniswap-v3-periphery/contracts/base/PoolInitializer.sol

   // 通过UniswapV3Factory查看是否已经存在对应的交易池，如果没有，创建交易池，如果有了但是还没有初始化，初始化交易池

    /// @inheritdoc IPoolInitializer
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable override returns (address pool) {
        require(token0 < token1);
        pool = IUniswapV3Factory(factory).getPool(token0, token1, fee);

        if (pool == address(0)) {
            pool = IUniswapV3Factory(factory).createPool(token0, token1, fee);
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        } else {
            (uint160 sqrtPriceX96Existing, , , , , , ) = IUniswapV3Pool(pool).slot0();
            if (sqrtPriceX96Existing == 0) {
                IUniswapV3Pool(pool).initialize(sqrtPriceX96);
            }
        }
    }
```

### 流动性操作

#### 添加流动性
```
./uniswap-v3-periphery/contracts/base/LiquidityManagement.sol


    //  添加流动性需要的参数

    struct AddLiquidityParams {
        address token0;
        address token1;
        uint24 fee;
        address recipient;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    // 添加流动性

    /// @notice Add liquidity to an initialized pool
    function addLiquidity(AddLiquidityParams memory params)
        internal
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            IUniswapV3Pool pool
        )
    {
```


#### 删除流动性

```
uniswap-v3-periphery/contracts/NonfungiblePositionManager.sol

  /// @inheritdoc INonfungiblePositionManager
    function collect(CollectParams calldata params)
        external
        payable
        override
        isAuthorizedForToken(params.tokenId)
        returns (uint256 amount0, uint256 amount1)
    {
        ...
    }
```


```
uniswap-v3-core/contracts/UniswapV3Pool.sol

    /// @inheritdoc IUniswapV3PoolActions
    /// @dev noDelegateCall is applied indirectly via _modifyPosition
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        (Position.Info storage position, int256 amount0Int, int256 amount1Int) =
            _modifyPosition(
                ModifyPositionParams({
                    owner: msg.sender,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidityDelta: -int256(amount).toInt128()
                })
            );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.tokensOwed0, position.tokensOwed1) = (
                position.tokensOwed0 + uint128(amount0),
                position.tokensOwed1 + uint128(amount1)
            );
        }

        emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
    }


    /// @inheritdoc IUniswapV3PoolActions
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        // we don't need to checkTicks here, because invalid positions will never have non-zero tokensOwed{0,1}
        Position.Info storage position = positions.get(msg.sender, tickLower, tickUpper);

        amount0 = amount0Requested > position.tokensOwed0 ? position.tokensOwed0 : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1 ? position.tokensOwed1 : amount1Requested;

        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit Collect(msg.sender, recipient, tickLower, tickUpper, amount0, amount1);
    }
```




### swap换币操作

```
./uniswap-v3-periphery/contracts/SwapRouter.sol
```

```
swap的逻辑实现在SwapRouter.sol，实现了多条路径互连swap逻辑。总共有两套函数：

exactInputSingle/exactInput
exactOutputSingle/exactOutput
exactInputSingle和exactOutputSingle是单交易池的swap函数，一个是从指定swap的输入金额，换取一定的输出，一个是指定swap的输出金额，反推需要多少输入金额。

无论是exactInputSingle，还是exactOutputSingle，最终都是调用交易池的swap函数
```

#### exactInputSingle

```
    /// @inheritdoc ISwapRouter
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        returns (uint256 amountOut)
    {
        amountOut = exactInputInternal(
            params.amountIn,
            params.recipient,
            params.sqrtPriceLimitX96,
            SwapCallbackData({path: abi.encodePacked(params.tokenIn, params.fee, params.tokenOut), payer: msg.sender})
        );
        require(amountOut >= params.amountOutMinimum, 'Too little received');
    }
```

```
    /// @dev Performs a single exact input swap
    function exactInputInternal(
        uint256 amountIn,
        address recipient,
        uint160 sqrtPriceLimitX96,
        SwapCallbackData memory data
    ) private returns (uint256 amountOut) {
        // allow swapping to the router address with address 0
        if (recipient == address(0)) recipient = address(this);

        // 解析交易对的token0, token1和fee

        (address tokenIn, address tokenOut, uint24 fee) = data.path.decodeFirstPool();


        // 两个token顺序是否是升序
        // 是否是Token0转换为Token1, < : true, >= : false

        bool zeroForOne = tokenIn < tokenOut;

        // 调用交易对的swap()

        (int256 amount0, int256 amount1) =
            getPool(tokenIn, tokenOut, fee).swap(
                recipient,
                zeroForOne,
                amountIn.toInt256(),
                sqrtPriceLimitX96 == 0
                    ? (zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : sqrtPriceLimitX96,
                abi.encode(data)
            );

        return uint256(-(zeroForOne ? amount1 : amount0));
    }
```


```
./uniswap-v3-core/contracts/UniswapV3Pool.sol

  // 交易对中的swap兑换操作

    /// @inheritdoc IUniswapV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override noDelegateCall returns (int256 amount0, int256 amount1) {
        ...
    }
```

#### exactInput

```
```

#### exactOutputSingle

```
```

#### exactOutput

```
```
