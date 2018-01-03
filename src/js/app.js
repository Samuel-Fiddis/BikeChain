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
    $(document).on('click', '.transfer-bike', App.transferBike);

    // Admin Functions
    $(document).on('click', '.contract-owner', App.contractOwner);
    $(document).on('click', '.total-supply', App.totalBikes);
    $(document).on('click', '.reg-price', App.registrationPrice);
  },

  registerBike: function(event){
    event.preventDefault();

    var bikechainInstance;

    var framenumber = $('#registerBike').find('input[name="FrameNumber"]').val();
    var make = $('#registerBike').find('input[name="Make"]').val();
    var model = $('#registerBike').find('input[name="Model"]').val();
    var year = parseInt($('#registerBike').find('input[name="Year"]').val());
    var size = parseInt($('#registerBike').find('input[name="Size"]').val());
    var colour = $('#registerBike').find('input[name="Colour"]').val();
    var features = $('#registerBike').find('input[name="Features"]').val();
    var infoUrl = $('#registerBike').find('input[name="InfoUrl"]').val();
    var cID = 0;

    App.contracts.BikeChain.deployed().then(function(instance) {
      bikechainInstance = instance;
      return bikechainInstance.getRegistrationPrice();
    }).then(function(regP){
      return bikechainInstance.addBike(framenumber, make, model, year, size, colour, features, infoUrl, cID, {value: regP});
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
    var infoUrl;

    App.contracts.BikeChain.deployed().then(function(instance) {
      bikeInstance = instance;

      return bikeInstance.tokenMetadata.call(framenumber);
    }).then(function(inUrl){
      infoUrl = inUrl;
      return bikeInstance.getBike.call(framenumber);
    }).then(function(bike) {

      if(bike[1] == ""){
        throw new Error("Bike not in register");
      }
      if(bike[8]){
        status = "Stolen";
        status.fontcolor("red");
      }

      $('#showBike').find('.show-bike-error').text("");

      bikeTemplate.find('.framenumber').text(framenumber);
      bikeTemplate.find('.owner').text(bike[0]);
      bikeTemplate.find('.make').text(bike[1]);
      bikeTemplate.find('.model').text(bike[2]);
      bikeTemplate.find('.year').text(String(bike[3]));
      bikeTemplate.find('.size').text(String(bike[4]));
      bikeTemplate.find('.colour').text(bike[5]);
      bikeTemplate.find('.features').text(bike[6]);
      bikeTemplate.find('.details').text(bike[7]);
      bikeTemplate.find('.stolen').text(status);
      bikeTemplate.find('.infoUrl').text(infoUrl);

      bikeRow.append(bikeTemplate.html());
    }).catch(function(err) {
      console.log(err.message);
      $('#showBike').find('.show-bike-error').text(err.message);
      $('#showBike').find('.show-bike-error').css('color', 'red');
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
    },

    transferBike: function(event){
      event.preventDefault();

      var bikeInstance;
      var frameNumber = $('#transferBike').find('input[name="FrameNumber"]').val();
      var to = $('#transferBike').find('input[name="To"]').val();

      App.contracts.BikeChain.deployed().then(function(instance) {
        bikeInstance = instance;

        return bikeInstance.transfer(to, frameNumber);
      }).then(function(bike) {

      }).catch(function(err) {
        console.log(err.message);
      });
    },

    // Admin Functions
    contractOwner: function(event){
      event.preventDefault();

      var cID = 0;

      App.contracts.BikeChain.deployed().then(function(instance) {
        bikeInstance = instance;

        return bikeInstance.getCompany(cID);
      }).then(function(company){
        $('#adminFunctions').find('.contract-creator').text(company);
      }).catch(function(err){
        console.log(err.message);
      });
    },

    contractOwner: function(event){
      event.preventDefault();

      var cID = $('#adminFunctions').find('input[name="CompanyId"]').val();

      App.contracts.BikeChain.deployed().then(function(instance) {
        bikeInstance = instance;

        return bikeInstance.getCompany(cID);
      }).then(function(company){
        $('#adminFunctions').find('.contract-creator').text(company);
      }).catch(function(err){
        console.log(err.message);
      });
    },

    totalBikes: function(event){
      event.preventDefault();

      App.contracts.BikeChain.deployed().then(function(instance) {
        bikeInstance = instance;

        return bikeInstance.totalSupply();
      }).then(function(numBikes){
        $('#adminFunctions').find('.total-bikes').text(numBikes);
      }).catch(function(err){
        console.log(err.message);
      });
    },

    registrationPrice: function(event){
      event.preventDefault();

      App.contracts.BikeChain.deployed().then(function(instance) {
        bikeInstance = instance;

        return bikeInstance.getRegistrationPrice();
      }).then(function(regP){
        $('#adminFunctions').find('.registration-price').text(regP + " wei");
      }).catch(function(err){
        console.log(err.message);
      });
    },

    getDetails: function(event){

    }
};

$(function() {
  $(window).load(function() {
    App.initWeb3();
  });
});
