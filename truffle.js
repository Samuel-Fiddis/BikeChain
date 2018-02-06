module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    development: {
      host: 'localhost',
      port: 9545,
      network_id: '*' // Match any network id
    },
    rinkeby: {
      host: "localhost", // Connect to geth on the specified
      port: 8545,
      from: "0x3e965e55f5c462608a76b3bffe92b03062898ba8", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gas: 6312558,//4612388, // Gas limit used for deploys
      //gasPrice: web3.toWei("16", "gwei")
    },
    ropsten:  {
      network_id: 3,
      host: "localhost",
      port:  8545,
      from: "0xee2bc995dc35b719b25f26940999e8c0a80bb742",
      gas:   6312558
    }
  }
};
