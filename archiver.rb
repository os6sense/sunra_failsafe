#!/usr/bin/env ruby
# File:: sunra-failsafe.rb
# Description:: Manage recordings so that :
# - any recording older than n weeks old is deleted
# - any recording greater than n weeks is down converted

module Sunra
  module Failsafe
    require "FileUtils"
    require 'date'

    # Class:: Archiver
    # Manage recordings to ensure that archival data size is kept within
    # reasonable bounds
    class Sunra::Failsafe::Archiver
      attr_accessor :config

      def initialize config
        @config = config
      end

      def check_age path, months, &block
        Dir.glob(path) do | f |
          if File.mtime(f).to_date < Date.today - (months * 28) 
            block.call f
          end
        end
      end

      # check the age of all files in STORAGE_DIR
      # check_storage_age "*.mp3"
      def check_storage_age filetype
        check_age "#{@config.storage_dir}/#{filetype}", \
            @config.delete_after do | f |
          puts "delete #{f}"
          File.delete f
        end
      end

      # check the age of all files in ARCHIVE_DIR
      # check_storage_age "*.mp3"
      def check_archive_age filetype
        check_age "#{@config.storage_dir}/#{@config.archive_dir}/#{filetype}", \
            @config.archive_after do |f|
          puts "archive #{f}"

          #FileUtils.move 'stuff.rb', '/notexist/lib/ruby'
        end
      end

    end
  end
end
