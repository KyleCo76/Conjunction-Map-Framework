package
{
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.GradientType;
   import flash.display.Loader;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.ColorMatrixFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;

   // Map Quest Insight adapter: the Quest List on CMF's map, as a screen movie (CMF API 13, "Your own movie on
   // the screen"). Our own code, written from Map Quest Insight 2.0's player-facing description; no Map Quest
   // Insight code or class is used. Every word on screen comes from the adapter's script (its string table and
   // the game's own journal words), sent with the quest data on the listen key "mqiadapter.questlist".
   public class MqiAdapterQuestList extends MovieClip
   {
      private static const GOLD:uint = 0xFFD402;
      // Map Quest Insight 2.2.0 values (colours, sizes, places). The panel width does not scale; the row heights and
      // the text sizes scale with the list text size (qmiQjTextSize, default 90).
      private static const PANEL_W:Number = 640;
      private static const HEADER_H:Number = 56;
      private static const QUEST_H:Number = 90;
      private static const FILTER_H:Number = 46;
      private static const ICON_SIZE:Number = 58;
      private static const BOX_SIZE:Number = 22;
      private static const BOX_FILL:Number = 14;
      private static const BOX_OFF_FILL:Number = 18;
      private static const BOX_OFF_COLOR:uint = 0x0B0B0B;
      // Quest Filters rows (Map Quest Insight 2.2.0): the symbol's centre and scale (quest rows use 4.5), the label,
      // and the count's right edge measured from the panel's right edge; the rows run in Map Quest Insight's order,
      // each holding its hide-switch index.
      private static const FILTER_ICON_X:Number = 48;
      private static const FILTER_ICON_SCALE:Number = 2.3;
      private static const FILTER_LABEL_X:Number = 80;
      private static const FILTER_COUNT_RIGHT:Number = 76;
      private static const FILTER_ORDER:Array = [10,8,0,1,2,3,4,5,6,7,9];
      // The Heroes' Pursuits row's symbol (hide index 6) is drawn in grey through this colour matrix, once, into a
      // bitmap (greyCopy): no filter sits on a row picture, whose cached image the game's player does not redraw when
      // the row moves.
      private static const GREY_MATRIX:Array = [0.299,0.587,0.114,0,0,0.299,0.587,0.114,0,0,0.299,0.587,0.114,0,0,0,0,0,1,0];
      private static const PLATE_COLOR:uint = 0x0B0B0B;
      private static const HEAD_TOP:uint = 0x2C2925;
      private static const HEAD_REST:uint = 0x242220;
      private static const TEXT_ON:uint = 0xDCD6C8;
      private static const TEXT_SUB:uint = 0xC4C0B8;
      private static const TEXT_OFF:uint = 0x9C9890;
      private static const ACCENT:uint = 0xC9A452;
      private static const SELECT_FILL:uint = 0x3A2E14;
      private static const BOX_COLOR:uint = 0x8C877E;
      private static const TRACK_COLOR:uint = 0x3C3832;
      private static const RING_COLOR:uint = 0xFF9900;
      private static const TITLE_COLOR:uint = 0xD7B060;
      private static const TAB_ON:uint = 0xF0F0F0;
      private static const TAB_OFF:uint = 0x7E7A74;
      private static const SORT_LABEL:uint = 0xC8C4BC;
      private static const SORT_VALUE:uint = 0xE3D9C4;
      private static const JUST_CHANGED:uint = 0xFFD966;
      private static const REGION_ON:uint = 0xFFD966;
      private static const REGION_OFF:uint = 0xC8C4BC;
      private static const DIVIDER_COLOR:uint = 0x5A4A2A;
      private static const WHITE:uint = 0xFFFFFF;
      private static const OBJ_ON:uint = 0xF0BE38;
      private static const OBJ_OFF:uint = 0xDFDEDE;
      private static const DLC_COLOR:uint = 0xBEBAB2;
      private static const ARROW_COLOR:uint = 0xD8D2C4;
      // Places in map units at text size 100% (the panel's own width, so these do not scale).
      private static const INSET:Number = 20;
      // The footer (round(56 x text size)) sits above the game's own bottom hint row (about 64 units tall, as in
      // Map Quest Insight alone), so the divider is at the bottom minus both.
      private static const GAME_HINTS_H:Number = 64;
      // The bottom key row (Map Quest Insight 2.2.0): labels in the normal font, size 28 at the row scale
      // (0.6 x text size x 1.3), 24 apart, centred and capped to the panel width less 40.
      private static const FOOT_LABEL:uint = 0xDCD6C8;
      private static const FOOT_FONT:Number = 28;
      private static const FOOT_GAP:Number = 24;
      private static const FOOT_SCALE:Number = 0.78;
      // The Objectives prompt sits on the quest row's second line, right-aligned, 14 px left of the distance text
      // (or ending at ROW_RIGHT when there is none); the region text is clipped for it, to 40 px at the least.
      private static const OBJ_PROMPT_GAP:Number = 14;
      private static const REGION_MIN_W:Number = 40;
      // A D-pad press and the arrow-coded twin the game sends after it arrive within this many ms.
      private static const TWIN_MS:int = 30;

      private var dpadDir:String = "";

      private var dpadAt:int = 0;

      private var axisDeclined:Boolean = false;
      // The controller's A, from its press to its release, went to the map: a pin was under the reticle (map.pinAtReticle).
      private var aToMap:Boolean = false;

      // Prompt key names: the keyboard key, then the controller button, then the PlayStation button. The only place
      // that names them, so the game's button pictures can replace the text in promptButton alone.
      private static const PROMPT_KEYS:Object = {"close":["F","LT","L2"],"track":["E","A","Cross"],"region":["H","X","Square"],"sort":["T","RT","R2"],"objs":[">","D-pad Right","D-pad Right"],"fold":["C","Y","Triangle"]};
      // The game's button pictures (CMF API 17, map.cmfMakeButton): the controller button's navigation name and the
      // keyboard key code per prompt, the same ones handleInput takes. On an older CMF, or when the map gives no
      // button, the text prompts above stay. BUTTON_FONT is the size the game's button draws its word at; the
      // pictures are scaled so the word matches the text prompt's size.
      private static const PROMPT_NAV:Object = {"close":["gamepad_L2",70],"track":["enter-gamepad_A",69],"region":["gamepad_X",72],"sort":["gamepad_R2",84],"objs":["dpad_right",39],"fold":["gamepad_Y",67]};
      private static const BUTTON_FONT:Number = 28;
      // The Objectives prompt on the keyboard: the key cap's text gives way to a filled right triangle this share of
      // the cap's height, in the cap's text colour.
      private static const CAP_TRIANGLE:Number = 0.42;
      private static const OBJECT_H:Number = 22;
      private static const OBJ_BOX:Number = 13;
      private static const OBJ_BOX_X:Number = 173;
      private static const OBJ_TEXT_X:Number = 190;
      private static const ICON_CX:Number = 62;
      private static const LEVEL_X:Number = 96;
      private static const NAME_X:Number = 164;
      private static const ROW_RIGHT:Number = 612;
      private static const COUNT_RIGHT:Number = 572;
      private static const ARROW_X:Number = 596;
      private static const SHADOW_ALPHAS:Array = [0.4,0.28,0.18,0.1,0.05];
      private static const ROW_CAT:int = 1;
      private static const ROW_QUEST:int = 2;
      private static const ROW_OBJECTIVE:int = 3;
      private static const ROW_REGION:int = 4;
      private static const ROW_FILTER:int = 6;

      private var map:Object;
      private var drawingId:String = "";
      private var boxW:Number = PANEL_W;
      private var boxH:Number = 1080;
      private var data:Object;
      private var lastSeq:Number = -1;
      private var lastOpen:Number = -1;
      private var opened:Boolean = false;
      private var focused:Boolean = false;

      private var quests:Array = [];
      private var rows:Array = [];
      private var selected:int = 0;
      private var top:int = 0;
      private var sortMode:int = 0;
      private var sortChanged:Boolean = false;
      // Quests Available and Quest Filters start folded, as in Map Quest Insight's own list.
      private var folded:Object = {"avail":true,"filters":true};
      private var expanded:Object = {};
      private var filters:Array = [];
      private var thisRegion:Boolean = false;
      private var touched:Boolean = false;
      private var lastArea:String = "";
      private var focusAt:int = 0;
      // The device the prompts show: the game's input manager when it can be read, else what the keys came from.
      private var pad:Boolean = false;
      private var playStation:Boolean = false;
      private var managerClass:Class = null;
      private var managerTried:Boolean = false;
      private var managerKnown:Boolean = false;
      // Quests whose objectives the player closed (Left, or Right again); the selected quest shows them otherwise.
      private var closedObjs:Object = {};
      // The game buttons on show, by place ("foot0" to "foot3", "row_objs", "row_fold"): {key, clip}; key names the
      // prompt, its word and the device, so a change of any makes a new button. The fold and Objectives prompts keep
      // a place each, so moving between a header and a quest row only shows one and hides the other.
      private var buttons:Object = {};
      // The selected row's prompt on show (set by render): its row, its id ("objs" or "fold") and its box, so a click
      // inside the box does what the key does (2.5.2).
      private var promptRow:int = -1;
      private var promptId:String = "";
      private var promptBox:Rectangle = null;

      private var pinsRef:Object;
      private var pinById:Object = {};
      private var dist:Object = {};
      private var lit:Array = [];
      private var pendingPick:int = -1;
      private var pendingObj:int = -1;
      private var pendingQa:Boolean = false;
      private var swapAt:int = 0;
      private var pendingHome:Boolean = false;
      private var switched:Boolean = false;
      private var restRow:int = -1;
      private var restAt:int = 0;
      private var restDone:Boolean = true;
      private var drawn:int = 0;
      // Until this time (getTimer) the list hides the map's panels again on every frame: a filter save rebuilds the
      // map's pins (the game's UpdateData), which shows the legend again a frame or more after the list's new value.
      private var rehideUntil:int = 0;

      private var bg:Sprite;
      private var bar:Sprite;
      private var edge:Sprite;
      private var title:TextField;
      private var counter:TextField;
      private var levelLine:TextField;
      private var sortLine:TextField;
      private var regionLine:TextField;
      private var hints:Array = [];
      private var countBold:String = "";
      private var slots:Array = [];
      private var scale:Number = 0.9;

      public function MqiAdapterQuestList()
      {
         super();
         bg = new Sprite();
         addChild(bg);
         bar = new Sprite();
         bar.mouseEnabled = false;
         addChild(bar);
         title = field(false);
         counter = field(false);
         levelLine = field(false);
         sortLine = field(false);
         regionLine = field(true);
         hints = [field(true),field(true),field(true),field(true)];
         doubleClickEnabled = true;
         addEventListener(MouseEvent.CLICK,onClick);
         addEventListener(MouseEvent.DOUBLE_CLICK,onDoubleClick);
         addEventListener(MouseEvent.MOUSE_WHEEL,onWheel);
         addEventListener(Event.ADDED_TO_STAGE,onAdded);
         addEventListener(Event.REMOVED_FROM_STAGE,onRemoved);
         visible = false;
      }

      private function field(right:Boolean) : TextField
      {
         var f:TextField = new TextField();
         f.selectable = false;
         f.mouseEnabled = false;
         f.multiline = false;
         f.wordWrap = false;
         f.autoSize = right ? TextFieldAutoSize.RIGHT : TextFieldAutoSize.NONE;
         addChild(f);
         return f;
      }

      // CMF calls this after loading and again on every redraw: a new listen value, an area change or a theme
      // send. The list keeps its own state across calls; only a new open number opens it.
      public function cmfScreen(entry:Object, liveMap:Object) : Boolean
      {
         var listened:Object = entry ? entry.listen : null;
         drawingId = String(entry.id);
         map = liveMap;
         // An area change keeps the movie but releases its focus, pan lock and highlights: take them again.
         if(opened && map && curMap() != lastArea)
         {
            lit = [];
            pinsRef = null;
            hidePanelsAgain();
            if(focusAt == 0) { takeFocus(); }
         }
         if(map) { lastArea = curMap(); }
         if(!opened && pendingHome && map && curMap() == String(data.homeMap)) { goHome(); }
         if(entry.number)
         {
            if(Number(entry.number.height) > 0) { boxH = Number(entry.number.height); }
         }
         addEventListener(Event.ENTER_FRAME,onFrame);
         if(listened && Number(listened.seq) != lastSeq)
         {
            lastSeq = Number(listened.seq);
            take(listened);
         }
         placeCorner();
         if(opened && map && focused) { map.lockPan(!conf("pan")); }
         return true;
      }

      // Velen and Novigrad share one map, which the game names either way.
      private static function mapOf(area:String) : String
      {
         return area == "AN_Velen" ? "AN_NMLandNovigrad" : area;
      }

      private function curMap() : String
      {
         return map ? mapOf(String(map.area)) : "";
      }

      private function conf(key:String) : Boolean
      {
         return data && data.conf && (data.conf[key] == true || Number(data.conf[key]) == 1);
      }

      private function confNum(key:String, fallback:Number) : Number
      {
         var value:Number = data && data.conf ? Number(data.conf[key]) : NaN;
         return isNaN(value) ? fallback : value;
      }

      // Quest list corner (conf.corner, stage units, 0 = the left edge): the list moves right by it, and a mask keeps
      // anything it draws left of its own x (a slide-in or a wide label) from showing left of the corner.
      private function placeCorner() : void
      {
         var offset:Number = Math.max(0,confNum("corner",0));
         x = offset;
         if(offset > 0)
         {
            if(!edge)
            {
               edge = new Sprite();
               edge.mouseEnabled = false;
               addChild(edge);
            }
            // Only the panel and its shadow strips (5 px to the right), redrawn on every call as the height can change.
            edge.graphics.clear();
            edge.graphics.beginFill(0,1);
            edge.graphics.drawRect(0,0,boxW + 5,boxH);
            edge.graphics.endFill();
            mask = edge;
         }
         else
         {
            mask = null;
            if(edge && edge.parent) { removeChild(edge); }
            edge = null;
         }
      }

      private function word(key:String) : String
      {
         return data && data.words && data.words[key] != null ? String(data.words[key]) : "";
      }

      private function wordList(key:String) : Array
      {
         return word(key).split("|");
      }

      private function take(listened:Object) : void
      {
         var first:Boolean = data == null;
         var keepId:Number = selectedQuestId();
         var keepKey:String = selectedKey();
         var keepIndex:int = rows.length > 0 ? selected : -1;
         var i:int = 0;
         data = listened;
         quests = data.quests is Array ? data.quests as Array : [];
         // The first value of an opening names the open number to count from; the list opens only when it grows.
         if(first && lastOpen < 0) { lastOpen = 0; }
         if(first || Number(data.open) > lastOpen)
         {
            sortMode = int(confNum("sort",0));
            sortChanged = false;
            thisRegion = conf("thisRegion");
            touched = false;
            filters = [];
            var sent:Array = data.filters is Array ? data.filters as Array : [];
            for(i = 0; i < 11; i++) { filters.push(i < sent.length && (sent[i] == true || Number(sent[i]) == 1)); }
            dist = {};
            pinsRef = null;
         }
         availDistances();
         scale = confNum("textSize",90) / 100;
         // Every value while the list is open: hide the panels again now and for the next second (see rehideUntil).
         if(opened) { rehide(); }
         if(Number(data.open) > lastOpen)
         {
            lastOpen = Number(data.open);
            open(int(Number(data.at)));
            return;
         }
         build(keepId,keepKey,keepIndex);
         render();
      }

      // Map Quest Insight measures the Quests Available rows itself (QMI_qaD, -1 off the player's map); kept once
      // per opening, like the quests' own distances, so a region switch does not lose them.
      private function availDistances() : void
      {
         var a:Object = null;
         for each(a in available())
         {
            if(Number(a.d) >= 0 && dist[String(a.i)] == null) { dist[String(a.i)] = Number(a.d); }
         }
      }

      private function available() : Array
      {
         return data && data.available is Array ? data.available as Array : [];
      }

      private function selectedQuestId() : Number
      {
         if(selected >= 0 && selected < rows.length && rows[selected].q) { return Number(rows[selected].q.i); }
         return -1;
      }

      // ---- open and close ----

      private function open(at:int) : void
      {
         opened = true;
         switched = false;
         pendingHome = false;
         pendingPick = -1;
         pendingObj = -1;
         pendingQa = false;
         expanded = {};
         closedObjs = {};
         visible = true;
         hidePanelsAgain();
         // Start quest sections folded (qmiQjFoldAll): every section, Quests Available too, at each opening.
         if(conf("foldAll")) { foldAll(); }
         snapshot();
         build(at >= 0 ? at : trackedId());
         followObjectives();
         // The keys come to the list a moment after it opens: taken at once, the list would also take the release
         // of the F that opened it, and CMF's key hints would then miss the next F (launch start B).
         focusAt = getTimer() + 350;
         if(at >= 0) { pick(selected,false); }
         render();
         note("open","1");
      }

      private function foldAll() : void
      {
         var q:Object = null;
         folded = {};
         for each(q in quests) { folded[String(q.cat)] = true; }
         folded["avail"] = true;
         folded["filters"] = true;
      }

      private function close() : void
      {
         if(!opened) { return; }
         opened = false;
         focusAt = 0;
         rehideUntil = 0;
         unlight();
         restDone = true;
         if(map)
         {
            map.lockPan(false);
            map.focus(false);
            if(map.hidePanels is Function) { map.hidePanels(null); }
         }
         focused = false;
         // Map when the list closes (qmiQjClose): 0 back to you, only after a switch the list made; 1 stays.
         if(map && confNum("close",1) == 0 && switched)
         {
            pendingHome = true;
            if(curMap() != String(data.homeMap)) { map.showArea(String(data.home)); note("region",String(data.home)); }
            else { goHome(); }
         }
         switched = false;
         visible = false;
         bg.graphics.clear();
         note("open","0");
      }

      // CMF brings the hidden panels back on an area change, and the game's own pin build (UpdateData, run again on a
      // filter save) shows the legend again: hide them again (nothing on a CMF without hidePanels).
      private function hidePanelsAgain() : void
      {
         if(map && map.hidePanels is Function) { map.hidePanels(["legend","title","hubBar"]); }
      }

      private function rehide() : void
      {
         hidePanelsAgain();
         rehideUntil = getTimer() + 1000;
      }

      private function takeFocus() : void
      {
         if(!map) { return; }
         focused = map.focus(true) == true;
         map.lockPan(!conf("pan"));
      }

      private function goHome() : void
      {
         pendingHome = false;
         if(map && map.player) { map.center(Number(map.player.x),Number(map.player.y),Number(map.zoom),0.3); }
      }

      // ---- the map's pins ----

      private function snapshot() : void
      {
         var pins:Object = map ? map.pins : null;
         var pin:Object = null;
         if(!pins || pins === pinsRef) { return; }
         pinsRef = pins;
         pinById = {};
         for each(pin in pins)
         {
            if(Number(pin.id) > 0 && !pinById[String(pin.id)]) { pinById[String(pin.id)] = pin; }
         }
         measure();
      }

      // Distances are measured on the player's own map, once per opening, to each quest's nearest marker.
      private function measure() : void
      {
         var q:Object = null;
         var best:Number = NaN;
         var d:Number = NaN;
         var id:Object = null;
         var pin:Object = null;
         if(!map || !map.player || curMap() != String(data.homeMap)) { return; }
         for each(q in quests)
         {
            best = NaN;
            for each(id in q.pins)
            {
               pin = pinById[String(id)];
               if(pin)
               {
                  d = Math.sqrt(Math.pow(Number(pin.x) - Number(map.player.x),2) + Math.pow(Number(pin.y) - Number(map.player.y),2));
                  if(isNaN(best) || d < best) { best = d; }
               }
            }
            if(!isNaN(best)) { dist[String(q.i)] = best; }
         }
      }

      private function questPins(q:Object, objective:int) : Array
      {
         var list:Array = [];
         var o:Object = null;
         var id:Object = null;
         var source:Array = q.pins as Array;
         if(objective >= 0 && q.objs is Array)
         {
            for each(o in q.objs) { if(int(o.o) == objective) { source = o.pins as Array; } }
         }
         for each(id in source)
         {
            if(pinById[String(id)] && pinById[String(id)].shown !== false) { list.push(pinById[String(id)]); }
         }
         return list;
      }

      private function unlight() : void
      {
         var id:Object = null;
         if(map) { for each(id in lit) { map.highlightPin(Number(id),null); } }
         lit = [];
      }

      // Picking a quest rings its markers and centres on them; a quest of another map switches the map
      // (Quests in other regions, qmiQjOtherRegions 1 or 2) and is picked again once its markers are ready.
      private function pick(row:int, switchOk:Boolean, objective:int = -2) : void
      {
         var r:Object = row >= 0 && row < rows.length ? rows[row] : null;
         var found:Array = null;
         var pin:Object = null;
         if(!r || !r.q || !map) { return; }
         snapshot();
         if(objective == -2) { objective = r.type == ROW_OBJECTIVE ? int(r.o.o) : -1; }
         found = r.q.avail ? availPins(r.q) : questPins(r.q,objective);
         if(!found.length && objective >= 0) { found = questPins(r.q,-1); }
         if(!found.length)
         {
            if(switchOk && confNum("other",1) > 0 && String(r.q.map) != "" && String(r.q.map) != curMap())
            {
               pendingPick = int(r.q.i);
               pendingObj = objective;
               switched = true;
               note("region",String(r.q.area));
               map.showArea(String(r.q.area));
            }
            else if(r.q.avail && String(r.q.map) == curMap() && conf("centre"))
            {
               map.center(Number(r.q.x),Number(r.q.y),Number(map.zoom),0.3);
            }
            return;
         }
         unlight();
         for each(pin in found)
         {
            map.highlightPin(Number(pin.id),{"glowColor":r.q.tracked ? GOLD : 0xFFFFFF,"glowAlpha":1,"pulse":1});
            map.noSpread(Number(pin.id));
            lit.push(Number(pin.id));
         }
         pin = found[0];
         if(conf("centre")) { map.center(Number(pin.x),Number(pin.y),Number(map.zoom),0.3); }
         map.selectPin(Number(pin.id));
      }

      // A Quests Available row's "!" marker: the map's pin at the row's place (QMI_qaX, QMI_qaY) on its own map.
      private function availPins(q:Object) : Array
      {
         var pin:Object = null;
         var best:Object = null;
         var d:Number = NaN;
         var bestD:Number = 3;
         if(String(q.map) != curMap()) { return []; }
         for each(pin in pinById)
         {
            if(pin.shown === false) { continue; }
            d = Math.sqrt(Math.pow(Number(pin.x) - Number(q.x),2) + Math.pow(Number(pin.y) - Number(q.y),2));
            if(d < bestD) { bestD = d; best = pin; }
         }
         return best ? [best] : [];
      }

      private function onFrame(event:Event) : void
      {
         var pins:Object = null;
         var device:int = 0;
         if(!map || !opened) { return; }
         device = managerDevice();
         managerKnown = device >= 0;
         if(managerKnown) { setDevice(device > 0,device == 2); }
         if(rehideUntil > 0)
         {
            hidePanelsAgain();
            if(getTimer() >= rehideUntil) { rehideUntil = 0; }
         }
         dressButtons();
         if(focusAt > 0 && getTimer() >= focusAt)
         {
            focusAt = 0;
            if(!focused) { takeFocus(); render(); }
         }
         pins = map.pins;
         if(pins && pins !== pinsRef && (pins as Array).length > 0)
         {
            // New pins: the map ran its pin build again, which shows the legend again.
            rehide();
            snapshot();
            if(pendingPick >= 0)
            {
               build(pendingPick);
               pendingPick = -1;
               pick(selected,false,pendingObj);
               pendingObj = -1;
               // A Quests Available row picked on another map: its marker is set once its map shows.
               if(pendingQa && rows[selected] && rows[selected].q && rows[selected].q.avail) { note("qaPick",String(rows[selected].q.gv)); }
               pendingQa = false;
               render();
            }
            else { render(); }
         }
         // Switch while browsing (qmiQjOtherRegions 2): about 0.6 s on a row; on this map, centring follows the
         // selection after a short rest in every mode.
         if(!restDone && selected == restRow && getTimer() - restAt >= (needsSwitch(selected) ? 600 : 250))
         {
            restDone = true;
            pick(selected,confNum("other",1) == 2);
         }
      }

      private function needsSwitch(row:int) : Boolean
      {
         var r:Object = row >= 0 && row < rows.length ? rows[row] : null;
         return r && r.q && map && String(r.q.map) != "" && String(r.q.map) != curMap();
      }

      // ---- the rows ----

      private function trackedId() : int
      {
         var q:Object = null;
         for each(q in quests) { if(q.tracked) { return int(q.i); } }
         return -1;
      }

      private function shownQuest(q:Object) : Boolean
      {
         // Quests Available follows only "Only this region"; Map Quest Insight's hide switches leave it as it is.
         if(q.avail) { return !(thisRegion && String(q.map) != String(data.homeMap)); }
         if(q.tracked) { return true; }
         if(thisRegion && String(q.map) != String(data.homeMap)) { return false; }
         // Until a filter row is changed in this opening, Map Quest Insight's own answer decides.
         if(!touched) { return !(q.hid == true || Number(q.hid) == 1); }
         if(filters[int(q.fk)]) { return false; }
         if(q.deadly && filters[9]) { return false; }
         return true;
      }

      private function compare(a:Object, b:Object) : int
      {
         var x:Number = NaN;
         var y:Number = NaN;
         if(a.tracked != b.tracked) { return a.tracked ? -1 : 1; }
         switch(sortMode)
         {
            case 0:
               x = dist[String(a.i)] != null ? Number(dist[String(a.i)]) : Infinity;
               y = dist[String(b.i)] != null ? Number(dist[String(b.i)]) : Infinity;
               if(x != y) { return x < y ? -1 : 1; }
               break;
            case 1:
               if(int(a.lvl) != int(b.lvl)) { return int(a.lvl) < int(b.lvl) ? -1 : 1; }
               break;
            case 2:
               if(int(a.lvl) != int(b.lvl)) { return int(a.lvl) > int(b.lvl) ? -1 : 1; }
               break;
            case 3:
               x = String(a.name).toLowerCase().localeCompare(String(b.name).toLowerCase());
               if(x != 0) { return x < 0 ? -1 : 1; }
               break;
         }
         return int(a.i) < int(b.i) ? -1 : (int(a.i) > int(b.i) ? 1 : 0);
      }

      // A row's name across rebuilds, so the selection stays on it when objective lists open or close above it.
      private function rowKey(r:Object) : String
      {
         if(!r) { return ""; }
         if(r.q) { return r.type + ":" + String(r.q.i) + (r.o ? ":" + String(r.o.o) : ""); }
         return r.type + ":" + String(r.cat) + ":" + String(r.k);
      }

      // The selected row's key, kept across a rebuild (see build).
      private function selectedKey() : String
      {
         return selected >= 0 && selected < rows.length ? rowKey(rows[selected]) : "";
      }

      // Rebuilds the rows keeping the selection as Map Quest Insight 2.2.0 does after any rebuild (a value sent after a
      // filter save or the pin build, a filter, Only this region, the sort, objectives opening or closing).
      private function buildKept() : void
      {
         build(selectedQuestId(),selectedKey(),selected);
      }

      // The selection after a rebuild (Map Quest Insight 2.2.0): the row with the same key (a quest by its id, a section
      // header by its section, a filter row by its filter); when that row is gone, the same index, clamped to the last
      // row (keepIndex -1: no index to keep, the first row under a leading header). render then scrolls only as far
      // as the selection needs.
      private function build(keepId:Number, keepKey:String = "", keepIndex:int = -1) : void
      {
         var cats:Array = [];
         var byCat:Object = {};
         var q:Object = null;
         var o:Object = null;
         var c:Object = null;
         var list:Array = null;
         var names:Array = wordList("filterNames");
         var i:int = 0;
         rows = [];
         for each(q in quests)
         {
            if(!shownQuest(q)) { continue; }
            if(!byCat[String(q.cat)])
            {
               byCat[String(q.cat)] = [];
               cats.push({"id":int(q.cat),"label":String(q.catLabel)});
            }
            byCat[String(q.cat)].push(q);
         }
         cats.sortOn("id",Array.NUMERIC);
         for each(c in cats)
         {
            list = byCat[String(c.id)];
            list.sort(compare);
            rows.push({"type":ROW_CAT,"label":c.label,"cat":String(c.id),"count":list.length});
            if(folded[String(c.id)]) { continue; }
            for each(q in list)
            {
               rows.push({"type":ROW_QUEST,"q":q});
               if(expanded[String(q.i)] && q.objs is Array)
               {
                  for each(o in q.objs) { rows.push({"type":ROW_OBJECTIVE,"q":q,"o":o}); }
               }
            }
         }
         if(!quests.length) { rows.push({"type":ROW_CAT,"label":word("empty"),"cat":"","count":-1}); }
         // Quests Available (with Quests not started yet on): a section of its own after the quests, in the list's sort.
         list = [];
         for each(q in available()) { if(shownQuest(q)) { list.push(q); } }
         if(list.length)
         {
            list.sort(compare);
            rows.push({"type":ROW_CAT,"label":word("available"),"cat":"avail","count":list.length});
            if(!folded["avail"]) { for each(q in list) { rows.push({"type":ROW_QUEST,"q":q}); } }
         }
         // Quest Filters: a section of its own at the end, holding Only this region and the filter rows.
         rows.push({"type":ROW_CAT,"label":word("filtersTitle"),"cat":"filters","count":-1});
         if(!folded["filters"])
         {
            rows.push({"type":ROW_REGION});
            for(i = 0; i < FILTER_ORDER.length; i++) { rows.push({"type":ROW_FILTER,"k":FILTER_ORDER[i],"label":FILTER_ORDER[i] < names.length ? names[FILTER_ORDER[i]] : ""}); }
         }
         selected = -1;
         for(i = 0; i < rows.length; i++)
         {
            if(rows[i].type == ROW_QUEST && Number(rows[i].q.i) == keepId) { selected = i; break; }
         }
         if(keepKey != "") { for(i = 0; i < rows.length; i++) { if(rowKey(rows[i]) == keepKey) { selected = i; break; } } }
         if(selected < 0 && keepIndex >= 0) { selected = Math.max(0,Math.min(keepIndex,rows.length - 1)); }
         if(selected < 0)
         {
            selected = 0;
            if(rows.length > 1 && rows[0].type == ROW_CAT) { selected = 1; }
         }
      }

      private function slot(i:int) : Object
      {
         var s:Object = null;
         while(slots.length <= i)
         {
            s = {"left":field(false),"right":field(false),"dist":field(true),"obj":field(true),"lvl":field(false),"icon":new Sprite(),"loader":null,"grey":false,"greyOn":false,"greyPic":null,"url":"","type":-1};
            s.right.width = 330;
            s.lvl.width = 62;
            s.icon.mouseEnabled = false;
            s.icon.mouseChildren = false;
            newLoader(s);
            addChild(s.icon);
            slots.push(s);
         }
         return slots[i];
      }

      private function iconLoaded(event:Event) : void
      {
         var s:Object = null;
         for each(s in slots)
         {
            if(s.loader.contentLoaderInfo == event.target) { fitIcon(s); }
         }
      }

      // Each slot owns one picture holder (s.icon) holding exactly one Loader. A new picture never goes into the old
      // Loader: the old one is closed, unloaded and taken out with everything else in the holder, and a fresh Loader
      // takes its place, so a reused slot can never show its last row's picture behind the new one.
      private function newLoader(s:Object) : void
      {
         var old:Loader = s.loader as Loader;
         if(old)
         {
            old.contentLoaderInfo.removeEventListener(Event.COMPLETE,iconLoaded);
            try { old.close(); } catch(error:Error) { }
            try { old.unload(); } catch(error:Error) { }
         }
         while(s.icon.numChildren > 0) { s.icon.removeChildAt(0); }
         if(s.greyPic)
         {
            try { BitmapData(Bitmap(s.greyPic.getChildAt(0)).bitmapData).dispose(); } catch(error:Error) { }
         }
         s.greyPic = null;
         s.loader = new Loader();
         s.loader.visible = false;
         s.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,iconLoaded,false,0,true);
         s.icon.addChild(s.loader);
         s.greyOn = false;
      }

      // A reused slot starts clean whenever its row type changes: the old picture holder is emptied (a fresh Loader) and
      // its scale, tint and filters are gone, so a filter row never shows a quest badge under its symbol (or the other
      // way round).
      private function resetSlot(s:Object, type:int) : void
      {
         if(s.type == type) { return; }
         s.type = type;
         newLoader(s);
         s.url = "";
         s.icon.scaleX = s.icon.scaleY = 1;
         s.icon.transform.colorTransform = new ColorTransform();
         s.icon.visible = false;
      }

      // The panel's backing: one plate, redrawn from clear on every render, at the spec colour and alpha.
      private function drawPlate() : void
      {
         var g:Object = bg.graphics;
         g.clear();
         g.beginFill(PLATE_COLOR,conf("fullScreen") ? 0.68 : 0.78);
         g.drawRect(0,0,boxW,boxH);
         g.endFill();
      }

      // Map pins and the edge arrow are siblings in CMF's holder: keep the list on top of them (nothing if it cannot).
      private function toFront() : void
      {
         try
         {
            if(parent && parent.getChildIndex(this) < parent.numChildren - 1) { parent.setChildIndex(this,parent.numChildren - 1); }
         }
         catch(error:Error) { }
      }

      // Shows the slot's picture once its Loader has content: every Loader is fresh for its one picture (newLoader), so
      // any content it has is the row's own, whether its load finished with an event or not. The grey matrix sits on
      // the Loader itself, put on or taken off only when the content is there and the wanted state changes (never
      // cleared and set again on every render, which left the grey symbol blank after a redraw).
      private function fitIcon(s:Object) : void
      {
         var size:Number = ICON_SIZE;
         var k:Number = 0;
         if(!s.loader.content || !(s.loader.content.width > 0)) { return; }
         k = size / Math.max(s.loader.content.width,s.loader.content.height);
         s.loader.scaleX = s.loader.scaleY = k;
         // The grey copy is made once per loaded picture (greyOn), then shown or not on every call like the picture.
         if(s.grey && !s.greyOn)
         {
            s.greyOn = true;
            s.greyPic = greyCopy(s.loader.content);
            if(s.greyPic) { s.icon.addChild(s.greyPic); }
         }
         if(s.greyPic)
         {
            s.greyPic.scaleX = s.greyPic.scaleY = k;
            s.greyPic.visible = s.grey;
         }
         // Without a grey copy (the draw failed) the picture shows as it is rather than not at all.
         s.loader.visible = !(s.grey && s.greyPic);
      }

      // The loaded picture drawn once into a bitmap and turned grey there (BitmapData.applyFilter), in a holder placed
      // as the picture is; null when the draw fails or draws nothing (the caller then shows the picture ungreyed).
      private function greyCopy(content:DisplayObject) : Sprite
      {
         var box:Rectangle = null;
         var data:BitmapData = null;
         var m:Matrix = null;
         var pic:Bitmap = null;
         var holder:Sprite = null;
         try
         {
            box = content.getBounds(content);
            if(!(box.width >= 1 && box.height >= 1)) { return null; }
            data = new BitmapData(Math.ceil(box.width),Math.ceil(box.height),true,0);
            m = new Matrix();
            m.translate(-box.x,-box.y);
            data.draw(content,m);
            if(data.getColorBoundsRect(0xFF000000,0,false).width <= 0)
            {
               data.dispose();
               return null;
            }
            data.applyFilter(data,data.rect,new Point(0,0),new ColorMatrixFilter(GREY_MATRIX));
            pic = new Bitmap(data,"auto",true);
            pic.x = box.x;
            pic.y = box.y;
            holder = new Sprite();
            holder.mouseEnabled = false;
            holder.addChild(pic);
         }
         catch(error:Error)
         {
            if(data) { try { data.dispose(); } catch(error2:Error) { } }
            holder = null;
         }
         return holder;
      }

      private function html(text:String, color:String) : String
      {
         text = text.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
         return "<font color='" + color + "'>" + text + "</font>";
      }

      private function hex(rgb:Number) : String
      {
         var text:String = (uint(rgb) & 0xFFFFFF).toString(16);
         while(text.length < 6) { text = "0" + text; }
         return "#" + text;
      }

      private function distText(q:Object) : String
      {
         var d:Object = dist[String(q.i)];
         if(String(q.map) != "" && String(q.map) != String(data.homeMap)) { return word("otherRegion"); }
         if(!conf("distance") || d == null) { return ""; }
         return Number(d) >= 1000 ? (Math.round(Number(d) / 100) / 10) + " km" : Math.round(Number(d)) + " m";
      }

      // The height of a row: section headers, quests and the filter-style rows each have their own.
      private function heightOf(r:Object) : Number
      {
         switch(r.type)
         {
            case ROW_CAT:
               return Math.max(30,Math.round(HEADER_H * scale));
            case ROW_QUEST:
               return Math.max(75,Math.round(QUEST_H * scale));
            case ROW_OBJECTIVE:
               return Math.round(OBJECT_H * scale);
            default:
               return Math.max(34,Math.round(FILTER_H * scale));
         }
         return Math.max(34,Math.round(FILTER_H * scale));
      }

      // A font size at the list text size, rounded (Map Quest Insight 2.2.0 rounds each size).
      private function px(size:Number) : Number
      {
         return Math.round(size * scale);
      }

      // The list starts round(100 x text size) down; the footer is round(56 x text size) tall and sits above the
      // game's own bottom hint row, so the list ends and the divider stands that far above the bottom.
      private function listTopY() : Number
      {
         return Math.round(100 * scale);
      }

      private function footerH() : Number
      {
         return Math.round(56 * scale);
      }

      private function barLine() : Number
      {
         return GAME_HINTS_H + footerH();
      }

      private function heightSum(from:int, to:int) : Number
      {
         var sum:Number = 0;
         var i:int = 0;
         for(i = from; i <= to && i < rows.length; i++) { sum += heightOf(rows[i]); }
         return sum;
      }

      // A run of text in one of the game's fonts, for a row's html.
      private function span(text:String, color:uint, size:Number, bold:Boolean) : String
      {
         text = text.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;");
         return "<font face='" + (bold ? "$BoldFont" : "$NormalFont") + "' size='" + Math.round(size) + "' color='" + hex(color) + "'>" + text + "</font>";
      }

      // A section header: the dark gradient with the section's stripe at its left edge.
      private function gradientBar(x:Number, y:Number, w:Number, h:Number, stripe:uint) : void
      {
         var m:Matrix = new Matrix();
         m.createGradientBox(w,h,0,x,y);
         bar.graphics.beginGradientFill(GradientType.LINEAR,[HEAD_TOP,HEAD_REST,HEAD_REST],[1,0.85,0.22],[0,110,255],m);
         bar.graphics.drawRect(x,y,w,h);
         bar.graphics.endFill();
         bar.graphics.beginFill(stripe,1);
         bar.graphics.drawRect(x,y,6,h);
         bar.graphics.endFill();
      }

      // The stripe of a section header by its key: Main 0, Secondary 1, Contracts 2, Treasure 3, Hearts of Stone 5,
      // Blood and Wine 6, Filters; Gwent (4), Quests Available and any other section take the Other colour.
      private function stripeOf(cat:String) : uint
      {
         if(cat == "0") { return 0xFFC400; }
         if(cat == "1") { return 0x9C8C00; }
         if(cat == "2") { return 0x5BA65F; }
         if(cat == "3") { return 0xB44100; }
         if(cat == "5") { return 0x4F8FD0; }
         if(cat == "6") { return 0xC0506A; }
         if(cat == "filters") { return 0xA08D6B; }
         return 0x7A8899;
      }

      // The section a row belongs to: a header's own, a quest's, or the filters section for its rows.
      private function catOf(r:Object) : String
      {
         if(!r) { return ""; }
         if(r.type == ROW_CAT) { return String(r.cat); }
         if(r.type == ROW_REGION || r.type == ROW_FILTER) { return "filters"; }
         if(r.q) { return r.q.avail ? "avail" : String(r.q.cat); }
         return "";
      }

      private function checkBox(x:Number, y:Number, checked:Boolean) : void
      {
         bar.graphics.lineStyle(2,BOX_COLOR,1);
         bar.graphics.drawRect(x + 1,y + 1,BOX_SIZE - 2,BOX_SIZE - 2);
         bar.graphics.lineStyle();
         if(checked)
         {
            bar.graphics.beginFill(ACCENT,1);
            bar.graphics.drawRect(x + (BOX_SIZE - BOX_FILL) / 2,y + (BOX_SIZE - BOX_FILL) / 2,BOX_FILL,BOX_FILL);
            bar.graphics.endFill();
         }
         else
         {
            bar.graphics.beginFill(BOX_OFF_COLOR,1);
            bar.graphics.drawRect(x + (BOX_SIZE - BOX_OFF_FILL) / 2,y + (BOX_SIZE - BOX_OFF_FILL) / 2,BOX_OFF_FILL,BOX_OFF_FILL);
            bar.graphics.endFill();
         }
      }

      // The Deadly row's skull, drawn here (the row has no picture): a round head with two eye holes and a jaw line,
      // on a dark backing the size of the other rows' symbols; x, y its top left.
      private function deadlySkull(x:Number, y:Number, on:Boolean) : void
      {
         var g:Object = bar.graphics;
         var size:Number = ICON_SIZE * FILTER_ICON_SCALE / 4.5;
         var cx:Number = x + size / 2;
         var cy:Number = y + size * 0.44;
         var fill:uint = on ? 0xFFFFFF : 0x6E6A64;
         g.beginFill(0x161412,1);
         g.drawRect(x,y,size,size);
         g.endFill();
         g.beginFill(fill,1);
         g.drawCircle(cx,cy,size * 0.32);
         g.endFill();
         g.beginFill(fill,1);
         g.drawRect(cx - size * 0.17,cy + size * 0.18,size * 0.34,size * 0.22);
         g.endFill();
         g.beginFill(0x161412,1);
         g.drawCircle(cx - size * 0.12,cy + size * 0.02,size * 0.08);
         g.drawCircle(cx + size * 0.12,cy + size * 0.02,size * 0.08);
         g.endFill();
         g.lineStyle(1.5,0x161412,1);
         g.moveTo(cx - size * 0.17,cy + size * 0.29);
         g.lineTo(cx + size * 0.17,cy + size * 0.29);
         g.lineStyle();
      }

      // The picture of a filter row, sent by the script in the hide-switch order; empty for Deadly.
      private function filterIcon(k:int) : String
      {
         var sent:Array = data && data.filterIcons is Array ? data.filterIcons as Array : [];
         if(k < 0 || k >= sent.length) { return ""; }
         return String(sent[k]);
      }

      // How many quests (all regions) the row's switch hides: the quests of its kind, or the deadly ones for Deadly.
      private function filterCount(k:int) : int
      {
         var q:Object = null;
         var n:int = 0;
         for each(q in quests)
         {
            if(k == 9) { if(q.deadly) { n++; } }
            else if(int(q.fk) == k) { n++; }
         }
         return n;
      }

      // An objective's small box: empty while open, crossed when done.
      private function objectiveBox(x:Number, y:Number, done:Boolean) : void
      {
         bar.graphics.lineStyle(1.5,OBJ_OFF,1);
         bar.graphics.drawRect(x,y,OBJ_BOX,OBJ_BOX);
         if(done)
         {
            bar.graphics.moveTo(x + 3,y + 3);
            bar.graphics.lineTo(x + OBJ_BOX - 3,y + OBJ_BOX - 3);
            bar.graphics.moveTo(x + OBJ_BOX - 3,y + 3);
            bar.graphics.lineTo(x + 3,y + OBJ_BOX - 3);
         }
         bar.graphics.lineStyle();
      }

      // A small solid triangle: dir 0 up, 1 down, 2 right, 3 left; w across, h along its direction; cx, cy its centre.
      private function triangle(cx:Number, cy:Number, w:Number, h:Number, dir:int, color:uint) : void
      {
         var g:Object = bar.graphics;
         g.beginFill(color,1);
         if(dir == 0) { g.moveTo(cx - w / 2,cy + h / 2); g.lineTo(cx + w / 2,cy + h / 2); g.lineTo(cx,cy - h / 2); }
         else if(dir == 1) { g.moveTo(cx - w / 2,cy - h / 2); g.lineTo(cx + w / 2,cy - h / 2); g.lineTo(cx,cy + h / 2); }
         else if(dir == 2) { g.moveTo(cx - h / 2,cy - w / 2); g.lineTo(cx - h / 2,cy + w / 2); g.lineTo(cx + h / 2,cy); }
         else { g.moveTo(cx + h / 2,cy - w / 2); g.lineTo(cx + h / 2,cy + w / 2); g.lineTo(cx - h / 2,cy); }
         g.endFill();
      }

      // The tracked quest's ring with an arrow on each side of it.
      private function trackedRing(cx:Number, cy:Number) : void
      {
         var r:Number = ICON_SIZE / 2 + 2;
         bar.graphics.lineStyle(3,RING_COLOR,1);
         bar.graphics.drawCircle(cx,cy,r);
         bar.graphics.lineStyle();
         triangle(cx,cy - r - 5,10,8,0,RING_COLOR);
         triangle(cx,cy + r + 5,10,8,1,RING_COLOR);
         triangle(cx - r - 5,cy,10,8,3,RING_COLOR);
         triangle(cx + r + 5,cy,10,8,2,RING_COLOR);
      }

      // A one-line field centred on a height; a field that sizes itself keeps its own height.
      private function placeLine(f:TextField, centre:Number, size:Number) : void
      {
         if(f.autoSize == TextFieldAutoSize.NONE) { f.height = Math.round(size * 1.3 + 4); }
         f.y = Math.round(centre - f.height / 2);
      }

      // The title block: the list's name and the region count, then the sort, the player's level and Only this region.
      private function drawTitleBlock(sorts:Array) : void
      {
         var text:String = countText();
         var bold:String = countBold;
         var sortName:String = sortMode < sorts.length ? sorts[sortMode] : "";
         var lineY:Number = listTopY() - px(24);
         title.htmlText = span(word("listTitle").toUpperCase(),TITLE_COLOR,px(32),true);
         title.x = 18;
         title.width = 262;
         title.height = Math.round(px(32) * 1.3 + 4);
         title.y = px(12);
         if(bold != "" && text.indexOf(bold) == 0)
         {
            counter.htmlText = "<p align='right'>" + span(bold,TAB_ON,px(20),true) + span(text.substr(bold.length),TAB_ON,px(20),false) + "</p>";
         }
         else { counter.htmlText = "<p align='right'>" + span(text,TAB_ON,px(20),false) + "</p>"; }
         // Starts at W-360 and is right-aligned up to the panel's inset, so it never covers the title.
         counter.x = PANEL_W - 360;
         counter.width = PANEL_W - INSET - (PANEL_W - 360);
         counter.height = Math.round(px(20) * 1.3 + 4);
         counter.y = px(20);
         counter.visible = text != "";
         sortLine.htmlText = span(word("sort") + ": ",SORT_LABEL,px(18),false) + span(sortName,sortChanged ? JUST_CHANGED : SORT_VALUE,px(18),true) + (pad ? "" : span(" [" + promptKey("sort") + "]",TAB_OFF,px(18),false));
         sortLine.x = 18;
         sortLine.width = 200;
         placeLine(sortLine,lineY,px(18));
         levelLine.visible = conf("givers") && Number(data.playerLevel) > 0;
         if(levelLine.visible)
         {
            levelLine.htmlText = "<p align='center'>" + span(word("currentLevel") + ": " + int(data.playerLevel),SORT_LABEL,px(18),true) + "</p>";
            levelLine.width = 220;
            levelLine.x = 313 - 110;
            placeLine(levelLine,lineY,px(18));
         }
         regionLine.htmlText = span(word("thisRegion") + ": " + (thisRegion ? word("on") : word("off")),thisRegion ? REGION_ON : REGION_OFF,px(18),false);
         regionLine.x = PANEL_W - INSET + 2 - regionLine.width;
         placeLine(regionLine,lineY,px(18));
      }

      // The footer: a divider line above it and the four keys with their words, centred in it.
      private function drawHintBar() : void
      {
         var ids:Array = ["close","track","region","sort"];
         var words:Array = [word("close"),word("track"),thisRegion ? word("allRegions") : word("thisRegion"),word("sort")];
         var total:Number = 0;
         var k:Number = 1;
         var x:Number = 0;
         var i:int = 0;
         var made:MovieClip = null;
         var widths:Array = [];
         bar.graphics.beginFill(DIVIDER_COLOR,1);
         bar.graphics.drawRect(INSET,boxH - barLine(),PANEL_W - 2 * INSET,1);
         bar.graphics.endFill();
         for(i = 0; i < 4; i++)
         {
            hints[i].scaleX = hints[i].scaleY = 1;
            hints[i].htmlText = span(promptButton(ids[i],words[i]),FOOT_LABEL,px(FOOT_FONT * FOOT_SCALE),false);
            made = gameButton("foot" + i,ids[i],words[i]);
            if(made) { made.scaleX = made.scaleY = footFont() / BUTTON_FONT; }
            widths[i] = made ? made.getBounds(this).width : hints[i].width;
            total += widths[i];
         }
         total += FOOT_GAP * 3;
         if(total > PANEL_W - 40) { k = (PANEL_W - 40) / total; }
         x = (PANEL_W - total * k) / 2;
         for(i = 0; i < 4; i++)
         {
            hints[i].scaleX = hints[i].scaleY = k;
            hints[i].x = x;
            placeLine(hints[i],boxH - GAME_HINTS_H - footerH() / 2,footFont());
            made = gameButton("foot" + i,ids[i],words[i]);
            if(made)
            {
               made.scaleX = made.scaleY = footFont() / BUTTON_FONT * k;
               placeButton(made,x,boxH - GAME_HINTS_H - footerH() / 2,false);
            }
            hints[i].visible = !made;
            x += widths[i] * k + FOOT_GAP * k;
         }
      }

      private function footFont() : Number
      {
         return px(FOOT_FONT * FOOT_SCALE);
      }

      // ---- prompts and the device ----

      // The name of a prompt's key on the device in use.
      private function promptKey(id:String) : String
      {
         var names:Array = PROMPT_KEYS[id] as Array;
         return names[pad ? (playStation ? 2 : 1) : 0];
      }

      // One prompt: the key and its word. Text today; the game's button picture replaces this one function.
      private function promptButton(id:String, label:String) : String
      {
         return "[" + promptKey(id) + "] " + label;
      }

      // The game's own button for a prompt (CMF API 17), made once per prompt, word and device; null on an older CMF
      // or when the map gives none, and the caller keeps its text.
      private function gameButton(place:String, id:String, label:String) : MovieClip
      {
         var nav:Array = PROMPT_NAV[id] as Array;
         var key:String = id + "|" + label + "|" + (pad ? (playStation ? "ps" : "pad") : "kb");
         var held:Object = buttons[place];
         var made:MovieClip = null;
         if(held && held.key == key && held.clip)
         {
            dressButton(held);
            return held.clip as MovieClip;
         }
         dropButton(place);
         if(!map || !(map.cmfMakeButton is Function) || !nav) { return null; }
         try { made = map.cmfMakeButton(String(nav[0]),int(nav[1]),label) as MovieClip; } catch(error:Error) { made = null; }
         if(!made) { return null; }
         made.mouseEnabled = false;
         made.mouseChildren = false;
         made.visible = false;
         keyPicture(made);
         addChild(made);
         held = {"key":key,"clip":made,"cap":id == "objs" && !pad,"capField":null,"mark":null};
         buttons[place] = held;
         dressButton(held);
         return made;
      }

      // The game's button draws a clickable button's key as "[F]" text in a box (the tracker's and the world map's
      // buttons) and a hint row button's key as the key picture (the map's own bottom row). These buttons are never
      // clicked, so they take the hint row's look: not clickable, set up again.
      private function keyPicture(made:MovieClip) : void
      {
         try
         {
            if("clickable" in made && made["clickable"] != false)
            {
               made["clickable"] = false;
               made["updateDataFromStage"]();
               made["validateNow"]();
            }
         }
         catch(error:Error) { }
      }

      // What the list changes on a game button, applied again whenever the button may have redrawn itself (it redraws
      // once it is on the stage and on the game's own updates): the word in the footer colour and, for the keyboard
      // Objectives prompt, the cap's text hidden under the triangle.
      private function dressButton(held:Object) : void
      {
         var made:MovieClip = held ? held.clip as MovieClip : null;
         if(!made) { return; }
         try
         {
            if(made["textField"] is TextField && TextField(made["textField"]).textColor != FOOT_LABEL) { TextField(made["textField"]).textColor = FOOT_LABEL; }
         }
         catch(error:Error) { }
         if(held.cap) { capTriangle(held); }
      }

      private function dressButtons() : void
      {
         var place:String = null;
         for(place in buttons) { dressButton(buttons[place]); }
      }

      // A text field the player sees: on, with text.
      private static function shownText(f:TextField) : Boolean
      {
         return f != null && f.visible && f.text != "";
      }

      // The key cap's text in a button's hint row look: the first shown text field (the label word excepted) that
      // ends left of the label, searched four clips deep; null when there is none.
      private function capSearch(clip:DisplayObjectContainer, made:MovieClip, label:TextField, labelLeft:Number, depth:int) : TextField
      {
         var i:int = 0;
         var child:DisplayObject = null;
         var found:TextField = null;
         if(!clip || depth > 4) { return null; }
         for(i = 0; i < clip.numChildren; i++)
         {
            child = clip.getChildAt(i);
            if(child is TextField)
            {
               if(child !== label && shownText(child as TextField) && child.getBounds(made).right <= labelLeft + 4) { return child as TextField; }
            }
            else if(child is DisplayObjectContainer && child.visible)
            {
               found = capSearch(child as DisplayObjectContainer,made,label,labelLeft,depth + 1);
               if(found) { return found; }
            }
         }
         return null;
      }

      // The cap's text the button shows now: the field found before when the game shows it again, else tfKeyLabel
      // when shown (the clickable look, "[RIGHT]"), else the hint row look's own key text ("Right"). The hint row look
      // keeps tfKeyLabel hidden, so a hidden tfKeyLabel must never end the search.
      private function capField(held:Object, made:MovieClip) : TextField
      {
         var cap:TextField = held.capField as TextField;
         var label:TextField = null;
         var labelLeft:Number = Number.MAX_VALUE;
         if(shownText(cap)) { return cap; }
         try { cap = made["tfKeyLabel"] as TextField; } catch(error:Error) { cap = null; }
         if(shownText(cap)) { return cap; }
         try { label = made["textField"] as TextField; } catch(error:Error) { label = null; }
         if(shownText(label)) { labelLeft = label.getBounds(made).left; }
         return capSearch(made,made,label,labelLeft,0);
      }

      // On the keyboard the Objectives key is Right: its cap's text is hidden and a filled right triangle, 0.42 x the
      // cap's height, drawn in the cap instead, in the cap's text colour; otherwise the button stays as the game drew
      // it. Run again on every frame and whenever the button may have redrawn (a device switch, a pin build): a cap
      // text the game showed again is hidden again and the button's one triangle moved onto it, on top of the
      // button's own clips.
      private function capTriangle(held:Object) : void
      {
         var made:MovieClip = held.clip as MovieClip;
         var cap:TextField = null;
         var mark:Shape = held.mark as Shape;
         var box:Rectangle = null;
         var size:Number = 0;
         var cx:Number = 0;
         var cy:Number = 0;
         try
         {
            if(mark && mark.parent == made && made.getChildIndex(mark) < made.numChildren - 1) { made.addChild(mark); }
            cap = capField(held,made);
            if(!cap) { return; }
            box = cap.getBounds(made);
            if(box.height <= 0) { return; }
            held.capField = cap;
            size = CAP_TRIANGLE * box.height;
            cx = box.x + box.width / 2;
            cy = box.y + box.height / 2;
            if(!mark) { mark = new Shape(); }
            mark.graphics.clear();
            mark.graphics.beginFill(cap.textColor,1);
            mark.graphics.moveTo(cx - size * 0.433,cy - size / 2);
            mark.graphics.lineTo(cx - size * 0.433,cy + size / 2);
            mark.graphics.lineTo(cx + size * 0.433,cy);
            mark.graphics.endFill();
            mark.visible = true;
            if(mark.parent != made || made.getChildIndex(mark) < made.numChildren - 1) { made.addChild(mark); }
            held.mark = mark;
            cap.visible = false;
         }
         catch(error:Error) { }
      }

      // Moves a button so its left (or right) edge is at edge and its middle at centre, and shows it.
      private function placeButton(made:MovieClip, edge:Number, centre:Number, alignRight:Boolean) : void
      {
         var box:Rectangle = made.getBounds(this);
         made.x += alignRight ? edge - box.right : edge - box.left;
         made.y += centre - (box.top + box.bottom) / 2;
         made.visible = true;
      }

      // The selected row's prompt as a game button: right-aligned where the text prompt ends, the text hidden, and
      // the prompt's left edge moved to the button's so the region text is clipped against it.
      private function promptPicture(s:Object, id:String, label:String, centre:Number) : void
      {
         var made:MovieClip = gameButton("row_" + id,id,label);
         var right:Number = s.obj.x + s.obj.width - 2;
         if(!made) { return; }
         made.scaleX = made.scaleY = px(18) / BUTTON_FONT;
         placeButton(made,right,centre,true);
         s.obj.visible = false;
         s.obj.x = made.getBounds(this).left;
      }

      // Where the prompt is drawn: the game button's box, or the text prompt's field.
      private function promptBounds(s:Object, id:String) : Rectangle
      {
         var held:Object = buttons["row_" + id];
         var clip:DisplayObject = held ? held.clip as DisplayObject : null;
         if(clip && clip.visible) { return clip.getBounds(this); }
         return s.obj.getBounds(this);
      }

      private function hideButtons() : void
      {
         var place:String = null;
         for(place in buttons) { if(buttons[place].clip) { buttons[place].clip.visible = false; } }
      }

      private function dropButton(place:String) : void
      {
         var held:Object = buttons[place];
         var clip:DisplayObject = held ? held.clip as DisplayObject : null;
         if(clip && clip.parent) { clip.parent.removeChild(clip); }
         delete buttons[place];
      }

      private function dropButtons() : void
      {
         var places:Array = [];
         var place:String = null;
         for(place in buttons) { places.push(place); }
         for each(place in places) { dropButton(place); }
      }

      private function setDevice(isPad:Boolean, isPs:Boolean) : void
      {
         if(isPad == pad && isPs == playStation) { return; }
         pad = isPad;
         playStation = isPs;
         if(opened && data) { render(); }
      }

      // What the keys say: a gamepad_ navigation name is a button (Enter and Esc carry the pad's A and B names on the
      // keyboard too, so they say nothing), a letter, Enter, Esc or Space is the keyboard. PlayStation comes only
      // from the game's input manager.
      private function learnDevice(code:int, nav:String) : void
      {
         var padName:Boolean = nav.indexOf("gamepad_") == 0 || nav.indexOf("enter-gamepad_") == 0 || nav.indexOf("escape-gamepad_") == 0;
         if(managerKnown) { return; }
         if((padName && code != 13 && code != 27) || nav.indexOf("dpad_") == 0) { setDevice(true,playStation); }
         else if((code >= 37 && code <= 40) || (code >= 65 && code <= 90) || code == 13 || code == 27 || code == 32) { setDevice(false,false); }
      }

      // The game's input manager, read every frame: -1 not readable, 0 keyboard, 1 controller, 2 PlayStation.
      private function managerDevice() : int
      {
         var manager:Object = null;
         if(!managerTried)
         {
            managerTried = true;
            try { managerClass = getDefinitionByName("red.game.witcher3.managers.InputManager") as Class; } catch(error:Error) { managerClass = null; }
         }
         if(managerClass == null) { return -1; }
         try
         {
            manager = managerClass["getInstance"]();
            if(manager == null) { return -1; }
            if(!manager.isGamepad()) { return 0; }
            return String(manager.gamepadType).toLowerCase().indexOf("ps") >= 0 ? 2 : 1;
         }
         catch(error:Error) { }
         return -1;
      }

      private function render() : void
      {
         var g:Object = bg.graphics;
         var listTop:Number = listTopY();
         var avail:Number = boxH - barLine() - 8 - listTop;
         var k:int = 0;
         var maxTop:int = 0;
         var shown:int = 0;
         var selEnd:int = 0;
         var i:int = 0;
         var j:int = 0;
         var r:Object = null;
         var s:Object = null;
         var y:Number = 0;
         var h:Number = 0;
         var extra:Number = 0;
         var wide:Number = PANEL_W - 2 * INSET;
         var left:String = "";
         var lvl:String = "";
         var second:String = "";
         var distHtml:String = "";
         var objLabel:String = "";
         var objId:String = "";
         var objWord:String = "";
         var key:String = "";
         var selCat:String = catOf(selected >= 0 && selected < rows.length ? rows[selected] : null);
         var checked:Boolean = false;
         var sorts:Array = wordList("sorts");
         var iconUrl:String = "";
         var tint:Number = 0;
         var tracked:Boolean = false;
         var trackY:Number = 0;
         var trackH:Number = 0;
         var thumbH:Number = 0;
         var ring:Number = 0;
         var symbol:Number = 0;
         var colour:uint = 0;
         var clipW:Number = 0;
         for each(s in slots)
         {
            s.left.visible = false;
            s.right.visible = false;
            s.dist.visible = false;
            s.lvl.visible = false;
            s.obj.visible = false;
            s.icon.visible = false;
         }
         for(i = 0; i < hints.length; i++) { hints[i].visible = false; }
         hideButtons();
         promptRow = -1;
         promptId = "";
         promptBox = null;
         bar.graphics.clear();
         if(!opened || !data) { g.clear(); return; }
         drawPlate();
         // The right edge shadow: five 1 px black strips, fading outwards.
         for(k = 0; k < 5; k++)
         {
            g.beginFill(0x000000,SHADOW_ALPHAS[k]);
            g.drawRect(boxW + k,0,1,boxH);
            g.endFill();
         }
         drawTitleBlock(sorts);
         drawHintBar();
         // Keep the highlighted row on the page; the page never ends in empty room while rows are left above it.
         if(selected < top) { top = selected; }
         // The highlighted quest stays on the page with its objective rows where they fit.
         selEnd = selected;
         while(selEnd + 1 < rows.length && selected >= 0 && selected < rows.length && rows[selected].type == ROW_QUEST && rows[selEnd + 1].type == ROW_OBJECTIVE) { selEnd++; }
         while(top < selected && heightSum(top,selEnd) > avail) { top++; }
         maxTop = Math.max(0,rows.length - 1);
         while(maxTop > 0 && heightSum(maxTop - 1,rows.length - 1) <= avail) { maxTop--; }
         top = Math.max(0,Math.min(top,maxTop));
         y = listTop;
         for(i = top; i < rows.length; i++)
         {
            r = rows[i];
            h = heightOf(r);
            if(i > top && y + h > listTop + avail + 0.5) { break; }
            shown++;
            s = slot(i - top);
            left = "";
            lvl = "";
            second = "";
            distHtml = "";
            objLabel = "";
            objId = "";
            objWord = "";
            iconUrl = "";
            checked = false;
            tracked = false;
            s.left.x = 20;
            s.left.width = boxW - 40;
            resetSlot(s,r.type);
            switch(r.type)
            {
               case ROW_CAT:
                  key = String(r.cat);
                  gradientBar(INSET,y,wide,h,stripeOf(key));
                  s.left.x = 38;
                  left = span(String(r.label).toUpperCase(),TEXT_ON,px(22),true);
                  if(r.count >= 0) { distHtml = span(String(r.count),TEXT_ON,px(22),true); }
                  if(key != "") { triangle(ARROW_X,y + h / 2,14,8,folded[key] ? 1 : 0,ARROW_COLOR); }
                  if(key != "" && key == selCat)
                  {
                     objLabel = span(promptButton("fold",word("collapse")),FOOT_LABEL,px(18),false);
                     objId = "fold";
                     objWord = word("collapse");
                  }
                  break;
               case ROW_QUEST:
                  iconUrl = String(r.q.icon);
                  tint = Number(r.q.band);
                  tracked = r.q.tracked;
                  s.left.x = NAME_X - 2;
                  s.left.width = boxW - NAME_X - INSET;
                  if(int(r.q.lvl) > 0) { lvl = "<p align='center'>" + span(String(int(r.q.lvl)),WHITE,px(30),true) + "</p>"; }
                  left = questText(r.q,String(r.q.name));
                  if(conf("region")) { second = span(String(r.q.region),TEXT_SUB,px(19),false); }
                  distHtml = span(distText(r.q),TEXT_SUB,px(19),false);
                  if(i == selected && !r.q.avail && r.q.objs is Array && (r.q.objs as Array).length > 0)
                  {
                     objLabel = span(promptButton("objs",word("objectives")),FOOT_LABEL,px(18),false);
                     objId = "objs";
                     objWord = word("objectives");
                  }
                  break;
               case ROW_OBJECTIVE:
                  s.left.x = OBJ_TEXT_X - 2;
                  s.left.width = boxW - OBJ_TEXT_X - INSET;
                  colour = int(r.o.state) == 2 ? 0xD61010 : (r.o.tracked ? OBJ_ON : OBJ_OFF);
                  left = span(String(r.o.text),colour,px(19),false);
                  break;
               case ROW_REGION:
                  checked = thisRegion;
                  s.left.x = INSET + 12 + BOX_SIZE + 12;
                  left = span(word("thisRegion"),checked ? TEXT_ON : TEXT_OFF,px(20),false);
                  break;
               case ROW_FILTER:
                  checked = !filters[int(r.k)];
                  s.left.x = FILTER_LABEL_X - 2;
                  left = span(String(r.label),checked ? TEXT_ON : TEXT_OFF,px(20),false);
                  distHtml = span(String(filterCount(int(r.k))),checked ? TEXT_ON : TEXT_OFF,px(20),false);
                  iconUrl = filterIcon(int(r.k));
                  break;
            }
            if(i == selected)
            {
               if(r.type == ROW_CAT)
               {
                  bar.graphics.lineStyle(2,ACCENT,focused ? 1 : 0.55);
                  bar.graphics.drawRect(INSET + 1,y + 1,wide - 2,h - 2);
                  bar.graphics.lineStyle();
               }
               else
               {
                  extra = 0;
                  if(r.type == ROW_QUEST)
                  {
                     for(j = i + 1; j < rows.length && rows[j].type == ROW_OBJECTIVE; j++) { extra += heightOf(rows[j]); }
                  }
                  bar.graphics.lineStyle(2,ACCENT,focused ? 1 : 0.55);
                  bar.graphics.beginFill(SELECT_FILL,focused ? 1 : 0.55);
                  extra = Math.max(0,Math.min(extra,listTop + avail - (y + h)));
                  bar.graphics.drawRect(INSET + 1,y + 1,wide - 2,h + extra - 2);
                  bar.graphics.endFill();
                  bar.graphics.lineStyle();
               }
            }
            if(r.type == ROW_REGION) { checkBox(INSET + 12,y + (h - BOX_SIZE) / 2,checked); }
            if(r.type == ROW_FILTER) { checkBox(boxW - 60,y + (h - BOX_SIZE) / 2,checked); }
            if(r.type == ROW_FILTER && int(r.k) == 9)
            {
               symbol = ICON_SIZE * FILTER_ICON_SCALE / 4.5;
               deadlySkull(FILTER_ICON_X - symbol / 2,y + (h - symbol) / 2,checked);
            }
            if(r.type == ROW_OBJECTIVE) { objectiveBox(OBJ_BOX_X,y + (h - OBJ_BOX) / 2,int(r.o.state) == 1); }
            s.left.htmlText = left;
            s.left.visible = true;
            placeLine(s.left,r.type == ROW_QUEST ? y + h * 0.31 : y + h / 2,r.type == ROW_QUEST ? px(24) : px(20));
            // The level sits in its own column, centred on the row.
            s.lvl.htmlText = lvl;
            s.lvl.x = LEVEL_X - 2;
            placeLine(s.lvl,y + h / 2,px(30));
            s.lvl.visible = lvl != "";
            // The right-hand text: a count or a distance at the right edge, a label before it.
            s.dist.htmlText = distHtml;
            s.dist.x = r.type == ROW_FILTER ? boxW - FILTER_COUNT_RIGHT + 2 - s.dist.width : (r.type == ROW_CAT ? COUNT_RIGHT : ROW_RIGHT) + 2 - s.dist.width;
            placeLine(s.dist,r.type == ROW_QUEST ? y + h * 0.69 : y + h / 2,r.type == ROW_CAT ? px(22) : (r.type == ROW_QUEST ? px(19) : px(20)));
            s.dist.visible = distHtml != "";
            s.obj.htmlText = objLabel;
            s.obj.x = r.type == ROW_QUEST ? (distHtml != "" ? s.dist.x + 2 - OBJ_PROMPT_GAP : ROW_RIGHT) + 2 - s.obj.width : (distHtml != "" ? s.dist.x + 2 : COUNT_RIGHT) - 14 + 2 - s.obj.width;
            placeLine(s.obj,r.type == ROW_QUEST ? y + h * 0.69 : y + h / 2,px(18));
            s.obj.visible = objLabel != "";
            if(objLabel != "")
            {
               promptPicture(s,objId,objWord,r.type == ROW_QUEST ? y + h * 0.69 : y + h / 2);
               promptRow = i;
               promptId = objId;
               promptBox = promptBounds(s,objId);
            }
            // The region line sits under the name.
            s.right.autoSize = TextFieldAutoSize.RIGHT;
            s.right.htmlText = second;
            s.right.x = NAME_X - 2;
            placeLine(s.right,y + h * 0.69,px(19));
            // The region text keeps its old 330 px width; on the prompt row it ends before the prompt (40 px at least).
            clipW = objLabel != "" && r.type == ROW_QUEST ? Math.min(330,Math.max(REGION_MIN_W,s.obj.x - OBJ_PROMPT_GAP / 2 - s.right.x)) : 330;
            if(s.right.width > clipW)
            {
               s.right.autoSize = TextFieldAutoSize.NONE;
               s.right.width = clipW;
               s.right.height = Math.round(px(19) * 1.3 + 4);
               placeLine(s.right,y + h * 0.69,px(19));
            }
            s.right.visible = second != "";
            if(r.type == ROW_QUEST) { fitName(s.left,r.q); }
            if(iconUrl != "")
            {
               if(s.url != iconUrl)
               {
                  s.url = iconUrl;
                  newLoader(s);
                  try { s.loader.load(new URLRequest(iconUrl)); } catch(error:Error) { }
               }
               // Heroes' Pursuits (hide index 6) in grey.
               s.grey = r.type == ROW_FILTER && int(r.k) == 6;
               fitIcon(s);
               if(r.type == ROW_FILTER)
               {
                  // A filter row's symbol: normal when on, multiplied by 6E6A64 when off; Heroes' Pursuits in grey.
                  symbol = ICON_SIZE * FILTER_ICON_SCALE / 4.5;
                  s.icon.scaleX = s.icon.scaleY = FILTER_ICON_SCALE / 4.5;
                  s.icon.x = FILTER_ICON_X - symbol / 2;
                  s.icon.y = y + (h - symbol) / 2;
                  s.icon.transform.colorTransform = checked ? new ColorTransform() : tintOf(0x6E6A64);
                  s.icon.visible = true;
               }
               else
               {
                  // The tracked quest's icon is gold at 0.85 size inside an orange ring with an arrow on each side.
                  ring = tracked ? 0.85 : 1;
                  s.icon.scaleX = s.icon.scaleY = ring;
                  s.icon.x = ICON_CX - ICON_SIZE * ring / 2;
                  s.icon.y = y + (h - ICON_SIZE * ring) / 2;
                  s.icon.transform.colorTransform = tracked ? tintOf(GOLD) : (tint > 0 ? tintOf(tint) : new ColorTransform());
                  s.icon.visible = true;
                  if(tracked) { trackedRing(ICON_CX,y + h / 2); }
               }
            }
            y += h;
         }
         for(j = shown; j < slots.length; j++) { slots[j].type = -1; }
         drawn = shown;
         // The scroll bar: a 3 px track with a 5 px thumb, at least 24 px tall.
         if(shown < rows.length)
         {
            trackY = listTop;
            trackH = avail;
            thumbH = Math.max(24,trackH * shown / rows.length);
            bar.graphics.beginFill(TRACK_COLOR,0.9);
            bar.graphics.drawRect(boxW - 9,trackY,3,trackH);
            bar.graphics.endFill();
            bar.graphics.beginFill(ACCENT,1);
            bar.graphics.drawRect(boxW - 10,trackY + (trackH - thumbH) * (maxTop > 0 ? top / maxTop : 0),5,thumbH);
            bar.graphics.endFill();
         }
         setChildIndex(bar,1);
         toFront();
      }

      // "%r: %n/%t active quests": the shown map's region (upper case, kept in countBold), your active quests there and
      // in all regions, without the types the filter rows leave out (Only this region does not change the total).
      // Quests not started yet never count.
      private function countText() : String
      {
         var q:Object = null;
         var region:String = "";
         var here:int = 0;
         var all:int = 0;
         var text:String = "";
         countBold = "";
         for each(q in quests)
         {
            if(String(q.map) == curMap() && region == "") { region = String(q.region); }
            if(!counted(q)) { continue; }
            all++;
            if(String(q.map) == curMap()) { here++; }
         }
         for each(q in available()) { if(region == "" && String(q.map) == curMap()) { region = String(q.region); } }
         if(region == "") { return ""; }
         countBold = region.toUpperCase();
         text = all == 0 ? word("regionNone") : (all == 1 ? word("regionCountOne") : word("regionCount"));
         return text.split("%r").join(countBold).split("%n").join(String(here)).split("%t").join(String(all));
      }

      private function counted(q:Object) : Boolean
      {
         var keep:Boolean = thisRegion;
         var shown:Boolean = false;
         thisRegion = false;
         shown = shownQuest(q);
         thisRegion = keep;
         return shown;
      }

      // The quest's name in its difficulty colour, then its expansion in brackets, smaller.
      private function questText(q:Object, name:String) : String
      {
         return html(name,conf("nameCol") ? String(q.diff) : "#FFFFFF").replace("<font ","<font face='$BoldFont' size='" + px(24) + "' ") +
            (conf("dlc") && String(q.dlc) != "" ? span("  (" + String(q.dlc) + ")",DLC_COLOR,px(18),false) : "");
      }

      // A name too long for its row ends in an ellipsis instead of being cut off at the row's edge.
      private function fitName(f:TextField, q:Object) : void
      {
         var name:String = String(q.name);
         while(f.textWidth > f.width - 6 && name.length > 1)
         {
            name = name.substr(0,name.length - 1);
            f.htmlText = questText(q,name.replace(/\s+$/,"") + "…");
         }
      }

      private function tintOf(rgb:Number) : ColorTransform
      {
         return new ColorTransform(((uint(rgb) >> 16) & 255) / 255,((uint(rgb) >> 8) & 255) / 255,(uint(rgb) & 255) / 255,1,0,0,0,0);
      }

      // ---- actions ----

      // Objective lines cannot be selected (Map Quest Insight 2.1.0): the highlight steps over them. The highlighted
      // quest shows its objectives under it, and they close when the highlight leaves it.
      private function move(to:int) : void
      {
         var step:int = to > selected ? 1 : -1;
         if(!rows.length) { return; }
         to = Math.max(0,Math.min(rows.length - 1,to));
         while(to > 0 && to < rows.length - 1 && skipped(rows[to])) { to += step; }
         if(skipped(rows[to])) { to = selected; }
         selected = Math.max(0,Math.min(rows.length - 1,to));
         followObjectives();
         restRow = selected;
         restAt = getTimer();
         restDone = !(rows[selected].q);
         render();
      }

      private function skipped(r:Object) : Boolean
      {
         return r.type == ROW_OBJECTIVE;
      }

      private function followObjectives() : void
      {
         var r:Object = selected >= 0 && selected < rows.length ? rows[selected] : null;
         var want:Object = {};
         var id:String = r && r.q && !r.q.avail ? String(r.q.i) : "";
         var key:String = "";
         var changed:Boolean = false;
         if(id != "" && !closedObjs[id]) { want[id] = true; }
         for(key in expanded) { if(expanded[key] && !want[key]) { changed = true; } }
         for(key in want) { if(!expanded[key]) { changed = true; } }
         if(!changed) { return; }
         expanded = want;
         build(-1,rowKey(r),selected);
      }

      // Right (D-pad Right) shows or hides the selected quest's objectives; Left (keyboard) hides them.
      private function toggleObjectives() : void
      {
         var r:Object = selected >= 0 && selected < rows.length ? rows[selected] : null;
         if(!r || r.type != ROW_QUEST || r.q.avail) { return; }
         objectivesOpen(closedObjs[String(r.q.i)] == true);
      }

      private function objectivesOpen(open:Boolean) : void
      {
         var r:Object = selected >= 0 && selected < rows.length ? rows[selected] : null;
         if(!r || r.type != ROW_QUEST || r.q.avail) { return; }
         closedObjs[String(r.q.i)] = !open;
         followObjectives();
         render();
      }

      // Left and Right on the keyboard and the D-pad (one press each: the direction-coded twin of a D-pad press is dropped in
      // handleInput). On a quest row Right (D-pad Right) toggles the objectives, the keyboard's Left closes them, and
      // D-pad Left does nothing (Map Quest Insight's own); on a section header Left and Right fold it. param1 is "left" or
      // "right"; param2 true when it came from the D-pad.
      private function sideKey(dir:String, dpad:Boolean) : void
      {
         var r:Object = selected >= 0 && selected < rows.length ? rows[selected] : null;
         if(!r) { return; }
         if(r.type == ROW_QUEST)
         {
            if(dpad && dir == "left") { return; }
            if(dir == "right") { toggleObjectives(); }
            else { objectivesOpen(false); }
         }
         else if(r.type == ROW_CAT) { fold(selected); }
      }

      // The left stick's sideways moves while the list has focus. Kyle's pick: the stick pans the map left and right and the list
      // takes only stick up and down, so the list declines them (CMF API 17, the key goes on to the map; from the panel that pairs with this change
      // the stick's pan axis does too). param1 is the event's details, param2 the arrow direction its code says, param3 true when
      // it came from the stick (fromJoystick). One place to change.
      private function stickDeclines(details:Object, arrow:String, stick:Boolean) : Boolean
      {
         var v:Object = null;
         if(stick) { return arrow != ""; }
         if(details.type == "axis")
         {
            v = details.value;
            if(v && v.xvalue != undefined) { return Math.abs(Number(v.xvalue)) >= 0.6 || Math.abs(Number(v.yvalue)) >= 0.6; }
         }
         return false;
      }

      // A pin the reticle chose is under it (CMF's map.pinAtReticle). The pin the list itself selected for its highlighted row does not
      // count. An older CMF has no such value: false, and the list keeps A as before.
      private function reticlePin() : Boolean
      {
         try { return map != null && map.pinAtReticle === true; } catch(error:Error) { }
         return false;
      }

      // Debug lines for the pad (CMF's log, written when the game runs with -debugscripts): what the list took, the twins it dropped and the stick
      // moves it declined, so a controller test shows each press.
      private function padLog(text:String) : void
      {
         note("padlog",text);
      }

      private function logDecline(details:Object, arrow:String) : void
      {
         if(details.type == "axis")
         {
            if(!axisDeclined)
            {
               axisDeclined = true;
               padLog("axis declined x=" + Math.round(Number(details.value.xvalue) * 100) / 100 + " y=" + Math.round(Number(details.value.yvalue) * 100) / 100);
            }
         }
         else if(details.value == "keyDown") { padLog("stick " + arrow + " declined code=" + int(details.code)); }
      }

      // The D-pad button's direction: its own codes (142 up, 143 down, 144 left, 145 right) or its dpad_ navigation name; "" if the event is not the D-pad.
      private function padDirOf(code:int, nav:String) : String
      {
         if(code == 142 || nav == "dpad_up") { return "up"; }
         if(code == 143 || nav == "dpad_down") { return "down"; }
         if(code == 144 || nav == "dpad_left") { return "left"; }
         if(code == 145 || nav == "dpad_right") { return "right"; }
         return "";
      }

      // The direction an arrow code says (the keyboard, the left stick, and the twin the game sends after a D-pad press).
      private function arrowDirOf(code:int) : String
      {
         if(code == 38) { return "up"; }
         if(code == 40) { return "down"; }
         if(code == 37) { return "left"; }
         if(code == 39) { return "right"; }
         return "";
      }

      // Swap Obj: the tracked quest's next objective you have not done, in the journal's order, round again at the end.
      private function nextObjective(q:Object) : Object
      {
         var open:Array = [];
         var o:Object = null;
         var i:int = 0;
         if(!q || !q.tracked || !(q.objs is Array)) { return null; }
         for each(o in q.objs) { if(int(o.state) == 0) { open.push(o); } }
         if(open.length < 2) { return null; }
         for(i = 0; i < open.length; i++) { if(open[i].tracked) { return open[(i + 1) % open.length]; } }
         return open[0];
      }

      private function activate(row:int) : void
      {
         var r:Object = row >= 0 && row < rows.length ? rows[row] : null;
         var swap:Object = null;
         if(!r) { return; }
         switch(r.type)
         {
            case ROW_CAT:
               fold(row);
               break;
            case ROW_QUEST:
               if(r.q.avail)
               {
                  // A Quests Available row: Map Quest Insight sets its custom marker at the "!" (on the shown map).
                  pendingQa = String(r.q.map) != curMap();
                  pick(row,true);
                  if(!pendingQa) { note("qaPick",String(r.q.gv)); }
                  else if(pendingPick < 0) { pendingQa = false; }
                  break;
               }
               swap = nextObjective(r.q);
               if(swap)
               {
                  pick(row,true,int(swap.o));
                  note("objective",String(r.q.i) + ":" + String(swap.o));
                  break;
               }
               pick(row,true);
               note("track",String(r.q.i));
               break;
            case ROW_OBJECTIVE:
               pick(row,true);
               note("objective",String(r.q.i) + ":" + String(r.o.o));
               break;
            case ROW_REGION:
               toggleRegion();
               break;
            case ROW_FILTER:
               filters[int(r.k)] = !filters[int(r.k)];
               touched = true;
               note("filter",String(r.k) + ":" + (filters[int(r.k)] ? "1" : "0"));
               rebuild();
               break;
         }
      }

      private function rebuild() : void
      {
         buildKept();
         render();
      }

      // H: Only this region on or off; the highlight stays on its row when that row is still listed.
      private function toggleRegion() : void
      {
         thisRegion = !thisRegion;
         note("thisRegion",thisRegion ? "1" : "0");
         buildKept();
         followObjectives();
         render();
      }

      private function fold(row:int) : void
      {
         var r:Object = rows[row];
         var cat:String = catOf(r);
         var i:int = 0;
         if(cat == "") { return; }
         folded[cat] = !folded[cat];
         build(-1);
         for(i = 0; i < rows.length; i++) { if(rows[i].type == ROW_CAT && String(rows[i].cat) == cat) { selected = i; break; } }
         followObjectives();
         render();
      }

      private function cycleSort() : void
      {
         sortMode = (sortMode + 1) % 5;
         sortChanged = true;
         buildKept();
         render();
      }

      private function rowAt(localY:Number) : int
      {
         var listTop:Number = listTopY();
         var row:int = top;
         var rowEdge:Number = listTop;
         if(localY < listTop || localY > boxH - barLine() - 8) { return -1; }
         while(row < rows.length && row < top + drawn)
         {
            rowEdge += heightOf(rows[row]);
            if(localY < rowEdge) { return row; }
            row++;
         }
         return -1;
      }

      private function onClick(event:MouseEvent) : void
      {
         var row:int = rowAt(mouseY);
         event.stopPropagation();
         if(!opened) { return; }
         if(!focused) { focusAt = 0; takeFocus(); }
         if(row < 0 || rows[row].type == ROW_OBJECTIVE) { render(); return; }
         // A click on the row's Objectives prompt does what Right does; on the fold prompt, what C does. It neither
         // tracks the quest nor swaps its objective, and the double click that may follow is ignored.
         if(row == promptRow && promptBox && promptBox.contains(mouseX,mouseY))
         {
            swapAt = getTimer();
            restDone = true;
            if(promptId == "objs")
            {
               selected = row;
               toggleObjectives();
            }
            else { fold(row); }
            return;
         }
         // A second click on the tracked quest swaps its objective (Swap Obj); the double click that may follow is
         // the same swap.
         if(row == selected && rows[row].type == ROW_QUEST && nextObjective(rows[row].q))
         {
            swapAt = getTimer();
            restDone = true;
            activate(row);
            render();
            return;
         }
         selected = row;
         restDone = true;
         followObjectives();
         if(rows[selected].type == ROW_QUEST) { pick(selected,true); render(); }
         else { activate(selected); }
      }

      private function onDoubleClick(event:MouseEvent) : void
      {
         var row:int = rowAt(mouseY);
         event.stopPropagation();
         if(getTimer() - swapAt < 500) { return; }
         if(opened && row >= 0 && rows[row].type == ROW_QUEST) { activate(row); }
      }

      private function onWheel(event:MouseEvent) : void
      {
         if(!opened) { return; }
         event.stopPropagation();
         move(selected + (event.delta > 0 ? -1 : 1));
      }

      // Returns false for the keys that belong to the quest info box's Show more / Show less (the keyboard's X, the
      // default key of Map Quest Insight's fold, and R3 on a controller) and for the left stick's moves in every direction, press and release alike, so CMF's panel
      // (API 17, CMFHasAbility('screen','keyDecline')) lets the key go on to the box. On an older CMF the false is
      // ignored and the key is swallowed as before. Every other path returns nothing.
      public function handleInput(event:Object) : *
      {
         var details:Object = event ? event.details : null;
         var code:int = details ? int(details.code) : 0;
         var nav:String = details ? String(details.navEquivalent) : "";
         var held:Boolean = details && details.value == "keyHold";
         var pad:String = "";
         var arrow:String = "";
         var stick:Boolean = false;
         var declines:Boolean = false;
         var padA:Boolean = false;
         var aDeclines:Boolean = false;
         if(!details) { return; }
         pad = padDirOf(code,nav);
         arrow = arrowDirOf(code);
         stick = arrow != "" && details.fromJoystick == true;
         learnDevice(code,nav);
         if(!opened || !focused) { return; }
         // The controller's A: with a pin under the reticle it belongs to the map (press, hold and release alike); with none it acts on the
         // highlighted row as before, except on a section header, where Y folds and A does nothing. The keyboard keeps Enter and E.
         padA = this.pad && nav == "enter-gamepad_A" && code != 69;
         if(padA && details.value == "keyDown")
         {
            aToMap = reticlePin();
            padLog(aToMap ? "A goes to the map, a pin is under the reticle" : "A stays with the list, no pin under the reticle");
         }
         aDeclines = padA && aToMap;
         if(padA && details.value != "keyDown" && details.value != "keyHold") { aToMap = false; }
         declines = stickDeclines(details,arrow,stick) || aDeclines;
         if(details.type == "axis" && !declines) { axisDeclined = false; }
         if(code == 88 || nav == "gamepad_R3" || declines)
         {
            if(declines && !aDeclines) { logDecline(details,arrow); }
            return false;
         }
         // Esc and B close when released; every other key acts once, on its press (a held arrow keeps moving).
         if(details.value == "keyUp")
         {
            if(code == 27 || nav == "escape-gamepad_B") { close(); event.handled = true; }
            return;
         }
         if(details.value != "keyDown" && !(held && (code == 38 || code == 40 || code == 142 || code == 143 || nav == "up" || nav == "down" || nav == "dpad_up" || nav == "dpad_down"))) { return; }
         // A D-pad press arrives twice, 0 to 10 ms apart: its own code, then the arrow code of the same direction (not from the stick).
         // The list acts on the D-pad code and drops the twin; the stick (fromJoystick) and the keyboard have no D-pad code before them.
         if(pad != "") { dpadDir = pad; dpadAt = getTimer(); }
         else if(arrow != "" && !stick && arrow == dpadDir && getTimer() - dpadAt <= TWIN_MS)
         {
            if(details.value == "keyDown") { padLog("twin dropped " + arrow + " code=" + code + " dt=" + (getTimer() - dpadAt)); }
            event.handled = true;
            return;
         }
         if(details.value == "keyDown" && (pad != "" || stick)) { padLog((pad != "" ? "dpad " + pad : "stick " + arrow) + " code=" + code + " nav=" + nav + " taken"); }
         if(code == 70 || nav == "gamepad_L2") { close(); }
         else if(code == 27 || nav == "escape-gamepad_B") { }
         else if(code == 38 || nav == "up" || nav == "dpad_up") { move(selected - 1); }
         else if(code == 40 || nav == "down" || nav == "dpad_down") { move(selected + 1); }
         else if(code == 37 || code == 39 || nav == "dpad_left" || nav == "dpad_right") { sideKey(pad != "" ? pad : arrow,pad != ""); }
         else if(code == 13 || code == 69 || nav == "enter-gamepad_A") {
            if(padA && selected >= 0 && selected < rows.length && rows[selected].type == ROW_CAT) { if(details.value == "keyDown") { padLog("A on a section header does nothing, Y folds"); } }
            else
            {
               if(padA && details.value == "keyDown") { padLog("A acts on the highlighted row " + selected); }
               activate(selected);
            }
         }
         else if(code == 72 || nav == "gamepad_X") { toggleRegion(); }
         else if(code == 84 || nav == "gamepad_R2") { cycleSort(); }
         else if(code == 67 || nav == "gamepad_Y") { fold(selected); }
         event.handled = true;
      }

      // ---- events and life cycle ----

      private function note(name:String, value:String) : void
      {
         var GameEventClass:Class = getDefinitionByName("red.core.events.GameEvent") as Class;
         dispatchEvent(new GameEventClass("callGameEvent","OnCMFMovieEvent",[drawingId,name,value],true,true));
      }

      private function onAdded(event:Event) : void
      {
         addEventListener(Event.ENTER_FRAME,onFrame);
      }

      private function onRemoved(event:Event) : void
      {
         // CMF releases focus, the pan lock and the highlights itself on removal; the list forgets that it was open.
         removeEventListener(Event.ENTER_FRAME,onFrame);
         rehideUntil = 0;
         if(opened && map && map.hidePanels is Function) { map.hidePanels(null); }
         dropButtons();
         opened = false;
         focused = false;
         lit = [];
         visible = false;
         map = null;
      }
   }
}
