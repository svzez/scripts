# speedster.py
A python script to test the network speed using speedtest-cli.  
Optional: plots the results using plotly
Accepts multiple arguments from command line.

## Pre requisites
* Python 3.4+
* speedtest-cli
* plotly

## Usage
```sh
usage: Speedster [-h] [-s SERVER] [-p JSONPATH] [-t] [-l] [-o PLOTPATH]

optional arguments:
  -h, --help            show this help message and exit
  -s SERVER, --server SERVER
                        Miniserver or Speedtest ID
  -p JSONPATH, --path JSONPATH
                        Path to json files
  -t, --plot            Plot graphic for the day
  -l, --pingOnly        Does not test download/upload
  -o PLOTPATH, --plotPath PLOTPATH
                        Path for plot output files

```

## Examples

Full tests with plot, saving and reading info from/to specified paths
```sh
./speedster.py -p outputjson/ -t -o outputhtml/
```

Only ping tests (no Download/Upload):
```sh
./speedster.py -p outputjson/ -t -l -o outputhtml/
```

Specifies a server ID (from: http://www.speedtest.net/speedtest-servers.php):
```sh
./speedster.py -t -s 911
```

Specifies a URL (a miniserver for example: http://myminiserver.com)
```sh
./speedster.py -t -s "http://myminiserver.com"
```
