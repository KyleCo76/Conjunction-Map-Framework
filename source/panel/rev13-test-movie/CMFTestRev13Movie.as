package
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;

   // Original fixture. All visible words are supplied by the provider's tables.
   public class CMFTestRev13Movie extends MovieClip
   {
      private var map:Object;
      private var drawingId:String;
      private var words:Object;
      private var focused:Boolean = false;
      private var label:TextField;
      private var regionButton:TextField;
      private var releaseButton:TextField;
      private var helpLabel:TextField;
      private var rows:Array = [];
      private var selected:int = 0;
      private var selectedId:Number = -1;
      private var litId:Number = -1;
      private var ticks:int = 0;
      private var lastPins:Object;

      public function CMFTestRev13Movie()
      {
         super();
         graphics.beginFill(0x18232F,0.95);
         graphics.drawRect(0,0,360,360);
         graphics.endFill();
         label = new TextField();
         label.width = 344;
         label.height = 220;
         label.defaultTextFormat = new TextFormat("$NormalFont",14);
         label.x = 8;
         label.y = 8;
         label.textColor = 0xFFFFFF;
         label.selectable = false;
         label.mouseEnabled = false;
         label.wordWrap = true;
         addChild(label);
         regionButton = button(232);
         releaseButton = button(264);
         helpLabel = button(296);
         helpLabel.height = 56;
         helpLabel.wordWrap = true;
         addEventListener(MouseEvent.CLICK,pick);
         addEventListener(Event.ENTER_FRAME,refresh);
         addEventListener(Event.REMOVED_FROM_STAGE,release);
         addEventListener(Event.ADDED_TO_STAGE,resume);
      }

      private function button(y:Number) : TextField
      {
         var field:TextField = new TextField();
         field.defaultTextFormat = new TextFormat("$NormalFont",14);
         field.x = 8;
         field.y = y;
         field.width = 344;
         field.height = 28;
         field.textColor = 0x99FFFF;
         field.selectable = false;
         field.mouseEnabled = false;
         addChild(field);
         return field;
      }

      public function cmfScreen(data:Object, liveMap:Object) : Boolean
      {
         drawingId = String(data.id);
         map = liveMap;
         words = data.text;
         // A redraw can move the loader to a new holder: refresh again and re-read the pins (area change).
         addEventListener(Event.ENTER_FRAME,refresh);
         lastPins = null;
         snapshot();
         return true;
      }

      private function note(name:String, value:String) : void
      {
         var GameEventClass:Class = getDefinitionByName("red.core.events.GameEvent") as Class;
         dispatchEvent(new GameEventClass("callGameEvent","OnCMFMovieEvent",[drawingId,name,value],true,true));
      }

      private function snapshot() : void
      {
         if(!map) { return; }
         var pins:Object = map.pins;
         if(pins === lastPins) { return; }
         lastPins = pins;
         rows = [];
         // Id 0 can't be selected or lit, so it isn't listed, nor is a pin the current tab or filters hide. A
         // stable order keeps the list still when the pin snapshot refreshes, and the selection follows its pin id.
         if(pins) { for each(var pin:Object in pins) { if(Number(pin.id) > 0 && pin.shown !== false) { rows.push(pin); } } }
         rows.sortOn(["type","label","id"],[Array.CASEINSENSITIVE,Array.CASEINSENSITIVE,Array.NUMERIC]);
         selected = 0;
         for(var i:int = 0; i < rows.length; ++i) { if(Number(rows[i].id) == selectedId) { selected = i; break; } }
         render();
         note("pins",String(rows.length));
      }

      private function render() : void
      {
         var text:String = String(words.caption) + (focused ? " [*]" : "") + "\n";
         var start:int = Math.max(0,selected - 3);
         for(var i:int = start; i < Math.min(rows.length,start + 8); ++i)
         {
            // Labels can carry the game's own markup (a tinted herb name); the list shows plain words.
            text += (i == selected ? "> " : "  ") + String(rows[i].label || rows[i].type).replace(/<[^>]*>/g,"") + "\n";
         }
         if(!rows.length) { text += String(words.empty) + "\n"; }
         regionButton.text = String(words.region);
         releaseButton.text = String(words.release);
         helpLabel.text = String(words.help);
         label.text = text;
      }

      private function refresh(event:Event) : void
      {
         if(++ticks % 20 == 0) { snapshot(); }
      }

      private function focus(on:Boolean) : void
      {
         if(map) { focused = map.focus(on) && on; map.lockPan(focused); }
         note("focus",focused ? "true" : "false");
         render();
      }

      private function activate() : void
      {
         if(!map || !rows.length) { return; }
         var pin:Object = rows[selected];
         selectedId = Number(pin.id);
         if(litId >= 0 && litId != selectedId) { map.highlightPin(litId,null); }
         litId = selectedId;
         map.center(Number(pin.x),Number(pin.y),Number(map.zoom),0.25);
         map.selectPin(Number(pin.id));
         map.highlightPin(Number(pin.id),{glowColor:65535,glowAlpha:1,pulse:1});
         map.noSpread(Number(pin.id));
         note("picked",String(pin.id));
      }

      private function otherRegion() : void
      {
         if(!map) { return; }
         var area:String = String(map.area).toLowerCase();
         var target:String = area.indexOf("an_skellige") == 0 ? "AN_NMLandNovigrad" : "AN_Skellige_ArdSkellig";
         note("showArea",target);
         map.showArea(target);
      }

      private function pick(event:MouseEvent) : void
      {
         if(!focused) { focus(true); }
         else if(mouseY < 228)
         {
            // Only a click on a listed row picks; the caption and the space below the rows do nothing.
            var line:int = int((label.mouseY - 2) / Math.max(1,label.getLineMetrics(0).height));
            var start:int = Math.max(0,selected - 3);
            var row:int = start + line - 1;
            if(line >= 1 && row < Math.min(rows.length,start + 8))
            {
               selected = row;
               activate();
               render();
            }
         }
         else if(mouseY < 264) { otherRegion(); }
         else { focus(false); }
         event.stopPropagation();
      }

      private function choose(row:int) : void
      {
         if(!rows.length) { return; }
         selected = Math.min(rows.length - 1,Math.max(0,row));
         selectedId = Number(rows[selected].id);
         render();
      }

      private function resume(event:Event) : void
      {
         addEventListener(Event.ENTER_FRAME,refresh);
      }

      private function release(event:Event) : void
      {
         if(map) { map.focus(false); map.lockPan(false); }
         focused = false;
         litId = -1;
         map = null;
         removeEventListener(Event.ENTER_FRAME,refresh);
      }

      public function handleInput(event:Object) : void
      {
         if(!focused || !map) { return; }
         var code:int = int(event.details.code);
         var nav:String = String(event.details.navEquivalent);
         var held:Boolean = event.details.value == "keyHold";
         // A held arrow keeps moving through the list; every other key acts once, on its press.
         if(event.details.value != "keyDown" && !(held && (code == 38 || code == 40 || code == 142 || code == 143 || nav == "up" || nav == "down" || nav == "dpad_up" || nav == "dpad_down"))) { return; }
         if(code == 27 || nav == "escape-gamepad_B") { focus(false); }
         else if(code == 38 || code == 142 || nav == "up" || nav == "dpad_up") { choose(selected - 1); }
         else if(code == 40 || code == 143 || nav == "down" || nav == "dpad_down") { choose(selected + 1); }
         else if(code == 13 || nav == "enter-gamepad_A") { activate(); }
         else if(code == 9 || nav == "gamepad_X") { otherRegion(); }
         event.handled = true;
      }
   }
}
