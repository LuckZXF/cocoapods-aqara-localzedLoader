
# require 'file'
$LOAD_PATH << '.'
# -*- coding: UTF-8 -*-
require 'rubyXL'
require_relative  './StringElement'

class File_util

  attr_accessor :keys_hash
    #读取excel 返回StringElement数组
    def read_excel(filename)
      unless filename != nil
        puts "读取的excel为空"
        return
      end

      workbook = RubyXL::Parser.parse filename
      worksheet = workbook[0]
      row1 = worksheet[0]
      @key_hash = getkeyHash(row1)
      lang_hash = {}
      worksheet.each_with_index do |row,rowIndex|
        next unless rowIndex>0
        ele = StringElement.new
        self_key = ''
        # 设置StringElement的值
        row.cells.each_with_index do |cell, i|
          next unless cell.value
          case i
          when 0
            self_key = cell.value
          else
            key = @key_hash[i]
            if key
              ele.langHash[key] = (cell.value || '')
            end
          end
        end

        lang_hash[self_key] = ele
      end
      lang_hash
    end

    #根据第一行来获取当前cell的key
    # return {1:selfkey,2:en,3:zh....} 方便excel取
    # Command+Option+L 对齐快捷键
    def getkeyHash(row1,ios:true)
      keys_hash = {}
      key = ''
      row1.cells.each_with_index do |cell, i|
        next unless cell.value && i > 3
        if cell.value === "zh-CN"
          key = 'zh-Hans'
        elsif cell.value == "zh-TW"
          key = 'zh-Hant-TW'
        elsif cell.value == "zh-HK"
          key = 'zh-HK'
        else
          key = cell.value.split("-")[0]
        end
        # result = cell.value.scan(/.*?\[(.*)\]/)
        keys_hash[i] = key
      end
      keys_hash
    end

    def getLangList
      list = @key_hash.values
      list.delete_if{|item| item.downcase === "keys"||item.downcase === "source" || item.downcase === "length limit" || item.downcase === "context"}
      list
    end
end

# hash = File_util.read_excel"hit_all.xls"
# puts hash.keys.size
# hash.each do |key,value|
#   puts value
# end

# p "key-sname".split("-")[0]

