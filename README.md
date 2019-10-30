# Redstone Nuclear Dawn Server Project
Get Started Using Github Here: https://guides.github.com/activities/hello-world/

The current stable build environment for this github is sourcemod 1.10 build 6453.

Compile checks are run with sourcemod 1.10 build 6453 to point out future issues.

Bugs/Issues with sourcemod can be fixed here https://github.com/alliedmodders/sourcemod

# Scripting Resources
https://wiki.alliedmods.net/Introduction_to_sourcemod_plugins

https://wiki.alliedmods.net/Nuclear_Dawn_Events

https://sm.alliedmods.net/new-api/

# Build plugins

Run `make` to compile `addons/sourcemod/scripting/*.sp` files using latest stable build of SourceMod or `make build-dev` to compile using latest dev build.

# Deployment

If you have write access to this repo then following command will compile and
deploy all the files required by server to the `build` branch upstream:

```
export GH_TOKEN=<your token>; make build deploy
```

You won't likely need to do this manually though because Travis CI does
that automatically each time `master` branch changes.
