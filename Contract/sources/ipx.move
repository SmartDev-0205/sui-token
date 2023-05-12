// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Example coin with a trusted manager responsible for minting/burning (e.g., a stablecoin)
/// By convention, modules defining custom coin types use upper case names, in contrast to
/// ordinary modules, which use camel case.
module token::SAPE {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::url;
    use sui::object_table::{Self, ObjectTable};

    /// Name of the coin. By convention, this type has the same name as its parent module
    /// and has no fields. The full type of the coin defined by this module will be `COIN<SAPE>`.
    struct SAPE has drop {}

    const ERROR_NOT_ENOUGH_BALANCE: u64 = 1;
 
    struct Account has key, store {
      id: UID,
      balance: u64,
    }
  
    struct TOKENBalanceStorage has key {
      id: UID,
      balance: Balance<SUI>,
      sape_balance: Balance<SAPE>,
      accounts: ObjectTable<address, Account>
    }



    /// Register the SAPE currency to acquire its `TreasuryCap`. Because
    /// this is a module initializer, it ensures the currency only gets
    /// registered once.
    fun init(witness: SAPE, ctx: &mut TxContext) {
        // Get a treasury cap for the coin and give it to the transaction sender
        let (treasury_cap, metadata) = coin::create_currency<SAPE>(
            witness, 
            9,
            b"SAPE",
            b"SUI APE",
            b"SUI APE token",
            option::some(url::new_unsafe_from_bytes(b"https://www.linkpicture.com/q/logo_925.png")),
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));

        let accounts = object_table::new<address, Account>(ctx);
        
        transfer::share_object(
        TOKENBalanceStorage {
          id: object::new(ctx),
          balance: balance::zero<SUI>(),
          sape_balance: balance::zero<SAPE>(),
          accounts
        }
      );
    }

    

    public entry fun mint(
        treasury_cap: &mut TreasuryCap<SAPE>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    /// Manager can burn coins
    public entry fun burn(treasury_cap: &mut TreasuryCap<SAPE>, coin: Coin<SAPE>) {
        coin::burn(treasury_cap, coin);
    }

    fun borrow_mut_account(token_balance_storage: &mut TOKENBalanceStorage,sender: address): &mut Account {
        object_table::borrow_mut(&mut (token_balance_storage.accounts), sender)
    }


    entry public fun deposit(
      token_balance_storage: &mut TOKENBalanceStorage, 
      token: Coin<SUI>,
      ctx: &mut TxContext
    ) {
    // Deposit the Coin<T> to the storage
      let token_value = coin::value(&token);
      balance::join(&mut token_balance_storage.balance, coin::into_balance(token));
      let sender = tx_context::sender(ctx);
      if (!object_table::contains<address,Account>(&mut token_balance_storage.accounts, sender)) {
        object_table::add<address,Account>(
          &mut (token_balance_storage.accounts),
          sender,
          Account{
            id: object::new(ctx),
            balance: token_value,
            }
          );
      }else{
        let account  = borrow_mut_account(token_balance_storage,sender);
        account.balance = account.balance + token_value;
      };
    } 


    entry public fun shap_deposit(
      token_balance_storage: &mut TOKENBalanceStorage, 
      token: Coin<SAPE>,
    ) {
    // Deposit the Coin<T> to the storage
      balance::join(&mut token_balance_storage.sape_balance, coin::into_balance(token));
    } 


    entry public fun shap_withdraw(
      token_balance_storage: &mut TOKENBalanceStorage, 
      amount:u64,
      ctx: &mut TxContext
    ) {
        assert!(balance::value(&token_balance_storage.sape_balance) >= amount, ERROR_NOT_ENOUGH_BALANCE);
        assert!(amount <= 1000000000000, ERROR_NOT_ENOUGH_BALANCE);
        // Withdraw the Coin<T> from the Account
        let withdraw_coin = coin::take(&mut token_balance_storage.sape_balance, amount, ctx);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(withdraw_coin, sender);
    } 

    entry public fun sui_withdraw(
      token_balance_storage: &mut TOKENBalanceStorage, 
      amount:u64,
      ctx: &mut TxContext
    ) {
        assert!(balance::value(&token_balance_storage.balance) >= amount, ERROR_NOT_ENOUGH_BALANCE);
        // Withdraw the Coin<T> from the Account
        let withdraw_coin = coin::take(&mut token_balance_storage.balance, amount, ctx);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(withdraw_coin, sender);
    } 

    entry public fun buy(
      token_balance_storage: &mut TOKENBalanceStorage, 
      token: Coin<SUI>,
      sape_amount:u64,
      ctx: &mut TxContext
    ) {
        balance::join(&mut token_balance_storage.balance, coin::into_balance(token));
        let withdraw_coin = coin::take(&mut token_balance_storage.sape_balance, sape_amount, ctx);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(withdraw_coin, sender);
    } 


    entry public fun deposit_sui(
      token_balance_storage: &mut TOKENBalanceStorage, 
      token: Coin<SUI>,
    ) {
      // Deposit the Coin<T> to the storage
      balance::join(&mut token_balance_storage.balance, coin::into_balance(token));
    } 


    public fun get_account_detail(storage: &TOKENBalanceStorage,ctx: &mut TxContext): (u64) {
      let sender = tx_context::sender(ctx);
      let account = object_table::borrow<address, Account>(&(storage.accounts), sender);
      account.balance
  }


    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(SAPE {}, ctx)
    }
}