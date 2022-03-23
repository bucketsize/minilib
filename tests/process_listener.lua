#!/usr/bin/env lua

package.path = os.getenv("HOME") .. '/?.lua;'
    .. package.path

-- local Pr = require("minilib.process")
-- local Notifeir = require("minilib.notifeir")

function test_listener()
    Pr.new_listener()("pi", "less", function()
        Util:exec("weston-flower")
    end)
end

-- function test_notifeir()
--     Notifeir:notify("test", "gotcja!")
-- end

test_listener()
-- test_notifeir()
