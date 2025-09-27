// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PoolId} from "../../lib/v4-core/src/types/PoolId.sol";
import {Currency} from "../../lib/v4-core/src/types/Currency.sol";

interface IAmAmm {
    error AmAmm__BidLocked();
    error AmAmm__InvalidBid();
    error AmAmm__NotEnabled();
    error AmAmm__Unauthorized();
    error AmAmm__InvalidDepositAmount();

    event SubmitBid(
        PoolId indexed id,
        address indexed manager,
        uint48 indexed blockIdx,
        bytes6 payload,
        uint128 rent,
        uint128 deposit
    );
    event DepositIntoTopBid(
        PoolId indexed id,
        address indexed manager,
        uint128 amount
    );
    event WithdrawFromTopBid(
        PoolId indexed id,
        address indexed manager,
        address indexed recipient,
        uint128 amount
    );
    event DepositIntoNextBid(
        PoolId indexed id,
        address indexed manager,
        uint128 amount
    );
    event WithdrawFromNextBid(
        PoolId indexed id,
        address indexed manager,
        address indexed recipient,
        uint128 amount
    );
    event ClaimRefund(
        PoolId indexed id,
        address indexed manager,
        address indexed recipient,
        uint256 refund
    );
    event ClaimFees(
        Currency indexed currency,
        address indexed manager,
        address indexed recipient,
        uint256 fees
    );
    event SetBidPayload(
        PoolId indexed id,
        address indexed manager,
        bytes6 payload,
        bool topBid
    );
    event IncreaseBidRent(
        PoolId indexed id,
        address indexed manager,
        uint128 additionalRent,
        uint128 updatedDeposit,
        bool topBid,
        address indexed withdrawRecipient,
        uint128 amountDeposited,
        uint128 amountWithdrawn
    );

    struct Bid {
        address manager;
        uint48 blockIdx;
        bytes6 payload; 
        uint128 rent;
        uint128 deposit;
    }

    function bid(
        PoolId id,
        address manager,
        bytes6 payload,
        uint128 rent,
        uint128 deposit
    ) external;

    function depositIntoBid(PoolId id, uint128 amount, bool isTopBid) external;

    function withdrawFromBid(
        PoolId id,
        uint128 amount,
        address recipient,
        bool isTopBid
    ) external;

    function claimRefund(
        PoolId id,
        address recipient
    ) external returns (uint256 refund);

    function claimFees(
        Currency currency,
        address recipient
    ) external returns (uint256 fees);

    function increaseBidRent(
        PoolId id,
        uint128 additionalRent,
        uint128 updatedDeposit,
        bool isTopBid,
        address withdrawRecipient
    ) external returns (uint128 amountDeposited, uint128 amountWithdrawn);

    function setBidPayload(PoolId id, bytes6 payload, bool isTopBid) external;

    function getBid(
        PoolId id,
        bool isTopBid
    ) external view returns (Bid memory);

    function getBidWrite(
        PoolId id,
        bool isTopBid
    ) external returns (Bid memory);

    function getRefund(
        address manager,
        PoolId id
    ) external view returns (uint256);

    function getRefundWrite(
        address manager,
        PoolId id
    ) external returns (uint256);

    function getFees(
        address manager,
        Currency currency
    ) external view returns (uint256);

    function updateStateMachine(PoolId id) external;
}
