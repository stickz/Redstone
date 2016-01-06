#undef REQUIRE_PLUGIN
#tryinclude <updater>
#define REQUIRE_PLUGIN

#if defined _updater_included
public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
        Updater_AddPlugin(UPDATE_URL);
}
#endif

AddUpdaterLibrary()
{
	#if defined _updater_included
	if (LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
	#else
	return;	
	#endif
}