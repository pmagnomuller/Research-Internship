# -*- coding: utf-8 -*-
"""
Created on Wed Nov 13 10:11:17 2019

@author: ga62nok
"""

import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from web3 import Web3, IPCProvider, HTTPProvider

web3 = Web3(HTTPProvider("http://localhost:8501"))
Flexmarket_address = web3.toChecksumAddress("0x9227ecbcae2f2634754cde53c85e7a1f28ea2d5e")
Flexmarket_abi = '[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"tokens","type":"uint256"}],"name":"Transfer","type":"event"},{"constant":false,"inputs":[{"internalType":"address","name":"_newAdmin","type":"address"}],"name":"addAdmin","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_smartMeterAddress","type":"address"},{"internalType":"string","name":"_smartMeterUnit","type":"string"}],"name":"addSmartMeter","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"}],"name":"copyResult","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"}],"name":"deleteDemand","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"},{"internalType":"string","name":"_MaLoID","type":"string"}],"name":"deleteOffer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_timestep","type":"uint256"}],"name":"filterDemands","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_timestep","type":"uint256"}],"name":"filterOffers","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"}],"name":"matching","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_kind","type":"string"}],"name":"registrationOp","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"string","name":"_name","type":"string"}],"name":"registrationPro","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"string","name":"_kind","type":"string"},{"internalType":"string","name":"_MaLoID","type":"string"},{"internalType":"uint256","name":"_capacity","type":"uint256"}],"name":"registrationUnit","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"sortDemands","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"sortOffers","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_numTokens","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_numTokens","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"success","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"},{"internalType":"string","name":"_kind","type":"string"},{"internalType":"uint256","name":"_power","type":"uint256"},{"internalType":"uint256","name":"_energy","type":"uint256"},{"internalType":"uint256","name":"_maxPrice","type":"uint256"}],"name":"transmitFlexdemand","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"},{"internalType":"string","name":"_MaLoID","type":"string"},{"internalType":"string","name":"_kind","type":"string"},{"internalType":"uint256","name":"_power","type":"uint256"},{"internalType":"uint256","name":"_energy","type":"uint256"},{"internalType":"uint256","name":"_price","type":"uint256"}],"name":"transmitFlexoffer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"internalType":"string","name":"_MaLoID","type":"string"},{"internalType":"uint256","name":"_time","type":"uint256"},{"internalType":"uint256","name":"_delEnergy","type":"uint256"}],"name":"verifyDelivery","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_totalTokens","type":"uint256"}],"payable":false,"stateMutability":"nonpayable","type":"constructor"},{"constant":true,"inputs":[{"internalType":"address","name":"_tokenOwner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"getDemandsOp","outputs":[{"internalType":"bool[]","name":"flextype","type":"bool[]"},{"internalType":"uint256[]","name":"power","type":"uint256[]"},{"internalType":"uint256[]","name":"price","type":"uint256[]"},{"internalType":"uint256[]","name":"energy","type":"uint256[]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"}],"name":"getDemandsTime","outputs":[{"internalType":"bool[]","name":"flextype","type":"bool[]"},{"internalType":"uint256[]","name":"power","type":"uint256[]"},{"internalType":"uint256[]","name":"price","type":"uint256[]"},{"internalType":"uint256[]","name":"energy","type":"uint256[]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"}],"name":"getMatchingResult","outputs":[{"internalType":"bool[]","name":"flextype","type":"bool[]"},{"internalType":"uint256[]","name":"price","type":"uint256[]"},{"internalType":"uint256[]","name":"power","type":"uint256[]"},{"internalType":"uint256[]","name":"energy","type":"uint256[]"},{"internalType":"uint256[]","name":"time","type":"uint256[]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"uint256","name":"_time","type":"uint256"}],"name":"getOffersTime","outputs":[{"internalType":"bool[]","name":"flextype","type":"bool[]"},{"internalType":"uint256[]","name":"power","type":"uint256[]"},{"internalType":"uint256[]","name":"price","type":"uint256[]"},{"internalType":"uint256[]","name":"energy","type":"uint256[]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"internalType":"string","name":"_MaLoID","type":"string"}],"name":"getOffersUnit","outputs":[{"internalType":"bool[]","name":"flextype","type":"bool[]"},{"internalType":"uint256[]","name":"power","type":"uint256[]"},{"internalType":"uint256[]","name":"price","type":"uint256[]"},{"internalType":"uint256[]","name":"energy","type":"uint256[]"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]'
Flexmarket_contract = web3.eth.contract(abi = Flexmarket_abi, address = Flexmarket_address)

t = list(range(96))
neg_off = []
pos_off = []
neg_off_sum = []
pos_off_sum = []
dem_sum = []
res_sum = []

for x in range(96):
    #get flexibility offers from the smart contract
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (flxtp, pwr, prc, engy) = Flexmarket_contract.functions.getOffersTime(x).call({'from': web3.eth.accounts[3]})
    
    for y in range(len(flxtp)):
        if(flxtp[y] == False):
            neg_off.append(pwr[y])
        else:
            pos_off.append(pwr[y])
            
    neg_off_sum.append(np.sum(neg_off))
    neg_off = []
    pos_off_sum.append(np.sum(pos_off))
    pos_off = []

    #get flexibility demands from the smart contract
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (flxtp, pwr, prc, engy) = Flexmarket_contract.functions.getDemandsTime(x).call({'from': web3.eth.accounts[3]})
    dem_sum.append(np.sum(pwr))
    #get matching results from the smart contract
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResult(x).call({'from': web3.eth.accounts[3]})
    res_sum.append(np.sum(pwr))

    #convert W to kW
    dem_sum_kw = []
    neg_off_sum_kw = []
    pos_off_sum_kw = []
    res_sum_kw = []
    for x in dem_sum:
        dem_sum_kw.append(x/1000)
    for x in neg_off_sum:    
        neg_off_sum_kw.append(-x/1000)
    for x in pos_off_sum:    
        pos_off_sum_kw.append(x/1000)
    for x in res_sum:
        res_sum_kw.append(x/1000)

plt.rcParams.update({'font.size': 22})

#plot offers, demands and matching results    
plt.figure()
plt.bar(t, dem_sum_kw, alpha=0.8, width=1, color=[(0.8,0.5,0.2)])
plt.bar(t, pos_off_sum_kw, alpha=0.8, width=1., color=[(0.7,0.1,0.0)])
plt.bar(t, neg_off_sum_kw, alpha=0.8, width=1., color=[(0.2,0.1,0.8)])
plt.bar(t, res_sum_kw, alpha=0.8, width=1, color=[(0.2,0.5,0.3)])
plt.xlim(-0.5, 95.5)
plt.xticks(np.arange(0, 96, step=5))
plt.yticks(np.arange(0, 4001, step =1000))
plt.xlabel("timestep")
plt.ylabel("power [kW]")
plt.legend(["Positive flexibility demand","Positive flexibility offer","Negative flexibility offer","Matched flexibility"])
plt.grid()
plt.show()

#total_off=np.sum(off_sum)
#total_dem=np.sum(dem_sum)
#total_res=np.sum(res_sum)

#share_off = total_res / total_off
#share_dem = total_res / total_dem