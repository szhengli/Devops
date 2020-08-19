#!/usr/bin/expect
set user [lindex $argv 0]
set userpass [lindex $argv 1]
spawn htpasswd -m /data/svn/passwd.http $user
expect "*password*"
send "$userpass\r"
expect "Re-type new password:"
send "$userpass\r"
expect eof
