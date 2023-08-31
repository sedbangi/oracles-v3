// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {PriceFeedTest} from "../PriceFeedTest.sol";

import {WATokenMock} from "../../mocks/aave/WATokenMock.sol";

import {IWAToken} from "../../../interfaces/aave/IWAToken.sol";
import {WrappedAaveV2PriceFeed} from "../../../oracles/aave/WrappedAaveV2PriceFeed.sol";

contract WrappedAaveV2PriceFeedUnitTest is PriceFeedTest {
    WrappedAaveV2PriceFeed priceFeed;
    WATokenMock waToken;

    function setUp() public {
        _setUp();

        waToken = new WATokenMock();
        waToken.hackExchangeRate(1.02 ether);

        priceFeed = new WrappedAaveV2PriceFeed(
            address(addressProvider),
            address(waToken),
            address(underlyingPriceFeed),
            1 days
        );

        waToken.hackExchangeRate(1.03 ether);
    }

    /// @notice U:[AAVE-1]: Price feed works as expected
    function test_U_AAVE_01_price_feed_works_as_expected() public {
        // constructor
        assertEq(priceFeed.lpToken(), address(waToken), "Incorrect lpToken");
        assertEq(priceFeed.lpContract(), address(waToken), "Incorrect lpToken");
        assertEq(priceFeed.lowerBound(), 1.01796 ether, "Incorrect lower bound"); // 1.02 * 0.998

        // overriden functions
        vm.expectCall(address(waToken), abi.encodeCall(IWAToken.exchangeRate, ()));
        assertEq(priceFeed.getLPExchangeRate(), 1.03 ether, "Incorrect getLPExchangeRate");
        assertEq(priceFeed.getScale(), 1 ether, "Incorrect getScale");
    }
}
