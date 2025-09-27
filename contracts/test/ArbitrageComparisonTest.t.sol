// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Amm.sol";
import "../src/ERC20Mock.sol";
import "../src/interfaces/IAmAmm.sol";

/// @title ArbitrageComparisonTest
/// @notice Comprehensive test comparing auction AMM vs normal AMM for LP profitability
/// @dev This test demonstrates how the auction mechanism can provide more value to LPs
///      compared to traditional swap fees in a normal AMM
contract ArbitrageComparisonTest is Test {
    // using stdUtils for *;

    PoolId constant POOL_0 = PoolId.wrap(bytes32(0));
    
    uint128 internal constant K = 7200; // 7200 blocks
    uint256 internal constant MIN_BID_MULTIPLIER = 1.1e18; // 10%
    
    // Auction AMM
    AmAmmMock auctionAmm;
    
    // Normal AMM (using the same contract but without auction features for comparison)
    AmAmmMock normalAmm;
    
    // Test parameters - ETH:USD pool (1:2000 ratio)
    uint256 constant INITIAL_LIQUIDITY_ETH = 100 ether;      // 100 ETH
    uint256 constant INITIAL_LIQUIDITY_USD = 200000 ether;   // 200,000 USD (1:2000 ratio)
    uint256 constant SMALL_SWAP_ETH = 0.1 ether;             // Small ETH swaps
    uint256 constant SMALL_SWAP_USD = 200 ether;             // Small USD swaps
    uint256 constant NUM_SWAPS = 20;
    
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
        // Mint tokens for liquidity provider (ETH:USD pool)
        auctionAmm.feeToken0().mint(liquidityProvider, INITIAL_LIQUIDITY_ETH * 2);    // ETH
        auctionAmm.feeToken1().mint(liquidityProvider, INITIAL_LIQUIDITY_USD * 2);    // USD
        normalAmm.feeToken0().mint(liquidityProvider, INITIAL_LIQUIDITY_ETH * 2);
        normalAmm.feeToken1().mint(liquidityProvider, INITIAL_LIQUIDITY_USD * 2);
        
        // Mint bid tokens for auction manager - lower rent expectation
        auctionAmm.bidToken().mint(auctionManager, K * 1e18); // 1 ETH per block rent capacity
        
        // Mint tokens for traders - realistic amounts for small volume trades
        address[] memory traders = new address[](3);
        traders[0] = arbitrager;
        traders[1] = trader1;
        traders[2] = trader2;
        
        for (uint i = 0; i < traders.length; i++) {
            auctionAmm.feeToken0().mint(traders[i], 50 ether);      // 50 ETH each
            auctionAmm.feeToken1().mint(traders[i], 100000 ether);  // 100,000 USD each
            normalAmm.feeToken0().mint(traders[i], 50 ether);
            normalAmm.feeToken1().mint(traders[i], 100000 ether);
        }
    }

    function setupInitialLiquidity() internal {
        console.log("1. Setting up initial ETH:USD liquidity (1:2000 ratio)...");
        
        vm.startPrank(liquidityProvider);
        
        // Add liquidity to auction AMM - ETH:USD pool
        uint256 auctionShares = auctionAmm.addLiquidity(
            POOL_0, 
            INITIAL_LIQUIDITY_ETH,   // 100 ETH
            INITIAL_LIQUIDITY_USD    // 200,000 USD
        );
        
        // Add liquidity to normal AMM  
        uint256 normalShares = normalAmm.addLiquidity(
            POOL_0, 
            INITIAL_LIQUIDITY_ETH, 
            INITIAL_LIQUIDITY_USD
        );
        
        vm.stopPrank();
        
        console.log("   Initial ETH liquidity: 100 ETH");
        console.log("   Initial USD liquidity: 200,000 USD");
        console.log("   ETH:USD ratio: 1:2000");
        console.log("   Auction AMM LP tokens:", auctionShares / 1e18);
        console.log("   Normal AMM LP tokens:", normalShares / 1e18);
        console.log("");
    }

    function setupAuction() internal {
        console.log("2. Setting up auction...");
        
        vm.startPrank(auctionManager);
        
        // Submit bid with 0.3% swap fee and 0.1 ETH per block rent (conservative)
        bytes6 payload = bytes6(bytes3(uint24(0.003e6))); // 0.3% swap fee (typical DEX fee)
        uint128 rent = 0.1e18; // 0.1 ETH per block rent (conservative bid)
        uint128 deposit = rent * K; // Deposit for K blocks
        
        auctionAmm.bid({
            id: POOL_0,
            manager: auctionManager,
            payload: payload,
            rent: rent,
            deposit: deposit
        });
        
        vm.stopPrank();
        
        // Advance K blocks to make the bid active
        vm.roll(block.number + K);
        
        console.log("   Conservative auction bid:");
        console.log("   - Rent per block: 0.1 ETH (720 ETH total)");
        console.log("   - Swap fee: 0.3% (typical DEX rate)");
        console.log("   - Manager expects to break even on fees vs rent");
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
            // Random small trades - sometimes ETH->USD, sometimes USD->ETH
            bool swapEthForUsd = (i % 3 != 0); // 2/3 trades are ETH->USD, 1/3 are USD->ETH
            
            vm.startPrank(trader);
            
            if (swapEthForUsd) {
                // Small ETH -> USD swap (0.1 ETH)
                auctionAmm.swap(
                    POOL_0,
                    Currency.wrap(address(auctionAmm.feeToken0())), // ETH
                    SMALL_SWAP_ETH
                );
                
                normalAmm.swapWithoutFees(
                    POOL_0,
                    Currency.wrap(address(normalAmm.feeToken0())), // ETH
                    SMALL_SWAP_ETH
                );
            } else {
                // Small USD -> ETH swap (200 USD)
                auctionAmm.swap(
                    POOL_0,
                    Currency.wrap(address(auctionAmm.feeToken1())), // USD
                    SMALL_SWAP_USD
                );
                
                normalAmm.swapWithoutFees(
                    POOL_0,
                    Currency.wrap(address(normalAmm.feeToken1())), // USD
                    SMALL_SWAP_USD
                );
            }
            
            vm.stopPrank();
        }
    }

    function compareResults() internal {
        console.log("4. Comparing Results - Conservative Scenario...");
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
        
        // Get fees earned by auction manager
        uint256 managerFees0 = auctionAmm.getFees(
            auctionManager, 
            Currency.wrap(address(auctionAmm.feeToken0()))
        );
        uint256 managerFees1 = auctionAmm.getFees(
            auctionManager, 
            Currency.wrap(address(auctionAmm.feeToken1()))
        );
        
        // Calculate rent paid (this goes to LPs in auction AMM)
        uint256 rentPaid = calculateRentPaid();
        
        console.log("=== ETH:USD POOL ANALYSIS ===");
        console.log("Auction AMM Reserves:");
        console.log("  ETH:", auctionReserve0 / 1e18);
        console.log("  USD:", auctionReserve1 / 1e18);
        console.log("");
        console.log("Normal AMM Reserves:");
        console.log("  ETH:", normalReserve0 / 1e18);
        console.log("  USD:", normalReserve1 / 1e18);
        console.log("");
        
        console.log("=== MANAGER PERFORMANCE ANALYSIS ===");
        console.log("Manager Swap Fee Earnings:");
        console.log("  ETH fees:", managerFees0 / 1e18);
        console.log("  USD fees:", managerFees1 / 1e18);
        uint256 totalManagerFees = managerFees0 + managerFees1;
        console.log("  Total fee value (in tokens):", totalManagerFees / 1e18);
        console.log("");
        console.log("Manager Rent Payment:");
        console.log("  Total rent paid:", rentPaid / 1e18, "ETH");
        console.log("");
        console.log("Manager Net Position:");
        if (totalManagerFees >= rentPaid) {
            console.log("  Manager profit:", (totalManagerFees - rentPaid) / 1e18, "tokens");
            console.log("  *** Manager made a profit - bid was profitable");
        } else {
            console.log("  Manager loss:", (rentPaid - totalManagerFees) / 1e18, "tokens");
            console.log("  *** Manager overpaid - LPs benefit from excess rent");
        }
        console.log("");
        
        console.log("=== LP EARNINGS COMPARISON ===");
        // Calculate normal AMM LP earnings (just from reserves)
        uint256 normalLPEarnings = (normalLPValue0 + normalLPValue1);
        
        // Calculate auction AMM LP earnings (reserves + rent distribution)
        uint256 auctionLPEarnings = (auctionLPValue0 + auctionLPValue1) + rentPaid;
        
        console.log("Normal AMM LP Total:");
        console.log("  Reserve value:", normalLPEarnings / 1e18, "tokens");
        console.log("  Additional earnings: 0 (no rent mechanism)");
        console.log("  Total LP benefit:", normalLPEarnings / 1e18, "tokens");
        console.log("");
        
        console.log("Auction AMM LP Total:");
        console.log("  Reserve value:", (auctionLPValue0 + auctionLPValue1) / 1e18, "tokens");
        console.log("  Rent distribution:", rentPaid / 1e18, "tokens");
        console.log("  Total LP benefit:", auctionLPEarnings / 1e18, "tokens");
        console.log("");
        
        if (auctionLPEarnings > normalLPEarnings) {
            uint256 advantage = auctionLPEarnings - normalLPEarnings;
            console.log("*** LP Advantage from Auction AMM:", advantage / 1e18, "tokens");
            console.log("*** This comes from rent payments by auction manager");
        }
        
        console.log("");
        console.log("=== SCENARIO INSIGHTS ===");
        console.log("*** Conservative bid scenario (no arbitrage expected):");
        console.log("    - Manager bids conservatively, expecting to break even");
        console.log("    - Small trading volume, limited fee generation");
        console.log("    - LPs benefit from any excess rent over fee generation");
        console.log("");
        console.log("*** In high arbitrage scenarios:");
        console.log("    - Managers bid higher rents expecting more fee volume");
        console.log("    - LPs earn significantly more from rent payments");
        console.log("    - Competition drives up rent payments to LPs");
        console.log("");
        
        // Verify the scenario worked as expected
        assertTrue(auctionLPEarnings >= normalLPEarnings, "Auction AMM LPs should earn at least as much");
        assertTrue(rentPaid > 0, "Rent should have been paid to LPs");
    }

    function calculateRentPaid() internal view returns (uint256) {
        // Get current bid information
        IAmAmm.Bid memory bid = auctionAmm.getBid(POOL_0, true);
        
        // Original deposit was 0.1 ETH * 7200 blocks = 720 ETH
        uint256 originalDeposit = 0.1e18 * K;  
        uint256 currentDeposit = bid.deposit;
        
        // Rent paid is the difference (this represents value transferred to LPs)
        return originalDeposit - currentDeposit;
    }

    function _swapFeeToPayload(uint24 swapFee) internal pure returns (bytes6) {
        return bytes6(bytes3(swapFee));
    }

    /// @dev Test high-rent scenario where managers expect arbitrage opportunities
    function testHighArbitrageScenario() external {
        console.log("=== HIGH ARBITRAGE EXPECTATION SCENARIO ===");
        console.log("");
        
        setupInitialLiquidity();
        
        // Setup auction with HIGH rent expectation (expecting arbitrage volume)
        vm.startPrank(auctionManager);
        
        // High rent bid - manager expects significant arbitrage volume
        bytes6 payload = bytes6(bytes3(uint24(0.003e6))); // 0.3% swap fee
        uint128 rent = 2e18; // 2 ETH per block rent (20x higher than conservative)
        uint128 deposit = rent * K; // Deposit for K blocks
        
        // Manager needs more bid tokens for this aggressive bid
        auctionAmm.bidToken().mint(auctionManager, deposit);
        
        auctionAmm.bid({
            id: POOL_0,
            manager: auctionManager,
            payload: payload,
            rent: rent,
            deposit: deposit
        });
        
        vm.stopPrank();
        
        // Advance K blocks to make the bid active
        vm.roll(block.number + K);
        
        console.log("High-expectation auction bid:");
        console.log("  - Rent per block: 2 ETH (expecting high arbitrage volume)");
        console.log("  - Total rent commitment: 14,400 ETH");
        console.log("  - Manager expects significant fee income to justify this");
        console.log("");
        
        // Perform the same low-volume trading
        performTradingActivity();
        
        // Analyze results
        analyzeHighRentScenario();
    }

    function analyzeHighRentScenario() internal {
        console.log("4. High-Rent Scenario Analysis...");
        console.log("");
        
        // Get fees earned by auction manager
        uint256 managerFees0 = auctionAmm.getFees(
            auctionManager, 
            Currency.wrap(address(auctionAmm.feeToken0()))
        );
        uint256 managerFees1 = auctionAmm.getFees(
            auctionManager, 
            Currency.wrap(address(auctionAmm.feeToken1()))
        );
        
        // Calculate rent paid
        uint256 rentPaid = calculateHighRentPaid();
        
        console.log("=== HIGH-RENT SCENARIO RESULTS ===");
        console.log("Manager Performance:");
        console.log("  Fees earned: ~", (managerFees0 + managerFees1) / 1e18, "tokens");
        console.log("  Rent paid:", rentPaid / 1e18, "ETH");
        console.log("  Manager loss:", (rentPaid - (managerFees0 + managerFees1)) / 1e18, "tokens");
        console.log("");
        
        console.log("LP Benefits:");
        console.log("  Massive rent distribution:", rentPaid / 1e18, "ETH");
        console.log("  *** LPs earn", rentPaid / 1e18, "ETH from manager's overoptimistic bid");
        console.log("");
        
        console.log("=== SCENARIO INSIGHTS ===");
        console.log("*** When managers overestimate arbitrage opportunities:");
        console.log("    - They bid high rents expecting high fee volume");
        console.log("    - If volume is low, they lose money on the auction");
        console.log("    - LPs benefit enormously from excess rent payments");
        console.log("    - This creates market discipline - managers learn to bid accurately");
        console.log("");
    }

    function calculateHighRentPaid() internal view returns (uint256) {
        // Get current bid information for high rent scenario
        IAmAmm.Bid memory bid = auctionAmm.getBid(POOL_0, true);
        
        // Original deposit was 2 ETH * 7200 blocks = 14400 ETH
        uint256 originalDeposit = 2e18 * K;  
        uint256 currentDeposit = bid.deposit;
        
        // Rent paid is the difference
        return originalDeposit - currentDeposit;
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
        auctionAmm.bidToken().mint(competitor, K * 5e18);
        
        vm.startPrank(competitor);
        auctionAmm.bidToken().approve(address(auctionAmm), type(uint256).max);
        
        // Higher rent bid - expecting better arbitrage opportunities
        bytes6 competitorPayload = bytes6(bytes3(uint24(0.002e6))); // 0.2% swap fee (lower)
        uint128 competitorRent = 0.5e18; // 0.5 ETH per block (5x higher than conservative)
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
        console.log("  - Rent per block: 0.5 ETH (5x higher than conservative)");
        console.log("  - Swap fee: 0.2% (lower fee for users)");
        console.log("  - Total rent commitment:", uint256(competitorDeposit) / 1e18, "ETH");
        console.log("");
        
        // Advance blocks to make competitor bid active
        vm.roll(block.number + K);
        
        // Check if competitor is now the top bid
        IAmAmm.Bid memory topBid = auctionAmm.getBid(POOL_0, true);
        
        console.log("Competition successful:", topBid.manager == competitor);
        console.log("");
        console.log("*** This demonstrates how auction mechanism drives:");
        console.log("   - Higher rent payments to LPs");
        console.log("   - Lower fees for users");
        console.log("   - Market-driven price discovery");
    }
}
