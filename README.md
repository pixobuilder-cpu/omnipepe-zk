
#OmniPepe zk ($oPEPE) — Omnichain, Post-Quantum & Gasless M2M Protocol

Decentralized architecture designed for autonomous Machine-to-Machine (M2M) agents:
• ERC-4626 Vault & Stealth Identities (OmniPepeVault): Wraps $PEPE into $oPEPE with native ERC20Permit (EIP-712) support for operations without native gas.
• Post-Quantum Security (AiQuantumWotsStrategy): Winternitz One-Time Signature (WOTS+ 64 blocks) verification and Merkle proofs optimized in Yul assembly (~191,773 gas).
• M2M Financial Autonomy (OmniPepeGasManager): Automated USDC top-up (10 USDC floor) via off-chain signature without ETH.
• LayerZero V2 Omnichain Interoperability (Base ↔ Solana): Solidity EVM hub (OFTAdapter) synchronized with a native Rust/Anchor SPL program on Solana.

Deployed Contracts & Programs (Testnets)


Base Sepolia (Chain ID: 84532 | LayerZero EID: 40245)


Contract	Address	Details
OmniPepeVault ($oPEPE)	0x0592170d7b70cb5c1f5b421a45d6648c3fba662d	ERC-4626 Vault + EIP-2612 Permit
OmniPepeOFTAdapter	0xD72b42CF147c6c3FC6e6E31817c2C937843738DE	LayerZero V2 Omnichain Adapter
AiQuantumWotsStrategy	0x427425Fd3111a1ccadd1FF38A5B6aCa8A4aBDF46	Post-Quantum WOTS+ Verifier (Yul)
OmniPepeGasManager	0x654369f131f31A8A4fE1445E61c6698477bF8555	Automated 10 USDC M2M Top-Up


Solana Devnet (LayerZero EID: 40168)


Component	Base58 Address	Details
OFT Program (Rust / Anchor)	AJ548vhTT1hHF7PsYafFNRJur1KSbFhtaVbfTWgXeMqY	Optimized BPF executable (opt-level="z", LTO)
OFTStore (PDA)	F5HxDxsUaZTgeeDX1waUEvru6iGfbXK9hRv5iyuUNhJZ	Exclusive mint authority & ULN configuration
SPL Mint ($oPEPE)	APfwA7jxDBur8UefqGWwXo1zx24hQ8rWjAVm6h9KZ2bS	SPL token 6 shared decimals (Freeze disabled)
DVN Config PDA (LayerZero Labs)	6PW6tBKu9rQVKL8TiYV7BhmAxviHau68LfBAvRdmmPhE	Configured decentralized verifier


Repository Structure

• src/: Solidity smart contracts (OmniPepeVault, OmniPepeOFTAdapter, OmniPepeOFT, AiQuantumWotsStrategy, OmniPepeGasManager).
• test/: Foundry unit, fuzzing, and security tests.
• solana-oft/: Rust Anchor program (programs/oft) and TypeScript Umi/LayerZero V2 scripts.
• *.py: M2M agent scripts, WOTS+ Merkle tree generation, and gasless relayers.

