"""Backup local solr indexes."""


import requests
import os
import sys
import shutil
import time


def parseFromCmd(argv):
"""Helper fn to parse args from command line"""
    vardict = {}
    for param in argv:
        vardict[param.split('=')[0]] = param.split('=', 1)[1]
    return vardict


def getRequestStatus(nodeIp, backupName):
    queryParams = {
        'wt': 'json',
        'action': 'REQUESTSTATUS',
        'requestid': backupName
    }
    url = "http://{0}".format(nodeIp)
    url += ":31000/solr/admin/collections"
    r = requests.get(url, params=queryParams)
    return r.json().get("status", {}).get("state")


def startBackup(nodeIp, backupName, locationPath):
    queryParams = {
        'wt': 'json',
        'action': 'BACKUP',
        'name': backupName,
        'collection': 'ma',
        'location': locationPath,
        'async': backupName
    }
    url = "http://{0}".format(nodeIp)
    url += ":31000/solr/admin/collections"
    r = requests.get(url, params=queryParams)
    return r.json().get("responseHeader", {}).get("status")

def deleteStatusFromStore(nodeIp, backupName):
    queryParams = {
        'wt': 'json',
        'action': 'DELETESTATUS',
        'requestid': backupName
    }
    url = "http://{0}".format(nodeIp)
    url += ":31000/solr/admin/collections"
    r = requests.get(url, params=queryParams)
    return r.json().get("responseHeader", {}).get("status")

def main():
    # ARGS
    backupDest = myArgs.get('backupDest', '/var/bkps')
    backupName = myArgs.get('backupName', 'indexBkps')
    timeOutValue = myArgs.get('timeOut', 7200)

    if os.path.isdir("{0}/{1}".format(backupDest, backupName)):
        print("backup folder exists")
        return 1

    print("Clearing status requestId")
    deleteStatusFromStore("localhost", backupName)
    time.sleep(1)

    print("Start backup")
    startBackup("localhost", backupName, backupDest)
    time.sleep(1)

    timeTotal = 0
    timeIncrement = 5
    timeLimit = timeOutValue
    asyncStatus = ""
    while (asyncStatus != "completed") and (timeTotal <= timeLimit):
        timeTotal += timeIncrement
        time.sleep(timeIncrement)
        asyncStatus = getRequestStatus("localhost", backupName)
    if timeTotal > timeLimit:
        print("Timed Out {0} seconds".format(timeLimit))
    else:
        print("Backup finished succesfully at {0}/{1}".format(
            backupDest, backupName))

if __name__ == "__main__":
    myArgs = parseFromCmd(sys.argv[1:])
    sys.exit(main())
