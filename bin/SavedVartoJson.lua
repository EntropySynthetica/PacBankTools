SavedVar = require("PacBankTools")
json = require("json")

output = json.encode(PacBankToolsSavedVariables)

file = io.open("SavedVarOutput.json", "w")
file:write(output)
file:close(file)