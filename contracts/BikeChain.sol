pragma solidity ^0.4.18;

contract BikeChain{

    struct Bike{
        address owner;
        string make;
        string model;
        uint16 year;
        uint8 size;
        string colour;
        string features;
        string details;
        bool stolen;
    }

    // Currently unused
    struct ContactDetails{
        string name;
        string email;
        string phone;
    }

    // Switch to turn company admin off or on
    bool adminSwitch;

    // Price to register Bike in Wei
    uint registrationPrice;

    address[] public company;
    mapping(string => Bike) register; // Maps frame number to bike
    mapping(address => string[]) ownerList; // Maps address to frame numbers
    mapping(address => ContactDetails) contactList; // Owner details

    modifier onlyCompany(uint cID){
        if(adminSwitch) require(msg.sender == company[cID]);
        _;
    }

    modifier bikeOwner(string _frameNumber){
        require(register[_frameNumber].owner == msg.sender);
            _;
    }

    modifier costs(uint price) {
        require(msg.value >= price);
            _;
    }

    event BikeCreated(string frameNumber);
    event BikeRemoved(address company, address owner, string frameNumber);
    event BikeTransfered(address from, address to, string frameNumber);
    event BikeStolen(string frameNumber, string details);
    event BikeFound(address finder, string frameNumber, string details);

    function BikeChain() public{
        company.length++;
        company[0] = msg.sender;
        registrationPrice = 10000000000000000;
        adminSwitch = false;
    }

    function addCompany(uint cID, address newCompany) onlyCompany(cID) public returns(uint newcID){
        newcID = company.length++;
        company[newcID] = newCompany;
        return newcID;
    }

    function addBike(string _frameNumber, string _make, string _model, uint16 _year, uint8 _size, string _colour, string _features, uint cID)
    payable onlyCompany(cID) costs(registrationPrice) public returns(bool){
        require(register[_frameNumber].owner == 0); // Check bike isn't owned

        Bike storage b = register[_frameNumber];
        b.owner = msg.sender;
        b.make = _make;
        b.model = _model;
        b.year = _year;
        b.size = _size;
        b.colour = _colour;
        b.features = _features;
        b.stolen = false;
        BikeCreated(_frameNumber);

        ownerList[msg.sender].push(_frameNumber);

        return true;
    }

    function addContactDetails(string _name, string _email, string _phone) public{
        contactList[msg.sender].name = _name;
        contactList[msg.sender].email = _email;
        contactList[msg.sender].phone = _phone;
    }

    function reportStolen(string _frameNumber, string details) bikeOwner(_frameNumber) public{
        Bike storage b = register[_frameNumber];
        b.stolen = true;
        BikeStolen(_frameNumber, details);
    }

    function reportFound(string _frameNumber, string details) public{
        require(register[_frameNumber].stolen);
        register[_frameNumber].stolen = false;
        BikeFound(msg.sender, _frameNumber, details);
    }

    function transferOwner(string _frameNumber, address newOwner) bikeOwner(_frameNumber) public{
        ownerList[newOwner].push(_frameNumber);
        register[_frameNumber].owner = newOwner;
        string[] storage fn = ownerList[msg.sender];
        uint index = getFrameIndex(msg.sender, _frameNumber);
        for (uint i = index; i < fn.length-1; i++){
          fn[i] = fn[i+1];
        }
        delete fn[fn.length-1];
        fn.length--;

        BikeTransfered(msg.sender, newOwner, _frameNumber);
    }

    function getFrameIndex(address owner, string _frameNumber) constant public returns(uint i){
        string[] storage fn = ownerList[owner];
        for(i = 0; i < fn.length; i++){
            if(keccak256(fn[i]) == keccak256(_frameNumber)) return i;
        }
        require(false); // Fail if not found
    }

    // Not sure if necessary, allows anyone to remove bike
    function removeBike(string _frameNumber, uint _cID) onlyCompany(_cID) public{
        address owner = register[_frameNumber].owner;
        delete register[_frameNumber];
        string[] storage fn = ownerList[owner];
        uint index = getFrameIndex(owner, _frameNumber);
        for (uint i = index; i < fn.length-1; i++){
          fn[i] = fn[i+1];
        }
        delete fn[fn.length-1];
        fn.length--;

        BikeRemoved(msg.sender, owner, _frameNumber);
    }

    function removeCompany(uint cID) public{
        require(cID != 0);
        require(cID < company.length);
        for (uint i = cID; i < company.length-1; i++){
          company[i] = company[i+1];
        }
        delete company[company.length-1];
        company.length--;
    }

    function changeAdminSwitch() public returns(bool){
        require(msg.sender == company[0]);
        adminSwitch = !adminSwitch;
        return adminSwitch;
    }

    // Get functions
    function getBike(string _frameNumber) constant public
    returns(address owner, string make, string model, uint16 year, uint8 size, string colour, string features, string details, bool stolen){

    Bike storage b = register[_frameNumber];
    owner = b.owner;
    make = b.make;
    model = b.model;
    year = b.year;
    size = b.size;
    colour = b.colour;
    features = b.features;
    details = b.details;
    stolen = b.stolen;
    }

    function getCompany(uint cID) constant public returns(address co){
        require(cID < company.length);
        co = company[cID];
    }

    function getContactDetails(address _owner) constant public
    returns(string name, string email, string phone){
        name = contactList[_owner].name;
        email = contactList[_owner].email;
        phone = contactList[_owner].phone;
    }

    function getOwner(string _frameNumber) constant public returns(address owner){
        owner = register[_frameNumber].owner;
    }

    function getMyBalance() constant public returns (uint) { return this.balance; }

    function getAdminSwitch() constant public returns(bool) { return adminSwitch; }

    function getRegistrationPrice() constant public returns(uint)
    { return registrationPrice; }
}
