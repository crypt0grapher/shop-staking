// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/XShop.sol";
import "./UniswapV2Mock.sol";

contract XShopTest is Test {
    XShop public xshop;

    function setUp() public {
        xshop = new XShop();
        ERC20 shop =  new ERC20("SHOP MOCK", "MOCK");
        UniswapV2Mock router = new UniswapV2Mock(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40);
        vm.etch(address(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40),address(shop).code);
        vm.etch(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), address(router).code);
    }

    function deposit() public {

    }

}
