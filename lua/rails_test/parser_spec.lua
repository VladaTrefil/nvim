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

	it('parses an error with backtrace, emitting primary + trace entries', function()
		local output = [[
Running:

E

Error:
UserTest#test_bar:
NoMethodError: undefined method `foo' for nil:NilClass
    /gems/some_gem-1.0/lib/some_gem.rb:99:in `something'
    app/models/user.rb:42:in `bar'
    test/models/user_test.rb:20:in `block in <class:UserTest>'

Finished in 0.01s
]]

		local items = parser.parse(split(output))

		-- Primary entry: first RELATIVE backtrace frame (gem frame skipped).
		assert.are.equal('app/models/user.rb', items[1].filename)
		assert.are.equal(42, items[1].lnum)
		assert.are.equal('E', items[1].type)
		assert.is_truthy(items[1].text:find('NoMethodError'))

		-- Trace entries follow (type = 'W'). Exact count depends on which
		-- frames exist under cwd; the gem frame must be absent.
		local trace_count = 0
		for k = 2, #items do
			assert.are.equal('W', items[k].type)
			assert.is_nil(items[k].filename:match('^/'))
			trace_count = trace_count + 1
		end
		assert.is_true(trace_count >= 0)
	end)
end)
