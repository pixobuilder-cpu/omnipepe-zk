// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./OmniPepeVault.sol";

contract OmniPepeOmnichainRouter is ReentrancyGuard {
    using SafeERC20 for IERC20;
    OmniPepeVault public immutable vault;
    IERC20 public immutable pepeToken;
    address public immutable lzEndpoint;
    address public trustedOFTAdapter;
    uint256 public maxHourlyCrossChainVolume;
    uint256 public currentHourVolume;
    uint256 public lastResetTimestamp;

    constructor(address _v, address _lz, address _oft, uint256 _lim) {
        vault = OmniPepeVault(_v); pepeToken = IERC20(vault.asset());
        lzEndpoint = _lz; trustedOFTAdapter = _oft;
        maxHourlyCrossChainVolume = _lim; lastResetTimestamp = block.timestamp;
    }
    function lzCompose(address _from, bytes32, bytes calldata _msg, address, bytes calldata) external payable nonReentrant {
        require(msg.sender == lzEndpoint && _from == trustedOFTAdapter, "Non autorise");
        (address stealth, uint256 amt, , ) = abi.decode(_msg, (address, uint256, bytes, bytes1));
        if (block.timestamp >= lastResetTimestamp + 1 hours) { currentHourVolume = 0; lastResetTimestamp = block.timestamp; }
        require(currentHourVolume + amt <= maxHourlyCrossChainVolume, "Plafond atteint");
        currentHourVolume += amt;
        pepeToken.forceApprove(address(vault), amt);
        vault.deposit(amt, stealth);
    }
}
