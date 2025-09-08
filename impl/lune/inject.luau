local env = {}

local pattern = "zune %d+%.%d+%.%d+%-?[%.%w%d]*%+%d+%.(%d+)"

local luauVersion = string.match(_VERSION, pattern)
env._VERSION = "Lune 0.10.2+" .. luauVersion
env.warn = function(...)
    print("Warning: ", ...)
end

return {
    env = env,
    inject = function(target)
        for key, value in env do
            target[key] = value
        end
    end,
    injectLevel = function(level: number?)
        local target = getfenv(level);
        for key, value in env do
            target[key] = value
        end
    end,
}