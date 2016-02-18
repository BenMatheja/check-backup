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

#Function to Traverse directories and storing newest file date to hash
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

#Traverse both backup destinations and store users and dates
traverse(sftp_dir)
traverse(timemachine_dir)

#puts @users_and_dates

backup_users.each do |user|
  if @users_and_dates.has_key?(user)
    @users_and_result[user] = evaluate(@users_and_dates[user])
  else
    @users_and_result[user] = 2
  end
end

puts @users_and_result



#files = `find -type f`.split("\n")
#puts files
# infotxt="\nTotal Users Checked: $total_users_checked 
# Active Backups found: $total_active_backup_counter
# Outdated Backups found: $(cat tm_old_backup_users sf_old_backup_users | tr "\n" " ")
# Users not having backups: $(cat tm_not_having_backup_users sf_not_having_backup_users | tr "\n" " ")
# Backups Successful Quota: $total_backup_succesful_quota "
# #echo -e "$infotxt" >> check_backupstate.log

# #Reporting for Icinga
# if [ $(echo "$total_backup_succesful_quota < $threshold_warn" | bc -l) -eq 1 ] && [ $(echo "$total_backup_succesful_quota > $threshold_crit" | bc -l) -eq 1 ]; then
#   status=1
#   statustxt=WARN
# elif [ $(echo "$total_backup_succesful_quota < $threshold_warn" | bc -l) -eq 1 ] && [ $(echo "$total_backup_succesful_quota < $threshold_crit" | bc -l) -eq 1 ]; then
#   status=2
#   statustxt=CRITICAL
# else
#   status=0
#   statustxt=OK
# fi
# echo -e "Team Backup is $statustxt $infotxt"

# #Cleanup
# rm tm_users_checked tm_active_backup_counter tm_old_backup_counter tm_not_having_counter sf_users_checked sf_active_backup_counter sf_old_backup_counter sf_not_having_counter passwd_out total_backup_succesful_quota  total_active_backup_counter total_not_having_counter total_old_backup_counter total_users_checked tm_old_backup_users tm_not_having_backup_users tm_having_multiple_users sf_old_backup_users sf_not_having_backup_users sf_having_multiple_users
# exit $status

