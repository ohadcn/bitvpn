from flask import Flask
from random import sample
from json import loads as decode, dumps as encode
from datetime import datetime

clients = []
clients_dates = {}

app = Flask(__name__)

@app.route('/list')
def root():
    return encode(clients)

@app.route('/register/<string:address>')
def register(address):
    if not address in clients:
        clients.append(address)
    clients_dates[address] = datetime.now()
    return 'success'

@app.route('/get_servers/<int:n>')
def get_servers(n):
    if n > len(clients):
        return encode(clients)
    return encode(sample(clients, k=n))

app.run()