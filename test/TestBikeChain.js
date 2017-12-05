// Specifically request an abstraction for MetaCoin
var BikeChain = artifacts.require("BikeChain");

contract('BikeChain', function(accounts) {
  it("First Company account same as contract creator", function(){
    var companyAddress;
    return BikeChain.deployed().then(function(instance) {
      return instance.getCompany(0);
    }).then(function(companyAddress){
      assert.equal(accounts[0],companyAddress,"Not equal");
    });
  });

  it("Add Company working correctly", function() {
    var bc;
    var as;

    return BikeChain.deployed().then(function(instance) {
      bc = instance;
      bc.changeAdminSwitch(true); // Turn admin switch on
      as = instance.getAdminSwitch();
      return bc.getCompanyLength.call();
    }).then(function(len){
      bc.addCompany(accounts[1],{from: accounts[0]});
      return bc.getCompany(len);
    }).then(function(cID){
      assert.equal(accounts[1], cID, "Company not added correctly");
      assert.isOk(as, "Admin switch is not on");
    });
  });

    it("Add Bike working correctly", function() {
      var bc;
      var as;
      var owner = accounts[0];
      var price;
      var frameNumber = "1234";
      var make = "Specialized";
      var model = "Allez";
      var year = 2015;
      var size = 56;
      var colour = "Orange";
      var features = "Dint on handlebar";
      var stolen = false;
      var cID = 0;

      return BikeChain.deployed().then(function(instance) {
        bc = instance;
        bc.changeAdminSwitch(true);
        return bc.getAdminSwitch();
      }).then( function(_as){
        as = _as;
        return bc.getRegistrationPrice();
      }).then(function(_price){
        price = _price.toNumber();
        bc.addBike(frameNumber, make, model, year, size, colour, features, cID,{from: owner, value: price});
        return bc.getBike.call(frameNumber);
      }).then(function(bike){
        assert.equal(bike[0], owner, "Owners not equal");
        assert.notEqual(bike[0], "0x0", "Owners not equal");
        assert.equal(bike[1], make, "Make not equal");
        assert.notEqual(bike[1], "Giant", "Make not equal");
        assert.equal(bike[2], model, "Model not equal");
        assert.notEqual(bike[2], "Defy", "Model not equal");
        assert.equal(bike[3].toNumber(), year, "Year not equal");
        assert.notEqual(bike[3].toNumber(), 1, "Year not equal");
        assert.equal(bike[4].toNumber(), size, "Size not equal");
        assert.equal(bike[5], colour, "Colour not equal");
        assert.equal(bike[6], features, "Features not equal");
        assert.equal(bike[8], stolen, "Stolen not equal");
        assert.isOk(as, "Admin switch not working");
      });
    });

    it("Add contact details working correctly", function() {
      var bc;
      var name = "Sam Smith";
      var email = "sam.smith@gmail.com";
      var phone = "+447572665355";

      return BikeChain.deployed().then(function(instance) {
        bc = instance;
        bc.addContactDetails(name, email, phone);
        return bc.getContactDetails(accounts[0]);
      }).then(function(dets){
        assert.equal(dets[0], name, "Name not equal");
        assert.equal(dets[1], email, "Email not equal");
        assert.equal(dets[2], phone, "Phone not equal");
      })


    })
});
