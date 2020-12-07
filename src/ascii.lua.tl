@../lua/ptformula/ascii.lua=
@requires
@declare_functions

@grid_prototype

local style = {
	@style_variables
}

@script_variables

@functions

return {
@export_symbols
}

@functions+=
local function to_ascii(exp)
	@init_grid_structure
	@transform_exp_to_grid
	@if_not_valid_exp_return_nil
	return grid
end

@export_symbols+=
to_ascii = to_ascii,

@if_not_valid_exp_return_nil+=
else
	return nil
end

@grid_prototype+=
local grid = {}
function grid:new(w, h, content)
	local o = { 
		w = w or 0, 
		h = h or 0, 
		content = content or {},
		@grid_data
	}
	return setmetatable(o, { 
		@grid_metamethods
		__index = grid,
	})
end

@init_grid_structure+=
local g = grid:new()

@grid_prototype+=
function grid:join_hori(g)
	local combined = {}

	@align_both_for_horizontal_join
	@compute_horizontal_spaces
	local h = math.max(self.h, g.h)

	for y=1,h do
		@get_row_or_create_empty_row
		@combine_rows_and_put_in_result
	end

	local c = grid:new(self.w+g.w, h, combined)
	@set_result_horizontal_middle
	return c
end

@compute_spacers+=
local s1 = math.floor((h-self.h)/2)
local s2 = math.floor((h-g.h)/2)


@grid_prototype+=
function grid:get_row(y)
	if y < 1 or y > self.h then
		local s = ""
		for i=1,self.w do s = s .. " " end
		return s
	end
	return self.content[y]
end

@get_row_or_create_empty_row+=
local r1 = self:get_row(y-s1)
local r2 = g:get_row(y-s2)

@combine_rows_and_put_in_result+=
table.insert(combined, r1 .. r2)

@style_variables+=
plus_sign = " + ",

@transform_exp_to_grid+=
if exp.kind == "numexp" then
	local numstr = tostring(exp.num)
	return grid:new(string.len(numstr), 1, { tostring(numstr) })
elseif exp.kind == "addexp" then
	local leftgrid = to_ascii(exp.left)
	local rightgrid = to_ascii(exp.right)
	local opgrid = grid:new(utf8len(style.plus_sign), 1, { style.plus_sign })
	local c1 = leftgrid:join_hori(opgrid)
	local c2 = c1:join_hori(rightgrid)
	return c2

@style_variables+=
minus_sign = " - ",

@transform_exp_to_grid+=
elseif exp.kind == "subexp" then
	local leftgrid = to_ascii(exp.left)
	local rightgrid = to_ascii(exp.right)
	local opgrid = grid:new(utf8len(style.minus_sign), 1, { style.minus_sign })
	local c1 = leftgrid:join_hori(opgrid)
	local c2 = c1:join_hori(rightgrid)
	return c2

@style_variables+=
multiply_sign = " ∙ ",

@transform_exp_to_grid+=
elseif exp.kind == "mulexp" then
	local leftgrid = to_ascii(exp.left)
	local rightgrid = to_ascii(exp.right)
	local opgrid = grid:new(utf8len(style.multiply_sign), 1, { style.multiply_sign })
	local c1 = leftgrid:join_hori(opgrid)
	local c2 = c1:join_hori(rightgrid)
	return c2

@grid_metamethods+=
__tostring = function(g)
	return table.concat(g.content, "\n")
end,

@grid_prototype+=
function grid:join_vert(g)
	local w = math.max(self.w, g.w)
	local h = self.h+g.h
	local combined = {}

	@compute_spacers_vertical
	for x=1,w do
		@get_column_or_get_empty_column
		@combine_cols_and_put_in_result
	end

	@transpose_columns
	return grid:new(w, h, rows)
end

@compute_spacers_vertical+=
local s1 = math.floor((w-self.w)/2)
local s2 = math.floor((w-g.w)/2)

@declare_functions+=
local utf8len, utf8char

@functions+=
function utf8len(str)
	return vim.str_utfindex(str)
end

function utf8char(str, i)
	if i >= utf8len(str) or i < 0 then return nil end
	local s1 = vim.str_byteindex(str, i)
	local s2 = vim.str_byteindex(str, i+1)
	return string.sub(str, s1+1, s2)
end

@grid_prototype+=
function grid:get_col(x) 
	local s = ""
	if x < 1 or x > self.w then
		for i=1,self.h do s = s .. " " end
	else
		for y=1,self.h do
			s = s .. utf8char(self.content[y], x-1)
		end
	end
	return s
end

@get_column_or_get_empty_column+=
local c1 = self:get_col(x-s1)
local c2 = g:get_col(x-s2)

@combine_cols_and_put_in_result+=
table.insert(combined, c1 .. c2)

@transpose_columns+=
local rows = {}
for y=1,h do
	local row = ""
	for x=1,w do
		row = row .. utf8char(combined[x], y-1)
	end
	table.insert(rows, row)
end

@transform_exp_to_grid+=
elseif exp.kind == "divexp" then
	local leftgrid = to_ascii(exp.left)
	local rightgrid = to_ascii(exp.right)

	@generate_appropriate_size_fraction_bar

	local opgrid = grid:new(w, 1, { bar })

	local c1 = leftgrid:join_vert(opgrid)
	local c2 = c1:join_vert(rightgrid)
	@set_middle_for_fraction
	return c2

@style_variables+=
div_bar = "―",

@generate_appropriate_size_fraction_bar+=
local bar = ""
local w = math.max(leftgrid.w, rightgrid.w)
for x=1,w do
	bar = bar .. style.div_bar
end

@grid_data+=
my = 0, -- middle y (might not be h/2, for example fractions with big denominator, etc )

@align_both_for_horizontal_join+=
local num_max = math.max(self.my, g.my)
local den_max = math.max(self.h - self.my, g.h - g.my)
local h = num_max + den_max

@compute_horizontal_spaces+=
local s1 = num_max - self.my
local s2 = num_max - g.my

@set_result_horizontal_middle+=
c.my = num_max

@set_middle_for_fraction+=
c2.my = leftgrid.h