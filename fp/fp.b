implement FunctionalProgramming;

include "sys.m";
	sys: Sys;

include "draw.m";

include "lists.m";
	lists: Lists;

FunctionalProgramming: module {
	init: fn(nil: ref Draw->Context, nil: list of string);
};

# Can't have a `ref int`, but you can have a type alias to `ref Integral` in `T` polymorphism
Integral: adt {
	n: int;
};

Int: type ref Integral;

double(i: Int): Int {
	return Int(2 * i.n);
}

iseven(i: Int): int {
	return i.n % 2 == 0;
}

init(nil: ref Draw->Context, nil: list of string) {
	sys = load Sys Sys->PATH;
	lists = load Lists Lists->PATH;

	# Int boundary

	l: list of Int;
	l = Int(13) :: Int(32) :: Int(9) :: Int(-13) :: Int(9999) :: l;
	l = lists->map(
			double, lists->filter(
				iseven, id(l)
			)
		);

	for(; l != nil; l = tl l) {
		n := hd l;
		sys->print("%d\n", n.n);
	}

	exit;
}

id[T](l: list of T): list of T {
	return l;
}
