#!/usr/bin/perl6
module CronParser;
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
	method Mon {
		my $min=1;
		my $max=12;
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			Err qq{from {$from} is not in unit's range} unless $from ~~ $min..$max;
			Err qq{to {$to} is not in unit's range} unless $to ~~ $min..$max;
			if ($from <= $to) {
				return $from..$to;
			} else {
				return $from..$max,$min..$to;
			}
		};
	}
	method Hr {
		my $min=1;
		my $max=23;
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			Err qq{from {$from} is not in unit's range} unless $from ~~ $min..$max;
			Err qq{to {$to} is not in unit's range} unless $to ~~ $min..$max;
			if ($from <= $to) {
				return $from..$to;
			} else {
				return $from..$max,$min..$to;
			}
		};
	}
	method Min {
		my $min=0;
		my $max=59;
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			Err qq{from {$from} is not in unit's range} unless $from ~~ $min..$max;
			Err qq{to {$to} is not in unit's range} unless $to ~~ $min..$max;
			if ($from <= $to) {
				return $from..$to;
			} else {
				return $from..$max,$min..$to;
			}
		};
	}
	method Dom {
		my $min=1;
		my $max=31;
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			Err qq{from {$from} is not in unit's range} unless $from ~~ $min..$max;
			Err qq{to {$to} is not in unit's range} unless $to ~~ $min..$max;
			if ($from <= $to) {
				return $from..$to;
			} else {
				return $from..$max,$min..$to;
			}
		};
	}
	method Yr {
		my $min=-Inf;
		my $max=Inf;
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			Err qq{from {$from} is not in unit's range} unless $from ~~ $min..$max;
			Err qq{to {$to} is not in unit's range} unless $to ~~ $min..$max;
			if ($from <= $to) {
				return $from..$to;
			} else {
				return $from..$max,$min..$to;
			}
		};
	}
	method Dow {
		my $min=0;
		my $max=6;
		return sub ( :$from is copy,  :$to is copy =$from) {
			$from=$min if ($from ~~ '*');
			$to=$max if ($to ~~ '*');
			$from=$max if ($from ~~ 7);
			$to=$max if ($to ~~ 7);
			Err qq{from {$from} is not in unit's range} unless $from ~~ $min..$max;
			Err qq{to {$to} is not in unit's range} unless $to ~~ $min..$max;
			if ($from <= $to) {
				return $from..$to;
			} else {
				return $from..$max,$min..$to;
			}
		}
	}
 }
#class Dow does Int {
#	has Int where(0..7); # Sunday is 0&7
#}
#my enum Dow <Sun Mon Tue Wed Thu Fri Sat Sun>; # Sunday is 0&7

role DynamicRange { # Rethink the role's and method's name.
	method !SmartRange ($from, $to, :$unit) { 
		$unit.(:$from, :$to);
	}
}

class Cron {...};
class Cron::Time {...}; # TODO Remove these lines. Im too tired to get my code back into working condition to check if these are needed, but they shouldn't be.
class Cron::Time::Unit {...}; # TODO delete this line
class Cron::Time::Unit::Range {...};
# NOTE This was made specificly for fcron. other implimentations. Next will be Cron
grammar Cron::Gram { # FIXME Most \h, \n, and \s 's should be replaced with a escap compatible token.
	token Unparse { # Short for Unparsable. NOTE This should only be used durring testing, Never published ## Probably should eat the rest of the Input..
		(\N+) .* {Err "FAILED TO PARSE--<<$0>>"}
	}

#	token TWord_Arr { # NOTE I am not satisfied with this name, So it will likely change
#		[<TWord> ',']* <TWord>
#	}
	token TWord { # NOTE TWord for TimeWord. Probably isn't the best name for this either.
		'*' | [\d+ '-' \d+] | \d+ 
	}
	token Min { [<TWord> ',']* <TWord> }
	token Hr { [<TWord> ',']* <TWord> }
	token Dow { [<TWord> ',']* <TWord> }
	token Dom { [<TWord> ',']* <TWord> }
	token Month { [<TWord> ',']* <TWord> }
	token Yr { [<TWord> ',']* <TWord> }
	
	token Word { # Should IsA#Comment? be a word? (Probably, as it is in bash)
		[  <Literal>
		|| <Quote>
		|| <-[#]> & \S]+
	}
	token Literal { # FIXME Escaped whitspaces(including newlines) should be ignored, not taken literaly. (May need to be implimented elsewear).
		\\ \N
	}
	token Quote { # FIXME? Match unclosed quotes to EOF?
		# FIXME Escaped Closure for <">. ie " \" " should work as expected ( '\' stays the same ). Try [ <Literal> || <-[\"]> ]*
		  \' <-[\']>* \'
		| \"   [<Literal> || <-[\"]>]*   \" 
	}

	token CronVar { # FIXME % is not a var, but a Non-clasic CronJob format. CronVar should probably handle things like mail(no) after \&. 
		( <[ \! \% ]> <Word>)
	}
	token CronArg { # I dont think \& should be  part of the CronArg. (What is CronArg Anyway) What succeeds \& should be a CronVar or the like. 
		(  \&  <Word>?) 
	}
	token CronTime {
		 <Min> \h+ <Hr> \h+  <Dom> \h+ <Month> \h+ <Dow> 
	}
	token CronJob {
		 <CronArg> \h+ <CronTime> \h+  <Cmd> 
	}
	
	# TODO token User { ... }
	token Cmd {
		<Word> [\h+<Word>]+
	}
	token Comment { 
		'#' (\N*)
	}
		
	
	rule TOP {
		[ <Comment> 
		|| [ <CronJob>||<CronVar> ] \h* \n? 
		|| <Unparse> ]+
	#	[[  <Comment>
	##	|| <CronJob> <Comment>?
	#	|| <CronVar>
	#	|| <Unparse>
	#	] \h* \n? ]+
	}
}
class Cron::Actions {
	method Min($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.Min()) ) ;
		#my $cta = Cron::Time::Unit.create( @twords, :unit(Min) ) ;
		make $cta;
	}
	method Hr($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.Hr()) ) ;
		make $cta;
	}
	method Dow($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.Dow()) ) ;
		make $cta;
	}
	method Dom($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.Dom()) ) ;
		make $cta;
	}
	method Month($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.Mon()) ) ;
		make $cta;
	}
	method Yr($/) {
		my @twords = $<TWord>.list;
		my $cta = Cron::Time::Unit.create( @twords, :unit(Cron::CheckTime.Yr()) ) ;
		make $cta;
	}
