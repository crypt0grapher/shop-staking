// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/XShop.sol";
import "./UniswapV2Mock.sol";
import "./ShopMock.sol";

contract XShopTest is Test {
    XShop public xshop;
    IERC20 public shopToken;
    uint256 initialSupply = 10 ** 24; // 1 million tokens, 18 decimals

    function setUp() public {
        xshop = new XShop();
        address _shopToken = address(new ShopMock("SHOP MOCK", "MOCK"));
        UniswapV2Mock router = new UniswapV2Mock(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40);
        vm.etch(address(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40), _shopToken.code);
        vm.etch(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), address(router).code);
        ShopMock(_shopToken).mint(address(this), initialSupply);
        shopToken = ERC20(_shopToken);
    }

    function testInitialization() public {
        // Check initial parameters
        assert(xshop.minimumStake() == 20000 * 10 ** 18);
        assert(xshop.timeLock() == 5 days);
        assert(xshop.epochDuration() == 1 days);
    }

    function testDeposit() public {
        uint256 depositAmount = 25000 * 10 ** 18;

        // Approve XShop to transfer SHOP
        shopToken.approve(address(xshop), depositAmount);

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
