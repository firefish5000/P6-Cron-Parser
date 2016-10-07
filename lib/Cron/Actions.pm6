#!/usr/bin/perl6
#unit module Cron::Actions;
#unit class Cron::Actions;
use v6;
use DateTime::Math;
use BC::Debug::Color;
#$BC::Debug::Color::DebugLevel=0;

################
# Actions for Cron::Grammar. Our main job is converting CronTime patterns and ranges to lists.
# Considered Date-WorkdayCaleder


class Cron::CheckTime {
	#= Checker(min,max,looprange): Creates an anonomouse subroutine that resolves ranges/patterns. Min and max are used to resolve ranges that include an asterisk, and should be the mininmum and maximum possible value for a given unit. looprange sets weather values are forced to be in range by use of the modules operator. This is usefull for the day_of_week timeunit since in many implementations, both 0 and 7 can refer to sunday.
	method Checker($min,$max,Bool :$looprange = False) {	
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			if ($looprange.Bool) {
				# FIXME Consider min=>15 max=>20. with from=>21 we get 1
				# Something like (but not exactly): ($from %(1+$max-$min)) + $min; 
				$from	= $from % ($max+1);
				$to		= $to % ($max+1);
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
	
#	for ['Month', 1, 12], ['Hr', 0, 23], ['Min', 0, 59], ['Dom', 1, 31], ['Dow', 0, 6, True], ['Yr', - Inf, Inf] -> [$unit, $min, $max, Bool $looprange = False ] {
#		Cron::CheckTime.HOW.add_method(Cron::CheckTime, $unit, anon method () {
#            return self.Checker($min, $max, :$looprange); 
#        });
#    }
	#= For(Wanted_Unit): Returns a Checker for the given unit.
	method For(Str $Wanted_Unit) {
		for ['Month', 1, 12], ['Hr', 0, 23], ['Min', 0, 59], ['Dom', 1, 31], ['Dow', 0, 6, True], ['Yr', - Inf, Inf] -> [$unit, $min, $max, Bool $looprange = False ] {
			next unless $unit eq $Wanted_Unit;
            return self.Checker($min, $max, :$looprange);
		}
    }
 }

#= DynamicRange: Adds a SmartRange method which automaticly resolves a units patterns and ranges and returns only the ones between the specified 'from' and 'to'.
role DynamicRange { # Rethink the role's and method's name.
	#= SmartRange(from,to,:unit) Resolves patterns and ranges to a list or sequence and returns only the numbers within the specified 'from' and 'to'.
	method !SmartRange ($from, $to, :$unit) { 
		$unit.(:$from, :$to);
	}
}

class Cron::Time {...}
class Cron::Time::Unit {...}
class Cron::Time::Unit::Range {...}
#= Actions for Cron::Grammar
class Cron::Actions {
	method CronJobVar($/) {
		make $/;
	}
	#TODO Loop This
#	for <Min Hr Dow Dom Month Yr> -> $Unit {
#		Cron::Actions.^add_method( $Unit, anon method ($/) {
#			my @twords = $<TimeWord>.list;
#			my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime."$Unit"()) ) ;
#			make $cta;
#		});
#	}
	method Hr($/) {
		my @twords = $<TimeWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.For("Hr")) ) ;
		make $cta;
	}
	method Dow($/) {
		my @twords = $<TimeWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.For("Dow")) ) ;
		make $cta;
	}
	method Dom($/) {
		my @twords = $<TimeWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.For("Dom")) ) ;
		make $cta;
	}
	method Month($/) {
		my @twords = $<TimeWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.For("Month")) ) ;
		make $cta;
	}
	method Yr($/) {
		my @twords = $<TimeWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.For("Yr")) ) ;
		make $cta;
	}
	method Min($/) {
		my @twords = $<TimeWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.For("Min")) ) ;
		make $cta;
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
# change <TimeWord> [ \, <TimeWord> ]* to Capturing (<.TimeWord>) [ \, (<.TimeWord>) ]*
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
