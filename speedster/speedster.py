#!/usr/bin/env python3

""" Tests against speedtest.net using the speedtest-cli library.  
    Dumps a subset of the results into 1 single file that rotates 
    at each new GMT day.
    Plots and updates graphic(s) for the current day
"""

import os
import json
import datetime
import speedtest
import argparse
import collections
import plotly as py
import plotly.graph_objs as go
from pathlib import Path

class TimeStamp:
    """ Needed to handle date format for plotly """
    def __init__(self, local=False):
        if local:
            today = datetime.datetime.now()
        else:
            today = datetime.datetime.utcnow()
        self.dateStr = today.strftime("%Y-%m-%d")
        self.timeStr = today.strftime("%H:%M")

    def getDateStamp(self):
        return self.dateStr

    def getHourStamp(self):
        return self.timeStr

    def __str__(self):
        timeStampStr = self.dateStr + " " + self.timeStr
        return timeStampStr

    __repr__ = __str__

class TestSample:
    """ Individual test sample """
    def __init__(self, timeStamp):
        self.timeStamp = timeStamp
        self.sampleData = {}
    
    def __str__(self):
        attr = []
        for key in self.__dict__:
            attr.append("{key}='{value}'".format(key=key, value=self.__dict__[key]))
        return ('\n'.join(map(str, attr))) 
    
    __repr__ = __str__

    def getTimeStamp(self):
        return self.timeStamp

    def getSampleData(self):
        return self.sampleData

    def addSpeed(self, speed):
        if speed[0]:
            self.sampleData['download_speed'] = niceFloat(speed[0]/1024/1024,2)
        if speed[1]:
            self.sampleData['upload_speed'] = niceFloat(speed[1]/1024/1024,2)
    
    def addPing(self, ping):
        self.sampleData['ping'] = niceFloat(ping,2)
    
    def addServerDetails(self, server):
        self.sampleData['serverid'] = server['id']
        self.sampleData['servername'] = server['name']
        self.sampleData['serverurl'] = server['url']

    def writeToJSON(self, jsonFileName):
        pass


class dayData:
    """ All the tests from the date that corresponds to the single sample being added.
        The set will be loaded from disk if the file exists, it will add the single
        test sample provided in the generator and then update the file.
    """
    def __init__(self, sampleData, jsonDataPath):
        self.daySamples = {}
        self.date = str(sampleData.getTimeStamp().getDateStamp())
        if jsonDataPath:
            jsonFileName = jsonDataPath + "/" + self.date + ".json"
        else:
            jsonFileName = self.date + ".json"
        jsonFilePath = Path(jsonFileName)

        if jsonFilePath.is_file():
            with open(jsonFileName, "r") as json_output:
                self.daySamples = json.load(json_output)
        
        self.daySamples[str(sampleData.getTimeStamp())] = sampleData.getSampleData()

        with open(jsonFileName, "w") as json_output:
            json.dump(self.daySamples, json_output)

    def plot(self, outputPath=None):
        """ Generates 2 plots, 1 for Download/Upload and 1 for Ping """
        # TO DO: Option to generate only 1 plot + remove hardcoded titles and size
        sortedDict = collections.OrderedDict(sorted(self.daySamples.items()))
        xAxis = []
        yAxisUpload = []
        yAxisDownload = []
        yAxisPing = []
        for k, v in sortedDict.items():
            xAxis.append(k)
            yAxisUpload.append(v.get('upload_speed', 0))
            yAxisDownload.append(v.get('download_speed', 0))
            yAxisPing.append(v.get('ping', 0))

        traceDownload = go.Scatter(
            x = xAxis,
            y = yAxisDownload,
            mode = 'lines+markers',
            name = 'Download'
        )
        traceUpload = go.Scatter(
            x = xAxis,
            y = yAxisUpload,
            mode = 'lines+markers',
            name = 'Upload'
        )
        layoutDownloadUpload = go.Layout(
            xaxis=dict(
                title="GMT Date"
            ),
            yaxis=dict(
                title="MB/Second"
            ),
            autosize=True,
            margin=go.Margin(
                b=100
            ),
            title='Download/Upload Speed Tests',
            height=550,
            width=1137
        )

        outputSpeed = outputPath + self.date + "_speed.html"
        plotSpeedData = [traceUpload, traceDownload]
        plot_speed = go.Figure(data=plotSpeedData, layout=layoutDownloadUpload)
        py.offline.plot(plot_speed, filename=outputSpeed, auto_open=False)
        
        trace_ping = go.Scatter(
            x = xAxis,
            y = yAxisPing
        )
        layoutPing = go.Layout(
            xaxis=dict(
                title="GMT Date"
            ),
            yaxis=dict(
                title="Milliseconds"
            ),
            autosize=True,
            margin=go.Margin(
                b=100
            ),
            title='Ping Tests',
            height=550,
            width=1137
        )
        outputPing = outputPath + self.date + "_ping.html"
        plotPingData = [trace_ping]
        plotPing = go.Figure(data=plotPingData, layout=layoutPing)
        py.offline.plot(plotPing, filename=outputPing, auto_open=False)

class RunTest:
    """ By encapsulating SpeedTest into a class, it makes more obvious to run only ping tests """
    def __init__(self, server=None):
        self.speedTest = speedtest.Speedtest()   
        if server:
            self.server = server
        else:
            self.server = ""

    def runPing(self):
        if self.server:
            if not looksLikeInt(self.server):
                    self.speedTest.get_best_server(self.speedTest.set_mini_server(self.server))
            else:
                self.speedTest.get_servers([self.server])
                self.speedTest.get_best_server()
        else:
            self.speedTest.get_best_server()

    def runDownload(self):
        self.speedTest.download()

    def runUpload(self):
        self.speedTest.upload()

    def getResults(self):
        return self.speedTest.results.dict()

#Helper functions
def looksLikeInt(value):
    try: 
        int(value)
        return True
    except ValueError:
        return False

def parseMe():
    parser = argparse.ArgumentParser('Speedster')
    parser.add_argument("-s", "--server", dest="server", help="Miniserver or Speedtest ID")
    parser.add_argument("-p", "--path", dest="jsonPath", help="Path to json files")
    parser.add_argument("-t", "--plot", action='store_true', default=False, dest="plot", help="Plot graphic for the day")
    parser.add_argument("-l", "--pingOnly", action='store_true', default=False, dest="pingOnly", help="Does not test download/upload")
    parser.add_argument("-o", "--plotPath", dest="plotPath", help="Path for plot output files")
    # TO DO: Validate file paths 
    return parser.parse_args()

def niceFloat(value, decimals):
    return float(("{0:.%if}" %decimals).format(float(value)))

def main():    
    options = parseMe()
    test = RunTest(options.server)
    
    test.runPing()
    if not options.pingOnly:
        test.runDownload()
        test.runUpload()
    resultsTest = test.getResults()

    date = TimeStamp()
    sampleData = TestSample(date)
    sampleData.addPing(resultsTest['ping'])
    sampleData.addSpeed((resultsTest['download'],resultsTest['upload']))
    sampleData.addServerDetails(resultsTest['server'])

    todayData = dayData(sampleData, options.jsonPath)

    if options.plot:
        if options.plotPath:
            todayData.plot(options.plotPath)
        else:
            todayData.plot("")
    
if __name__ == '__main__':
    main()
