-- required part
local gui=require 'gui'

-- a bit to allow us later move this into gui.widgets
local widgets=require "gui.widgets"
local Widget=widgets.Widget

-- the widget itself
TextField = defclass(TextField, Widget)
-- default variables
TextField.ATTRS{
    text = '', -- this will be currently editable line
    text_pen = DEFAULT_NIL, -- color/background etc of text
    on_char = DEFAULT_NIL, -- callback when each character is added
    on_change = DEFAULT_NIL, -- callback when line changes
    on_submit = DEFAULT_NIL, -- callback when "secondary select" is used to indicate finish
}
--setup of the widget
function TextField:init(args)
    --reformat data a bit, split string into lines or if already lines leave them
    if type(self.text)=="string" then
        local lines={} -- an empty lines list

        --this splits up input text (in self.text) to be different lines
        local dist=0 --a counter used to find last part of text that is left after all lines
        for line in string.gmatch(self.text, "([^\n]+)\n") do
            table.insert(lines,line)
            dist=dist+#line+1
        end
        if #lines>0 then
            table.insert(lines,string.sub(self.text,dist+1)) -- the leftover
        else
            table.insert(lines,self.text)
        end
        self.text=lines
    end
end
-- the rendering of the widget
function TextField:onRenderBody(dc)
    dc:pen(self.text_pen or COLOR_LIGHTCYAN):fill(0,0,dc.width-1,dc.height-1) --first clear everything
    --now draw each line
    for i,v in ipairs(self.text) do
        if i==#self.text then --last line is special, it where we input
            -- add blinky cursor to current line
            local cursor = '_'
            if not self.active or gui.blink_visible(300) then
                cursor = ' '
            end
            local txt = v .. cursor
            -- show an arrow and clip text to fit in screen
            if #txt > dc.width then
                txt = string.char(27)..string.sub(txt, #txt-dc.width+2)
            end
            dc:string(txt)
        else
            if #v > dc.width then
                -- clip each line and show an arrow
                --TODO(warmist): maybe we should have some better way of clipping
                --  multiline text
                dc:string(string.char(27)..string.sub(v, #v-dc.width+2))
            else
                dc:string(v)
            end
            dc:seek(0,i) -- move to start of next line
        end
    end
end
-- the input handling for textfield
function TextField:onInput(keys)
    if keys.SELECT then --usually enter, we'll use it for newline
        table.insert(self.text,"") -- just add new empty line at the end
        return true
    elseif keys._STRING then
        local old = self.text[#self.text] -- the last line is one we are editing
        if keys._STRING == 0 then --this is backspace
            if old~="" then --if not empty, delete one char from the end
                self.text[#self.text] = string.sub(old, 1, #old-1)
            elseif #self.text>0 then --if we have lines, and current is empty...
                table.remove(self.text) --...remove one from the end
            end
        else
            local cv = string.char(keys._STRING) --just text key
            if not self.on_char or self.on_char(cv, old) then --if there is a callback and it returns okay...
                self.text[#self.text] = old .. cv --... add that char to the end of last string
            end
        end
        local new_line=self.text[#self.text]
        if self.on_change and new_line ~= old then --check if last line changed and...
            self.on_change(new_line, old) --... call callback if it exists
        end
        return true
    elseif self.on_submit and keys.SEC_SELECT then
        self.on_submit(self.text) --finaly if we press "SEC_SELECT" (usually shift+enter) we call submit callback
        return true
    end
end

--the rest is testing
test_screen=defclass(test_screen,gui.FramedScreen)

function test_screen:init()
    self:addviews{
        TextField { --in real use (if this is added to widgets) this should be widgets.TextField
            text={"a","b","==="}, --our text, we could have written it as "a\nb\n===" or as lua multiline text with double '['
            frame={t=1,b=1,l=1,r=1},  --our widget position and layout
            on_submit=self:callback("dismiss")  -- finally a way to exist the screen
            }
    }
end

test_screen{}:show()
