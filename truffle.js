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
      port: 9545,
      from: "0x627306090abaB3A6e1400e9345bC60c78a8BEf57", // default address to use for any transaction Truffle makes during migrations
      network_id: 4,
      gas: 4612388 // Gas limit used for deploys
    }
  }
};
