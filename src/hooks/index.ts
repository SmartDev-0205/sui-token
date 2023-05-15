import { TransactionBlock } from '@mysten/sui.js';
import { bcsForVersion } from '@mysten/sui.js';
import { OBJECT_RECORD } from "../config"
import { useMemo, useState } from 'react';
import { Connection, JsonRpcProvider } from "@mysten/sui.js";

const getProvider = () => {
    return new JsonRpcProvider(
        new Connection({
            fullnode: "https://wallet-rpc.testnet.sui.io/",
            websocket: "wss://fullnode.testnet.sui.io:443",
            faucet: "https://faucet.testnet.sui.io/gas",
        }))
}

export const useGetAccountInfo = (account: string) => {

    const [data, setdata] = useState<number>(0);

    useMemo(() => {
        const getAccount = async () => {
            const txb = new TransactionBlock();
            txb.moveCall({
                target: `${OBJECT_RECORD.PACKAGEID}::SAPE::get_account_detail`,
                arguments: [
                    txb.object(OBJECT_RECORD.TOKENBalanceStorage),
                ],
                typeArguments: [],
            });
            let provider = getProvider();
            const result = await provider.devInspectTransactionBlock({
                transactionBlock: txb,
                sender: account || OBJECT_RECORD.AddressZero,
            });

            if (result!["results"]){

                const returnValues = result!["results"]![0]!["returnValues"];
                let balance = bcsForVersion(await provider.getRpcApiVersion()).de(
                    returnValues![0]![1],
                    Uint8Array.from(returnValues![0]![0])
                );
    

                console.log("Account -----",balance);
                setdata(balance);
            }else{
                
                setdata(0);
            }
        }
        getAccount()
    }, [account])

    return data;
};
