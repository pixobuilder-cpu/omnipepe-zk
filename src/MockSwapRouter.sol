// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./OmniPepeGasManager.sol";

contract MockSwapRouter is ISwapRouter {
    IERC20 public immutable usdc;
    uint256 public constant PEPE_PER_USDC = 100_000 * 1e18;

    constructor(address _usdc) { usdc = IERC20(_usdc); }

    function exactOutput(ExactOutputParams calldata p) external payable override returns (uint256 amountIn) {
        amountIn = (p.amountOut * PEPE_PER_USDC) / 1e6;
        require(amountIn <= p.amountInMaximum, "Glissement maximal depasse");
        address tokenIn;
        bytes memory path = p.path;
        assembly { tokenIn := shr(96, mload(add(add(path, 32), sub(mload(path), 20)))) }
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        usdc.transfer(p.recipient, p.amountOut);
    }
}
