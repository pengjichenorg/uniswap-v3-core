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


### 主要接口

- 1. 创建交易对 位于UniswapV3Factory.sol

- 2. 添加/删除流动性 位于UniswapV3Pool.sol 

- 3. 领取流动性手续费奖励 位于UniswapV3Pool.sol 

- 4. token兑换 位于UniswapV3Pool.sol 


### 创建交易对


入口1: 前端迁移部分相关代码: uniswap-interface/src/pages/MigrateV2/MigrateV2Pair.tsx

```js
    // create/initialize pool if necessary
    if (noLiquidity) {
      data.push(
        migrator.interface.encodeFunctionData('createAndInitializePoolIfNecessary', [
          token0.address,
          token1.address,
          feeAmount,
          `0x${sqrtPrice.toString(16)}`,
        ])
      )
    }
```

入口2: 前端创建pool部分相关代码: uniswap-interface/src/pages/AddLiquidity/index.tsx

```js
// only called on optimism, atm
  async function onCreate() {
    if (!chainId || !library) return

    if (!positionManager || !currencyA || !currencyB) {
      return
    }

    if (position && account && deadline) {
      const { calldata, value } = NonfungiblePositionManager.createCallParameters(position.pool)

      const txn: { to: string; data: string; value: string } = {
        to: NONFUNGIBLE_POSITION_MANAGER_ADDRESSES[chainId],
        data: calldata,
        value,
      }
      ...
```

前端用v3 sdk中封装的方法: v3/uniswap-v3-sdk/src/nonfungiblePositionManager.ts

```js

  private static encodeCreate(pool: Pool): string {
    return NonfungiblePositionManager.INTERFACE.encodeFunctionData('createAndInitializePoolIfNecessary', [
      pool.token0.address,
      pool.token1.address,
      pool.fee,
      toHex(pool.sqrtRatioX96)
    ])
  }

  public static createCallParameters(pool: Pool): MethodParameters {
    return {
      calldata: this.encodeCreate(pool),
      value: toHex(0)
    }
  }
```

uniswap-v3-periphery/contracts/base/PoolInitializer.sol

```js

   // 通过UniswapV3Factory查看是否已经存在对应的交易池，如果没有，创建交易池，如果有了但是还没有初始化，初始化交易池
   // 调用factory.createPool()创建pool
   // 调用pool.initialize()初始化pool价格，否则就无法添加流动性

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

uniswap-v3-core/contracts/UniswapV3Factory.sol

```js

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        // 按手续费设置tick间跨度 万五 千三 百一
        // 手续费分子和分母被放大100万倍

        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }


```

```js

    // 创建交易对 两个tokenpool地址和手续费决定一个pool地址
    // 500 3000 或者10000

    /// @inheritdoc IUniswapV3Factory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));

        // 创建UniswapV3Pool智能合约并设置两个token信息，交易费用信息和tick的步长信息

        pool = deploy(address(this), token0, token1, fee, tickSpacing);

        // 在三层map中记录pool地址，并记录两种方向

        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

```

uniswap-v3-core/contracts/UniswapV3PoolDeployer.sol

```js

   /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The spacing between usable ticks
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {

        // parameters是存储在合约里的一个变量 这里是赋值
        // 后面在对poo初始化时, 再获取parameters, 而不是通过参数传入使用, 避免创建不同的pool时因传入不同的参数导致initcode发生变化

        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});

        // 交易对地址是token0, token1和fee编码后的结果
        // 每个交易池有唯一的地址，并且和PoolKey信息保持一致。通过这种方法，从PoolKey信息可以反推出交易池的地址
        // 通过指定salt选项, 创建合约时生成的地址只与salt内容有关, 而与创建者的nonce无关
        
        // solidity文档: https://docs.soliditylang.org/en/v0.7.6/control-structures.html?highlight=salt#salted-contract-creations-create2

        // 如果构造函数中有参数, 还需要在构造函数中传入参数args, 此处创建pool合约的构造函数无需传入参数

        // UniswapV3Pool的构造函数中会通过变量parameters对合约中的factory, token0, token1, fee进行赋值, 并通过tickSpacing计算出单个tick能拥有的流动性上限值maxLiquidityPerTick

        pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());

        // 删除变量

        delete parameters;
    }
