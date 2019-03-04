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

# A dice roller, pass in args in format XdY and enjoy the rolls
init(nil: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;
	arg = load Arg Arg->PATH;

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
	
	roll();
}

# Roll all of the die
roll() {
	random := load Random Random->PATH;
	bufio := load Bufio Bufio->PATH;
	Iobuf: import bufio;

	out := bufio->open("/fd/1", bufio->OWRITE);

	for(; toroll != nil; toroll = tl toroll) {
		d := hd toroll;

		str := sys->sprint("%dd%d: ", d.n, d.m);
		out.write(array of byte str, len str);

		count := d.n;
		for(i := 0; i < count; i++) {
			r := abs(random->randomint(random->ReallyRandom) % d.m) + 1;
			if(exploding)
				if(r == d.m)
					count++;

			str = sys->sprint("%d ", r);
			out.write(array of byte str, len str);
			out.flush();
		}

		str = sys->sprint("\n");
		out.write(array of byte str, len str);
	}

	out.flush();
	out.close();
}

# Return absolute value
abs(x: int): int
{
	if(x < 0)
		return -x;
	return x;
}
