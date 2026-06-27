PACKAGE=nvidia-driver-manager

.PHONY: all build clean lint shellcheck install

all: build

build:
	dpkg-buildpackage -us -uc

clean:
	debian/rules clean

lint:
	lintian ../$(PACKAGE)_*.changes

shellcheck:
	find src lib -type f -exec shellcheck {} \;

install:
	sudo dpkg -i ../$(PACKAGE)_*.deb
