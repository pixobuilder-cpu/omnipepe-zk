import os, time
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
VAULT_ADDR = Web3.to_checksum_address(os.environ["OMNI_VAULT"])
PEPE_ADDR = Web3.to_checksum_address(os.environ["MOCK_PEPE"])
GAS_MGR_ADDR = Web3.to_checksum_address(os.environ["GAS_MANAGER"])

ABI = [
    {"name": "approve", "type": "function", "inputs": [{"name": "s", "type": "address"}, {"name": "a", "type": "uint256"}], "outputs": [{"type": "bool"}]},
    {"name": "balanceOf", "type": "function", "inputs": [{"name": "a", "type": "address"}], "outputs": [{"type": "uint256"}]},
    {"name": "nonces", "type": "function", "inputs": [{"name": "o", "type": "address"}], "outputs": [{"type": "uint256"}]},
    {"name": "deposit", "type": "function", "inputs": [{"name": "assets", "type": "uint256"}, {"name": "receiver", "type": "address"}], "outputs": [{"type": "uint256"}]}
]
pepe = w3.eth.contract(address=PEPE_ADDR, abi=ABI)
vault = w3.eth.contract(address=VAULT_ADDR, abi=ABI)

def send_tx(fn):
    tx = fn.build_transaction({"from": relayer.address, "nonce": w3.eth.get_transaction_count(relayer.address), "gas": 300000, "gasPrice": w3.eth.gas_price, "chainId": 84532})
    rcpt = w3.eth.wait_for_transaction_receipt(w3.eth.send_raw_transaction(w3.eth.account.sign_transaction(tx, relayer.key).raw_transaction))
    return rcpt.transactionHash.hex()

stealth = Account.create()
print("1. Agent Furtif M2M :", stealth.address)
amt = 5_000_000 * 10**18
print("2. Approbation PEPE :", send_tx(pepe.functions.approve(VAULT_ADDR, amt)))
print("3. Depot $oPEPE     :", send_tx(vault.functions.deposit(amt, stealth.address)))
print("4. Solde $oPEPE     :", vault.functions.balanceOf(stealth.address).call() // 10**18)

dl = int(time.time()) + 3600
data = {
    "types": {"EIP712Domain": [{"name": "name", "type": "string"}, {"name": "version", "type": "string"}, {"name": "chainId", "type": "uint256"}, {"name": "verifyingContract", "type": "address"}], "Permit": [{"name": "owner", "type": "address"}, {"name": "spender", "type": "address"}, {"name": "value", "type": "uint256"}, {"name": "nonce", "type": "uint256"}, {"name": "deadline", "type": "uint256"}]},
    "primaryType": "Permit",
    "domain": {"name": "OmniPepe zk", "version": "1", "chainId": 84532, "verifyingContract": VAULT_ADDR},
    "message": {"owner": stealth.address, "spender": GAS_MGR_ADDR, "value": 1_500_000 * 10**18, "nonce": vault.functions.nonces(stealth.address).call(), "deadline": dl}
}
sig = Account.sign_typed_data(stealth.key, full_message=data)
print("5. Signature Permit EIP-712 OK (v=" + str(sig.v) + ")")
