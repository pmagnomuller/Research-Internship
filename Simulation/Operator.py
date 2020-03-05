# -*- coding: utf-8 -*-

import web3
import json
import math
import random
import time
import timeit
import matplotlib.pyplot as plt
import pandas as pd
import numpy as np

from web3 import Web3, IPCProvider, HTTPProvider


web3 = Web3(HTTPProvider("http://localhost:8501"))
Flexmarket_address = web3.toChecksumAddress("0x3c375af1aac69f7af48b19ad06231f6633251b2e")

with open("ABI.json") as f:
    abi = json.load(f)

Flexmarket_contract = web3.eth.contract(abi = abi, address = Flexmarket_address)

print(web3.eth.accounts)

power_limit = 7500000            # max. power in watts
max_price = 100                 # max price for flexibility
season = 'Winter'               # 'Summer' or 'Winter'
day = 'Weekday'                  # 'Weekday', 'Saturday' or 'Sunday'
ev_scenario = 'Evening'         # 'Morning' or 'Evening'
no_household = 3000
no_ev = 2000    
no_hp = 2000
no_nsh = 0
no_pv = 0

web3.parity.personal.unlockAccount(web3.eth.accounts[4], "PassOperator", None)
web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.registrationOp("operator", "dso").transact({'from': web3.eth.accounts[4]}))

loads = pd.read_excel('flexdemand.xlsx',sheet_name = "Tabelle1", header = (0,1), error_bad_lines=False);

demand = pd.DataFrame(index = loads.index)
demand['W'] = 0

start_time=time.time()

for i in range(len(loads.index)):
    demand.loc[i]['W'] = loads.loc[i]['Household, '+season,day]*no_household + loads.loc[i]['Electric Vehicle', ev_scenario]*no_ev + loads.loc[i]['Heating', 'Heat Pump']*no_hp + loads.loc[i]['Heating', 'Night Storage Heater']*no_nsh - loads.loc[i]['PV', season]*no_pv
    
for i in range(len(demand.index)):
    if(demand.loc[i]['W'] >= power_limit):
        web3.parity.personal.unlockAccount(web3.eth.accounts[4], "PassOperator", None)
        Flexmarket_contract.functions.transmitFlexdemand(i, "pos", int(demand.loc[i]['W']-power_limit), 1000000000, max_price).transact({'from': web3.eth.accounts[4]})
        print("Timestep",i,":", int(demand.loc[i]['W']-power_limit), "W positive flexdemand transmitted")
    elif(demand.loc[i]['W'] <= power_limit * -1):
        web3.parity.personal.unlockAccount(web3.eth.accounts[4], "PassOperator", None)
        Flexmarket_contract.functions.transmitFlexdemand(i, "neg", abs(int(demand.loc[i]['W']))-power_limit, 1000000000, max_price).transact({'from': web3.eth.accounts[4]})
        print("Timestep",i,":", int(demand.loc[i]['W']+power_limit), "W negative flexdemand transmitted")


print(f'Time for Operator to execute:{time.time()-start_time}')


