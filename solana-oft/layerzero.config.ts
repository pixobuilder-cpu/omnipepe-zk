import { EndpointId } from '@layerzerolabs/lz-definitions'
import { OmniPointHardhat } from '@layerzerolabs/toolbox-hardhat'

const baseSepoliaContract: OmniPointHardhat = {
    eid: EndpointId.BASESEP_V2_TESTNET,
    contractName: 'OmniPepeOFTAdapter',
}

const solanaContract: OmniPointHardhat = {
    eid: EndpointId.SOLANA_V2_TESTNET,
    address: 'F5HxDxsUaZTgeeDX1waUEvru6iGfbXK9hRv5iyuUNhJZ',
}

export default async function () {
    return {
        contracts: [
            { contract: baseSepoliaContract },
            { contract: solanaContract },
        ],
        connections: [
            { from: baseSepoliaContract, to: solanaContract },
            { from: solanaContract, to: baseSepoliaContract },
        ],
    }
}
