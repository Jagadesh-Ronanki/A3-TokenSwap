// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {TokenSwap} from "../src/TokenSwap.sol";
import {DeployTokenSwap} from "./DeployTokenSwap.s.sol";
import {ERC20Mock} from "../test/mock/ERC20Mock.sol";

contract InteractTokenSwap is Script {
    TokenSwap public tokenSwapContract;
    HelperConfig public helperConfig;
    ERC20Mock[] public tokens;
    address[] public users;

    function run() public {
        DeployTokenSwap deploy = new DeployTokenSwap();
        (tokenSwapContract, helperConfig, tokens, users) = deploy.run();

        (,uint256 deployerKey) = helperConfig.activeNetworkConfig();

        mintTokensToTokenSwap(deployerKey, tokens);
        createPairs(deployerKey, tokens);
        setExchangeRate(deployerKey, "Y/Z", 2);
        swapToken("X/Y", 10, false);
        swapToken("Y/Z", 10, true);
        swapToken("X/Z", 10, true);

        console.log("4. User0 Token Balances");
        console.log("==============================");
        console.log("TokenX:", ERC20Mock(tokens[0]).balanceOf(users[0]));
        console.log("TokenY:", ERC20Mock(tokens[1]).balanceOf(users[0]));
        console.log("TokenZ:", ERC20Mock(tokens[2]).balanceOf(users[0]));
        console.log("==============================");
    }

    function mintTokensToTokenSwap(uint256 _deployerKey, ERC20Mock[] memory _tokens) public {
        vm.startBroadcast(_deployerKey);
        for(uint8 i; i<_tokens.length; i++) {
            _tokens[i].mint(address(tokenSwapContract), 100);
        }
        vm.stopBroadcast();
    }

    function createPairs(uint256 _deployerKey, ERC20Mock[] memory _tokens) public {
        vm.startBroadcast(_deployerKey);

        // X:Y 1:1
        tokenSwapContract.createPair(address(_tokens[0]), address(_tokens[1]), 1);
        // Y:Z 1:4
        tokenSwapContract.createPair(address(_tokens[1]), address(_tokens[2]), 4);
        // X:Z 1:2
        tokenSwapContract.createPair(address(_tokens[0]), address(_tokens[2]), 2);

        vm.stopBroadcast();

        console.log("1. Pairs Created");
        console.log("==============================");
        (, , uint256 exchangeRate) = tokenSwapContract.getPair("X/Y", false);
        console.log("Tokens: X/Y Exchange rate:", exchangeRate);
        (, , exchangeRate) = tokenSwapContract.getPair("Y/Z", false);
        console.log("Tokens: Y/Z Exchange rate:", exchangeRate);
        (, , exchangeRate) = tokenSwapContract.getPair("X/Z", false);
        console.log("Tokens: X/Z Exchange rate:", exchangeRate);
        console.log("==============================");
    }

    function setExchangeRate(uint256 _deployerKey, string memory _symbol, uint256 _newExchangeRate) public {
        vm.startBroadcast(_deployerKey);
        tokenSwapContract.setExchangeRate(_symbol, _newExchangeRate);
        vm.stopBroadcast();

        (, , uint256 exchangeRate) = tokenSwapContract.getPair(_symbol, false);
        console.log("2.", _symbol, "exchange rate updated to", exchangeRate);
    }

    function swapToken(string memory _symbol, uint256 _amount, bool _swapSymbols) public {
        console.log("3. Swap Operation");
        console.log("==============================");
        console.log("Swap", _amount, _symbol);
        console.log("swap symbols:", _swapSymbols);
        (address inToken, address outToken,) = tokenSwapContract.getPair(_symbol, _swapSymbols);

        address currUser = users[0];
        console.log("InToken balance of user0: ", ERC20Mock(inToken).balanceOf(currUser));
        console.log("OutToken balance of user0: ", ERC20Mock(outToken).balanceOf(currUser));

        vm.startBroadcast(currUser);
        tokenSwapContract.swapTokens(_symbol, _amount, _swapSymbols);
        vm.stopBroadcast();

        console.log("InToken balance of user0: ", ERC20Mock(inToken).balanceOf(currUser));
        console.log("OutToken balance of user0: ", ERC20Mock(outToken).balanceOf(currUser));
        console.log("==============================");
    }
}