# -*- coding: utf-8 -*-

import web3
import json
import time
from datetime import datetime
import pandas as pd
import numpy as np
from xlwt import Workbook
from web3 import Web3, IPCProvider, HTTPProvider

web3 = Web3(HTTPProvider("http://localhost:8501"))
Flexmarket_address = web3.toChecksumAddress("0x3c375af1aac69f7af48b19ad06231f6633251b2e")

with open("ABI.json") as f:
    abi = json.load(f)

Flexmarket_contract = web3.eth.contract(abi = abi, address = Flexmarket_address)

print(web3.eth.accounts)

#Settings for Dataframe
pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)
pd.set_option('display.width', 1000)
pd.options.display.float_format = '{:.0f}'.format

#Arrays for Timedata
timedata_filteroffers = []
timedata_sortingoffers = []

timedata_filtersortingdemands = []
timedata_matching = []
timedata_timestep = []

markettime = 15 #value in minutes
noOfTimesteps = 1440/markettime #96
dt = datetime.now()
timestep = int((dt.hour * 3600 + dt.minute *60 + dt.second)/(markettime*60))

while True:
    time.sleep(1)
    dt = datetime.now()
    print('Working!')
    '''if((dt.hour * 3600 + dt.minute *60 + dt.second)%(markettime*60) == 0):
        if(timestep < noOfTimesteps-1):
            timestep = timestep +1
        else:
            timestep = 0'''

    #check if it is admin

    start_timersimcycle = time.time()

    print(f'Results of current timestep: {timestep} are being copied')
    web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
    web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.copyResult(timestep).transact({'from': web3.eth.accounts[3]}))
    print("Done copying Results!")

    t = timestep + 1 #start with the matching process one step after the current timestep
    for x in range(95): #adjust this value for the number of timesteps that should be cleared
        if(t>95):
            t = 0

        timedata_timestep.append(t)

        print(f"Matching function is called at timestep: {t}\n")

        #Demands Filtering and Sorting

        print('Demand before filtered and sorted:\n')
        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (flxtp2, pwr2, prc2, engy2) = Flexmarket_contract.functions.getDemandsTime(t).call(
            {'from': web3.eth.accounts[3]})
        print(f'Flextype :{flxtp2}\nPower:{pwr2}\nPrice: {prc2}\nEnergy:{engy2}\n')

        if all(v == 0 for v in engy2):
            print("No Demands, so no Matching Results\n")
            timedata_filtersortingdemands.append(0)
            print('Time filtering and sorting Demands: 0\n')
            timedata_filteroffers.append(0)
            timedata_sortingoffers.append(0)
            print('Time filtering Offers: 0\n')
            print('Time sorting Offers: 0\n')
            print('No MatchingResults\n')
            timedata_matching.append(0)
            print('Time Matching : 0\n')
            t = t + 1
            print('Done!\n')
            continue
        else:
            start_time_filtersortingdemands = time.time()

            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            # web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.sortDemands().transact({'from': web3.eth.accounts[3]}))
            # web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.quicksortDemands().transact({'from': web3.eth.accounts[3]}))
            # web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.sortSebDemands().transact({'from': web3.eth.accounts[3]}))
            Flexmarket_contract.functions.filtersortSebDemands(t).transact({'from': web3.eth.accounts[3]})

            time_filtersortingdemands = time.time() - start_time_filtersortingdemands

            timedata_filtersortingdemands.append(time_filtersortingdemands)

            print(f'Time filtering and sorting Demands: {time_filtersortingdemands}\n')

        #Offers Filtering and Sorting

        print('Offer before sorted:\n')
        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (flxtp1, pwr1, prc1, engy1) = Flexmarket_contract.functions.getOffersTime(t).call({'from': web3.eth.accounts[3]})
        print(f'Flextype :{flxtp1}\nPower:{pwr1}\nPrice: {prc1}\nEnergy:{engy1}')

        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (mli) = Flexmarket_contract.functions.getOffersMaLoIdTime(t).call({'from': web3.eth.accounts[3]})
        print(f'MaLoID :{mli}\n')

        if all(v == 0 for v in engy1):
            print("No Offers\n")
            timedata_filteroffers.append(0)
            timedata_sortingoffers.append(0)
            print('Time filtering Offers: 0\n')
            print('Time sorting Offers: 0\n')
            print('No MatchingResults\n')
            timedata_matching.append(0)
            print('Time Matching : 0\n')
            t = t + 1
            print('Done!\n')
            continue
        else:
            start_time_filteroffers = time.time()

            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            Flexmarket_contract.functions.filterOffers(t).transact({'from': web3.eth.accounts[3]})

            time_filteroffers = time.time() - start_time_filteroffers

            timedata_filteroffers.append(time_filteroffers)

            print(f'Time filtering Offers: {time_filteroffers}\n')

            start_time_sortingoffers = time.time()

            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            #web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.sortOffers().transact({'from': web3.eth.accounts[3]}))
            #web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.quicksortOffers().transact({'from': web3.eth.accounts[3]}))
            web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.sortSebOffers().transact({'from': web3.eth.accounts[3]}))

            time_sortingoffers = time.time() - start_time_sortingoffers

            timedata_sortingoffers.append(time_sortingoffers)

            print(f'Time sorting Offers: {time_sortingoffers}\n')

        #Matching Function Called


        start_time_matching = time.time()

        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.matching(t).transact({'from': web3.eth.accounts[3]}))

        time_matching = time.time() - start_time_matching

        timedata_matching.append(time_matching)

        print(f'Time Matching : {time_matching}\n')

        print('Matching Results:')
        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResult(t).call({'from': web3.eth.accounts[3]})
        print(f'Flextype :{flxtp} ,\nPrice: {prc},\nPower : {pwr},\nEnergy : {engy},\nTime : {tm}')

        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (mli) = Flexmarket_contract.functions.getMatchingMarketID(t).call({'from': web3.eth.accounts[3]})
        print(f'MaLoId: {mli} \n')

        t = t + 1
        print('Done!\n')

    for t in range(95):
        print(f'Matching Results at {t}:')
        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResult(t).call({'from': web3.eth.accounts[3]})
        print(f'Flextype :{flxtp} ,\nPrice: {prc},\nPower : {pwr},\nEnergy : {engy},\nTime : {tm}')

        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        (mli) = Flexmarket_contract.functions.getMatchingMarketID(t).call({'from': web3.eth.accounts[3]})
        print(f'MaLoId: {mli} \n')


    timersim = time.time() - start_timersimcycle

    print(f'Time for one cycle: {timersim}\n')

    df_simtimer = pd.DataFrame({'Filter Offers Time': np.array(timedata_filteroffers),
                                'Sorting Offers Time': np.array(timedata_sortingoffers),
                                'Filter & Sorting Demands Time': np.array(timedata_filtersortingdemands),
                                'Matching Time': np.array(timedata_matching),
                                'Timestep' : np.array(timedata_timestep)})

    print(df_simtimer)

    df_simtimer.to_excel(f'SimTimer_Opt_{dt.day}d{dt.month}m{dt.year}y_{dt.hour}h{dt.minute}min.xlsx',
                         float_format="%.2f")

    file = open('Simulation_Times.txt', 'a')

    timersim = timersim / 60

    file.write(f'The Simulation of timer_optimized.py was {timersim}min long Date:{dt.year}y{dt.month}m{dt.day}d_{dt.hour}h{dt.minute}min \n')

    file.close()

    break

