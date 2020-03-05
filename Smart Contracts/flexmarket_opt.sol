pragma solidity ^0.5.1;

import "./registration.sol";

contract Flexmarket_Opt is Registration{
    
    constructor(uint _totalTokens) Registration(_totalTokens) public {}

/* ---- functions ---- */

    //add flexoffer to the flexoffer-array; decide whether pos or neg flex is offered; only Prosumers with registered units can transmit Offers for these units
    function transmitFlexoffer(uint _time, uint _MaLoID, string memory _kind, uint _power, uint _energy, uint _price) 
    onlyUnitOwner(_MaLoID, msg.sender)
    public 
    returns(bool)
    {
        require(checkOffer(_time, _kind, _power, _energy),"checkOffer did not work!");
        if(keccak256(abi.encodePacked(_kind)) == keccak256(abi.encodePacked("neg"))){
            Offers[_time][MaLoIDToColumn[_MaLoID]] = Flexoffer(msg.sender, _MaLoID, _time, _power, _energy, _price, false , false);
        }
        else{
            Offers[_time][MaLoIDToColumn[_MaLoID]] = Flexoffer(msg.sender, _MaLoID, _time, _power, _energy, _price, true, false);
        }
        transfer(owner, (_energy*_price)/10); //transfer 10% of the total price to the market as a deposit
        return true;
    }

    //timestamp 0-95, power and energy != 0, kind = neg or pos
    function checkOffer(uint _time, string memory _kind, uint _power, uint _energy)
    private pure
    returns(bool){
        if(_time <= 95 && _power != 0 && _energy != 0){
            if(keccak256(abi.encodePacked(_kind)) == keccak256(abi.encodePacked("neg")) || keccak256(abi.encodePacked(_kind)) == keccak256(abi.encodePacked("pos"))){
                return true;
            }
        }
        else{
            return false;
        }
    }

    //function that allows prosumers to delete their offers
    function deleteOffer(uint _time, uint _MaLoID) 
    onlyOfferOwner(_time, _MaLoID, msg.sender)
    public 
    returns(bool){
        Offers[_time][MaLoIDToColumn[_MaLoID]] = Flexoffer(msg.sender, _MaLoID, 0,0,0,0, false, false);
        transferFrom(owner, msg.sender, (Offers[_time][MaLoIDToColumn[_MaLoID]].price * Offers[_time][MaLoIDToColumn[_MaLoID]].energy)/100);   //refund deposit
        return true;
    }

    //add flexdemand to the flexdemand-array; decide whether pos or neg flex is needed
    function transmitFlexdemand(uint _time, string memory _kind, uint _power, uint _energy, uint _maxPrice) 
    onlyOperator(msg.sender)
    public 
    returns(bool){
        require(checkDemand(_time, _kind, _power, _energy));
        if(keccak256(abi.encodePacked(_kind)) == keccak256(abi.encodePacked("neg"))){
            Demands[_time][AddressToColumn[msg.sender]] = Flexdemand(msg.sender, _time, _power, _energy, _maxPrice, false, false);
        }
        else{
            Demands[_time][AddressToColumn[msg.sender]] = Flexdemand(msg.sender, _time, _power, _energy, _maxPrice, true, false);
        }
        
        return true;
    }

    //timestamp 0-95, power and energy != 0, kind = neg or pos    
    function checkDemand(uint _time, string memory _kind, uint _power, uint _energy)
    private pure
    returns(bool){
        if(_time <= 95 && _power != 0 && _energy != 0){
            if(keccak256(abi.encodePacked(_kind)) == keccak256(abi.encodePacked("neg")) || keccak256(abi.encodePacked(_kind)) == keccak256(abi.encodePacked("pos"))){
                return true;
            }
        }
        else{
            return false;
        }
    }

    //function that allows operators to delete their demand   
    function deleteDemand(uint _time)
    onlyDemandOwner(_time, msg.sender) 
    public
    returns(bool){
        Demands[_time][AddressToColumn[msg.sender]] = Flexdemand(msg.sender, 0,0,0,0, false, false);
        return true;
    }

    //function called by the smart meter to verify the delivered flexibility
    function verifyDelivery(uint _MaLoID, uint _time, uint _delEnergy)
    onlySmartMeter(msg.sender)
    public{
        for(uint i = 0; i<numberOfUnits+numberOfOperators; i++){
            if(keccak256(abi.encodePacked(_MaLoID)) == keccak256(abi.encodePacked(MatchingResultCopy[_time][i].MaLoID))){
                if(_delEnergy == 0 && MatchingResultCopy[_time][i].flextype == false){ //no delivery of negative flex
                    //penalty: not refunding the deposit
                    transferFrom(owner, Offers[_time][MaLoIDToColumn[MatchingResultCopy[_time][i].MaLoID]].owner, MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy);        //refund fee to prosumer
                }
                if(_delEnergy == 0 && MatchingResultCopy[_time][i].flextype == true){ //no delivery of positive flex
                    //penalty: not refunding the deposit
                    transferFrom(owner, Demands[_time][AddressToColumn[MatchingResultCopy[_time][i].demandOwner]].owner, MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy);        //refund fee to operator
                }
                if(_delEnergy <= MatchingResultCopy[_time][i].energy && MatchingResultCopy[_time][i].flextype == false){  //partial delivery of negative flex
                    uint share = (_delEnergy * 100) / MatchingResultCopy[_time][i].energy;    //calculate shares
                    transferFrom(owner, Demands[_time][AddressToColumn[MatchingResultCopy[_time][i].demandOwner]].owner, (MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy * share) / 100);         //credit fee to operator
                    transferFrom(owner, Offers[_time][MaLoIDToColumn[MatchingResultCopy[_time][i].MaLoID]].owner, (MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy * (100 - share)) / 100);        //refund fee to prosumer
                    _delEnergy = 0;
                }
                if(_delEnergy <= MatchingResultCopy[_time][i].energy && MatchingResultCopy[_time][i].flextype == true){ //partial delivery of positive flex
                    uint share = (_delEnergy * 100) / MatchingResultCopy[_time][i].energy;     //calculate shares
                    transferFrom(owner, Offers[_time][MaLoIDToColumn[MatchingResultCopy[_time][i].MaLoID]].owner, (MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy * share) / 100);                //credit fee to prosumer
                    transferFrom(owner, Demands[_time][AddressToColumn[MatchingResultCopy[_time][i].demandOwner]].owner, (MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy * (100 - share)) / 100); //refund fee to operator
                    _delEnergy = 0;
                }
                if(_delEnergy >= MatchingResultCopy[_time][i].energy && MatchingResultCopy[_time][i].flextype == false){  //full delivery of negative flex
                    transferFrom(owner, Offers[_time][MaLoIDToColumn[MatchingResultCopy[_time][i].MaLoID]].owner, MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy / 10);       //refund deposit
                    transferFrom(owner, Demands[_time][AddressToColumn[MatchingResultCopy[_time][i].demandOwner]].owner, MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy);     //credit fee to operator
                    _delEnergy = _delEnergy - MatchingResultCopy[_time][i].energy;
                }
                if(_delEnergy >= MatchingResultCopy[_time][i].energy && MatchingResultCopy[_time][i].flextype == true){   //full delivery of positive flex
                    transferFrom(owner, Offers[_time][MaLoIDToColumn[MatchingResultCopy[_time][i].MaLoID]].owner, MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy / 10);       //refund deposit
                    transferFrom(owner, Offers[_time][MaLoIDToColumn[MatchingResultCopy[_time][i].MaLoID]].owner, MatchingResultCopy[_time][i].price * MatchingResultCopy[_time][i].energy);            //credit fee to prosumer
                    _delEnergy = _delEnergy - MatchingResultCopy[_time][i].energy;
                }
            }
        }
    }

    //filters all offers with the relevant timestamp for the matching and stores them in the MatchingOffers array
    function filterOffers(uint _timestep) 
    onlyAdmin(msg.sender)
    public{
        //preset the MatchingOffer array with empty entries (one for each unit)
        for(uint i = 0; i<numberOfMatchingOffers; i++){
            MatchingOffers[i] = Flexoffer(address(0), 10000000000, 0, 0, 0, 999999999999999999999999999, false , true);
        }
        while(MatchingOffers.length < numberOfUnits){
                    MatchingOffers.push(Flexoffer(address(0), 10000000000, 0, 0, 0, 999999999999999999999999999, false , true));
                }
        numberOfMatchingOffers = 0;
        for(uint i = 0; i<numberOfUnits; i++){
            if(Offers[_timestep][i].power != 0 && Offers[_timestep][i].called == false){
                MatchingOffers[numberOfMatchingOffers] = Offers[_timestep][i];
                numberOfMatchingOffers++;           
            }
        }
    }

    //Sebastian Option
    function sortSebOffers() public {

        uint s;
        for (uint i = 0; i < MatchingOffers.length; i++) {            
            helper[i] = 0;
            // Compare the current element to all items that have already been sorted
            for (uint j = 0; j < i; j++){                
                // If the item is smaller than the item it is compared against, sort it accordingly.
                if (MatchingOffers[i].price < MatchingOffers[j].price && MatchingOffers[i].energy !=0) {                    
                    // The first time the new value is smaller than a sorted entry, set the mapping to that entry
                    if(helper[i] == 0){
                        helper[i] = helper[j];
                    }                    
                    /* Every time the new value is smaller than the (already sorted) value it is compared against,
                    ** increment the index of the bigger item in the sorted array. */
                    helper[j] = helper[j] + 1;                    
                    if(helper[j] == helper[i]){
                        helper[i] = helper[i]-1;
                        for(uint k=0; k<i;k++){
                            s = helper[i];
                            if(s == helper[k]){
                                helper[i] = helper[i] -1;
                                k=0;
                            }
                        }
                    }
                }            }
            // Catch every entry that is larger than all previously sorted items
            if(helper[i] == 0) {
                helper[i] = i + 1;
            }
        }        /* Initialize the sortedArray to the same size as the testStructArray. Skip as many entries as !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        ** the sortedArray already has, otherwise the sortedArray would double in size each time the
        ** function is called.*/
        uint lengthSortedArray = sortedOffers.length;
        for (uint i = 0; i < MatchingOffers.length; i++) {
            if (i < lengthSortedArray) continue;
            sortedOffers.push(Flexoffer(address(0), 10000000000, 0, 0, 0, 0, false , true));      }        
            /* Go over the MatchingOffers-Array and copy the items to sortedOffers to the positions specified in
        ** the helper mapping. At this point subtract the added 1, to get the real index */
        for (uint i = 0; i < MatchingOffers.length; i++) {
            sortedOffers[helper[i]-1] = MatchingOffers[i];
        }
    }
    
    //sorts offers from lower to higher prices; sorting result is stored in "sortedOffers[]"
    function sortOffers() 
    onlyAdmin(msg.sender)
    public {

        // Loop through the original array to sort it
        for (uint i = 0; i < MatchingOffers.length; i++) {

            /* Set the helper mapping to 0 initially. Later on all mapping entries will be the actual index +1.
            ** This is done, because an element larger than all compared elements will keep its 0 mapping
            ** throughout all comparisons and is assigned the new largest index in the end. If the acutal
            ** idices were used, an element smaller than all others might falsely be assigned the largest
            ** index, because it got through the comparisons with mapping value 0.*/
            helper[i] = 0;

            // Compare the current element to all items that have already been sorted
            for (uint j = 0; j < i; j++){

                // If the item is smaller than the item it is compared against, sort it accordingly.
                if (MatchingOffers[i].price < MatchingOffers[j].price) {

                    // The first time the new value is smaller than a sorted entry, set the mapping to that entry
                    if(helper[i] == 0){
                        helper[i] = helper[j];
                    }

                    /* Every time the new value is smaller than the (already sorted) value it is compared against,
                    ** increment the index of the bigger item in the sorted array. */
                    helper[j] = helper[j] + 1;
                }
            }

            // Catch every entry that is larger than all previously sorted items
            if(helper[i] == 0) {
                helper[i] = i + 1;
            }
        }

        /* Initialize the sortedArray to the same size as the testStructArray. Skip as many entries as
        ** the sortedArray already has, otherwise the sortedArray would double in size each time the
        ** function is called.*/
        uint lengthSortedArray = sortedOffers.length;
        for (uint i = 0; i < MatchingOffers.length; i++) {
            if (i < lengthSortedArray) continue;
            sortedOffers.push(Flexoffer(address(0), 10000000000, 0, 0, 0, 0, false , true));
        }

        /* Go over the MatchingOffers-Array and copy the items to sortedOffers to the positions specified in
        ** the helper mapping. At this point subtract the added 1, to get the real index */
        for (uint i = 0; i < MatchingOffers.length; i++) {
            sortedOffers[helper[i]-1] = MatchingOffers[i];
        }
    }  


    function quicksortOffers() 
    onlyAdmin(msg.sender)
    public{
       quickSortOffersInt(0, MatchingOffers.length);
    }
   
    function quickSortOffersInt(uint offers_left, uint offers_right) 
    public{

        uint i = offers_left;
        uint j = offers_right;
        
        if(i==j) return;

        uint pivot = MatchingOffers[offers_left + (offers_right - offers_left) / 2].price;
        while (i <= j) {
            while (MatchingOffers[i].price < pivot) 
                i++;
            while (pivot < MatchingOffers[j].price) 
                j--;
            if (i <= j) {
                MatchingOffers[i] = MatchingOffers[j];
                sortedOffers[i] = MatchingOffers[j];
                MatchingOffers[j] = MatchingOffers[i];
                sortedOffers[j] = MatchingOffers[i];
                i++;
                j--;
            }
        }
        if (offers_left < j)
            quickSortOffersInt(offers_left, j);
        if (i < offers_right)
            quickSortOffersInt(i, offers_right);
    }

   /*  //filters all demands with the relevant timestamp for the matching and stores them in the MatchingDemands array
    function filterDemands(uint _timestep) 
    onlyAdmin(msg.sender)
    public{
        //preset the MatchingDemands array with empty entries (one for each operator)
        for(uint i = 0; i<numberOfMatchingDemands; i++){
            MatchingDemands[i] = Flexdemand(address(0), 0, 0, 0, 999999999999999999999999999, false , true);
        }
        while(MatchingDemands.length < numberOfOperators){
                    MatchingDemands.push(Flexdemand(address(0), 0, 0, 0, 999999999999999999999999999, false , true));
                }
        numberOfMatchingDemands = 0;
        for(uint i = 0; i<numberOfOperators; i++){
            if(Demands[_timestep][i].power != 0 && Demands[_timestep][i].called == false){
                MatchingDemands[numberOfMatchingDemands] = Demands[_timestep][i];
                numberOfMatchingDemands++;                
            }
        }
    } */

    //Sebastian Option
    function filtersortSebDemands(uint _timestep) public {

        for(uint i = 0; i<numberOfMatchingDemands; i++){
            MatchingDemands[i] = Flexdemand(address(0), 0, 0, 0, 999999999999999999999999999, false , true);
        }
        while(MatchingDemands.length < numberOfOperators){
                    MatchingDemands.push(Flexdemand(address(0), 0, 0, 0, 999999999999999999999999999, false , true));
                }
        numberOfMatchingDemands = 0;
        for(uint i = 0; i<numberOfOperators; i++){
            if(Demands[_timestep][i].power != 0 && Demands[_timestep][i].called == false){
                MatchingDemands[numberOfMatchingDemands] = Demands[_timestep][i];
                numberOfMatchingDemands++;                
            }
        }

        uint s;
        for (uint i = 0; i < MatchingDemands.length; i++) {            
            helper[i] = 0;
            // Compare the current element to all items that have already been sorted
            for (uint j = 0; j < i; j++){                
                // If the item is smaller than the item it is compared against, sort it accordingly.
                if (MatchingDemands[i].maxPrice < MatchingDemands[j].maxPrice && MatchingDemands[i].energy !=0) {                    
                    // The first time the new value is smaller than a sorted entry, set the mapping to that entry
                    if(helper[i] == 0){
                        helper[i] = helper[j];
                    }                    
                    /* Every time the new value is smaller than the (already sorted) value it is compared against,
                    ** increment the index of the bigger item in the sorted array. */
                    helper[j] = helper[j] + 1;                    
                    if(helper[j] == helper[i]){
                        helper[i] = helper[i]-1;
                        for(uint k=0; k<i;k++){
                            s = helper[i];
                            if(s == helper[k]){
                                helper[i] = helper[i] -1;
                                k=0;
                            }
                        }
                    }
                }            }
            // Catch every entry that is larger than all previously sorted items
            if(helper[i] == 0) {
                helper[i] = i + 1;
            }
        }        /* Initialize the sortedArray to the same size as the testStructArray. Skip as many entries as !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        ** the sortedArray already has, otherwise the sortedArray would double in size each time the
        ** function is called.*/
        uint lengthSortedArray = sortedDemands.length;
        for (uint i = 0; i < MatchingDemands.length; i++) {
            if (i < lengthSortedArray) continue;
            sortedDemands.push(Flexdemand(address(0), 0, 0, 0, 0, false , false));        }        
            /* Go over the MatchingOffers-Array and copy the items to sortedOffers to the positions specified in
        ** the helper mapping. At this point subtract the added 1, to get the real index */
        for (uint i = 0; i < MatchingDemands.length; i++) {
            sortedDemands[helper[i]-1] = MatchingDemands[i];
        }
    }

    //sorts demands from low to higher maxPrices; sorting result is stored in "sortedDemands[]"
    function sortDemands() 
    onlyAdmin(msg.sender)
    public {

        // Loop through the original array to sort it
        for (uint i = 0; i < MatchingDemands.length; i++) {

            /* Set the mapping to 0 initially. Later on all mapping entries will be the actual index +1.
            ** This is done, because an element larger than all compared elements will keep its 0 mapping
            ** throughout all comparisons and is assigned the new largest index in the end. If the acutal
            ** idexes were used, an element smaller than all others might falsely be assigned the largest
            ** index, because it got through the comparisons with mapping value 0.*/
            helper[i] = 0;

            // Compare the current element to all items that have already been sorted
            for (uint j = 0; j < i; j++){

                // If the item is smaller than the item it is compared against, sort it accordingly.
                if (MatchingDemands[i].maxPrice < MatchingDemands[j].maxPrice) {

                    // The first time the new value is smaller than a sorted entry, set the mapping to that entry
                    if(helper[i] == 0){
                        helper[i] = helper[j];
                    }

                    /* Every time the new value is smaller than the (already sorted) value it is compared against,
                    ** increment the index of the bigger item in the sorted array. */
                    helper[j] = helper[j] + 1;
                }
            }

            // Catch every entry that is larger than all previously sorted items
            if(helper[i] == 0) {
                helper[i] = i + 1;
            }
        }

        /* Initialize the sortedArray to the same size as the testStructArray. Skip as many entries as
        ** the sortedArray already has, otherwise the sortedArray would double in size each time the
        ** function is called.*/
        uint lengthSortedArray = sortedDemands.length;
        for (uint i = 0; i < MatchingDemands.length; i++) {
            if (i < lengthSortedArray) continue;
            sortedDemands.push(Flexdemand(address(0), 0, 0, 0, 0, false , false));
        }

        /* Go over the MatchingDemands-Array and copy the items to sortedDemands to the positions specified in
        ** the helper mapping. At this point subtract the added 1, to get the real index */
        for (uint i = 0; i < MatchingDemands.length; i++) {
            sortedDemands[helper[i]-1] = MatchingDemands[i];
        }
    }  
    
    function quicksortDemands() 
    onlyAdmin(msg.sender)
    public 
    {
       quickSortDemandsInt(0, MatchingDemands.length);
    }
   
    function quickSortDemandsInt(uint demands_left, uint demands_right) 
    public 
    {

        uint i = demands_left;
        uint j = demands_right;
        
        if(i==j) return;

        uint pivot = MatchingDemands[demands_left + (demands_right - demands_left) / 2].maxPrice;
        while (i <= j) {
            while (MatchingDemands[i].maxPrice < pivot) 
                i++;
            while (pivot < MatchingDemands[j].maxPrice) 
                j--;
            if (i <= j) {
                MatchingDemands[i] = MatchingDemands[j];
                sortedDemands[i] = MatchingDemands[j];
                MatchingDemands[j] = MatchingDemands[i];
                sortedDemands[j] = MatchingDemands[i];
                i++;
                j--;
            }
        }
        if (demands_left < j) return;
            quickSortDemandsInt(demands_left, j);
        if (i < demands_right) return;
            quickSortDemandsInt(i, demands_right);
    }
    // market clearing function

    function matching(uint _time)
    onlyAdmin(msg.sender)
    public{
            //extend MatchingResult array in case of new units or operators
            for(uint i = numberOfMatchingResults[_time]; i<(numberOfUnits+numberOfOperators+1); i++){
                if(MatchingResult[_time].length < i){
                    MatchingResult[_time].push(MatchingPair(false, address(0), 10000000000, 0,0,0,0));
                }
            }

            //iterate through all demands
            for(uint i=0; i<sortedDemands.length; i++){
                uint j = 0;
                while(sortedDemands[i].called == false && j<sortedOffers.length){
                    //iterate through the offers
                    for(j; j<sortedOffers.length; j++){
                        //flextype suitbale?
                        if(sortedOffers[j].flextype == sortedDemands[i].flextype && sortedOffers[j].called == false && sortedDemands[i].called == false){
                            //check whether offer price is lower than the maximum price the DSO/TSO would pay
                            if(sortedOffers[j].price <= sortedDemands[i].maxPrice){
                                //is enough power offered?
                                if(sortedOffers[j].power > sortedDemands[i].power){
                                    sortedOffers[j].power = sortedOffers[j].power - sortedDemands[i].power; //available offered power is reduced by already matched power
                                    //is enough energy offered?
                                    if(sortedOffers[j].energy > sortedDemands[i].energy){
                                        sortedOffers[j].energy = sortedOffers[j].energy - sortedDemands[i].energy; //available offered energy is reduced by already matched energy
                                        MatchingResult[_time][numberOfMatchingResults[_time]] = MatchingPair(sortedOffers[j].flextype, sortedDemands[i].owner, sortedOffers[j].MaLoID, sortedOffers[j].price, sortedDemands[i].power, sortedDemands[i].energy, _time);
                                        numberOfMatchingResults[_time]++;
                                        sortedDemands[i].called = true;
                                        sortedOffers[j].called = true;
                                    }
                                    else{//less energy is offered than requested
                                        sortedDemands[i].energy = sortedDemands[i].energy - sortedOffers[j].energy; //store amount of energy that is still needed
                                        MatchingResult[_time][numberOfMatchingResults[_time]] = MatchingPair(sortedOffers[j].flextype, sortedDemands[i].owner, sortedOffers[j].MaLoID, sortedOffers[j].price, sortedDemands[i].power, sortedOffers[j].energy, _time);
                                        numberOfMatchingResults[_time]++;
                                        sortedOffers[j].energy = 0;
                                        sortedOffers[j].power = 0;
                                        sortedOffers[j].called = true;
                                        sortedDemands[i].called = true;
                                    }
                                }
                                else{//less power is offered than requested
                                    sortedDemands[i].power = sortedDemands[i].power - sortedOffers[j].power; //store amount of power that is still needed
                                    //is enough energy offered?
                                    if(sortedOffers[j].energy > sortedDemands[i].energy){
                                        MatchingResult[_time][numberOfMatchingResults[_time]] = MatchingPair(sortedOffers[j].flextype, sortedDemands[i].owner, sortedOffers[j].MaLoID, sortedOffers[j].price, sortedOffers[j].power, sortedDemands[i].energy, _time);
                                        numberOfMatchingResults[_time]++;
                                        sortedDemands[i].called = true;
                                    }
                                    else{//less power AND less energy is offered than requested
                                        sortedDemands[i].energy = sortedDemands[i].energy - sortedOffers[j].energy; //store amount of energy that is still needed
                                        MatchingResult[_time][numberOfMatchingResults[_time]] = MatchingPair(sortedOffers[j].flextype, sortedDemands[i].owner, sortedOffers[j].MaLoID, sortedOffers[j].price, sortedOffers[j].power, sortedOffers[j].energy, _time);
                                        numberOfMatchingResults[_time]++;
                                    }
                                    sortedOffers[j].power = 0;
                                    sortedOffers[j].energy = 0;
                                    sortedOffers[j].called = true;
                                }
                                Offers[_time][MaLoIDToColumn[sortedOffers[j].MaLoID]].called = true;
                                //delete all following offers of same MaLoID
                                /*
                                uint t = _time+1;
                                for(uint k = 0; k<95; k++){
                                    if(t>95){
                                        t = 0;
                                    }
                                    if(Offers[t][MaLoIDToColumn[sortedOffers[j].MaLoID]].power != 0){
                                        Offers[t][MaLoIDToColumn[sortedOffers[j].MaLoID]] = Flexoffer(sortedOffers[j].owner, sortedOffers[j].MaLoID, 0,0,0,0, false, false);
                                    }
                                    t = t+1;
                                }*/
                            }//price too high --> go to next offer
                        }//flextype not suitbale -> go to next offer
                    }
                }
            }        
    }

    //Copy matching results for current timestep before they get overwritten by the next matching process
    function copyResult(uint _time) 
    onlyAdmin(msg.sender)
    public{
        for(uint i = 0; i<MatchingResult[_time].length; i++){
            if(MatchingResultCopy[_time].length >= MatchingResult[_time].length){
                MatchingResultCopy[_time][i] = MatchingResult[_time][i];
            }
            else{
                MatchingResultCopy[_time].push(MatchingResult[_time][i]);
            }
            //delete data from original array
            MatchingResult[_time][i] = MatchingPair(false, address(0), 0, 0,0,0,0);
        }
        numberOfMatchingResults[_time] = 0;
    }

    //view Matching results offchain
    function getMatchingResult(uint _time) 
    onlyAdmin(msg.sender)
    public view 
    returns(bool[] memory flextype, uint[] memory price, uint[] memory power, uint[] memory energy, uint[] memory time){
        uint length = MatchingResult[_time].length;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        uint[] memory tm = new uint[](length);
        for(uint i = 0; i<length; i++){
           flxtp[i] = MatchingResult[_time][i].flextype;
           prc[i] = MatchingResult[_time][i].price;
           pwr[i] = MatchingResult[_time][i].power;
           engy[i] = MatchingResult[_time][i].energy;
           tm[i] = MatchingResult[_time][i].time;
        }
        return (flxtp, prc, pwr, engy, tm);
    }
    
    function getMatchingMarketID(uint _time) 
    onlyAdmin(msg.sender)
    public view 
    returns(uint[] memory MaLoID){
        uint length = MatchingResult[_time].length;
        uint[] memory mli = new uint[](length);
        for(uint i = 0; i<length; i++){
           mli[i] = MatchingResult[_time][i].MaLoID;
        }
        return (mli);
    }

//view copied Matching results offchain
    function getMatchingResultCopy(uint _time) 
    onlyAdmin(msg.sender)
    public view 
    returns(bool[] memory flextype, uint[] memory price, uint[] memory power, uint[] memory energy, uint[] memory time){
        uint length = MatchingResultCopy[_time].length;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        uint[] memory tm = new uint[](length);
        for(uint i = 0; i<length; i++){
           flxtp[i] = MatchingResultCopy[_time][i].flextype;
           prc[i] = MatchingResultCopy[_time][i].price;
           pwr[i] = MatchingResultCopy[_time][i].power;
           engy[i] = MatchingResultCopy[_time][i].energy;
           tm[i] = MatchingResultCopy[_time][i].time;
        }
        return (flxtp, prc, pwr, engy, tm);
    }
    
    function getMatchingMarketIDCopy(uint _time) 
    onlyAdmin(msg.sender)
    public view 
    returns(uint[] memory MaLoID){
        uint length = MatchingResultCopy[_time].length;
        uint[] memory mli = new uint[](length);
        for(uint i = 0; i<length; i++){
           mli[i] = MatchingResultCopy[_time][i].MaLoID;
        }
        return (mli);
    }
    //view all active offers for a certain MaLoID
    /*function getOffersUnit(uint _MaLoID) 
    onlyUnitOwner(_MaLoID, msg.sender)
    public view
    returns(bool[] memory flextype, uint[] memory power, uint[] memory price, uint[] memory energy){
        uint length = 96;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        for(uint i = 0; i<96; i++){
            if(Offers[i][MaLoIDToColumn[_MaLoID]].power != 0){
                flxtp[i] = Offers[i][MaLoIDToColumn[_MaLoID]].flextype;
                prc[i] = Offers[i][MaLoIDToColumn[_MaLoID]].price;
                pwr[i] = Offers[i][MaLoIDToColumn[_MaLoID]].power;
                engy[i] = Offers[i][MaLoIDToColumn[_MaLoID]].energy;
            }
        }
        return(flxtp, pwr, prc, engy);
    }*/

    //view all active offers for a certain timestep
    function getOffersTime(uint _time)
    onlyAdmin(msg.sender)
    public view
    returns(bool[] memory flextype, uint[] memory power, uint[] memory price, uint[] memory energy){
        uint length = numberOfUnits;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        for(uint i = 0; i<numberOfUnits;i++){
            if(Offers[_time][i].power != 0){
                flxtp[i] = Offers[_time][i].flextype;
                prc[i] = Offers[_time][i].price;
                pwr[i] = Offers[_time][i].power;
                engy[i] = Offers[_time][i].energy;
            }
        }
        return(flxtp, pwr, prc, engy);
    }

    function getOffersMaLoIdTime(uint _time) 
    onlyAdmin(msg.sender)
    public view 
    returns(uint[] memory MaLoID){
        uint length = Offers[_time].length;
        uint[] memory mli = new uint[](length);
        for(uint i = 0; i<length; i++){
           mli[i] = Offers[_time][i].MaLoID;
        }
        return (mli);
    }
    
    //view all sortedOffers
    /*function getSortedOffersTime(uint _time)
    onlyAdmin(msg.sender)
    public view
    returns(bool[] memory flextype, uint[] memory power, uint[] memory price, uint[] memory energy){
        uint length = numberOfUnits;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        for(uint i = 0; i<numberOfUnits;i++){
            if(sortedOffers[_time].power != 0){
                flxtp = sortedOffers[_time].flextype;
                prc = sortedOffers[_time].price;
                pwr = sortedOffers[_time].power;
                engy = sortedOffers[_time].energy;
            }
        }
        return(flxtp, pwr, prc, engy);
    }*/

    //view all active demands of an operator
    function getDemandsOp() 
    onlyOperator(msg.sender)
    public view
    returns(bool[] memory flextype, uint[] memory power, uint[] memory price, uint[] memory energy){
        uint length = 96;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        for(uint i = 0; i<96; i++){
            if(Demands[i][AddressToColumn[msg.sender]].power != 0){
                flxtp[i] = Demands[i][AddressToColumn[msg.sender]].flextype;
                prc[i] = Demands[i][AddressToColumn[msg.sender]].maxPrice;
                pwr[i] = Demands[i][AddressToColumn[msg.sender]].power;
                engy[i] = Demands[i][AddressToColumn[msg.sender]].energy;
            }
        }
        return(flxtp, pwr, prc, engy);
    }

    //view all active offers for a certain timestep
    function getDemandsTime(uint _time)
    onlyAdmin(msg.sender)
    public view
    returns(bool[] memory flextype, uint[] memory power, uint[] memory price, uint[] memory energy){
        uint length = numberOfOperators;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        for(uint i = 0; i<numberOfOperators;i++){
            if(Demands[_time][i].power != 0){
                flxtp[i] = Demands[_time][i].flextype;
                prc[i] = Demands[_time][i].maxPrice;
                pwr[i] = Demands[_time][i].power;
                engy[i] = Demands[_time][i].energy;
            }
        }
        return(flxtp, pwr, prc, engy);
    }
    
    function getDemandsOwnerTime(uint _time)
    onlyAdmin(msg.sender)
    public view
    returns(address[] memory owner){
        uint length = numberOfOperators;
        address[] memory add = new address[](length);
        for(uint i = 0; i<numberOfOperators;i++){
            if(Demands[_time][i].power != 0){
            add[i] = Demands[_time][i].owner;
        }
        }
        return(add);
        
    }
    
    /*function getSortedDemandsTime(uint _time)
    onlyAdmin(msg.sender)
    public view
    returns(bool[] memory flextype, uint[] memory power, uint[] memory price, uint[] memory energy){
        uint length = numberOfOperators;
        bool[] memory flxtp = new bool[](length);
        uint[] memory prc = new uint[](length);
        uint[] memory pwr = new uint[](length);
        uint[] memory engy = new uint[](length);
        for(uint i = 0; i<numberOfOperators;i++){
            if(Demands[_time][i].power != 0){
                flxtp[i] = sortedDemands[_time][i].flextype;
                prc[i] = sortedDemands[_time][i].maxPrice;
                pwr[i] = sortedDemands[_time][i].power;
                engy[i] = sortedDemands[_time][i].energy;
            }
        }
        return(flxtp, pwr, prc, engy);
    }*/

   function InitMatchingResult(uint _time, uint numberofmr)
   onlyAdmin(msg.sender)
   public
   {
    //extend MatchingResult array in case of new units or operators
            for(uint i = numberOfMatchingResults[_time]; i<numberofmr; i++){
                if(MatchingResult[_time].length < i){
                    MatchingResult[_time][i] = MatchingPair(false, address(0), 10000000000, 0,0,0,0);
                }
            }
   }

    function MatchingPairTransfer(bool flextype, uint MaLoID, uint price, uint power, uint energy, uint _time, uint i)
    onlyAdmin(msg.sender)
    public
    {
        address a = 0xB9786cCbe3Bba11078ec13A5e14e0980231D6693;
        MatchingResult[_time][i] = MatchingPair(flextype, address(a), MaLoID, price, power, energy, _time);
        
        /*MatchingResult[_time][i].flextype = flextype;
        MatchingResult[_time][i].demandOwner = a;
        MatchingResult[_time][i].MaLoID = MaLoID;
        MatchingResult[_time][i].price = price;
        MatchingResult[_time][i].power = power;
        MatchingResult[_time][i].energy = energy;
        MatchingResult[_time][i].time = _time;*/
        
    }
    
}