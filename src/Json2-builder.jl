#
# type JsonOpt
# 	mode::Int
# 	opts::Int
# 	indent_size::Int
# end

function build(doc::JsonObj)
	size = ccall((:json_measure, libjson2), UInt64, (Ptr{JsonValue},), doc.root)
	buf = Array(UInt8, size)

	# opts = JsonOpt(JSON_SERIALIZE_MODE_PACKED, 0, 4)
	# ccall((:json_serialize_ex, libjson2), Void
	# 	, (Ptr{Cchar}, Ptr{JsonValue}, JsonOpt)
	# 	, pointer(buf), doc.root, opts)
	ccall((:json_serialize, libjson2), Void
		, (Ptr{Cchar}, Ptr{JsonValue})
		, pointer(buf), doc.root)
	pop!(buf)	# delete last NULL
	return utf8(buf)
end

import Base.setindex!

makeValue(value::Int) = ccall((:json_integer_new, libjson2), Ptr{JsonValue}
	, (Int,), value)
makeValue(value::Float64) = ccall((:json_double_new, libjson2), Ptr{JsonValue}
	, (Float64,), value)
makeValue(value::String) = ccall((:json_string_new, libjson2), Ptr{JsonValue}
	, (Ptr{UInt8},), pointer(value))

function setindex!(pObj::Ptr{JsonValue}, value, idx::Int)
	newValue = makeValue(value)
	ccall((:json_array_set, libjson2), Int64
		, (Ptr{JsonValue}, Int64, Ptr{JsonValue})
		, pObj, idx, newValue)
end	# 1: success, 0: failed

function setindex!(pObj::Ptr{JsonValue}, value, key::String)
	newValue = makeValue(value)
	ccall((:json_object_set, libjson2), Int64
		, (Ptr{JsonValue}, Ptr{UInt8}, Ptr{JsonValue})
		, pObj, pointer(key), newValue)
end	# 1: success, 0: failed

function push!(pObj::Ptr{JsonValue}, key::String, value)
	newValue = makeValue(value)
	ccall((:json_object_push, libjson2), Int64
		, (Ptr{JsonValue}, Ptr{UInt8}, Ptr{JsonValue})
		, pObj, pointer(key), newValue)
end	# 1: success, 0: failed

push!(obj::JsonObj, key::String, value) = push!(obj.root, key, value)
setindex!(obj::JsonObj, value, idx::Int) = setindex!(obj.root, value, idx)
setindex!(obj::JsonObj, value, key::String) = setindex!(obj.root, value, key)
