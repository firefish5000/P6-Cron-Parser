# Term::ColorText --- As it says. Temporary only though.
unit module BC::Debug::Color;
#module BC::Debug::Color;
use v6;
use Terminal::ANSIColor;


# DEFAULTS
our $DebugLevel=0;
our %Format = (
	Msg		=> 'yellow',
	Info	=> 'green',
	Dbg		=> 'magenta',
	Wrn		=> 'yellow',
	Err		=> 'red',
	
	Path	=> 'magenta',
		Dir	=> 'magenta',
		File	=> 'red',
	URL		=> 'blue',
	Quote	=> 'yellow',
	Dig	=> 'green',
	Ticket		=> 'green',
);

# API
our sub Fjoin($sep,*@arr) is export {
	return @arr unless @arr.elems >= 2;
	return |(@arr[0..*-2] X, $sep).flat, @arr[*-1];
}
our sub Color($color, *@things) is export {
	my $i=0; for @things {$i++ if .defined};
	return unless $i > 0;
    my @ar = color($color) X~ @things;
    @ar[*-1] ~= color("reset");
    return  @ar;
}

# Builder
#`{{
sub Add_Auto (Str $Name, Routine $Call) {
	EXPORT::ALL::{$Name} := EXPORT::DEFAULT::{$Name} := OUR::{$Name} := anon sub (*@things) {
		Color( %Format{$Type}, @things);
	}
}
sub Add_Formater (Str $Name, Routine $Call) {
	EXPORT::ALL::{$Name} := EXPORT::DEFAULT::{$Name} := OUR::{$Name} := anon sub (*@things) {
		Color( %Format{$Type}, @things);
	}
}
sub Add_Caller (Str $Name, Routine $Call) {
	EXPORT::ALL::{$Name} := EXPORT::DEFAULT::{$Name} := OUR::{$Name} := anon sub (*@things) {
		Color( %Format{$Type}, @things);
	}
}
#}}
#BEGIN { 
	our sub Say(*@things) {
	    $*ERR.say([~] @things);
	}
	our sub Fail(*@things) {
		fail([~] @things);
	}
	our sub Die(*@things) {
	    die([~] @things);
	}
	our sub Note(*@things) {
	    note([~] @things);
	}
	our sub Warn(*@things) {
	    note([~] @things);
	}	

	for <Err Dbg Msg Info Wrn Path File URL Quote Dir Dig Bug Ticket> -> $Type {
		my $Name="\&C{$Type}";
		EXPORT::ALL::{$Name} := EXPORT::DEFAULT::{$Name} := OUR::{$Name} := anon sub (*@things) {
			Color( %Format{$Type}, @things);
		}
#		MY::{"&{$CName}"} := OUR::{"&{$CName}"};
	}
	for <Msg Info Wrn Path File URL Quote> -> $Type {
		my $Name="\&{$Type}";
		my $CName = "\&C{$Type}";
		EXPORT::ALL::{$Name} := EXPORT::DEFAULT::{$Name} := OUR::{$Name} := anon sub (*@things) {
			Say( OUR::{$CName}(@things)  );
		}
		#trait_mod:<is>(:export, $x);
		#trait_mod:<is>(:export, OUR::{"&{$Type}"});
	}
	for <Msg Info Wrn Path File URL Quote> -> $Type {
		my $Name="\&S{$Type}";
		my $CName = "\&C{$Type}";
		EXPORT::ALL::{$Name} := EXPORT::DEFAULT::{$Name} := OUR::{$Name} := anon sub (*@things) {
			Say( OUR::{$CName}(CAuto(@things) )  );
		}
	}
	our sub Dbg($level, *@things) is export { Say( &OUR::CDbg(@things)) if $level <= $DebugLevel;}
	our sub Err(*@things) is export { Die(&OUR::CErr(@things));}
	our sub SDbg(*@things) is export { Say(&OUR::CDbg(CAuto @things));}
	our sub SErr(*@things) is export { Say(&OUR::CErr(CAuto @things));}
#}


#END say EXPORT::ALL::;
#END say EXPORT::DEFAULT::;

grammar Auto::Grammar {
	token special {
		<[
			\~ \! \@ \# \$ \% \^ \& \* \( \) \_ \+ \{ \} \: \" \< \> \? \|
			\` \- \= \[ \] \; \' \, \. \\
		]>  | ' '
	}
	token Path {
		^ ['/'|'./'|'../']  [ [ <[a..zA..Z0..9]>|<.special> ]+ '/'* ]+ $
		# || [ [<[a..zA..Z0..9]>|<.special>]+ '/'* ]+
	}
	token URL {
		^ ['http's?|'ftp's?|'file'] '://'   [ '/'* [ <[a..zA..Z0..9]>|<.special> ]+ '/'* ]+ $
		|| ^ ['www.']  [[ <[a..zA..Z0..9]>|<.special> ]+! '.' ]   [ [ <[a..zA..Z0..9]>|<.special> ]+ '/'* ]+ $
		# || [ [<[a..zA..Z0..9]>|<.special>]+ '/'* ]+
	}
	token Ticket {
		^ ['#' | 'RC' | 'RC'\h*'#'] \h* \d+ $ 
	}
	token Quote {
		^  '"'  <[^\"]>* '"' $ 
		|| ^  "'"  <-[\']>* "'" $ 
	}
	token TOP {
		<Quote>
		|| <Ticket>
		|| <URL>
		|| <Path> && {$<Path>.IO ~~ :e}
	}
}
sub CAuto(*@things) is export {
	my @Ret;

	for @things -> $thing {
		given $thing {
			when .IO ~~ :e {
				when .IO ~~ :d {
					#DIR
					@Ret.push(&OUR::CDir($thing));
				}
				when .IO ~~ :f {
					#FILE
					@Ret.push(&OUR::CFile($thing));
				}
				default {
					@Ret.push(&OUR::CPath($thing));
					#OTHER
				}

			}
			when Auto::Grammar.parse($_, :rule<Ticket> ).Bool == True {
				#RC Ticket
				@Ret.push(&OUR::CBug($thing));
			}
			when m{^ \d+ $} {
				#DIGIT
				@Ret.push(&OUR::CDig($thing));
			}
			when Auto::Grammar.parse($thing, :rule<Quote>).Bool == True {
				# Pathlike Test.
				@Ret.push(&OUR::CQuote($thing));
			}
			when Auto::Grammar.parse($_, :rule<URL>).Bool == True {
				#URLlike Test
				@Ret.push(&OUR::CURL($thing));
			}
			when Auto::Grammar.parse($thing, :rule<Path>).Bool == True {
				# Pathlike Test.
				@Ret.push(&OUR::CPath($thing));
			}
			default {
				# Advanced parcing
				# and Fallback say.
				@Ret.push($thing);
			}
		}
	}
	return(@Ret);
}

