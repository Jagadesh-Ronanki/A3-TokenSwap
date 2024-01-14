// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {TokenSwap} from "../src/TokenSwap.sol";
import {ERC20Mock} from "../test/mock/ERC20Mock.sol";

contract DeployTokenSwap is Script {
    address[] public users;
    ERC20Mock[] public tokens;

    function run() public returns(TokenSwap, HelperConfig, ERC20Mock[] memory, address[] memory) {
        HelperConfig helperConfig = new HelperConfig();
        (,uint256 deployerKey) = helperConfig.activeNetworkConfig();

        address user1 = address(1);
        address user2 = address(2);

        vm.startBroadcast(deployerKey);

        TokenSwap tokenSwapContract = new TokenSwap();

        ERC20Mock TokenX = new ERC20Mock("TokenX", "X");
        ERC20Mock TokenY = new ERC20Mock("TokenY", "Y");
        ERC20Mock TokenZ = new ERC20Mock("TokenZ", "Z");

        TokenX.mint(user1, 100);
        TokenX.mint(user2, 100);

        TokenY.mint(user1, 100);
        TokenY.mint(user2, 100);

        TokenZ.mint(user1, 100);
        TokenZ.mint(user2, 100);

        vm.stopBroadcast();

        tokens.push(TokenX);
        tokens.push(TokenY);
        tokens.push(TokenZ);

        users.push(user1);
        users.push(user2);

        vm.startPrank(user1);
        TokenX.approve(address(tokenSwapContract), type(uint256).max);
        TokenY.approve(address(tokenSwapContract), type(uint256).max);
        TokenZ.approve(address(tokenSwapContract), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        TokenX.approve(address(tokenSwapContract), type(uint256).max);
        TokenY.approve(address(tokenSwapContract), type(uint256).max);
        TokenZ.approve(address(tokenSwapContract), type(uint256).max);
        vm.stopPrank();

        return (tokenSwapContract, helperConfig, tokens, users);
    }
}