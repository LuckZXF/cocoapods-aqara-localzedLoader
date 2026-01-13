# frozen_string_literal: true
require_relative './LanguageDownloader'
require_relative  './File_util'
require_relative './crowdin_util'
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

  def self.downloadxls(project_path, crowdin=false)
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
    crowdin_arg = crowdin ? "true" : "false"
    system "cd #{File.dirname(__FILE__)};python3 DownloadNewLanguage.py #{project_path} #{crowdin_arg}"
    @@download_Count = @@download_Count + 1
  end

  def self.generate(project_path)
    # 下载excel
    puts "开始下载多语言文件...".green

    crowdin = true if File.exist? "#{project_path}/crowdin.yml"

    f_path = "#{project_path}/download.xlsx"
    if crowdin
      f_path = "#{project_path}/APP/APP.xlsx"
    end

    puts f_path

    until File.exist?(f_path)
      self.downloadxls(project_path, crowdin)
    end
    # 读取excel到内存
    file_til = File_util.new
    hash = file_til.read_excel(f_path, crowdin)
    if File.exist? f_path
      if crowdin
        parent_dir = File.dirname(f_path)
        FileUtils.rm_rf(parent_dir)
      else
        FileUtils.rm_rf f_path
      end
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

    errors = []
    #生成资源文件
    hash.each do |key, stringElement|
      expected_count = nil
      stringElement.langHash.each do |lang, value|
        # puts "#{lang}:#{value}"
        next if lang.downcase === "selfkey" or lang.downcase === "context" or lang.downcase === "tag" or lang.downcase === "length limit" or value === nil or value === " " or value === ""
        value = self.handleValue value,stringElement
        current_count = value.scan(/%@/).size

        if expected_count.nil?
          expected_count = current_count
        elsif current_count != expected_count
          errors << {
            key: key,
            lang: lang,
            expected: expected_count,
            actual: current_count
          }
          next
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

    #判读是否有多语言出现不同语种%@数量不匹配,出现后中断打包
    if errors.any?
      puts "以下 key 的 %@ 在不同语种的数量存在不一致，让产品交互速度改后再打包：\n".red
      errors.each do |err|
        puts "key: #{err[:key]} | 语言: #{err[:lang]} | 实际: #{err[:actual]} | 应为: #{err[:expected]}".red
      end
      exit(1)
    else
      puts "✅ 所有 key 的 %@ 在不同语种保持数量一致".green
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
      # FileUtils.rm_rf (File.dirname(path))
    end
    puts "多语言拷贝到目录:#{bundPath}"
    if copy_info_plist
      puts "InfoPlist多语言拷贝到目录:#{info_plist_path}"
    end
    if crowdin
      system("crowdin upload translations --config #{project_path}/AqaraHome/Common/crowdin.yml --branch iOS_Localizable")
      crowdin_util = CrowdinUtil.new
      crowdin_util.release_distribution
    end
  end
  #对多语言的value进行处理
  def self.handleValue(value='',stringElement = nil)
    #替换{=}
    value = self.replace_placeholders value
    value = value.gsub('%s', '%@')
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
