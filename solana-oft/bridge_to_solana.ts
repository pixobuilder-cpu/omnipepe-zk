import 'dotenv/config'
import { ethers } from 'ethers'
import { PublicKey } from '@solana/web3.js'
import { Options } from '@layerzerolabs/lz-v2-utilities'
import fs from 'fs'

async function main() {
    const rpc = 'https://' + 'sepolia.' + 'base.org'
    const provider = new ethers.providers.JsonRpcProvider(rpc)
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider)

    const pepeAddr = '0xf1b5e5e964f071ff2ca9abf08d7036f8f75ba0d3'
    const vaultAddr = '0x0592170d7b70cb5c1f5b421a45d6648c3fba662d'
    const adapterAddr = '0xD72b42CF147c6c3FC6e6E31817c2C937843738DE'
    const solanaRecipient = new PublicKey('42NzibXcpvW3ZsjcssuTgLLEBHh3fp9CfPUitwRD4aBt')
    const toBytes32 = '0x' + solanaRecipient.toBuffer().toString('hex')

    const erc20Abi = [
        'function approve(address spender, uint256 amount) external returns (bool)',
        'function deposit(uint256 assets, address receiver) external returns (uint256)',
        'function balanceOf(address owner) external view returns (uint256)'
    ]
    const adapterArt = JSON.parse(fs.readFileSync('deployments/base-sepolia/OmniPepeOFTAdapter.json', 'utf8'))

    const pepe = new ethers.Contract(pepeAddr, erc20Abi, wallet)
    const vault = new ethers.Contract(vaultAddr, erc20Abi, wallet)
    const adapter = new ethers.Contract(adapterAddr, adapterArt.abi, wallet)

    const amount = ethers.utils.parseUnits('100', 18) // 100 $oPEPE

    console.log('1. Preparation de 100 $oPEPE sur Base Sepolia...')
    await (await pepe.approve(vaultAddr, amount)).wait()
    await (await vault.deposit(amount, wallet.address)).wait()
    await (await vault.approve(adapterAddr, amount)).wait()

    // Options d'execution Solana : 200 000 CU + 0.00203928 SOL (2039280 lamports) pour l'ATA SPL
    const extraOptions = Options.newOptions().addExecutorLzReceiveOption(200000, 2039280).toHex()

    const sendParam = {
        dstEid: 40168, // Solana Devnet
        to: toBytes32,
        amountLD: amount,
        minAmountLD: amount,
        extraOptions,
        composeMsg: '0x',
        oftCmd: '0x'
    }

    console.log('2. Estimation des frais LayerZero V2 (quoteSend)...')
    const [nativeFee] = await adapter.quoteSend(sendParam, false)
    console.log('   -> Frais relais Base -> Solana :', ethers.utils.formatEther(nativeFee), 'ETH')

    console.log('3. Envoi omnichain de 100 $oPEPE vers Solana Devnet...')
    const tx = await adapter.send(sendParam, { nativeFee, lzTokenFee: 0 }, wallet.address, { value: nativeFee })
    const receipt = await tx.wait()
    console.log('   -> SUCCES ! Tx Hash Base Sepolia :', receipt.transactionHash)
    console.log('   -> Destinataire Solana Devnet     :', solanaRecipient.toBase58())
}

main().catch(console.error)
