---
layout: index
---

# Gui programming on dfhack

## Intro

So there is some strange notion that gui programming with dfhack is very hard. Everyone is inventing all these insanely hard raw tricks and trying to workaround df all the time but IMHO simplest system that is easy and fun to use is never used. Let's try to fix that.

## Setup

### Basics

Screen using scripts are not magical in any way and use same '.lua' scripts so let's create one. I called mine "tutorial.lua" and saved in df/hack/scripts folder. As you probably know we can invoke it from dfhack console by simply typing `tutorial` . Currently it does nothing, so let's fix that by adding first line into "tutorial.lua".

```lua
print('tutorial file running okay!')
```

After typing `tutorial` into dfhack console the 'tutorial file running okay!' should appear.

### Tools of trade(destruction)

Now because we will be working on gui we need a toolkit for that. Fortunately for us Angavrilov made huge toolkit just for that. It includes many different useful things. So let's pull that in.

```lua	
local gui=require 'gui'
```

Now because we will be making a screen it's best to thing about that in objective manner. Let's create a new class. Syntax for it might be strange but it has a reason.

```lua
tutorial_screen=defclass(tutorial_screen,gui.FramedScreen)
```

Tutorial_screen is the name of our class and we indicate that we want to inherit all the functionality from a snazy "FramedScreen". This allows to skip a LOT of boring setup and just do fun stuff. 

Now there are a few ways to draw stuff. Simpler way makes you write more code, but is more flexible. That way is needed if you want to do something fancy. The idea is to add your own render method. The other way to draw is by using pre-made widgets. That way you define layout and functionality like in higher level languages by using buttons and labels and so on. To use this we need another 'require' so put this after 'local gui...' line

```lua
local widgets=require 'gui.widgets'
```

Now the layout and structure of said widgets must (you can do it later, but it's rare that it's needed) happen when constructing our object. For that let's use "init" method.

```lua
function tutorial_screen:init(args)
	self:addviews{
		widgets.Label{text="Info:",frame={t=1,l=1}},
		widgets.Label{text="Other text: Text Text text",frame={t=2,l=2}},
		widgets.List{choices={'a','b','c'},frame={t=3,l=1}},
	}
end
```

Now finally let's show this screen.

```
tutorial_screen{}:show() --construct and show our screen
```

One problem though. We can't exit this screen. If you are ever stuff in such screen just type "devel/pop-screen". Be careful, pop'ing df native screens can crash or exit from df.

Finally let's add a way to exit the screen in a normal way. Again there are more ways to do this but this seems like easiest to me :). In the `self:addviews{..." before closing "}` add these lines.

```lua
widgets.Label{
	text={{text="Exit",key="LEAVESCREEN",frame={b=1,l=1},key_sep="()",on_activate=self:callback('dismiss')}}
}
```