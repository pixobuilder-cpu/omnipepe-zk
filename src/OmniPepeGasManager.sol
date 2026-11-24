// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OmniPepeVault.sol";

interface ISwapRouter {
    struct ExactOutputParams { bytes path; address recipient; uint256 deadline; uint256 amountOut; uint256 amountInMaximum; }
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract OmniPepeGasManager {
    using SafeERC20 for IERC20;
    OmniPepeVault public immutable vault;
    IERC20 public immutable pepeToken;
    IERC20 public immutable usdc;
    address public immutable weth;
    ISwapRouter public immutable swapRouter;
    uint256 public constant MIN_USDC_FLOOR = 10 * 1e6;

    constructor(address _v, address _u, address _w, address _r) {
        vault = OmniPepeVault(_v); pepeToken = IERC20(vault.asset()); usdc = IERC20(_u); weth = _w; swapRouter = ISwapRouter(_r);
    }
    function getRequiredUsdcForFloor(address _a) public view returns (uint256) {
        uint256 b = usdc.balanceOf(_a); return b >= MIN_USDC_FLOOR ? 0 : MIN_USDC_FLOOR - b;
    }
    function refuelAgentUsdcWithPermit(address _a, uint256 _max, uint256 _fee, uint256 _dl, uint8 _v, bytes32 _r, bytes32 _s) external {
        uint256 need = getRequiredUsdcForFloor(_a);
        require(need > 0, "Plancher de 10 USDC deja atteint");
        IERC20Permit(address(vault)).permit(_a, address(this), _max, _dl, _v, _r, _s);
        if (_fee > 0) IERC20(address(vault)).safeTransferFrom(_a, msg.sender, _fee);
        uint256 maxPepe = vault.redeem(_max - _fee, address(this), _a);
        bytes memory path = abi.encodePacked(address(usdc), uint24(500), weth, uint24(3000), address(pepeToken));
        pepeToken.forceApprove(address(swapRouter), maxPepe);
        uint256 spent = swapRouter.exactOutput(ISwapRouter.ExactOutputParams(path, _a, block.timestamp, need, maxPepe));
        if (maxPepe > spent) { pepeToken.forceApprove(address(vault), maxPepe - spent); vault.deposit(maxPepe - spent, _a); }
    }
}
