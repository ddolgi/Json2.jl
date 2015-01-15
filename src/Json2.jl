module Json2

	# Depends on https://github.com/udp/json-builder
	const libjson2 = find_library(["libjson2"],[Pkg.dir("Json2", "deps")])

	const JSON_NONE = 0
	const JSON_OBJ = 1
	const JSON_ARR = 2
	const JSON_INT = 3
	const JSON_DBL = 4
	const JSON_STR = 5
	const JSON_BOOL = 6
	const JSON_NULL = 7
	const JSON_BUILDER_EXTRA = unsafe_load(cglobal((:json_builder_extra, libjson2), Uint))
	const JSON_SERIALIZE_MODE_MULTILINE = 0::Int
	const JSON_SERIALIZE_MODE_SINGLE_LINE= 1::Int
	const JSON_SERIALIZE_MODE_PACKED = 2::Int

	type Json_settings
		max_memory::Culong
		settings::Int
		mem_alloc::Ptr{Void}
		mem_free::Ptr{Void}
		user_data::Ptr{Void}
		value_extra::Uint64
		Json_settings() = new(0,0,0,0,0,0)
	end

	type Json_object_entry
		name::Ptr{Int8}
		name_length::Uint
		value::Ptr{Void}
	end

	type Json_value
		parent::Ptr{Json_value}
		vtype::Uint 
		num::Uint
		ptr::Ptr{Void}
		_reserved::Ptr{Void}
	end

	function getValue(pObj::Ptr{Json_value})
		obj = unsafe_load(pObj)
		if obj.vtype == JSON_NONE || obj.vtype == JSON_NULL
			return None
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

	function getindex(obj::Json_value, idx::Int)
		if obj.vtype != JSON_ARR || idx < 1 || obj.num < idx
			return None
		end
		arr = unsafe_load(convert(Ptr{Ptr{Json_value}}, obj.ptr), idx)
		return getValue(arr)
	end	

	function getindex(obj::Json_value, key::String)
		if obj.vtype == JSON_OBJ
			pEntry = convert(Ptr{Json_object_entry}, obj.ptr)
			for i in 1:obj.num	# Linear Search
				entry = unsafe_load(pEntry, i)
				if bytestring(entry.name) == key
					return getValue(convert(Ptr{Json_value}, entry.value))
				end
			end
		end
		return None
	end	

	type Json_document # for Auto-Free
		root::Ptr{Json_value}
		function Json_document(ptr::Ptr{Json_value})
			newItem = new(ptr)
			finalizer( newItem, free)
			return newItem
		end
	end
	getindex(doc::Json_document, idx::Int) = getindex(unsafe_load(doc.root),idx)
	getindex(doc::Json_document, key::String) = getindex(unsafe_load(doc.root), key)

	function parse(json::String)
		settings = Json_settings()
		settings.value_extra = JSON_BUILDER_EXTRA;
		error = Array(Cchar, 128)

		return Json_document(ccall((:json_parse_ex, libjson2) , Ptr{Json_value}
			, (Ptr{Json_settings}, Ptr{Int8}, Uint, Ptr{Cchar})
			, &settings, json, sizeof(json), pointer(error)))
	end


	type Json_serialize_opts
		mode::Int
		opts::Int
		indent_size::Int
	end

	function build(doc::Json_document)
		size = ccall((:json_measure, libjson2), Uint64, (Ptr{Json_value},), doc.root)
		buf = Array(Cchar, size)

		opts = Json_serialize_opts(JSON_SERIALIZE_MODE_PACKED, 0, 4)
		ccall((:json_serialize_ex, libjson2), Void
			, (Ptr{Cchar}, Ptr{Json_value}, Json_serialize_opts)
			, pointer(buf), doc.root, opts)
		return bytestring(convert(Ptr{Cchar}, buf))
	end

	function free(doc::Json_document)
		ccall((:json_builder_free, libjson2), Void
			, (Ptr{Json_value},), doc.root)
	end
end

