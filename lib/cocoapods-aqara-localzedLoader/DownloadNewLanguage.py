import shutil
import os, sys, stat
import time
import requests
# import zipfile

# from __future__ import print_function

from volcengine.iam.IamService import IamService

from volcengine.ApiInfo import ApiInfo
from volcengine.Credentials import Credentials
from volcengine.base.Service import Service
from volcengine.ServiceInfo import ServiceInfo

from volcengine.auth.SignerV4 import SignerV4


# 浏览器登录后抓取的 cookie
myheader = '''
accept: application/json, text/plain, */*
accept-encoding: gzip, deflate, br
accept-language: zh
content-length: 155
content-type: application/json
cookie:experimentation_subject_id=IjZmOTJkNTAwLWRhNGQtNDllOS04NWJmLTViMDA3YWQyNzNmNSI%3D--ea0d856d9ab513dbab485429b3eb34d28baf575c; _ga_WF6G97Z3ZH=GS1.1.1655109583.7.0.1655109635.0; Hm_lvt_2df419cadb3951597d5f6df3a9e563d1=1677809958; __gads=ID=7b3f01c117b67f05-227ecfaf8fe20014:T=1688561915:RT=1695382086:S=ALNI_MZWfx6X7kl8bcHGz9c7kVOi5EJ97g; __gpi=UID=00000c96aea158eb:T=1688561915:RT=1695382086:S=ALNI_MaQoB1d1fZVX_-TNOZ9-FBy0AmJeQ; _ga_3EMB6JL0XV=GS1.1.1695897491.159.0.1695897491.60.0.0; _ga=GA1.1.726824286.1621481586; _ga_1MSMD2CRQ5=GS1.1.1695897492.25.0.1695897492.0.0.0; sensorsdata2015jssdkcross=%7B%22distinct_id%22%3A%222698037175171e6d.824697002942386177%22%2C%22first_id%22%3A%2217954f52ff723e-046b05611aed99-113a6054-1296000-17954f52ff9e4c%22%2C%22props%22%3A%7B%22%24latest_traffic_source_type%22%3A%22%E5%BC%95%E8%8D%90%E6%B5%81%E9%87%8F%22%2C%22%24latest_search_keyword%22%3A%22%E6%9C%AA%E5%8F%96%E5%88%B0%E5%80%BC%22%2C%22%24latest_referrer%22%3A%22https%3A%2F%2Fuc.aqara.cn%2F%22%7D%2C%22%24device_id%22%3A%2217954f52ff723e-046b05611aed99-113a6054-1296000-17954f52ff9e4c%22%7D; Token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI4MzcyOTA5NzQ3NmUwMmYyLjY0MjA2ODExMTgyMzk1MzkyMSIsImlzcyI6Imh0dHBzOi8vYWlvdC1ycGMuYXFhcmEuY24iLCJhY2NvdW50Ijoid2FuaHVhLnlhbkBhcWFyYS5jb20iLCJpYXRHbXQ4IjoxNjk2NjQ2MDYyLCJqdGkiOiI4ZjJlNDJiNTk1MTE0ODFmOTBiMDI3NWExZmE2OWNkZDlkMjVhZDY5NGUzMDQ4MGZhNDM3ZDM2NGI5YTFjZTIzIn0.FqpQfHNi--7FxAu4ytiGpQBwUdMVGDgdKaqZI4hLAus; Userid=83729097476e02f2.642068111823953921; currentSid=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI4MzcyOTA5NzQ3NmUwMmYyLjY0MjA2ODExMTgyMzk1MzkyMSIsImlzcyI6Imh0dHBzOi8vYWlvdC1ycGMuYXFhcmEuY24iLCJpYXRHbXQ4IjoxNjk2NjQ2MDYyLCJqdGkiOiJhNDZlZjExOGE3YTk0ZTIwYTBkNmE5YTE5YjRiM2UxYjM0ZmMxNjYzZTUzYjQ1NzI4Zjk5YzhiYzRhZGUzMGE4In0.W_fWYx-B0kvj2uAUz0pw8vOhw5VKJ4SM5oCwpY_YZkk; currentAccount=wanhua.yan@aqara.com; userInfo=%7B%22accountCategory%22%3A%220%22%2C%22company%22%3A%7B%22companyId%22%3A1%2C%22companyName%22%3A%22%E7%BB%BF%E7%B1%B3%E8%81%94%E5%88%9B%22%7D%2C%22user%22%3A%7B%22avatarUrl%22%3A%22%22%2C%22companyId%22%3A1%2C%22email%22%3A%22wanhua.yan%40aqara.com%22%2C%22nickName%22%3A%22%22%2C%22userType%22%3A0%7D%7D; sidebarStatus=0
lang: zh
nonce: z7isblgw7hzfrlebmu7fzoukr20vpvs8
operate-platform: 40
origin: https://intl-lang.aqara.com
projectid: 5
referer: https://intl-lang.aqara.com/
sec-ch-ua: "Not/A)Brand";v="99", "Google Chrome";v="115", "Chromium";v="115"
sec-ch-ua-mobile: ?1
sec-ch-ua-platform: "Android"
sec-fetch-dest: empty
sec-fetch-mode: cors
sec-fetch-site: same-origin
time: 1690280776221
timestamp: 1690280776221
user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Mobile Safari/537.36
'''