```

uniswap-v3-core/contracts/UniswapV3Pool.sol

```js

   constructor() {
        int24 _tickSpacing;

        // 获取deployer合约中的parameters变量

        (factory, token0, token1, fee, _tickSpacing) = IUniswapV3PoolDeployer(msg.sender).parameters();
        tickSpacing = _tickSpacing;

        // 计算每个tick上可拥有的最大流动性, 以防止累加流动性时溢出

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
    }

```

```
创建pool的时候，只是将pool创建出来，此时还并没有添加流动性，没有具体价格，在添加流动性之前，还需要对pool进行初始化，初始化方法为pool.initialize()

在uniswap-v3-periphery/contracts/base/PoolInitializer.sol的createAndInitializePoolIfNecessary()方法中，调用完factory.createPool()后，会再调用pool.initialize()设置pool的价格
```

```js
// 每个交易池的initialize函数初始化交易池的参数和状态。所有交易池的参数和状态用一个数据结构Slot0来记录
    // 创建时需要初始化一个价格sqrtPriceX96

    /// @inheritdoc IUniswapV3PoolActions
    /// @dev not locked because it initializes unlocked
    function initialize(uint160 sqrtPriceX96) external override {
        require(slot0.sqrtPriceX96 == 0, 'AI');

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

        //  保存交易对状态
        // 在初始化的时候，初始化了交易价格。这样可以把所有流动性的添加逻辑统一。

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 0,
            unlocked: true
        });

        emit Initialize(sqrtPriceX96, tick);
    }
```

### 流动性操作

#### 添加流动性

前端: uniswap/v3/uniswap-interface/src/pages/AddLiquidity/index.tsx

```js
 ...
 async function onAdd() {
    if (!chainId || !library || !account) return

    if (!positionManager || !currencyA || !currencyB) {
      return
    }

    if (position && account && deadline) {
      const useNative = currencyA.isNative ? currencyA : currencyB.isNative ? currencyB : undefined
      const { calldata, value } =
        hasExistingPosition && tokenId
          ? NonfungiblePositionManager.addCallParameters(position, {
              tokenId,
              slippageTolerance: allowedSlippage,
              deadline: deadline.toString(),
              useNative,
            })
          : NonfungiblePositionManager.addCallParameters(position, {
              slippageTolerance: allowedSlippage,
              recipient: account,
              deadline: deadline.toString(),
              useNative,
              createPool: noLiquidity,
            })
...

```

前端用sdk uniswap/v3/uniswap-v3-sdk/src/nonfungiblePositionManager.ts

```js

```

uniswap/v3/uniswap-v3-sdk/src/entities/position.ts
```js
public static addCallParameters(position: Position, options: AddLiquidityOptions): MethodParameters {
    ...
    ...

    // create pool if needed
    if (isMint(options) && options.createPool) {
      calldatas.push(this.encodeCreate(position.pool))
    }

    // permits if necessary
    if (options.token0Permit) {
      calldatas.push(NonfungiblePositionManager.encodePermit(position.pool.token0, options.token0Permit))
    }
    if (options.token1Permit) {
      calldatas.push(NonfungiblePositionManager.encodePermit(position.pool.token1, options.token1Permit))
    }

    // mint
    if (isMint(options)) {
      const recipient: string = validateAndParseAddress(options.recipient)

      // 调用mint方法添加初始流动性，创建新的position
      // 调用increaseLiquidity调整流动性
      // 两者的区别就是mint中会产生NFTtoken，increaseLiquidity中不再产生NFTtoken

      calldatas.push(
        NonfungiblePositionManager.INTERFACE.encodeFunctionData('mint', [
          {
            token0: position.pool.token0.address,
            token1: position.pool.token1.address,
            fee: position.pool.fee,
            tickLower: position.tickLower,
            tickUpper: position.tickUpper,
            amount0Desired: toHex(amount0Desired),
            amount1Desired: toHex(amount1Desired),
            amount0Min,
            amount1Min,
            recipient,
            deadline
          }
        ])
      )
    } else {
      // increase
      calldatas.push(
        NonfungiblePositionManager.INTERFACE.encodeFunctionData('increaseLiquidity', [
          {
            tokenId: toHex(options.tokenId),
            amount0Desired: toHex(amount0Desired),
            amount1Desired: toHex(amount1Desired),
            amount0Min,
            amount1Min,
            deadline
          }
        ])
      )
    }

    ...
    ...
```


uniswap-v3-periphery/contracts/NonfungiblePositionManager.sol

```js
    // 创建新的position，添加流动性
    // payble 可以接受eth
    // 如果是首次添加流动性, 会mint NFT token
    // 修改position和tick及其中的手续费累计信息

    /// @inheritdoc INonfungiblePositionManager
    function mint(MintParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        IUniswapV3Pool pool;
        (liquidity, amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: params.token0,
                token1: params.token1,
                fee: params.fee,
                recipient: address(this),
                tickLower: params.tickLower,
                tickUpper: params.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min
            })
        );

        // mint NFT token
        _mint(params.recipient, (tokenId = _nextId++));

        bytes32 positionKey = PositionKey.compute(address(this), params.tickLower, params.tickUpper);
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

        // idempotent set
        uint80 poolId =
            cachePoolKey(
                address(pool),
                PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee})
            );

        _positions[tokenId] = Position({
            nonce: 0,
            operator: address(0),
            poolId: poolId,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper,
            liquidity: liquidity,
            feeGrowthInside0LastX128: feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: feeGrowthInside1LastX128,
            tokensOwed0: 0,
            tokensOwed1: 0
        });

        emit IncreaseLiquidity(tokenId, liquidity, amount0, amount1);
    }

