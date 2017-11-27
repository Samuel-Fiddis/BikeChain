pragma solidity ^0.4.0;

contract BikeChain{

    struct Bike{
        string make;
        string model;
        uint16 year;
        uint8 size;
        string colour;
        string features;
        bool stolen;
    }

    address company;
    mapping(string => Bike) register; // Maps frame number to bike
    mapping(string => address) ownerList; // Maps frame number to owner

    modifier onlyCompany(){
        require(msg.sender == company);
        _;
    }

    modifier bikeOwner(string _frameNumber){
        require(msg.sender == ownerList[_frameNumber]);
            _;
    }

    event BikeCreated(Bike b);
    event BikeTransfered(address from, address to, Bike b);
    event BikeStolen(Bike b, string details);
    event BikeFound(address finder, Bike b, string details);

    function BikeChain() public {
        company = msg.sender;
    }

    function addBike(string _frameNumber, string _make, string _model, uint16 _year, uint8 _size, string _colour, string _features) onlyCompany public{
        require(ownerList[_frameNumber] == 0); // Check bike isn't owned
        bytes memory tempEmptyStringTest = bytes(register[_frameNumber].make);
        require(tempEmptyStringTest.length == 0); // Make sure bike isn't in register

        Bike storage b = register[_frameNumber];
        b.make = _make;
        b.model = _model;
        b.year = _year;
        b.size = _size;
        b.colour = _colour;
        b.features = _features;
        b.stolen = false;
        BikeCreated(b);

        ownerList[_frameNumber] = msg.sender;
    }

    function reportStolen(string _frameNumber, string details) bikeOwner(_frameNumber) public {
        Bike storage b = register[_frameNumber];
        b.stolen = true;
        BikeStolen(b, details);
    }

    function transferOwner(string _frameNumber, address newOwner) bikeOwner(_frameNumber) public{
        ownerList[_frameNumber] = newOwner;
        BikeTransfered(msg.sender, newOwner, register[_frameNumber]);
    }

    function reportFound(string _frameNumber, string details) public{
        require(register[_frameNumber].stolen);
        BikeFound(msg.sender, register[_frameNumber], details);
    }
}
