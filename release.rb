#!/usr/bin/env ruby

require 'optparse'
require 'pp'

require 'erb'

def main()

  # Global settings
  # working_dir = File.join(File.dirname(__FILE__), 'tmp')
  conf_dir = File.join(File.dirname(__FILE__), 'conf')
  options = {
    root_build_dir:   "#{ENV['HOME']}/Workspace/Builds/",
    environments: ['development', 'recette', 'preprod', 'prod']
  }

  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: release.rb OPTIONS"

    opts.on("-v", "--version-name VERSION_NAME", "Set the build version name") do |version_name|
      options[:version_name] = version_name
    end

    opts.on("-p", "--project-name PROJECT_NAME", "Select the project") do |project|
      options[:project_name] = project
    end

    opts.on("-e", "--environments env1,env2,..", "Specify environments") do |envString|
      options[:environments] = envString.split(',')
    end

    opts.on("-r", "--root-build-dir PATH", "Path of root build dir") do |root_build_dir|
      options[:root_build_dir] = root_build_dir
    end
  end

  opt_parser.parse!

  # Parameters checking
  raise OptionParser::MissingArgument.new(:project_name) if options[:project_name].nil?
  raise OptionParser::MissingArgument.new(:version_name) if options[:version_name].nil?

  # Create the builds dir for the given version
  build_dir = File.join(options[:root_build_dir], options[:project_name], options[:version_name])
  unless File.exists?(build_dir)
    Dir.mkdir(build_dir)
    puts "#{build_dir} [created]"
  end

  # For each env
  options[:environments].each do |env|
    puts
    puts "Building for env: #{env}"
    puts

    # Assert there is an env xcconfig file
    env_conf_file = File.join(conf_dir, options[:project_name], "#{env}.xcconfig")
    unless File.exists?(env_conf_file)
      raise OptionParser::InvalidOption.new("Can't find the #{env} xcconfig: #{env_conf_file}")
    end

    # Assert there is an env distribution plist
    env_erb_plist = File.join(conf_dir, options[:project_name], "#{env}.plist.erb")
    unless File.exists?(env_erb_plist)
      raise OptionParser::InvalidOption.new("Can't find the #{env} plist template: #{env_erb_plist}")
    end

    # Create the ipa destination dir
    env_build_dir = File.join(build_dir, env)
    unless File.exists?(env_build_dir)
      Dir.mkdir(env_build_dir)
      puts "    #{env_build_dir} [created]"
    end

    # Build ipa
    build_succeeded = system(
      'ipa', 'build',
      '--configuration', 'Release',
      '--scheme', options[:project_name],
      '--xcconfig', env_conf_file,
      '--destination', env_build_dir
    )
    raise "IPA building fail for env : #{env}" unless build_succeeded

    # Rename ipa
    File.rename(
      File.join(env_build_dir, "#{options[:project_name]}.app.dSYM.zip"),
      File.join(env_build_dir, "#{options[:project_name]}-#{options[:version_name]}.app.dSYM.zip")
    )
    File.rename(
      File.join(env_build_dir, "#{options[:project_name]}.ipa"),
      File.join(env_build_dir, "#{options[:project_name]}-#{options[:version_name]}.ipa")
    )

    # Generate plist
    template = File.read(env_erb_plist)
    renderer = ERB.new(template)
    plist_content = renderer.result(binding)
    File.open(File.join(env_build_dir, "#{options[:project_name]}-#{options[:version_name]}.plist"), 'w') do |file|
      file.write(plist_content)
    end

    puts
    puts "Built for env #{env} ready to be uploaded"
    puts
  end

  options[:environments].each do |env|
    # TODO push to ftp server
  end

  system('open', build_dir)

rescue OptionParser::ParseError => exception
  puts 'Error:'
  puts exception
  puts
  puts opt_parser.help
rescue => exception
  puts 'Error:'
  puts exception
  puts
  puts exception.backtrace
end

main()
