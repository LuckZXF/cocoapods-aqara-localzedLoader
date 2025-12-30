import shutil
import os, sys, stat
import time
import requests
from typing import Optional


#########  火山多语言  #############

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


def UpdateSource_language():
    DownLatestLocalizableSource()
    return './download.xlsx'


#######################################

#####  Crowdin  #########

class CrowdinPlatform():
    """Crowdin 翻译平台"""

    def __init__(self, access_token: str, project_id: str, base_url: str = "https://aqara.crowdin.com/api/v2"):
        """初始化 Crowdin 平台

        Args:
            access_token: 访问令牌
            project_id: 项目 ID
            base_url: API 基础 URL
        """
        self.access_token = access_token
        self.project_id = project_id
        self.base_url = base_url

    def _get_headers(self) -> dict:
        """获取 API 请求头"""
        return {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json"
        }

    def _get_project_files(self) -> dict:
        """获取项目文件列表

        Returns:
            dict: API 返回的文件列表数据
        """
        url = f"{self.base_url}/projects/{self.project_id}/files"
        headers = self._get_headers()
        params = {"limit": 500}
        print(f"Request: GET {url} with params {params}")
        response = requests.get(url, headers=headers, params=params)
        #print(f"Response: {response.status_code}")
#         print(f"Response Body: {response.text}")
        if response.status_code != 200:
            raise Exception(f"获取项目文件列表失败: {response.status_code}, {response.text}")
        return response.json()

    def _find_file_id_by_name(self, files_data: dict, file_name: str) -> Optional[int]:
        """从文件列表中查找指定文件名的 fileId

        Args:
            files_data: get_project_files 返回的数据
            file_name: 要查找的文件名

        Returns:
            int: 文件的 ID，如果未找到则返回 None
        """
        if "data" not in files_data:
            raise Exception("文件列表数据格式错误: 缺少 'data' 字段")
        for file_item in files_data["data"]:
            if "data" in file_item and file_item["data"]["name"] == file_name:
                return file_item["data"]["id"]
        return None

    def _get_file_download_url(self, file_id: int) -> str:
        """获取文件下载 URL

        Args:
            file_id: 文件 ID

        Returns:
            str: 下载 URL
        """
        url = f"{self.base_url}/projects/{self.project_id}/files/{file_id}/download"
        headers = self._get_headers()
        print(f"Request: GET {url}")
        response = requests.get(url, headers=headers)
        #print(f"Response: {response.status_code}")
#         print(f"Response Body: {response.text}")
        if response.status_code != 200:
            raise Exception(f"获取文件下载 URL 失败: {response.status_code}, {response.text}")
        data = response.json()
        if "data" not in data or "url" not in data["data"]:
            raise Exception(f"下载 URL 数据格式错误: {data}")
        return data["data"]["url"]

    def _download_file_from_url(self, download_url: str, save_path: str, max_retries: int = 3) -> None:
        """从 URL 下载文件

        Args:
            download_url: 文件下载 URL
            save_path: 保存路径
            max_retries: 最大重试次数
        """
        for attempt in range(max_retries):
            try:
#                 print(f"Request: GET {download_url} (Attempt {attempt + 1}/{max_retries})")
                response = requests.get(download_url, stream=True, timeout=60)
                #print(f"Response: {response.status_code}")
                if response.status_code != 200:
                    raise Exception(f"下载文件失败: {response.status_code}, {response.text}")

                os.makedirs(os.path.dirname(save_path) if os.path.dirname(save_path) else ".", exist_ok=True)
                with open(save_path, "wb") as f:
                    for chunk in response.iter_content(chunk_size=8192):
                        if chunk:
                            f.write(chunk)
                #print(f"文件下载成功: {save_path}")
                return
            except (requests.exceptions.ChunkedEncodingError, requests.exceptions.RequestException, Exception) as e:
                print(f"下载失败 (Attempt {attempt + 1}/{max_retries}): {e}")
                if attempt < max_retries - 1:
                    wait_time = (attempt + 1) * 2
                    print(f"等待 {wait_time} 秒后重试...")
                    time.sleep(wait_time)
                else:
                    raise Exception(f"文件下载最终失败，已重试 {max_retries} 次: {e}")

    def download_file(self, target_file_name: str, output_path: str, **kwargs) -> None:
        """从 Crowdin 下载指定文件

        Args:
            target_file_name: 目标文件名
            output_path: 输出文件路径
            **kwargs: 其他参数（未使用）
        """
        print(f"开始从 Crowdin 下载文件: {target_file_name}")
        # 1. 获取项目文件列表
        print("正在获取项目文件列表...")
        files_data = self._get_project_files()
        # 2. 查找目标文件的 fileId
        print(f"正在查找文件: {target_file_name}")
        file_id = self._find_file_id_by_name(files_data, target_file_name)
        if file_id is None:
            raise Exception(f"未找到文件: {target_file_name}")
        print(f"找到文件 ID: {file_id}")
        # 3. 获取下载 URL
        print("正在获取下载 URL...")
        download_url = self._get_file_download_url(file_id)
        print("下载 URL 获取成功")
        # 4. 下载文件
        print("正在下载文件...")
        self._download_file_from_url(download_url, output_path)
        print("文件下载完成")

    def update_source_language(self, target_file_name: str, output_path: str, **kwargs) -> None:
        """从 Crowdin 更新源语言文件

        Args:
            target_file_name: 目标文件名
            output_path: 输出文件路径（最终保存位置）
            **kwargs: 其他参数（未使用）
        """
        temp_file = "./APP.xlsx"
        self.download_file(target_file_name, temp_file, **kwargs)
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        shutil.copy(temp_file, output_path)
        os.remove(temp_file)
        print(f"源语言文件已更新: {output_path}")


# 默认配置（需要设置）
DEFAULT_ACCESS_TOKEN = "db0506fb755d528c7b9b750e15174d3cfa483859488da978748ad6b9e34d13dc94d8716810a2f978"  # 需要设置
DEFAULT_PROJECT_ID = "71"  # 需要设置
DEFAULT_TARGET_FILE_NAME = "APP.xlsx"


############################

if __name__ == '__main__':
    localizable_path = sys.argv[1]
    crowdin = sys.argv[2]
    if crowdin:
        platform = CrowdinPlatform(DEFAULT_ACCESS_TOKEN, DEFAULT_PROJECT_ID)
        target_path = f"{localizable_path}/APP/APP.xlsx"
        platform.update_source_language(DEFAULT_TARGET_FILE_NAME, target_path)
    else:
        DownLatestLocalizableSource(localizable_path)
