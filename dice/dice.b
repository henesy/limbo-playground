implement Dice;

include "sys.m";
include "draw.m";
include "arg.m";
include "keyring.m";	# required by security.m
include "security.m";
include "bufio.m";

sys: Sys;
arg: Arg;

Dice: module {
	init: fn(nil: ref Draw->Context, argv: list of string);
};

Die: adt {
	n: int;	# number of die
	m: int;	# max value [1-m]
};

exploding: int = 0;
toroll: list of Die;
ndice: int = 0;
schan: chan of string;

# A dice roller, pass in args in format XdY and enjoy the rolls
init(nil: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;
	arg = load Arg Arg->PATH;
	schan = chan of string;

	arg->init(argv);
	arg->setusage("dice [-e] XdY... (default: 1d6)");

	while((f := arg->opt()) != 0)
		case f {
		'e' =>
			exploding = 1;
		* =>
			arg->usage();
		}
	argv = arg->argv();

	# Process args list
	case len argv {
	0 =>
		toroll = Die(1, 6) :: toroll;
	* =>
		for(; argv != nil; argv = tl argv) {
			(c, fields) := sys->tokenize(hd argv, "d");
			if(c != 2)
				raise "bad number of d's ­ " + hd argv;

			if(int hd fields < 1 || int hd tl fields < 1)
				raise "values must be ≥1";

			if(int hd tl fields == 1 && exploding)
				raise "exploding d1 is ∞";

			toroll = Die(int hd fields, int hd tl fields) :: toroll;
		}
	}
	
	# Kick off rolling threads
	for(; toroll != nil; toroll = tl toroll) {
		spawn roll(hd toroll);
		ndice++;
	}

	# Print all of the roll results
	bufio := load Bufio Bufio->PATH;
	Iobuf: import bufio;

	out := bufio->open("/fd/1", bufio->OWRITE);

	while(ndice)
		alt {
			s := <-schan =>
				out.write(array of byte s, len s);
				ndice--;
			* =>
				sys->sleep(15);
		}

	out.flush();
	out.close();

	exit;
}

# Roll a die
roll(d: Die) {
	random := load Random Random->PATH;

	str := sys->sprint("%dd%d: ", d.n, d.m);

	count := d.n;
	for(i := 0; i < count; i++) {
		r := abs(random->randomint(random->ReallyRandom) % d.m) + 1;
		if(exploding)
			if(r == d.m)
				count++;

		str += sys->sprint("%d ", r);
	}

	str += sys->sprint("\n");

	schan <-= str;
}

# Return absolute value
abs(x: int): int
{
	if(x < 0)
		return -x;
	return x;
}
