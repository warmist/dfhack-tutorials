---
layout: post
title: Making stuff do stuff
---

In last post our little project did almost nothing - it quit if we pressed "esc". Let's try making something more interactive.

##Last lesson

Some explantaion about this line:

```lua
widgets.Label{
	text={ {text="Exit",key="LEAVESCREEN",frame={b=1,l=1},key_sep="()",on_activate=self:callback('dismiss')} }
}
```
It has a lot of strange stuff, but for now let's focus on ``on_activate=self:callback('dismiss')``. That is the only
functionality it had in last lesson. It says that when it's activated (for label that is by keypress) call a function.
The ``self:callback('dismiss')`` basically returns a function with first parameter as ``self`` in our case that is the
screen we are creating.

##New stuff

If you look over the index for dfhack help [widgets section](https://github.com/DFHack/dfhack/blob/develop/Lua%20API.rst#gui-widgets)
you will see this list of built-in widgets:

* Widget - every other widget is based on this
* Panel - a grouping box for other widgets
* Pages - switch between pages with different widgets
* EditField - text input field
* Label - a mutifunctional text output or button widget
* List - a list of items
* FilteredList - a list with filter input.

Depending on what you want by mixing and matching you can achieve almost anything you want. For more detailed callbacks 
and how to use them refer to individual documentation.

##When it's not enough
Sometimes there is no widget that can do what you want. In that case you have two options: either do it manually (by 
overwriting ``onRenderBody`` and ``onInput``) or making a custom widget. In this case i'll show how to make custom widget.
This has an advantage that you can later reuse the widget and even submit to dfhack so it can be integrated and other people
could use it.

Let's say i want to create a multiline input field. There already is an "EditField" but it does not allow entering more than one line of text. So let's create one that does. I'll call it ``TextField``.

We'll start by some setup code:
```lua
-- required part
local gui=require 'gui'

-- a bit to allow us later move this into gui.widgets
local widgets=require "gui.widgets"
local Widget=widgets.Widget

-- the widget itself
TextField = defclass(TextField, Widget)
```

The last line creates a new class. Currently that class has all the functions and variables from ``Widget``. So now we extend it to our needs.

```lua
TextField.ATTRS{
    text = '', -- this will be currently editable line
    text_pen = DEFAULT_NIL, -- color/background etc of text
    on_char = DEFAULT_NIL, -- callback when each character is added
    on_change = DEFAULT_NIL, -- callback when line changes
    on_submit = DEFAULT_NIL, -- callback when "secondary select" is used to indicate finish
}
```

If you look at ``hack/lua/gui/widget.lua`` you'll see that this is identical to ``EditField``. That is because I want it to feel very similar also it is easier to build upon already created things.

The ``text`` variable will be used a bit differently. Because i think it will take a lot of unnecessary spliting of text into lines each frame, I'll keep the text as lines, and edit only the last one. That complicates editing a bit, but simplifies the rendering. That is done once at the "birth" of each ``TextField``. For that we use ``init`` function. It exists in all classes created with ``defclass`` function.

```lua
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
```

Now last paragraph mentioned two things: editing (or key input really) and rendering. That is the base of each widget (or really of any interactive computer thing, showing and reacting). Let's start with rendering. Widgets use ``onRenderBody`` function for that. It get's passed a strange thing called ``[Painter](https://github.com/DFHack/dfhack/blob/develop/Lua%20API.rst#painter-class)``. This object simplifies drawing a lot, and we usually call it ``dc`` for "drawing context".

```lua
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
```

Next (and almost finally) we have input. For that we use ``onInput`` function.

```lua
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
```

And finally I really wanted to test it out. So let's add a quick test screen with our new widget.

```lua
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
```

That is it. Now you have a new widget that you can use anywhere else. Also this can be extended to support multiple colors or more inteligent cursor but that it's for now.

And now for how it looks:

![picture of dwarven news](http://i.imgur.com/FkbkuUY.png "Dwarven News")
