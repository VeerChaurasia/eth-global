// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Amm.sol";
import "./mocks/ERC20.sol";

contract ArbitrageTest is Test {
    ERC20Mock token0;
    ERC20Mock token1;
    AMM amm1;
    AMM amm2;

    function setUp() public {
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();
        amm1 = new AMM(address(token0), address(token1));
        amm2 = new AMM(address(token0), address(token1));

        token0.mint(address(this), 100000000000000);
        token1.mint(address(this), 100000000000000 ether);

        token0.approve(address(amm1), type(uint256).max);
        token1.approve(address(amm1), type(uint256).max);
        token0.approve(address(amm2), type(uint256).max);
        token1.approve(address(amm2), type(uint256).max);

        amm1.addLiquidity(9999, 200 ether); 
        amm2.addLiquidity(10000, 200 ether);
    }

    function testArbitrageOpportunity() public {
        console2.log("=== Initial State ===");
        console2.log("AMM1 reserves - token0:", amm1.reserve0());
        console2.log("AMM1 reserves - token1:", amm1.reserve1());
        console2.log("AMM2 reserves - token0:", amm2.reserve0());
        console2.log("AMM2 reserves - token1:", amm2.reserve1());

        uint256 arbitrageAmount = 0.99 ether; 

        console2.log("=== Arbitrage Execution ===");
        console2.log("Using token0 amount:", arbitrageAmount);

        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));

        console2.log("Initial token0 balance:", initialToken0Balance);
        console2.log("Initial token1 balance:", initialToken1Balance);

        uint256 token1Received = amm1.swapWithoutFees(
            address(token0),
            arbitrageAmount
        );
        console2.log("Token0 swapped:", arbitrageAmount);
        console2.log("Token1 received from AMM1:", token1Received);

        uint256 token0Received = amm2.swap(address(token1), token1Received);
        console2.log("Token1 swapped:", token1Received);
        console2.log("Token0 received from AMM2:", token0Received);

        uint256 finalToken0Balance = token0.balanceOf(address(this));
        uint256 finalToken1Balance = token1.balanceOf(address(this));

        console2.log("=== Final State ===");
        console2.log("Final token0 balance:", finalToken0Balance);
        console2.log("Final token1 balance:", finalToken1Balance);
        console2.log("AMM1 final token0:", amm1.reserve0());
        console2.log("AMM1 final token1:", amm1.reserve1());
        console2.log("AMM2 final token0:", amm2.reserve0());
        console2.log("AMM2 final token1:", amm2.reserve1());

        int256 token0Profit = int256(finalToken0Balance) -
            int256(initialToken0Balance);
        int256 token1Profit = int256(finalToken1Balance) -
            int256(initialToken1Balance);

        console2.log("=== Profit Analysis ===");
        if (token0Profit > 0) {
            console2.log("Profit in token0:", uint256(token0Profit));
        } else if (token0Profit < 0) {
            console2.log("Loss in token0:", uint256(-token0Profit));
        } else {
            console2.log("No change in token0");
        }

        if (token1Profit > 0) {
            console2.log("Profit in token1:", uint256(token1Profit));
        } else if (token1Profit < 0) {
            console2.log("Loss in token1:", uint256(-token1Profit));
        } else {
            console2.log("No change in token1");
        }

        assertTrue(
            token0Received > 0,
            "Should receive some token0 from arbitrage"
        );
        assertTrue(
            token1Received > 0,
            "Should receive some token1 from first swap"
        );
    }

    function testReverseArbitrage() public {
        console2.log("=== Initial State ===");
        console2.log("AMM1 reserves - token0:", amm1.reserve0());
        console2.log("AMM1 reserves - token1:", amm1.reserve1());
        console2.log("AMM2 reserves - token0:", amm2.reserve0());
        console2.log("AMM2 reserves - token1:", amm2.reserve1());

        uint256 arbitrageAmount = 0.1 ether; 

        console2.log("=== Arbitrage Execution ===");
        console2.log("Using token0 amount:", arbitrageAmount);

        uint256 initialToken0Balance = token0.balanceOf(address(this));
        uint256 initialToken1Balance = token1.balanceOf(address(this));

        console2.log("Initial token0 balance:", initialToken0Balance);
        console2.log("Initial token1 balance:", initialToken1Balance);

        uint256 token1Received = amm1.swapWithoutFees(
            address(token0),
            arbitrageAmount
        );
        console2.log("Token0 swapped:", arbitrageAmount);
        console2.log("Token1 received from AMM1:", token1Received);

        uint256 token0Received = amm2.swapWithoutFees(
            address(token1),
            token1Received
        );
        console2.log("Token1 swapped:", token1Received);
        console2.log("Token0 received from AMM2:", token0Received);

        uint256 finalToken0Balance = token0.balanceOf(address(this));
        uint256 finalToken1Balance = token1.balanceOf(address(this));

        console2.log("=== Final State ===");
        console2.log("Final token0 balance:", finalToken0Balance);
        console2.log("Final token1 balance:", finalToken1Balance);
        console2.log("AMM1 final token0:", amm1.reserve0());
        console2.log("AMM1 final token1:", amm1.reserve1());
        console2.log("AMM2 final token0:", amm2.reserve0());
        console2.log("AMM2 final token1:", amm2.reserve1());

        int256 token0Profit = int256(finalToken0Balance) -
            int256(initialToken0Balance);
        int256 token1Profit = int256(finalToken1Balance) -
            int256(initialToken1Balance);

        console2.log("=== Profit Analysis ===");
        if (token0Profit > 0) {
            console2.log("Profit in token0:", uint256(token0Profit));
        } else if (token0Profit < 0) {
            console2.log("Loss in token0:", uint256(-token0Profit));
        } else {
            console2.log("No change in token0");
        }

        if (token1Profit > 0) {
            console2.log("Profit in token1:", uint256(token1Profit));
        } else if (token1Profit < 0) {
            console2.log("Loss in token1:", uint256(-token1Profit));
        } else {
            console2.log("No change in token1");
        }

        assertTrue(
            token0Received > 0,
            "Should receive some token0 from arbitrage"
        );
        assertTrue(
            token1Received > 0,
            "Should receive some token1 from first swap"
        );
    }
}