local colors = require('theme.colors')
local utils = require('core.utils')

local highlights = {
	NormalFloat = { bg = colors.dark, fg = colors.light0 },

	SnacksBackdrop = { fg = colors.dark, bg = colors.dark, blend = 100 },

	SnacksPicker = { fg = colors.dark, bg = colors.dark },
	SnacksPickerBorder = { fg = colors.dark, bg = colors.dark },
	SnacksPickerInputBorder = { link = 'SnacksPickerBorder' },
	SnacksPickerDir = { fg = colors.light1 },
	SnacksPickerDirectory = { fg = colors.light1 },
	SnacksPickerFile = { fg = colors.light0 },
	SnacksPickerGitStatusAdded = { fg = colors.bright_green, bg = colors.dark },
	SnacksPickerGitStatusIgnored = { fg = colors.light4 },
	SnacksPickerGitStatusModified = { fg = colors.yellow },
	SnacksPickerGitStatusRenamed = { fg = colors.yellow },
	SnacksPickerGitStatusStaged = { fg = colors.green, bg = colors.dark },
	SnacksPickerGitStatusUnmerged = { fg = colors.orange },
	SnacksPickerGitStatusUntracked = { fg = colors.light2 },
	SnacksPickerInput = { link = 'NormalFloat' },
	SnacksPickerMatch = { fg = colors.bright_yellow, bg = colors.dark1, italic = true },
	SnacksPickerPathHidden = { fg = colors.light4 },
	SnacksPickerPrompt = { fg = colors.blue },
	SnacksPickerTitle = { fg = colors.aqua, bold = true },

	SnacksPickerListCursorLine = { link = 'CursorLine' },
	SnacksPickerPreviewCursorLine = { link = 'CursorLine' },

	SnacksPickerPreview = { bg = colors.dark0 },
	SnacksPickerPreviewBorder = { bg = colors.dark0, fg = colors.dark0 },
}

utils.set_highlights(highlights)
