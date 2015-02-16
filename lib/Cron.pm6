#!/usr/bin/perl6
class Cron {
use v6;
use DateTime::Math;
use Cron::Grammar;
use Cron::Actions;
use BC::Debug::Color;
$BC::Debug::Color::DebugLevel=1;
################
# Project Goal #
# To automaticly create rtcwake events for every Cron Job.
#######################
# Implimantation Goal #
# Create an RTC wake event for the next CronJob occuring in 10min+
# By default, Set RTC wake event for 5min prior to CronJob execution time.
# On Wake, Imediantly create the RTCwake event for the next job that meats the criteria.
# Check Every 5min to see if cronfile has changed and update events(create a hook to notify us if possible)
# Allow the user to specify weather to create RTC wake events, both by default, and on individual jobs.
# Check to see if cron has a &wake(1) or similar command once done. (put your hard work to waste)
###############
# SubProjects #
# CronParser, a potentialy usefull Cron:: Grammar && Actions implimentation;
#########
# State #
# Unusable, no support garenty. Future versions will break this and no there will be no backwards compatibility until API version 0.0.1
# The API uses the following naming convention. <Complete Rewrite>.<Incompatible Changes>.<Compatible Changes> [Some testing/development tag/number]?
# For now our API and version is 0.0.0 and our code is broken.
# Other Thoughts:
# I need spell checking for vim or a some other good editor for perl6. (padre was crashing)
# Vim's syntax highlighting is AWFULY SLOW for perl6.

# Considered Date-WorkdayCaleder

sub TSort(@List, :$Start!) {
	return @List.map: { $_ if ($_ >= $Start) };
}

sub TNext ( :@Mons!, :@DOMs!, :@DOWs!, :@Hrs!, :@Mins!, :$Predictions = 1, :$Start = DateTime.now, :@Yrs = $Start.year.map:{ $_,$_+1} ) { 
	my $UnFilt=0; # stop filtering 1=min 2=hr, 3=dom; 4=month
	my @NextRuns;
	# NOTE This looks like magic code. Its realy just 2 simple lines, that are repeated for Yr, Month, etc. 
	# TODO In fact, We can probably warp them in a loop/recursive call and reduce it to >10 lines.
#	for (@Yrs, $Start.year; @Mons, $Start.month; @DOMs, $Start.day; @DOWs; @Hrs, $Start.hour; @Mins, $Start.minute ) -> (@list, $start) {
#		for ( @list !! TSort(:Start($start), @list) ) -> $dom {						# Nearest Dom
#	}
	for ( TSort(:Start($Start.year), @Yrs) ) -> $yr { # Nearest year. Needed for keeping up with leap days.!! Do not give Year and Infi range!
		$UnFilt = 5 if ($UnFilt < 5 && $Start.year != $yr);
		for ( ($UnFilt >= 4) ?? @Mons !! TSort(:Start($Start.month), @Mons) ) ->  $mon {					# Nearest Month
			$UnFilt = 4 if ($UnFilt < 4 && $Start.month != $mon);
			for ( $UnFilt >= 3 ?? @DOMs !! TSort(:Start($Start.day), @DOMs) ) -> $dom {						# Nearest Dom
				$UnFilt = 3 if ($UnFilt < 3 && $Start.day != $dom);
				next if ( $dom > Date.new(:year($yr), :month($mon)).days-in-month);							# Next unless Day is in month
				next unless ( Date.new(:year($yr), :month($mon), :day($dom)).day-of-week ~~ any(@DOWs));	# Next unless day is of DOW
				for ( $UnFilt >= 2 ?? @Hrs !! TSort(:Start($Start.hour), @Hrs) ) -> $hr  {					# Nearest hr 
					# TODO How do we handle dailight savings, if at all.
					$UnFilt = 2 if ($UnFilt < 2 && $Start.hour != $hr);
					for ( $UnFilt >= 1 ?? @Mins !! TSort(:Start($Start.minute), @Mins ) ) -> $min  {		# Nearest Min. Next Run FOUND!!
						$UnFilt = 1 if ($UnFilt < 1);
						@NextRuns.push(DateTime.new(:year($yr), :hour($hr), :minute($min), :day($dom), :month($mon)) );
						return @NextRuns if (@NextRuns.elems >= $Predictions);
					}
				}
			}
		}
	} # END Year
	Dbg 1, "NOT ENOUGH RUNS IN RANGE:  ";
	return @NextRuns but False;
}

#class Cron {
	has $.CronFile is rw = die "CronFile Is Required";
	has $!CronO = Cron::Grammar.parse($!CronFile, :actions(Cron::Actions)); # The Parsed CronFile (Tree?)
	method Call() {
		#my $C = Cron::Gram.parse($Time);
		#$Time.say; 
		$!CronO = Cron::Grammar.parse($.CronFile, :actions(Cron::Actions));	# $!CronO Defined here
	}
	method NextRun( :$Job, DateTime :$From = DateTime.now, Int :$Count=1) { 
		my ($Mins,$Hrs,$DOMs,$Mons,$DOWs)=$Job.for:{ [.for:{.Int}] };
		my @NextRuns=TNext(:Start($From), :Predictions($Count), :$Mins, :$Hrs, :$DOMs, :$Mons, :$DOWs);
		return @NextRuns;
	}
	# The method used here is less than ideal. We should build all of their time tiables at the same time, stopping as soon as Count is reached.
	# If patched, it needs to be done in TNext, which also could use a renaming.
	method NextCmd( DateTime :$From = DateTime.now, Int :$Count=1) { 
		my @Cmds;
		for $!CronO<CronJob>.list -> $Ctime {
			for $Ctime<CronTime>.made.list -> $atime {
				my @nRuns=$.NextRun(:Job($atime), :$From, :$Count).list;
				#say qq{Will Push: \n},  (@nRuns.for:{ [$Ctime<Cmd>.made, $^a] })  X "\n" if @nRuns.elems >= 1;
				@Cmds.push( @nRuns.for:{ [$Ctime<Cmd>.made, $^a] }) if @nRuns.elems >= 1;
			}
		}
		#Dbg 1, q{Next Command is: },join(" -- ",  (@Cmds.sort:{ $^a[1] <=> $^b[1] })[0..$Count - 1]); #[0..$Count - 1]);
		say ((@Cmds.sort:{ $^a[1] <=> $^b[1] })[0..$Count - 1]).for:{  [~] "\nCommand: ", $^a[0], "\nTime: ", $^a[1] };
		return (@Cmds.sort:{ $^a[1] <=> $^b[1] })[0..$Count - 1];
	}
}
