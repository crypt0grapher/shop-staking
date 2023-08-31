// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/XShop.sol";
import "./UniswapV2Mock.sol";
import "./ShopMock.sol";

contract XShopTest is Test {
    XShop public xshop;
    SHOP public shopToken;
    uint256 initialSupply = 10 ** 23; // 100K tokens, 18 decimals

    function setUp() public {
        xshop = new XShop();
        shopToken = new SHOP();
        UniswapV2Mock router = new UniswapV2Mock(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40);
        vm.etch(address(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40), address(shopToken).code);
        vm.etch(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), address(router).code);
        SHOP shop = SHOP(payable(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40));
        shop.mint(address(this),initialSupply);
    }

    function testInitialization() public {
        // Check initial parameters
        assert(xshop.minimumStake() == 20000 * 10 ** 18);
        assert(xshop.timeLock() == 5 days);
        assert(xshop.epochDuration() == 1 days);
    }

    function testDeposit() public {
        uint256 depositAmount = 25000 * 1e18;
        SHOP shop = SHOP(payable(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40));

        // Approve XShop to transfer SHOP
        shop.approve(address(xshop), depositAmount);

        // Deposit into XShop
        xshop.deposit(depositAmount);

        // Validate the deposit
        assert(xshop.balanceOf(address(this)) == depositAmount);
    }

    function testWithdraw() public {
        uint256 withdrawAmount = 10000 * 10 ** 18;

        // Withdraw from XShop
        xshop.withdraw(withdrawAmount);

        // Validate the withdrawal
        assert(xshop.balanceOf(address(this)) == 15000 * 10 ** 18);
    }

    function testToggleReinvesting() public {
        xshop.toggleReinvesting();
        // Check the status of reinvesting
        assert(xshop.isReinvesting() == true);
    }

    function testSnapshot() public payable {
        // Create a snapshot with some eth
        xshop.snapshot{value: 1 ether}();

        // Validate the snapshot
        (uint256 timestamp, uint256 rewards,  uint256 supply, uint256 shop) = xshop.epochInfo(0);
        //rewards
        assert(rewards == 1 ether);
        //timestamp
        assert(timestamp > 0);
    }

}
