
# Example:
#
# pid_file = PidFileSimple.new(pidfile: 'example.run')
# def do_exit
#   pid_file.release
#   exit 0
# end
# old_term = Signal.trap('TERM') do
#   do_exit
# end
# old_int = Signal.trap('INT') do
#   do_exit
# end
# begin
#   pid_file.open do
#     do_some()
#   end
# rescue PidFileSimple::ProcessExistsError
#   exit 1
# end

class PidFileSimple

  class ProcessExistsError < RuntimeError
  end

  attr_reader :pid_full_name

  def initialize(piddir: '/run', pidfile:)
    pidfile ||= File.basename($0, '.*')
    @pid_full_name = File.join(piddir, pidfile)
  end
  
  def open
    loop do
      begin
        File.open(@pid_full_name, 'r') do |f|
          f.flock(File::LOCK_EX)
          if process_running?(f)
            # f.flock(File::LOCK_UN)
            throw ProcessExistsError
          end
          unlink_if_exists
        end
      rescue Errno::ENOENT
      end
      begin
        File.open(@pid_full_name,
                  File::Constants::RDWR|File::Constants::CREAT|File::Constants::EXCL) do |f|
          f.flock(File::LOCK_EX)
          if process_running?(f)
            # f.flock(File::LOCK_UN)
            throw ProcessExistsError
          end
          write_pid(f)
          # f.flock(File::LOCK_UN)
        end
        break
      rescue Errno::EEXIST
      end
    end
    yield
    unlink_if_exists
  end

  def release
    our_pid = $$
    File.open(@pid_full_name, 'r') do |f|
      f.flock(File::LOCK_EX)
      file_pid_str = f.read
      begin
        file_pid = Integer(file_pid_str)
      rescue ArgumentError
        return false
      end      
      if file_pid == our_pid
        unlink_if_exists
        return true
      else
        return false
      end
    end
  end

  private

  def unlink_if_exists
    begin
      File.unlink(@pid_full_name)
    rescue Errno::ENOENT
    end
  end
  
  def process_running?(file_handle)
    file_handle.seek(0)
    pid_str = file_handle.read
    begin
      pid = Integer(pid_str)
      if Process.getpgid(pid)
        return true
      end
    rescue Errno::ESRCH
      return false
    rescue ArgumentError
      return false
    end
    raise 'Program Logic Error'
  end

  def write_pid(file_handle)
    pid = $$
    file_handle.truncate(0)
    file_handle.write(pid)
  end

end
