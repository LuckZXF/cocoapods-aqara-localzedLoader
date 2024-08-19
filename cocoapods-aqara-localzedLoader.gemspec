# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-aqara-localzedLoader/gem_version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-aqara-localzedLoader'
  spec.version       = Localzedloader::VERSION
  spec.authors       = ['zhaoxifan']
  spec.email         = ['179988305@qq.com']
  spec.description   = %q{Aqara 多语言插件}
  spec.summary       = %q{Aqara 多语言从云端多语言平台下载并处理解析成Xcode需要的多语言文件}
  spec.homepage      = 'https://github.com/LuckZXF/cocoapods-aqara-localzedLoader'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 2.1'
  spec.add_development_dependency 'coveralls', '>= 0'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '>= 3.0'

  spec.add_runtime_dependency 'claide', '>= 1.0.2', '< 2.0'
  spec.add_runtime_dependency 'colored2'
  spec.add_runtime_dependency 'fileutils'
  spec.add_runtime_dependency 'rubyzip'
  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'rubyXL'
  spec.add_runtime_dependency 'open3'
end
