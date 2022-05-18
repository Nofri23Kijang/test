import json
import websockets
from binaryapi.stable_api import Binary

def test(min_payout):
    import os
    desktop = os.path.normpath(os.path.expanduser("~/Desktop"))

    token1 = "BLUOJPaibtKudHG"
    token2 = "5ROjwbUE4A4t2mz"

    demo_real = input("(demo/real) acc : 1 / 2  ")
    UsedToken = ""
    if demo_real == "1":
        UsedToken = token2
    if demo_real == "2":
        UsedToken = token1
    binary_token = UsedToken
    binary = Binary(token=binary_token)
    data_id3 = []

    # folder1 = str(input("address file: "))
    # folder1 = "C:\\Users\\user\\Desktop\\handle.txt"
    folder1 = desktop + "\dump.txt"
    nominal = input("Percent of copy: ")

    import os.path
    try:
        if os.path.isfile(folder1):
            print("file is exist")
        else:
            print("file not exist")
    except IOError:
        print("file not accessible")
        pass

    file = open(folder1, "r+")
    file.truncate(0)
    file.close()
    balance = binary.api.profile.balance
    currency = binary.api.profile.currency
    print('Balance: {:.2f} {}'.format(balance, currency))

    while True:
        connection = binary.api.websocket_alive()
        #print(connection)


        if connection == False:
            binary = Binary(token=binary_token)
            a = binary.api.connect()
            if binary == False:
                print("error  : ", binary)
            print("reconnecting.......")
        if connection == True:

            with open(folder1, 'r') as f:
                data_id = f.readlines()
                for line in data_id:
                    line.strip('\n')

                    fm_data = line.split(" ,")
                    RT = float(fm_data[4].strip())
                    ATM = float(fm_data[3].strip())
                    CA = fm_data[1].strip()
                    ID = fm_data[0].strip()
                    TYPE = fm_data[2].strip()
                    # print(type(ATM), type(CA), type(TYPE), type(RT))
                    # print(ID, ATM, CA, TYPE, RT)

                    if not ID in data_id3:
                        # print("Sending order")

                        if currency == "IDR":
                            uang = int(ATM * 15000)
                        if currency == "USD":
                            uang = ATM

                        if TYPE == "call":
                            tipe = 'CALL'
                        if TYPE == "put":
                            tipe = 'PUT'
                        r = round(RT)

                        duit = (float(ATM) * float(nominal)) / 100
                        if duit <= 1:
                            duit = 1

                        print(ID, duit, CA, TYPE, RT)
                        

                        try:
                            beli, id, no = (binary.buy(tipe, amount=duit, symbol=("frx" + CA), duration=r,min_payout=min_payout, duration_unit='m'))
                            if beli == True:
                                payout = binary.api.payout_currencies("frx"+CA)
                                print("Success: pair:", CA, " Type: ", tipe, " jumlah: ", duit, " waktu:", RT, " m", " Payout: ", payout, "0 %")
                                data_id3.append(ID)
                                balance = binary.api.profile.balance
                                currency = binary.api.profile.currency
                                print('Balance: {:.2f} {}'.format(balance, currency))

                            else:
                                print("not success")
                                print(id, no)

                        except Exception as e:
                            print(e)
                            continue
                f.close()


async def connect(app_id: int):
    return await websockets.connect(f'wss://ws.binaryws.com/websockets/v3?app_id={app_id}')

async def _do(websocket, request: dict) -> dict:
    await websocket.send(json.dumps(request))
    return json.loads(await websocket.recv())

async def authorize(websocket, api_token: str) -> dict:
    request = {
        'authorize': api_token
    }
    return await _do(websocket, request)


async def tick_history(websocket, symbol: str, from_: int, to: int) -> dict:
    request = {
        'ticks_history': symbol,
        'start': from_,
        'end': to
    }
    return await _do(websocket, request)
async def price(websocket, token: str) -> dict:
    request = {
        'copy_start': 'RRuwcyBznqbsmnQ'

    }
    return await _do(websocket, request)

async def buy_contract(websocket, parameters: dict) -> dict:
    request = {
        'buy': 'buy',
        'price': 9999,
        'parameters': parameters
    }
    return await _do(websocket, request)
async def time_server(websocket):
    request = {
        'time': 1
    }
    return await _do(websocket, request)
async def buy(websocket):
    request = {
        'buy': 1,
        'price': 100,
        'parameters': {
            'proposal': {
                1
            },
            'amount': '1',
            'barrier': '0.1',
            'basis': 'payout',
            'contract_type': 'PUT',
            'currency': 'USD',
            'duration': 60,
            'duration_unit': 's',
            'symbol': 'frxEURUSD'
            }
        }
    return await _do(websocket, request)

async def balance(websocket):
    request = {
        'balance': 1
    }
    return await _do(websocket, request)
async def email(websocket):
    request = {
        'proposal': True
    }
    return await _do(websocket, request)
