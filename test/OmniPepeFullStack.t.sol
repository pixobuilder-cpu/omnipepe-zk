// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/MockPEPE.sol";
import "../src/OmniPepeVault.sol";
import "../src/OmniPepeOmnichainRouter.sol";
import "../src/OmniPepeGasManager.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {}
    function decimals() public pure override returns (uint8) { return 6; }
    function mint(address to, uint256 a) external { _mint(to, a); }
}

contract MockSwapRouter is ISwapRouter {
    MockUSDC public usdc;
    constructor(address _u) { usdc = MockUSDC(_u); }
    function exactOutput(ExactOutputParams calldata p) external payable override returns (uint256 amountIn) {
        amountIn = (p.amountOut * 100_000 * 1e18) / 1e6;
        address tIn; bytes memory path = p.path;
        assembly { tIn := shr(96, mload(add(add(path, 32), sub(mload(path), 20)))) }
        IERC20(tIn).transferFrom(msg.sender, address(this), amountIn);
        usdc.mint(p.recipient, p.amountOut);
    }
}

contract OmniPepeFullStackTest is Test {
    MockPEPE pepe; MockUSDC usdc; MockSwapRouter swap; OmniPepeVault vault; OmniPepeOmnichainRouter router; OmniPepeGasManager gasMgr;
    uint256 pk = 0xA11CE; address agent;

    function setUp() public {
        agent = vm.addr(pk);
        pepe = new MockPEPE(); usdc = new MockUSDC(); swap = new MockSwapRouter(address(usdc));
        vault = new OmniPepeVault(IERC20(address(pepe)));
        router = new OmniPepeOmnichainRouter(address(vault), address(0x1), address(0x2), 50_000_000 * 1e18);
        gasMgr = new OmniPepeGasManager(address(vault), address(usdc), address(0x3), address(swap));
    }

    function testFullM2MFlow() public {
        pepe.mint(address(router), 5_000_000 * 1e18);
        vm.prank(address(0x1));
        router.lzCompose(address(0x2), bytes32(0), abi.encode(agent, 5_000_000 * 1e18, hex"02", bytes1(0x01)), address(0), "");
        assertEq(vault.balanceOf(agent), 5_000_000 * 1e18);

        uint256 dl = block.timestamp + 1 hours;
        bytes32 sh = keccak256(abi.encode(keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"), agent, address(gasMgr), 1_500_000 * 1e18, vault.nonces(agent), dl));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, keccak256(abi.encodePacked("\x19\x01", vault.DOMAIN_SEPARATOR(), sh)));

        gasMgr.refuelAgentUsdcWithPermit(agent, 1_500_000 * 1e18, 10_000 * 1e18, dl, v, r, s);
        assertEq(usdc.balanceOf(agent), 10 * 1e6);
        assertEq(vault.balanceOf(agent), 3_990_000 * 1e18);
    }
}
