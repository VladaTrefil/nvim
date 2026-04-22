local parser = require('rails_test.parser')

local function split(s)
	return vim.split(s, '\n', { plain = true })
end

describe('rails_test.parser', function()
	it('parses a plain failure with [file:line] bracket', function()
		local output = [[
Running:

F

Failure:
UserTest#test_should_save [test/models/user_test.rb:15]:
Expected true to be nil or false.

Finished in 0.01s
1 runs, 1 assertions, 1 failures, 0 errors, 0 skips
]]

		local items = parser.parse(split(output))

		assert.are.equal(1, #items)
		assert.are.equal('test/models/user_test.rb', items[1].filename)
		assert.are.equal(15, items[1].lnum)
		assert.are.equal('E', items[1].type)
		assert.is_truthy(items[1].text:find('Expected true'))
		assert.is_truthy(items[1].text:find('UserTest#test_should_save'))
	end)
end)
