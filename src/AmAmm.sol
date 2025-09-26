// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {PoolId} from "../lib/v4-core/src/types/PoolId.sol";
import {Currency} from "../lib/v4-core/src/types/Currency.sol";

abstract contract AmAmm {
    using SafeCastLib for *;
    using FixedPointMathLib for *;

    uint48 constant K = 7200;
    uint256 constant MIN_BID_MULTIPLIER = 1e18;
    uint128 constant MIN_RENT = 0;
    uint256 immutable deploymentBlockNumber;

    mapping(PoolId id => Bid) internal _topBids;
    mapping(PoolId id => Bid) internal _nextBids;
    mapping(PoolId id => uint48) internal _lastUpdatedBlockIdx;
    mapping(Currency currency => uint256) internal _totalFees;
    mapping(address manager => mapping(PoolId id => uint256)) internal _refunds;
    mapping(address manager => mapping(Currency currency => uint256))
        internal _fees;

    modifier onlyAmAmmEnabled(PoolId id) {
        if (!_amAmmEnabled(id)) {
            revert AmAmm__NotEnabled();
        }
        _;
    }

    function _amAmmEnabled(PoolId id) internal view virtual returns (bool);
}
