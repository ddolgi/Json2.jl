module Json2
	import Base.getindex
	import Base.push!
	import Base.keys
	import Base.length

	const Null = Union{}
	typealias String AbstractString
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
		num::Int64
		ptr::Ptr{Void}
		_reserved::Ptr{Void}
	end

	type JsonFloat
		parent::Ptr{JsonValue}
		vtype::UInt
		num::Float64
		ptr::Ptr{Void}
		_reserved::Ptr{Void}
	end

	function free(pValue::Ptr{JsonValue})
		ccall((:json_builder_free, libjson2), Void
			, (Ptr{JsonValue},), pValue)
	end

	function getValue(pObj::Ptr{JsonValue})
		obj = unsafe_load(pObj)
		if obj.vtype == JSON_NONE || obj.vtype == JSON_NULL
			return Null
		elseif obj.vtype == JSON_OBJ || obj.vtype == JSON_ARR
			return pObj
		elseif obj.vtype == JSON_INT
			return obj.num
		elseif obj.vtype == JSON_DBL
			return unsafe_load(convert(Ptr{JsonFloat}, pObj)).num
		elseif obj.vtype == JSON_STR
			pStr = convert(Ptr{Int8}, obj.ptr)
			return bytestring(pStr)
		elseif obj.vtype == JSON_BOOL
			return convert(Bool, obj.num)
		end
	end

	function getindex(pObj::Ptr{JsonValue}, idx::Int)
		obj = unsafe_load(pObj)
		if obj.vtype != JSON_ARR || idx < 1 || obj.num < idx
			return Null
		end
		arr = unsafe_load(convert(Ptr{Ptr{JsonValue}}, obj.ptr), idx)
		return getValue(arr)
	end
	getlength(pObj::Ptr{JsonValue}) = unsafe_load(pObj).num

	Base.start(pObj::Ptr{JsonValue}) = 1
	Base.done(pObj::Ptr{JsonValue}, state) = getlength(pObj) < state
	Base.next(pObj::Ptr{JsonValue}, state) = pObj[state], state + 1

	type JsonObjKey
		name::Ptr{Int8}
		name_length::UInt
		value::Ptr{Void}
	end

	function getindex(pObj::Ptr{JsonValue}, key::String)
		obj = unsafe_load(pObj)
		if obj.vtype == JSON_OBJ
			pEntry = convert(Ptr{JsonObjKey}, obj.ptr)
			for i in 1:obj.num	# Linear Search
				entry = unsafe_load(pEntry, i)
				if bytestring(entry.name) == key
					return getValue(convert(Ptr{JsonValue}, entry.value))
				end
			end
		end
		return Null
	end

	function getsize(pObj::Ptr{JsonValue})
		obj = unsafe_load(pObj)
		if obj.vtype != JSON_OBJ
			return Null
		end

		return obj.num
	end

	function getkeys(pObj::Ptr{JsonValue})
		obj = unsafe_load(pObj)
		if obj.vtype != JSON_OBJ
			return Null
		end

		ret = []
		pEntry = convert(Ptr{JsonObjKey}, obj.ptr)
		for i in 1:obj.num	# Linear Search
			entry = unsafe_load(pEntry, i)
			push!(ret, bytestring(entry.name))
		end
		return ret
	end

	function getitems(pObj::Ptr{JsonValue})
		obj = unsafe_load(pObj)
		if obj.vtype != JSON_OBJ
			return Null
		end

		ret = []
		pEntry = convert(Ptr{JsonObjKey}, obj.ptr)
		for i in 1:obj.num	# Linear Search
			entry = unsafe_load(pEntry, i)
			push!(ret, 
					(bytestring(entry.name), getValue(convert(Ptr{JsonValue}, entry.value))))
		end
		return ret
	end

	type JsonObj # for Auto-Free
		root::Ptr{JsonValue}
		function JsonObj(ptr::Ptr{JsonValue})
			newItem = new(ptr)
			finalizer(newItem, free)
			return newItem
		end
	end

	free(doc::JsonObj) = free(doc.root)
	getindex(doc::JsonObj, idx::Int) = getindex(doc.root, idx)
	getindex(doc::JsonObj, key::String) = getindex(doc.root, key)
	getsize(doc::JsonObj) = getsize(doc.root)
	getkeys(doc::JsonObj) = getkeys(doc.root)
	getitems(doc::JsonObj) = getitems(doc.root)

	Base.start(doc::JsonObj) = 1
	Base.done(doc::JsonObj, state) = getlength(doc) < state
	Base.next(doc::JsonObj, state) = doc[state], state + 1

	type JsonInfo
		max_memory::Culong
		settings::Int
		mem_alloc::Ptr{Void}
		mem_free::Ptr{Void}
		user_data::Ptr{Void}
		value_extra::UInt64
		JsonInfo() = new(0,0,0,0,0,0)
	end

	function parse(json::String)
		settings = JsonInfo()
		settings.value_extra = JSON_BUILDER_EXTRA;
		error = Array(Cchar, 128)

		return JsonObj(ccall((:json_parse_ex, libjson2) , Ptr{JsonValue}
			, (Ptr{JsonInfo}, Ptr{Int8}, UInt, Ptr{Cchar})
			, &settings, json, sizeof(json), pointer(error)))
	end

	export Null, getkeys, getlength, getitems, getsize
	include("Json2-builder.jl")
end
