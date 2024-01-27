local utils = require("harpoon.test.utils")
local Config = require("harpoon.config")

local eq = assert.are.same

describe("config", function()
    it("default.create_list_item", function()
        local file_name = "/tmp/harpoon-test"
        local row = 3
        local col = 1
        utils.create_file(file_name, {
            "foo",
            "bar",
            "baz",
            "qux",
        }, row, col)

        local config = Config.get_default_config()
        local config_item = Config.get_config(config, "foo")
        local item = config_item.create_list_item(config_item)
        eq({
            value = file_name,
            context = {
                row = 3,
                col = 1,
            },
        }, item)
    end)
end)
