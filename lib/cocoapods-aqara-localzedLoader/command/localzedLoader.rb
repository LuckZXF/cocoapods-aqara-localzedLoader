require_relative '../ios_bundle_generate'
module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Download < Command
      self.summary = 'langDownnloader for user'

      self.description = <<-DESC
        help user downnloade language resource
      DESC

      self.arguments = []

      def initialize(argv)
        super
        # puts "初始化:#{argv}"
        project_directory = argv.option('project-directory')
        puts project_directory
        project_directory = Dir.pwd if project_directory.nil?
        puts project_directory
        @project_directory = Pathname.new(project_directory).expand_path
        puts project_directory

      end
      def self.options
        [
          ['--project-directory=/project/dir/', 'The path to the root of the project directory']
        ].concat(super)
      end
      def run
        UI.puts "项目路径 #{@project_directory}"
        BundleGenerater.generate(@project_directory)
      end
    end
  end
end