#define PREFIX "\x05[xG]"

stock void PrintMessage(int client, const char[] phrase) {
	PrintToChat(client, "%s %t.", PREFIX, phrase);
}
