
type JsonOpt
	mode::Int
	opts::Int
	indent_size::Int
end

function build(doc::JsonObj)
	size = ccall((:json_measure, libjson2), UInt64, (Ptr{JsonValue},), doc.root)
	buf = Array(UInt8, size)

	opts = JsonOpt(JSON_SERIALIZE_MODE_PACKED, 0, 4)
	ccall((:json_serialize_ex, libjson2), Void
		, (Ptr{Cchar}, Ptr{JsonValue}, JsonOpt)
		, pointer(buf), doc.root, opts)
	return utf8(buf)
end

#function setindex!(obj::JsonValue, idx::Int)

#function setindex!(obj::JsonValue, key::AbstractString)
