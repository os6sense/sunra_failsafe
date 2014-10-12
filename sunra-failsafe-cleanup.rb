#!/usr/bin/env ruby
# File: sunra-failsafe-cleanup.rb
# Description: Depending on the configuration directive, deletes or
# archives files recorded by the failsafe process.
#
# Notes: Please note that since this is intended to be run as a daemon
# the long filename is used in order to easily identify this process
# in the process list

require 'daemons'

require 'sunra_utils/config/failsafe'
require_relative './archiver'

# Only run once per hour
RUN_FREQUENCY = 3600

mp3_conf = Sunra::Failsafe::Config::MP3.new
mp4_conf = Sunra::Failsafe::Config::MP4.new

mp3_archiver = Sunra::Failsafe::Archiver (mp3_conf)
mp4_archiver = Sunra::Failsafe::Archiver (mp4_conf)

Daemons.run_proc('sunra-failsafe-cleanup.rb') do
  loop do
    mp3_archiver.clean
    mp4_archiver.clean

    # only run once per hour
    sleep RUN_FREQUENCY
  end
end
