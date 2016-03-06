all: build

build: build-stable

# In build tasks:
# pass -v for verbose mode
# pass --no-cache to download SDK even if it is cached in .tmp/
# pass `--sourcemod=1.7.x-xxxx` or `--sourcemod=1.8.x-xxxx`
#   or whatever version-build of SourceMod you want to compile
#   with
build-stable:
	./build_scripts/build.sh -v --sourcemod=1.7.3-5255

build-dev:
	./build_scripts/build.sh -v --sourcemod=1.8.0-5868

pack:
	rm -fr ./build && mkdir ./build && cp -r ./updater ./build

deploy:
	@./build_scripts/deploy.sh -v \
		--dir=build \
		--repo=github.com/stickz/Redstone \
		--token=${GH_TOKEN} \
		--branch=build
