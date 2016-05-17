stock bool:StrStartsWith(const String:sArgs[], const String:segment[])
{
	return STRING_STARTS_WITH == StrContains(sArgs, segment, false);
}

stock bool:StrIsWithin(const String:sArgs[], const String:segment[])
{
	return StrContains(sArgs, segment, false) > IS_WITHIN_STRING;
}
