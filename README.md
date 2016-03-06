# Redstone ND Server Project
Looking for: An automated build script to compile pull requests and copy the plugin to /updater/plugin_name/plugins.

# Useful Information
Get Started Using Github Here: https://guides.github.com/activities/hello-world/

Vist this link for questions: http://steamcommunity.com/groups/NDBattleSoc/discussions/0/451850468369717745/

All [xG] Nuclear Dawn servers are running Linux with sourcemod 1.7 build 5255

Bugs/Issues with sourcemod can be fixed here https://github.com/alliedmodders/sourcemod

# Scripting Resources
https://wiki.alliedmods.net/Introduction_to_sourcemod_plugins

https://wiki.alliedmods.net/Nuclear_Dawn_Events

https://sm.alliedmods.net/new-api/

# Compile plugins

Run `make` to compile `addons/sourcemod/scripting/*.sp` files using latest stable build of SourceMod or `make compile-dev` to compile using latest dev build.

# Deployment

If you have write access to this repo then following command will compile and
deploy all the files required by server to the `build` branch upstream:

```
GH_TOKEN=<your token>; make compile pack deploy
```

You won't likely need to do this manually though because Travis CI does
that automatically each time `master` branch changes.
