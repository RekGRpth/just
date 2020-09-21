CC=g++
RELEASE=0.0.3

.PHONY: help clean

help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_\.-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

zlib: ## install and compile the zlib modules, needed for builder runtime
	rm -fr modules
	curl -L -o modules.tar.gz https://github.com/just-js/modules/archive/$(RELEASE).tar.gz
	tar -zxvf modules.tar.gz
	mv modules-$(RELEASE) modules

builtins-build-deps: zlib deps just.cc just.h Makefile main.cc just.js lib/*.js ## compile builtins with build dependencies
	ld -r -b binary deps.tar.gz just.cc just.h just.js Makefile main.cc lib/websocket.js lib/inspector.js lib/loop.js lib/require.js lib/path.js lib/repl.js lib/fs.js lib/build.js -o builtins.o

builtins-build: zlib deps just.cc just.h Makefile main.cc just.js lib/*.js ## compile builtins with build dependencies
	ld -r -b binary just.cc just.h just.js Makefile main.cc lib/websocket.js lib/inspector.js lib/loop.js lib/require.js lib/path.js lib/repl.js lib/fs.js lib/build.js -o builtins.o

builtins: just.js lib/*.js ## compile builtins js
	ld -r -b binary just.js lib/websocket.js lib/inspector.js lib/loop.js lib/require.js lib/path.js lib/repl.js lib/fs.js -o builtins.o

runtime: builtins ## build dynamic runtime
	$(CC) -c -DSHARED -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter just.cc
	$(CC) -c -DSHARED -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter main.cc
	$(CC) -s -rdynamic -pie -flto -pthread -m64 -Wl,--start-group main.o just.o builtins.o -Wl,--end-group -ldl -lrt -lv8 -lv8_libplatform -o just

runtime-builder: builtins-build ## build builder runtime
	JUST_HOME=$(JUST_HOME) make -C modules/zlib/ deps zlib.a
	$(CC) -c -DSHARED -DBUILDER -std=c++17 -DV8_COMPRESS_POINTERS -I. -Imodules/zlib -Ideps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter just.cc
	$(CC) -c -DSHARED -DBUILDER -std=c++17 -DV8_COMPRESS_POINTERS -I. -Imodules/zlib -Ideps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter main.cc
	$(CC) -s -rdynamic -pie -flto -pthread -m64 -Wl,--start-group modules/zlib/zlib.a main.o just.o builtins.o -Wl,--end-group -ldl -lrt -lv8 -lv8_libplatform -o just

runtime-builder-deps: builtins-build-deps ## build builder with dependencies embedded in the binary
	JUST_HOME=$(JUST_HOME) make -C modules/zlib/ deps zlib.a
	$(CC) -c -DSHARED -DBUILDER -std=c++17 -DV8_COMPRESS_POINTERS -I. -Imodules/zlib -Ideps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter just.cc
	$(CC) -c -DSHARED -DBUILDER -std=c++17 -DV8_COMPRESS_POINTERS -I. -Imodules/zlib -Ideps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter main.cc
	$(CC) -s -rdynamic -pie -flto -pthread -m64 -Wl,--start-group modules/zlib/zlib.a main.o just.o builtins.o -Wl,--end-group -ldl -lrt -lv8 -lv8_libplatform -o just

runtime-debug: builtins ## build debug version of runtime
	$(CC) -c -DSHARED -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -g -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter just.cc
	$(CC) -c -DSHARED -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -g -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter main.cc
	$(CC) -rdynamic -pie -flto -pthread -m64 -Wl,--start-group main.o just.o builtins.o -Wl,--end-group -ldl -lrt -lv8 -lv8_libplatform -o just

runtime-static: builtins ## build static version of runtime
	$(CC) -c -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter just.cc
	$(CC) -c -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter main.cc
	$(CC) -s -static -pie -flto -pthread -m64 -Wl,--start-group main.o just.o builtins.o -Wl,--end-group -ldl -lrt -lv8 -lv8_libplatform -o just

runtime-debug-static: builtins ## build static debug version of runtime
	$(CC) -c -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -g -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter just.cc
	$(CC) -c -std=c++17 -DV8_COMPRESS_POINTERS -I. -I./deps/v8/include -g -O3 -march=native -mtune=native -Wpedantic -Wall -Wextra -flto -Wno-unused-parameter main.cc
	$(CC) -static -pie -flto -pthread -m64 -Wl,--start-group main.o just.o builtins.o -Wl,--end-group -ldl -lrt -lv8 -lv8_libplatform -o just

clean: ## tidy up
	rm -f *.o
	rm -f just

cleanall: ## remove just and build deps
	rm -fr deps
	rm -f *.gz
	rm -fr modules
	make clean

install: runtime ## install
	cp -f just /usr/local/bin/

uninstall: ## uninstall
	rm -f /usr/local/bin/just

.DEFAULT_GOAL := help
