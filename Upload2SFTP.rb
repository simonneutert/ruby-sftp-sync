#!/usr/bin/env ruby

require 'net/ssh'
require 'net/sftp'
require 'find'
require 'io/console'
require 'yaml'
require 'rubygems'
require 'commander/import'
require 'fileutils'


# unpolute namespace
module Upload2SFTP

  # Server holds your hosts' specific data
  class Server
    attr_reader :host_url, :username, :password
    def initialize(host_url, username, password)
      @host_url = host_url
      @username = username
      @password = password
    end
  end

  # Client holds your client-side related settings
  class Client
    attr_reader :local_path, :remote_path, :dir_perm, :file_perm
    def initialize(local_path, remote_path, dir_perm, file_perm)
      @local_path = local_path
      @remote_path = remote_path
      @file_perm = file_perm
      @dir_perm = dir_perm
    end
  end

  def self.upload(config_path="./config.yml")
    connect_to_server(config_path) do |sftp, client, server|
      create_root_dir(sftp, client)
      Find.find(client.local_path) do |file|
        if File.stat(file).directory?
          next
        else
          local_file = file.to_s
          remote_file = client.remote_path + local_file.sub(client.local_path, '')
          remote_dir = File.dirname(remote_file)
          upload_dir(sftp, local_file, remote_dir, client)
          upload_file(sftp, local_file, remote_file, client)
        end
      end
    end
  end

  def self.clean(config_path="./config.yml")
    connect_to_server(config_path) do |sftp, client, server|
      sftp.session.exec!("rm -rf #{client.remote_path + "/*"}")
    end
  end

  def self.remove(config_path="./config.yml")
    connect_to_server(config_path) do |sftp, client, server|
      sftp.session.exec!("rm -rf #{client.remote_path + "/*"}")
      sftp.session.exec!("rm -rf #{client.remote_path}")
    end
  end

  private

  # loads the configuration from a config file
  def self.load_configuration(config_path)
    puts "Loading config..."
    if File.exists?(config_path)
      config = YAML.load_file(config_path)
    else
      puts 'config.yml not found, needs to be in the same directory as this script.'
      exit() # no config no love
    end
    host_url = config['host_url']
    username = config['username']
    p "Enter SSH/SFTP Password for user #{username}:"
    password = STDIN.noecho(&:gets).chomp # hidden user input
    server = Server.new(host_url, username, password)

    local_path = config['local_path']
    remote_path = config['remote_path']
    file_perm = config['file_perm'].to_i(8)
    dir_perm = config['dir_perm'].to_i(8)
    client = Client.new(local_path, remote_path, dir_perm, file_perm)

    return client, server
  end

  # connect_to_server
  # loads configuration and instantiates Client and Server objects
  # pass a block that gets executed on the established sftp connection
  def self.connect_to_server(config_path)
    client, server = load_configuration(config_path)
    puts 'Connecting to remote server'
    Net::SSH.start(server.host_url, server.username, password: server.password) do |ssh|
      ssh.sftp.connect do |sftp|
        if block_given?
          yield(sftp, client, server)
        else
          raise "No block given, please specify a block."
        end
      end # sftp session closed
    end # ssh session closed
    puts 'Disconnecting from remote server'
    puts 'File transfer complete'
  end

  # create root directory if missing
  def self.create_root_dir(sftp, client)
    begin
      sftp.mkdir!(client.remote_path, permissions: client.dir_perm)
    rescue Net::SFTP::StatusException => e
      raise unless e.code == 4
    end
  end

  # upload directory
  def self.upload_dir(sftp, local_file, remote_dir, client)
    begin
      # directory exists?
      sftp.dir.entries(remote_dir)
    rescue Net::SFTP::StatusException => e
      raise unless (e.code == 2) || (e.code == 4)
      # parse directory structure from file(path)
      dir_structure = File.dirname(local_file.sub(client.local_path, ''))[1..-1].split('/')
      # create directory and subdirectories if they do not exist
      create_directory(sftp, client, dir_structure, remote_dir)
    end
  end

  # uploads a file
  def self.upload_file(sftp, local_file, remote_file, client)
    # does the file exist?
    begin
      rstat = sftp.file.open(remote_file).stat
      # does the file need updating?
      if File.stat(local_file).mtime > Time.at(rstat.mtime)
        sftp.upload!(local_file, remote_file) # update file
        puts "updating #{remote_file}"
      end
    rescue Net::SFTP::StatusException => e
      raise unless e.code == 2
      # file does not exist -> upload
      sftp.upload!(local_file, remote_file)
      sftp.setstat(remote_file, permissions: client.file_perm)
      puts "creating #{remote_file}"
    end
  end

  # create a directory
  def self.create_directory(sftp, client, dir_structure, remote_dir)
    # do subdirectories need to be created?
    if dir_structure.size <= 1 # no subdirectories
      sftp.mkdir!(remote_dir)
      puts "creating dir: #{remote_dir}"
    else
      # iterate over subdirectories and create them
      dir_structure.each_with_index do |_d, i|
        begin
          # code diamond<3 ahead
          subdir = client.remote_path + "/#{dir_structure[0..i].join('/')}"
          sftp.mkdir!(subdir, permissions: client.dir_perm)
          puts "creating dir: #{subdir}"
        rescue Net::SFTP::StatusException => e
          # directory or subdirectory exists already
          raise unless e.code == 4
          next
        end
      end
    end
  end
end

program :name, 'Upload2SFTP'
program :version, '0.5.1'
program :description, 'simple sftp interaction'

command :upload do |c|
  c.syntax = 'Upload2SFTP upload [options]'
  c.summary = 'uploads a directory and all its content to a webhoster'
  c.description = ''
  c.example 'description', 'command example'
  c.option '--config x', 'Some switch that does something'
  c.action do |args, options|
    if options.config
      if options.config.include?("./")
        Upload2SFTP.upload(options.config)
      else
        Upload2SFTP.upload("./" + options.config)
      end
    else
      Upload2SFTP.upload()
    end
  end
end

command :clean do |c|
  c.syntax = 'Upload2SFTP clean [options]'
  c.summary = 'cleans the remote directory from all content'
  c.description = ''
  c.example 'description', 'command example'
  c.option '--config x', 'Some switch that does something'
  c.action do |args, options|
    # Do something or c.when_called Upload2SFTP::Commands::Clean
    if options.config
      if options.config.include?("./")
        Upload2SFTP.clean(options.config)
      else
        Upload2SFTP.clean("./" + options.config)
      end
    else
      Upload2SFTP.clean()
    end
  end
end

command :remove do |c|
  c.syntax = 'Upload2SFTP remove [options]'
  c.summary = 'removes the content completely'
  c.description = ''
  c.example 'description', 'command example'
  c.option '--config x', 'Some switch that does something'
  c.action do |args, options|
    if options.config
      if options.config.include?("./")
        Upload2SFTP.remove(options.config)
      else
        Upload2SFTP.remove("./" + options.config)
      end
    else
      Upload2SFTP.remove()
    end
  end
end

command :reupload do |c|
  c.syntax = 'Upload2SFTP reupload [options]'
  c.summary = ''
  c.description = ''
  c.example 'description', 'command example'
  c.option '--config x', 'Some switch that does something'
  c.action do |args, options|
    puts "\n\n\tYou need to enter your password twice!\n\n"
    if options.config
      if options.config.include?("./")
        Upload2SFTP.clean(options.config)
        Upload2SFTP.upload(options.config)
      else
        Upload2SFTP.clean("./" + options.config)
        Upload2SFTP.upload("./" + options.config)
      end
    else
      Upload2SFTP.clean()
      Upload2SFTP.upload()
    end
  end
end
