import 'dotenv/config'
import 'hardhat-deploy'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'
import './tasks/solana'
import './tasks/solana/initConfig'
import { HardhatUserConfig } from 'hardhat/types'
import { EndpointId } from '@layerzerolabs/lz-definitions'

const PRIVATE_KEY = process.env.PRIVATE_KEY

const config: HardhatUserConfig = {
    solidity: { compilers: [{ version: '0.8.22' }] },
    networks: {
        'base-sepolia': {
            eid: EndpointId.BASESEP_V2_TESTNET,
            url: 'https://' + 'sepolia.' + 'base.org',
            accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
        },
    },
    namedAccounts: { deployer: { default: 0 } },
}

export default config
