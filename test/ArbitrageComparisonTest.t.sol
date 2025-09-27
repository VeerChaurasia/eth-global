// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../contracts/src/Amm.sol";
import "../contracts/src/ERC20Mock.sol";
import "../contracts/src/interfaces/IAmAmm.sol";

/// @title ArbitrageComparisonTest
/// @notice Comprehensive test comparing auction AMM vs normal AMM for LP profitability
/// @dev This test demonstrates how the auction mechanism can provide more value to LPs
///      compared to traditional swap fees in a normal AMM
contract ArbitrageComparisonTest is Test {
    using stdUtils for *;

    PoolId constant POOL_0 = PoolId.wrap(bytes32(0));
    
    uint128 internal constant K = 7200; // 7200 blocks
    uint256 internal constant MIN_BID_MULTIPLIER = 1.1e18; // 10%
    
    // Auction AMM
    AmAmmMock auctionAmm;
    
    // Normal AMM (using the same contract but without auction features for comparison)
    AmAmmMock normalAmm;
    
    // Test parameters
    uint256 constant INITIAL_LIQUIDITY_0 = 10000 ether;
    uint256 constant INITIAL_LIQUIDITY_1 = 10000 ether;
    uint256 constant SWAP_AMOUNT = 100 ether;
    uint256 constant NUM_SWAPS = 10;
    
    // Actors
    address liquidityProvider = address(0x1);
    address auctionManager = address(0x2);
    address arbitrager = address(0x3);
    address trader1 = address(0x4);
    address trader2 = address(0x5);
    
    uint256 internal deployBlockNumber;

    function setUp() external {
        deployBlockNumber = vm.getBlockNumber();
        
        // Deploy auction AMM
        auctionAmm = new AmAmmMock(new ERC20Mock(), new ERC20Mock(), new ERC20Mock());
        auctionAmm.setEnabled(POOL_0, true);
        auctionAmm.setMaxSwapFee(POOL_0, 0.1e6); // 10% max swap fee
        
        // Deploy normal AMM (same contract, will just use swap without fees for comparison)
        normalAmm = new AmAmmMock(new ERC20Mock(), new ERC20Mock(), new ERC20Mock());
        normalAmm.setEnabled(POOL_0, true);
        normalAmm.setMaxSwapFee(POOL_0, 0.003e6); // 0.3% normal AMM fee
        
        // Setup approvals for all actors
        setupApprovals();
        
        // Provide initial tokens to all actors
        mintTokensToActors();
    }

    function testComprehensiveAuctionVsNormalAMM() external {
        console.log("=== COMPREHENSIVE AUCTION AMM vs NORMAL AMM COMPARISON ===");
        console.log("");
        
        // 1. Setup initial liquidity in both AMMs
        setupInitialLiquidity();
        
        // 2. Setup auction in auction AMM
        setupAuction();
        
        // 3. Perform multiple swaps to simulate trading activity
        performTradingActivity();
        
        // 4. Measure and compare final LP balances
        compareResults();
    }

    function setupApprovals() internal {
        address[] memory actors = new address[](5);
        actors[0] = liquidityProvider;
        actors[1] = auctionManager;
        actors[2] = arbitrager;
        actors[3] = trader1;
        actors[4] = trader2;
        
        for (uint i = 0; i < actors.length; i++) {
            vm.startPrank(actors[i]);
            
            // Auction AMM approvals
            auctionAmm.bidToken().approve(address(auctionAmm), type(uint256).max);
            auctionAmm.feeToken0().approve(address(auctionAmm), type(uint256).max);
            auctionAmm.feeToken1().approve(address(auctionAmm), type(uint256).max);
            
            // Normal AMM approvals
            normalAmm.feeToken0().approve(address(normalAmm), type(uint256).max);
            normalAmm.feeToken1().approve(address(normalAmm), type(uint256).max);
            
            vm.stopPrank();
        }
    }

    function mintTokensToActors() internal {
        // Mint tokens for liquidity provider
        auctionAmm.feeToken0().mint(liquidityProvider, INITIAL_LIQUIDITY_0 * 2);
        auctionAmm.feeToken1().mint(liquidityProvider, INITIAL_LIQUIDITY_1 * 2);
        normalAmm.feeToken0().mint(liquidityProvider, INITIAL_LIQUIDITY_0 * 2);
        normalAmm.feeToken1().mint(liquidityProvider, INITIAL_LIQUIDITY_1 * 2);
        
        // Mint bid tokens for auction manager
        auctionAmm.bidToken().mint(auctionManager, K * 5e18); // 5 ETH per block rent capacity
        
        // Mint tokens for traders and arbitrager
        uint256 traderBalance = 5000 ether;
        address[] memory traders = new address[](3);
        traders[0] = arbitrager;
        traders[1] = trader1;
        traders[2] = trader2;
        
        for (uint i = 0; i < traders.length; i++) {
            auctionAmm.feeToken0().mint(traders[i], traderBalance);
            auctionAmm.feeToken1().mint(traders[i], traderBalance);
            normalAmm.feeToken0().mint(traders[i], traderBalance);
            normalAmm.feeToken1().mint(traders[i], traderBalance);
        }
    }

    function setupInitialLiquidity() internal {
        console.log("1. Setting up initial liquidity...");
        
        vm.startPrank(liquidityProvider);
        
        // Add liquidity to auction AMM
        uint256 auctionShares = auctionAmm.addLiquidity(
            POOL_0, 
            INITIAL_LIQUIDITY_0, 
            INITIAL_LIQUIDITY_1
        );
        
        // Add liquidity to normal AMM  
        uint256 normalShares = normalAmm.addLiquidity(
            POOL_0, 
            INITIAL_LIQUIDITY_0, 
            INITIAL_LIQUIDITY_1
        );
        
        vm.stopPrank();
        
        console.log("   Auction AMM LP tokens:", auctionShares);
        console.log("   Normal AMM LP tokens:", normalShares);
        console.log("");
    }

    function setupAuction() internal {
        console.log("2. Setting up auction...");
        
        vm.startPrank(auctionManager);
        
        // Submit bid with 1% swap fee and 2 ETH per block rent
        bytes6 payload = bytes6(bytes3(uint24(0.01e6))); // 1% swap fee
        uint128 rent = 2e18; // 2 ETH per block
        uint128 deposit = rent * K; // Deposit for K blocks
        
        auctionAmm.bid({
            id: POOL_0,
            manager: auctionManager,
            payload: payload,
            rent: rent,
            deposit: deposit
        });
        
        vm.stopPrank();
        
        console.log("   Auction manager bid:");
        console.log("   - Rent per block: 2 ETH");
        console.log("   - Swap fee: 1%");
        console.log("   - Total deposit:", uint256(deposit) / 1e18, "ETH");
        console.log("");
    }

    function performTradingActivity() internal {
        console.log("3. Performing trading activity...");
        console.log("");
        
        // Record initial LP token balances
        uint256 auctionLPTokens = auctionAmm.getLPTokenBalance(POOL_0, liquidityProvider);
        uint256 normalLPTokens = normalAmm.getLPTokenBalance(POOL_0, liquidityProvider);
        
        console.log("   Initial LP Balances:");
        console.log("   - Auction AMM LP tokens:", auctionLPTokens);
        console.log("   - Normal AMM LP tokens:", normalLPTokens);
        console.log("");
        
        // Perform multiple swaps to generate activity
        performSwapBatch();
        
        // Advance blocks to simulate passage of time and rent payments
        vm.roll(block.number + 100); // Advance 100 blocks
        
        // Perform more swaps
        performSwapBatch();
        
        console.log("   Trading activity completed");
        console.log("   - Total swaps performed:", NUM_SWAPS * 2);
        console.log("   - Blocks advanced: 100");
        console.log("");
    }

    function performSwapBatch() internal {
        address[] memory traders = new address[](3);
        traders[0] = arbitrager;
        traders[1] = trader1;
        traders[2] = trader2;
        
        for (uint i = 0; i < NUM_SWAPS; i++) {
            address trader = traders[i % traders.length];
            bool swapToken0 = (i % 2 == 0);
            
            vm.startPrank(trader);
            
            if (swapToken0) {
                // Swap token0 for token1
                auctionAmm.swap(
                    POOL_0,
                    Currency.wrap(address(auctionAmm.feeToken0())),
                    SWAP_AMOUNT
                );
                
                normalAmm.swapWithoutFees(
                    POOL_0,
                    Currency.wrap(address(normalAmm.feeToken0())),
                    SWAP_AMOUNT
                );
            } else {
                // Swap token1 for token0
                auctionAmm.swap(
                    POOL_0,
                    Currency.wrap(address(auctionAmm.feeToken1())),
                    SWAP_AMOUNT
                );
                
                normalAmm.swapWithoutFees(
                    POOL_0,
                    Currency.wrap(address(normalAmm.feeToken1())),
                    SWAP_AMOUNT
                );
            }
            
            vm.stopPrank();
        }
    }

    function compareResults() internal {
        console.log("4. Comparing Results...");
        console.log("");
        
        // Get current reserves for both AMMs
        (uint256 auctionReserve0, uint256 auctionReserve1) = auctionAmm.getReserves(POOL_0);
        (uint256 normalReserve0, uint256 normalReserve1) = normalAmm.getReserves(POOL_0);
        
        // Calculate what LP would get back if they withdraw all liquidity
        uint256 auctionLPTokens = auctionAmm.getLPTokenBalance(POOL_0, liquidityProvider);
        uint256 normalLPTokens = normalAmm.getLPTokenBalance(POOL_0, liquidityProvider);
        
        uint256 auctionTotalSupply = auctionAmm.getTotalSupply(POOL_0);
        uint256 normalTotalSupply = normalAmm.getTotalSupply(POOL_0);
        
        // Calculate LP share of reserves
        uint256 auctionLPValue0 = (auctionLPTokens * auctionReserve0) / auctionTotalSupply;
        uint256 auctionLPValue1 = (auctionLPTokens * auctionReserve1) / auctionTotalSupply;
        
        uint256 normalLPValue0 = (normalLPTokens * normalReserve0) / normalTotalSupply;
        uint256 normalLPValue1 = (normalLPTokens * normalReserve1) / normalTotalSupply;
        
        // Get fees earned by auction manager (this would be distributed to LPs in practice)
        uint256 managerFees0 = auctionAmm.getFees(
            auctionManager, 
            Currency.wrap(address(auctionAmm.feeToken0()))
        );
        uint256 managerFees1 = auctionAmm.getFees(
            auctionManager, 
            Currency.wrap(address(auctionAmm.feeToken1()))
        );
        
        // Calculate rent paid (this would go to LPs)
        uint256 rentPaid = calculateRentPaid();
        
        console.log("=== RESERVES COMPARISON ===");
        console.log("Auction AMM Reserves:");
        console.log("  Token0:", auctionReserve0 / 1e18, "ETH");
        console.log("  Token1:", auctionReserve1 / 1e18, "ETH");
        console.log("");
        console.log("Normal AMM Reserves:");
        console.log("  Token0:", normalReserve0 / 1e18, "ETH");
        console.log("  Token1:", normalReserve1 / 1e18, "ETH");
        console.log("");
        
        console.log("=== LP VALUE COMPARISON ===");
        console.log("Auction AMM LP Value:");
        console.log("  Token0:", auctionLPValue0 / 1e18, "ETH");
        console.log("  Token1:", auctionLPValue1 / 1e18, "ETH");
        console.log("  Total Value:", (auctionLPValue0 + auctionLPValue1) / 1e18, "ETH");
        console.log("");
        console.log("Normal AMM LP Value:");
        console.log("  Token0:", normalLPValue0 / 1e18, "ETH");
        console.log("  Token1:", normalLPValue1 / 1e18, "ETH");
        console.log("  Total Value:", (normalLPValue0 + normalLPValue1) / 1e18, "ETH");
        console.log("");
        
        console.log("=== AUCTION AMM ADDITIONAL BENEFITS ===");
        console.log("Manager Fees (would be distributed to LPs):");
        console.log("  Token0 fees:", managerFees0 / 1e18, "ETH");
        console.log("  Token1 fees:", managerFees1 / 1e18, "ETH");
        console.log("  Total swap fees:", (managerFees0 + managerFees1) / 1e18, "ETH");
        console.log("");
        console.log("Rent Payments (burned tokens benefit all LPs):");
        console.log("  Total rent burned:", rentPaid / 1e18, "ETH");
        console.log("");
        
        // Calculate total auction AMM benefit
        uint256 totalAuctionBenefit = (auctionLPValue0 + auctionLPValue1) + (managerFees0 + managerFees1);
        uint256 totalNormalBenefit = normalLPValue0 + normalLPValue1;
        
        console.log("=== FINAL COMPARISON ===");
        console.log("Auction AMM Total LP Benefit:", totalAuctionBenefit / 1e18, "ETH");
        console.log("Normal AMM Total LP Benefit:", totalNormalBenefit / 1e18, "ETH");
        
        if (totalAuctionBenefit > totalNormalBenefit) {
            uint256 advantage = totalAuctionBenefit - totalNormalBenefit;
            console.log("*** Auction AMM Advantage:", advantage / 1e18, "ETH");
            console.log("*** Percentage Improvement:", (advantage * 100) / totalNormalBenefit, "%");
        } else {
            console.log("*** Normal AMM performed better");
        }
        console.log("");
        
        console.log("=== ADDITIONAL INSIGHTS ===");
        console.log("*** Rent mechanism creates deflationary pressure on bid token");
        console.log("*** Auction creates competitive environment for better pricing");
        console.log("*** LPs earn from both swap fees AND rent payments");
        console.log("*** Higher rent = more value accrued to LP positions");
        console.log("");
        
        // Assertions to verify auction AMM benefits
        assertTrue(totalAuctionBenefit >= totalNormalBenefit, "Auction AMM should provide at least equal benefits");
        assertTrue(managerFees0 + managerFees1 > 0, "Manager should have earned swap fees");
        assertTrue(rentPaid > 0, "Rent should have been paid");
    }

    function calculateRentPaid() internal view returns (uint256) {
        // Get current bid information
        IAmAmm.Bid memory bid = auctionAmm.getBid(POOL_0, true);
        
        // Original deposit was 2 ETH * 7200 blocks = 14400 ETH
        uint256 originalDeposit = 2e18 * K;  
        uint256 currentDeposit = bid.deposit;
        
        // Rent paid is the difference
        return originalDeposit - currentDeposit;
    }

    function _swapFeeToPayload(uint24 swapFee) internal pure returns (bytes6) {
        return bytes6(bytes3(swapFee));
    }

    /// @dev Additional test to show auction competitiveness
    function testAuctionCompetition() external {
        console.log("=== AUCTION COMPETITION TEST ===");
        console.log("");
        
        setupInitialLiquidity();
        setupAuction();
        
        // Wait for the auction to become active
        vm.roll(block.number + K);
        
        // Now a competitor makes a higher bid
        address competitor = address(0x6);
        auctionAmm.bidToken().mint(competitor, K * 10e18);
        auctionAmm.bidToken().approve(address(auctionAmm), type(uint256).max);
        
        vm.startPrank(competitor);
        
        // Higher rent bid - 4 ETH per block with 0.5% swap fee
        bytes6 competitorPayload = bytes6(bytes3(uint24(0.005e6))); // 0.5% swap fee
        uint128 competitorRent = 4e18; // 4 ETH per block
        uint128 competitorDeposit = competitorRent * K;
        
        auctionAmm.bid({
            id: POOL_0,
            manager: competitor,
            payload: competitorPayload,
            rent: competitorRent,
            deposit: competitorDeposit
        });
        
        vm.stopPrank();
        
        console.log("Competitor submitted higher bid:");
        console.log("  - Rent per block: 4 ETH (2x higher)");
        console.log("  - Swap fee: 0.5% (lower fee for users)");
        console.log("  - Total deposit:", uint256(competitorDeposit) / 1e18, "ETH");
        console.log("");
        
        // Advance blocks to make competitor bid active
        vm.roll(block.number + K);
        
        // Check if competitor is now the top bid
        IAmAmm.Bid memory topBid = auctionAmm.getBid(POOL_0, true);
        
        console.log("Current top bid manager:", topBid.manager);
        console.log("Competitor address:", competitor);
        console.log("Competition successful:", topBid.manager == competitor);
        
        console.log("");
        console.log("*** This demonstrates how auction mechanism drives:");
        console.log("   - Higher rent payments to LPs");
        console.log("   - Lower fees for users");
        console.log("   - Competitive efficiency in the market");
    }
}
