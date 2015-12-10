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
end

function stream()
	println(STDERR, "### Parse JSONs from STDIN, build JSONs to STDOUT")
	for line in eachline(STDIN)
		obj = Json2.parse(line)
		println(Json2.build(obj))
	end
end

function modify_validate()
	sampleJson = readall(open(SAMPLE_FILE, "r"))
	obj = Json2.parse(sampleJson)

	arr = obj["int array"]
	arr[3] = 7
	push!(arr, 99.9)
	obj["sites"]["google"] = "Gooooogle" # replace new value
	obj["sites"]["gigle"] = "Gigle" # insert new field/value

	#push!(obj, "new field", "hahaha") # Instead of This,
	obj["new field"] = "hahaha" # Use this.

	println("-- iter test 1")
	for key in getkeys(obj)
		println("$key\t$(obj[key])")
	end

	println("-- iter test 2")
	for (key, value) in getitems(obj["sites"])
		println("$key\t$value")
	end

	println("-- iter test 3")
	for item in obj["int array"]
		println(item)
	end
end

# TESTS
parse_validate()

#@time stream()

modify_validate()

