App = {
  web3Provider: null,
  contracts: {},

  init: function() {
    // Load pets.

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

      // Use our contract to retrieve and mark the adopted pets
      //return App.markAdopted();
    });

    return App.bindEvents();
  },

  bindEvents: function() {
    $(document).on('click', '.register-bike', App.registerBike);
    $(document).on('click', '.show-bike', App.showBike);
  },

  markAdopted: function(adopters, account) {
    var adoptionInstance;

    App.contracts.Adoption.deployed().then(function(instance) {
      adoptionInstance = instance;

      return adoptionInstance.getAdopters.call();
    }).then(function(adopters) {
      for (i = 0; i < adopters.length; i++) {
        if (adopters[i] !== '0x0000000000000000000000000000000000000000') {
          $('.panel-pet').eq(i).find('button').text('Success').attr('disabled', true);
        }
      }
    }).catch(function(err) {
      console.log(err.message);
    });
  },

  handleAdopt: function(event) {
    event.preventDefault();

    var petId = parseInt($(event.target).data('id'));

    var adoptionInstance;

    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.Adoption.deployed().then(function(instance) {
        adoptionInstance = instance;

        // Execute adopt as a transaction by sending account
        return adoptionInstance.adopt(petId, {from: account});
  }).then(function(result) {
    return App.markAdopted();
  }).catch(function(err) {
    console.log(err.message);
  });
});

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

    console.log(framenumber);
    console.log(make);
    console.log(model);
    console.log(year + 2);
    console.log(size);
    console.log(colour);
    console.log(features);

    App.contracts.BikeChain.deployed().then(function(instance) {
      bikechainInstance = instance;
      console.log("In deployed contract");

      // Execute adopt as a transaction by sending account
      return bikechainInstance.addBike(framenumber, make, model, year, size, colour, features, cID);
    }).then(function(result) {
      console.log("Bike Added");
    }).catch(function(err) {
      console.log(err.message);
    });

  },

  showBike: function(event){
    event.preventDefault();

    var bikeInstance;

    var framenumber = $('#showBike').find('input[name="FrameNumber"]').val();

    var bikeRow = $('#bikeRow');
    var bikeTemplate = $('#bikeTemplate');

    App.contracts.BikeChain.deployed().then(function(instance) {
      console.log("In deployed contract");
      bikeInstance = instance;

      return bikeInstance.getBike(framenumber);
    }).then(function(bike) {

      if(bike[0] == ""){
        throw new Error("Bike not in register");
      }

      bikeTemplate.find('.framenumber').text(framenumber);
      bikeTemplate.find('.make').text(bike[0]);
      bikeTemplate.find('.model').text(bike[1]);
      bikeTemplate.find('.year').text(String(bike[2]));

      bikeRow.append(bikeTemplate.html());
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
