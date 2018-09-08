pragma solidity ^0.4.18;

contract BikeChain{

  // ----- Coupon Code -----

  mapping(address => bool) public coupon;

  function giveCoupon(address _to) onlyCompany public{
      coupon[_to] = true;
  }

  function takeCoupon(address _to) onlyCompany public{
      delete coupon[_to];
  }

  function useCoupon() internal{
      coupon[msg.sender] = false;
  }

  // ------------------------

    string contractName;
    string contractSymbol;
    uint256 totalSupply;
    uint256 donated;
    address creator;

    struct Bike{
        address owner;
        bool stolen;
        bool found;
        string founddetails;
        string ipfsHash;
    }

    // Switch to turn company admin off or on
    bool adminSwitch;

    // Price to register Bike in Wei
    uint registrationPrice;

    mapping(address => bool) company;
    mapping(string => Bike) register; // Maps frame number to bike
    mapping(address => string[]) ownerList; // Maps address to frame numbers
    mapping(string => address) approvedAddress; // Maps frame number to address which is approved to take ownership

    modifier onlyAdmin(){
        if(adminSwitch) require(company[msg.sender]);
        _;
    }

    modifier onlyAdminOrOwner(string _frameNumber){
        require((adminSwitch && (company[msg.sender])) || register[_frameNumber].owner == msg.sender);
        _;
    }

    modifier onlyCompany(){
        require(company[msg.sender]);
        _;
    }

    modifier onlyCompanyOrOwner(string _frameNumber){
        require(company[msg.sender] || (register[_frameNumber].owner == msg.sender));
        _;
    }

    modifier onlyContractCreator(){
        require(msg.sender == creator);
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
    event BikeFound(address finder, string frameNumber);
    event BikeNotFound(address finder, string frameNumber);
    event BikeReturned(address owner, string frameNumber);
    event CompanyAdded(address admin, address company);
    event CompanyRemoved(address admin, address company);
    event OwnerChanged(address from, address to);
    event EtherWithdrawn(address from, address to, uint value);
    event AdminSwitchChanged(bool status);

    function BikeChain() public{
        creator = msg.sender;
        registrationPrice = 10000000000000000;
        adminSwitch = false;
        contractName = "Bike-Token";
        contractSymbol = "🚲";
        totalSupply = 0;
    }

    // Begin Temporary functions

    function getSender() constant public returns(address){
      return msg.sender;
    }

    function getEthBalance() constant public returns (uint) { return address(this).balance; }

    // End Temporary functions

    // Begin ERC-721 Standard Functions

    function name() constant public returns (string){
      return contractName;
    }

    function symbol() constant public returns (string){
      return contractSymbol;
    }

    function getTotalSupply() constant public returns (uint256){
      return totalSupply;
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
      emit Approval(msg.sender, _to, _frameNumber);
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

      emit BikeTransfered(oldOwner, msg.sender, _frameNumber);
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

      emit BikeTransfered(msg.sender, _to, _frameNumber);
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) constant public returns (string frameNumber){
      require(_index < balanceOf(_owner));
      require(_index >= 0);
      frameNumber = ownerList[_owner][_index];
    }

    function tokenMetadata(string _frameNumber) constant public returns (string){
      return register[_frameNumber].ipfsHash;
    }

    function updateTokenMetadata(string _frameNumber, string _ipfsHash) bikeOwner(_frameNumber) public{
      register[_frameNumber].ipfsHash = _ipfsHash;
    }

    // End ERC-721 Standard Functions

    function () payable public{
      donated = donated + msg.value; // Can remove this
    }

    function withdrawEther(address _to, uint _value) onlyContractCreator() public{
        _to.transfer(_value);
        emit EtherWithdrawn(msg.sender, _to, _value);
    }

    function addBike(string _frameNumber, string _ipfsHash)
    payable onlyAdmin costs(registrationPrice) public{
        require(register[_frameNumber].owner == 0); // Check bike isn't owned

        Bike storage b = register[_frameNumber];
        b.owner = msg.sender;
        b.stolen =false;
        b.found = false;
        b.founddetails = "";
        b.ipfsHash = _ipfsHash;
        totalSupply++;
        donated = donated + msg.value;
        emit BikeCreated(_frameNumber);

        ownerList[msg.sender].push(_frameNumber);
    }

    function addCompany(address _companyAdd) onlyContractCreator public{
        company[_companyAdd] = true;
        emit CompanyAdded(creator, _companyAdd);
    }

    function reportStolen(string _frameNumber, string _ipfsHash) bikeOwner(_frameNumber) public{
        Bike storage b = register[_frameNumber];
        b.stolen = true;
        b.ipfsHash = _ipfsHash;
        emit BikeStolen(_frameNumber, _ipfsHash);
    }

    function reportFound(string _frameNumber, string _details) public{
        require(register[_frameNumber].stolen);
        Bike storage b = register[_frameNumber];
        b.found = true;
        b.founddetails = _details;
        emit BikeFound(msg.sender, _frameNumber);
    }

    function reportNotFound(string _frameNumber) bikeOwner(_frameNumber) public{
        register[_frameNumber].found = false;
        register[_frameNumber].founddetails = "";
        emit BikeNotFound(msg.sender, _frameNumber);
    }

    function reportReturned(string _frameNumber) bikeOwner(_frameNumber) public{
        require(register[_frameNumber].stolen);
        require(register[_frameNumber].found);
        Bike storage b = register[_frameNumber];
        b.stolen = false;
        b.found = false;
        b.founddetails = "";
        emit BikeReturned(msg.sender, _frameNumber);
    }

    function transferOwner(string _frameNumber, address _newOwner) onlyAdminOrOwner(_frameNumber) public{
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

        emit BikeTransfered(msg.sender, _newOwner, _frameNumber);
    }

    function removeBike(string _frameNumber) onlyAdminOrOwner(_frameNumber) public{
        address owner = register[_frameNumber].owner;
        delete register[_frameNumber];
        string[] storage fn = ownerList[owner];
        uint index = getFrameIndex(owner, _frameNumber);
        for (uint i = index; i < fn.length-1; i++){
          fn[i] = fn[i+1];
        }
        delete fn[fn.length-1];
        fn.length--;
        totalSupply--;

        emit BikeRemoved(msg.sender, owner, _frameNumber);
    }

    // Only contract creator can remove companies
    function removeCompany(address _companyAdd) onlyContractCreator public{
        require(company[_companyAdd]);
        delete company[_companyAdd];
        emit CompanyRemoved(msg.sender, _companyAdd);
    }

    function changeOwner(address _newOwner) onlyContractCreator public{
        creator = _newOwner;
        emit OwnerChanged(msg.sender, _newOwner);
    }

    function changeAdminSwitch(bool _status) public onlyContractCreator returns(bool){
        adminSwitch = _status;
        emit AdminSwitchChanged(_status);
        return adminSwitch;
    }

    // Get functions
    function getBike(string _frameNumber) constant public
    returns(address owner, string details, bool stolen, bool found, string ipfsHash){

    Bike storage b = register[_frameNumber];
    owner = b.owner;
    details = b.founddetails;
    stolen = b.stolen;
    found = b.found;
    ipfsHash = b.ipfsHash;
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

    function isCompany(address _companyAdd) constant public returns(bool){
        return company[_companyAdd];
    }

    function getEthDonated() constant public returns (uint) { return donated; }

    function getAdminSwitch() constant public returns(bool) { return adminSwitch; }

    function getRegistrationPrice() constant public returns(uint)
    { return registrationPrice; }
}
