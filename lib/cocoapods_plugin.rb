require 'cocoapods-aqara-localzedLoader/command'
require_relative 'cocoapods-aqara-localzedLoader/ios_bundle_generate'
module Pod
  Pod::HooksManager.register('cocoapods-aqara-localzedLoader', :pre_install) do |context|
    args = ['download', "--project-directory=#{Config.instance.installation_root}"]
    Pod::Command.run(args)
  end
end