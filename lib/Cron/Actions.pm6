#!/usr/bin/perl6
use v6;
use DateTime::Math;
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
class Cron::CheckTime {
	method Checker($min,$max,Bool :$looprange = False) {	
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			if ($looprange.Bool) {
				# FIXME Consider min=>15 max=>20. with from=>21 we get 1
				# Something like (but not exactly): ($from %(1+$max-$min)) + $min; 
				$from	= $from % $max+1;
				$to		= $to % $max+1;
			}
			Err qq{from {$from} is not in unit's range} unless $from ~~ $min..$max;
			Err qq{to {$to} is not in unit's range} unless $to ~~ $min..$max;
			if ($from <= $to) {
				return $from..$to;
			} else {
				return $from..$max,$min..$to;
			}
		};
	}
	
	for ['Month', 1, 12], ['Hr', 0, 23], ['Min', 0, 59], ['Dom', 1, 31], ['Dow', 0, 6, True], ['Yr', - Inf, Inf] -> [$unit, $min, $max, Bool $looprange = False ] {
		Cron::CheckTime.HOW.add_method(Cron::CheckTime, $unit, anon method () {
            return self.Checker($min, $max, :$looprange); 
        });
    }
 }

role DynamicRange { # Rethink the role's and method's name.
	method !SmartRange ($from, $to, :$unit) { 
		$unit.(:$from, :$to);
	}
}

class Cron::Time {...}; # TODO Remove these lines. Im too tired to get my code back into working condition to check if these are needed, but they shouldn't be.
class Cron::Time::Unit {...}; # TODO delete this line
class Cron::Time::Unit::Range {...};
# NOTE This was made specificly for fcron. other implimentations. Next will be Cron
class Cron::Actions {
	method CronArg($/) {
		make $/;
	}
	#TODO Loop This
	for <Min Hr Dow Dom Month Yr> -> $Unit {
		Cron::Actions.^add_method( $Unit, anon method ($/) {
			my @twords = $<TWord>.list;
			my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime."$Unit"()) ) ;
			make $cta;
		});
	}
	method Cmd($/) {
		make $/.Str;
	}
	method Comment($/) {
		make $/;
		#say $/;
	}
	method CronTime($/) {
		make Cron::Time.create( [$<Min>.made,
			$<Hr>.made,
			$<Dom>.made,
			$<Month>.made,
			$<Dow>.made
			#$<Yr>.made
		]);
	}
	method CronJob($/) {
		make	[$<CronTime>.made.Str,
			$<Cmd>.made,
			#$<Yr>.made
		];
	}
	method TOP($/) {
		my @CronJobs = (for ($<CronJob>.list) { .made });
		make @CronJobs;
	}
}


class Cron::Time { # NOTE Rethink what Str and list should return. (is list reeucursive? should Str return 1 Str or a list of Str?)
# List crrently doesn't let you extract the Hr, Min,etc
	has @.TimeUnits;
	method gist () {
		return &.Str;
	}
	method list () {
		return &.TUnit_List;
	}
	method Str () {
		return &.TUnit_Str.join(' ');
	}
	method TUnit_Str {
		return (for @.TimeUnits {.Str});
	}
	method TUnit_List {
		my @ret;
		my $i=0;
		for @.TimeUnits {
			@ret[$i] = $_.list;
			$i++;
		};
		return @ret;
		return (for @.TimeUnits {.list});
	}
	method NextRun {
		my $dt = DateTime.now;

		Info $dt;
	}
	method create (@TimeUnits) {
		for @TimeUnits -> $TimeUnit {
			die 'Cron::Time must be passed a Cron::Time::Unit array Not ',$TimeUnit.^name unless ($TimeUnit ~~ Cron::Time::Unit);
		}
		return &.new(:@TimeUnits);
	}

}
# CONSID makeing Cron::Time::Unit handle CronTimeWord's job. 
# change <TWord> [ \, <TWord> ]* to Capturing (<.TWord>) [ \, (<.TWord>) ]*
class Cron::Time::Unit { # NOTE Im still not sure about the name 
	# An array of One unit of time. ie. 30 0,12 1-5 * 3-5,11-1. Your time units would be 
	# Min 30
	# Hr 0,12
	# Dow 1-5
	# Day(OfMonth) *
	# Month 3-5,11-12
	has @.TRange;
	has $.unit;
	method gist () {
		return &.Str;
	}
	method list () {
		return &.TRange_List;
	}
	method Str () {
		return &.TRange_Str.join(',');
	}
	method TRange_Str () {
		my @retval;
		for @.TRange -> $Tnums {
			@retval.push($Tnums.Str);
		}
		return @retval;
	}
	method TRange_List () {
		my %retval;
		for @.TRange -> $Tnums {
			for $Tnums.list -> $Tnum {
				#@retval.push($Tnum) unless (@retval ~~ $Tnum);
				%retval{$Tnum}=1;
			}
		}
		return %retval.keys;
	}
	method AddTime(*@TRange) {
		for @TRange -> $Tnums { # I couldnt get Cron::Time @TnumsA or @TnumsA of Cron::Time to work. So I am checking individualy.
			die 'Cron::Time::Unit.create needs a Cron::Time::Word Array' unless ($Tnums ~~ Cron::Time::Word);
		}
		@.TRange.push(|@TRange);
	}
	method create(@TStrs, :$unit) {
		my @TRange;
		for @TStrs -> $Tstr { # I couldnt get Cron::Time @TnumsA or @TnumsA of Cron::Time to work. So I am checking individualy.
			die 'Cron::Time::Unit.create needs a Str||Match Array' unless ($Tstr ~~ (Str||Match)); # Str, Match, or the like
			@TRange.push(Cron::Time::Unit::Range.create($Tstr, :$unit));
		}
		return &.new(:@TRange, :$unit);
	}
}
class Cron::Time::Unit::Range does DynamicRange { # NOTE Im still not sure about the name. 
	# A single Unit of Time Specifier thing. Ie. in 1,10-12 Your Time::Words would be 1 and 10-12.
	has $.orig is rw;
	#has $.orig is rw where (Str|Match|Int);
	has $.unit is rw = die q{'unit' is a required var}; 
	method gist () { 
		return &.Str;
	}
	method list () {
		Err "Attempt to return Timeword list before \$.unit is set." if $.unit.WHAT ~~ Str; 
		return self!CreateRange();
#		return $.from unless ($.from != $.to);
#		return self!SmartRange($.from, $.to, :unit(%legal{$.unit}));
	}
	method Str () {
		return $.orig;
	}
	multi method create (Str $Range, Sub :$unit! ) { &.new(orig => $Range, :$unit); }
	multi method create (Match $Range, Sub :$unit! ) { &.new(orig => $Range, :$unit); }
	method !CreateRange () {
		given $.orig {
			when (Int || /^\d+$/) {
				return $.unit.(from=>$.orig.Int);
#				die unless $.orig;
#				return $.orig ;
			}
			when ('*') {
				return $.unit.(from=>'*');
			}
			when (Str || Match) {
				if (/^ (\d+) '-'  (\d+) $/) {
					return self!SmartRange($0.Int, $1.Int, :$.unit );
				}
				die "!CreateRange failed to parse {$.orig}"
			}
		}
		die "!CreateRange Called with Unsupported Type {$.orig.WHAT}";
	}
}
