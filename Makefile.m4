.SUFFIXES: .in       # Add .in as a suffix

M4       = m4
M4FLAGS  =
M4SCRIPT =

.in:
	${M4} ${M4FLAGS} ${M4SCRIPT} $< > $*
