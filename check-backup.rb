#!/usr/bin/ruby
#Configuration
timespan=1814400
threshold_warn=0.8
threshold_crit=0.25
timemachine_dir='/srv/backup'
sftp_dir='/srv/sftp'
Dir.glob(timemachine_dir).max_by {|f| puts File.mtime(f) }

# used_space=`df -h / | grep -v "Filesystem" | awk '{print $5}'`
#  case used_space.chomp <=> "85%"
#  when -1
#    puts "OK - #{used_space.chomp!} of disk space used."
#    exit 0
#  when 0
#    puts "WARNING - #{used_space.chomp!} of disk space used."
#    exit 1
#  when 1
#    puts "CRITICAL - #{used_space.chomp!} of disk space used."
#    exit 2
#  else
#    puts "UNKNOWN - #{used_space.chomp!} of disk space used."
#    exit 3
# end