import asyncio
import websockets, requests

clients = dict()


async def hello(websocket, path):
    podName = ""
    randID = ""
    sid = ""
    namespace = ""
    try:
        print("one comming")
        print("path:" + path)
        print("id:" + str(websocket.id))
        namespace = path.split('_')[0].strip('/')
        podName = path.split('_')[1]
        print("????????????????????????")
        print(podName)
        print("????????????????????????")
        randID = path.split('_')[-2]
        sid = path.strip('/')
        clients[sid] = websocket
        users = {clients[k] for k in clients if namespace in k and podName in k and randID in k}
        print("*************************************************")
        print(users)
        print("*************************************************")
        async for msg in websocket:
            websockets.broadcast(users, msg)
            print("#####################################")
            print(clients)
            print("#####################################")

    finally:
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
        print(clients)
        print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

        params = {"namespace": namespace, "podName": podName, "randID": randID}
        requests.get("http://192.168.2.89:8088/exitpodlog", params=params)
        print("&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&")
        clients.pop(sid)

        print(clients)
        print("one left")


async def main():
    async with websockets.serve(hello, "0.0.0.0", 5678):
        await asyncio.Future()  # run forever


asyncio.run(main())
