// SPDX-License-Identifier: UNLICENSED
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2023.
pragma solidity ^0.8.17;

import {PriceFeedTest} from "../PriceFeedTest.sol";

import {YVaultMock} from "../../mocks/yearn/YVaultMock.sol";

import {IYVault} from "../../../interfaces/yearn/IYVault.sol";
import {YearnPriceFeed} from "../../../oracles/yearn/YearnPriceFeed.sol";

contract YearnPriceFeedUnitTest is PriceFeedTest {
    YearnPriceFeed priceFeed;
    YVaultMock yVault;

    function setUp() public {
        _setUp();

        yVault = new YVaultMock(makeAddr("TOKEN"), 6);
        yVault.hackPricePerShare(1.02e6);

        priceFeed = new YearnPriceFeed(
            address(addressProvider),
            address(yVault),
            address(underlyingPriceFeed),
            1 days
        );

        yVault.hackPricePerShare(1.03e6);
    }

    /// @notice U:[YFI-1]: Price feed works as expected
    function test_U_YFI_01_price_feed_works_as_expected() public {
        // constructor
        assertEq(priceFeed.lpToken(), address(yVault), "Incorrect lpToken");
        assertEq(priceFeed.lpContract(), address(yVault), "Incorrect lpToken");
        assertEq(priceFeed.lowerBound(), 1.01796e6, "Incorrect lower bound"); // 1.02 * 0.998

        // overriden functions
        vm.expectCall(address(yVault), abi.encodeCall(IYVault.pricePerShare, ()));
        assertEq(priceFeed.getLPExchangeRate(), 1.03e6, "Incorrect getLPExchangeRate");
        assertEq(priceFeed.getScale(), 1e6, "Incorrect getScale");
    }
}
