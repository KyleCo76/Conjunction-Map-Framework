package
{
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.ColorTransform;
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
      private static const ROW_CAT:int = 1;
      private static const ROW_QUEST:int = 2;
      private static const ROW_OBJECTIVE:int = 3;
      private static const ROW_REGION:int = 4;
      private static const ROW_FILTERS:int = 5;
      private static const ROW_FILTER:int = 6;

      private var map:Object;
      private var drawingId:String = "";
      private var boxW:Number = 520;
      private var boxH:Number = 830;
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
      // Quests Available starts folded, as in Map Quest Insight's own list.
      private var folded:Object = {"avail":true};
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

      private var bg:Sprite;
      private var bar:Sprite;
      private var title:TextField;
      private var counter:TextField;
      private var levelLine:TextField;
      private var help:TextField;
      private var slots:Array = [];
      private var rowH:Number = 26;
      private var fontSize:Number = 18;

      public function MqiAdapterQuestList()
      {
         super();
         bg = new Sprite();
         addChild(bg);
         bar = new Sprite();
         bar.mouseEnabled = false;
         addChild(bar);
         title = field(false);
         counter = field(true);
         levelLine = field(false);
         help = field(false);
         help.wordWrap = true;
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
            if(focusAt == 0) { takeFocus(); }
         }
         if(map) { lastArea = curMap(); }
         if(!opened && pendingHome && map && curMap() == String(data.homeMap)) { goHome(); }
         if(entry.number)
         {
            if(Number(entry.number.width) > 0) { boxW = Number(entry.number.width); }
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
         fontSize = 20 * confNum("textSize",90) / 100;
         rowH = Math.round(fontSize * 1.45);
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
         rows.push({"type":ROW_REGION});
         rows.push({"type":ROW_FILTERS});
         for(i = 0; i < 11; i++) { rows.push({"type":ROW_FILTER,"k":i,"label":i < names.length ? names[i] : ""}); }
         selected = 0;
         for(i = 0; i < rows.length; i++)
         {
            if(rows[i].type == ROW_QUEST && Number(rows[i].q.i) == keepId) { selected = i; break; }
         }
         if(keepKey != "") { for(i = 0; i < rows.length; i++) { if(rowKey(rows[i]) == keepKey) { selected = i; break; } } }
         if(selected == 0 && rows.length > 1 && rows[0].type == ROW_CAT) { selected = 1; }
         if(rows[selected] && rows[selected].type == ROW_FILTERS) { selected = 0; }
      }

      private function slot(i:int) : Object
      {
         var s:Object = null;
         while(slots.length <= i)
         {
            s = {"left":field(false),"right":field(true),"icon":new Sprite(),"loader":new Loader(),"url":""};
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
         var size:Number = rowH * 0.8;
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

      private function render() : void
      {
         var g:Object = bg.graphics;
         var listTop:Number = 0;
         var count:int = 0;
         var i:int = 0;
         var r:Object = null;
         var s:Object = null;
         var y:Number = 0;
         var left:String = "";
         var right:String = "";
         var sorts:Array = wordList("sorts");
         var fmt:TextFormat = new TextFormat("$NormalFont",fontSize,0xFFFFFF);
         var small:TextFormat = new TextFormat("$NormalFont",Math.round(fontSize * 0.8),0xBBBBBB);
         var iconUrl:String = "";
         var tint:Number = 0;
         for each(s in slots) { s.left.visible = false; s.right.visible = false; s.icon.visible = false; }
         bar.graphics.clear();
         g.clear();
         if(!opened || !data) { return; }
         g.beginFill(0x000000,conf("fullScreen") ? 0.85 : 0.92);
         g.drawRect(0,0,boxW,boxH);
         g.endFill();
         title.defaultTextFormat = new TextFormat("$BoldFont",Math.round(fontSize * 1.1),0xFFFFFF);
         title.x = 12;
         title.y = 8;
         title.width = boxW - 24;
         title.height = rowH + 6;
         // The region count at the top right; with Quests not started yet on, "Current Level: N" on a line of its own,
         // centred under the title (Map Quest Insight's own list centres it between the sort and its region prompt).
         counter.defaultTextFormat = small;
         counter.htmlText = html(countText(),"#BBBBBB");
         counter.y = title.y + Math.round(rowH * 0.12);
         counter.x = boxW - 14 - counter.width;
         counter.visible = counter.text != "";
         title.width = (counter.visible ? counter.x - 8 : boxW - 12) - title.x;
         title.htmlText = html(word("title"),"#FFFFFF") + "   " + html(sortMode < sorts.length ? sorts[sortMode] : "","#BBBBBB");
         listTop = title.y + rowH + 10;
         levelLine.visible = conf("givers") && Number(data.playerLevel) > 0;
         if(levelLine.visible)
         {
            levelLine.defaultTextFormat = new TextFormat("$NormalFont",Math.round(fontSize * 0.9),0xBBBBBB,null,null,null,null,null,"center");
            levelLine.x = 12;
            levelLine.width = boxW - 24;
            levelLine.height = rowH;
            levelLine.y = listTop - 6;
            levelLine.htmlText = "<p align='center'>" + html(word("currentLevel") + ": " + int(data.playerLevel),"#BBBBBB") + "</p>";
         }
         listTop = listStart();
         help.defaultTextFormat = small;
         help.x = 12;
         help.width = boxW - 24;
         help.height = rowH * 2.2;
         help.y = boxH - help.height - 6;
         help.htmlText = html(word("help"),"#BBBBBB");
         count = Math.max(1,int((help.y - listTop - 4) / rowH));
         if(selected < top) { top = selected; }
         if(selected >= top + count) { top = selected - count + 1; }
         top = Math.max(0,Math.min(top,Math.max(0,rows.length - count)));
         for(i = top; i < Math.min(rows.length,top + count); i++)
         {
            r = rows[i];
            s = slot(i - top);
            y = listTop + (i - top) * rowH;
            left = "";
            right = "";
            iconUrl = "";
            s.left.defaultTextFormat = fmt;
            s.right.defaultTextFormat = small;
            s.left.x = 12;
            switch(r.type)
            {
               case ROW_CAT:
                  left = html((folded[r.cat] ? "+ " : "- ") + String(r.label) + (r.count >= 0 ? "  (" + r.count + ")" : ""),"#E0C890");
                  break;
               case ROW_QUEST:
                  iconUrl = String(r.q.icon);
                  tint = Number(r.q.band);
                  s.left.x = 12 + rowH;
                  left = questText(r.q,String(r.q.name));
                  right = (conf("region") ? html(String(r.q.region),"#BBBBBB") + "  " : "") + html(distText(r.q),"#BBBBBB");
                  if(r.q.tracked)
                  {
                     bar.graphics.beginFill(GOLD,1);
                     bar.graphics.drawRect(3,y + 3,4,rowH - 6);
                     bar.graphics.endFill();
                  }
                  break;
               case ROW_OBJECTIVE:
                  s.left.x = 12 + rowH * 1.5;
                  left = html((int(r.o.state) == 1 ? "[x] " : "[ ] ") + String(r.o.text),
                     int(r.o.state) == 2 ? "#D61010" : (r.o.tracked ? hex(GOLD) : (int(r.o.state) == 1 ? "#8A8A8A" : "#DDDDDD")));
                  break;
               case ROW_REGION:
                  left = html((thisRegion ? "[x] " : "[ ] ") + word("thisRegion"),"#DDDDDD");
                  break;
               case ROW_FILTERS:
                  left = html(word("filters"),"#E0C890");
                  break;
               case ROW_FILTER:
                  left = html((filters[int(r.k)] ? "[ ] " : "[x] ") + String(r.label),"#DDDDDD");
                  break;
            }
            if(i == selected)
            {
               bar.graphics.beginFill(0xFFFFFF,focused ? 0.16 : 0.08);
               bar.graphics.drawRect(8,y,boxW - 16,rowH);
               bar.graphics.endFill();
            }
            s.left.width = boxW - s.left.x - 12;
            s.left.height = rowH;
            s.left.y = y + 1;
            s.left.htmlText = left;
            s.left.visible = true;
            s.right.y = y + Math.round(rowH * 0.12);
            s.right.htmlText = right;
            // The field sizes itself to its text, so its right edge is placed after the text is set: a reused
            // row keeps its previous width and would otherwise start at the edge and run off the list.
            s.right.x = boxW - 14 - s.right.width;
            s.right.visible = right != "";
            if(right != "")
            {
               // The name gives way to the region and distance on the right.
               s.left.width = Math.max(40,s.right.x - s.left.x - 8);
            }
            if(r.type == ROW_QUEST) { fitName(s.left,r.q); }
            if(iconUrl != "")
            {
               if(s.url != iconUrl)
               {
                  s.url = iconUrl;
                  try { s.loader.load(new URLRequest(iconUrl)); } catch(error:Error) { }
               }
               fitIcon(s);
               s.icon.x = 12;
               s.icon.y = y + rowH * 0.1;
               s.icon.transform.colorTransform = r.q.tracked ? tintOf(GOLD) : (tint > 0 ? tintOf(tint) : new ColorTransform());
               s.icon.visible = true;
            }
         }
         setChildIndex(bar,1);
      }

      // "%r: %n/%t active quests": the shown map's region, your active quests there and in all regions, without the
      // types the filter rows leave out (Only this region does not change the total). Quests not started yet never count.
      private function countText() : String
      {
         var q:Object = null;
         var region:String = "";
         var here:int = 0;
         var all:int = 0;
         var text:String = "";
         for each(q in quests)
         {
            if(String(q.map) == curMap() && region == "") { region = String(q.region); }
            if(!counted(q)) { continue; }
            all++;
            if(String(q.map) == curMap()) { here++; }
         }
         for each(q in available()) { if(region == "" && String(q.map) == curMap()) { region = String(q.region); } }
         if(region == "") { return ""; }
         text = all == 0 ? word("regionNone") : (all == 1 ? word("regionCountOne") : word("regionCount"));
         return text.split("%r").join(region).split("%n").join(String(here)).split("%t").join(String(all));
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

      private function questText(q:Object, name:String) : String
      {
         return (int(q.lvl) > 0 ? html(word("level") + " " + int(q.lvl) + "  ",hex(Number(q.band) > 0 ? Number(q.band) : 0xFFFFFF)) : "") +
            html(name,conf("nameCol") ? String(q.diff) : "#FFFFFF") +
            (conf("dlc") && String(q.dlc) != "" ? html("  " + String(q.dlc),"#9A9A9A") : "");
      }

      // A name too long for its row ends in an ellipsis instead of being cut off at the region column.
      private function fitName(f:TextField, q:Object) : void
      {
         var name:String = String(q.name);
         while(f.textWidth > f.width - 6 && name.length > 1)
         {
            name = name.substr(0,name.length - 1);
            f.htmlText = questText(q,name.replace(/\s+$/,"") + "\u2026");
         }
      }

      private function tintOf(rgb:Number) : ColorTransform
      {
         return new ColorTransform(((uint(rgb) >> 16) & 255) / 255,((uint(rgb) >> 8) & 255) / 255,(uint(rgb) & 255) / 255,1,0,0,0,0);
      }

      // ---- actions ----

      // Objective lines cannot be selected (Map Quest Insight 2.1.0): the highlight steps over them and the filters
      // heading. An open objective list closes when the highlight leaves its quest, and with "Show objectives on
      // highlight" (qmiQjObjHover) the highlighted quest's list opens by itself.
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
         return r.type == ROW_FILTERS || r.type == ROW_OBJECTIVE;
      }

      private function followObjectives() : void
      {
         var r:Object = selected >= 0 && selected < rows.length ? rows[selected] : null;
         var want:Object = {};
         var id:String = r && r.q && !r.q.avail ? String(r.q.i) : "";
         var key:String = "";
         var changed:Boolean = false;
         if(id != "" && (expanded[id] || conf("objHover"))) { want[id] = true; }
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
               thisRegion = !thisRegion;
               note("thisRegion",thisRegion ? "1" : "0");
               rebuild();
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

      private function fold(row:int) : void
      {
         var r:Object = rows[row];
         var cat:String = r.type == ROW_CAT ? String(r.cat) : (r.q ? String(r.q.cat) : "");
         var i:int = 0;
         if(cat == "") { return; }
         folded[cat] = !folded[cat];
         build(-1);
         for(i = 0; i < rows.length; i++) { if(rows[i].type == ROW_CAT && String(rows[i].cat) == cat) { selected = i; break; } }
         render();
      }

      private function objectives(row:int, on:Boolean) : void
      {
         var r:Object = row >= 0 && row < rows.length ? rows[row] : null;
         if(!r || !r.q || r.q.avail) { return; }
         if(Boolean(expanded[String(r.q.i)]) == on) { return; }
         expanded[String(r.q.i)] = on;
         build(Number(r.q.i));
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

      // The first row's top: under the title, and under the Current Level line while it shows.
      private function listStart() : Number
      {
         return title.y + rowH + 10 + (levelLine.visible ? rowH - 2 : 0);
      }

      private function rowAt(localY:Number) : int
      {
         var listTop:Number = listStart();
         var row:int = top + int((localY - listTop) / rowH);
         if(localY < listTop || localY > help.y || row < 0 || row >= rows.length) { return -1; }
         return row;
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
         else if(code == 39 || nav == "right" || nav == "dpad_right") { objectives(selected,true); }
         else if(code == 37 || nav == "left" || nav == "dpad_left") { objectives(selected,false); }
         else if(code == 13 || code == 69 || nav == "enter-gamepad_A") { activate(selected); }
         else if(code == 72 || nav == "gamepad_X") { journal(selected); }
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
         opened = false;
         focused = false;
         lit = [];
         visible = false;
         map = null;
      }
   }
}