```


```js
    // 在已有的position调整流动性

    /// @inheritdoc INonfungiblePositionManager
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        override
        checkDeadline(params.deadline)
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        Position storage position = _positions[params.tokenId];

        PoolAddress.PoolKey memory poolKey = _poolIdToPoolKey[position.poolId];

        IUniswapV3Pool pool;
        (liquidity, amount0, amount1, pool) = addLiquidity(
            AddLiquidityParams({
                token0: poolKey.token0,
                token1: poolKey.token1,
                fee: poolKey.fee,
                tickLower: position.tickLower,
                tickUpper: position.tickUpper,
                amount0Desired: params.amount0Desired,
                amount1Desired: params.amount1Desired,
                amount0Min: params.amount0Min,
                amount1Min: params.amount1Min,
                recipient: address(this)
            })
        );

        bytes32 positionKey = PositionKey.compute(address(this), position.tickLower, position.tickUpper);

        // this is now updated to the current transaction
        (, uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128, , ) = pool.positions(positionKey);

        // 计算未领取手续费
        // mint方法中因为是首次添加流动性, 所以没有可以累加的未领取手续费

        position.tokensOwed0 += uint128(
            FullMath.mulDiv(
                feeGrowthInside0LastX128 - position.feeGrowthInside0LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );
        position.tokensOwed1 += uint128(
            FullMath.mulDiv(
                feeGrowthInside1LastX128 - position.feeGrowthInside1LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );

        position.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
        position.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
        position.liquidity += liquidity;

        emit IncreaseLiquidity(params.tokenId, liquidity, amount0, amount1);
    }


```

uniswap-v3-periphery/contracts/NonfungiblePositionManager.sol

```js
import './base/LiquidityManagement.sol';

// 合约NonfungiblePositionManager继承了LiquidityManagement，便拥有了它里面的方法
// 比如addLiquidity()

contract NonfungiblePositionManager is
    INonfungiblePositionManager,
    Multicall,
    ERC721Permit,
    PeripheryImmutableState,
    PoolInitializer,
    LiquidityManagement,
    PeripheryValidation,
    SelfPermit
{
  ...
  ...
```

uniswap-v3-periphery/contracts/base/LiquidityManagement.sol

```js

    // 添加流动性使用的参数

    struct AddLiquidityParams {
        address token0;             // token0
        address token1;             // token1
        uint24 fee;                 // 手续费
        address recipient;          // 用户地址
        int24 tickLower;            // 价格下边界
        int24 tickUpper;            // 价格上边界
        uint256 amount0Desired;     // token0添加额
        uint256 amount1Desired;     // token1添加额
        uint256 amount0Min;         // token0最低额
        uint256 amount1Min;         // token1最低额
    }
```

```js
    // 添加流动性
    // 将传入的代表价格范围tick转化为对应的存储价格
    // 根据期望提供的token和价格范围, 计算出对应的流动性L
    // 调用pool.mint()对postion及对应的tick对象进行修改

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
        // 计算pool唯一的key， 由token0，token1和fee决定

        PoolAddress.PoolKey memory poolKey =
            PoolAddress.PoolKey({token0: params.token0, token1: params.token1, fee: params.fee});

        // 由poolKey获取pool地址

        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));

        // 计算流动性大小

        // compute the liquidity amount
        {
            // 获取价格， 价格保存在pool的slot中
            // factory.createPool()时还没有设置价格，之后会调用pool.initialize()设置价格

            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();

            // 根据白皮书设计: 添加流动性需要制定价格上边界和价格下边界，即B(价格较高)点和A(价格较低)点
            // 两个价格边界在前端显示的是价格， 二在合约中，使用价格对应的tick表示
            // 根据tick计算开方并放大后表示的A和B两个点的价格，base price: 1.0001是固定值，已定义在库中
            // 价格较低点 A点: tickLower -> sqrtRatioAx96
            // 价格较高点 B点: tickUpper -> sqrtRatioBx96

            uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
            uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

            // 计算添加的流动性
            // 里面涉及到白皮书书中提供的流动性计算公式

            liquidity = LiquidityAmounts.getLiquidityForAmounts(
                sqrtPriceX96,
                sqrtRatioAX96,
                sqrtRatioBX96,
                params.amount0Desired,
                params.amount1Desired
            );
        }

        // 计算出流动性后, 调用pool.mint()进入核心代码区域

        (amount0, amount1) = pool.mint(
            params.recipient,
            params.tickLower,
            params.tickUpper,
            liquidity,
            abi.encode(MintCallbackData({poolKey: poolKey, payer: msg.sender}))
        );

        require(amount0 >= params.amount0Min && amount1 >= params.amount1Min, 'Price slippage check');
    }
}

