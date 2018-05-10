from lightningRpc import lightningRpcApi as remote_wallet
from optparse import OptionParser
from flask import Flask, request
from json import loads as decode, dumps as encode
from os import popen
from threading import Thread
from time import sleep
from requests import get
try:
    from ConfigParser import ConfigParser
except:
    from configparser import ConfigParser

clients_payments_hitory = {}
clients_payments = {}

parser = OptionParser()
parser.add_option("-c", "--config", dest="config_file",
                  help="config file to use", metavar="FILE", default="server_config.ini")
(options, args) = parser.parse_args()

config = ConfigParser()
config.read(options.config_file)

wallet = remote_wallet(config["wallet"])

app = Flask(__name__)

def update_payments_status(log_file, ppb):
    while True:
        try:
            text = open(log_file, "rt").read()
            text = text[text.index("Since\n") + 6:text.index("\nROUTING")].split("\n")
            for line in text:
                parts = line.split(",")
                addr = parts[0]
                byte_count = int(parts[3]) + int(parts[3])
                if not addr in clients_payments:
                    clients_payments[addr] = 0
                if not addr in clients_payments_hitory:
                    clients_payments_hitory[addr] = 0
                clients_payments[addr] += byte_count * ppb
        except Exception as e:
            print(str(e))
        sleep(20)

def update_ninja_server(address):
    while True:
        try:
            get(address)
        except:
            print("failed to get " + address)
        sleep(10)

@app.route("/generateNewClient/<string:rand>")
def generateNewClient(rand):
    return popen("~/cgi-bin/generateNewClient.sh " + rand).read()


@app.route("/should_pay/<string:addr>")
def should_pay(addr):
    s = ""
    if addr in clients_payments:
        topay = int(clients_payments[addr])
        s = wallet.get_payment_request(topay)['content']
        clients_payments_hitory[addr] += topay
        clients_payments[addr] = 0
        print("sent payment request of " + str(topay) + " to client " + addr)
    return s


Thread(target=update_payments_status,args=(config["netninja"]["ovpn_status_files"],1,)).start()
Thread(target=update_ninja_server,args=(config["netninja"]["server"] + "/register/" + config["netninja"]["my_addr"],)).start()

app.run()