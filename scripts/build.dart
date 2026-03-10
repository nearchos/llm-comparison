import 'dart:convert';
import 'dart:io';

Future<void> main() async {
    print('Starting builder...');

    // read 'template.html'
    var template = await File("template.html").readAsString();
    // replace %date% with current date
    var now = DateTime.now();
    var formattedDate = "${now.day}/${now.month}/${now.year}";
    template = template.replaceAll("%date%", formattedDate);

    // read 'llm_row_item_template.html'
    var llmRowItemTemplate = await File("llm_row_item_template.html").readAsString();

    // read 'llm_row_template.html'
    var llmRowTemplate = await File("llm_row_template.html").readAsString();

    // read 'config.json'
    var configJson = await File("config.json").readAsString();
    var config = jsonDecode(configJson);

    // read 'config.json'
    var selfAssessmentJson = await File("self_assessment.json").readAsString();
    var selfAssessment = jsonDecode(selfAssessmentJson);

    // read 'notes.json'
    var notesJson = await File("notes.json").readAsString();
    var notes = jsonDecode(notesJson);  

    // read 'scores.json'
    var scoresJson = await File("scores.json").readAsString();
    var scores = jsonDecode(scoresJson);

    var llms = config['llms'];
    int numOfLlms = llms.length;

    var rows = [];

    for(int i = 0; i < numOfLlms; i++) {
        var llm = llms[i];
        var llm_name = llm['name'];
        var llm_folder = llm['folder'];
        var llm_id = llm['id'];
        var llm_developer = llm['developer'];
        var llm_url = llm['url'];
        var llm_self_assessment = selfAssessment['self_assessment'][i];
        print("LLM: $llm_name, folder: $llm_folder, id: $llm_id, developer: $llm_developer, URL: $llm_url, self-assessment: $llm_self_assessment");

        var first_prompt = "";
        var other_prompts = "";
        for(int j  = 0; j < numOfLlms; j++) {
            var prompt = llms[j];
            // create row each LLM prompt
            var prompt_row = llmRowItemTemplate;
            prompt_row = prompt_row.replaceAll("%llm_id%", llm_id);

            prompt_row = prompt_row.replaceAll("%name%", prompt['name']);
            prompt_row = prompt_row.replaceAll("%folder%", prompt['folder']);
            prompt_row = prompt_row.replaceAll("%id%", prompt['id']);
            prompt_row = prompt_row.replaceAll("%developer%", prompt['developer']);
            prompt_row = prompt_row.replaceAll("%url%", prompt['url']);

            // check if file exists, if not, replace with placeholder
            var response3Path = "../docs/responses/response_3_${llm_id}_${prompt['id']}.txt";
            bool response3PathExists = File(response3Path).existsSync();
            print("    ...adding $i:$j -> $llm_name : ${prompt['name']} (response3PathExists: $response3PathExists)");

            String response3Html = response3PathExists ?
                "<a href='responses/response_3_${llm_id}_${prompt['id']}.txt' target='_blank'>View</a>" :
                "&empty;";
            prompt_row = prompt_row.replaceAll("%response3%", response3Html);

            String screenshotHtml = response3PathExists ?
                "<a href='screenshots/${llm_id}_${prompt['id']}.png' target='_blank'><img src='screenshots/${llm_id}_${prompt['id']}.png' width='100'/></a>" :
                "";
            prompt_row = prompt_row.replaceAll("%screenshot%", screenshotHtml);

            var notesList = notes[llm_id][prompt['id']];
            var notesHtml = notesList != null ? "<ol>" + notesList.map((note) => "<li><div data-tooltip=\"$note\">${shorten(note)}</div></li>").join("\n") + "</ol>" : "&empty;";
            prompt_row = prompt_row.replaceAll("%notes%", notesHtml);

            var liveGameHtml = response3PathExists ?
                "<a href='live/${llm_id}/${prompt['id']}/index.html' target='_blank'>View</a>" :
                "";
            prompt_row = prompt_row.replaceAll("%live_game%", liveGameHtml);

            var scoreHtml = response3PathExists ?
                """<ul>
    <li>Brand: ${scores[llm_id][prompt['id']]['brand']}/10</li>
    <li>Gameplay: ${scores[llm_id][prompt['id']]['gameplay']}/10</li>
    <li>Graphics: ${scores[llm_id][prompt['id']]['graphics']}/10</li>
</ul>""" :
                "";
            prompt_row = prompt_row.replaceAll("%score%", scoreHtml);

            if(j == 0) {
                // set first prompt to template
                first_prompt = prompt_row;
            } else {
                other_prompts += """        <tr>
            $prompt_row
        </tr>
        
        """;
            }
        }
        // create row for given LLM
        var row = llmRowTemplate;

        row = row.replaceAll("%name%", llm_name);
        row = row.replaceAll("%folder%", llm_folder);
        row = row.replaceAll("%id%", llm_id);
        row = row.replaceAll("%developer%", llm_developer);
        row = row.replaceAll("%url%", llm_url);
        row = row.replaceAll("%num_of_llms%", numOfLlms.toString());

        row = row.replaceAll("%brand%", llm_self_assessment['brand'].toString());
        row = row.replaceAll("%gameplay%", llm_self_assessment['gameplay'].toString());
        row = row.replaceAll("%graphics%", llm_self_assessment['graphics'].toString());

        row = row.replaceAll("%first_prompt%", first_prompt);
        row = row.replaceAll("%other_prompts%", other_prompts);

        rows.add(row);
        // break;//todo
    }

    // replace %rows% with rows
    template = template.replaceAll("%rows%", rows.join("\n\n"));

    // write 'data.html'
    await File("../docs/data.html").writeAsString(template);
    print('Builder finished.');
}

// Shorten a string to a given length, adding "..." at the end if it was shortened.
// Does not cut words in half, but rather cuts at the last space before the max length.
String shorten(String str, {int maxLength = 24}) {
    if (str.length <= maxLength) {
        return str;
    }
    var lastSpace = str.lastIndexOf(' ', maxLength);
    if (lastSpace == -1) {
        return str.substring(0, maxLength) + '...';
    }
    return str.substring(0, lastSpace) + '...';
}   