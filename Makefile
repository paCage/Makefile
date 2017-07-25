# MODULE_NAME must be set in each module

CC := gcc
CFLAGS := -Wall -std=c11 -lm

MAKE := make compile

TESTRUNNER := cgreen-runner
TESTLIBS := -lcgreen

# _FILES must be set in each module
FILES := $(addsuffix .c,$(_FILES))
FILE_OBJS := $(addsuffix .o,$(_FILES))

# _TESTS must be set in each module
TESTS := $(addsuffix .c,$(_TESTS))
TEST_OBJS := $(addsuffix .o,$(_TESTS))

# _DEPS must be set in each module
# It is recommended to use no dependencies if it is possible
DEPDIRS := $(dir $(_DEPS))
DEP_OBJS := $(addsuffix .o,$(_DEPS))

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

$(MODULE_NAME)_tests.so : compile
	@$(CC) -shared -o $(MODULE_NAME)_tests.so $(FILE_OBJS) $(TEST_OBJS) $(DEP_OBJS) $(TESTLIBS) $(CFLAGS)
	@echo "[CC]\t-shared $(CFLAGS) -o $(MODULE_NAME)_tests.so"

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
test : $(MODULE_NAME)_tests.so
	@echo ""
	@echo "[TESTRUNNER]\t$(MODULE_NAME)_tests.so"
	@echo "-----------------------------------------------------------------------"
	@$(TESTRUNNER) $(MODULE_NAME)_tests.so
	@echo "-----------------------------------------------------------------------"

.PHONY : clean
clean :
	rm -f $(MODULE_NAME)_tests.so $(FILE_OBJS) $(TEST_OBJS) $(DEP_OBJS)

define \n


endef
