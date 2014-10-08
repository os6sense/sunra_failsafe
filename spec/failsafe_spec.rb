require_relative '../failsafe'

require 'sunra_config/failsafe'
require 'sunra_ps'

include SunraPS

# Note a requirement of these tests is the ffs-relay is running.
# These are brittle tests but confirm correct operation.
describe Sunra::Recording::Failsafe do
  let(:fs_rec) { Sunra::Recording::Failsafe.new(Sunra::Config::Failsafe.new) }

  describe :initialize do
    it 'creates an instance of the subject' do
      fs_rec.should_not be nil
    end
  end

  describe :process_control do
    before(:each) do
      fs_rec.start(false, false)
      fs_rec.is_recording?.should eq true #sanity check
    end

    after(:each) { fs_rec.stop }

    describe :start do
      context 'when ffserver and the feed are running' do
        context 'and when the capturer terminates for any reason' do
          it 'should restart' do
            # force a termination of the capturer
            kill fs_rec.pid
            sleep 1 # allow time to restart

            fs_rec.is_recording?.should eq true
          end
        end

        context 'when ffserver terminates for any reason' do
          it 'should restart' do
            # force a termination of ffserver
            ffs_pid = get_pid('ffserver')
            kill ffs_pid
            sleep 2 # allow time to restart

            fs_rec.is_recording?.should eq true
          end
        end
      end

      context 'when the lock file is deleted' do
        it 'should stop' do
          File.delete('/tmp/failsafe.lock')
          sleep 1
          fs_rec.is_recording?.should eq false
        end
      end
    end

    describe :stop do
      it 'deletes the lockfile' do
        fs_rec.stop
        File.exists?('/tmp/failsafe.lock').should eq false
      end

      it 'stops the capture process and the failsafe process' do
        fs_rec.stop
        sleep 1 # allow time to restart
        fs_rec.is_recording?.should eq false
      end
    end
  end
end
