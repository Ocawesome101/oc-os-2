-- Shell API for OC-OS

prompt = {"__USER__", "@", "__HOSTNAME__", ":", "__DIR__", "#$"}

function renderPrompt(p)
    local prompt = p or rtn.prompt

    for i=1, #prompt, 1 do
        if prompt[i] == "__USER__" then
            write(_G.__user__)
        elseif prompt[i] == "__HOSTNAME__" then
            write(_G.__hostname__)
        elseif prompt[i] == "__DIR__" then
            write(_G.__currentDir__)
        elseif prompt[i] == "#$" then
            if __user__ == "root" and __uid__ == 0 then
                write("#")
            else
                write("$")
            end
        else
            write(prompt[i])
        end
    end
end
