#!/usr/local/bin/julia
using Base.Test
using Json2

SAMPLE_FILE = "sample.json"
function parse_validate()
	sampleJson = readall(open(SAMPLE_FILE, "r"))
	obj = Json2.parse(sampleJson)
	@test length(getkeys(obj)) == 12
	@test obj["invalid"] == Null
	@test obj["int5"] == 5
	@test obj["big int"] == 4294967301
	@test obj["float"] == 4.323422 #Failed
	@test obj["string thing"] == "example"
	@test obj["bool var true"] == true

	arr = obj["int array"]
	@test getlength(arr) == 5
	@test arr[0] == Null
	@test arr[1] == 1
	@test arr[4] == -4
	@test arr[6] == Null
	println(STDERR, "### Checked sample.json: ")
	println(Json2.build(obj))

	arr[3] = 7
	obj["sites"]["google"] = "Gooooogle"
	push!(obj, "new field", "hahaha")
	println(STDERR, "### Modified sample.json: ")
	println(Json2.build(obj))
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
