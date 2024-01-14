// TODO: Use safeERC20

//SPDX-License-Identifier:MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title TokenSwap
 * @notice A contract facilitating token swaps with adjustable exchange rates between pairs.
 * @notice This contract allows the owner to create pairs of tokens and set their exchange rates.
 * Users can swap tokens based on the specified exchange rates.
 */
contract TokenSwap is Ownable(msg.sender) {
    using SafeERC20 for ERC20;

    struct Pair {
        address tokenA;
        address tokenB;
        uint256 exchangeRate;
    }

    /// @dev store pairs using a unique symbol as the key
    mapping(string => Pair) public pairs;

    // Events to log pair creation, exchange rate updates, and token swaps
    event PairCreated(address tokenA, address tokenB, uint256 exchangeRate);
    event ExchangeRateUpdate(string symbol, uint256 newExchangeRate);
    event TokensSwapped(address indexed user, address indexed inToken, address indexed outToken, uint256 inAmount, uint256 outAmount);

    // Errors for various invalid scenarios
    error Invalid_ExchangeRate();
    error Invalid_Pair();
    error Pair_Exists();
    error Pair_DoesntExist();
    error Invalid_Amount();
    error Insufficient_OutTokens();
    error Insufficient_InTokens();

    /**
     * @notice Creates a new token pair with the specified exchange rate.
     * @param _tokenA The address of the first token in the pair.
     * @param _tokenB The address of the second token in the pair.
     * @param _exchangeRate The initial exchange rate between the two tokens.
     */
    function createPair(address _tokenA, address _tokenB, uint256 _exchangeRate) external onlyOwner {
        string memory pairSymbol = string(abi.encodePacked(ERC20(_tokenA).symbol(), "/", ERC20(_tokenB).symbol()));

        if(_tokenA == address(0) || _tokenB == address(0)) revert Invalid_Pair();
        if(_exchangeRate < 1) revert Invalid_ExchangeRate();
        if(pairs[pairSymbol].tokenA != address(0)) revert Pair_Exists();

        pairs[pairSymbol].tokenA = _tokenA;
        pairs[pairSymbol].tokenB = _tokenB;
        pairs[pairSymbol].exchangeRate = _exchangeRate;

        emit PairCreated(_tokenA, _tokenB, _exchangeRate);
    }

    /**
     * @notice Sets a new exchange rate for an existing token pair.
     * @param _symbol The unique symbol representing the token pair.
     * @param _newExchangeRate The new exchange rate to be set.
     */
    function setExchangeRate(string memory _symbol, uint256 _newExchangeRate) external onlyOwner {
        if (_newExchangeRate < 1) revert Invalid_ExchangeRate();
        if (pairs[_symbol].tokenA == address(0)) revert Pair_DoesntExist();

        pairs[_symbol].exchangeRate = _newExchangeRate;
        emit ExchangeRateUpdate(_symbol, _newExchangeRate);
    }

    /**
     * @notice Swaps tokens based on the specified pair and amount.
     * @param _pairSymbol The symbol representing the token pair.
     * @param _amount The amount of tokens to be swapped.
     * @param _swapSymbols Flag to indicate whether to swap the token symbols in the pair.
     */
    function swapTokens(string memory _pairSymbol, uint256 _amount, bool _swapSymbols) public {
        if (pairs[_pairSymbol].tokenA == address(0)) revert Invalid_Pair();
        if (_amount < 1) revert Invalid_Amount();

        address inToken;
        address outToken;
        uint256 inRate = 1;
        uint256 outRate = 1;
        if(_swapSymbols) {
            inToken = pairs[_pairSymbol].tokenB;
            outToken = pairs[_pairSymbol].tokenA;
            inRate = pairs[_pairSymbol].exchangeRate;
        } else {
            inToken = pairs[_pairSymbol].tokenA;
            outToken = pairs[_pairSymbol].tokenB;
            outRate = pairs[_pairSymbol].exchangeRate;
        }

        uint256 expectedTokenB = swapAmount(inToken, _amount, inRate, outRate);
        if (ERC20(inToken).balanceOf(msg.sender) < _amount) revert Insufficient_InTokens();
        if (ERC20(outToken).balanceOf(address(this)) < expectedTokenB) revert Insufficient_OutTokens();


        ERC20(inToken).safeTransferFrom(msg.sender, address(this), _amount);
        ERC20(outToken).approve(address(this), type(uint256).max);
        ERC20(outToken).safeTransferFrom(address(this), msg.sender, expectedTokenB);

        emit TokensSwapped(msg.sender, inToken, outToken, _amount, expectedTokenB);
    }

    /**
     * @notice Calculates the expected amount of output tokens based on input amount and exchange rates.
     * @param _inToken The address of the input token.
     * @param _amount The input amount of tokens.
     * @param _inRate The exchange rate of the input token.
     * @param _outRate The exchange rate of the output token.
     * @return The expected amount of output tokens.
     */
    function swapAmount(address _inToken, uint256 _amount, uint256 _inRate, uint256 _outRate) public view returns(uint256) {
        uint256 inDecimals = ERC20(_inToken).decimals();
        return (_outRate * _amount * 10**inDecimals) / (_inRate * 10**inDecimals);
    }

    /**
     * @notice Gets information about a token pair.
     * @param _symbol The symbol representing the token pair.
     * @param _swapSymbols Flag to indicate whether to swap the token symbols in the pair.
     * @return tokenA The address of the first token in the pair.
     * @return tokenB The address of the second token in the pair.
     * @return exchangeRate The exchange rate between the two tokens.
     */
    function getPair(string memory _symbol, bool _swapSymbols) public view returns(address tokenA, address tokenB, uint256 exchangeRate){
        Pair memory pair = pairs[_symbol];
        if(_swapSymbols) {
            tokenA = pair.tokenA;
            tokenB = pair.tokenB;
        } else {
            tokenA = pair.tokenB;
            tokenB = pair.tokenA;
        }
        exchangeRate = pair.exchangeRate;
    }
}