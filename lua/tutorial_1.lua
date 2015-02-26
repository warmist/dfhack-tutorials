local gui=require 'gui'
local widgets=require 'gui.widgets'


tutorial_screen=defclass(tutorial_screen,gui.FramedScreen)
tutorial_screen.ATTRS{
	frame={t=10,l=10,b=10,r=10}
}
function tutorial_screen:init(args)
	self:addviews{
		widgets.Label{text={{text="Info:"},{text=self:callback("get_tooltip")}},frame={t=1,l=1}},
		widgets.List{view_id="my_list",choices={{text='a',tooltip="this is 'a'"},{text='b',tooltip="second leter of alphabet"},{text='c',tooltip="3rd choice"}},frame={t=3,l=1}},
		widgets.Label{
			text={{text="Exit",key="LEAVESCREEN",frame={b=1,l=1},key_sep="()",on_activate=self:callback('dismiss')}}
		}
	}
end
function tutorial_screen:get_tooltip()
	local _,choice=self.subviews.my_list:getSelected()
	return choice.tooltip
end
tutorial_screen{}:show() --construct and show our screen
