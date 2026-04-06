# llm-comparison

Describes an experiment where various LLMs are compared to assess their ability to generate functional apps

A live page is automatically generated with code from [scripts/](scripts/), and is accessible at:
- [data.html](https://nearchos.github.io/llm-comparison/data.html)

Build Flutter projects using:
- `flutter build web --base-href /live/<llm>/<prompt-llm>/`
- for example: `flutter build web --base-href /llm-comparison/live/chatgpt/chatgpt/`

For each variation `<llm-which-creates-the-code>`/`<llm-which-formed-the-prompt>` we list the following:
1. The LLM's response
2. The resulting codebase
3. Notes about the effort required to get from the LLM's response to a working codebase (where working mainly means 'compiles' and 'launches')
4. A screenshot of the app in action
5. A live version of the game as a Web app 
