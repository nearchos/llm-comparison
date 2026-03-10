# llm-comparison

Describes an experiment where various LLMs are compared to assess their ability to generate functional apps

A live page is automatically generated with [build.dart](scripts/build.dart), and is available at:
- [data.html](https://nearchos.github.io/llm-comparison/data.html)

Build Flutter projects using:

- `flutter build web --base-href /live/<llm>/<prompt-llm>/`
- for example: `flutter build web --base-href /llm-comparison/live/chatgpt/chatgpt/`
