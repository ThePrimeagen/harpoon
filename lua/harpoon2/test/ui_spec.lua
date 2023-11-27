local utils = require("harpoon2.test.utils")

local eq = assert.are.same

describe("harpoon", function()

    before_each(utils.before_each)

    it("open the ui without any items in the list", function()
        local harpoon = require("harpoon2")
        harpoon.ui:toggle_quick_menu(harpoon:list())

        -- no test, just wanted it to run without error'ing
    end)

end)


