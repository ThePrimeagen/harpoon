local harpoon = require("harpoon")
local term = require("harpoon.term")

local function assert_table_equals(tbl1, tbl2)
    if #tbl1 ~= #tbl2 then
        assert(false, "" .. #tbl1 .. " != " .. #tbl2)
    end
    for i = 1, #tbl1 do
        if tbl1[i] ~= tbl2[i] then
            assert.equals(tbl1[i], tbl2[i])
        end
    end
end

describe("basic functionalities", function()
    local emitted
    local cmds

    before_each(function()
        emitted = false
        cmds = {}
        harpoon.get_term_config = function()
            return {
                cmds = cmds,
            }
        end
        term.emit_changed = function()
            emitted = true
        end
    end)

    it("add_cmd for empty", function()
        term.add_cmd("cmake ..")
        local expected_result = {
            "cmake ..",
        }
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
        assert.equals(emitted, true)
    end)

    it("add_cmd for non_empty", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        local expected_result = {
            "cmake ..",
            "make",
            "ninja",
        }
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
        assert.equals(emitted, true)
    end)

    it("rm_cmd: removing a valid element", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        term.rm_cmd(2)
        local expected_result = {
            "cmake ..",
            "ninja",
        }
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
        assert.equals(emitted, true)
    end)

    it("rm_cmd: remove first element", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        term.rm_cmd(1)
        local expected_result = {
            "make",
            "ninja",
        }
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
        assert.equals(emitted, true)
    end)

    it("rm_cmd: remove last element", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        term.rm_cmd(3)
        local expected_result = {
            "cmake ..",
            "make",
        }
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
        assert.equals(emitted, true)
    end)

    it("rm_cmd: trying to remove invalid element", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        term.rm_cmd(5)
        local expected_result = {
            "cmake ..",
            "make",
            "ninja",
        }
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
        assert.equals(emitted, true)
        term.rm_cmd(0)
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
        term.rm_cmd(-1)
        assert_table_equals(harpoon.get_term_config().cmds, expected_result)
    end)

    it("get_length", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        assert.equals(term.get_length(), 3)
    end)

    it("valid_index", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        assert(term.valid_index(1))
        assert(term.valid_index(2))
        assert(term.valid_index(3))
        assert(not term.valid_index(0))
        assert(not term.valid_index(-1))
        assert(not term.valid_index(4))
    end)

    it("set_cmd_list", function()
        term.add_cmd("cmake ..")
        term.add_cmd("make")
        term.add_cmd("ninja")
        term.set_cmd_list({ "make uninstall", "make install" })
        local expected_result = {
            "make uninstall",
            "make install",
        }
        assert_table_equals(expected_result, harpoon.get_term_config().cmds)
    end)
end)
