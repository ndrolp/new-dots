hl.workspace_rule({ workspace = "special:scratchpad" })

for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "desc:AOC CU34G4 2SES7HA013005" })
end

for i = 11, 20 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "desc:Philips Consumer Electronics Company PHL 243V7 0x00009A4C",
		layout = "dwindle",
	})
end
