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
    const peerAddress = Uint8Array.from(Buffer.from('000000000000000000000000d72b42cf147c6c3fc6e6e31817c2c937843738de', 'hex'))

    console.log('1. Initialisation des comptes LayerZero pour Base Sepolia (40245)...')
    let tx = transactionBuilder()
        .add(oft.initSendLibrary({ admin, oftStore }, remoteEid))
        .add(oft.initReceiveLibrary({ admin, oftStore }, remoteEid))
        .add(await oft.initConfig({ admin, oftStore, payer: admin }, remoteEid))
        .add(oft.setPeerConfig({ admin, oftStore }, { __kind: 'PeerAddress', peer: peerAddress, remote: remoteEid }, programId))

    const res = await tx.sendAndConfirm(umi)
    console.log('   -> Pont Solana <-> Base Sepolia active ! Signature :', Buffer.from(res.signature).toString('base64'))
}

main().catch(console.error)
