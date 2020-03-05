# -*- coding: utf-8 -*-

import web3
import json
import math
import random
import time
import pandas as pd
from datetime import datetime

from web3 import Web3, IPCProvider, HTTPProvider

web3 = Web3(HTTPProvider("http://localhost:8501"))
Flexmarket_address = web3.toChecksumAddress("0x66e71756522d77743e0c8c6f2c01482ccc5ab4d3")

with open("ABI.json") as f:
    abi = json.load(f)

Flexmarket_contract = web3.eth.contract(abi = abi, address = Flexmarket_address)

print(web3.eth.accounts)

web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.addSmartMeter(web3.eth.accounts[3], "EV").transact({'from': web3.eth.accounts[3]}))

t = 0
a = 0

'''for n in range(95):
    if (a > 95):
        a = 0
    print(f'Timestep: {a}')
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResultCopy(a).call({'from': web3.eth.accounts[3]})
    print(f'flextype: {flxtp} ,\nprice: {prc},\npower : {pwr},\nenergy : {engy},\ntm : {tm}')
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (mli) = Flexmarket_contract.functions.getMatchingMarketIDCopy(a).call({'from': web3.eth.accounts[3]})
    print(f'MaLoId :{mli} \n')
    a = a + 1'''

markettime = 15 #value in minutes
noOfTimesteps = 1440/markettime  #96
dt = datetime.now()
timestep = int((dt.hour * 3600 + dt.minute *60 + dt.second)/(markettime*60))

while True:
    time.sleep(1)
    dt = datetime.now()
    print('Working!')
    if((dt.hour * 3600 + dt.minute *60 + dt.second)%(markettime*60) == 0):
        print('\nStart Verify Delivery\n')
        if(timestep < noOfTimesteps-1):
            timestep = timestep +1
        else:
            timestep = 0

        #for x in range(95):
            #if (t > 95):
                #t = 0
        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResultCopy(timestep).call({'from': web3.eth.accounts[3]})
        #print(f'flextype: {flxtp} ,\nprice: {prc},\npower : {pwr},\nenergy : {engy},\ntm : {tm}')
        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (mli) = Flexmarket_contract.functions.getMatchingMarketIDCopy(timestep).call({'from': web3.eth.accounts[3]})
        #print(f'MaLoId :{mli} \n')

        t = t + 1
        x = 0

        for x in range(len(tm)):
                print(f'Verify Delivery nr {x} at timestep {timestep}')
                print(f'with mli: {mli[x]}, tm: {tm[x]}, engy: {engy[x]}\n')
                if (engy[x] == 0):
                    print('No Delivery to be verified!\n')
                    x = x + 1
                else:
                    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
                    web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.verifyDelivery(mli[x], tm[x], engy[x]).transact({'from': web3.eth.accounts[3]}))
                    print('Delivery done!\n')
                    x = x + 1


