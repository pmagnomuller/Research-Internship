import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
from web3 import Web3, IPCProvider, HTTPProvider

wweb3 = Web3(HTTPProvider("http://localhost:8501"))
Flexmarket_address = web3.toChecksumAddress("0x66e71756522d77743e0c8c6f2c01482ccc5ab4d3")

with open("ABI.json") as f:
    abi = json.load(f)

Flexmarket_contract = web3.eth.contract(abi = abi, address = Flexmarket_address)


t = list(range(96))
neg_off = []
pos_off = []
neg_off_sum = []
pos_off_sum = []
dem_sum = []
res_sum = []

for x in range(96):
    # get flexibility offers from the smart contract
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (flxtp, pwr, prc, engy) = Flexmarket_contract.functions.getOffersTime(x).call({'from': web3.eth.accounts[3]})

    for y in range(len(flxtp)):
        if (flxtp[y] == False):
            neg_off.append(pwr[y])
        else:
            pos_off.append(pwr[y])

    neg_off_sum.append(np.sum(neg_off))
    neg_off = []
    pos_off_sum.append(np.sum(pos_off))
    pos_off = []

    # get flexibility demands from the smart contract
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (flxtp, pwr, prc, engy) = Flexmarket_contract.functions.getDemandsTime(x).call({'from': web3.eth.accounts[3]})
    dem_sum.append(np.sum(pwr))
    # get matching results from the smart contract
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResult(x).call(
        {'from': web3.eth.accounts[3]})
    res_sum.append(np.sum(pwr))

    # convert W to kW
    dem_sum_kw = []
    neg_off_sum_kw = []
    pos_off_sum_kw = []
    res_sum_kw = []
    for x in dem_sum:
        dem_sum_kw.append(x / 1000)
    for x in neg_off_sum:
        neg_off_sum_kw.append(-x / 1000)
    for x in pos_off_sum:
        pos_off_sum_kw.append(x / 1000)
    for x in res_sum:
        res_sum_kw.append(x / 1000)

plt.rcParams.update({'font.size': 22})

# plot offers, demands and matching results
plt.figure()
plt.bar(t, dem_sum_kw, alpha=0.8, width=1, color=[(0.8, 0.5, 0.2)])
plt.bar(t, pos_off_sum_kw, alpha=0.8, width=1., color=[(0.7, 0.1, 0.0)])
plt.bar(t, neg_off_sum_kw, alpha=0.8, width=1., color=[(0.2, 0.1, 0.8)])
plt.bar(t, res_sum_kw, alpha=0.8, width=1, color=[(0.2, 0.5, 0.3)])
plt.xlim(-0.5, 95.5)
plt.xticks(np.arange(0, 96, step=5))
plt.yticks(np.arange(0, 4001, step=1000))
plt.xlabel("timestep")
plt.ylabel("power [kW]")
plt.legend(
    ["Positive flexibility demand", "Positive flexibility offer", "Negative flexibility offer", "Matched flexibility"])
plt.grid()
plt.show()

# total_off=np.sum(off_sum)
# total_dem=np.sum(dem_sum)
# total_res=np.sum(res_sum)

# share_off = total_res / total_off
# share_dem = total_res / total_dem