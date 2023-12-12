// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UQ112x112} from "../library/UQ112x112.sol";

contract UniswapV2Pair is ERC20{
    using UQ112x112 for uint224;

    ////////////
    // Errors //
    ////////////

    error UniswapV2Pair__AddressZeroProvided();
    error UniswapV2Pair__InsufficientLiquidityMinted();
    error UniswapV2Pair__InsufficientBurnAmount();
    error UniswapV2Pair__ZeroAmountProvidedForSwap();
    error UniswapV2Pair__InavlidK();
    error TransferFailed();

    //////////////////////
    // Events and Enums //
    //////////////////////

    event Mint(address indexed sender, uint256 liquidity);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, uint256 amount0Out, uint256 amount1Out, address indexed to);

    ///////////////////////
    // Storage Variables //
    ///////////////////////

    address private immutable token0;
    address private immutable token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 private price0CumulativeLast;
    uint256 private price1CumulativeLast;

    uint256 private constant MINIMUM_LIQUIDITY = 1000;

    /////////////////
    // Constructor //
    /////////////////

    constructor(address _token0, address _token1) ERC20("UniswapV2Pair", "UNI-V2", 18){
        if(token0 == address(0) || token1 == address(0)){
            revert UniswapV2Pair__AddressZeroProvided();
        }
        token0 = _token0;
        token1 = _token1;
    }


    /////////////////////////
    // External and Public //
    /////////////////////////

    function mint() external payable {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        uint256 liquidity;

        if(totalSupply == 0){
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        }else{
            liquidity = Math.min(amount0 * totalSupply / reserve0, amount1 * totalSupply / reserve1);
        }

        if(liquidity == 0){
            revert UniswapV2Pair__InsufficientLiquidityMinted();
        }

        _mint(msg.sender, liquidity);

        // we have to implement reserves update here. we will create a function for that later

        emit Mint(msg.sender, liquidity);
    }


    function burn() public {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 liquidity = balanceOf[msg.sender];

        uint256 amount0 = liquidity * balance0 / totalSupply;
        uint256 amount1 = liquidity * balance1 / totalSupply;

        if(amount0 <= 0 || amount1 <= 0){
            revert UniswapV2Pair__InsufficientBurnAmount();
        }

        _burn(msg.sender, liquidity);

        _safeTransfer(token0, msg.sender, amount0);
        _safeTransfer(token1, msg.sender, amount1);

        // we have to implement reserves update here. we will create a function for that later

        emit Burn(msg.sender, amount0, amount1);
    }   

    function swap(uint256 amount0Out, uint256 amount1Out, address to) public {
        if(amount0Out == 0 && amount1Out == 0){
            revert UniswapV2Pair__ZeroAmountProvidedForSwap();
        }

        // old balances
        (uint112 _reserve0, uint112 _reserve1) = getReserves();

        
        // balance to withdraw should not be greater than the reserve
        if(amount0Out > _reserve0 || amount1Out > _reserve1){
            revert UniswapV2Pair__InsufficientBurnAmount();
        }

        // balances that will be after swap
        uint256 balance0 = IERC20(token0).balanceOf(address(this)) - amount0Out;
        uint256 balance1 = IERC20(token1).balanceOf(address(this)) - amount1Out;


        // new K should be more than old K
        // K = x * y
        // x = balance0
        // y = balance1
        if(balance0 * balance1 < uint256(reserve0) * uint256(reserve1)){
            revert UniswapV2Pair__InavlidK();
        }


        if(amount0Out > 0){
            _safeTransfer(token0, to, amount0Out);
        }

        if(amount1Out > 0){
            _safeTransfer(token1, to, amount1Out);
        }

        // we have to implement reserves update here. we will create a function for that later

        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }

    function _update(uint256 balance0, uint256 balance1) private {
        unchecked{
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;

            if(timeElapsed > 0 && balance0 > 0 && balance1 > 0){
                price0CumulativeLast +=
                    uint256(UQ112x112.encode(reserve1).uqdiv(reserve0)) *
                    timeElapsed;
                price1CumulativeLast +=
                    uint256(UQ112x112.encode(reserve0).uqdiv(reserve1)) *
                    timeElapsed;
            }
        } 

        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
    }


    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        if (!success || (data.length != 0 && !abi.decode(data, (bool))))
            revert TransferFailed();
    }
    

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1){
        return (reserve0, reserve1);
    }
}  