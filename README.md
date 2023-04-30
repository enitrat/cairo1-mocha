# Cairo1 project with Mocha + StarknetJS

As the tooling around Cairo 1 is still in its infancy, there is currently (01/05/2023)
no satisfying way of extensively testing your contracts.

- Protostar is relying on an older version of the compiler (alpha.6) which lacks support for the last features, making it complitely unusable ATM.
- starknet-hardhat-plugin has no integration and requires you to write custom scripts to adapt the output of Scarb to the input of the hardhat plugin; and some features like contract calls are bugged.
- The default `cairo-test` runner works great for unit testing, but is not suited for integration testing and to test cross-contract interacitons due to a lack of testing features (like prank calls)

This project aims to provide a simple way of testing your contracts using Mocha and StarknetJS. While not ideal (extremely slow), it is just temporary and hopefully can be migrated into a more convenient solution soon. Hopefully, the work done by Dojo on [Katana](https://github.com/dojoengine/katana) will help improve performance.

## How to use

1. Clone this repository
2. Install dependencies: `npm install`
3. Write your contracts as a Scarb package under the `src/` directory
4. Write your tests under the `test/` directory
5. Compile your contracts using `scarb_build`.
6. Start a starknet-devnet instance with your local compiler version and the seed `42`:

```bash
starknet-devnet --cairo-compiler-manifest ~/path/to/cairo/Cargo.toml --seed 42
```

7. Run your tests: `npm test`
