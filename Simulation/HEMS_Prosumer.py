# -*- coding: utf-8 -*-

import web3
import json
import timeit
import math
import random
import time
import pandas as pd
import random
from timeit import Timer
from web3 import Web3, IPCProvider, HTTPProvider

web3 = Web3(HTTPProvider("http://localhost:8501"))
Flexmarket_address = web3.toChecksumAddress("0x3c375af1aac69f7af48b19ad06231f6633251b2e")

with open("ABI.json") as f:
    abi = json.load(f)

Flexmarket_contract = web3.eth.contract(abi = abi, address = Flexmarket_address)

#registration prosumer
print(web3.eth.accounts)
web3.parity.personal.unlockAccount(web3.eth.accounts[0], "PassProsumer", None)
web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.registrationPro("Prosumer").transact({'from': web3.eth.accounts[0]}))
print('Prosumer created!')


for x in range(101,201):
    start_time = time.time()
    MaLoID = 10000000000 + x

    #read flexiblity offers from excel file
    offers = pd.read_excel("Flexoffers//20190321_FLEX_"+str(x-100)+".xlsx",error_bad_lines=False);

    #convert € to ct
    offers['NegPreis'] = offers['NegPreis'] * 100
    offers['PosPreis'] = offers['PosPreis'] * 100

    #convert kW to W
    offers['NegLeistung'] = offers['NegLeistung'] * 1000
    offers['NegEnergie'] = offers['NegEnergie'] * 1000
    offers['PosLeistung'] = offers['PosLeistung'] * 1000
    offers['PosEnergie'] = offers['PosEnergie'] * 1000

    #registration unit
    web3.parity.personal.unlockAccount(web3.eth.accounts[0], "PassProsumer", None)
    web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.registrationUnit("EV", MaLoID, 9999).transact({'from': web3.eth.accounts[0]}))

    print('Unit created by Prosumer!')

    print("\nOffers for MaLoID", MaLoID,":")
    time.sleep(1)
    
    #send offers to the market smart contract
    for i in range(len(offers.index)):
        if (offers.loc[i]['NegLeistung'] != 0): #negative flexoffer
            web3.parity.personal.unlockAccount(web3.eth.accounts[0], "PassProsumer", None)
            Flexmarket_contract.functions.transmitFlexoffer(i, MaLoID, "neg", int(offers.loc[i]['NegLeistung']), int(offers.loc[i]['NegEnergie']), int(offers.loc[i]['NegPreis'])).transact({'from': web3.eth.accounts[0]})
            print("Timestep",i,":",int(offers.loc[i]['NegLeistung']),"W negative flexoffer transmitted")
        elif(offers.loc[i]['PosLeistung'] != 0): #positive flexoffer
            web3.parity.personal.unlockAccount(web3.eth.accounts[0], "PassProsumer", None)
            Flexmarket_contract.functions.transmitFlexoffer(i, MaLoID, "pos", int(offers.loc[i]['PosLeistung']), int(offers.loc[i]['PosEnergie']), int(offers.loc[i]['PosPreis'])).transact({'from': web3.eth.accounts[0]})
            print("Timestep",i,":",int(offers.loc[i]['PosLeistung']),"W positive flexoffer transmitted")
    endloop_time = time.time()
    print(f'\nTime for sending offer nr {i}: {endloop_time-start_time}')

end_time = time.time()

print(f'\nTime for HEMS_Prosumer: {end_time-start_time}')