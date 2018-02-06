var BikeChain = artifacts.require("BikeChain");
const duration = {
    seconds: function(val) { return val},
    minutes: function(val) { return val * this.seconds(60) },
    hours:   function(val) { return val * this.minutes(60) },
    days:    function(val) { return val * this.hours(24) },
    weeks:   function(val) { return val * this.days(7) },
    years:   function(val) { return val * this.days(365)}
};

module.exports = function(deployer, network, accounts) {
  const startTime = web3.eth.getBlock('latest').timestamp + duration.minutes(1);
  const endTime = startTime + duration.minutes(30);
  const rate = new web3.BigNumber(1000);
  const wallet = '0x3e965e55f5c462608a76b3bffe92b03062898ba8';

  console.log("deploying");

  deployer.deploy(BikeChain, startTime, endTime, rate, wallet);
};
