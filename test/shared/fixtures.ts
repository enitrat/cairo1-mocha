import {Account, Contract, Provider, json, RawArgs, shortString} from "starknet";
import fs from "fs";
import dotenv from "dotenv";

dotenv.config();

const deployerPrivateKey = process.env.DEPLOYACCT_PRIVATE_KEY!;
const deployerAddress = process.env.DEPLOYACCT_ADDRESS!;

const userPrivateKey = process.env.OZ_ACCOUNT_PRIVATE_KEY!;
const userAddress = process.env.OZ_ACCOUNT_ADDRESS!;

export const provider = new Provider({sequencer: {baseUrl: "http://127.0.0.1:5050"}});
export const deployer = new Account(provider, deployerAddress, deployerPrivateKey);
// export const executor = new Account(provider, EXECUTOR_ADDRESS, EXECUTOR_PRIVATE_KEY);
export const user = new Account(provider, userAddress, userPrivateKey);

async function deployContract(contractName: string, constructorCalldata: RawArgs): Promise<Contract> {
  // Declare & deploy contract
  const compiledSierra = json.parse(fs.readFileSync(`target/dev/compiled_${contractName}.sierra.json`).toString("ascii"));
  const compiledCasm = json.parse(fs.readFileSync(`target/dev/compiled_${contractName}.casm.json`).toString("ascii"));
  const deployResponse = await deployer.declare({contract: compiledSierra, casm: compiledCasm});
  const contractClassHash = deployResponse.class_hash;
  console.log(`✅ Contract ${contractName} declared at:`, deployResponse.class_hash);
  await provider.waitForTransaction(deployResponse.transaction_hash);
  const {transaction_hash: transaction_hash, address} = await deployer.deployContract({
    classHash: contractClassHash,
    salt: "0",
    constructorCalldata
  });
  await provider.waitForTransaction(transaction_hash);

  // Return the new contract instance
  const contract = new Contract(compiledSierra.abi, address, provider);
  return contract;
}

export async function ERC20Fixtures(): Promise<Contract> {
  const contract = await deployContract("ERC20", [
    shortString.encodeShortString('SimpleVault'),
    shortString.encodeShortString('SV'),
    100,
    0,
    userAddress
  ]);
  contract.connect(deployer);
  console.log('✅ ERC20 Token contract deployed at:', contract.address);

  return (contract);
}

export async function vaultFixtures(): Promise<[Contract, Contract]> {
  const ERC20 = await ERC20Fixtures();
  const initialTk = { low: 100, high: 0 };
  const contract = await deployContract("Vault", {
    _token: ERC20.address,
  });
  console.log('✅ Vault contract deployed at:', contract.address);

  return [contract,ERC20];
}
