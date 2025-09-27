//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract BidToken is ERC20 {
    constructor() ERC20("Bid Token", "BT") {
        _mint(msg.sender, 100e18);
    }
}

contract FeeToken is ERC20 {
    constructor() ERC20("Fee Token", "FT") {
        _mint(msg.sender, 100e18);
    }
}
