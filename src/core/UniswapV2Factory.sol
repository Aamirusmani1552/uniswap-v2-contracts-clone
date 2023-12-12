// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {UniswapV2Pair} from "./UniswapV2Pair.sol";

contract UniswapV2Factory{
    ////////////////////
    // Error Messages //
    ////////////////////
    
    error UniswapV2Factory__IdenticalAddressesProvided();
    error UniswapV2Factory__AddressZeroProvided();
    error UniswapV2Factory__PairsAlreadyExist();

    //////////////////////
    // Events and Enums //
    //////////////////////
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    ///////////////////////
    // Storage Variables //
    ///////////////////////
    mapping(address => mapping(address => address)) public pairs;
    address[] public allPairs;

    ///////////////////////
    // Constructor Logic //
    ///////////////////////
    constructor() {
        
    }


    //////////////////////////
    // Function Definitions //
    //////////////////////////
    function createPair(address token0, address token1) public {
        if(token0 == token1){
            revert UniswapV2Factory__IdenticalAddressesProvided();
        }

        (address tokenA, address tokenB) = token0 < token1 ? (token0, token1) : (token1, token0);

        if(tokenA == address(0)){
            revert UniswapV2Factory__AddressZeroProvided();
        }

        if(pairs[tokenA][tokenB] != address(0)){
            revert UniswapV2Factory__PairsAlreadyExist();
        }

        // creating new pair
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        address pairAddress;
        assembly{
            pairAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        UniswapV2Pair(pairAddress).Initialize(tokenA, tokenB);

        pairs[tokenA][tokenB] = pairAddress;
        pairs[tokenB][tokenA] = pairAddress;
        allPairs.push(pairAddress);


        emit PairCreated(tokenA, tokenB, pairAddress, allPairs.length);
    }
}