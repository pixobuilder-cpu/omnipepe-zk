// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AiQuantumWotsStrategy is Ownable {
    IERC20 public immutable pepeToken;
    address public immutable vault;
    bytes32 public merkleRoot;
    uint256 public currentNonce;

    event QuantumActionExecuted(uint256 indexed nonce, address indexed target, uint256 amount);

    constructor(address _pepe, address _vault, bytes32 _root) Ownable(msg.sender) {
        pepeToken = IERC20(_pepe); vault = _vault; merkleRoot = _root;
    }

    function totalManagedAssets() external view returns (uint256) {
        return pepeToken.balanceOf(address(this));
    }

    function withdrawToVault(uint256 amount) external {
        require(msg.sender == vault, "Uniquement coffre-fort");
        pepeToken.transfer(vault, amount);
    }

    function executeQuantumStrategy(
        address target,
        uint256 amount,
        bytes32[64] calldata wotsSig,
        bytes32[] calldata merkleProof
    ) external {
        bytes32 msgHash = keccak256(abi.encodePacked(address(this), currentNonce, target, amount));
        bytes32 wotsPubKeyHash;

        assembly {
            // Pointeur libre pour stocker les 64 blocs reconstitues (2048 octets)
            let pubKeyPtr := mload(0x40)
            let sigOffset := wotsSig

            for { let i := 0 } lt(i, 64) { i := add(i, 1) } {
                // Extraction du nibble (4 bits) correspondant a l'index i
                let shift := mul(sub(63, i), 4)
                let nibble := and(shr(shift, msgHash), 0x0f)

                // Chargement direct depuis calldata sans copie intermediaire
                let acc := calldataload(add(sigOffset, mul(i, 32)))

                for { let step := nibble } lt(step, 15) { step := add(step, 1) } {
                    // Ecriture sur place dans la scratch space (0x00..0x22 = 34 octets)
                    mstore(0x00, acc)
                    mstore8(0x20, i)
                    mstore8(0x21, step)
                    acc := keccak256(0x00, 0x22)
                }
                mstore(add(pubKeyPtr, mul(i, 32)), acc)
            }
            // Hachage final de la cle publique complete (64 * 32 = 2048 octets)
            wotsPubKeyHash := keccak256(pubKeyPtr, 2048)
        }

        bytes32 leaf = keccak256(abi.encodePacked(currentNonce, wotsPubKeyHash));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "Signature WOTS+ invalide");

        currentNonce++;
        if (amount > 0 && target != address(0)) {
            pepeToken.transfer(target, amount);
        }
        emit QuantumActionExecuted(currentNonce - 1, target, amount);
    }
}
