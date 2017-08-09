# MODULE_NAME must be set in each module

CC := gcc
FC := gfortran
SHELL := /bin/bash
MAKE := make compile

TESTRUNNER := cgreen-runner
TESTLIBS := -lcgreen

# _LIBS (a list of libraries, e.g. -leagle) must be set inside a module Makefile
CFLAGS := -Wall -std=c11 $(_LIBS)
FFLAGS := -Wall -std=f2003 $(_FORT_LIBS)

# _FILES must be set in each module
FILE_OBJS := $(_FILES:.c=.o)

# _TESTS must be set in each module
TEST_OBJS := $(_TESTS:.c=.o)

# _FSRC (fortran source codes) must be set in eavc moudle
FORT_MODS := $(_FSRC:.f90=.mod)
FORT_OBJS := $(_FSRC:.f90=.o)

LIB_NAME := lib$(MODULE_NAME).so
TEST_FNAME := $(MODULE_NAME)_tests.so


.PHONY : all
all : test


$(FILE_OBJS) : $(_FILES)
	@echo "[CC]\t-fPIC -c $(_FILES) $(CFLAGS)"
	@$(CC) -fPIC -c $(_FILES) $(CFLAGS)


$(TEST_OBJS) : $(_TESTS) $(FILE_OBJS)
	@echo "[CC]\t-fPIC -c $(_TESTS) $(CFLAGS)"
	@$(CC) -fPIC -c $(_TESTS) $(CFLAGS)


$(FORT_MODS): $(_FSRC)
	@echo "[FC]\t $(FFLAGS) -c $(_FSRC)"
	$(FC) $(FFLAGS) -c $(_FSRC)


define dep_compile
@echo "[MAKE]\t--directory $(1)"; $(MAKE) --directory $(1) $(\n)
endef


dep_compile :
	$(foreach dir, $(DEPDIRS), $(call dep_compile, $(dir)))


.PHONY : compile
compile : $(FILE_OBJS) $(TEST_OBJS) dep_compile


$(TEST_FNAME) : compile
	@echo "[CC]\t-shared $(CFLAGS) -o $(TEST_FNAME)"
	@$(CC) -shared -o $(TEST_FNAME) $(FILE_OBJS) $(TEST_OBJS) $(DEP_OBJS) $(TESTLIBS) $(CFLAGS)


.PHONY : lib
lib : $(FILE_OBJS) $(FORT_MODS)
	@echo "[CC]\t-shared -Wl,-soname,$(LIB_NAME) -o $(LIB_NAME).1.0 $(FILE_OBJS)"
	@$(CC) -shared -Wl,-soname,$(LIB_NAME).1 -o $(LIB_NAME).1.0 $(FILE_OBJS)
	@read -p "Please enter a path to accessible local directory (q for quit): " local_dir; \
	if [ "$$local_dir" == "q" ]; then \
		exit; \
	fi; \
	mkdir -p $$local_dir/lib; \
	mv ./$(LIB_NAME).1.0 $$local_dir/lib; \
	ln -sf $$local_dir/lib/$(LIB_NAME).1.0 $$local_dir/lib/$(LIB_NAME).1; \
	ln -sf $$local_dir/lib/$(LIB_NAME).1.0 $$local_dir/lib/$(LIB_NAME); \
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
test : $(TEST_FNAME)
	@echo ""
	@echo "[TESTRUNNER]\t$(TEST_FNAME)"
	@echo "-----------------------------------------------------------------------"
	@$(TESTRUNNER) $(TEST_FNAME)
	@echo "-----------------------------------------------------------------------"


.PHONY : clean
clean :
	@rm -fv $(TEST_FNAME) $(FILE_OBJS) $(TEST_OBJS) $(DEP_OBJS) $(FORT_MODS) $(FORT_OBJS)


define \n


endef
