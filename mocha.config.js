module.exports = {
    require: 'ts-node/register', // use the ts-node TypeScript execution environment
    spec: 'test/*.t.ts', // run all test files in the test directory and its subdirectories
    extension: ['ts'], // require .ts files instead of .js files
    timeout: "500000"
};