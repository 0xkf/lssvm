// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ICurve} from "./ICurve.sol";
import {CurveErrorCodes} from "./CurveErrorCodes.sol";
import {PRBMathUD60x18} from "prb-math/PRBMathUD60x18.sol";

contract LinearCurve is ICurve, CurveErrorCodes {
    using PRBMathUD60x18 for uint256;

    function getBuyInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 numItems,
        uint256 feeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint256 newSpotPrice,
            uint256 inputValue
        )
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0);
        }
        if (feeMultiplier > PRBMathUD60x18.SCALE) {
            return (Error.INVALID_FEE_MULTIPLIER, 0, 0);
        }

        newSpotPrice = spotPrice + delta * numItems;
        inputValue =
            numItems *
            spotPrice +
            (numItems * (numItems - 1) * delta) /
            2;
        inputValue += inputValue.mul(feeMultiplier);
        error = Error.OK;
    }

    function getSellInfo(
        uint256 spotPrice,
        uint256 delta,
        uint256 numItems,
        uint256 feeMultiplier
    )
        external
        pure
        override
        returns (
            Error error,
            uint256 newSpotPrice,
            uint256 outputValue
        )
    {
        if (numItems == 0) {
            return (Error.INVALID_NUMITEMS, 0, 0);
        }
        if (feeMultiplier > PRBMathUD60x18.SCALE) {
            return (Error.INVALID_FEE_MULTIPLIER, 0, 0);
        }

        uint256 totalPriceDecrease = delta * numItems;
        if (spotPrice < totalPriceDecrease) {
            newSpotPrice = 0;
            uint256 numItemsTillZeroPrice = spotPrice / delta + 1;
            outputValue =
                numItemsTillZeroPrice *
                spotPrice -
                (numItemsTillZeroPrice * (numItemsTillZeroPrice - 1) * delta) /
                2;
        } else {
            newSpotPrice = spotPrice - totalPriceDecrease;
            outputValue =
                numItems *
                spotPrice -
                (numItems * (numItems - 1) * delta) /
                2;
        }
        outputValue -= outputValue.mul(feeMultiplier);

        error = Error.OK;
    }
}
