// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3PoolDeployer.sol';

import './UniswapV3Pool.sol';

contract UniswapV3PoolDeployer is IUniswapV3PoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    /// @inheritdoc IUniswapV3PoolDeployer
    Parameters public override parameters;

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
}
