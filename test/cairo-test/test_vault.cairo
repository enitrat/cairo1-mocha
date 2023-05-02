use starknet::syscalls::deploy_syscall;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::contract_address::contract_address_const;
use starknet::ContractAddress;
use starknet::testing;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use result::ResultTrait;
use array::ArrayTrait;
use debug::PrintTrait;

use simple_vault::vault::Vault;
use simple_vault::vault::IVaultDispatcher;
use simple_vault::vault::IVaultDispatcherTrait;
use openzeppelin::token::erc20::ERC20;
use openzeppelin::token::erc20::IERC20Dispatcher;
use openzeppelin::token::erc20::IERC20DispatcherTrait;

fn setup() -> (ContractAddress, ContractAddress) {
    // Set up.

    // Deploy token.

    let user1 = contract_address_const::<0x123456789>();

    let mut calldata = ArrayTrait::new();
    let name = 'TOKEN_A';
    let symbol = 'TKNA';
    let initial_supply_low = 100;
    let initial_supply_high = 0;
    let recipient: felt252 = user1.into();
    calldata.append(name);
    calldata.append(symbol);
    calldata.append(initial_supply_low);
    calldata.append(initial_supply_high);
    calldata.append(recipient);

    let (token_address, _) = deploy_syscall(
        ERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append(token_address.into());
    let (vault_address, _) = deploy_syscall(
        Vault::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    (token_address, vault_address)
}

#[test]
#[available_gas(200000000)]
fn test_should_mint_50_shares() {
    let (token_address, vault_address) = setup();
    let user1 = contract_address_const::<0x123456789>();
    let token = IERC20Dispatcher { contract_address: token_address };
    let vault = IVaultDispatcher { contract_address: vault_address };
    let amount: u256 = 50.into();

    testing::set_contract_address(user1); // `caller_address` in contract will return
    // `user1` instead of `0`.
    token.approve(vault_address, amount);
    vault.deposit(amount);

    let total_supply = vault.total_supply();
    assert(total_supply == amount, 'total supply doesnt match');

    let erc20_balance_vault = token.balance_of(vault_address);
    assert(erc20_balance_vault == amount, 'erc20 balance doesnt match');

    let user_token_balance = token.balance_of(user1);
    assert(user_token_balance == 50.into(), 'user token balance doesnt match');
}

#[test]
#[available_gas(200000000)]
fn test_withdraw_50_shares() {
    // Deposit tokens
    let (token_address, vault_address) = setup();
    let user1 = contract_address_const::<0x123456789>();
    let token = IERC20Dispatcher { contract_address: token_address };
    let vault = IVaultDispatcher { contract_address: vault_address };
    let amount: u256 = 50.into();

    //First, deposit tokens
    testing::set_contract_address(user1); // `caller_address` in contract will return
    // `user1` instead of `0`.
    token.approve(vault_address, amount);
    vault.deposit(amount);

    // Then, withdraw tokens
    vault.withdraw(amount);

    let total_supply: u256 = vault.total_supply();
    assert(total_supply == 0.into(), 'total supply doesnt match');
    let erc20_balance_vault = token.balance_of(vault_address);
    assert(erc20_balance_vault == 0.into(), 'vault balance doesnt match');
    let erc20_balance_user = token.balance_of(user1);
    assert(erc20_balance_user == 100.into(), 'user balance doesnt match');
}

#[test]
#[available_gas(200000000)]
fn test_mint() {
    let token = contract_address_const::<0x987>();
    let user = contract_address_const::<0x123>();
    Vault::constructor(token);
    Vault::_mint(user, 100.into());

    let user_balance = Vault::balance_of(user);
    let total_supply = Vault::total_supply();

    assert(user_balance == 100.into(), 'user balance is not correct');
    assert(total_supply == 100.into(), 'total supply is not correct');
}