```

uniswap-v3-core/contracts/UniswapV3Pool.sol

```js
    // 添加流动性
    // 使用回调做了一些处理
    // 1.更新position
    // 2.使用回调执行transferFrom()

    /// @inheritdoc IUniswapV3PoolActions
    /// @dev noDelegateCall is applied indirectly via _modifyPosition
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        require(amount > 0);

        // 根据流动性计算需要添加的token0和token1数量
        // 之前属于预计算, 算出流动性数量后再根据流动性数量计算出amount0和amount1
        // _modifyPosition是个方法
        // ModifyPositionParams是个结构体

        (, int256 amount0Int, int256 amount1Int) =
            _modifyPosition(
                ModifyPositionParams({
                    owner: recipient,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidityDelta: int256(amount).toInt128()
                })
            );


        // 去顶amount0和amount1的值

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int)Console.WriteLine('');
        Console.ReadKey();


        // 添加流动性之前的balance0和balance1

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();

        // 使用回调, 进行token0和token1的转入和NFTtoekn的mint

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);

        // 检查token0和token1两个token数量是否相应增加

        if (amount0 > 0) require(balance0Before.add(amount0) <= balance0(), 'M0');
        if (amount1 > 0) require(balance1Before.add(amount1) <= balance1(), 'M1');

        // 输入Mint日志, 至此添加流动性操作完成

        emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
    }
