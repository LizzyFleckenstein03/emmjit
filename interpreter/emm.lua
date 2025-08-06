#!/usr/bin/env lua
local stack = {}
local queue = {}
local inst = {}

local function tostr(x) return string.char(x) end
local function fromstr(x) return x:byte(1) end
local function push(x) table.insert(stack, x % 256) end
local function pop() return assert(table.remove(stack), "pop from empty stack") end
local function top() return assert(stack[#stack], "get top of empty stack") end
local function enqueue(x) table.insert(queue, x) end
local function dequeue() return table.remove(queue, 1) end
local function input() return fromstr(io.read(1)) end
local function output(x) io.write(tostr(x)) io.flush() end
local function log2(x) return math.floor(math.log(x, 2)) end
local function define(x, f) inst[x] = f end
local function nop() end
local function func(x) return inst[x] or nop end
local function exec(x) return func(x)() end
local function popstr()
    local str = {}
    while true do
        local c = pop()
        if c == fromstr(";") then break end
        table.insert(str, 1, c)
    end
    return str
end
local function mergefuncs(fns)
    -- allow tail call
    local last = table.remove(fns) or nop
    return function()
        for _, f in ipairs(fns) do f() end
        return last()
    end
end
local function compile(str)
    local fns = {}
    for i, c in ipairs(str) do fns[i] = func(c) end
    return mergefuncs(fns)
end

local function defstr(x, f) define(fromstr(x), f) end
defstr('#', function() push(0) end)
defstr('+', function() push(pop()+pop()) end)
defstr('-', function() local x = pop() push(pop() - x) end)
defstr('~', function() local x = pop() push(x == 0 and 8 or log2(x)) end)
defstr('.', function() output(pop()) end)
defstr(',', function() push(input()) end)
defstr('^', function() enqueue(top()) end)
defstr('v', function() push(dequeue()) end)
defstr(':', function() push(top()) end)
defstr('!', function() local sym = pop() define(sym, compile(popstr())) end)
defstr('?', function() return exec(pop()) end)
defstr(';', function() push(fromstr(";")) end)
for i = 0, 9 do defstr(tostring(i), function() push(pop()*10+i) end) end

local f = assert(io.open(assert(arg[1], "missing argument"), "r"), "no such file")
local buffered
local function readcode()
    local c
    if buffered then
        c = buffered
        buffered = nil
    else
        c = f:read(1)
        if not c then return end
    end

    -- ignore newline at end of file
    if c == "\n" then
        buffered = f:read(1)
        if not buffered then return end
    end

    return c
end

while true do
    local c = readcode()
    if not c then break end
    exec(fromstr(c))
end
