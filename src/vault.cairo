use starknet::ContractAddress;

#[abi]
trait IVault {
    fn deposit(amount: u256);
    fn withdraw(shares: u256);
    fn balance_of(account: ContractAddress) -> u256;
    fn total_supply() -> u256;
}

#[contract]
mod Vault {
    // use openzeppelin::token::erc20::IERC20;
    // use openzeppelin::token::erc20::IERC20Dispatcher;
    // use openzeppelin::token::erc20::IERC20DispatcherTrait;

    use simple_vault::erc20::IERC20;
    use simple_vault::erc20::IERC20Dispatcher;
    use simple_vault::erc20::IERC20DispatcherTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use traits::Into;
    use debug::PrintTrait;

    struct Storage {
        _token: ContractAddress,
        _total_supply: u256,
        _balances: LegacyMap<ContractAddress, u256>,
    }

    #[constructor]
    fn constructor(token: ContractAddress) {
        _token::write(token)
    }

    #[external]
    fn deposit(amount: u256) {
        // a = amount
        // B = balance of token before deposit
        // T = total supply
        // s = shares to mint

        // (T + s) / T = (a + B) / B

        // s = aT / B

        let shares = if _total_supply::read() == 0.into() {
            amount
        } else {
            amount * _total_supply::read() / _erc20_dispatcher().balance_of(get_contract_address())
        };

        _mint(get_caller_address(), shares);
        _erc20_dispatcher().transfer_from(get_caller_address(), get_contract_address(), amount);
    }

    #[external]
    fn withdraw(shares: u256) {
        // a = amount
        // B = balance of token before withdraw
        // T = total supply
        // s = shares to burn

        // (T - s) / T = (B - a) / B

        // a = sB / T
        let amount: u256 = (shares * _erc20_dispatcher().balance_of(get_contract_address()))
            / _total_supply::read();
        _burn(get_caller_address(), shares);
        _erc20_dispatcher().transfer(get_caller_address(), amount);
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        _balances::read(account)
    }

    #[view]
    fn total_supply() -> u256 {
        _total_supply::read()
    }

    fn _mint(to: ContractAddress, shares: u256) {
        _total_supply::write(_total_supply::read() + shares);
        _balances::write(to, _balances::read(to) + shares);
    }

    fn _burn(from: ContractAddress, shares: u256) {
        _total_supply::write(_total_supply::read() - shares);
        _balances::write(from, _balances::read(from) - shares);
    }

    #[inline(always)]
    fn _erc20_dispatcher() -> IERC20Dispatcher {
        IERC20Dispatcher { contract_address: _token::read() }
    }
}

