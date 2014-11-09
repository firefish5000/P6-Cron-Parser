#!/usr/bin/perl6
use v6;
use DateTime::Math;
use BC::Debug::Color;
$BC::Debug::Color::DebugLevel=1;
use CronParser;

my $CronFile = q:to/HERECRON/;
# &  -  classic cron syntax
# @  -  frequency or timespan (every 30 minutes; with options: best moment within every 30 minutes)
# %  -  (once) within time interval
# bootrun(1|0),b(1|0)  -  Runs cammand at boot if missed
# classic cron syntax:
#
# * * * * * user 'command to be executed'
# - - - - - -
# | | | | | +- - - user to run as (optional) # `echo hello'(without quotations) may try to run `hello' as user `echo'
# | | | | +- - - - day of week (0 - 6) (Sunday=0)
# | | | +- - - - - month (1 - 12)
# | | +- - - - - - day of month (1 - 31)
# | +- - - - - - - hour (0 - 23)
# +- - - - - - - - minute (0 - 59)
###Eg.################################################
## Syncronize portage tree every other day at 03:27 am
## 27 3 */2 * * 'emerge --sync'
!bootrun(false)

# Check If Our External Ip Address Changed Every day
#&mail(no) 29 1 * * * bash /home/beck/BCust/Specific.Anime/Networking/DLink_DSL-2540B/CheckIP.bash -e 'firefish5000@gmail.com firefish6000@gmail.com'

# Get Justin at 3:00
#&mail(no) 0 14 * * 2,4-5  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Pick Justin up at 3:30'
#&mail(no) 30 15 * * 2,4-5 export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Pick Justin up at 3:30'
# Take Them To School
#&mail(no) 0 7,8 * * 1-5  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Take The kids to school at 8:45'
# Go To School at 2:35 for Math
#&mail(no) 00,30 13 * * 1,3 export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Go to your math class at 2:35 (14:35)'
#&mail(no) 00 14 * * 1,3 export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Go to your math class at 2:35 (14:35)'
# Get Up
#&mail(no) 00 14 * * 0,2,4-6  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Wake Up From 12:00 Nap (2:00)'
#&mail(no) 00 10 * * 0-6  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Asa Dai Yo (6:00)'
&mail(no) 58 4 25-31 8 2,4  export DISPLAY=:0 && amixer sset Master '50%'
&mail(no) 58 4 * 9-12 2,4  export DISPLAY=:0 && amixer sset Master '50%'
&mail(no) 00 5 25-31 8 2,4  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'School At 6:00  (Leave by 5:45) (5:00)'
&mail(no) 00 5 * 9-12 2,4  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'School At 6:00  (Leave by 5:45) (5:00)'
HERECRON

#my $CronFile = qqx{fcrontab -l};
my $Cron = CronParser::Cron.new(:CronFile($CronFile) );
$Cron.Call;
$Cron.NextCmd;
$Cron.Test;
# vim: syntax=off
