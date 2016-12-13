#define PREFIX "\x05[xG]"

void PrintMessage(int client, const char[] phrase) {
	PrintToChat(client, "%s %t.", PREFIX, phrase);
}
