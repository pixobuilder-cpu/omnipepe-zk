// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import { Script, console } from "forge-std/Script.sol";
import { OmniPepeOFTAdapter } from "../src/OmniPepeOFTAdapter.sol";

contract DeployOFTAdapter is Script {
    address constant LZ_ENDPOINT_BASE_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;

    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address delegate = vm.addr(deployerKey);
        address oPepeVault = vm.envAddress("OMNI_VAULT");

        vm.startBroadcast(deployerKey);
        OmniPepeOFTAdapter adapter = new OmniPepeOFTAdapter(oPepeVault, LZ_ENDPOINT_BASE_SEPOLIA, delegate);
        console.log("OmniPepeOFTAdapter deploye :", address(adapter));
        vm.stopBroadcast();
    }
}
