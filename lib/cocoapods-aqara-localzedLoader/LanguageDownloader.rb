# frozen_string_literal: true
require 'httparty'
require 'zip'
require 'fileutils'
require 'colored2'

class LanguageDownloader

  HeaderString = %Q{User-Agent: volc-sdk-python/v1.0.109
Accept-Encoding: gzip, deflate
Accept: application/json
Host: iam.volcengineapi.com
X-Date: 20231017T062815Z
X-Content-Sha256: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
Authorization: HMAC-SHA256 Credential=AKLTZTFjNzFjYTczMzJjNGQyMjg0NTRkZjQ2ZTA4MTE1Mjc/20231017/cn-north-1/i18n_openapi/request, SignedHeaders=host;x-content-sha256;x-date, Signature=fb24f4211cf74f4e985cdd72f09156c288bd8e078d9867813327084204587b0a
Connection: keep-alive
}
  
  def self.makeHeader
    headerArray = HeaderString.split("\n")
    header = {}
    headerArray.each do |str|
      header[str.split(":",2)[0].strip] = str.split(":",2)[1].strip
    end
    header
  end
  def self.download

    # puts makeHeader
    #下载文件

    params = {"projectIdList":[5],"langIds":[1,2,3,9,10,11,12,13,14,15,16,17,18],"fileTypeList":["excel"],"auditState":1,"valueState":0,"userId":"","value":"","tagIds":nil,"bizUseTagIds":nil,"pkeys":[]}
    response = HTTParty.post('https://intl-lang.aqara.com/v1.0/lumi/language/file/export', body: JSON.generate(params), headers:LanguageDownloader.makeHeader)
    # puts response.body
    unless response.body["code"] == nil
      3.times do
        puts "资源包下载失败了！！！！！ code:#{response.body}".red
      end
      return
    end
    destation_path = "./localize.zip"
    if File.exist? destation_path
      FileUtils.rm_rf destation_path
    end
    File.open(destation_path,"w") do |io|
      io.binmode
      io.write response.body
    end

    # 解压缩文件到指定目录
    f_path =  ''

    Zip::File.open(destation_path) do |zip_file|
      zip_file.each do |f|
        f_path = File.join('./','hit_all.xls')
        File.delete f_path if File.exist? f_path
        # FileUtils.mkdir_p(File.dirname(f_path))
        f.extract(f_path)
      end

    end
    if File.exist? destation_path
      FileUtils.rm_rf destation_path
    end

    f_path
  end

end

#LanguageDownloader.download
