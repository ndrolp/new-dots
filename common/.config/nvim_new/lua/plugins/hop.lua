---@diagnostic disable: missing-fields
return { {
    "smoka7/hop.nvim",
    version = "*",
    opts = {
        keys = "etovxqpdygfblzhckisuran",
    },
    keys = {
        {
            "<leader>fw", ":HopWordMW<CR>", desc = "Find Word",
        },
        {
            "<leader>fW", ":HopCamelCaseMW<CR>", desc = "Find Word Camel case"
        },
        {
            "f",
            function()
                local hop = require("hop")
                local directions = require("hop.hint").HintDirection
                hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true })
            end,
        },
        {
            "F",
            function()
                local hop = require("hop")
                local directions = require("hop.hint").HintDirection
                hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true })
            end,
        }
    }

} }
