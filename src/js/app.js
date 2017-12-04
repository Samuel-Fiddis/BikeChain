App = {
  web3Provider: null,
  contracts: {},

  init: function() {
    // Load any required information

    return App.initWeb3();
  },

  initWeb3: function() {
   // Is there is an injected web3 instance?
	if (typeof web3 !== 'undefined') {
	  App.web3Provider = web3.currentProvider;
	} else {
	  // If no injected web3 instance is detected, fallback to the TestRPC
	  App.web3Provider = new Web3.providers.HttpProvider('http://localhost:8545');
	}
	web3 = new Web3(App.web3Provider);

    return App.initContract();
  },

  initContract: function() {
    $.getJSON('BikeChain.json', function(data) {
      // Get the necessary contract artifact file and instantiate it with truffle-contract
      var BikeChainArtifact = data;
      App.contracts.BikeChain = TruffleContract(BikeChainArtifact);

      // Set the provider for our contract
      App.contracts.BikeChain.setProvider(App.web3Provider);
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.register-bike', App.registerBike);
    $(document).on('click', '.show-bike', App.showBike);
    $(document).on('click', '.report-bike', App.reportBike);
  },

  registerBike: function(event){
    event.preventDefault();

    var framenumber = $('#registerBike').find('input[name="FrameNumber"]').val();
    var make = $('#registerBike').find('input[name="Make"]').val();
    var model = $('#registerBike').find('input[name="Model"]').val();
    var year = parseInt($('#registerBike').find('input[name="Year"]').val());
    var size = parseInt($('#registerBike').find('input[name="Size"]').val());
    var colour = $('#registerBike').find('input[name="Colour"]').val();
    var features = $('#registerBike').find('input[name="Features"]').val();
    var cID = 0;

    App.contracts.BikeChain.deployed().then(function(instance) {
      bikechainInstance = instance;

      return bikechainInstance.addBike(framenumber, make, model, year, size, colour, features, cID);
    }).then(function(result) {
      console.log(result.log);
    }).catch(function(err) {
      console.log(err.message);
    });

  },

  showBike: function(event){
    event.preventDefault();

    var bikeInstance;
    var status = "Owned";
    var framenumber = $('#showBike').find('input[name="FrameNumber"]').val();
    var bikeRow = $('#bikeRow');
    var bikeTemplate = $('#bikeTemplate');

    App.contracts.BikeChain.deployed().then(function(instance) {
      bikeInstance = instance;

      return bikeInstance.getBike.call(framenumber);
    }).then(function(bike) {

      if(bike[0] == ""){
        throw new Error("Bike not in register");
      }
      if(bike[6]){
        status = "Stolen";
        status.fontcolor("red");
      }

      bikeTemplate.find('.framenumber').text(framenumber);
      bikeTemplate.find('.make').text(bike[0]);
      bikeTemplate.find('.model').text(bike[1]);
      bikeTemplate.find('.year').text(String(bike[2]));
      bikeTemplate.find('.stolen').text(status);

      bikeRow.append(bikeTemplate.html());
    }).catch(function(err) {
      console.log(err.message);
    });

  },

    reportBike: function(event){
      event.preventDefault();

      var bikeInstance;
      var frameNumber = $('#reportBike').find('input[name="FrameNumber"]').val();
      var Stolen = $('#reportBike').find('input[name="Stolen"]').val();
      var Found = $('#reportBike').find('input[name="Found"]').val();

      App.contracts.BikeChain.deployed().then(function(instance) {
        bikeInstance = instance;

        if(Stolen){
          return bikeInstance.reportStolen(frameNumber, ""); // Extra details needed
        }
        if(Found){
          return bikeInstance.reportFound(frameNumber, ""); // Extra details needed
        }

      }).then(function(bike) {

      }).catch(function(err) {
        console.log(err.message);
      });
    }
};

$(function() {
  $(window).load(function() {
    App.initWeb3();
  });
});
