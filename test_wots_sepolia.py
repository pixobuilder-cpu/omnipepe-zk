import os, json
from web3 import Web3
from eth_account import Account

with open(".env") as f:
    for line in f:
        if "=" in line and not line.startswith("#"):
            k, v = line.strip().split("=", 1)
            os.environ[k] = v

rpc = "https://" + "sepolia." + "base.org"
w3 = Web3(Web3.HTTPProvider(rpc))
relayer = Account.from_key(os.environ["PRIVATE_KEY"])
PEPE_ADDR = Web3.to_checksum_address(os.environ["MOCK_PEPE"])
VAULT_ADDR = Web3.to_checksum_address(os.environ["OMNI_VAULT"])

with open("out/AiQuantumWotsStrategy.sol/AiQuantumWotsStrategy.json") as f:
    artifact = json.load(f)

def send_tx(tx_dict):
    tx_dict.update({"from": relayer.address, "nonce": w3.eth.get_transaction_count(relayer.address), "chainId": 84532})
    signed = w3.eth.account.sign_transaction(tx_dict, relayer.key)
    return w3.eth.wait_for_transaction_receipt(w3.eth.send_raw_transaction(signed.raw_transaction))

# 1. Generation cles WOTS+ (nonce 0) et Arbre de Merkle
priv0, pub0 = [], []
for i in range(64):
    sk = Web3.keccak(text=f"omnipepe-quantum-secret-0-{i}")
    priv0.append(sk)
    acc = sk
    for step in range(15):
        acc = Web3.keccak(acc + bytes([i, step]))
    pub0.append(acc)

leaf0 = Web3.keccak((0).to_bytes(32, "big") + Web3.keccak(b"".join(pub0)))
leaf1 = Web3.keccak((1).to_bytes(32, "big") + Web3.keccak(text="backup-quantum-leaf-1"))
root = Web3.keccak(leaf0 + leaf1) if leaf0 < leaf1 else Web3.keccak(leaf1 + leaf0)
print("1. Racine Merkle WOTS+ :", "0x" + root.hex())

# 2. Deploiement AiQuantumWotsStrategy sur Base Sepolia
Factory = w3.eth.contract(abi=artifact["abi"], bytecode=artifact["bytecode"]["object"])
rcpt_deploy = send_tx(Factory.constructor(PEPE_ADDR, VAULT_ADDR, root).build_transaction({"gas": 1200000}))
strat_addr = rcpt_deploy.contractAddress
strategy = w3.eth.contract(address=strat_addr, abi=artifact["abi"])
print("2. Strategie WOTS+ deployee :", strat_addr)

# 3. Financement de la strategie avec 500 000 PEPE
ERC20_ABI = [{"name": "transfer", "type": "function", "inputs": [{"name": "to", "type": "address"}, {"name": "a", "type": "uint256"}], "outputs": [{"type": "bool"}]}, {"name": "balanceOf", "type": "function", "inputs": [{"name": "a", "type": "address"}], "outputs": [{"type": "uint256"}]}]
pepe = w3.eth.contract(address=PEPE_ADDR, abi=ERC20_ABI)
send_tx(pepe.functions.transfer(strat_addr, 500_000 * 10**18).build_transaction({"gas": 100000}))

# 4. Signature post-quantique WOTS+ (64 blocs)
target = Web3.to_checksum_address("0x000000000000000000000000000000000000dEaD")
amount = 100_000 * 10**18
msg_hash = Web3.solidity_keccak(["address", "uint256", "address", "uint256"], [strat_addr, 0, target, amount])
msg_int = int.from_bytes(msg_hash, "big")

sig_blocks = []
for i in range(64):
    nibble = (msg_int >> ((63 - i) * 4)) & 0x0F
    acc = priv0[i]
    for step in range(nibble):
        acc = Web3.keccak(acc + bytes([i, step]))
    sig_blocks.append(acc)

# 5. Envoi sur Base Sepolia
rcpt_exec = send_tx(strategy.functions.executeQuantumStrategy(target, amount, sig_blocks, [leaf1]).build_transaction({"gas": 600000}))
print("3. Tx WOTS+ executee   :", rcpt_exec.transactionHash.hex())
print("4. Gaz reel consomme   :", rcpt_exec.gasUsed)
print("5. Nouveau Nonce WOTS+ :", strategy.functions.currentNonce().call())
print("6. PEPE recus par cible:", pepe.functions.balanceOf(target).call() // 10**18)
