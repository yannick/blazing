require 'blazing/shell'

class Blazing::Target

  attr_accessor :name, :location, :options

  def initialize(name, location, config, options = {})
    @name = name
    @location = location
    @config = config
    @options = options
    @shell = Blazing::Shell.new
  end

  def setup
    logger.info "Setting up repository for #{name} in #{location}"
    @shell.run "ssh #{user}@#{host} '#{init_repository} && #{setup_repository}'"
  end

  def apply_hook
    logger.info "Generating and uploading post-receive hook for #{name}"
    hook = ERB.new(File.read("#{Blazing::TEMPLATE_ROOT}/hook.erb")).result(binding)

    File.open(Blazing::TMP_HOOK, "wb") do |f|
      f.puts hook
    end

    logger.debug "Copying hook for #{name} to #{location}"
    copy_hook
    @shell.run "ssh #{user}@#{host} #{make_hook_executable}"
  end

  def path
    @location.match(/:(.*)$/)[1]
  end

  def host
    host = @location.match(/@(.*):/)
    host[1] unless host.nil?
  end

  def user
    user = @location.match(/(.*)@/)
    user[1] unless user.nil?
  end

  def init_repository
    "git init #{path}"
  end

  def copy_hook
    logger.debug "Making hook executable"
    @shell.run "scp #{Blazing::TMP_HOOK} #{user}@#{host}:#{path}/.git/hooks/post-receive"
  end

  def make_hook_executable
    "chmod +x #{path}/.git/hooks/post-receive"
  end

  def setup_repository
    "cd #{path} && git config receive.denyCurrentBranch ignore"
  end

end
