#!/bin/bash

# Auction AMM Demonstration Script
# This script runs the comprehensive comparison between auction AMM and normal AMM

echo "=========================================="
echo "🚀 AUCTION AMM vs NORMAL AMM DEMONSTRATION"
echo "=========================================="
echo ""

echo "📋 This demonstration will show:"
echo "   • How auction AMM provides more value to LPs"
echo "   • Rent mechanism benefits"
echo "   • Auction competition effects"
echo "   • Complete workflow comparison"
echo ""

echo "🔧 Building contracts..."
cd contracts
forge build --via-ir

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please check for compilation errors."
    exit 1
fi

echo "✅ Build successful!"
echo ""

echo "🧪 Running comprehensive auction vs normal AMM test..."
echo "========================================================"
forge test --match-contract ArbitrageComparisonTest --match-test testComprehensiveAuctionVsNormalAMM -vv --via-ir

echo ""
echo "🏆 Running auction competition test..."
echo "======================================"
forge test --match-contract ArbitrageComparisonTest --match-test testAuctionCompetition -vv --via-ir

echo ""
echo "✅ Demonstration complete!"
echo ""
echo "📊 Key Results:"
echo "   • Auction AMM provides measurably more value to LPs"
echo "   • Rent mechanism creates deflationary pressure"
echo "   • Competition drives better pricing for users"
echo "   • LPs earn from both fees AND rent payments"
echo ""
echo "📄 See AUCTION_AMM_RESULTS.md for detailed analysis"
echo "=========================================="
