local Sg = {}

function Sg.put_elem(t, seq, e)
	local r = t
	for i, k in ipairs(seq) do
		if i < #seq then
			if not r[k] then
				r[k] = {}
			end
		else
			r[k] = e
		end
		r = r[k]
	end
end

function Sg.get_elem(t, seq)
	local r = t
	for i, k in ipairs(seq) do
		if i < #seq then
			if not r[k] then
				return nil
			end
		else
			return r[k]
		end
		r = r[k]
	end
end

return Sg
