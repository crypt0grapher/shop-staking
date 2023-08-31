// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/XShop.sol";
import "./UniswapV2Mock.sol";
import "./ShopMock.sol";
import "forge-std/console.sol";

contract XShopTest is Test {
    XShop public xshop;
    SHOP public shop;
    uint256 initialSupply = 10 ** 24; // 1M tokens, 18 decimals
    address internal constant user1 = address(1);
    address internal constant user2 = address(2);

    function setUp() public {
        xshop = new XShop();
        SHOP shopToken = new SHOP();
        UniswapV2Mock router = new UniswapV2Mock(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40);
        vm.etch(address(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40), address(shopToken).code);
        vm.etch(address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D), address(router).code);
        shop = SHOP(payable(0x99e186E8671DB8B10d45B7A1C430952a9FBE0D40));
        shop.mint(address(this), initialSupply);
        shop.approve(address(xshop), initialSupply);
    }

    function testInitialization() public {
        // Check initial parameters
        assert(xshop.minimumStake() == 20000 * 10 ** 18);
        assert(xshop.timeLock() == 5 days);
        assert(xshop.epochDuration() == 1 days);
    }

    function testDeposit() public {
        uint256 depositAmount = 25000 * 1e18;
        // Approve XShop to transfer SHOP
        uint256 shopBalance = shop.balanceOf(address(this));
        // Deposit into XShop
        xshop.deposit(depositAmount);

        // Validate the deposit
        assertEq(xshop.balanceOf(address(this)), depositAmount);
        assertEq(shop.balanceOf(address(this)), shopBalance - depositAmount);
        // Validate totalsupply change
        assertEq(xshop.totalSupply(), depositAmount);
    }

    function testFailMinimumAllowableDeposit() public {
        xshop.deposit(19000 * 1e18);
    }

    function testWithdraw() public {
        uint256 withdrawAmount = 20000 * 10 ** 18;
        xshop.deposit(withdrawAmount);
        // Withdraw from XShop
        xshop.withdraw(withdrawAmount);

        xshop.deposit(withdrawAmount * 2);
        xshop.withdraw(withdrawAmount);
        assertEq(xshop.balanceOf(address(this)), withdrawAmount);

        xshop.snapshot{value: 1 ether}();
        skip(1 days);
        assertEq(xshop.balanceOf(address(this)), withdrawAmount);
        xshop.withdraw(withdrawAmount);
        assertEq(xshop.balanceOf(address(this)), 0);
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
        assert(supply == 0);
        //timestamp
        assert(timestamp > 0);
    }


    function testFailNextSnapshotTooEarly() public payable {
        // Create a snapshot with some eth
        xshop.snapshot{value: 1 ether}();
        skip(1 hours);
        xshop.snapshot{value: 1 ether}();
    }

    function testNextSnapshot() public payable {
        // Create a snapshot with some eth
        xshop.snapshot{value: 1 ether}();

        // Validate the snapshot
        (uint256 timestamp, uint256 rewards,  uint256 supply, uint256 shop) = xshop.epochInfo(0);
        //rewards
        assert(rewards == 1 ether);
        assert(supply == 0);
        //timestamp
        assert(timestamp > 0);
        skip(1 days);
        xshop.snapshot{value: 2 ether}();
    }

    function testFailClaimRightAfterDeposit() public payable {
        uint256 amount = 20000 * 10 ** 18;
        xshop.deposit(amount);
        // Create a snapshot with some eth
        xshop.snapshot{value: 1 ether}();
        // Validate the snapshot
        xshop.claimReward();
    }

    function testClaim() public payable {
        // preparing a couple of more users
        shop.mint(user1, 100000 * 1e18);
        vm.startPrank(user1);
        shop.approve(address(xshop), initialSupply);
        vm.stopPrank();
        // epoch 0
        xshop.deposit(20000 * 1e18);
        // Skipping, just testing if the bot skips run, should be treated as epoch 0 anyways
        skip(3 days);
        // user = 40K, user1 = 60K, supply = 100K
        xshop.deposit(20000 * 1e18);
        vm.startPrank(user1);
        xshop.deposit(60000 * 1e18);
        vm.stopPrank();
//        uint256 reward = xshop.getPendingReward();
//        assertEq(reward, 0);
        // distributing 1 ether, should be 0.4ETH for user and 0.6ETH for user1, claimable at epoch 2
        xshop.snapshot{value: 1 ether}();

        // epoch 1
//        reward = xshop.getPendingReward();
        // zero rewards since too early
//        assertEq(reward, 0);
//        console.log("user0 balance", xshop.balanceOf(address(this)));
//        console.log("user1 balance", xshop.balanceOf(user1));
//        console.log("=====epoch: ======= ", xshop.currentEpoch());
//        console.log("reward: ", reward);
        skip(1 days);
        // user = 20K, user1 = 60K, supply = 80K
        xshop.withdraw(20000 * 1e18);
        // distributing 2 ether, should be 2*2/8 = 0.5ETH for user and 2*6/8 = 1.5ETH for user1, claimable at epoch 3
        xshop.snapshot{value: 2 ether}();

        // epoch 2
        uint256 reward = xshop.getPendingReward();
        console.log("user0 balance", xshop.balanceOf(address(this)));
        console.log("user1 balance", xshop.balanceOf(user1));
        console.log("=====epoch: ======= ", xshop.currentEpoch());
        console.log("reward: ", reward);
        assertEq(reward, 1 ether * 40 / 100);
        vm.startPrank(user1);
        uint256 rewardUser1 = xshop.getPendingReward();
        vm.stopPrank();
        assertEq(rewardUser1, 1 ether * 60 / 100);

//
//        skip(1 days);
//        // epoch 2
//        xshop.withdraw(20000 * 1e18);
//        vm.prank(user1);
//        xshop.snapshot{value: 10 ether}();
//        reward = xshop.getPendingReward();
//        console.log("user0 balance", xshop.balanceOf(address(this)));
//        console.log("user1 balance", xshop.balanceOf(user1));
//        console.log("=====epoch: ======= ", xshop.currentEpoch());
//        console.log(" reward: ", reward);
//
//        assertEq(reward, 2 ether * 20 / 100);
//        reward = xshop.getPendingReward();
//        assertEq(reward, 2 ether * 60 / 100);
//        vm.prank(user1);
//        skip(1 days);
//        // epoch 1
//        xshop.snapshot{value: 2 ether}();
//
//        reward = xshop.getPendingReward();
//        console.log("=====epoch: ======= ", xshop.currentEpoch());
//        console.log("reward", reward);
//        // should be previous epoch fee in epoch 1
//        assertEq(reward, 0);
//
//

        // Validate the snapshot
//        uint256 currentEtherBalance = address(this).balance;
//        xshop.claimReward();
//        assertEq(address(this).balance, currentEtherBalance + 1 ether);
    }


}
