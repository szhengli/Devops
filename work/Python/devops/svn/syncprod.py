import requests


def invokeSync(branch, sysops):
    syncHostProd = "http://172.19.125.135:8088/"
    payload = {"branch": branch, "sysops": sysops}
    url = syncHostProd + "syncBranch"
    return requests.get(url, params=payload)

