pragma solidity ^0.5.1;

contract Framework{

/* ---- declaration of variables ---- */

    struct Prosumer{
        address prosumerAddress; 
        string name;
        uint penalties;         // is increased by 1 every time the prosumer doesn't (completely) fulfill his offer
    }
    
    struct Unit{
        address unitOwner;      // address of the unit-owner
        string kind;
        uint MaLoID;          // "Marktlokations-ID"; unique identifier for each market location in the german energy market
        uint capacity;
    }
    
    struct Operator{
        address operatorAddress;
        string name;
        string kind;            // DSO, TSO
    }
    
    struct SmartMeter{
        address smartMeterAddress;
        string smartMeterUnit;  //MaLoID of the unit the smart meter belongs to
    }
    
    struct Flexoffer{
        address owner;          // address of the offer-owner
        uint MaLoID;          // "Marktlokations-ID"; identifier for each market location in the german energy market
        uint time;              // timestamp from 0 to 95 for each 15min of each day
        uint power;
        uint energy;
        uint price;
        bool flextype;          // true for positive and false for negative flexibility
        bool called;            // true, when the offer is accepted and matched
    }
    
    struct Flexdemand{
        address owner;          // address of the demand-owner
        uint time;              // timestamp from 0 to 95 for each 15min of each day
        uint power;
        uint energy;
        uint maxPrice;
        bool flextype;          // true for positive and false for negative flexibility
        bool called;            // true, when the demand is accepted and matched
    }
    
    struct MatchingPair{
        bool flextype;
        address demandOwner;
        uint MaLoID;
        uint price;
        uint power;
        uint energy;
        uint time;
    }

    MatchingPair[][96] MatchingResult;
    MatchingPair[][96] MatchingResultCopy;
    uint[96] numberOfMatchingResults;
    
    Flexoffer[] sortedOffers;
    Flexoffer[] MatchingOffers;
    Flexdemand[] sortedDemands;
    Flexdemand[] MatchingDemands;
    
    uint numberOfMatchingOffers = 0; 
    uint numberOfMatchingDemands = 0;
    
    mapping (uint => uint) helper; //helper mapping for sorting algorithm
    
    Prosumer[] Prosumers;
    uint numberOfProsumers = 0;
    
    Operator[] Operators;
    uint numberOfOperators = 0;
    
    Unit[] Units;
    uint numberOfUnits = 0;
    
    SmartMeter[] SmartMeters;
    uint numberOfSmartMeters = 0;
    
    Flexoffer[][96] Offers;     //dynamic array to store all flexoffers; for every prosumer there is one slot reserved to store his flexoffer for each timestep
    Flexdemand[][96] Demands;   //dynamic array to store all flexdemands; for every operator there is one slot reserved to store his flexdemand for each timestep
    
    address[] admins;
    
    mapping(address => uint) usertype;  // 0 = owner, 1 = admin, 2 = prosumer, 3 = operator, 4 = smart meter
    mapping(uint => address) MaLoIDToOwnerAddress;
    mapping(uint => uint) MaLoIDToColumn;     //mapping to find the corresponding column in the offers-array for a certain unit
    mapping(address => uint) AddressToColumn;   //mapping to find the corresponding column in the demands-array for a certain operator
    
    mapping(address => uint) balances;
    
    address owner;
    
    
/* ---- modifiers ---- */    
    
    constructor() public{
        owner = msg.sender;
        admins.push(msg.sender);
        usertype[msg.sender] = 0;
        for(uint i=0; i<96; i++){
            MatchingResultCopy[i].push(MatchingPair(false, address(0), 10000000000, 0,0,0,0)); //initial entry in MatchingResults and MatchingResultCopy array 
            MatchingResult[i].push(MatchingPair(false, address(0), 10000000000, 0,0,0,0));
        }        
    }

    modifier onlyMarketOwner{
        require(msg.sender == owner);
        _;
    }
    
    modifier onlyAdmin(address _caller){
        require(usertype[_caller] == 1 || _caller == owner);
        _;
    }
    
    modifier onlyProsumer(address _caller){
        require(usertype[_caller] == 2 || usertype[_caller] == 1 || _caller == owner);
        _;
    }
    
    modifier onlyOperator(address _caller){
        require(usertype[_caller] == 3 || usertype[_caller] == 1 || _caller == owner);
        _;
    }    
    
    modifier onlyOfferOwner(uint _time, uint _MaLoID, address _caller){
        require(_caller == Offers[_time][MaLoIDToColumn[_MaLoID]].owner  || usertype[_caller] == 1 || _caller == owner);
        _;
    }
    
    modifier onlyDemandOwner(uint _time, address _caller){
        require(_caller == Demands[_time][AddressToColumn[_caller]].owner  || usertype[_caller] == 1 || _caller == owner);
        _;
    }
    
    modifier onlyUnitOwner(uint _MaLoID, address _caller){
        require(MaLoIDToOwnerAddress[_MaLoID] == _caller  ||usertype[_caller] == 1 || _caller == owner);
        _;
    }
    
    modifier onlySmartMeter(address _caller){
        require(usertype[_caller] == 4);
        _;
    }
    
/* ---- functions ---- */  

    //adds a new admin to the admins array
    function addAdmin(address _newAdmin) onlyMarketOwner public{
        admins.push(_newAdmin);
        usertype[_newAdmin] = 1;
    } 
    
}