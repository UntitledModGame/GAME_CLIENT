



rawset(_G, "constants", require("src.shared.constants"))
rawset(_G, "variables", require("src.shared.variables"))

rawset(_G, "tools", require("src.shared.tools.tools"))

rawset(_G, "typecheck", require("src.shared.typecheck"))


rawset(_G, "json", require("libs.json"))


rawset(_G, "ecs", require("src.shared.ecs.ecs"))

string.buffer = require("string.buffer")

table.clear = require("table.clear")


