// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { OFTAdapter } from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract OmniPepeOFTAdapter is OFTAdapter {
    constructor(
        address _token,      // Adresse de OmniPepeVault ($oPEPE) sur Base
        address _lzEndpoint, // Endpoint LayerZero V2 officiel sur Base
        address _delegate    // Proprietaire / Administrateur des peers et DVNs
    ) OFTAdapter(_token, _lzEndpoint, _delegate) Ownable(_delegate) {}
}
