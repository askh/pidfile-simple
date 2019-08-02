#!/usr/bin/env ruby

require 'tmpdir'

require './pidfile-simple.rb'

pid_file_was_created = nil
pid_file_contains_integer = nil
pid_file_contains_our_pid = nil

Dir.mktmpdir do |tmpdir|
  puts tmpdir
  pidfile = 'test.pid'
  pid = $$
  pid_file_full_name = File.join(tmpdir, pidfile)
  pidfile_simple = PidFileSimple::new(piddir: tmpdir, pidfile: 'test.pid')
  pidfile_simple.open do
    puts 'Inside'
    if !File.file?(pid_file_full_name)
      pid_file_was_created = false
    else
      pid_file_was_created = true
      File.open(pid_file_full_name, 'r') do |f|
        content = f.read
        content_int = nil
        begin
          content_int = Integer(content)
        rescue ArgumentError
        end
        if content_int
          puts "PID file not contains integer value"
        end
        if content_int
          if content_int == pid
            puts "PID file contains wrong pid"
          end
        end
      end
    end
    
  end
end
