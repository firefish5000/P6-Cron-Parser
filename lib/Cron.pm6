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


sub TimeRangeFilter (:%Cur, :$Unit, :$From!, :@List!, :$Till) {
	my %Limit;
	for ['Mons', 1, 12], ['Hrs', 0, 23], ['Mins', 0, 59], ['DOMs', 1, sub (%ccur) { return DateTime.new( |{year=>$From.year,month=>12,day=>1}, |%ccur, |{day=>1} ).days-in-month; }], ['Yrs', $From.year, $Till.year] -> [$unit, $min, $max] {
		%Limit{$unit}<min>=$min;
		%Limit{$unit}<max>=$max;
	}
	my %Units =  <Yrs Mons DOMs Hrs Mins> Z=> <year month day hour minute>;
	# When calculating Moths, day's max needs to be dynamic
	my $MaxDate = sub (%ccur) { 
		return %((
				%Limit.map:{ %Units{$^a.key} => $^a.value<max> unless $^a.key ~~ any(<DOWs DOMs>)}
			),
			day=> %Limit<DOMs><max>(%ccur),
			%ccur
		);
	};
	my %MinDate = (%Limit.map:{ %Units{$^a.key} => $^a.value<min> unless $^a.key ~~ any(<DOWs>)}), %Cur;
	return (for (@List) -> $a { 
		next if ($Unit ~~ 'DOMs' && $a > %Limit<DOMs><max>(%Cur));
		$a if (
			DateTime.new( |$MaxDate({%Cur, %Units{$Unit} => $a}  ) ) >= $From 
			&& DateTime.new( |%MinDate, |{%Units{$Unit} => $a}) <= $Till
		) 
	});
}
# NOTE 365*400+100; 400yrs, all posible DOW/DOM/Mon combinations. If the compution speed increases so such is reasonable...
# TODO Allow multiple jobs NextRuns to be calculated at the same time. this way NextCmd wont have to iterate through all before knowing anything.
sub TimeFind ( :$Unit="Yrs", :$Predictions = 1, :$From = DateTime.now, :$Till = DateTime.now+to-seconds(365, 'd'), :%Cur, :@Yrs = [$From.year..$Till.year], :@Mons!, :@DOMs!, :@DOWs!, :@Hrs!, :@Mins! ) { 
	my @NextRuns;
	my %HTime = ( :@Yrs, :@Mons, :@DOMs, :@DOWs, :@Hrs, :@Mins);
	my %NextUnit = <Yrs Mons DOMs Hrs> Z=> <Mons DOMs Hrs Mins>;
	my %Units =  <Yrs Mons DOMs Hrs Mins> Z=> <year month day hour minute>;
	for ( TimeRangeFilter(:%Cur, :$Unit, :List(%HTime{$Unit}.list), :$From, :$Till) ) -> $unitvalue {						# Nearest Dom
		next if ( $Unit ~~ q{DOMs} && Date.new(|%Cur, day=>$unitvalue).day-of-week !~~ any(@DOWs));	# Next unless day is of DOW
		@NextRuns.push(DateTime.new(|%Cur, minute=>$unitvalue)) if $Unit ~~ 'Mins';
		@NextRuns.push(TimeFind(:Unit(%NextUnit{$Unit}), :Predictions($Predictions - @NextRuns.elems), :$From, :$Till, :Cur({%Cur, %Units{$Unit}=>$unitvalue}), |%HTime )) unless $Unit ~~ 'Mins';
		return @NextRuns if (@NextRuns.elems >= $Predictions);
	} # END Year
	Dbg 1, "NOT ENOUGH RUNS IN RANGE:  " if $Unit ~~ 'Yrs';
	Dbg 2, "Returning from a {$Unit} accumilating  {@NextRuns.elems} of {@NextRuns.elems+$Predictions} Runs";
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
		#my @NextRuns=TNext(:Start($From), :Predictions($Count), :$Mins, :$Hrs, :$DOMs, :$Mons, :$DOWs);
		my @NextRuns=TimeFind(:$From, :Predictions($Count), :$Mins, :$Hrs, :$DOMs, :$Mons, :$DOWs);
		return @NextRuns;
	}
	# The method used here is less than ideal. We should build all of their time tiables at the same time, stopping as soon as Count is reached.
	# If patched, it needs to be done in TNext, which also could use a renaming.
	method NextCmd( DateTime :$From = DateTime.now, Int :$Count=1) { 
		my @Cmds;
		for $!CronO<CronJob>.list -> $Ctime {
			for $Ctime<CronTime>.made.list -> $atime {
				my @nRuns=$.NextRun(:Job($atime), :$From, :$Count).list;
				@Cmds.push( @nRuns.for:{ [$Ctime<Cmd>.made, $^a] }) if @nRuns.elems >= 1;
			}
		}
		#Dbg 1, q{Next Command is: },join(" -- ",  (@Cmds.sort:{ $^a[1] <=> $^b[1] })[0..$Count - 1]); #[0..$Count - 1]);
		return (@Cmds.sort:{ $^a[1] <=> $^b[1] })[0..$Count - 1];
	}
}
