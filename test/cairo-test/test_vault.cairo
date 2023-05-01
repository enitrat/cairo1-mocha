use starknet::testing;
use simple_vault::vault::Vault;
use starknet::contract_address::contract_address_const;
use traits::Into;


#[test]
#[available_gas(20000000)]
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
