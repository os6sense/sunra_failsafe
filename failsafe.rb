# File:: failsafe.rb
#
# Description::
# Base class to allow sub classes to ensure that a stream is
# always captured from the ffserver relay.
require 'sunra_utils/ps'
require 'sunra_utils/capture'
require 'sunra_utils/logging'
require 'sunra_utils/lockfile'

module Sunra
  module Recording
    # **CONTINUALLY** Capture audio/video from the ffserver
    # in files of 1hrs length. Length is determined via the
    # -t value specified in the relevant config file
    class Failsafe
      include Sunra::Utils::Logging
      include Sunra::Utils::PS

      def initialize(config, lockfile = nil)
        @cap = Sunra::Utils::Capture.new(config) do
          logger.info 'Failsafe Capture Stopped'
        end

        @lock_file = lockfile
        @lock_file =
          Sunra::Utils::LockFile.new('/tmp/failsafe.lock') if @lock_file.nil?
      end

      def is_recording?
        @cap.is_recording?
      end

      def pid
        @cap.pid
      end

      # Description::
      # Start the failsafe service. IF the capture thread dies for any
      # reason (its pid doesnt exist, which is what is_recording? should
      # tell us) then the failsafe service will attempt to restart as long
      # as its lockfile exists.
      def start(monitor = false, daemonized = true)
        if @lock_file.exists?
          logger.warn 'Service Running/Lockfile already exists! Exiting.'
          return
        end

        logger.info 'Starting Failsafe Service'

        _start_capture
        _start_failsafe_thread

        if monitor || daemonized
          loop do
            sleep 1
          end
        end
      end

      def _start_failsafe_thread
        @t = Thread.new do
          loop do
            unless @cap.is_recording?
              logger.info('failsafe.start') { 'Failsafe Restart Triggered.' }
              _start_capture
            end

            unless @lock_file.exists?
              logger.info('failsafe.start') { 'Lockfile absent, stopping!' }
              @cap.stop if @cap.is_recording?
              break
            end
            sleep 0.5
          end
          stop
        end
      end

      # Description::
      # attempt to stop the failsafe service. Internally @stop is set to true
      # which tells the thread launched by start to stop looping. In addition
      # the lockfile is deleted which is another trigger for the failsafe
      # to stop.
      def stop
        if @lock_file.exists?
          pid = Integer(@lock_file.contents[0])
          logger.info('failsafe.stop') { 'Deleting Lockfile.' }

          @lock_file.delete
          kill pid
        end
      end

      # Description::
      # Prints out the status of the service using the logger.
      def status
        unless @lock_file.exists?
          logger.info { 'Failsafe Stopped/Lockfile Not Found.' }
          return
        end

        pid = Integer(@lock_file.contents[0])
        if pid > -1 && pid_exists?(pid)
          logger.info { 'Failsafe Running.' }
        else
          logger.warn { 'Failsafe Running but unable to capture.' }
        end
      end

      protected

      def _start_capture
        @cap.start
        @lock_file.create([@cap.pid])
        logger.info 'Failsafe Service Started.'
      rescue RuntimeError
        # If the ffserver is not running we will definately receive
        # a runtime error. Rather than abort we keep trying.
        logger.error 'Runtime Error attempting to start capture!'
        @lock_file.create(-1)
        sleep 1
      end
    end
  end
end
