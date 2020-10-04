implement Folds;

include "sys.m";
	sys: Sys;

include "draw.m";

Folds: module {
	init:	fn(nil: ref Draw->Context, nil: list of string);
	fold:	fn[T](f: ref fn(a, b: T): T, a₀: array of T): T;
};


sum(a, b: Integer): Integer {
	return Integer(a.n + b.n);
}

fold[T](f: ref fn(a, b: T): T, a₀: array of T): T {
	if(a₀ == nil || len a₀ == 0)
		return nil;

	if(len a₀ < 2)
		return a₀[0];

	x := f(a₀[0], a₀[1]);
	a₁ := array[1] of { * => x };
	n := fold(f, cat(a₁, a₀[2:]));
	return n;
}

# Terrible algorithm
digits(x: Integer): (Integer, array of Integer) {
	if(x.n == 0)
		return (Integer(0), nil);

	s := string x.n;

	if(len s == 1) {
		a := array[1] of { * => x };
		return (Integer(0), a);
	}

	if(len s < 2) {
		y := Integer(int string x.n);
		a := array[2] of {x, y};
		return (Integer(0), a);
	}

	a₁ := Integer(int string s[0]);
	b₁ := Integer(int string s[1]);
	x₁ := Integer(int string s[2:]);

	set := array[2] of {a₁, b₁};

	return (x₁, set);
}

unfold[T](f: ref fn(x: T): (T, array of T), x: T): array of T {
	a: array of T;

	return unfold_rec(f, x, a);
}

unfold_rec[T](f: ref fn(x: T): (T, array of T), x: T, a₀: array of T): array of T {
	(y, a₁) := f(x);

	if(len a₁ < 1)
		return a₀;

	return unfold_rec(f, y, cat(a₀, a₁));
}


init(nil: ref Draw->Context, nil: list of string) {
	sys = load Sys Sys->PATH;

	a₀ := array[6] of Integer;
	for(i := 0; i < len a₀; i++)
		a₀[i] = Integer(i ** 2);

	aprint(a₀);

	sys->print("%d\n", fold(sum, a₀).n);

	aprint(unfold(digits, Integer(987456)));
}

cat[T](a₀, a₁: array of T): array of T {
	if(a₀ == nil && a₁ == nil)
		return nil;

	if(a₀ == nil)
		return a₁;

	if(a₁ == nil)
		return a₀;

	a₂ := array[len a₀ + len a₁] of T;

	for(i₀ := 0; i₀ < len a₀; i₀++)
		a₂[i₀] = a₀[i₀];

	for(i₁ := 0; i₁ < len a₁;){
		a₂[i₀] = a₁[i₁];
		i₀++;
		i₁++;
	}

	return a₂;
}

Integer: type ref Integral;

Integral: adt {
	n: int;
	Equals:		fn(a, b: ref Integral): int;
	String:		fn(x: self ref Integral): string;
};

Integral.Equals(a, b: ref Integral): int {
	return a.n == b.n;
}

Integral.String(x: self ref Integral): string {
	return sys->sprint("%d", x.n);
}

aprint[T](a: array of T)
	for {
		T =>	String:	fn(a: self T): string;
	}
{
	if(a == nil) {
		sys->print("[]\n");
		return;
	}

	sys->print("[");

	for(i := 0; i < len a; i++) {
		sys->print("%s", a[i].String());

		if(i < len a - 1)
			sys->print(", ");
	}

	sys->print("]\n");

}
