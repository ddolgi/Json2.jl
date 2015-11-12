module Json2
	import Base.getindex
	# Depends on https://github.com/udp/json-builder
	const libjson2 = Libdl.find_library(["libjson2"],[Pkg.dir("Json2", "deps")])

	const JSON_NONE = 0
	const JSON_OBJ = 1
	const JSON_ARR = 2
	const JSON_INT = 3
	const JSON_DBL = 4
	const JSON_STR = 5
	const JSON_BOOL = 6
	const JSON_NULL = 7
	const JSON_BUILDER_EXTRA = unsafe_load(cglobal((:json_builder_extra, libjson2), UInt))
	const JSON_SERIALIZE_MODE_MULTILINE = 0::Int
	const JSON_SERIALIZE_MODE_SINGLE_LINE= 1::Int
	const JSON_SERIALIZE_MODE_PACKED = 2::Int

	type JsonValue
		parent::Ptr{JsonValue}
		vtype::UInt
		num::UInt
		ptr::Ptr{Void}
		_reserved::Ptr{Void}
	end

	function getValue(pObj::Ptr{JsonValue})
		obj = unsafe_load(pObj)
		if obj.vtype == JSON_NONE || obj.vtype == JSON_NULL
			return Union{}
		elseif obj.vtype == JSON_OBJ || obj.vtype == JSON_ARR
			return obj
		elseif obj.vtype == JSON_INT
			return convert(Int, obj.num)
		elseif obj.vtype == JSON_DBL
			return convert(Float64, obj.num)
		elseif obj.vtype == JSON_STR
			pStr = convert(Ptr{Int8}, obj.ptr)
			return bytestring(pStr)
		elseif obj.vtype == JSON_BOOL
			return convert(Bool, obj.num)
		end
	end

	function getindex(obj::JsonValue, idx::Int)
		if obj.vtype != JSON_ARR || idx < 1 || obj.num < idx
			return Union{}
		end
		arr = unsafe_load(convert(Ptr{Ptr{JsonValue}}, obj.ptr), idx)
		return getValue(arr)
	end

	type JsonObjKey
		name::Ptr{Int8}
		name_length::UInt
		value::Ptr{Void}
	end

	function getindex(obj::JsonValue, key::AbstractString)
		if obj.vtype == JSON_OBJ
			pEntry = convert(Ptr{JsonObjKey}, obj.ptr)
			for i in 1:obj.num	# Linear Search
				entry = unsafe_load(pEntry, i)
				if bytestring(entry.name) == key
					return getValue(convert(Ptr{JsonValue}, entry.value))
				end
			end
		end
		return Union{}
	end

	type JsonObj # for Auto-Free
		root::Ptr{JsonValue}
		function JsonObj(ptr::Ptr{JsonValue})
			newItem = new(ptr)
			finalizer(newItem, free)
			return newItem
		end
	end

	function free(doc::JsonObj)
		ccall((:json_builder_free, libjson2), Void
			, (Ptr{JsonValue},), doc.root)
	end

	getindex(doc::JsonObj, idx::Int) = getindex(unsafe_load(doc.root), idx)
	getindex(doc::JsonObj, key::AbstractString) = getindex(unsafe_load(doc.root), key)

	type JsonInfo
		max_memory::Culong
		settings::Int
		mem_alloc::Ptr{Void}
		mem_free::Ptr{Void}
		user_data::Ptr{Void}
		value_extra::UInt64
		JsonInfo() = new(0,0,0,0,0,0)
	end

	function parse(json::AbstractString)
		settings = JsonInfo()
		settings.value_extra = JSON_BUILDER_EXTRA;
		error = Array(Cchar, 128)

		return JsonObj(ccall((:json_parse_ex, libjson2) , Ptr{JsonValue}
			, (Ptr{JsonInfo}, Ptr{Int8}, UInt, Ptr{Cchar})
			, &settings, json, sizeof(json), pointer(error)))
	end

	include("Json2-builder.jl")
end
