import 'dart:convert';
import 'dart:io';

Future<void> main() async {
    print('Starting builder...');

    // read 'config.json'ß
    var jsonString = await File("config.json").readAsString();

    var config = jsonDecode(jsonString);
    var llms = config['llms'];
    int numOfLlms = llms.length;

    for(var llm in llms) {
        var name = llm['name'];
        var developer = llm['developer'];
        var url = llm['url'];
        print("LLM: $name, developer: $developer, URL: $url");
    }
}