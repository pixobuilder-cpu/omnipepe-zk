import 'dotenv/config'
import { createUmi } from '@metaplex-foundation/umi-bundle-defaults'
import { createSignerFromKeypair, signerIdentity, publicKey, transactionBuilder } from '@metaplex-foundation/umi'
import { oft } from '@layerzerolabs/oft-v2-solana-sdk'
import { EndpointId } from '@layerzerolabs/lz-definitions'
import fs from 'fs'

async function main() {
    const rpc = 'https://' + 'api.devnet.' + 'solana.com'
    const umi = createUmi(rpc)
    const secret = JSON.parse(fs.readFileSync(process.env.HOME + '/.config/solana/id.json', 'utf8'))
    const kp = umi.eddsa.createKeypairFromSecretKey(Uint8Array.from(secret))
    const admin = createSignerFromKeypair(umi, kp)
    umi.use(signerIdentity(admin))

    const programId = publicKey('AJ548vhTT1hHF7PsYafFNRJur1KSbFhtaVbfTWgXeMqY')
    const oftStore = publicKey('F5HxDxsUaZTgeeDX1waUEvru6iGfbXK9hRv5iyuUNhJZ')
    const remoteEid = EndpointId.BASESEP_V2_TESTNET // 40245

    // DVN officiel LayerZero Labs sur Solana Devnet
    const lzDvn = publicKey('4g2FbGr3q3T11c211111111111111111111111111111')
    console.log('Configuration des options enforces Solana -> Base Sepolia...')
    const tx = transactionBuilder().add(
        oft.setPeerConfig(
            { admin, oftStore },
            { __kind: 'EnforcedOptions', send: new Uint8Array([0, 3, 1, 0, 17, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 56, 128]), sendAndCall: new Uint8Array([0, 3]), remote: remoteEid },
            programId
        )
    )
    const res = await tx.sendAndConfirm(umi)
    console.log('Options configurees ! Signature :', Buffer.from(res.signature).toString('base64'))
}

main().catch(console.error)
