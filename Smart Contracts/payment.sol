pragma solidity ^0.5.1;

import "./framework.sol";
import "./SafeMath.sol";
import "./erc20.sol";

contract Payment is Framework, ERC20{

    constructor(uint _totalTokens) public{
        totalTokens = _totalTokens;
        balances[owner] = totalTokens;
    }
    
    using SafeMath for uint;

/* ---- declaration of variables ---- */

    uint totalTokens;
    uint initialTokens = 100000000000;

/* ---- functions ---- */
    
    //returns number of total tokens
    function totalSupply() 
    onlyMarketOwner
    public view returns(uint){
        return totalTokens;
    }
    
    //returns token balance of an address
    function balanceOf(address _tokenOwner) public view returns(uint){
        return balances[_tokenOwner];
    }
    
    //transfers tokens from the message sender to a receiving account
    function transfer(address _to, uint _numTokens) public returns (bool success){
        require(_numTokens <= balances[msg.sender],"transfer did not work!");
        balances[msg.sender] = balances[msg.sender].sub(_numTokens);
        balances[_to] = balances[_to].add(_numTokens);
        //emit Transfer(msg.sender, _to, _numTokens);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint _numTokens) public returns (bool success){
        require(_numTokens <= balances[_from]);
        balances[_from] = balances[_from].sub(_numTokens);
        balances[_to] = balances[_to].add(_numTokens);
        emit Transfer(_from, _to, _numTokens);
        return true;
    }
    
    // transfer initial Tokens to a new Prosumer
    function initTokensPro(address _from, uint _numTokens) internal returns (bool){
        require(_numTokens <= balances[_from]);
        balances[Prosumers[numberOfProsumers].prosumerAddress] = balances[Prosumers[numberOfProsumers].prosumerAddress].add(_numTokens);
        balances[_from] = balances[_from].sub(_numTokens);
        emit Transfer(owner, Prosumers[numberOfProsumers].prosumerAddress, _numTokens);
        return true;
    }
    
    // transfer initial Tokens to a new Operator
    function initTokensOp(address _from, uint _numTokens) internal returns (bool){
        require(_numTokens <= balances[_from]);
        balances[Operators[numberOfOperators].operatorAddress] = balances[Operators[numberOfOperators].operatorAddress].add(_numTokens);
        balances[_from] = balances[_from].sub(_numTokens);
        emit Transfer(owner, Operators[numberOfOperators].operatorAddress, _numTokens);
        return true;
    }    
}