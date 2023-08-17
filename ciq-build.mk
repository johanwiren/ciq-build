CURRENT_VERSION=$(shell git describe --tags --abbrev=0)
NEXT_VERSION=$(shell awk -F . '{OFS="."; $$NF+=1; print}' <<< $(CURRENT_VERSION))
MONKEY_ARGS=-f monkey.jungle -y $(DEVELOPER_KEY) -w
SRCS=$(shell find source resources -type f)
APP_ID=$(shell xpath -n -q -e '/iq:manifest/iq:application/@id' manifest.xml | cut -d\" -f2 | sed 's/-//g')

SIMULATOR_PID=$(shell cat $(HOME)/Sim-$(LOGNAME) 2>/dev/null)
SHELL_PORT=$(shell lsof -p $(SIMULATOR_PID) -P | sed -n '/TCP \*:123[4-9]/s/.*TCP \*:\([0-9]*\).*/\1/p')

build: build/$(DEFAULT_DEVICE).prg

test: test-on-$(DEFAULT_DEVICE)

clean:
	rm -rf build/*

.PHONY:
connectiq:
	[ -z "$(SIMULATOR_PID)" ] && (connectiq; sleep 1) || exit 0

devices:
	jq -r '[.deviceId, (.partNumbers | first .connectIQVersion), .deviceFamily, .displayType ] | @csv' "$(CONNECT_IQ_ROOT)"/Devices/*/compiler.json

.PHONY: release
release: test
	git diff --quiet HEAD
	monkeyc -e -o exports/$(APP_NAME)-$(NEXT_VERSION).iq -r $(MONKEY_ARGS)
	git tag $(NEXT_VERSION)

.PRECIOUS: build/%.prg
build/%.prg: $(SRCS)
	monkeyc -t -d $* $(MONKEY_ARGS) -o $@

build-for-%:
	monkeyc -r -d $* $(MONKEY_ARGS) -o build/$*.prg

test-on-%: build/%.prg connectiq
	shell --transport_args=127.0.0.1:$(SHELL_PORT) push $< "0:/GARMIN/APPS/$*.prg"
	set -o pipefail; ./ciq-build.exp $(SHELL_PORT) $(APP_ID) $* test | sed -e 's/\\n/\n/g'

.PHONY: run
run:
	$(MAKE)	run-on-$(shell xpath -n -q -e '/iq:manifest/iq:application/iq:products/iq:product/@id' manifest.xml | cut -d\" -f2 | pick)

run-on-%: build/%.prg connectiq
	shell --transport_args=127.0.0.1:$(SHELL_PORT) push $< "0:/GARMIN/APPS/$*.prg"
	./ciq-build.exp $(SHELL_PORT) $(APP_ID) $*
