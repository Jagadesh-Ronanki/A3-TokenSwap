//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {TokenSwap} from "../src/TokenSwap.sol";
import {ERC20Mock} from "./mock/ERC20Mock.sol";

contract TokenSwapTest is Test {
    address public owner = makeAddr("owner");
    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");

    TokenSwap public tokenSwapContract;
    ERC20Mock public TokenX;
    ERC20Mock public TokenY;
    ERC20Mock public TokenZ;

    modifier createPairs() {
        vm.startPrank(owner);

        // X:Y 1:1
        tokenSwapContract.createPair(address(TokenX), address(TokenY), 1);
        // Y:Z 1:4
        tokenSwapContract.createPair(address(TokenY), address(TokenZ), 4);
        // X:Z 1:2
        tokenSwapContract.createPair(address(TokenX), address(TokenZ), 2);

        vm.stopPrank();
        _;
    }

    function setUp() public {
        vm.startPrank(owner);

        tokenSwapContract = new TokenSwap();

        TokenX = new ERC20Mock("TokenX", "X");
        TokenY = new ERC20Mock("TokenY", "Y");
        TokenZ = new ERC20Mock("TokenZ", "Z");


        TokenX.mint(user1, 100);
        TokenX.mint(user2, 100);
        TokenX.mint(address(tokenSwapContract), 100);

        TokenY.mint(user1, 100);
        TokenY.mint(user2, 100);
        TokenY.mint(address(tokenSwapContract), 100);

        TokenZ.mint(user1, 100);
        TokenZ.mint(user2, 100);
        TokenZ.mint(address(tokenSwapContract), 100);


        vm.stopPrank();
    }

    function test_createPair() public {
        vm.startPrank(owner);

        // X:Y 1:1
        tokenSwapContract.createPair(address(TokenX), address(TokenY), 1);
        // Y:Z 1:4
        tokenSwapContract.createPair(address(TokenY), address(TokenZ), 4);
        // X:Z 1:2
        tokenSwapContract.createPair(address(TokenX), address(TokenZ), 2);

        vm.stopPrank();

        (address tokenA, address tokenB, uint256 exchangeRate) = tokenSwapContract.getPair("X/Y", false);
        assertEq(exchangeRate, 1);
        (tokenA, tokenB, exchangeRate) = tokenSwapContract.getPair("Y/Z", false);
        assertEq(exchangeRate, 4);
        (tokenA, tokenB, exchangeRate) = tokenSwapContract.getPair("X/Z", false);
        assertEq(exchangeRate, 2);
    }

    function testFail_duplicatePairs() public {
        vm.startPrank(owner);

        // X:Y 1:1
        tokenSwapContract.createPair(address(TokenX), address(TokenY), 1);
        // X:Y 1:4
        tokenSwapContract.createPair(address(TokenX), address(TokenY), 4); // <- FAIL

        vm.stopPrank();
    }

    function test_setExchangeRate() public {
        vm.prank(owner);
        // X:Y 1:1
        tokenSwapContract.createPair(address(TokenX), address(TokenY), 1);
        (address tokenA, address tokenB, uint256 exchangeRate) = tokenSwapContract.getPair("X/Y", false);
        assertEq(exchangeRate, 1);

        vm.prank(owner);
        tokenSwapContract.setExchangeRate("X/Y", 2);

        (tokenA, tokenB, exchangeRate) = tokenSwapContract.getPair("X/Y", false);
        assertEq(exchangeRate, 2);
    }

    function test_swapAmount() public createPairs {
        uint256 expectedOutTokens = tokenSwapContract.swapAmount(address(TokenX), 4, 1, 2);
        assertEq(expectedOutTokens, 8);

        expectedOutTokens = tokenSwapContract.swapAmount(address(TokenX), 8, 2, 1);
        assertEq(expectedOutTokens, 4);
    }

    function test_swapTokens() public createPairs {
        uint256 amount = 4;

        vm.startPrank(user1);
        TokenX.approve(address(tokenSwapContract), amount);
        tokenSwapContract.swapTokens("X/Z", amount, false);

        assertEq(TokenX.balanceOf(user1), 100-4); // swapped 4 X tokens for
        assertEq(TokenZ.balanceOf(user1), 100+8); // received 8 Z tokens

        vm.stopPrank();

        vm.startPrank(user2);
        TokenZ.approve(user2, type(uint256).max);
        TokenZ.approve(address(tokenSwapContract), type(uint256).max);
        tokenSwapContract.swapTokens("X/Z", amount, true);

        assertEq(TokenX.balanceOf(user2), 100+2); // swapped 4 X tokens for
        assertEq(TokenZ.balanceOf(user2), 100-4); // received 8 Z tokens

        vm.stopPrank();

    }

}