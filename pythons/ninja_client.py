from lightningRpc import lightningRpcApi as remote_wallet
from optparse import OptionParser
from requests import get
from json import loads as decode
from uuid import uuid4 as rand_data
from os import system
from time import sleep
from threading import Thread
try:
    from ConfigParser import ConfigParser
except:
    from configparser import ConfigParser

def constantly_pay(wallet, server_addr, myid):
    addr = server_addr + "/should_pay/" + myid
    print(addr)
    while True:
        try:
            res = get(addr)
            if res.status_code != 200:
                print("error: " + str(res.status_code) + res.text)
                break
            req = res.text
            if req and len(req) > 10:
                print(wallet.pay(req))
        except Exception as e:
            print("failed to pay! " + addr + str(e))
        sleep(10)

parser = OptionParser()
parser.add_option("-c", "--config", dest="config_file",
                  help="config file to use", metavar="FILE", default="client_config.ini")
(options, args) = parser.parse_args()

config = ConfigParser()
config.read(options.config_file)

wallet = remote_wallet(config["wallet"])

servers = decode(get(config['netninja']['server'] + "/get_servers/2").text)
ovpn_conf = None
while not ovpn_conf:
    for server in servers:
        base_addr = "http://" + server
        addr = ""
        try:
            myid = str(rand_data())
            addr = base_addr + "/generateNewClient/" + myid
            resp = get(addr)
            if resp.status_code != 200:
                continue
            if len(resp.text) > 1000:
                ovpn_conf = resp.text
            else:
                addr = base_addr + "/download/" + myid + ".ovpn"
                ovpn_conf = get(addr).text
            break
        except:
            print("failed to get " + addr)
open("config.ovpn", "wt").write(ovpn_conf)
Thread(target=constantly_pay,args=(wallet,base_addr,myid,)).start()
print("connecting")
system('\"' + config['netninja']['ovpn_bin'] + "\" --config config.ovpn")
exit(0)