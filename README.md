# Json2.jl

JSON parser/builder
- Juila wrapper of following C modules
	- https://github.com/udp/json-parser
	- https://github.com/udp/json-builder

- Done @ v1.0: parse/build JSON, get values
	- parse()
	- getValue()
	- getindex()
	- build()
	- Auto-Free
- Done @ v2.0: set/add values
	- setindex!()
	- push!()
	- getkeys()
	- getlength()
- Done @ v2.1: iterators
	- start/ done/ next() for arrays
	- getsize() for objects
	- getitems() for objects

- Install : run following commands in Julia
	- Pkg.clone("https://github.com/ddolgi/Json2.jl.git")
	- Pkg.build("Json2")
