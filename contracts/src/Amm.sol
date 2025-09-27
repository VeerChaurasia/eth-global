// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import {PoolId} from "../lib/v4-core/src/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "../lib/v4-core/src/types/Currency.sol";

import "./ERC20Mock.sol";
import "./AmAmm.sol";

contract AmAmmMock is AmAmm {
    using CurrencyLibrary for Currency;

    ERC20Mock public immutable bidToken;
    ERC20Mock public immutable feeToken0;
    ERC20Mock public immutable feeToken1;

    mapping(PoolId id => bool) public enabled;
    mapping(PoolId id => uint128) public minRent;
    mapping(PoolId id => uint24) public maxSwapFee;
    
    // Uniswap V2-like storage for liquidity management
    mapping(PoolId id => uint256) public reserve0;
    mapping(PoolId id => uint256) public reserve1;
    mapping(PoolId id => uint256) public totalSupply;
    mapping(PoolId id => mapping(address => uint256)) public balanceOf;

    constructor(ERC20Mock _bidToken, ERC20Mock _feeToken0, ERC20Mock _feeToken1) {
        bidToken = _bidToken;
        feeToken0 = _feeToken0;
        feeToken1 = _feeToken1;
    }

    function setEnabled(PoolId id, bool value) external {
        enabled[id] = value;
    }
    
    function addLiquidity(PoolId id, uint256 amount0, uint256 amount1) external returns (uint256 shares) {
        // Transfer tokens from user to contract
        feeToken0.transferFrom(msg.sender, address(this), amount0);
        feeToken1.transferFrom(msg.sender, address(this), amount1);

        // If first liquidity provider
        if (totalSupply[id] == 0) {
            shares = _sqrt(amount0 * amount1);
        } else {
            // Ensure proportional liquidity addition
            require(
                reserve0[id] * amount1 == reserve1[id] * amount0,
                "Invalid ratio"
            );
            shares = _min(
                (amount0 * totalSupply[id]) / reserve0[id],
                (amount1 * totalSupply[id]) / reserve1[id]
            );
        }
        require(shares > 0, "Insufficient liquidity minted");
        
        // Mint LP tokens
        balanceOf[id][msg.sender] += shares;
        totalSupply[id] += shares;

        // Update reserves
        _updateReserves(id);
    }

    function removeLiquidity(PoolId id, uint256 shares) external returns (uint256 amount0, uint256 amount1) {
        require(balanceOf[id][msg.sender] >= shares, "Insufficient balance");
        
        uint256 bal0 = feeToken0.balanceOf(address(this));
        uint256 bal1 = feeToken1.balanceOf(address(this));

        amount0 = (shares * bal0) / totalSupply[id];
        amount1 = (shares * bal1) / totalSupply[id];
        require(amount0 > 0 && amount1 > 0, "Insufficient liquidity burned");

        // Burn LP tokens
        balanceOf[id][msg.sender] -= shares;
        totalSupply[id] -= shares;

        // Transfer tokens to user
        feeToken0.transfer(msg.sender, amount0);
        feeToken1.transfer(msg.sender, amount1);

        // Update reserves
        _updateReserves(id);
    }

    function setMinRent(PoolId id, uint128 value) external {
        minRent[id] = value;
    }

    function swap(PoolId id, Currency inputCurrency, uint256 inputAmount) external returns (uint256 outputAmount) {
        require(inputAmount > 0, "Invalid input amount");
        require(_amAmmEnabled(id), "AmAmm not enabled");
        
        // Update state machine to get current manager
        _updateAmAmmWrite(id);
        
        // Get current top bid to determine swap fee
        Bid memory topBid = _topBids[id];
        require(topBid.manager != address(0), "No active manager");
        
        // Extract swap fee from payload (first 3 bytes)
        uint24 swapFee = uint24(bytes3(topBid.payload));
        
        bool isToken0 = inputCurrency == Currency.wrap(address(feeToken0));
        require(
            isToken0 || inputCurrency == Currency.wrap(address(feeToken1)),
            "Invalid input currency"
        );

        (
            ERC20Mock tokenIn,
            ERC20Mock tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isToken0
            ? (feeToken0, feeToken1, reserve0[id], reserve1[id])
            : (feeToken1, feeToken0, reserve1[id], reserve0[id]);

        // Transfer input tokens
        tokenIn.transferFrom(msg.sender, address(this), inputAmount);

        // Calculate swap fee (fee is in basis points, so divide by 1e6)
        uint256 feeAmount = (inputAmount * swapFee) / 1e6;
        uint256 amountInWithFee = inputAmount - feeAmount;

        // Check that there's sufficient liquidity
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // Uniswap V2 constant product formula: x * y = k
        outputAmount = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);
        require(outputAmount > 0 && outputAmount < reserveOut, "Insufficient output amount");

        // Transfer output tokens
        tokenOut.transfer(msg.sender, outputAmount);

        // Accrue fees to the current manager
        if (feeAmount > 0) {
            _accrueFees(topBid.manager, inputCurrency, feeAmount);
        }

        // Update reserves
        _updateReserves(id);
    }

    function setMaxSwapFee(PoolId id, uint24 value) external {
        maxSwapFee[id] = value;
    }

    // View functions for UI/external integrations
    function getReserves(PoolId id) external view returns (uint256 _reserve0, uint256 _reserve1) {
        _reserve0 = reserve0[id];
        _reserve1 = reserve1[id];
    }

    function getLPTokenBalance(PoolId id, address user) external view returns (uint256) {
        return balanceOf[id][user];
    }

    function getTotalSupply(PoolId id) external view returns (uint256) {
        return totalSupply[id];
    }

    // Swap function without fees (for testing/arbitrage scenarios)
    function swapWithoutFees(PoolId id, Currency inputCurrency, uint256 inputAmount) external returns (uint256 outputAmount) {
        require(inputAmount > 0, "Invalid input amount");
        
        bool isToken0 = inputCurrency == Currency.wrap(address(feeToken0));
        require(
            isToken0 || inputCurrency == Currency.wrap(address(feeToken1)),
            "Invalid input currency"
        );

        (
            ERC20Mock tokenIn,
            ERC20Mock tokenOut,
            uint256 reserveIn,
            uint256 reserveOut
        ) = isToken0
            ? (feeToken0, feeToken1, reserve0[id], reserve1[id])
            : (feeToken1, feeToken0, reserve1[id], reserve0[id]);

        // Check that there's sufficient liquidity
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // Transfer input tokens
        tokenIn.transferFrom(msg.sender, address(this), inputAmount);

        // Uniswap V2 constant product formula without fees: x * y = k
        outputAmount = (reserveOut * inputAmount) / (reserveIn + inputAmount);
        require(outputAmount > 0 && outputAmount < reserveOut, "Insufficient output amount");

        // Transfer output tokens
        tokenOut.transfer(msg.sender, outputAmount);

        // Update reserves
        _updateReserves(id);
    }
    function giveFeeToken0(PoolId id, uint256 amount) external {
        _updateAmAmmWrite(id);
        address manager = _topBids[id].manager;
        feeToken0.mint(address(this), amount);
        _accrueFees(manager, Currency.wrap(address(feeToken0)), amount);
    }

    function giveFeeToken1(PoolId id, uint256 amount) external {
        _updateAmAmmWrite(id);
        address manager = _topBids[id].manager;
        feeToken1.mint(address(this), amount);
        _accrueFees(manager, Currency.wrap(address(feeToken1)), amount);
    }

    function MIN_RENT(PoolId id) internal view override returns (uint128) {
        return minRent[id];
    }

    /// @dev Returns whether the am-AMM is enabled for a given pool
    function _amAmmEnabled(PoolId id) internal view override returns (bool) {
        return enabled[id];
    }

    /// @dev Validates a bid payload
    function _payloadIsValid(PoolId id, bytes6 payload) internal view override returns (bool) {
        // first 3 bytes of payload are the swap fee
        return uint24(bytes3(payload)) <= maxSwapFee[id];
    }

    /// @dev Burns bid tokens from address(this)
    function _burnBidToken(PoolId, uint256 amount) internal override {
        bidToken.burn(amount);
    }

    /// @dev Transfers bid tokens from an address that's not address(this) to address(this)
    function _pullBidToken(PoolId, address from, uint256 amount) internal override {
        bidToken.transferFrom(from, address(this), amount);
    }

    /// @dev Transfers bid tokens from address(this) to an address that's not address(this)
    function _pushBidToken(PoolId, address to, uint256 amount) internal override {
        bidToken.transfer(to, amount);
    }

    /// @dev Transfers accrued fees from address(this)
    function _transferFeeToken(Currency currency, address to, uint256 amount) internal override {
        currency.transfer(to, amount);
    }

    // Helper functions for Uniswap V2-like calculations
    function _updateReserves(PoolId id) private {
        reserve0[id] = feeToken0.balanceOf(address(this));
        reserve1[id] = feeToken1.balanceOf(address(this));
    }

    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}
