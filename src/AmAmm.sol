// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {SafeCastLib} from "solady/utils/SafeCastLib.sol";
import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";
import {PoolId} from "../lib/v4-core/src/types/PoolId.sol";
import {Currency} from "../lib/v4-core/src/types/Currency.sol";
import {IAmAmm} from "./interfaces/IAmAmm.sol";
import {BlockNumberLib} from "./libraries/BlockNumberLib.sol";
import {LibMulticaller} from "multicaller/LibMulticaller.sol";

abstract contract AmAmm is IAmAmm {
    using SafeCastLib for *;
    using FixedPointMathLib for *;

    uint48 constant public K = 7200;
    uint256 constant public MIN_BID_MULTIPLIER = 1e18;
    uint128 constant public MIN_RENT = 0;
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

    constructor() {
        deploymentBlockNumber = BlockNumberLib.getBlockNumber();
    }

    function _amAmmEnabled(PoolId id) internal view virtual returns (bool);

    function _payloadIsValid(
        PoolId id,
        bytes6 payload
    ) internal view virtual returns (bool);

    function _burnBidToken(PoolId id, uint256 amount) internal virtual;

    function _pullBidToken(
        PoolId id,
        address from,
        uint256 amount
    ) internal virtual;

    function _pushBidToken(
        PoolId id,
        address to,
        uint256 amount
    ) internal virtual;

    function _transferFeeToken(
        Currency currency,
        address to,
        uint256 amount
    ) internal virtual;

    function bid(
        PoolId id,
        address manager,
        bytes6 payload,
        uint128 rent,
        uint128 deposit
    ) public virtual override onlyAmAmmEnabled(id) {
        address msgSender = LibMulticaller.senderOrSigner();

        _updateAmAmmWrite(id);

        if (
            manager == address(0) ||
            rent <= _nextBids[id].rent.mulWad(MIN_BID_MULTIPLIER) ||
            deposit < rent * K ||
            deposit % rent != 0 ||
            !_payloadIsValid(id, payload) ||
            rent < MIN_RENT
        ) {
            revert AmAmm__InvalidBid();
        }

        _refunds[_nextBids[id].manager][id] += _nextBids[id].deposit;

        uint48 blockIdx = uint48(
            BlockNumberLib.getBlockNumber() - deploymentBlockNumber
        );
        _nextBids[id] = Bid(manager, blockIdx, payload, rent, deposit);

        _pullBidToken(id, msgSender, deposit);

        emit SubmitBid(id, manager, blockIdx, payload, rent, deposit);
    }

    function depositIntoBid(
        PoolId id,
        uint128 amount,
        bool isTopBid
    ) public virtual override onlyAmAmmEnabled(id) {
        address msgSender = LibMulticaller.senderOrSigner();

        _updateAmAmmWrite(id);

        Bid storage bidStorage = isTopBid ? _topBids[id] : _nextBids[id];
        Bid memory bidMemory = bidStorage;

        if (msgSender != bidMemory.manager) {
            revert AmAmm__Unauthorized();
        }

        if (amount % bidMemory.rent != 0) {
            revert AmAmm__InvalidDepositAmount();
        }

        bidStorage.deposit = bidMemory.deposit + amount;

        _pullBidToken(id, msgSender, amount);

        if (isTopBid) {
            emit DepositIntoTopBid(id, msgSender, amount);
        } else {
            emit DepositIntoNextBid(id, msgSender, amount);
        }
    }

    function withdrawFromBid(
        PoolId id,
        uint128 amount,
        address recipient,
        bool isTopBid
    ) public virtual override onlyAmAmmEnabled(id) {
        address msgSender = LibMulticaller.senderOrSigner();
        _updateAmAmmWrite(id);

        Bid storage bidStorage = isTopBid ? _topBids[id] : _nextBids[id];
        Bid memory bidMemory = bidStorage;

        if (msgSender != bidMemory.manager) {
            revert AmAmm__Unauthorized();
        }

        if (amount % bidMemory.rent != 0) {
            revert AmAmm__InvalidDepositAmount();
        }

        if ((bidMemory.deposit - amount) / bidMemory.rent < K) {
            revert AmAmm__BidLocked();
        }

        bidStorage.deposit = bidMemory.deposit - amount;

        _pushBidToken(id, recipient, amount);

        if (isTopBid) {
            emit WithdrawFromTopBid(id, msgSender, recipient, amount);
        } else {
            emit WithdrawFromNextBid(id, msgSender, recipient, amount);
        }
    }

    function claimRefund(
        PoolId id,
        address recipient
    ) public virtual override onlyAmAmmEnabled(id) returns (uint256 refund) {
        address msgSender = LibMulticaller.senderOrSigner();
        _updateAmAmmWrite(id);

        refund = _refunds[msgSender][id];
        if (refund == 0) {
            return 0;
        }
        delete _refunds[msgSender][id];

        _pushBidToken(id, recipient, refund);

        emit ClaimRefund(id, msgSender, recipient, refund);
    }

    function claimFees(
        Currency currency,
        address recipient
    ) public virtual override returns (uint256 fees) {
        address msgSender = LibMulticaller.senderOrSigner();

        fees = _fees[msgSender][currency];
        if (fees == 0) {
            return 0;
        }
        delete _fees[msgSender][currency];

        unchecked {
            _totalFees[currency] -= fees;
        }

        _transferFeeToken(currency, recipient, fees);

        emit ClaimFees(currency, msgSender, recipient, fees);
    }

    function increaseBidRent(
        PoolId id,
        uint128 additionalRent,
        uint128 updatedDeposit,
        bool isTopBid,
        address withdrawRecipient
    )
        public
        virtual
        override
        onlyAmAmmEnabled(id)
        returns (uint128 amountDeposited, uint128 amountWithdrawn)
    {
        address msgSender = LibMulticaller.senderOrSigner();

        if (additionalRent == 0) return (0, 0);

        _updateAmAmmWrite(id);

        Bid storage relevantBidStorage = isTopBid
            ? _topBids[id]
            : _nextBids[id];
        Bid memory relevantBid = relevantBidStorage;

        if (msgSender != relevantBid.manager) {
            revert AmAmm__Unauthorized();
        }

        uint128 newRent = relevantBid.rent + additionalRent;

        if (updatedDeposit % newRent != 0 || newRent < MIN_RENT) {
            revert AmAmm__InvalidBid();
        }

        if (updatedDeposit / newRent < K) {
            revert AmAmm__BidLocked();
        }

        relevantBidStorage.rent = newRent;
        relevantBidStorage.deposit = updatedDeposit;

        unchecked {
            if (updatedDeposit > relevantBid.deposit) {
                amountDeposited = updatedDeposit - relevantBid.deposit;
                _pullBidToken(id, msgSender, amountDeposited);
            } else if (updatedDeposit < relevantBid.deposit) {
                amountWithdrawn = relevantBid.deposit - updatedDeposit;
                _pushBidToken(id, withdrawRecipient, amountWithdrawn);
            }
        }

        emit IncreaseBidRent(
            id,
            msgSender,
            additionalRent,
            updatedDeposit,
            isTopBid,
            withdrawRecipient,
            amountDeposited,
            amountWithdrawn
        );
    }

    function setBidPayload(
        PoolId id,
        bytes6 payload,
        bool isTopBid
    ) public virtual override onlyAmAmmEnabled(id) {
        address msgSender = LibMulticaller.senderOrSigner();

        _updateAmAmmWrite(id);

        Bid storage relevantBid = isTopBid ? _topBids[id] : _nextBids[id];

        if (msgSender != relevantBid.manager) {
            revert AmAmm__Unauthorized();
        }

        if (!_payloadIsValid(id, payload)) {
            revert AmAmm__InvalidBid();
        }

        relevantBid.payload = payload;

        emit SetBidPayload(id, msgSender, payload, isTopBid);
    }

    function updateStateMachine(PoolId id) external override {
        _updateAmAmmWrite(id);
    }

    function getBid(
        PoolId id,
        bool isTopBid
    ) external view override returns (Bid memory) {
        (Bid memory topBid, Bid memory nextBid) = _updateAmAmmView(id);
        return isTopBid ? topBid : nextBid;
    }

    function getBidWrite(
        PoolId id,
        bool isTopBid
    ) external override returns (Bid memory) {
        _updateAmAmmWrite(id);
        return isTopBid ? _topBids[id] : _nextBids[id];
    }

    function getRefund(
        address manager,
        PoolId id
    ) external view override returns (uint256) {
        return _refunds[manager][id];
    }

    function getRefundWrite(
        address manager,
        PoolId id
    ) external override returns (uint256) {
        _updateAmAmmWrite(id);
        return _refunds[manager][id];
    }

    function getFees(
        address manager,
        Currency currency
    ) external view override returns (uint256) {
        return _fees[manager][currency];
    }

    function _accrueFees(
        address manager,
        Currency currency,
        uint256 amount
    ) internal virtual {
        _fees[manager][currency] += amount;
        _totalFees[currency] += amount;
    }

    function _checkAmAmmEnabled(PoolId id) internal view {
        if (!_amAmmEnabled(id)) {
            revert AmAmm__NotEnabled();
        }
    }

    function _updateAmAmmWrite(PoolId id) internal virtual {
        uint48 currentBlockIdx = uint48(
            BlockNumberLib.getBlockNumber() - deploymentBlockNumber
        );

        if (_lastUpdatedBlockIdx[id] == currentBlockIdx) {
            return;
        }

        Bid memory topBid = _topBids[id];
        Bid memory nextBid = _nextBids[id];
        bool updatedTopBid;
        bool updatedNextBid;
        uint256 rentCharged;

        {
            bool stepHasUpdatedTopBid;
            bool stepHasUpdatedNextBid;
            uint256 stepRentCharged;
            address stepRefundManager;
            uint256 stepRefundAmount;
            while (true) {
                (
                    topBid,
                    nextBid,
                    stepHasUpdatedTopBid,
                    stepHasUpdatedNextBid,
                    stepRentCharged,
                    stepRefundManager,
                    stepRefundAmount
                ) = _stateTransition(currentBlockIdx, id, topBid, nextBid);

                if (!stepHasUpdatedTopBid && !stepHasUpdatedNextBid) {
                    break;
                }

                updatedTopBid = updatedTopBid || stepHasUpdatedTopBid;
                updatedNextBid = updatedNextBid || stepHasUpdatedNextBid;
                rentCharged += stepRentCharged;
                if (stepRefundManager != address(0)) {
                    _refunds[stepRefundManager][id] += stepRefundAmount;
                }
            }
        }

        if (updatedTopBid) {
            _topBids[id] = topBid;
        }
        if (updatedNextBid) {
            _nextBids[id] = nextBid;
        }

        _lastUpdatedBlockIdx[id] = currentBlockIdx;

        if (rentCharged != 0) {
            _burnBidToken(id, rentCharged);
        }
    }

    function _updateAmAmmView(
        PoolId id
    ) internal view virtual returns (Bid memory topBid, Bid memory nextBid) {
        uint48 currentBlockIdx = uint48(
            BlockNumberLib.getBlockNumber() - deploymentBlockNumber
        );

        topBid = _topBids[id];
        nextBid = _nextBids[id];

        if (_lastUpdatedBlockIdx[id] == currentBlockIdx) {
            return (topBid, nextBid);
        }

        {
            bool stepHasUpdatedTopBid;
            bool stepHasUpdatedNextBid;
            while (true) {
                (
                    topBid,
                    nextBid,
                    stepHasUpdatedTopBid,
                    stepHasUpdatedNextBid,
                    ,
                    ,

                ) = _stateTransition(currentBlockIdx, id, topBid, nextBid);

                if (!stepHasUpdatedTopBid && !stepHasUpdatedNextBid) {
                    break;
                }
            }
        }
    }

    function _stateTransition(
        uint48 currentBlockIdx,
        PoolId id,
        Bid memory topBid,
        Bid memory nextBid
    )
        internal
        view
        virtual
        returns (
            Bid memory,
            Bid memory,
            bool updatedTopBid,
            bool updatedNextBid,
            uint256 rentCharged,
            address refundManager,
            uint256 refundAmount
        )
    {
        uint48 k = K;
        if (nextBid.manager == address(0)) {
            if (topBid.manager != address(0)) {
                uint48 blocksPassed;
                unchecked {
                    blocksPassed = currentBlockIdx - topBid.blockIdx;
                }
                uint256 rentOwed = blocksPassed * topBid.rent;
                if (rentOwed >= topBid.deposit) {
                    rentCharged = topBid.deposit;

                    topBid = Bid(address(0), 0, 0, 0, 0);

                    updatedTopBid = true;
                } else if (rentOwed != 0) {
                    rentCharged = rentOwed;

                    topBid.deposit -= rentOwed.toUint128();
                    topBid.blockIdx = currentBlockIdx;

                    updatedTopBid = true;
                }
            }
        } else {
            if (topBid.manager == address(0)) {
                uint48 nextBidStartBlockIdx;
                unchecked {
                    nextBidStartBlockIdx = nextBid.blockIdx + k;
                }
                if (currentBlockIdx >= nextBidStartBlockIdx) {
                    topBid = nextBid;
                    topBid.blockIdx = nextBidStartBlockIdx;
                    nextBid = Bid(address(0), 0, 0, 0, 0);

                    updatedTopBid = true;
                    updatedNextBid = true;
                }
            } else {
                bool nextBidIsBetter = nextBid.rent >
                    topBid.rent.mulWad(MIN_BID_MULTIPLIER);
                uint48 blocksPassed;
                unchecked {
                    blocksPassed = nextBidIsBetter
                        ? uint48(
                            FixedPointMathLib.min(
                                currentBlockIdx - topBid.blockIdx,
                                nextBid.blockIdx + k - topBid.blockIdx
                            )
                        )
                        : currentBlockIdx - topBid.blockIdx;
                }
                uint256 rentOwed = blocksPassed * topBid.rent;
                if (rentOwed >= topBid.deposit) {
                    rentCharged = topBid.deposit;

                    topBid = Bid(address(0), 0, 0, 0, 0);
                    unchecked {
                        uint48 latestProcessedBlockIdx = nextBidIsBetter
                            ? uint48(
                                FixedPointMathLib.min(
                                    currentBlockIdx,
                                    nextBid.blockIdx + k
                                )
                            )
                            : currentBlockIdx;
                        nextBid.blockIdx = uint48(
                            FixedPointMathLib.max(
                                nextBid.blockIdx,
                                latestProcessedBlockIdx - k
                            )
                        );
                    }

                    updatedTopBid = true;
                    updatedNextBid = true;
                } else {
                    if (rentOwed != 0) {
                        rentCharged = rentOwed;

                        topBid.deposit -= rentOwed.toUint128();
                        topBid.blockIdx = currentBlockIdx;

                        updatedTopBid = true;
                    }

                    uint48 nextBidStartBlockIdx;
                    unchecked {
                        nextBidStartBlockIdx = nextBid.blockIdx + k;
                    }
                    if (
                        currentBlockIdx >= nextBidStartBlockIdx &&
                        nextBidIsBetter
                    ) {
                        (refundManager, refundAmount) = (
                            topBid.manager,
                            topBid.deposit
                        );

                        topBid = nextBid;
                        topBid.blockIdx = nextBidStartBlockIdx;
                        nextBid = Bid(address(0), 0, 0, 0, 0);

                        updatedTopBid = true;
                        updatedNextBid = true;
                    }
                }
            }
        }

        return (
            topBid,
            nextBid,
            updatedTopBid,
            updatedNextBid,
            rentCharged,
            refundManager,
            refundAmount
        );
    }
}
