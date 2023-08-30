// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Simple ERC20 Interface
interface IERC20Mock {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function mint(address to, uint256 amount) external;
}

contract UniswapV2Mock {
    // Assume that 1 ETH is equivalent to 1000 Mock Tokens as the predefined price
    uint256 public rate = 1000;

    IERC20Mock public token;

    event Swapped(address indexed user, uint256 ethAmount, uint256 tokenAmount);

    constructor(address _tokenAddress) {
        token = IERC20Mock(_tokenAddress);
    }

    // Fallback function to allow receiving ETH
    receive() external payable {}

    // Mock swapExactETHForTokens function
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (uint256[] memory amounts)
    {
        require(path[0] == address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), "UniswapV2Mock: Invalid path");
        require(path[path.length - 1] == address(token), "UniswapV2Mock: Invalid last token");
        require(block.timestamp <= deadline, "UniswapV2Mock: Deadline exceeded");
        require(msg.value > 0, "UniswapV2Mock: Invalid msg.value");

        uint256 tokenAmount = msg.value * rate;
        require(tokenAmount >= amountOutMin, "UniswapV2Mock: Slippage not acceptable");

        // Simulate token transfer
        require(token.transfer(to, tokenAmount), "UniswapV2Mock: Transfer failed");

        emit Swapped(msg.sender, msg.value, tokenAmount);

        amounts = new uint256[](path.length);
        amounts[0] = msg.value;
        amounts[path.length - 1] = tokenAmount;

        return amounts;
    }

    // To refill the mock contract's token balance
    function mintTokens(uint256 amount) external {
        token.mint(address(this), amount);
    }
}
