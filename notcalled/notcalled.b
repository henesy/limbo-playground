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

include "lists.m";
	lists: Lists;

include "workdir.m";

NotCalled: module {
	init:	fn(nil: ref Draw->Context, argv: list of string);
};

splitters: con "(, 	\n";

init(nil: ref Draw->Context, argv: list of string) {
	sys = load Sys Sys->PATH;
	bio = load Bufio Bufio->PATH;
	rdir = load Readdir Readdir->PATH;
	strings = load String String->PATH;
	workdir := load Workdir Workdir->PATH;
	lists = load Lists Lists->PATH;

	argv = tl argv;

	if(len argv < 1)
		argv = workdir->init() :: nil;

	# Function names to check for usage of and their line
	fnames: list of (string, string);

	# Unused fnames
	unused: list of (string, string);

	# For each directory
	for(dirs := argv; dirs != nil; dirs = tl dirs){
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

				unwanted := array[] of {
						":=",
						";",
						"if",
						"for",
						"while",
						"case",
						"\"",
						};

				for(i = 0; i < len needs; i++)
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

				#	# foo
				if(strings->contains(fname, "#"))
					continue readlines;

				fnames = (fname, line) :: fnames;

			}
		}
	}


	# Do it again, but a little different
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

				for(i = 0; i < len needs; i++)
					if(! strings->contains(line, needs[i]))
						continue readlines;

				#for(i = 0; i < len unwanted; i++)
				#	if(strings->contains(line, unwanted[i]))
				#		continue readlines;

				# foo()
				(ntoks, tokens) := sys->tokenize(line, splitters);
				if(ntoks < 2)
					continue readlines;

				# Find function name
				search:
				for(toks := tokens; toks != nil; toks = tl toks){
					token := hd toks;

					for(l := fnames; l != nil; l = tl l){
						(func, fline) := hd l;

						if(token == "#")
							break search;

						if(token != func)
							continue search;

						# Used
						if(fline != line){
							continue readlines;
						}

						unused = hd l :: unused;
					} 
				}
			}
		}
	}

	for(; unused != nil; unused = tl unused){
		(nil, line) := hd unused;
		sys->print("%s\n", line);
	}

	exit;
}


foo()
{}
