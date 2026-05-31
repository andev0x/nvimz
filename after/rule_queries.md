
* Prefer ; extends instead of full query overrides
* Keep captures as specific as possible
* Avoid broad (identifier) matches unless necessary
* Minimize regex predicates like #lua-match?
* Never duplicate upstream queries without reason
* Keep injections small and isolated
* Disable cosmetic highlights with low practical value
* Avoid nested or recursive query patterns
* Benchmark large TSX/Markdown files after query changes
* Separate semantic captures from visual-only captures
* Group custom patches by purpose, not by language size
* Remove dead captures aggressively
* Prefer readability over clever query tricks
* Treat queries as runtime code, not static config
* Own only the edge cases upstream cannot handle

> “Patch upstream, don’t replace upstream.”

