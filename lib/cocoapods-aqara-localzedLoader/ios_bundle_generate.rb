# frozen_string_literal: true
require_relative './LanguageDownloader'
require_relative  './File_util'
require 'fileutils'
require 'open3'
# require 'colored2'
class BundleGenerater

  # INFO_PLIST_ARRAY = [NSAppleMusicUsageDescription","NSLocalNetworkUsageDescription"]
  INFO_PLIST_MAP = {
    common_app_name: ["CFBundleDisplayName"],
    other_perm_camera_permission_description: [
      "NSCameraUsageDescription"
    ],
    other_perm_location_permission_description: [
      "NSLocationAlwaysAndWhenInUseUsageDescription",
      "NSLocationWhenInUseUsageDescription",
      "NSLocationAlwaysUsageDescription"
    ],
    other_perm_bluetooth_permission_description: [
      "NSBluetoothPeripheralUsageDescription",
      "NSBluetoothAlwaysUsageDescription"
    ],
    access_content_permssion_storage: [
      "NSPhotoLibraryUsageDescription"
    ],
    other_perm_mic_permission_description: [
      "NSMicrophoneUsageDescription"
    ],
    other_set_permissions_homedata_desc: [
      "NSHomeKitUsageDescription"
    ],
    other_set_permissions_asr_text: [
      "NSSpeechRecognitionUsageDescription"
    ],
    device_add_device: [
      "Add_Device_Title"
    ],
    automation_add: [
      "Add_Automation_Title"
    ],
    device_create_scene: [
      "Add_Scene_Title"
    ],
    NFCReaderUsageDescription: [
      "NFCReaderUsageDescription"
    ]
  }

  #定义类变量记录下载次数

  @@download_Count = 1

  def self.downloadxls(project_path)
    if @@download_Count > 10
      puts "当前无网络，程序即将退出。"
      exit(1)
    end
    if @@download_Count > 1
      base = 2
      sleep_time = base * (2 ** (@@download_Count - 2))
      puts "等待#{sleep_time}秒后重试..."
      sleep sleep_time
    end
    puts "当前进行第#{@@download_Count}次尝试下载多语言文件"
    system "cd #{File.dirname(__FILE__)};python3 DownloadNewLanguage.py #{project_path}"
    @@download_Count = @@download_Count + 1
  end

  def self.generate(project_path)
    # 下载excel
    puts "开始下载多语言文件...".green


    f_path = "#{project_path}/download.xlsx"
    printf(f_path)

    until File.exist?(f_path)
      self.downloadxls(project_path)
    end

    # 读取excel到内存
    file_til = File_util.new
    hash = file_til.read_excel f_path
    if File.exist? f_path
      FileUtils.rm_rf f_path
    end
    puts "一共有 #{hash.keys.size} 条文案".green

    # 创建文件夹
    file_til.getLangList.each do |lang|
      # puts lang
      localized_file = "./#{lang}.lproj/Localizable.strings"
      dir = File.dirname localized_file
      FileUtils.rm_rf localized_file
      FileUtils.mkdir_p dir
      new_file = File.new(localized_file, "w")
      new_file.close

    end

    #生成资源文件
    hash.each do |key, stringElement|
      num = 0
      stringElement.langHash.each do |lang, value|
        # puts "#{lang}:#{value}"
        next if lang.downcase === "selfkey" or value === nil or value === " " or value === ""
        value = self.handleValue value,stringElement
        value.scan(/%@/) do |match|
          num = match.size  if num == 0
          if num != match.size
            puts "key:#{key}中%@ 数量不一致,请检查".red
          end
        end
        str = %Q|"#{key}" = "#{value}";\n|
        localized_file = "./#{lang}.lproj/Localizable.strings"

        if File.exist?(localized_file)
          File.open(localized_file, "a") do |io|
            io.write str
        end
        end

        #如果是infoplist里的key，就写入指定的文件
        if key === nil
          puts "key值为空,#{stringElement.ios_list}"
        elsif key === "NSAppleMusicUsageDescription" || key === "NSLocalNetworkUsageDescription"
          file = "./#{lang}.lproj/InfoPlist.strings"
          File.open(file, "a") do |io|
            io.write str
          end
        elsif INFO_PLIST_MAP.has_key?(key.to_sym)
          # puts "---key:#{key}"
          keys = INFO_PLIST_MAP[key.to_sym]
          keys.each do |info_key|
            file = "./#{lang}.lproj/InfoPlist.strings"
            str = %Q|"#{info_key}" = "#{value}";\n|
            File.open(file, "a") do |io|
              io.write str
            end
          end
        end

      end
    end

    #验证导出的多语言包格式是否正确
    puts '开始校验多语言包格式'.red
    # puts "\e[31m 开始校验多语言包格式\e[0m"
    file_til.getLangList.each do |lang|
      localized_file = "./#{lang}.lproj/Localizable.strings"
      file = "./#{lang}.lproj/InfoPlist.strings"
      if File.exist?(file)
        system("plutil #{file}")
      end
      if File.exist?(localized_file)
        system("plutil #{localized_file}")
      end
    end

    #拷贝到代码仓库里
    #查找bundle路径
    bundPath = ""
    info_plist_path = "./AqaraHome/Resource"
    require 'find'
    Find.find("./") do |filePath|
      if  filePath.end_with?("LMFramework.bundle")
        bundPath = filePath
      elsif filePath.end_with?("Resource")
      end
    end
    unless bundPath != ""
      puts '没有拷贝'
      return
    end

    copy_info_plist = false
    file_til.getLangList.each do |lang|
      path = "./#{lang}.lproj/Localizable.strings"
      dest = bundPath + "/#{lang}.lproj"
      dest2 = "./AqaraHome/Resource/#{lang}.lproj"
      FileUtils.mkdir_p dest
      FileUtils.cp(path,dest2)
      FileUtils.mv("#{path}",dest,force:true)

      info_plist_file = "./#{lang}.lproj/InfoPlist.strings"
      # puts "path::::::#{info_plist_file}"
      if File.exist? info_plist_file
        copy_info_plist = true
        dest = "./AqaraHome/Resource/#{lang}.lproj"
        FileUtils.mkdir_p dest
        FileUtils.mv("#{info_plist_file}",dest,force:true)
      end
      FileUtils.rm_rf (File.dirname(path))
    end
    puts "多语言拷贝到目录:#{bundPath}"
    if copy_info_plist
      puts "InfoPlist多语言拷贝到目录:#{info_plist_path}"
    end

  end
  #对多语言的value进行处理
  def self.handleValue(value='',stringElement = nil)
    #替换{=}
    value = self.replace_placeholders value
    value = value.gsub(/{#}/,"%@")
    value = value.gsub(/""/,'"')
    value = value.gsub(/\\"/,'"')
    value = value.gsub(/""/,'"')
    value = value.gsub(/"/,'\"')
    #fix "common_time_day_with_space" = "\ day \";
    if value.end_with?"\\"
      value = value.chop
    end
    if value.end_with?"\\"
      value = value.chop
    end
    value
  end

  def self.replace_placeholders(str='')
    return str.gsub(/%(\d+)\$s/, '%\1$@')
  end

end


# BundleGenerater.generate
# map = {:common_app_name=>["CFBundleDisplayName"]}
# if map.has_key?("common_app_name".to_sym)
#   puts map[:common_app_name]
# end
# BundleGenerater.generate
# ios_list = ["%@","%d"]
# str = "{#}盏灯开着,真的吗{#}"
# i = -1
# str = str.gsub(/{#}/) do |matched|
#   i+=1
#   ios_list[i]
# end
#
# p str
# puts "111".green
