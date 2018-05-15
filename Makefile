# MODULE_NAME, MAJOR, MINOR and PATCH must be set for each module
# OBJS must be set for each module

SHELL := /bin/bash

CC := gcc
FC := gfortran
RM := rm -f -v
AR := ar -q
LN := ln -s
CP := cp
MKDIR := mkdir -p
TOUCH := touch

TESTRUNNER := cgreen-runner
TESTLIB := -lcgreen

BINDIR := ./bin
OBJDIR := ./obj
SRCDIR := ./src
LIBDIR := ./lib
TESTDIR := ./tests
INCLUDEDIR := ./include

HEADER_FILES := `ls $(SRCDIR)/*.h;`
HEADER_DIR := $(INCLUDEDIR)/$(MODULE_NAME)
HEADER_MAIN := $(INCLUDEDIR)/$(MODULE_NAME)/$(MODULE_NAME).h


_OBJS := $(foreach obj, $(OBJS), $(OBJDIR)/$(obj))
_TEST_OBJS := $(foreach obj, $(TEST_OBJS), $(OBJDIR)/$(obj))

LIBS += $(foreach lib, $(paCages), -L $(LIBDIR)/$(lib)/$(LIBDIR) -l$(lib))
INCLUDES += -I $(INCLUDEDIR)


CFLAGS := -Wall -std=c11 $(LIBS) $(INCLUDES)
FFLAGS := -Wall -std=f2003 $(LIBS) $(INCLUDES)


STATIC_LIB_FILE := $(LIBDIR)/lib$(MODULE_NAME).a
SHARED_LIB_FILE := $(LIBDIR)/lib$(MODULE_NAME).so
TEST_FILE := $(TESTDIR)/$(MODULE_NAME)_tests.so


VPATH := $(VPATH):$(SRCDIR):$(TESTDIR)


.PHONY: compile
compile: $(_OBJS) $(paCages)


.PHONY: test
test: CFLAGS := -fPIC $(CFLAGS)
test: FFLAGS := -fPIC $(FFLAGS)
test: clean $(TEST_FILE)
	$(TESTRUNNER) $(TEST_FILE)

$(TEST_FILE): $(_TEST_OBJS) $(_OBJS) $(paCages)
	$(CC) -shared -o $@ $^ $(CFLAGS) $(TESTLIB)


.PHONY: lib_static
lib_static: | cp_headers $(STATIC_LIB_FILE)

$(STATIC_LIB_FILE): | clean $(_OBJS) $(paCages)
	$(AR) $@ $(_OBJS)


.PHONY: lib_shared
lib_shared: | cp_headers $(SHARED_LIB_FILE)

$(SHARED_LIB_FILE): CFLAGS := -fPIC $(CFLAGS)
$(SHARED_LIB_FILE): FFLAGS := -fPIC $(FFLAGS)
$(SHARED_LIB_FILE): | clean $(_OBJS) $(paCages)
	$(CC) -shared -Wl,-soname,$(SHARED_LIB_FILE).$(MAJOR) \
	-o $(SHARED_LIB_FILE).$(MAJOR).$(MINOR) $(_OBJS)


.PHONY: cp_headers
	$(MKDIR) $(HEADER_DIR)
	$(TOUCH) $(HEADER_MAIN)
	$(CP) $(SRCDIR)/*.h $(HEADER_DIR)
	@for h in $(HEADER_FILES); do \
		printf "#include <%s/%s>" $(MODULE_NAME) $(h) >> $(HEADER_MAIN); \
	done;


$(OBJDIR)/%.o: %.c
	$(CC) -c $(CFLAGS) -o $@ $<

$(OBJDIR)/%.o: %.f90
	$(FC) -c $(FFLAGS) -o $@ $< -J $(INCLUDEDIR)


.PHONY: $(paCages)
$(paCages):
	@for lib in $(paCages); do \
		make lib_static -C $$lib; \
	done;


LOCAL_DIR := ${HOME}/.local
.PHONY: install
install: $(C_OBJS) $(F_MODS)


.PHONY: uninstall
uninstall:


.PHONY: watch
watch:
	$(eval FILES := `find . -regextype sed -regex ".*[?\.git][a-zA-Z0-9].[f|f90|c]"`)
	@printf "Watching following file(s)...\n$(FILES)\n"
	@[ command -v inotifywait >/dev/null 2>&1 ] && exit || true;
	@inotifywait -q -m -e modify $(FILES) | \
	while read -r filename event; do make; done;


.PHONY: clean
clean:
	$(RM) $(_OBJS) $(_TEST_OBJS) $(TEST_FILE)
	$(RM) $(STATIC_LIB_FILE) $(SHARED_LIB_FILE).$(MAJOR).$(MINOR)
