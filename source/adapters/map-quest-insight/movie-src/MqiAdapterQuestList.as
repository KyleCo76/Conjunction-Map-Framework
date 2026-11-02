package
{
   import flash.display.GradientType;
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
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
      // Map Quest Insight's look (Wolfer's values). The panel width does not scale; the row heights and the text
      // sizes scale with the list text size (qmiQjTextSize, default 90).
      private static const PANEL_W:Number = 640;
      private static const HEADER_H:Number = 56;
      private static const QUEST_H:Number = 90;
      private static const FILTER_H:Number = 46;
      private static const ICON_SIZE:Number = 58;
      private static const BOX_SIZE:Number = 22;
      private static const BOX_FILL:Number = 14;
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
      // The stripe of each section header (estimated from the screenshots, which clip bright colours).
      private static const STRIPE_MAIN:uint = 0xFFD402;
      private static const STRIPE_SECONDARY:uint = 0xFFD402;
      private static const STRIPE_AVAILABLE:uint = 0xDEB25C;
      private static const STRIPE_FILTERS:uint = 0xDCD6C8;
      private static const TITLE_COLOR:uint = 0xDEB25C;
      private static const WHITE:uint = 0xFFFFFF;
      private static const OBJ_ON:uint = 0xF0BE38;
      private static const OBJ_OFF:uint = 0xDFDEDE;
      private static const DLC_COLOR:uint = 0x9A9A9A;
      private static const ARROW_COLOR:uint = 0xD8D2C4;
      // Places in map units at text size 100% (the panel's own width, so these do not scale).
      private static const INSET:Number = 22;
      private static const LIST_TOP:Number = 112;
      // The key row sits above the game's own bottom hint row (about 64 units tall, as in Map Quest Insight alone).
      private static const GAME_HINTS_H:Number = 64;
      private static const BAR_LINE:Number = 70 + GAME_HINTS_H;
      private static const HINT_GAP:Number = 28;
      private static const OBJECT_H:Number = 22;
      private static const OBJ_BOX:Number = 13;
      private static const OBJ_BOX_X:Number = 173;
      private static const OBJ_TEXT_X:Number = 190;
      private static const ICON_CX:Number = 62;
      private static const LEVEL_X:Number = 112;
      private static const NAME_X:Number = 168;
      private static const ROW_RIGHT:Number = 610;
      private static const COUNT_RIGHT:Number = 572;
      private static const ARROW_X:Number = 595;
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
      // Quests Available and Quest Filters start folded, as in Map Quest Insight's own list.
      private var folded:Object = {"avail":true,"filters":true};
      private var expanded:Object = {};
      private var filters:Array = [];
      private var thisRegion:Boolean = false;
      private var touched:Boolean = false;
      private var lastArea:String = "";
      private var focusAt:int = 0;

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

      private var bg:Sprite;
      private var bar:Sprite;
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
         bg.filters = [new GlowFilter(0x000000,0.6,5,5,2,1)];
         bar = new Sprite();
         bar.mouseEnabled = false;
         addChild(bar);
         title = field(false);
         counter = field(true);
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
         var keepKey:String = selected >= 0 && selected < rows.length ? rowKey(rows[selected]) : "";
         var i:int = 0;
         data = listened;
         quests = data.quests is Array ? data.quests as Array : [];
         // The first value of an opening names the open number to count from; the list opens only when it grows.
         if(first && lastOpen < 0) { lastOpen = 0; }
         if(first || Number(data.open) > lastOpen)
         {
            sortMode = int(confNum("sort",0));
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
         if(Number(data.open) > lastOpen)
         {
            lastOpen = Number(data.open);
            open(int(Number(data.at)));
            return;
         }
         build(keepId,keepKey);
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

      // CMF brings the hidden panels back on an area change: hide them again (nothing on a CMF without hidePanels).
      private function hidePanelsAgain() : void
      {
         if(map && map.hidePanels is Function) { map.hidePanels(["legend","title","hubBar"]); }
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
         if(!map || !opened) { return; }
         if(focusAt > 0 && getTimer() >= focusAt)
         {
            focusAt = 0;
            if(!focused) { takeFocus(); render(); }
         }
         pins = map.pins;
         if(pins && pins !== pinsRef && (pins as Array).length > 0)
         {
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

      private function build(keepId:Number, keepKey:String = "") : void
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
            for(i = 0; i < 11; i++) { rows.push({"type":ROW_FILTER,"k":i,"label":i < names.length ? names[i] : ""}); }
         }
         selected = 0;
         for(i = 0; i < rows.length; i++)
         {
            if(rows[i].type == ROW_QUEST && Number(rows[i].q.i) == keepId) { selected = i; break; }
         }
         if(keepKey != "") { for(i = 0; i < rows.length; i++) { if(rowKey(rows[i]) == keepKey) { selected = i; break; } } }
         if(selected == 0 && rows.length > 1 && rows[0].type == ROW_CAT) { selected = 1; }
      }

      private function slot(i:int) : Object
      {
         var s:Object = null;
         while(slots.length <= i)
         {
            s = {"left":field(false),"right":field(false),"dist":field(true),"obj":field(true),"lvl":field(false),"icon":new Sprite(),"loader":new Loader(),"url":""};
            s.right.width = 330;
            s.lvl.width = 56;
            s.icon.mouseEnabled = false;
            s.icon.mouseChildren = false;
            s.icon.addChild(s.loader);
            s.loader.contentLoaderInfo.addEventListener(Event.COMPLETE,iconLoaded,false,0,true);
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

      private function fitIcon(s:Object) : void
      {
         var size:Number = ICON_SIZE;
         if(!s.loader.content || !(s.loader.content.width > 0)) { return; }
         s.loader.scaleX = s.loader.scaleY = size / Math.max(s.loader.content.width,s.loader.content.height);
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
               return Math.round(HEADER_H * scale);
            case ROW_QUEST:
               return Math.round(QUEST_H * scale);
            case ROW_OBJECTIVE:
               return Math.round(OBJECT_H * scale);
            default:
               return Math.round(FILTER_H * scale);
         }
         return Math.round(FILTER_H * scale);
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
         bar.graphics.beginGradientFill(GradientType.LINEAR,[HEAD_TOP,HEAD_REST,HEAD_REST],[1,0.85,0.22],[0,128,255],m);
         bar.graphics.drawRect(x,y,w,h);
         bar.graphics.endFill();
         bar.graphics.beginFill(stripe,1);
         bar.graphics.drawRect(x,y,6,h);
         bar.graphics.endFill();
      }

      private function stripeOf(cat:String) : uint
      {
         if(cat == "avail") { return STRIPE_AVAILABLE; }
         if(cat == "filters") { return STRIPE_FILTERS; }
         if(cat == "0") { return STRIPE_MAIN; }
         return STRIPE_SECONDARY;
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
         title.htmlText = span(word("listTitle").toUpperCase(),TITLE_COLOR,32 * scale,true);
         title.x = 20;
         title.width = 280;
         placeLine(title,54,32 * scale);
         if(bold != "" && text.indexOf(bold) == 0)
         {
            counter.htmlText = span(bold,TEXT_ON,20 * scale,true) + span(text.substr(bold.length),WHITE,20 * scale,false);
         }
         else { counter.htmlText = span(text,WHITE,20 * scale,false); }
         counter.x = PANEL_W - INSET + 2 - counter.width;
         placeLine(counter,54,20 * scale);
         counter.visible = text != "";
         sortLine.htmlText = span(word("sort") + ": ",WHITE,18 * scale,false) + span(sortName,WHITE,18 * scale,true) + span(" [T]",TEXT_OFF,18 * scale,false);
         sortLine.x = 20;
         sortLine.width = 200;
         placeLine(sortLine,87,18 * scale);
         levelLine.visible = conf("givers") && Number(data.playerLevel) > 0;
         if(levelLine.visible)
         {
            levelLine.htmlText = "<p align='center'>" + span(word("currentLevel") + ": " + int(data.playerLevel),WHITE,18 * scale,true) + "</p>";
            levelLine.width = 220;
            levelLine.x = 313 - 110;
            placeLine(levelLine,87,18 * scale);
         }
         regionLine.htmlText = span(word("thisRegion") + ": " + (thisRegion ? word("on") : word("off")),TITLE_COLOR,18 * scale,false);
         regionLine.x = PANEL_W - INSET + 2 - regionLine.width;
         placeLine(regionLine,87,18 * scale);
      }

      // The bottom bar: a thin line, and the four keys with their words, centred.
      private function drawHintBar() : void
      {
         var keys:Array = ["F","E","H","T"];
         var words:Array = [word("close"),word("track"),thisRegion ? word("allRegions") : word("thisRegion"),word("sort")];
         var total:Number = 0;
         var x:Number = 0;
         var i:int = 0;
         bar.graphics.beginFill(TRACK_COLOR,1);
         bar.graphics.drawRect(INSET,boxH - BAR_LINE,PANEL_W - 2 * INSET,1);
         bar.graphics.endFill();
         for(i = 0; i < 4; i++)
         {
            hints[i].htmlText = span(keys[i],TEXT_OFF,18 * scale,false) + span("  ",TEXT_OFF,18 * scale,false) + span(words[i],WHITE,20 * scale,false);
            total += hints[i].width;
         }
         x = (PANEL_W - (total + HINT_GAP * 3)) / 2;
         for(i = 0; i < 4; i++)
         {
            hints[i].x = x;
            placeLine(hints[i],boxH - 44 - GAME_HINTS_H,20 * scale);
            hints[i].visible = true;
            x += hints[i].width + HINT_GAP;
         }
      }

      private function render() : void
      {
         var g:Object = bg.graphics;
         var listTop:Number = LIST_TOP;
         var avail:Number = boxH - BAR_LINE - 8 - LIST_TOP;
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
         var colour:uint = 0;
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
         bar.graphics.clear();
         g.clear();
         if(!opened || !data) { return; }
         g.beginFill(PLATE_COLOR,conf("fullScreen") ? 0.68 : 0.78);
         g.drawRect(0,0,boxW,boxH);
         g.endFill();
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
            iconUrl = "";
            checked = false;
            tracked = false;
            s.left.x = 20;
            s.left.width = boxW - 40;
            switch(r.type)
            {
               case ROW_CAT:
                  key = String(r.cat);
                  gradientBar(INSET,y,wide,h,stripeOf(key));
                  s.left.x = 42;
                  left = span(String(r.label).toUpperCase(),TEXT_ON,22 * scale,true);
                  if(r.count >= 0) { distHtml = span(String(r.count),TEXT_ON,22 * scale,true); }
                  if(key != "") { triangle(ARROW_X,y + h / 2,14,10,folded[key] ? 1 : 0,ARROW_COLOR); }
                  if(key != "" && key == selCat)
                  {
                     objLabel = span("C",TEXT_OFF,18 * scale,false) + span("  ",TEXT_OFF,18 * scale,false) + span(word("collapse"),TEXT_ON,18 * scale,false);
                  }
                  break;
               case ROW_QUEST:
                  iconUrl = String(r.q.icon);
                  tint = Number(r.q.band);
                  tracked = r.q.tracked;
                  s.left.x = NAME_X - 2;
                  s.left.width = boxW - NAME_X - INSET;
                  if(int(r.q.lvl) > 0) { lvl = span(String(int(r.q.lvl)),WHITE,30 * scale,true); }
                  left = questText(r.q,String(r.q.name));
                  if(conf("region")) { second = span(String(r.q.region),TEXT_SUB,19 * scale,false); }
                  distHtml = span(distText(r.q),TEXT_SUB,19 * scale,false);
                  if(i == selected && !r.q.avail && r.q.objs is Array && (r.q.objs as Array).length > 0)
                  {
                     objLabel = span(word("objectives"),WHITE,18 * scale,false);
                  }
                  break;
               case ROW_OBJECTIVE:
                  s.left.x = OBJ_TEXT_X - 2;
                  s.left.width = boxW - OBJ_TEXT_X - INSET;
                  colour = int(r.o.state) == 2 ? 0xD61010 : (r.o.tracked ? OBJ_ON : OBJ_OFF);
                  left = span(String(r.o.text),colour,19 * scale,false);
                  break;
               case ROW_REGION:
                  checked = thisRegion;
                  s.left.x = INSET + 12 + BOX_SIZE + 12;
                  left = span(word("thisRegion"),checked ? TEXT_ON : TEXT_OFF,20 * scale,false);
                  break;
               case ROW_FILTER:
                  checked = !filters[int(r.k)];
                  s.left.x = INSET + 12 + BOX_SIZE + 12;
                  left = span(String(r.label),checked ? TEXT_ON : TEXT_OFF,20 * scale,false);
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
            if(r.type == ROW_REGION || r.type == ROW_FILTER) { checkBox(INSET + 12,y + (h - BOX_SIZE) / 2,checked); }
            if(r.type == ROW_OBJECTIVE) { objectiveBox(OBJ_BOX_X,y + (h - OBJ_BOX) / 2,int(r.o.state) == 1); }
            s.left.htmlText = left;
            s.left.visible = true;
            placeLine(s.left,r.type == ROW_QUEST ? y + h * 0.31 : y + h / 2,r.type == ROW_QUEST ? 24 * scale : 20 * scale);
            // The level sits in its own column, centred on the row.
            s.lvl.htmlText = lvl;
            s.lvl.x = LEVEL_X - 2;
            placeLine(s.lvl,y + h / 2,30 * scale);
            s.lvl.visible = lvl != "";
            // The right-hand text: a count or a distance at the right edge, a label before it.
            s.dist.htmlText = distHtml;
            s.dist.x = (r.type == ROW_CAT ? COUNT_RIGHT : ROW_RIGHT) + 2 - s.dist.width;
            placeLine(s.dist,r.type == ROW_QUEST ? y + h * 0.69 : y + h / 2,20 * scale);
            s.dist.visible = distHtml != "";
            s.obj.htmlText = objLabel;
            s.obj.x = (distHtml != "" ? s.dist.x + 2 : (r.type == ROW_CAT ? COUNT_RIGHT : ROW_RIGHT)) - 14 + 2 - s.obj.width;
            placeLine(s.obj,r.type == ROW_QUEST ? y + h * 0.69 : y + h / 2,18 * scale);
            s.obj.visible = objLabel != "";
            if(objLabel != "" && r.type == ROW_QUEST) { triangle(s.obj.x - 4,s.obj.y + s.obj.height / 2,9,6,2,WHITE); }
            // The region line sits under the name.
            s.right.htmlText = second;
            s.right.x = NAME_X - 2;
            placeLine(s.right,y + h * 0.69,19 * scale);
            s.right.visible = second != "";
            if(r.type == ROW_QUEST) { fitName(s.left,r.q); }
            if(iconUrl != "")
            {
               if(s.url != iconUrl)
               {
                  s.url = iconUrl;
                  try { s.loader.load(new URLRequest(iconUrl)); } catch(error:Error) { }
               }
               fitIcon(s);
               // The tracked quest's icon is gold at 0.85 size inside an orange ring with an arrow on each side.
               ring = tracked ? 0.85 : 1;
               s.icon.scaleX = s.icon.scaleY = ring;
               s.icon.x = ICON_CX - ICON_SIZE * ring / 2;
               s.icon.y = y + (h - ICON_SIZE * ring) / 2;
               s.icon.transform.colorTransform = tracked ? tintOf(GOLD) : (tint > 0 ? tintOf(tint) : new ColorTransform());
               s.icon.visible = true;
               if(tracked) { trackedRing(ICON_CX,y + h / 2); }
            }
            y += h;
         }
         drawn = shown;
         // The scroll bar: a 3 px track with a 5 px thumb, at least 24 px tall.
         if(shown < rows.length)
         {
            trackY = listTop;
            trackH = avail;
            thumbH = Math.max(24,trackH * shown / rows.length);
            bar.graphics.beginFill(TRACK_COLOR,0.9);
            bar.graphics.drawRect(boxW - 8,trackY,3,trackH);
            bar.graphics.endFill();
            bar.graphics.beginFill(ACCENT,1);
            bar.graphics.drawRect(boxW - 9,trackY + (trackH - thumbH) * (maxTop > 0 ? top / maxTop : 0),5,thumbH);
            bar.graphics.endFill();
         }
         setChildIndex(bar,1);
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
         return html(name,conf("nameCol") ? String(q.diff) : "#FFFFFF").replace("<font ","<font face='$BoldFont' size='" + Math.round(24 * scale) + "' ") +
            (conf("dlc") && String(q.dlc) != "" ? span("  (" + String(q.dlc) + ")",DLC_COLOR,18 * scale,false) : "");
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
         if(id != "") { want[id] = true; }
         for(key in expanded) { if(expanded[key] && !want[key]) { changed = true; } }
         for(key in want) { if(!expanded[key]) { changed = true; } }
         if(!changed) { return; }
         expanded = want;
         build(-1,rowKey(r));
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
         var keep:int = selected;
         build(selectedQuestId());
         selected = Math.min(keep,rows.length - 1);
         render();
      }

      // H: Only this region on or off; the highlight stays on its row when that row is still listed.
      private function toggleRegion() : void
      {
         var keepId:Number = selectedQuestId();
         var keepKey:String = selected >= 0 && selected < rows.length ? rowKey(rows[selected]) : "";
         thisRegion = !thisRegion;
         note("thisRegion",thisRegion ? "1" : "0");
         build(keepId,keepKey);
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

      private function journal(row:int) : void
      {
         var r:Object = row >= 0 && row < rows.length ? rows[row] : null;
         if(r && r.q && !r.q.avail) { note("journal",String(r.q.i)); }
      }

      private function cycleSort() : void
      {
         sortMode = (sortMode + 1) % 5;
         build(selectedQuestId());
         render();
      }

      private function rowAt(localY:Number) : int
      {
         var listTop:Number = LIST_TOP;
         var row:int = top;
         var edge:Number = listTop;
         if(localY < listTop || localY > boxH - BAR_LINE - 8) { return -1; }
         while(row < rows.length && row < top + drawn)
         {
            edge += heightOf(rows[row]);
            if(localY < edge) { return row; }
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

      public function handleInput(event:Object) : void
      {
         var details:Object = event ? event.details : null;
         var code:int = details ? int(details.code) : 0;
         var nav:String = details ? String(details.navEquivalent) : "";
         var held:Boolean = details && details.value == "keyHold";
         if(!opened || !focused || !details) { return; }
         // A held arrow keeps moving through the list; every other key acts once, on its press.
         if(details.value != "keyDown" && !(held && (code == 38 || code == 40 || nav == "up" || nav == "down" || nav == "dpad_up" || nav == "dpad_down"))) { return; }
         if(code == 27 || code == 70 || nav == "escape-gamepad_B" || nav == "gamepad_L2") { close(); }
         else if(code == 38 || nav == "up" || nav == "dpad_up") { move(selected - 1); }
         else if(code == 40 || nav == "down" || nav == "dpad_down") { move(selected + 1); }
         else if(code == 13 || code == 69 || nav == "enter-gamepad_A") { activate(selected); }
         else if(code == 72) { toggleRegion(); }
         else if(code == 74 || nav == "gamepad_X") { journal(selected); }
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
         if(opened && map && map.hidePanels is Function) { map.hidePanels(null); }
         opened = false;
         focused = false;
         lit = [];
         visible = false;
         map = null;
      }
   }
}
