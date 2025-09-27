//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Amm} from "../src/Amm.sol";
import {ERC20Mock} from "./mocks/ERC20.sol";

contract DeployAmm is Script {
    function run()
        external
        returns (Amm amm1, Amm amm2, ERC20Mock token0, ERC20Mock token1)
    {
        vm.startBroadcast();
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();
        ERC20Mock feeToken = new ERC20Mock();
        ERC20Mock bidToken = new ERC20Mock();
        amm1 = new Amm(
            address(token0),
            address(token1),
            address(bidToken),
            address(feeToken)
        );
        amm2 = new Amm(
            address(token0),
            address(token1),
            address(bidToken),
            address(feeToken)
        );
        vm.stopBroadcast();
    }
}
