require 'minitest/autorun'
require 'tmpdir'

require 'pidfile-simple'

class PidFileSimpleTest < Minitest::Test

  def test_create_pid_file

    pid_file_now_exists = nil
    pid_file_contains_integer = nil
    pid_file_contains_our_pid = nil
    
    Dir.mktmpdir do |tmpdir|
      pidfile = 'test.pid'
      pid = $$
      pid_file_full_name = File.join(tmpdir, pidfile)
      pidfile_simple = PidFileSimple::new(piddir: tmpdir, pidfile: 'test.pid')
      pidfile_simple.open do
        pid_file_now_exists = File.file?(pid_file_full_name)
        assert pid_file_now_exists, 'PID file not exists'
        if pid_file_now_exists
          File.open(pid_file_full_name, 'r') do |f|
            content = f.read
            content_int = nil
            begin
              content_int = Integer(content)
            rescue ArgumentError
            end
            assert content_int, "PID file not contains integer value"
            if content_int
              assert content_int == pid, "PID file contains wrong pid"
            end
          end
        end
      end
    end
  end

end