```


```js
    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        int24 tickLower;
        int24 tickUpper;
        // any change in liquidity
        int128 liquidityDelta;
    }

    // 添加流动性时对position结构的修改
    // 传入的参数: 用户地址, position上下边界价格, 变更的流动性
    // 1.修改position信息
    // 2.根据传入的liqudity计算出amount0和amount1, liquidity是前面从amount0或amount1计算出来的, 现在倒着再计算一遍, 以确保数值精确

    /// @dev Effect some changes to a position
    /// @param params the position details and the change to the position's liquidity to effect
    /// @return position a storage pointer referencing the position with the given owner and tick range
    /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
    /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
    function _modifyPosition(ModifyPositionParams memory params)
        private
        noDelegateCall
        returns (
            Position.Info storage position,
            int256 amount0,
            int256 amount1
        )
    {
        // 检查tickers是否超出tick的最大和最小边界

        checkTicks(params.tickLower, params.tickUpper);

        Slot0 memory _slot0 = slot0; // SLOAD for gas optimization

        // 更新position中的数据

        position = _updatePosition(
            params.owner,
            params.tickLower,
            params.tickUpper,
            params.liquidityDelta,
            _slot0.tick
        );

        // 分三种情况: 两种区间外, 区间内
        // upper外
        // lower外
        // 区间内

        if (params.liquidityDelta != 0) {
            if (_slot0.tick < params.tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            } else if (_slot0.tick < params.tickUpper) {
                // current tick is inside the passed range
                uint128 liquidityBefore = liquidity; // SLOAD for gas optimization

                // write an oracle entry
                (slot0.observationIndex, slot0.observationCardinality) = observations.write(
                    _slot0.observationIndex,
                    _blockTimestamp(),
                    _slot0.tick,
                    liquidityBefore,
                    _slot0.observationCardinality,
                    _slot0.observationCardinalityNext
                );

                amount0 = SqrtPriceMath.getAmount0Delta(
                    _slot0.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    _slot0.sqrtPriceX96,
                    params.liquidityDelta
                );

                liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            }
        }
    }
