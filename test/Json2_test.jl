#!/usr/local/bin/julia
using Base.Test
using Json2

SAMPLE_FILE = "sample.json"
function parse_validate()
	sampleJson = readall(open(SAMPLE_FILE, "r"))
	doc = Json2.parse(sampleJson)
	@test doc["int5"] == 5
	@test doc["string thing"] == "example"
	@test doc["bool"] == None
	@test doc["int array"][2] == 2

	Json2.build(doc)
end

function stream(fn::String)
	println(STDERR, "# Parse JSONs from STDIN, build JSONs to '$fn'")
	f = open(fn, "w")

	for (i, line) in enumerate(eachline(STDIN))
		doc = Json2.parse(line)
		write(f, Json2.build(doc))
		write(f, '\n')
	end
end


# TEST 1
parse_validate()


# TEST 2
@time stream("Json2_output.json")

