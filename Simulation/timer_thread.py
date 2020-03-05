from multiprocessing import Process
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

t=35

def FilteringSortingOffers(t):
  print('FilteringSortingOffers: starting')

  web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
  Flexmarket_contract.functions.filterOffers(t).transact({'from': web3.eth.accounts[3]})
  web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
  Flexmarket_contract.functions.sortSebOffers().transact({'from': web3.eth.accounts[3]})

  print('FilteringSortingOffers: finishing')

def FilteringSortingDemands(t):
  print('FilteringSortingDemands: starting')

  web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
  Flexmarket_contract.functions.filtersortSebDemands(t).transact({'from': web3.eth.accounts[3]})

  print('FilteringSortingDemands: finishing')

def runInParallel(*fns):
  proc = []
  for fn in fns:
    p = Process(target=fn)
    p.start()
    proc.append(p)
  for p in proc:
    p.join()

if __name__ == '__main__':

    # Info for the Timer
    markettime = 15  # value in minutes
    noOfTimesteps = 1440 / markettime  # 96
    dt = datetime.now()
    timestep = int((dt.hour * 3600 + dt.minute * 60 + dt.second) / (markettime * 60))

    while True:
        time.sleep(1)
        dt = datetime.now()
        print('Working!')
        if ((dt.hour * 3600 + dt.minute * 60 + dt.second) % (markettime * 60) == 0):
            if (timestep < noOfTimesteps - 1):
                timestep = timestep + 1
            else:
                timestep = 0

        start_timersim = time.time()  # Timer fot the Simulation

        print(f'Results of current timestep: {timestep} are being copied')
        web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
        Flexmarket_contract.functions.copyResult(timestep).transact({'from': web3.eth.accounts[3]})
        print("Done copying Results!")

        t = timestep + 1  # start with the matching process one step after the current timestep

        for x in range(95):  # adjust this value for the number of timesteps that should be cleared
            if (t > 95):
                t = 0

            print("Matching function is called at timestep:", t)

            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            (flxtp, pwr, prc, engy) = Flexmarket_contract.functions.getDemandsTime(t).call(
                {'from': web3.eth.accounts[3]})
            if all(v == 0 for v in engy):
                print('No Matching Results \n')
                t = t + 1
                continue
            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            (flxtp, pwr, prc, engy) = Flexmarket_contract.functions.getOffersTime(t).call(
                {'from': web3.eth.accounts[3]})
            if all([v == 0 for v in engy]):
                print('No Matching Results \n')
                t = t + 1
                continue

            runInParallel(FilteringSortingDemands(t),FilteringSortingOffers(t))



            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            web3.eth.waitForTransactionReceipt(Flexmarket_contract.functions.matching(t).transact({'from': web3.eth.accounts[3]}))

            print('Matching Results:')
            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResult(t).call({'from': web3.eth.accounts[3]})
            print(f'Flextype :{flxtp} ,\nPrice: {prc},\nPower : {pwr},\nEnergy : {engy},\nTime : {tm}')

            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            (mli) = Flexmarket_contract.functions.getMatchingMarketID(t).call({'from': web3.eth.accounts[3]})
            print(f'MaLoId: {mli} \n')

            t = t + 1

        for t in range(95):
            print(f'Matching Results at {t}:')
            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            (flxtp, prc, pwr, engy, tm) = Flexmarket_contract.functions.getMatchingResult(t).call({'from': web3.eth.accounts[3]})
            print(f'Flextype :{flxtp} ,\nPrice: {prc},\nPower : {pwr},\nEnergy : {engy},\nTime : {tm}')

            web3.parity.personal.unlockAccount(web3.eth.accounts[3], "Ukulele112", None)
            (mli) = Flexmarket_contract.functions.getMatchingMarketID(t).call({'from': web3.eth.accounts[3]})
            print(f'MaLoId: {mli} \n')

        timersim = time.time() - start_timersim

        file = open('Simulation_Times.txt', 'a')

        timersim = timersim / 60

        file.write(
          f'The Simulation of timer_thread.py was {timersim}min long _ {dt.year}y{dt.month}m{dt.day}d_{dt.hour}h{dt.minute}min \n')

        file.close()

        break