module.exports = {
  networks: {
    development: {
     host: "127.0.0.1",     // Localhost (default: none)
     port: 7545,            // Standard Ethereum port (default: none)
     network_id: "*",       // Any network (default: none)
    },
  },
  contracts_directory: './contracts/', // solidity contracts path
  contracts_build_directory: './assets/contracts_abis/', //where abis .json files are placed
  compilers: {
    solc: {    
        version: "0.8.7",
        optimizer: {
          enabled: false,
          runs: 200
        },
    }
  }
};
