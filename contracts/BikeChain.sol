pragma solidity ^0.4.18;

contract Contacts{

    struct ContactDetails{
        string name;
        string email;
        string phone;
    }

    mapping(address => ContactDetails) contactList; // Owner details

    event ContactDetailsAdded(address owner, string name, string email, string phone);

    function addContactDetails(string _name, string _email, string _phone) public{
        contactList[msg.sender].name = _name;
        contactList[msg.sender].email = _email;
        contactList[msg.sender].phone = _phone;
        ContactDetailsAdded(msg.sender, _name, _email, _phone);
    }
}

contract BikeChain is Contacts{

    string contractName;
    string contractSymbol;
    uint256 supplyNum;

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
        string infoUrl;
    }

    // Switch to turn company admin off or on
    bool adminSwitch;

    // Price to register Bike in Wei
    uint registrationPrice;

    address[] public company;
    mapping(string => Bike) register; // Maps frame number to bike
    mapping(address => string[]) ownerList; // Maps address to frame numbers
    // mapping(address => uint256) balance; Maps address to number of bikes owned
    mapping(string => address) approvedAddress; // Maps frame number to address which is approved to take ownership

    modifier onlyAdmin(uint _cID){
        if(adminSwitch) require(msg.sender == company[_cID]);
        _;
    }

    modifier onlyAdminOrOwner(uint _cID, string _frameNumber){
        bool test = false;
        if(adminSwitch){
            if(msg.sender == company[_cID]){
                test = true;
            }
        }
        if(register[_frameNumber].owner == msg.sender){
            test = true;
        }
        require(test);
        _;
    }

    modifier onlyCompany(uint _cID){
        require(msg.sender == company[_cID]);
        _;
    }

    modifier onlyCompanyOrOwner(uint _cID, string _frameNumber){
        bool test = false;
        if(msg.sender == company[_cID]){
            test = true;
        }
        if(register[_frameNumber].owner == msg.sender){
            test = true;
        }
        require(test);
        _;
    }

    modifier onlyContractCreator(){
        require(msg.sender == company[0]);
        _;
    }

    modifier bikeOwner(string _frameNumber){
        require(register[_frameNumber].owner == msg.sender);
        _;
    }

    modifier hasApproval(string _frameNumber){
        require(approvedAddress[_frameNumber] == msg.sender);
        _;
    }

    modifier costs(uint _price) {
        require(msg.value >= _price);
            _;
    }

    event Approval(address owner, address to, string frameNumber);
    event BikeCreated(string frameNumber);
    event BikeRemoved(address company, address owner, string frameNumber);
    event BikeTransfered(address from, address to, string frameNumber);
    event BikeStolen(string frameNumber, string details);
    event BikeFound(address finder, string frameNumber, string details);
    event CompanyAdded(address admin, address company, uint cID);
    event CompanyRemoved(address admin, address company, uint cID);
    event OwnerChanged(address from, address to);
    event EtherWithdrawn(address from, address to, uint value);
    event AdminSwitchChanged(bool status);

    function BikeChain() public{
        company.length++;
        company[0] = msg.sender;
        registrationPrice = 10000000000000000;
        adminSwitch = false;
        contractName = "Bike-Token";
        contractSymbol = "🚲";
        supplyNum = 0;
    }

    // Begin ERC-721 Standard Functions

    function name() constant public returns (string){
      return contractName;
    }

    function symbol() constant public returns (string){
      return contractSymbol;
    }

    function totalSupply() constant public returns (uint256){
      return supplyNum;
    }

    function balanceOf(address _owner) constant public returns (uint256){
      return ownerList[_owner].length;
    }

    function ownerOf(string _frameNumber) constant public returns (address){
      require(register[_frameNumber].owner != 0);
      return register[_frameNumber].owner;
    }

    function approve(address _to, string _frameNumber) bikeOwner(_frameNumber) public{
      approvedAddress[_frameNumber] = _to;
      Approval(msg.sender, _to, _frameNumber);
    }

    function takeOwnership(string _frameNumber) hasApproval(_frameNumber) public{
      address oldOwner = register[_frameNumber].owner;
      ownerList[msg.sender].push(_frameNumber);
      register[_frameNumber].owner = msg.sender;
      string[] storage fn = ownerList[oldOwner];
      uint index = getFrameIndex(oldOwner, _frameNumber);
      for (uint i = index; i < fn.length-1; i++){
        fn[i] = fn[i+1];
      }
      delete fn[fn.length-1];
      fn.length--;

      BikeTransfered(oldOwner, msg.sender, _frameNumber);
    }

    function transfer(address _to, string _frameNumber) bikeOwner(_frameNumber) public{
      require(_to != 0);
      ownerList[_to].push(_frameNumber);
      register[_frameNumber].owner = _to;
      string[] storage fn = ownerList[msg.sender];
      uint index = getFrameIndex(msg.sender, _frameNumber);
      for (uint i = index; i < fn.length-1; i++){
        fn[i] = fn[i+1];
      }
      delete fn[fn.length-1];
      fn.length--;

      BikeTransfered(msg.sender, _to, _frameNumber);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) constant public returns (string frameNumber){
      require(_index < balanceOf(_owner));
      require(_index >= 0);
      frameNumber = ownerList[_owner][_index];
    }

    function tokenMetadata(string _frameNumber) constant public returns (string){
      return register[_frameNumber].infoUrl;
    }

    function updateTokenMetadata(string _frameNumber, string _infoUrl) bikeOwner(_frameNumber) constant public{
      register[_frameNumber].infoUrl = _infoUrl;
    }

    // End ERC-721 Standard Functions

    function () payable public{}

    function withdrawEther(address _to, uint _value) onlyContractCreator() public{
        //require(this.balance > _value);
        _to.transfer(_value);
        EtherWithdrawn(msg.sender, _to, _value);
    }

    function addBike(string _frameNumber, string _make, string _model, uint16 _year, uint8 _size, string _colour, string _features, string _infoUrl, uint _cID)
    payable onlyAdmin(_cID) costs(registrationPrice) public{
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
        b.infoUrl = _infoUrl;
        supplyNum++;
        BikeCreated(_frameNumber);

        ownerList[msg.sender].push(_frameNumber);
    }

    function addCompany(address _newCompany) onlyContractCreator() public returns(uint newcID){
        newcID = company.length++;
        company[newcID] = _newCompany;
        CompanyAdded(company[0], _newCompany, newcID);
    }

    function reportStolen(string _frameNumber, string _details) bikeOwner(_frameNumber) public{
        Bike storage b = register[_frameNumber];
        b.stolen = true;
        BikeStolen(_frameNumber, _details);
    }

    function reportFound(string _frameNumber, string _details) public{
        require(register[_frameNumber].stolen);
        register[_frameNumber].stolen = false;
        BikeFound(msg.sender, _frameNumber, _details);
    }

    function transferOwner(string _frameNumber, address _newOwner, uint _cID) onlyAdminOrOwner(_cID, _frameNumber) public{
        require(_newOwner != 0);
        ownerList[_newOwner].push(_frameNumber);
        register[_frameNumber].owner = _newOwner;
        string[] storage fn = ownerList[msg.sender];
        uint index = getFrameIndex(msg.sender, _frameNumber);
        for (uint i = index; i < fn.length-1; i++){
          fn[i] = fn[i+1];
        }
        delete fn[fn.length-1];
        fn.length--;

        BikeTransfered(msg.sender, _newOwner, _frameNumber);
    }

    function removeBike(string _frameNumber, uint _cID) onlyAdminOrOwner(_cID, _frameNumber) public{
        address owner = register[_frameNumber].owner;
        delete register[_frameNumber];
        string[] storage fn = ownerList[owner];
        uint index = getFrameIndex(owner, _frameNumber);
        for (uint i = index; i < fn.length-1; i++){
          fn[i] = fn[i+1];
        }
        delete fn[fn.length-1];
        fn.length--;
        supplyNum--;

        BikeRemoved(msg.sender, owner, _frameNumber);
    }

    // Only contract creator can remove companies
    function removeCompany(uint _cID) onlyContractCreator() public{
        require(_cID != 0); // Cant remove contract creator
        require(_cID < company.length);
        address companyAddress = company[_cID];
        for (uint i = _cID; i < company.length-1; i++){
          company[i] = company[i+1];
        }
        delete company[company.length-1];
        company.length--;

        CompanyRemoved(msg.sender, companyAddress, _cID);
    }

    function changeOwner(address _newOwner) onlyContractCreator() public{
        company[0] = _newOwner;
        OwnerChanged(msg.sender, _newOwner);
    }

    function changeAdminSwitch(bool _status) public returns(bool){
        require(msg.sender == company[0]);
        adminSwitch = _status;
        AdminSwitchChanged(_status);
        return adminSwitch;
    }

    // Get functions
    function getBike(string _frameNumber) constant public
    returns(address owner, string make, string model, uint16 year, uint8 size, string colour, string features, string details, bool stolen, string infoUrl){

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
    infoUrl = b.infoUrl;
    }

    function getFrameIndex(address _owner, string _frameNumber) constant public returns(uint i){
        string[] storage fn = ownerList[_owner];
        for(i = 0; i < fn.length; i++){
            if(keccak256(fn[i]) == keccak256(_frameNumber)) return i;
        }
        require(false); // Fail if not found
    }

    function getFrameNumber(address _owner, uint _index) constant public returns(string frameNumber){
        require(_index < ownerList[_owner].length);
        frameNumber = ownerList[_owner][_index];
    }

    function getCompany(uint _cID) constant public returns(address co){
        require(_cID < company.length);
        co = company[_cID];
    }

    function getCompanyID() constant public returns(uint id){
        for(id = 0; id < company.length; id++){
            if(company[id] == msg.sender) return;
        }
        require(false); // Fail if not found
    }

    function getCompanyLength() constant public returns(uint len){
        len = company.length;
    }

    function getContactDetails(address _owner) constant public
    returns(string contactName, string email, string phone){
        contactName = contactList[_owner].name;
        email = contactList[_owner].email;
        phone = contactList[_owner].phone;
    }

    function getOwner(string _frameNumber) constant public returns(address owner){
        owner = register[_frameNumber].owner;
    }

    function getEthBalance() constant public returns (uint) { return this.balance; }

    function getAdminSwitch() constant public returns(bool) { return adminSwitch; }

    function getRegistrationPrice() constant public returns(uint)
    { return registrationPrice; }
}
