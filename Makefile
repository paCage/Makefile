# MODULE_NAME must be set in each module

CC := gcc
SHELL := /bin/bash
MAKE := make compile

TESTRUNNER := cgreen-runner
TESTLIBS := -lcgreen

# _LIBS (a list of libraries, e.g. -leagle) must be set inside a module Makefile
CFLAGS := -Wall -std=c11 -lm $(_LIBS)

# _FILES must be set in each module
FILES := $(addsuffix .c,$(_FILES))
FILE_OBJS := $(addsuffix .o,$(_FILES))

# _TESTS must be set in each module
TESTS := $(addsuffix .c,$(_TESTS))
TEST_OBJS := $(addsuffix .o,$(_TESTS))

LIB_NAME := lib$(MODULE_NAME).so
TEST_FNAME := $(MODULE_NAME)_tests.so


.PHONY : all
all : test


$(FILE_OBJS) : $(FILES)
	@$(CC) -fPIC -c $(FILES) $(CFLAGS)
	@echo "[CC]\t-fPIC -c $(FILES) $(CFLAGS)"


$(TEST_OBJS) : $(TESTS) $(FILE_OBJS)
	@$(CC) -fPIC -c $(TESTS) $(CFLAGS)
	@echo "[CC]\t-fPIC -c $(TESTS) $(CFLAGS)"


define dep_compile
@echo "[MAKE]\t--directory $(1)"; $(MAKE) --directory $(1) $(\n)
endef


dep_compile :
	$(foreach dir, $(DEPDIRS), $(call dep_compile, $(dir)))


.PHONY : compile
compile : $(FILE_OBJS) $(TEST_OBJS) dep_compile


$(TEST_FNAME) : compile
	@$(CC) -shared -o $(TEST_FNAME) $(FILE_OBJS) $(TEST_OBJS) $(DEP_OBJS) $(TESTLIBS) $(CFLAGS)
	@echo "[CC]\t-shared $(CFLAGS) -o $(TEST_FNAME)"


.PHONY : lib
lib : $(FILE_OBJS)
	@$(CC) -shared -Wl,-soname,$(LIB_NAME).1 -o $(LIB_NAME).1.0 $(FILE_OBJS)
	@echo "[CC]\t-shared -Wl,-soname,$(LIB_NAME) -o $(LIB_NAME).1.0 $(FILE_OBJS)"
	@read -p "Please enter a path to accessible local directory (q for quit): " local_dir; \
	if [ local_dir -eq 'q' ]; then \
		exit; \
	fi; \
	mkdir -p $$local_dir/lib; \
	mv ./$(LIB_NAME).1.0 $$local_dir/lib; \
	ln -sf $$lib_dir/lib/$(LIB_NAME).1.0 $$lib_dir/lib/$(LIB_NAME).1; \
	ln -sf $$lib_dir/lib/$(LIB_NAME).1.0 $$lib_dir/lib/$(LIB_NAME); \
	cat *.h > $(MODULE_NAME).h; \
	mkdir -p $$local_dir/include; \
	mv ./$(MODULE_NAME).h $$local_dir/include; \


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
	rm -f $(TEST_FNAME) $(FILE_OBJS) $(TEST_OBJS) $(DEP_OBJS)


define \n


endef
