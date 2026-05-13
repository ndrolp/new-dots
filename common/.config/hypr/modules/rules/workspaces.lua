hl.workspace_rule({ workspace = "special:scratchpad", on_created_empty = "foot" })

for i = 1, 10 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "desc:AOC Q27G42XE 2S6S1HA031479" })
end

for i = 11, 20 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "desc:Philips Consumer Electronics Company PHL 243V7 0x00009A4C",
	})
end
