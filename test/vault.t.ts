import { deployer, user, vaultFixtures } from "./shared/fixtures";
import { CallData, Contract, GatewayError, uint256 } from "starknet";
import { expect } from "chai";

describe("Vault contract", () => {
  let Vault: Contract;
  let ERC20: Contract;

  before(async () => {
    [Vault, ERC20] = await vaultFixtures();
    Vault.connect(user);
  });

  it("Initial supply should be 0", async () => {
    const initialSupply = await Vault.total_supply();
    expect(initialSupply).to.be.equal(0n);
  });

  it("Should mint 50 shares", async () => {
    const tokensToDeposit = 50n;

    await ERC20.approve(Vault.address, tokensToDeposit);

    const approval = await ERC20.allowance(user.address, Vault.address);

    await Vault.deposit(tokensToDeposit);

    const totalSupply = await Vault.total_supply();
    expect(totalSupply).to.be.equal(tokensToDeposit);

    const erc20_balance_vault = await ERC20.balance_of(Vault.address);
    expect(erc20_balance_vault).to.be.equal(tokensToDeposit);
  });

  it("Should withdraw 50 shares", async () => {
    const tokensToWithdraw = 50n;

    await Vault.withdraw(tokensToWithdraw);

    const totalSupply = await Vault.total_supply();
    expect(totalSupply).to.be.equal(0n);

    const erc20_balance_vault = await ERC20.balance_of(Vault.address);
    expect(erc20_balance_vault).to.be.equal(0n);

    const erc20_balance_user = await ERC20.balance_of(user.address);
    expect(erc20_balance_user).to.be.equal(100n);
  });
});
