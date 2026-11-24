// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAIStrategy {
    function totalManagedAssets() external view returns (uint256);
    function withdrawToVault(uint256 amount) external;
}

contract OmniPepeVault is ERC4626, ERC20Permit, Ownable {
    IAIStrategy public activeStrategy;
    constructor(IERC20 _pepe) ERC4626(_pepe) ERC20("OmniPepe zk", "oPEPE") ERC20Permit("OmniPepe zk") Ownable(msg.sender) {}
    function setStrategy(address _s) external onlyOwner { activeStrategy = IAIStrategy(_s); }
    function totalAssets() public view override returns (uint256) {
        uint256 s = address(activeStrategy) != address(0) ? activeStrategy.totalManagedAssets() : 0;
        return IERC20(asset()).balanceOf(address(this)) + s;
    }
    function decimals() public view virtual override(ERC4626, ERC20) returns (uint8) { return super.decimals(); }
    function _withdraw(address c, address r, address o, uint256 a, uint256 sh) internal override {
        uint256 b = IERC20(asset()).balanceOf(address(this));
        if (a > b && address(activeStrategy) != address(0)) activeStrategy.withdrawToVault(a - b);
        super._withdraw(c, r, o, a, sh);
    }
}
