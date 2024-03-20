VERSION = 2
LIBRARY_NAME = watchid-auth.so
DESTINATION = /usr/local/lib/pam
TARGET = x86_64-apple-macosx10.15
MODULE_NAME = watchid_auth

.PHONY: all install clean

all: $(LIBRARY_NAME)

$(LIBRARY_NAME): watchid-auth.swift
	swiftc $< -o $@ -module-name $(MODULE_NAME) -target $(TARGET) -emit-library

install: $(LIBRARY_NAME)
	mkdir -p $(DESTINATION)
	cp $< $(DESTINATION)/$(LIBRARY_NAME).$(VERSION)
	chmod 444 $(DESTINATION)/$(LIBRARY_NAME).$(VERSION)
	chown root:wheel $(DESTINATION)/$(LIBRARY_NAME).$(VERSION)

clean:
	rm -f $(LIBRARY_NAME)