#	method TWord_Arr($/) {
#		my @twords = (for ($<TWord>.list) { .made }) ;
#		my $cta = Cron::Time::Unit.create( @twords, :unit<Unk> ) ;
#		make $cta;
#	}
	method TWord($/) {
#		make Cron::Time::Unit::Range.create( $/ );
	}
	method CronArg($/) {
		make $/;
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

sub TSort(@List, :$Start!) {
	return @List.map: { $_ if ($_ >= $Start) };
}

# FIXME e need to use the unfiltered dates for children when the parren's first filtered date is greaterthat the starting date.
#sub TNext (@Years, @Months, @DOM, @DOW, @Hours, @Mins, $Start = now) { 
sub TNext ( :@Mons!, :@DOMs!, :@DOWs!, :@Hrs!, :@Mins!, :$Predictions = 1, :$Start = DateTime.now, :@Yrs = $Start.year.map:{ $_,$_+1} ) { 
	my $UnFilt=0; # stop filtering 1=min 2=hr, 3=dom; 4=month
	my @NextRuns;
	say  qq{NEXT OF 
	Yr {@Yrs.perl}
	Mon {@Mons.perl}
	Dom {@DOMs.perl}
	Dow {@DOWs.perl}
	Hr {@Hrs.perl}
	Min {@Mins.perl}};
	# NOTE This looks like magic code. Its realy just 2 simple lines, that are repeated for Yr, Month, etc. 
	# TODO In fact, We can probably warp them in a foreach and reduce it to 5-6 lines.
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
						#say "$yr - $mon - $dom WITH {Date.new(:year($yr), :month($mon)).days-in-month}";
						@NextRuns.push(DateTime.new(:year($yr), :hour($hr), :minute($min), :day($dom), :month($mon)) );
						return @NextRuns if (@NextRuns.elems >= $Predictions);
					}
				}
			}
		}
	} # END Year
	say "FAILED TO GET TIME:  ";
}

class Cron {
	has $.CronFile is rw = die "CronFile Is Required";
	has $!CronO = Cron::Gram.parse($!CronFile, :actions(Cron::Actions)); # The Parsed CronFile (Tree?)
	method Call() {
		#my $C = Cron::Gram.parse($Time);
		#$Time.say; 
		$!CronO = Cron::Gram.parse($.CronFile, :actions(Cron::Actions));	# $!CronO Defined here
	}
	method NextRun( :$Job, DateTime :$From = DateTime.now, Int :$Count=1) { 
		my ($Mins,$Hrs,$DOMs,$Mons,$DOWs)=$Job.for:{ [.for:{.Int}] };
		my @NextRuns=TNext(:Start($From), :Predictions($Count), :$Mins, :$Hrs, :$DOMs, :$Mons, :$DOWs);
		Msg q{NEXT COMMAND IS AT: }, @NextRuns;
		return @NextRuns;
	}
	method NextCmd( DateTime :$From = DateTime.now, Int :$Count=1) { 
#		say q{FIRST IS }, (
		my @Cmds;
		for $!CronO<CronJob>.list -> $Ctime {
			for $Ctime<CronTime>.made.list -> $atime {
				say $Ctime<Cmd>.made;
				@Cmds.push($.NextRun(:Job($atime), :$From, :$Count));
			}
		}
		Info q{FIRST IS: },join(" -- ",  @Cmds.sort[0..$Count - 1]);
	}
	method Test() {
		$!CronO<CronJob>.list[0]<CronTime>.made.NextRun;
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
		my $dt = DateTime.new(now);

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
