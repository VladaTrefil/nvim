local colors = require('theme.colors')
local utils = require('core.utils')

local highlights = {
	RenderMarkdownCodeBlock = { bg = colors.dark0 },
	RenderMarkdownCode = { bg = colors.dark0 },
}

utils.set_highlights(highlights)
