pragma solidity ^0.5.1;

import "./payment.sol";

contract Registration is Payment{

    constructor(uint _totalTokens) Payment(_totalTokens) public {}

/* ---- functions ---- */
    
    //adds a new prosumer to the prosumers-array
    function registrationPro(string memory _name) public{
        if(checkRegDataPro(_name)){
            Prosumers.push(Prosumer(msg.sender, _name, 0));
            usertype[msg.sender] = 2;
            initTokensPro(owner, initialTokens);
            numberOfProsumers++;
        }
    }

    //checks the registration data for validity (name is not already registered)
    function checkRegDataPro(string memory _name) 
    private view returns(bool){
        for(uint i = 0; i < numberOfProsumers; i++){
            if(keccak256(abi.encodePacked(Prosumers[i].name)) == keccak256(abi.encodePacked(_name))){
                return false;
            }
        }
        return true;
    }

    //adds a new unit to the units-array
    function registrationUnit(string memory _kind, uint _MaLoID, uint _capacity) 
    onlyProsumer(msg.sender)
    public{
        if(checkRegDataUnit(_MaLoID, _capacity)){
            Units.push(Unit(msg.sender, _kind, _MaLoID, _capacity));
            MaLoIDToOwnerAddress[_MaLoID] = msg.sender;
            MaLoIDToColumn[_MaLoID] = numberOfUnits;
            numberOfUnits++;
            for(uint i=0; i<96; i++){
                Offers[i].push(Flexoffer(msg.sender, _MaLoID, 0,0,0,0, false, false)); //reserves space in the offers-array, where the offers of the registered unit can be stored for each timestep
            }
        }
    }    
    
    function uint2str(uint _i) 
    public pure
    returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
    
    //checks the registration data for validity (capacity greater than 0, MaLoID has 11 characters)
    function checkRegDataUnit(uint _MaLoID, uint _capacity)
    private pure returns(bool){
        
        string memory strMaLoID = uint2str(_MaLoID);
        
        if(_capacity > 0 && bytes(strMaLoID).length == 11){
            return true;
        }
        else{
            return false;
        }
    }

    //adds a new operator to the operators-array
    function registrationOp(string memory _name, string memory _kind) public{
        if(checkRegDataOp(_name)){
            Operators.push(Operator(msg.sender, _name, _kind));
            usertype[msg.sender] = 3;
            initTokensOp(owner, initialTokens);
            AddressToColumn[msg.sender] = numberOfOperators;
            numberOfOperators++;
            for(uint i=0; i<96; i++){
                Demands[i].push(Flexdemand(msg.sender, 0,0,0,0, false, false)); //reserves space in the demands-array, where the demands of the registered operator can be stored for each timestep
            }
        }    
    }    

    //checks the registration data for validity (name is not already registered)
    function checkRegDataOp(string memory _name) 
    private view returns(bool){
        for(uint i = 0; i < numberOfOperators; i++){
            if(keccak256(abi.encodePacked(Operators[i].name)) == keccak256(abi.encodePacked(_name))){
                return false;
            }
        }
        return true;
    }

    //verify an account as a Smart Meter by adding it to the SmartMeter-Array, only possible by the market owner
    function addSmartMeter(address _smartMeterAddress, string memory _smartMeterUnit) 
    onlyAdmin(msg.sender)
    public{
        SmartMeters.push(SmartMeter(_smartMeterAddress, _smartMeterUnit));
        usertype[_smartMeterAddress] = 4;
        numberOfSmartMeters++;
    }
    
}