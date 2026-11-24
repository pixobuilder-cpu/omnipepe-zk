# OmniPepe zk ($oPEPE) — Omnichain, Post-Quantum & Gasless M2M Protocol

Architecture décentralisée conçue pour les agents autonomes Machine-to-Machine (M2M) :
- **Coffre-fort ERC-4626 & Identités Furtives (`OmniPepeVault`)** : Enveloppe `$PEPE` en `$oPEPE` avec support natif `ERC20Permit` (EIP-712) pour des opérations sans gaz natif.
- **Sécurité Post-Quantique (`AiQuantumWotsStrategy`)** : Vérification de signatures à usage unique Winternitz (WOTS+ 64 blocs) et preuves de Merkle optimisées en assemblage Yul (~191 773 gaz).
- **Autonomie Financière M2M (`OmniPepeGasManager`)** : Rechargement automatique en USDC (plancher de 10 USDC) via signature hors chaîne sans ETH.
- **Interopérabilité Omnichain LayerZero V2 (`Base` ↔ `Solana`)** : Hub EVM Solidity (`OFTAdapter`) synchronisé avec un programme SPL natif en Rust/Anchor sur Solana.

## Contrats & Programmes Déployés (Testnets)

### Base Sepolia (Chain ID: `84532` | LayerZero EID: `40245`)

| Contrat | Adresse | Détails |
| :--- | :--- | :--- |
| **`OmniPepeVault` (`$oPEPE`)** | `0x0592170d7b70cb5c1f5b421a45d6648c3fba662d` | Coffre ERC-4626 + EIP-2612 Permit |
| **`OmniPepeOFTAdapter`** | `0xD72b42CF147c6c3FC6e6E31817c2C937843738DE` | Adaptateur Omnichain LayerZero V2 |
| **`AiQuantumWotsStrategy`** | `0x427425Fd3111a1ccadd1FF38A5B6aCa8A4aBDF46` | Vérificateur WOTS+ Post-Quantique (Yul) |
| **`OmniPepeGasManager`** | `0x654369f131f31A8A4fE1445E61c6698477bF8555` | Rechargement automatique 10 USDC M2M |

### Solana Devnet (LayerZero EID: `40168`)

| Composant | Adresse Base58 | Détails |
| :--- | :--- | :--- |
| **Programme OFT (Rust / Anchor)** | `AJ548vhTT1hHF7PsYafFNRJur1KSbFhtaVbfTWgXeMqY` | Exécutable BPF optimisé (`opt-level="z"`, LTO) |
| **`OFTStore` (PDA)** | `F5HxDxsUaZTgeeDX1waUEvru6iGfbXK9hRv5iyuUNhJZ` | Autorité exclusive d'émission & configuration ULN |
| **Mint SPL (`$oPEPE`)** | `APfwA7jxDBur8UefqGWwXo1zx24hQ8rWjAVm6h9KZ2bS` | Jeton SPL 6 décimales partagées (Freeze désactivé) |
| **DVN Config PDA (LayerZero Labs)** | `6PW6tBKu9rQVKL8TiYV7BhmAxviHau68LfBAvRdmmPhE` | Vérificateur décentralisé configuré |

## Structure du Dépôt
- `src/` : Contrats intelligents Solidity (`OmniPepeVault`, `OmniPepeOFTAdapter`, `OmniPepeOFT`, `AiQuantumWotsStrategy`, `OmniPepeGasManager`).
- `test/` : Tests unitaires, fuzzing et sécurité Foundry.
- `solana-oft/` : Programme Rust Anchor (`programs/oft`) et scripts TypeScript Umi/LayerZero V2.
- `*.py` : Scripts d'agents M2M, génération d'arbres de Merkle WOTS+ et relais sans gaz.