def get_ak_sk():
    """从环境变量读取 AK/SK，未配置时回退到本地默认值。"""
    ak_env = os.getenv("VOLC_ACCESSKEY") or os.getenv("VOLCENGINE_ACCESS_KEY")
    sk_env = os.getenv("VOLC_SECRETKEY") or os.getenv("VOLCENGINE_SECRET_KEY")

    # 兼容现有脚本中写死的 AK/SK（建议在外部通过环境变量配置）
    default_ak = 'AKLTMjQ5NzU0YWY0ODU1NGVjOGIwMmVlYzk3ZGVhMjgzZmM'
    default_sk = 'TkRZeE9UazRNVEl4TW1JNU5HSTRZV0U0TUdRNU1HTmxNMk5pWVRJMU1EYw=='

    ak = ak_env or default_ak
    sk = sk_env or default_sk

    if not ak or not sk:
        raise RuntimeError("未找到火山引擎 AK/SK，请配置 VOLC_ACCESSKEY / VOLC_SECRETKEY 环境变量")

    return ak, sk

def MakeHeader(headerText):
    s = headerText.strip().split('\n')
    s = {x.split(':', 1)[0].strip() :x.split(':', 1)[1].strip() for x in s}
    return s

def DownLatestLocalizableSource(downloadPath):
    print("开始发送下载请求...")

    # 确保下载目录存在
    if not os.path.isdir(downloadPath):
        os.makedirs(downloadPath, exist_ok=True)

    # 加载 AK/SK
    ak123, sk = get_ak_sk()

    iam_service = IamService()
    iam_service.set_ak(ak123)
    iam_service.set_sk(sk)

    # 使用 OpenAPI 网关域名，结合 serviceName = i18n_openapi
    # 参考 Node SDK 的 OpenAPI 用法，统一走 open.volcengineapi.com
    connection_timeout = 10      # 建连超时
    socket_timeout = 300         # 读取超时（导出大项目时可能比较慢）

    service_info = ServiceInfo(
        "open.volcengineapi.com",
        {'Accept': 'application/json'},
        Credentials(ak123, sk, 'i18n_openapi', 'cn-north-1'),
        connection_timeout,
        socket_timeout
    )
    iam_service.service_info = service_info

    # OpenAPI 的 Action / Version / serviceName 与文档保持一致
    api_info = ApiInfo(
        "GET",
        "/",
        {"serviceName": "i18n_openapi", "Action": "ProjectNamespaceTextDownload", "Version": "2021-05-21"},
        {},
        {}
    )

    params = {
        'async': 0,           # 同步导出；如仍然超时，可改为 1 走异步任务
        'projectId': 5788,
        'namespaceId': 42835,
        'format': 'xlsx',
    }

    # 生成并签名请求
    r = iam_service.prepare_request(api_info, params, 0)
    SignerV4.sign(r, service_info.credentials)
    url = r.build(0)

    # 使用流式下载 + 调大的超时，避免大文件导出导致总是超时
    resp = iam_service.session.get(
        url,
        headers=r.headers,
        timeout=(service_info.connection_timeout, service_info.socket_timeout),
        stream=True,
    )

    if resp.status_code != 200:
        # 打印部分响应文本，方便排查权限 / 参数问题
        print('下载失败，HTTP 状态码:', resp.status_code)
        try:
            print('响应内容预览:', resp.text[:1000])
        except Exception:
            pass
        raise Exception(f"下载失败，状态码 {resp.status_code}")

    out_file = os.path.join(downloadPath, "download.xlsx")
    with open(out_file, "wb") as code:
        for chunk in resp.iter_content(chunk_size=1024 * 128):
            if chunk:
                code.write(chunk)

    print('下载 excel 成功:', out_file)



# def Unzip():
#     f = zipfile.ZipFile("./localizable.zip", 'r')  # 压缩文件位置
#     for file in f.namelist():
#         f.extract(file, "../")  # 解压位置
#     f.close()
#     os.remove('./localizable.zip')

def UpdateSource_language():
    DownLatestLocalizableSource()
    return './download.xlsx'

    # Unzip()
    # os.rename('./download.xlsx', '../hit_all_str.xlsx')
#     shutil.copy('./download.xlsx', '../source_language/hit_all_str.xlsx')
#     os.remove('./download.xlsx')

if __name__ == '__main__':
    localizable_path = sys.argv[1]
    DownLatestLocalizableSource(localizable_path)
