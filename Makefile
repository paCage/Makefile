# MODULE_NAME must be set in each module

CC := gcc
FC := gfortran

SHELL := /bin/bash
MAKE := make compile

TESTRUNNER := cgreen-runner
TEST_LIBS := -lcgreen

# _CSRC C source files, must be set in each module
C_OBJS := $(_CSRC:.c=.o)

# _FSRC fortran source files, must be set in eavc moudle
F_OBJS := $(_FSRC:.f90=.o)
F_MODS := $(shell echo $(_FSRC:.f90=.mod) | tr A-Z a-z)

# _TSRC cgreen tests files, must be set in each module
TEST_OBJS := $(_TSRC:.c=.o)

# _CLIBS a list of libraries, e.g. -leagle, must be set inside a module Makefile
CFLAGS := -Wall -std=c11 $(_CLIBS)

# _FLIBS a list of libraries, e.g. -leagle, must be set inside a module Makefile
FFLAGS := -Wall -std=f2003 $(_FLIBS)

# Final library file
LIB_FILE := lib$(MODULE_NAME).so

# Test file name
TEST_FILE := $(MODULE_NAME)_tests.so


.PHONY : compile
compile : $(C_OBJS) $(TEST_OBJS)


.PHONY : $(TEST_FILE)
$(TEST_FILE) : $(C_OBJS) $(TEST_OBJS)
	echo $(C_OBJS)
	@echo "[CC] -shared -o $(TEST_FILE) $(C_OBJS) $(TEST_OBJS) $(CFLAGS) $(TEST_LIBS)"
	@$(CC) -shared -o $(TEST_FILE) $(C_OBJS) $(TEST_OBJS) $(CFLAGS) $(TEST_LIBS)


.PHONY : install
install : $(C_OBJS) $(F_MODS)
	@echo "[CC] -shared -Wl,-soname,$(LIB_FILE) -o $(LIB_FILE).1.0 $(C_OBJS)"
	@$(CC) -shared -Wl,-soname,$(LIB_FILE).1 -o $(LIB_FILE).1.0 $(C_OBJS)
	@read -p "Please enter the path to an  accessible local directory (q for quit): " local_dir; \
	if [ "$$local_dir" == "q" ]; then \
		exit; \
	fi; \
	mkdir -p $$local_dir/lib; \
	mv ./$(LIB_FILE).1.0 $$local_dir/lib; \
	ln -sf $$local_dir/lib/$(LIB_FILE).1.0 $$local_dir/lib/$(LIB_FILE).1; \
	ln -sf $$local_dir/lib/$(LIB_FILE).1.0 $$local_dir/lib/$(LIB_FILE); \
	mkdir -p $$local_dir/include; \
	mkdir -p $$local_dir/include/$(MODULE_NAME); \
	rm -f ./$(MODULE_NAME).h; \
	for header in `ls *.h`; do \
		printf "#include <%s/%s>\n" $(MODULE_NAME) $$header >> ./$(MODULE_NAME).h; \
	done; \
	mv ./$(MODULE_NAME).h $$local_dir/include/$(MODULE_NAME); \
	cp *.h $$local_dir/include/$(MODULE_NAME); \
	cp *.mod $$local_dir/include; \


.PHONY : watch
watch :
	@command -v inotifywait >/dev/null 2>&1 || { \
		echo >&2 "Please consider installing inotify-tools first. Aborting."; \
		exit 1; \
	}
	@echo "Watching following file(s) for changes..."; \
	find . -regextype sed -regex ".*\.[c|h]"; \
	inotifywait -q -m -e modify `find . -regextype sed -regex ".*\.[c|h]"` | \
		while read -r filename event; do \
			make test; \
			printf "\n\n"; \
			printf "Wrtching following file(s) for changes...\n"; \
			echo "-----------------------------------------------------------------------"; \
			find . -regextype sed -regex ".*\.[c|h]"; \
			printf "\n"; \
		done; \


.PHONY : test
test : $(TEST_FILE)
	@echo ""
	@echo "[TESTRUNNER] $(TEST_FILE)"
	@echo "-----------------------------------------------------------------------"
	@$(TESTRUNNER) $(TEST_FILE)
	@echo "-----------------------------------------------------------------------"


$(C_OBJS) : $(_CSRC)
	@echo "[CC] -fPIC -c $(_CSRC) $(CFLAGS)"
	@$(CC) -fPIC -c $(_CSRC) $(CFLAGS)


$(TEST_OBJS) : $(_TSRC) $(C_OBJS)
	@echo "[CC] -fPIC -c $(_TSRC) $(CFLAGS)"
	@$(CC) -fPIC -c $(_TSRC) $(CFLAGS)


$(F_MODS): $(_FSRC)
	@echo "[FC] $(FFLAGS) -c $(_FSRC)"
	@$(FC) $(FFLAGS) -c $(_FSRC)


.PHONY : clean
clean :
	@rm -fv $(TEST_FILE) $(C_OBJS) $(TEST_OBJS) $(DEP_OBJS) $(F_MODS) $(F_OBJS) $(LIB_FILE).1.0
