import 'dotenv/config'
import { PublicKey } from '@solana/web3.js'
import { createUmi } from '@metaplex-foundation/umi-bundle-defaults'
import { createSignerFromKeypair, signerIdentity, publicKey, transactionBuilder } from '@metaplex-foundation/umi'
import { oft } from '@layerzerolabs/oft-v2-solana-sdk'
import { SetConfigType } from '@layerzerolabs/lz-solana-sdk-v2'
import { EndpointId } from '@layerzerolabs/lz-definitions'
import fs from 'fs'

async function main() {
    const rpc = 'https://' + 'api.devnet.' + 'solana.com'
    const umi = createUmi(rpc)
    const secret = JSON.parse(fs.readFileSync(process.env.HOME + '/.config/solana/id.json', 'utf8'))
    const kp = umi.eddsa.createKeypairFromSecretKey(Uint8Array.from(secret))
    const admin = createSignerFromKeypair(umi, kp)
    umi.use(signerIdentity(admin))

    const oftStore = publicKey('F5HxDxsUaZTgeeDX1waUEvru6iGfbXK9hRv5iyuUNhJZ')
    const remoteEid = EndpointId.BASESEP_V2_TESTNET // 40245

    // Derivation du PDA DvnConfig officiel LayerZero Labs Devnet
    const dvnProgram = new PublicKey('4VDjp6XQaxoZf5RGwiPU9NR1EXSZn2TP4ATMmiSzLfhb')
    const [dvnConfigPda] = PublicKey.findProgramAddressSync([Buffer.from('dvn_config')], dvnProgram)
    console.log('PDA DvnConfig exact :', dvnConfigPda.toBase58())

    const ulnConfig = {
        confirmations: 1n,
        requiredDvnCount: 1,
        optionalDvnCount: 0,
        optionalDvnThreshold: 0,
        requiredDvns: [publicKey(dvnConfigPda.toBase58())],
        optionalDvns: [],
    }

    const tx = transactionBuilder()
        .add(await oft.setConfig(umi.rpc, { signer: admin, oftStore }, { remoteEid, configType: SetConfigType.SEND_ULN, config: ulnConfig }))
        .add(await oft.setConfig(umi.rpc, { signer: admin, oftStore }, { remoteEid, configType: SetConfigType.RECEIVE_ULN, config: ulnConfig }))

    const res = await tx.sendAndConfirm(umi)
    console.log('PDA DVN enregistre ! Signature :', Buffer.from(res.signature).toString('base64'))
}

main().catch(console.error)
