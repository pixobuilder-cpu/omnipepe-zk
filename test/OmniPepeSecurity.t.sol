// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/MockPEPE.sol";
import "../src/OmniPepeVault.sol";
import "../src/AiQuantumWotsStrategy.sol";
import "../src/OmniPepeOmnichainRouter.sol";

contract OmniPepeSecurityTest is Test {
    MockPEPE pepe; OmniPepeVault vault; AiQuantumWotsStrategy strategy; OmniPepeOmnichainRouter router;
    bytes32[64] privKey0; bytes32[64] pubKey0; bytes32 leaf0; bytes32 leaf1; bytes32 root;

    function setUp() public {
        pepe = new MockPEPE();
        vault = new OmniPepeVault(IERC20(address(pepe)));
        router = new OmniPepeOmnichainRouter(address(vault), address(0x1), address(0x2), 1_000_000 * 1e18);

        for (uint256 i = 0; i < 64; i++) {
            privKey0[i] = keccak256(abi.encodePacked("secret-seed-0", i));
            bytes32 acc = privKey0[i];
            for (uint8 step = 0; step < 15; step++) { acc = keccak256(abi.encodePacked(acc, uint8(i), step)); }
            pubKey0[i] = acc;
        }
        leaf0 = keccak256(abi.encodePacked(uint256(0), keccak256(abi.encodePacked(pubKey0))));
        leaf1 = keccak256(abi.encodePacked(uint256(1), keccak256("dummy-pubkey-1")));
        root = leaf0 < leaf1 ? keccak256(abi.encodePacked(leaf0, leaf1)) : keccak256(abi.encodePacked(leaf1, leaf0));

        strategy = new AiQuantumWotsStrategy(address(pepe), address(vault), root);
        vault.setStrategy(address(strategy));
        pepe.mint(address(strategy), 500_000 * 1e18);
    }

    function _signWots0(address target, uint256 amount) internal view returns (bytes32[64] memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(address(strategy), uint256(0), target, amount));
        for (uint256 i = 0; i < 64; i++) {
            uint8 nibble = uint8((uint256(msgHash) >> ((63 - i) * 4)) & 0x0F);
            bytes32 acc = privKey0[i];
            for (uint8 step = 0; step < nibble; step++) { acc = keccak256(abi.encodePacked(acc, uint8(i), step)); }
            sig[i] = acc;
        }
    }

    function testWotsExecutionAndAntiReplay() public {
        bytes32[64] memory sig = _signWots0(address(0x99), 100_000 * 1e18);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = leaf1;

        strategy.executeQuantumStrategy(address(0x99), 100_000 * 1e18, sig, proof);
        assertEq(pepe.balanceOf(address(0x99)), 100_000 * 1e18);
        assertEq(strategy.currentNonce(), 1);

        vm.expectRevert("Signature WOTS+ invalide");
        strategy.executeQuantumStrategy(address(0x99), 100_000 * 1e18, sig, proof);
    }

    function testSecurityRateLimitAndUnauthorizedCaller() public {
        pepe.mint(address(router), 2_000_000 * 1e18);
        bytes memory payload = abi.encode(address(0x88), 1_500_000 * 1e18, hex"02", bytes1(0x01));

        vm.prank(address(0x999));
        vm.expectRevert("Non autorise");
        router.lzCompose(address(0x2), bytes32(0), payload, address(0), "");

        vm.prank(address(0x1));
        vm.expectRevert("Plafond atteint");
        router.lzCompose(address(0x2), bytes32(0), payload, address(0), "");
    }
}
