#!/usr/bin/perl6
use v6;
use DateTime::Math;
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

role DynamicRange { # Rethink the role's and method's name.
	method !SmartRange ($from, $to) { 
		if ($from <= $to) {
			return $from..$to;
		} else {
			return ($to..$from).reverse;
		}
	}
}

class Cron {...};
class Cron::Time {...}; # TODO Remove these lines. Im too tired to get my code back into working condition to check if these are needed, but they shouldn't be.
class Cron::Time::Unit {...}; # TODO delete this line
class Cron::Time::Word {...};
# NOTE This was made specificly for fcron. other implimentations. Next will be 
grammar Cron::Gram { # FIXME Most \h, \n, and \s 's should be replaced with a escap compatible token.
	token Unparse { # Short for Unparsable. NOTE This should only be used durring testing, Never published ## Probably should eat the rest of the Input..
		(\N+) {say "FAILED TO PARSE--<<$0>>"}
	}

	token TWord_Arr { # NOTE I am not satisfied with this name, So it will likely change
		[<TWord> ',']* <TWord>
	}
	token TWord { # NOTE TWord for TimeWord. Probably isn't the best name for this either.
		'*' | [\d+ '-' \d+] | \d+ 
	}
	token Min { <TWord_Arr> }
	token Hr { <TWord_Arr> }
	token Dow { <TWord_Arr> }
	token Dom { <TWord_Arr> }
	token Month { <TWord_Arr> }
	token Yr { <TWord_Arr> }
	
	token Word { # Should IsA#Comment? be a word? (Probably, as it is in bash)
		[  <Literal>
		|| <Quote>
		|| <-[#]> & \S]+
	}
	token Literal { # FIXME Escaped whitspaces should be ignored, not taken literaly. (May need to be implimented elsewear)
		\\ \N
	}
	token Quote { # FIXME? Match unclosed quotes to EOF?
		# FIXME Escaped Closure for <">. ie " \" " should work as expected ( '\' stays the same ). Try [ <Literal> || <-[\"]> ]*
		  \' <-[\']>* \'
		| \" <-[\"]>* \"
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
		#TODO [ <Comment> || [ <CronJob>||<CronVar> ] \h* \n? || <Unparse> ]+ #Needs to be tested first, Im tired so test with-held. Note .perl isn't working as expectd.
		[[  <Comment>
		|| <CronJob> <Comment>?
		|| <CronVar>
		|| <Unparse>
		] \h* \n? ]+
	}
}
class Cron::Actions {
	method Min($/) { make $<TWord_Arr>.made; }
	method Hr($/) { make $<TWord_Arr>.made; }
	method Dow($/) { make $<TWord_Arr>.made; }
	method Dom($/) { make $<TWord_Arr>.made; }
	method Month($/) { make $<TWord_Arr>.made; }
	method Yr($/) { make $<TWord_Arr>.made; }
	method TWord_Arr($/) {
		my @twords = (for ($<TWord>.list) { .made }) ;
		my $cta = Cron::Time::Unit.create( @twords ) ;
		make $cta;
	}
	method TWord($/) {
		make Cron::Time::Word.create( $/ );
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
		make	[$<Min>.made.Str,
			$<Hr>.made.Str,
			$<Dom>.made.Str,
			$<Dow>.made.Str,
			$<Month>.made.Str,
			#$<Yr>.made
		];
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

class Cron {
	has $.CronFile is rw = die "CronFile Is Required";
	has $!CronO = Cron::Gram.parse($!CronFile, :actions(Cron::Actions)); # The Parsed CronFile (Tree?)
	method Call() {
		#my $C = Cron::Gram.parse($Time);
		#$Time.say; 
		$!CronO = Cron::Gram.parse($.CronFile, :actions(Cron::Actions));	# $!CronO Defined here
	}
	method NextCmd() { # FIXME ... Impliment this
#		say '$!CronO';
#		say $!CronO;								# This works
#		say '$!CronO..perl';
#		say $!CronO.perl;							# This doesn't
	#	for $!CronO<CronJob> {
	#		say $_;
	#	}
	}
}
class Cron::Time {
	has @.TimeUnits;
	method gist () {
		return &.list;
	}
	method list () {
		return &.Tnum_List;
	}
	method Str () {
		return &.Tnum_Str.join(',');
	}
	method create (@TimeUnits) {
		for @TimeUnits -> $TimeUnit {
			die 'Error' unless ($TimeUnit ~~ Cron::Time::Unit);
		}
		return &.new(:@TimeUnits)
	}

}
class Cron::Time::Unit { # NOTE Im still not sure about the name 
	# An array of One unit of time. ie. 30 0,12 1-5 * 3-5,11-1. Your time units would be 
	# Min 30
	# Hr 0,12
	# Dow 1-5
	# Day(OfMonth) *
	# Month 3-5,11-12
	has @.TWords;
	method gist () {
		return &.list;
	}
	method list () {
		return &.TWord_List;
	}
	method Str () {
		return &.TWord_Str.join(',');
	}
	method TWord_Str () {
		my @retval;
		for @.TWords -> $Tnums {
			@retval.push($Tnums.Str);
		}
		return @retval;
	}
	method TWord_List () {
		my %retval;
		for @.TWords -> $Tnums {
			for $Tnums.list -> $Tnum {
				#@retval.push($Tnum) unless (@retval ~~ $Tnum);
				%retval{$Tnum}=1;
			}
		}
		return %retval.keys;
	}
	method create(@TWords) {
		for @TWords -> $Tnums { # I couldnt get Cron::Time @TnumsA or @TnumsA of Cron::Time to work. So I am checking individualy.
			die 'Cron::Time::Unit.create needs a Cron::Time::Word Array' unless ($Tnums ~~ Cron::Time::Word);
		}
		return &.new(:@TWords);
	}
}
class Cron::Time::Word does DynamicRange { # NOTE Im still not sure about the name. 
	# A single Unit of Time Specifier thing. Ie. in 1,10-12 Your Time::Words would be 1 and 10-12.
	has Int $.from is rw =  die q{'from' is a required var};
	has Int $.to is rw = $!from;
	has Str $.unit is rw;  
	method gist () { # NOTE gist to Str is probably better.
		return &.list;
		#return callsame();
	}
	method list () {
		return $.from unless ($.from != $.to);
		return self!SmartRange($.from, $.to);
	}
	method Str () {
		return $.from unless ($.from != $.to);
		return ($.from,'-',$.to).join;
	}
	multi method create (Str $Range ) { self!CreateRange($Range); }
	multi method create (Match $Range ) { self!CreateRange($Range); }
	multi method create (Int $from, Int $to=$from) {
		return &.new(:$from, :$to);
	}
	method !CreateRange ( $Range ) {
		given $Range {
			when (Int || /^\d+$/) {
				return &.new(:from($_.Int));
			}
			when ('*') { # TODO
			}
			when (Str || Match) {
				if (/^ (\d+) '-'  (\d+) $/) {
					return &.new(:from($0.Int), :to($1.Int));
				} else {
					die "!CreateRange failed to parse {$Range}"
				}
			}
			default {
				die "!CreateRange Called with Unsupported Type {$Range.WHAT}";
			}
		}
	}
}

#my $CronFile = qqx{fcrontab -l};
my $Cron = Cron.new(:CronFile($CronFile) );
$Cron.Call;
$Cron.NextCmd;

