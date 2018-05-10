from requests import post, get
from requests.auth import HTTPBasicAuth
from json import loads as decode, dumps as encode
from uuid import uuid4 as rand_data

class lightningRpcApi:
    def __init__(self, config, *args, **kwargs):
        self.config = config

        self.chrage = kwargs.get("charge") or config.get("charge") or "http://charge." + config.get("name") + ".hackbtc18.offchain.rocks/"
        self.chrage_username = config.get("chrage_username") or config.get("username") or "api-token"
        self.chrage_password = config.get("chrage_password") or config.get("password")
        self.chrage_auth = HTTPBasicAuth(self.chrage_username, self.chrage_password)

        self.clightning = kwargs.get("clightning") or config.get("clightning") or "http://rpc." + config.get("name") + ".hackbtc18.offchain.rocks/"
        self.clightning_username = config.get("clightning_username") or config.get("username") or "api-token"
        self.clightning_password = config.get("clightning_password") or config.get("password")
        self.clightning_auth = HTTPBasicAuth(self.clightning_username, self.clightning_password)

        self.spark = kwargs.get("spark") or config.get("spark") or "http://spark." + config.get("name") + ".hackbtc18.offchain.rocks/rpc"
        self.spark_username = config.get("spark_username") or config.get("username") or "spark"
        self.spark_password = config.get("spark_password") or config.get("password")
        self.spark_auth = HTTPBasicAuth(self.spark_username, self.spark_password)
        

    def make_rpc_request(self, url, auth, method, data):
        json = {
            'jsonrpc': '2.0',
            'id': 1,
            'method': method,
            'params':data
        }
        return post(url, auth=auth, json = json)


    def get_payment_request(self, sum, desc = "just pay!"):
        id = str(rand_data())
        resp = self.make_rpc_request(self.clightning, self.clightning_auth, "invoice", [sum, id, desc])
        data = decode(resp.text)
        data.update({
            'id': id,
            'content': data["bolt11"]
        })
        return data


    def pay(self, req_content):
        resp = self.make_rpc_request(self.clightning, self.clightning_auth, "pay", [req_content])
        return resp.text


def main():
    import config
    s = lightningRpcApi(config.server_wallet)
    req = s.get_payment_request(1000, "how are you?")
    print(req)
    c = lightningRpcApi(config.client_wallet)
    print(c.pay(req["content"]))


if __name__ == '__main__':
    main()