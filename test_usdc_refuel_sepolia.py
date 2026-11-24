import os, json, time
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
USDC_ADDR = Web3.to_checksum_address(os.environ["MOCK_USDC"])
VAULT_ADDR = Web3.to_checksum_address(os.environ["OMNI_VAULT"])
WETH_ADDR = Web3.to_checksum_address("0x4200000000000000000000000000000000000006")

def load_art(name):
    with open(f"out/{name}.sol/{name}.json") as f: return json.load(f)

def send_tx(tx_dict):
    tx_dict.update({"from": relayer.address, "nonce": w3.eth.get_transaction_count(relayer.address), "chainId": 84532})
    signed = w3.eth.account.sign_transaction(tx_dict, relayer.key)
    return w3.eth.wait_for_transaction_receipt(w3.eth.send_raw_transaction(signed.raw_transaction))

art_swap = load_art("MockSwapRouter")
swap_addr = send_tx(w3.eth.contract(abi=art_swap["abi"], bytecode=art_swap["bytecode"]["object"]).constructor(USDC_ADDR).build_transaction({"gas": 800000})).contractAddress
print("1. MockSwapRouter deploye :", swap_addr)

ERC20_ABI = [
    {"name": "transfer", "type": "function", "inputs": [{"name": "to", "type": "address"}, {"name": "a", "type": "uint256"}], "outputs": [{"type": "bool"}]},
    {"name": "approve", "type": "function", "inputs": [{"name": "s", "type": "address"}, {"name": "a", "type": "uint256"}], "outputs": [{"type": "bool"}]},
    {"name": "balanceOf", "type": "function", "inputs": [{"name": "a", "type": "address"}], "outputs": [{"type": "uint256"}]},
    {"name": "nonces", "type": "function", "inputs": [{"name": "o", "type": "address"}], "outputs": [{"type": "uint256"}]},
    {"name": "deposit", "type": "function", "inputs": [{"name": "assets", "type": "uint256"}, {"name": "receiver", "type": "address"}], "outputs": [{"type": "uint256"}]}
]
usdc = w3.eth.contract(address=USDC_ADDR, abi=ERC20_ABI)
pepe = w3.eth.contract(address=PEPE_ADDR, abi=ERC20_ABI)
vault = w3.eth.contract(address=VAULT_ADDR, abi=ERC20_ABI)
send_tx(usdc.functions.transfer(swap_addr, 10_000 * 10**6).build_transaction({"gas": 100000}))

art_gm = load_art("OmniPepeGasManager")
gm_addr = send_tx(w3.eth.contract(abi=art_gm["abi"], bytecode=art_gm["bytecode"]["object"]).constructor(VAULT_ADDR, USDC_ADDR, WETH_ADDR, swap_addr).build_transaction({"gas": 1200000})).contractAddress
gm = w3.eth.contract(address=gm_addr, abi=art_gm["abi"])
print("2. GasManager deploye     :", gm_addr)

agent = Account.create()
amt = 5_000_000 * 10**18
send_tx(pepe.functions.approve(VAULT_ADDR, amt).build_transaction({"gas": 100000}))
send_tx(vault.functions.deposit(amt, agent.address).build_transaction({"gas": 200000}))
print("3. Agent furtif credite   :", agent.address, "| $oPEPE:", vault.functions.balanceOf(agent.address).call() // 10**18)

dl, max_sp, fee = int(time.time()) + 3600, 1_500_000 * 10**18, 10_000 * 10**18
permit_data = {
    "types": {"EIP712Domain": [{"name": "name", "type": "string"}, {"name": "version", "type": "string"}, {"name": "chainId", "type": "uint256"}, {"name": "verifyingContract", "type": "address"}], "Permit": [{"name": "owner", "type": "address"}, {"name": "spender", "type": "address"}, {"name": "value", "type": "uint256"}, {"name": "nonce", "type": "uint256"}, {"name": "deadline", "type": "uint256"}]},
    "primaryType": "Permit",
    "domain": {"name": "OmniPepe zk", "version": "1", "chainId": 84532, "verifyingContract": VAULT_ADDR},
    "message": {"owner": agent.address, "spender": gm_addr, "value": max_sp, "nonce": vault.functions.nonces(agent.address).call(), "deadline": dl}
}
sig = Account.sign_typed_data(agent.key, full_message=permit_data)
rcpt = send_tx(gm.functions.refuelAgentUsdcWithPermit(agent.address, max_sp, fee, dl, sig.v, sig.r.to_bytes(32, "big"), sig.s.to_bytes(32, "big")).build_transaction({"gas": 400000}))

print("4. Tx Refuel 10 USDC      :", rcpt.transactionHash.hex())
print("5. Solde USDC final agent :", usdc.functions.balanceOf(agent.address).call() / 10**6, "USDC (ETH:", w3.eth.get_balance(agent.address), ")")
print("6. Solde $oPEPE restant   :", vault.functions.balanceOf(agent.address).call() // 10**18, "oPEPE")
