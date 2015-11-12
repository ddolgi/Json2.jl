#!/usr/local/bin/julia
using Base.Test
using Json2

SAMPLE_FILE = "sample.json"
function parse_validate()
	sampleJson = readall(open(SAMPLE_FILE, "r"))
	obj = Json2.parse(sampleJson)
	@test obj["int5"] == 5
	@test obj["string thing"] == "example"
	@test obj["bool"] == Union{}
	arr = obj["int array"]
	@test arr[0] == Union{}
	@test arr[1] == 1
	@test arr[5] == 5
	@test arr[6] == Union{}

	# arr[3] = 7
	println(STDERR, "### Checked sample.json: ")
	println(STDERR, Json2.build(obj))
end

function stream()
	println(STDERR, "### Parse JSONs from STDIN, build JSONs to STDOUT")
	for line in eachline(STDIN)
		obj = Json2.parse(line)
		println(Json2.build(obj))
	end
end


# TEST 1
parse_validate()


# TEST 2
@time stream()