```

```js
    // 为了便于计算，流动性的状态更新是通过流动性(position)边界上的Tick的liquidityNet来表示
    // 更新Poisition对应边界的Tick信息

    /// @dev Gets and updates a position with the given liquidity delta
    /// @param owner the owner of the position
    /// @param tickLower the lower tick of the position's tick range
    /// @param tickUpper the upper tick of the position's tick range
    /// @param tick the current tick, passed to avoid sloads
    function _updatePosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta,
        int24 tick
    ) private returns (Position.Info storage position) {
        // 获取position
        // owner tickerLower tickerUpper可以唯一确定一个position

        position = positions.get(owner, tickLower, tickUpper);

        // f0和f1 在首次添加流动性之前尚未赋值, 初始化为0

        uint256 _feeGrowthGlobal0X128 = feeGrowthGlobal0X128; // SLOAD for gas optimization
        uint256 _feeGrowthGlobal1X128 = feeGrowthGlobal1X128; // SLOAD for gas optimization

        // 更新上下tick
        // 初始化
        // 更新tick上的流动性

        // flipped: 翻转, 即从初始化状态变为未初始化状态, 或从未初始化状态变为初始化状态
        // tick lower是否翻转
        // tick upper是否翻转

        // if we need to update the ticks, do it
        bool flippedLower;
        bool flippedUpper;

        // 流动性有变化就更新ticker

        if (liquidityDelta != 0) {
            uint32 time = _blockTimestamp();
            (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) =

                // oracle相关

                observations.observeSingle(
                    time,
                    0,
                    slot0.tick,
                    slot0.observationIndex,
                    liquidity,
                    slot0.observationCardinality
                );

            // 更新tickLower和tickUpper
            // 传入的参数除了要更新的tick和是否是upper tick的bool值, 其他参数都一样

            flippedLower = ticks.update(
                tickLower,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = ticks.update(
                tickUpper,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true,
                maxLiquidityPerTick
            );

            // 如果tick状态有翻转, 则在tickBtimap中更新

            if (flippedLower) {
                tickBitmap.flipTick(tickLower, tickSpacing);
            }
            if (flippedUpper) {
                tickBitmap.flipTick(tickUpper, tickSpacing);
            }
        }

        // 计算内侧手续费, 用于计算position内积累的手续费

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            ticks.getFeeGrowthInside(tickLower, tickUpper, tick, _feeGrowthGlobal0X128, _feeGrowthGlobal1X128);

        // 更新position
        // 更新position的流动性
        // 更新position的已领取和未领取手续费

        position.update(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

        // 如果流动性是减少的, 则清理翻转了的tick数据

        // clear any tick data that is no longer needed
        if (liquidityDelta < 0) {
            if (flippedLower) {
                ticks.clear(tickLower);
            }
            if (flippedUpper) {
                ticks.clear(tickUpper);
            }
        }
    }
```
uniswap-v3-core/contracts/libraries/Tick.sol

```js

    // 更新tick
    // 更新tick的累加流动性
    // 更新越过tick时需要增减的流动性
    // 如果是初始化的tick lower, 初始化tick的f0

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tickCurrent The current tick
    /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulativeX128 The all-time seconds per max(1, liquidity) of the pool
    /// @param time The current block timestamp cast to a uint32
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @param maxLiquidity The maximum liquidity allocation for a single tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {

        // 取出tick对象

        Tick.Info storage info = self[tick];

        // tick 更新之前和更新之后的流动性
        // liquidityDelta为正数则加上, 为负数则减去

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, liquidityDelta);

        // 防止当前价格流动性溢出, 只要每个tick的流动性不溢出, 就算当前价格流动性是所有的tick上流动性的总和时也不会溢出

        require(liquidityGrossAfter <= maxLiquidity, 'LO');

        // tick上流动性变成了0或从0变成了非0
        // 即tick前后状态有变化
        // after == 0: true or false
        // before == 0: true or false
        // flipped:     true != true    => false    after: 0,   before: 0
        //              true != false   => true     after: 0,   before: > 0
        //              false!= true    => true     after: > 0, before: 0    
        //              false!= false   => flase    after: > 0, before: > 0

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        // 如果 tick 在更新之前的 liquidityGross 为 0，那么表示我们本次为初始化操作
        // 这里会初始化 tick 中的 f_o

        if (liquidityGrossBefore == 0) {

            // 按照惯例，我们假设在一个价格变动被初始化之前的所有增长都发生在_低于_价格变动

            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick

            // f0的初始化
            // 对于tick lower和token upper两个tick, tick lower的f0会被初始化为fg, tick upper的f0初始化为0
            // 这样在保证了fg = tickLower.f0 + tickUpper.f0, 以后越过tick时在用 f0越过后 = fg - f0越过前 

            if (tick <= tickCurrent) {
                info.feeGrowthOutside0X128 = feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = feeGrowthGlobal1X128;
                info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128;
                info.tickCumulativeOutside = tickCumulative;
                info.secondsOutside = time;
            }
            info.initialized = true;
        }

        // tick上累加的流动性

        info.liquidityGross = liquidityGrossAfter;

        // tick上越过tick时需要加减的流动性
        // 是加还是减去, 与tick是position的上边界还是下边界有关, 也与价格越过tick的方向有关
        // 进入position区间, 加上流动性
        // 退出position区间, 减去流动性

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = upper
            ? int256(info.liquidityNet).sub(liquidityDelta).toInt128()
            : int256(info.liquidityNet).add(liquidityDelta).toInt128();
    }
```
uniswap-v3-core/contracts/libraries/SqrtPriceMath.sol

```js

    // 根据价格差和流动性计算token数量
    // 白皮书公式在流动性的使用

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
```

```js
    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }
```
#### 删除流动性

uniswap-v3-periphery/contracts/NonfungiblePositionManager.sol

```js

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

uniswap-v3-core/contracts/UniswapV3Pool.sol

```js

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
