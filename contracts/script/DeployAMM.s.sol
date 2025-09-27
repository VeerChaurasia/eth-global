// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Amm.sol";
import "../src/ERC20Mock.sol";

contract DeployAmm is Script {
    function run() external returns (AmAmmMock) {
        vm.startBroadcast();
        
        ERC20Mock bidToken = new ERC20Mock();
        ERC20Mock feeToken0 = new ERC20Mock();
        ERC20Mock feeToken1 = new ERC20Mock();
        
        AmAmmMock amm = new AmAmmMock(bidToken, feeToken0, feeToken1);
        
        vm.stopBroadcast();
        
        return amm;
    }
}
