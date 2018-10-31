fennel = require("lib.fennel")
table[("insert")](package[("loaders")], fennel[("searcher")])
pp = function(x) print(require("lib.fennelview")(x)) end

-- tacky workaround for bug in the love appimage
fennel.path = love.filesystem.getSource() .. "/?.fnl"

require("game")

