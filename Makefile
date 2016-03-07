all: build

build: build-stable

# In build tasks:
# pass -v for verbose mode
# pass --no-cache to download SDK even if it is cached in .tmp/
# pass `--sourcemod=1.7.x-xxxx` or `--sourcemod=1.8.x-xxxx`
#   or whatever version-build of SourceMod you want to compile
#   with
# pass `--out=build` or whatever directory you want to buid into
build-stable:
	./build_scripts/build.sh -v --sourcemod=1.7.3-5255 --out=build

build-dev:
	./build_scripts/build.sh -v --sourcemod=1.8.0-5868 --out=build

deploy:
	@./build_scripts/deploy.sh -v \
		--dir=build \
		--repo=github.com/sergeylukin/Redstone \
		--token=${GH_TOKEN} \
		--branch=build
