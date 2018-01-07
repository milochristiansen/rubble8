
local file = io.open("./#vertag.go", "wb")
file:write([=[// +build vertag

// Automatically generated, do not edit!

package rubble8

func init() {
	VExtra = "]=]..(...)..[=["
}
]=])
file:close()
