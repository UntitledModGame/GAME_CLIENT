


rawset(_G, "constants", require("src.shared.constants"))
rawset(_G, "variables", require("src.shared.variables"))


string.buffer = require("string.buffer")
table.clear = require("table.clear")


rawset(_G, "tools", require("src.shared.tools.tools"))

rawset(_G, "typecheck", require("src.shared.typecheck"))

rawset(_G, "json", require("libs.json"))

rawset(_G, "log", require("src.shared.log"))


rawset(_G, "ecs", require("src.shared.ecs.ecs"))
if constants.TEST then
    require("src.shared.ecs.ecs_tests")
end



local Conn = require("src.shared.conn.Conn")
rawset(_G, "conn", Conn())

