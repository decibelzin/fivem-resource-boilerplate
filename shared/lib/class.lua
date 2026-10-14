--- Minimal OOP helper. Instances are created by calling the class: `local p = Player(...)`.
--- Constructor: define `function MyClass:__init(...)`.
--- Inheritance: `Child = class(Parent)`.
---@param parent table|nil
---@return table
function class(parent)
    local cls = {}
    cls.__index = cls

    setmetatable(cls, {
        __index = parent,
        __call = function(_, ...)
            local instance = setmetatable({}, cls)
            if (instance.__init) then
                instance:__init(...)
            end
            return instance
        end,
    })

    return cls
end
