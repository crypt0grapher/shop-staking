// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/XShop.sol";

contract XShopTest is Test {
    XShop public xshop;

    function setUp() public {
        xshop = new XShop();
    }

}
