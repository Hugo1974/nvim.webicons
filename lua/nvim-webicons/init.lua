local M = {}

-- Cargar los datos base
M.data = require("nvim-webicons.data").data

-- Definir la función setup()
function M.setup(user_config)
	if user_config and user_config.data then
		M.data = vim.tbl_deep_extend("force", M.data or {}, user_config.data)
	end
end

-- Función para calcular la posición centrada
local function calculate_center_position(width, height)
	local ui = vim.api.nvim_list_uis()[1]
	local row = math.floor((ui.height - height) / 2)
	local col = math.floor((ui.width - width) / 2)
	return row, col
end

local function get_max_width(items)
	local max_width = 0
	for _, item in ipairs(items) do
		local width = vim.fn.strdisplaywidth(item) -- Cuenta caracteres visuales
		if width > max_width then
			max_width = width
		end
	end
	return max_width
end
-- Función para mostrar un popup con una lista de elementos
function M.show_popup(items, callback, is_submenu)
	local buf = vim.api.nvim_create_buf(false, true)
	-- local width = get_max_width(items) + 10
	-- local height = #items
	local width = 90
	local height = 30

	local row, col = calculate_center_position(width, height)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "single",
	})

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, items)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Mapear <CR> para seleccionar un elemento
	vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", "", {
		callback = function()
			local line = vim.api.nvim_get_current_line()
			vim.api.nvim_win_close(win, true)
			callback(line)
		end,
	})

	-- Mapear <Esc> para cerrar el popup
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
		callback = function()
			vim.api.nvim_win_close(win, true)
		end,
	})

	-- Mapear <Backspace> para volver al menú principal (solo en submenús)
	if is_submenu then
		vim.api.nvim_buf_set_keymap(buf, "n", "<BS>", "", {
			callback = function()
				vim.api.nvim_win_close(win, true)
				M.start() -- Volver al menú principal
			end,
		})
	end
end

-- Función para ordenar una tabla alfabéticamente
local function sort_table(t)
	local sorted_keys = {}
	for key in pairs(t) do
		table.insert(sorted_keys, key)
	end
	table.sort(sorted_keys)
	return sorted_keys
end

function M.handle_selection(selection)
	if M.data[selection] then
		local sub_items = {}
		local sorted_keys = sort_table(M.data[selection])
		for _, key in ipairs(sorted_keys) do
			table.insert(sub_items, " " .. M.data[selection][key] .. " " .. key) -- Espacio al inicio
		end

		M.show_popup(sub_items, function(item)
			local content = item:match("^%s*(.-) ") -- Captura correctamente el emoji sin el espacio extra
			vim.api.nvim_put({ content }, "c", true, true)
			vim.api.nvim_feedkeys("a ", "n", false)
		end, true)
	end
end

-- Función para manejar la selección de un elemento
-- function M.handle_selection(selection)
-- 	if M.data[selection] then
-- 		local sub_items = {}
-- 		local sorted_keys = sort_table(M.data[selection])
-- 		for _, key in ipairs(sorted_keys) do
-- 			table.insert(sub_items, M.data[selection][key] .. " " .. key)
-- 		end
--
-- 		M.show_popup(sub_items, function(item)
-- 			local content = item:match("^(.-) ")
-- 			vim.api.nvim_put({ content }, "c", true, true)
-- 			vim.api.nvim_feedkeys("a ", "n", false)
-- 		end, true) -- Indicar que es un submenú
-- 	end
-- end

function M.start()
	local main_items = {}
	for _, key in ipairs(vim.tbl_keys(M.data)) do
		table.insert(main_items, " " .. key) -- Agrega un espacio antes de los emojis
	end
	table.sort(main_items)

	M.show_popup(main_items, function(item)
		local clean_selection = item:match("^%s*(.-)$") -- Elimina el espacio extra
		M.handle_selection(clean_selection)
	end)
end
-- Función principal para iniciar el popup
-- function M.start()
-- 	local main_items = vim.tbl_keys(M.data)
-- 	table.sort(main_items)
-- 	M.show_popup(main_items, M.handle_selection)
-- end

return M
