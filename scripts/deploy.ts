import {
  Account,
  Contract,
  Provider,
  RawArgs,
  json,
  shortString,
} from "starknet";
import fs from "fs";
import dotenv from "dotenv";
dotenv.config();

// Initialize the wallet.
const deployerPrivateKey = process.env.DEPLOYACCT_PRIVATE_KEY!;
const deployerAddress = process.env.DEPLOYACCT_ADDRESS!;

// const provider = new Provider({ sequencer: { baseUrl: "https://alpha4.starknet.io" } });
const provider = new Provider({
  sequencer: { baseUrl: "http://127.0.0.1:5050" },
});
const deployer = new Account(provider, deployerAddress, deployerPrivateKey);

async function deployContract(
  contractName: string,
  constructorCalldata: RawArgs
): Promise<Contract> {
  // Declare & deploy contract
  const compiledSierra = json.parse(
    fs
      .readFileSync(`target/dev/compiled_${contractName}.sierra.json`)
      .toString("ascii")
  );
  const compiledCasm = json.parse(
    fs
      .readFileSync(`target/dev/compiled_${contractName}.casm.json`)
      .toString("ascii")
  );
  const deployResponse = await deployer.declare({
    contract: compiledSierra,
    casm: compiledCasm,
  });
  const contractClassHash = deployResponse.class_hash;
  console.log(
    `✅ Contract ${contractName} declared at:`,
    deployResponse.class_hash
  );
  await provider.waitForTransaction(deployResponse.transaction_hash);
  const { transaction_hash: transaction_hash, address } =
    await deployer.deployContract({
      classHash: contractClassHash,
      salt: "0",
      constructorCalldata,
    });
  await provider.waitForTransaction(transaction_hash);

  // Return the new contract instance
  const contract = new Contract(compiledSierra.abi, address, provider);
  return contract;
}

async function main(): Promise<Contract> {
  const erc20 = await deployContract("ERC20", [
    shortString.encodeShortString("SimpleVault"),
    shortString.encodeShortString("SV"),
    100,
    0,
    deployer,
  ]);
  console.log("✅ ERC20 Token contract deployed at:", erc20.address);
  const vault = await deployContract("Vault", {
    _token: erc20.address,
  });
  console.log("✅ Vault contract deployed at:", vault.address);
  return vault;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
