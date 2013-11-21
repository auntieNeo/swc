# swc: Makefile

.PHONY: all
all: build

VERSION_MAJOR   := 0
VERSION_MINOR   := 0
VERSION         := $(VERSION_MAJOR).$(VERSION_MINOR)

TARGETS         := swc.pc
SUBDIRS         := launch libswc protocol
CLEAN_FILES     := $(TARGETS)

include config.mk
include $(SUBDIRS:%=%/Makefile.local)

ifeq ($(if $(V),$(V),0), 0)
    define quiet
        @echo "  $1	$@"
        @$(if $2,$2,$($1))
    endef
else
    quiet = $(if $2,$2,$($1))
endif

define check_deps
    @echo "Checking for dependencies of $1 ($2)"
    @$(PKG_CONFIG) --exists --print-errors $2
endef

compile = $(call quiet,CC) $(CFLAGS) $(CPPFLAGS) -I . -c -MMD -MP -MF .deps/$(basename $<).d -o $@ $<
link    = $(call quiet,CCLD,$(CC)) $(CFLAGS) -o $@ $^

$(foreach dir,BIN LIB INCLUDE PKGCONFIG,$(DESTDIR)$($(dir)DIR)):
	mkdir -p "$@"

.PHONY: check-dependencies
check-dependencies: $(SUBDIRS:%=check-dependencies-%)

.PHONY: build
build: $(SUBDIRS:%=build-%) $(TARGETS)

swc.pc: swc.pc.in
	$(call quiet,GEN,                           \
	    sed -e "s:@VERSION@:$(VERSION):"        \
	        -e "s:@PREFIX@:$(PREFIX):"          \
	        -e "s:@LIBDIR@:$(LIBDIR):"          \
	        -e "s:@INCLUDEDIR@:$(INCLUDEDIR):"  \
	        $< > $@)

.PHONY: install-swc.pc
install-swc.pc: swc.pc | $(DESTDIR)$(PKGCONFIGDIR)
	install -m0644 $< "$(DESTDIR)$(PKGCONFIGDIR)"

.PHONY: install
install: $(SUBDIRS:%=install-%) $(TARGETS:%=install-%)

.PHONY: clean
clean:
	rm -f $(CLEAN_FILES)

-include .deps/*/*.d

