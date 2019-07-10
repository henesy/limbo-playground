implement Fizzbuzz;

include "sys.m";
	sys: Sys;

include "draw.m";

include "arg.m";

Fizzbuzz: module {
	init: fn(nil: ref Draw->Context, argv: list of string);
};

init(nil: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;
	arg := load Arg Arg->PATH;

	max := big 110;

	arg->init(argv);
	arg->setusage("fizzbuzz [-n target]");
	while((c := arg->opt()) != 0)
		case c {
		'n' => max = big arg->earg();
		* => arg->usage();
		}

	i: big;
	for(i = big 0; i <= max; i++) {
		sys->print("%bd ", i);
		if(i % big 3 == big 0)
			sys->print("fizz ");
		if(i % big 5 == big 0)
			sys->print("buzz ");
		sys->print("\n");
	}

	exit;
}
