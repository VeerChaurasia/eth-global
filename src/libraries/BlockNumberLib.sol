// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ArbSys {
    function arbBlockNumber() external view returns (uint256);
}

library BlockNumberLib {
    uint256 private constant ARBITRUM_ONE_ID = 42161;
    ArbSys private constant ARB_SYS = ArbSys(address(100));

    function getBlockNumber() internal view returns (uint256) {
        return
            block.chainid == ARBITRUM_ONE_ID
                ? ARB_SYS.arbBlockNumber()
                : block.number;
    }
}
