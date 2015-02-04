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

Let's say i want to create a compass widget. 

<<TODO>>
