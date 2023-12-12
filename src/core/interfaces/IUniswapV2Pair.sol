// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IUniswapV2Pair{
    function Initialize(address token0, address token1) external;
    function mint(address to) external returns (uint256 liquidity);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}