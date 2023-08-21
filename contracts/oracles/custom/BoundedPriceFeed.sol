// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {AggregatorV2V3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import {PriceFeedType} from "@gearbox-protocol/sdk-gov/contracts/PriceFeedType.sol";
import {IPriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";
import {PriceFeedValidationTrait} from "@gearbox-protocol/core-v3/contracts/traits/PriceFeedValidationTrait.sol";

interface ChainlinkReadableAggregator {
    function aggregator() external view returns (address);
    function phaseAggregators(uint16 idx) external view returns (AggregatorV2V3Interface);
    function phaseId() external view returns (uint16);
}

/// @title Bounded price feed
/// @notice Can be used to provide upper-bounded answers for assets that are
///         expected to have the price in a certain range, e.g. stablecoins
contract BoundedPriceFeed is IPriceFeed, ChainlinkReadableAggregator, PriceFeedValidationTrait {
    PriceFeedType public constant override priceFeedType = PriceFeedType.BOUNDED_ORACLE;
    uint256 public constant override version = 3_00;
    uint8 public constant override decimals = 8;
    bool public constant override skipPriceCheck = true;

    /// @notice Underlying price feed
    address public immutable priceFeed;
    uint32 public immutable stalenessPeriod;
    bool public immutable skipCheck;

    /// @notice Upper bound for underlying price feed answers
    int256 public immutable upperBound;

    /// @notice Constructor
    /// @param _priceFeed Underlying price feed
    /// @param _stalenessPeriod Underlying price feed staleness period, must be non-zero unless it performs own checks
    /// @param _upperBound Upper bound for underlying price feed answers
    constructor(address _priceFeed, uint32 _stalenessPeriod, int256 _upperBound) {
        priceFeed = _priceFeed;
        stalenessPeriod = _stalenessPeriod;
        skipCheck = _validatePriceFeed(priceFeed, stalenessPeriod);
        upperBound = _upperBound;
    }

    /// @notice Price feed description
    function description() external view override returns (string memory) {
        return string(abi.encodePacked("Bounded ", IPriceFeed(priceFeed).description(), " price feed"));
    }

    /// @notice Returns the upper-bounded USD price of the token
    function latestRoundData()
        external
        view
        override
        returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80)
    {
        (answer, updatedAt) = _getValidatedPrice(priceFeed, stalenessPeriod, skipCheck);
        return (0, _upperBoundValue(answer), 0, updatedAt, 0);
    }

    /// @dev Upper-bounds given value
    function _upperBoundValue(int256 value) internal view returns (int256) {
        return (value > upperBound) ? upperBound : value;
    }

    // --------- //
    // ANALYTICS //
    // --------- //

    function aggregator() external view override returns (address) {
        return ChainlinkReadableAggregator(priceFeed).aggregator();
    }

    function phaseAggregators(uint16 idx) external view override returns (AggregatorV2V3Interface) {
        return ChainlinkReadableAggregator(priceFeed).phaseAggregators(idx);
    }

    function phaseId() external view override returns (uint16) {
        return ChainlinkReadableAggregator(priceFeed).phaseId();
    }
}
