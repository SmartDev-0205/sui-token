// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

import "./App.css";
import { ConnectButton, useWalletKit } from "@mysten/wallet-kit";
import { TransactionBlock } from "@mysten/sui.js";
import { useGetAccountInfo } from "./hooks";
import { OBJECT_RECORD } from "./config";
import { useReducer } from "react";

const ONESUI = 1000000000;
function App() {
  const { currentAccount, signAndExecuteTransactionBlock } = useWalletKit();

  const [forceUpdate] = useReducer((x) => x + 1, 0);

  const update = () => {
    setTimeout(() => {
      console.log("Starting update");
      forceUpdate();
    }, 5000);
  };

  const accountBalance = useGetAccountInfo(
    currentAccount?.address || OBJECT_RECORD.AddressZero
  );
  console.log("Account balance===>", accountBalance);

  const deposit = async () => {
    const txb = new TransactionBlock();
    const [coin] = txb.splitCoins(txb.gas, [txb.pure(ONESUI)]);
    console.log("-------------Starting Deposit-----------------");
    const packageObjectId = OBJECT_RECORD.PACKAGEID;
    txb.moveCall({
      target: `${packageObjectId}::SAPE::deposit`,
      arguments: [txb.object(OBJECT_RECORD.TOKENBalanceStorage), coin],
      typeArguments: [],
    });
    txb.setGasBudget(300000000);
    const tx = await signAndExecuteTransactionBlock({
      transactionBlock: txb,
      requestType: "WaitForEffectsCert",
      options: { showEffects: true },
    });
    console.log(tx);
  };

  const Withdraw = async () => {
    const txb = new TransactionBlock();
    console.log("-------------Starting Withdraw--------------");
    const packageObjectId = OBJECT_RECORD.PACKAGEID;
    txb.moveCall({
      target: `${packageObjectId}::SAPE::sui_withdraw`,
      arguments: [
        txb.object(OBJECT_RECORD.TOKENBalanceStorage),
        txb.pure(ONESUI),
      ],
      typeArguments: [],
    });
    txb.setGasBudget(300000000);
    const tx = await signAndExecuteTransactionBlock({
      transactionBlock: txb,
      requestType: "WaitForEffectsCert",
      options: { showEffects: true },
    });
    console.log(tx);
  };

  return (
    <div className="App">
      <div className="content">
        <ConnectButton />
        <div className="balance-block">
          <label htmlFor="balance-input">My Balance:</label>
          <input
            name="name"
            id="balance-input"
            type="text"
            value={accountBalance}
            readOnly
          />
        </div>
        <div className="action-block">
          <button onClick={deposit}>Deposit 1 SUI</button>

          <button onClick={Withdraw}>Withdraw 1 SUI</button>
        </div>
      </div>
    </div>
  );
}

export default App;
