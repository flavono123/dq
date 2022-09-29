### Usage

```sh
# Change the `xml_to_yaml.rb' then,
❯ ruby xml_to_yaml.rb
```

### YAML data structure

It is a simple, 2-level, structure

- The first level keys are **speakers**
  - Only heroes and the others exists for now
  - Following would be updated
    - Ancestor(Narrator)
    - Anonymous(Hero common)
    - Caretaker
    - Crier
    - ... 🤔
- The second level keys are **original entry ids** from the Darkest Dungeon locale files(XML)

```yaml
abomination:
   abomination+str_afflicted_abusive_0: Bung it up again and I'll awaken it!
  ...
...
rest:
  bark_effective_difficulty: THIS DUNGEON IS TOO DIFFICULT FOR ME!
  ...
```
