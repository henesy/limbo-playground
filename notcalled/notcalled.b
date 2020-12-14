implement NotCalled;

include "sys.m";
	sys: Sys;

include "draw.m";

include "bufio.m";
	bio: Bufio;
	Iobuf: import bio;

include "readdir.m";
	rdir: Readdir;

include "string.m";
	strings: String;

include "arg.m";

include "workdir.m";

include "lists.m";
	lists: Lists;

NotCalled: module {
	init:	fn(nil: ref Draw->Context, argv: list of string);
};


# A found function - definition details
Function: adt {
	lineno:	big;
	text:	string;
	name:	string;
	path:	string;
	count:	big;

	uses:	fn(loc: self ref Function, path: string): ref Function;
};

printn:		int		= 0;
printname:	int		= 1;
printline:	int		= 0;
recurse:	int		= 0;
file:		string;
modfile:	string;


# Find functions which are not called anywhere in a file or project
init(nil: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;
	bio = load Bufio Bufio->PATH;
	rdir = load Readdir Readdir->PATH;
	strings = load String String->PATH;
	workdir := load Workdir Workdir->PATH;
	arg := load Arg Arg->PATH;
	lists = load Lists Lists->PATH;

	fcount := big 0;
	nflag := 0;

	arg->init(argv);
	arg->setusage("notcalled [-nalr] [-m mod.m] [-f file.b] dir/ ...");
		while((c := arg->opt()) != 0)
			case c {
			'n' =>
				# Print line number
				printn = 1;
			'a' =>
				# Print function name
				nflag = 1;
			'l' =>
				# Print line text
				printline = 1;
			'r' =>
				# Don't recurse dirs, please
				recurse = 1;
			'f' =>
				file = arg->earg();
			'm' =>
				modfile = arg->earg();
			* =>
                 arg->usage();
             }
	argv = arg->argv();

	if(len argv < 1)
		argv = workdir->init() :: nil;

	if(printn || printline)
		printname = 0;

	if(nflag)
		printname = 1;

	# Function table
	funcs: list of ref Function;

	# Only one file
	if(file != nil){
		funcs = defs(file);
		# For each function
		for(l := funcs; l != nil; l = tl l){
			f := hd l;
			f.uses(file);
		}
		emit(funcs);
		exit;
	}

	# For each directory - find definitions
	for(dirs := argv; dirs != nil; dirs = tl dirs){
		dir := hd dirs;
		(files, n) := rdir->init(dir, rdir->NONE);
		if(n < 0)
			raise sys->sprint("err: could not rdir → %r\n");

		# For each Limbo file
		for(i := 0; i < n; i++) {
			name := files[i].name;
			path := dir + "/" + name;

			# If we recurse - add the file if it's a dir
			if(recurse && (files[i].mode & Sys->DMDIR)){
				# todo - broken
				in := 0;
				for(l := dirs; l != nil; l = tl l)
					if(hd l == path && name != dir)
						in = 1;

				if(!in){
					dirs = lists->append(dirs, path);
				}
			}

			if(len name < 3 || name[len name-2:] != ".b")
				continue;

			fcount++;
			
			funcs = lists->concat(defs(path), funcs);
		}
	}

	# Find all uses
	for(dirs = argv; dirs != nil; dirs = tl dirs){
		dir := hd dirs;
		(files, n) := rdir->init(dir, rdir->NONE);
		if(n < 0)
			raise sys->sprint("err: could not rdir → %r\n");

		# For each Limbo file
		for(i := 0; i < n; i++) {
			name := files[i].name;
			if(len name < 3 || name[len name-2:] != ".b")
				continue;

			path := dir + "/" + name;

			# For each function
			for(l := funcs; l != nil; l = tl l){
				f := hd l;
				f.uses(path);
			}
		}
	}

	emit(funcs);

	exit;
}

# Print out functions which are unused
emit(funcs: list of ref Function) {
	for(; funcs != nil; funcs = tl funcs){
		func := hd funcs;
		if(func.count <= big 0){
			if(printn)
				sys->print("%s:%bd\t", func.path, func.lineno);

			if(printname)
				sys->print("%s\t", func.name);

			if(printline)
				sys->print("%s\t", func.text);

			sys->print("\n");
		}
	}
}

# Find all function defintions in a file
defs(path: string): list of ref Function {
	f := bio->open(path, bio->OREAD);
	dl: list of ref Function;

	readlines:
	for(no := big 0;; no++){
		line := f.gets('\n');
		if(line == nil)
			break readlines;


		if(len line < 2)
			continue readlines;
		line = line[:len line-1];	# Trim newline

		needs := array[] of {
				"(",
				};

		unwanted := array[] of {
				":=",
				";",
				"if",
				"for",
				"while",
				"case",
				"\"",
				"fn",
				};

		for(i := 0; i < len needs; i++)
			if(! strings->contains(line, needs[i]))
				continue readlines;

		for(i = 0; i < len unwanted; i++)
			if(strings->contains(line, unwanted[i]))
				continue readlines;

		# foo()
		(ntoks, tokens) := sys->tokenize(line, "(");
		if(ntoks < 2)
			continue readlines;

		fname := hd tokens;

		# Ignore commented lines
		#	# foo
		if(strings->contains(fname, "#"))
			continue readlines;

		# We ignore init() for posterity
		if(fname == "init")
			continue readlines;

		# Method
		if(strings->contains(fname, "."))
			(nil, fname) = strings->splitstrr(fname, ".");

		dl = ref Function(no, line, fname, path, big 0) :: dl;
	}

	return dl;
}

# Count if unused in a file
Function.uses(loc: self ref Function, path: string): ref Function {
	f := bio->open(path, bio->OREAD);

	readlines:
	for(;;){
		line := f.gets('\n');
		if(line == nil)
			break readlines;

		if(len line < 2)
			continue readlines;
		line = line[:len line-1];	# Trim newline

		needs := array[] of {
				"(",
				};

		#unwanted := array[] of {
		#		};

		for(i := 0; i < len needs; i++)
			if(! strings->contains(line, needs[i]))
				continue readlines;

		#for(i = 0; i < len unwanted; i++)
		#	if(strings->contains(line, unwanted[i]))
		#		continue readlines;

		# foo()
		(ntoks, tokens) := sys->tokenize(line, "(, 	\n{[;.");
		if(ntoks < 2)
			continue readlines;

		# Find function name
		search:
		for(toks := tokens; toks != nil; toks = tl toks){
			token := hd toks;

			func := loc.name;
			fline := loc.text;

			if(token == "#")
				break search;

			if(token != func)
				continue search;

			# Our definition
			if(fline == line)
				continue readlines;

			# Used
			loc.count++;
		}
	}

	return loc;
}

# foo() is an unused function
foo()
{}
