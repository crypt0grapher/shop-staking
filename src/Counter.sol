// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract StakingContract is ERC20 {
    using SafeMath for uint256;

    IERC20 public shopToken;
    uint256 public totalFees;
    uint256 public lastSnapshot;

    mapping(address => uint256) public lastClaimed;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event FeesSnapshotted(uint256 totalFees);

    constructor(address _shopToken) ERC20("Staked SHOP Token", "stSHOP") {
        shopToken = IERC20(_shopToken);
    }

    function snapshot(uint256 newFees) external {
        totalFees = totalFees.add(newFees);
        lastSnapshot = block.timestamp;
        emit FeesSnapshotted(totalFees);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");

        uint256 share = calculateShare(msg.sender);
        lastClaimed[msg.sender] = totalFees;

        shopToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);

        if (share > 0) {
            shopToken.transfer(msg.sender, share);
        }

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0");

        uint256 share = calculateShare(msg.sender);
        lastClaimed[msg.sender] = totalFees;

        _burn(msg.sender, amount);
        shopToken.transfer(msg.sender, amount.add(share));

        emit Withdrawn(msg.sender, amount);
    }

    function calculateShare(address user) internal view returns (uint256) {
        uint256 userStake = balanceOf(user);
        if (userStake == 0) return 0;

        uint256 unclaimedFees = totalFees.sub(lastClaimed[user]);
        return userStake.mul(unclaimedFees).div(totalSupply());
    }
}
