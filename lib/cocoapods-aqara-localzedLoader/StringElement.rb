# frozen_string_literal: true

class StringElement
  attr_accessor :langHash
  attr_accessor :ios_list
  attr_accessor :android_list

  def initialize
    @langHash = {}
    @ios_list = []
    @android_list = []
  end

  def to_s
    @langHash.to_s
  end
end