#!/usr/bin/perl6
use v6;
use DateTime::Math;
use BC::Debug::Color;
$BC::Debug::Color::DebugLevel=0;
use Cron::Parser;

my $CronFile = q:to/HERECRON/;
# Comments are ignored, Including blank comments
#
# and even commented cronjobs
#&mail(no) 0 14 * * 2,4-5  export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Pick Justin up at 3:30'
#30 15 * * 2,4-5 export DISPLAY=:0 && bash "/home/beck/Scripts/Justin.sh" 'Pick Justin up at 3:30'
#
# Blank lines are also ignored

# Cron variables are Get caught by the Grammer rule for CronVars, both global
!bootrun(false)
# And job-local ones.
# Simple Cronjob
#10 4,6,7 9-12 2 2  export DISPLAY=:0 && amixer sset Master '50%'
58 4 25-31 8,10 2,4  echo 'example Command'
&mail(no) 58 4 25-31 8 2,4  export Complex && command
HERECRON

#$CronFile = qqx{fcrontab -l};
my $Cron = Cron::Parser.new(:CronFile($CronFile) );
$Cron.Call;

#my @Cmds=$Cron.NextCmd( :From(DateTime.now ), :Count(1) );
my @Cmds=$Cron.NextCmd( );
#my @Cmds=$Cron.NextCmd( :From(DateTime.now), :Count(2) );
#@Cmds[0][0][0] eq q<echo 'example Command'>;
#@Cmds[0][0][1] == ;
say @Cmds.map:{ [~] "\nCommand: ", $^a[0][0],  "\nTime: ", $^a[0][1] };
