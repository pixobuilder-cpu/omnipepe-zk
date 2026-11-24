// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "../src/MockPEPE.sol";
import "../src/MockUSDC.sol";
import "../src/OmniPepeVault.sol";
import "../src/AiQuantumWotsStrategy.sol";
import "../src/OmniPepeOmnichainRouter.sol";
import "../src/OmniPepeGasManager.sol";

contract DeployOmniPepe is Script {
    // Adresses officielles sur Base Sepolia (Chain ID: 84532)
    address constant LZ_ENDPOINT_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address constant WETH_SEPOLIA = 0x4200000000000000000000000000000000000006;
    address constant UNISWAP_ROUTER_SEPOLIA = 0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        bytes32 merkleRoot = vm.envBytes32("QUANTUM_MERKLE_ROOT");

        vm.startBroadcast(deployerKey);

        MockPEPE pepe = new MockPEPE();
        MockUSDC usdc = new MockUSDC();
        OmniPepeVault vault = new OmniPepeVault(IERC20(address(pepe)));
        
        AiQuantumWotsStrategy strategy = new AiQuantumWotsStrategy(
            address(pepe),
            address(vault),
            merkleRoot
        );
        vault.setStrategy(address(strategy));

        OmniPepeOmnichainRouter router = new OmniPepeOmnichainRouter(
            address(vault),
            LZ_ENDPOINT_SEPOLIA,
            address(pepe), // Simule l'adaptateur OFT en testnet
            50_000_000 * 10**18
        );

        OmniPepeGasManager gasManager = new OmniPepeGasManager(
            address(vault),
            address(usdc),
            WETH_SEPOLIA,
            UNISWAP_ROUTER_SEPOLIA
        );

        console.log("=== DEPLOIEMENT OMNIPEPE ZK SUR BASE SEPOLIA ===");
        console.log("MockPEPE                :", address(pepe));
        console.log("MockUSDC                :", address(usdc));
        console.log("OmniPepeVault ($oPEPE)  :", address(vault));
        console.log("AiQuantumWotsStrategy   :", address(strategy));
        console.log("OmniPepeOmnichainRouter :", address(router));
        console.log("OmniPepeGasManager      :", address(gasManager));

        vm.stopBroadcast();
    }
}
