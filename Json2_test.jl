#!/usr/local/bin/julia
using Base.Test
using Json2

SAMPLE_FILE = "sample.json"
function parse_test()
	sampleJson = readall(open(SAMPLE_FILE, "r"))
	pDoc = Json2.parse(sampleJson)
	doc = unsafe_load(pDoc)
	@test doc["int5"] == 5
	@test doc["string thing"] == "example"
	@test doc["bool"] == None
	@test doc["int array"][2] == 2
end

function stream()
	fn = "testing.json"
	f = open(fn, "w")

	for (i, line) in enumerate(eachline(STDIN))
		doc = Json2.parse(line)
		write(f, Json2.build(doc))
		write(f, '\n')
		Json2.free(doc)
	end
end

parse_test()

@time stream()

