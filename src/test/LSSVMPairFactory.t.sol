// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {DSTest} from "ds-test/test.sol";
import {LinearCurve} from "../bonding-curves/LinearCurve.sol";
import {LSSVMPairFactory} from "../LSSVMPairFactory.sol";
import {LSSVMPair} from "../LSSVMPair.sol";
import {LSSVMPairETH} from "../LSSVMPairETH.sol";
import {LSSVMPairERC20} from "../LSSVMPairERC20.sol";
import {LSSVMPairEnumerableETH} from "../LSSVMPairEnumerableETH.sol";
import {LSSVMPairMissingEnumerableETH} from "../LSSVMPairMissingEnumerableETH.sol";
import {LSSVMPairEnumerableERC20} from "../LSSVMPairEnumerableERC20.sol";
import {LSSVMPairMissingEnumerableERC20} from "../LSSVMPairMissingEnumerableERC20.sol";
import {Test721} from "../mocks/Test721.sol";
import {Hevm} from "./utils/Hevm.sol";

contract LSSVMPairFactoryTest is DSTest {
    uint256[] idList;
    Test721 test721;
    LinearCurve linearCurve;
    LSSVMPairFactory factory;
    address payable constant feeRecipient = payable(address(69));
    uint256 constant protocolFeeMultiplier = 3e15;

    function setUp() public {
        linearCurve = new LinearCurve();
        LSSVMPairETH enumerableETHTemplate = new LSSVMPairEnumerableETH();
        LSSVMPairETH missingEnumerableETHTemplate = new LSSVMPairMissingEnumerableETH();
        LSSVMPairERC20 enumerableERC20Template = new LSSVMPairEnumerableERC20();
        LSSVMPairERC20 missingEnumerableERC20Template = new LSSVMPairMissingEnumerableERC20();
        factory = new LSSVMPairFactory(
            enumerableETHTemplate,
            missingEnumerableETHTemplate,
            enumerableERC20Template,
            missingEnumerableERC20Template,
            feeRecipient,
            protocolFeeMultiplier
        );
        factory.setBondingCurveAllowed(linearCurve, true);
    }

    function test_createPairETH() public {
        uint256 delta = 0.1 ether;
        uint256 fee = 5e15;
        uint256 spotPrice = 1 ether;
        uint256 numInitialNFTs = 10;

        delete idList;
        test721 = new Test721();

        for (uint256 i = 1; i <= numInitialNFTs; i++) {
            test721.mint(address(this), i);
            idList.push(i);
        }

        test721.setApprovalForAll(address(factory), true);
        LSSVMPairETH pair = factory.createPairETH{value: 0.1 ether}(
            test721,
            linearCurve,
            LSSVMPair.PoolType.TRADE,
            delta,
            fee,
            spotPrice,
            idList
        );

        // verify pair variables
        assertEq(address(pair.nft()), address(test721));
        assertEq(address(pair.bondingCurve()), address(linearCurve));
        assertEq(pair.fee(), fee);
        assertEq(pair.spotPrice(), spotPrice);
        assertEq(pair.owner(), address(this));
        assertEq(address(pair).balance, 0.1 ether);

        // verify NFT ownership
        for (uint256 i = 1; i <= numInitialNFTs; i++) {
            assertEq(test721.ownerOf(i), address(pair));
        }
    }
}
