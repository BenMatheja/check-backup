#!/usr/bin/ruby
require 'etc'
require 'date'

#Configuration: State 0 active, 1 old, 2 absent
@latest_backup_allowed=Time.now - (3*7*24*60*60)
threshold_warn=0.8
threshold_crit=0.25
timemachine_dir='/srv/backup'
sftp_dir='/srv/sftp'

#Retrieve Backup Users
blacklist = File.read('blacklist')
backup_users= Array.new
@users_and_dates = Hash.new
@users_and_result = Hash.new

Etc.passwd do |user|
  backup_users.push(user.name)
end
backup_users.reject!{|x| blacklist.include? x}

#Function to Traverse directories and storing newest file modified date to hash
def traverse (directory)
  Dir.chdir(directory)
  Dir.glob("**/*").each do |file| 
    if File.file? file
      File.mtime(file)
      owner_name = Etc.getpwuid(File.stat(file).uid).name
      if @users_and_dates.has_key?(owner_name)
        if @users_and_dates[owner_name] < File.mtime(file)
          @users_and_dates[owner_name] = File.mtime(file)
        end
      else
        @users_and_dates[owner_name] = File.mtime(file)
      end
    end
  end
end

def evaluate (date_of_newest_file)
  if date_of_newest_file > @latest_backup_allowed
    return 0
  elsif date_of_newest_file < @latest_backup_allowed
    return 1
  else
    puts "error"
  end
end

def count_by_status (status)
  users_and_result_grouped = @users_and_result.group_by{|k,v| v}
  users_and_result_grouped[status].size
end

def names_by_status (status)
   users_and_result_grouped = @users_and_result.group_by{|k,v| v}
   result = ""
   users_and_result_grouped[status].each do |key, value|
    result += key + " "
  end
  result
end

#Traverse both backup destinations and store users and dates
traverse(sftp_dir)
traverse(timemachine_dir)

#For all identified backup users, evaluate the file modified dates
backup_users.each do |user|
  if @users_and_dates.has_key?(user)
    @users_and_result[user] = evaluate(@users_and_dates[user])
  else
    @users_and_result[user] = 2
  end
end

#puts @users_and_result
backup_succesful_quota = count_by_status(0).to_f / @users_and_result.size.to_f

case backup_succesful_quota
when 0..0.25
  status=2
  statustxt="CRITICAL"
when 0.26..0.85
  status=1
  statustxt="WARN"
when 0.86..1.0
  status=0
  statustxt="OK"
end

puts "Team Backup is #{statustxt}
Total Users Checked: #{@users_and_result.size}
Active Backups found: #{count_by_status(0)}
Outdated Backups found: #{count_by_status(1)} #{names_by_status(1)}
Users not having backups: #{count_by_status(2)} #{names_by_status(2)}
Backups Successful Quota: #{backup_succesful_quota.round(2)}"

exit status