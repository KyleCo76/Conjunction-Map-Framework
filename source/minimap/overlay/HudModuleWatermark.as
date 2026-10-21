package red.game.witcher3.hud.modules
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Loader;
   import flash.display.MovieClip;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   import flash.net.URLRequest;
   import flash.utils.Dictionary;
   import flash.utils.getQualifiedClassName;
   import red.core.events.GameEvent;

   // CMF minimap add-on. This movie is the game's unused watermark movie, shipped as the HUD's unused
   // hud_pickeditemsinfo slot, so it replaces no file. It draws nothing itself: it finds whichever minimap
   // is loaded, reads each pin's type from its PinIcon class, and adds CMF art or tint to claimed pins only.
   // It never moves, scales or hides the minimap, and touches only what it adds (its own layer inside a
   // claimed pin, PinIcon.mask and PinIcon's colour multipliers), restoring them when a claim goes away.
   [SWF(width="600", height="70", backgroundColor="#000000", frameRate="24")]
   public class HudModuleWatermark extends HudModuleBase
   {

      private static const MINIMAP_MODULE:String = "Minimap2Module";

      private static const REPORT_LIMIT:int = 300;

      private var cmfStyles:Object = new Object();

      private var cmfRevision:int = 0;

      private var cmfPins:Dictionary = new Dictionary(true);

      private var cmfMinimap:DisplayObject;

      private var cmfPinLayers:Array;

      private var cmfReported:int = 0;

      private var cmfListening:Boolean = false;

      public function HudModuleWatermark()
      {
         addFrameScript(0,this.frame1);
         super();
      }

      override public function get moduleName() : String
      {
         return "PickedItemsInfoModule";
      }

      override protected function onCoreInit() : void
      {
         // The movie is on the HUD stage; tell the HUD's script before registering, so a launch log
         // shows whether a failure is in loading the movie or in the game binding the part.
         if(parent)
         {
            parent.dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMinimapAddonLoaded",[getQualifiedClassName(parent)]));
         }
         super.onCoreInit();
      }

      override protected function configUI() : void
      {
         super.configUI();
         visible = true;
         alpha = 0;
         dispatchEvent(new GameEvent(GameEvent.CALL,"OnConfigUI"));
      }

      public function CMFClearTypeStyles() : *
      {
         this.cmfStyles = new Object();
      }

      public function CMFSetTypeStyle(param1:String, param2:String, param3:int, param4:Boolean) : *
      {
         this.cmfStyles[param1] = {
            "iconPath":param2,
            "tint":uint(param3),
            "tintEnabled":param4
         };
      }

      public function CMFApplyTypeStyles() : *
      {
         ++this.cmfRevision;
         this.CMFTick();
      }

      // Called by the script every HUD tick and by the stage every frame; cheap when nothing changed.
      public function CMFTick() : *
      {
         var _loc1_:int = 0;
         var _loc2_:DisplayObjectContainer = null;
         var _loc3_:int = 0;
         if(!this.cmfListening && stage)
         {
            stage.addEventListener(Event.ENTER_FRAME,this.cmfOnFrame,false,0,true);
            this.cmfListening = true;
         }
         if(!this.cmfFindMinimap())
         {
            return;
         }
         _loc1_ = 0;
         while(_loc1_ < this.cmfPinLayers.length)
         {
            _loc2_ = this.cmfPinLayers[_loc1_] as DisplayObjectContainer;
            if(_loc2_)
            {
               _loc3_ = 0;
               while(_loc3_ < _loc2_.numChildren)
               {
                  this.cmfCheckPin(_loc2_.getChildAt(_loc3_) as MovieClip);
                  _loc3_++;
               }
            }
            _loc1_++;
         }
      }

      private function cmfOnFrame(param1:Event) : void
      {
         this.CMFTick();
      }

      private function cmfFindMinimap() : Boolean
      {
         var _loc1_:DisplayObject = null;
         var _loc2_:Object = null;
         var _loc3_:DisplayObjectContainer = null;
         var _loc4_:int = 0;
         if(Boolean(this.cmfMinimap) && Boolean(this.cmfMinimap.stage) && Boolean(this.cmfPinLayers))
         {
            return true;
         }
         this.cmfMinimap = null;
         this.cmfPinLayers = null;
         _loc1_ = this.cmfFindModule(stage,MINIMAP_MODULE,6);
         if(!_loc1_)
         {
            return false;
         }
         try
         {
            _loc2_ = Object(_loc1_).mcCommonMap;
            _loc3_ = _loc2_ ? _loc2_.mcCommonMapContainer as DisplayObjectContainer : null;
         }
         catch(e:Error)
         {
            _loc3_ = null;
         }
         if(!_loc3_)
         {
            return false;
         }
         this.cmfMinimap = _loc1_;
         this.cmfPinLayers = new Array();
         _loc4_ = 0;
         while(_loc4_ < _loc3_.numChildren)
         {
            if(_loc3_.getChildAt(_loc4_) is DisplayObjectContainer)
            {
               this.cmfPinLayers.push(_loc3_.getChildAt(_loc4_));
            }
            _loc4_++;
         }
         dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMinimapFound",[getQualifiedClassName(_loc1_),this.cmfPinLayers.length]));
         return true;
      }

      private function cmfFindModule(param1:DisplayObjectContainer, param2:String, param3:int) : DisplayObject
      {
         var _loc4_:int = 0;
         var _loc5_:DisplayObject = null;
         var _loc6_:DisplayObject = null;
         if(!param1 || param3 <= 0)
         {
            return null;
         }
         _loc4_ = 0;
         while(_loc4_ < param1.numChildren)
         {
            _loc5_ = param1.getChildAt(_loc4_);
            if(_loc5_ != this && _loc5_.hasOwnProperty("moduleName") && Object(_loc5_).moduleName == param2)
            {
               return _loc5_;
            }
            _loc4_++;
         }
         _loc4_ = 0;
         while(_loc4_ < param1.numChildren)
         {
            _loc5_ = param1.getChildAt(_loc4_);
            if(_loc5_ != this && _loc5_ is DisplayObjectContainer)
            {
               _loc6_ = this.cmfFindModule(DisplayObjectContainer(_loc5_),param2,param3 - 1);
               if(_loc6_)
               {
                  return _loc6_;
               }
            }
            _loc4_++;
         }
         return null;
      }

      private function cmfCheckPin(param1:MovieClip) : void
      {
         var _loc2_:MovieClip = null;
         var _loc3_:Object = null;
         if(!param1)
         {
            return;
         }
         try
         {
            _loc2_ = param1["PinIcon"] as MovieClip;
         }
         catch(e:Error)
         {
            _loc2_ = null;
         }
         _loc3_ = this.cmfPins[param1];
         if(!_loc3_ || _loc3_.icon != _loc2_ || _loc3_.revision != this.cmfRevision)
         {
            this.cmfResetPin(param1,_loc3_);
            _loc3_ = this.cmfApplyPin(param1,_loc2_,!_loc3_ || _loc3_.icon != _loc2_);
            this.cmfPins[param1] = _loc3_;
         }
         if(Boolean(_loc3_.layer) && Boolean(_loc2_))
         {
            _loc3_.layer.transform.matrix = _loc2_.transform.matrix;
            _loc3_.layer.visible = _loc2_.visible;
            _loc3_.layer.alpha = _loc2_.alpha;
         }
      }

      private function cmfTypeOf(param1:MovieClip) : String
      {
         var _loc2_:String = null;
         if(!param1)
         {
            return "";
         }
         _loc2_ = getQualifiedClassName(param1);
         if(_loc2_.indexOf("class") == 0)
         {
            return _loc2_.substr(5);
         }
         return "";
      }

      private function cmfStyleOf(param1:String) : Object
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         if(!param1)
         {
            return null;
         }
         _loc2_ = this.cmfStyles[param1];
         if(_loc2_)
         {
            return _loc2_;
         }
         _loc3_ = param1.lastIndexOf("_");
         if(_loc3_ > 0 && _loc3_ < param1.length - 1 && !isNaN(Number(param1.substr(_loc3_ + 1))))
         {
            return this.cmfStyles[param1.substr(0,_loc3_)];
         }
         return null;
      }

      private function cmfApplyPin(param1:MovieClip, param2:MovieClip, param3:Boolean) : Object
      {
         var _loc4_:Object = {
            "icon":param2,
            "revision":this.cmfRevision,
            "layer":null
         };
         var _loc5_:String = this.cmfTypeOf(param2);
         var _loc6_:Object = this.cmfStyleOf(_loc5_);
         var _loc7_:ColorTransform = null;
         var _loc8_:ColorTransform = null;
         var _loc9_:Loader = null;
         if(param3 && Boolean(param2) && this.cmfReported < REPORT_LIMIT)
         {
            ++this.cmfReported;
            dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMinimapPin",[_loc5_,param1.x,param1.y,_loc6_ != null]));
         }
         if(!_loc6_ || !param2)
         {
            return _loc4_;
         }
         _loc4_.type = _loc5_;
         if(_loc6_.tintEnabled)
         {
            _loc7_ = param2.transform.colorTransform;
            _loc4_.base = [_loc7_.redMultiplier,_loc7_.greenMultiplier,_loc7_.blueMultiplier,_loc7_.redOffset,_loc7_.greenOffset,_loc7_.blueOffset];
            _loc8_ = new ColorTransform((_loc6_.tint >> 16 & 255) / 255,(_loc6_.tint >> 8 & 255) / 255,(_loc6_.tint & 255) / 255,1,0,0,0,0);
            _loc8_.concat(_loc7_);
            param2.transform.colorTransform = _loc8_;
            _loc4_.tint = new ColorTransform((_loc6_.tint >> 16 & 255) / 255,(_loc6_.tint >> 8 & 255) / 255,(_loc6_.tint & 255) / 255,1,0,0,0,0);
         }
         if(_loc6_.iconPath)
         {
            _loc4_.bounds = param2.getBounds(param2);
            _loc4_.layer = new Sprite();
            _loc4_.layer.mouseEnabled = false;
            _loc4_.layer.mouseChildren = false;
            _loc4_.layer.transform.matrix = param2.transform.matrix;
            if(_loc4_.tint)
            {
               _loc4_.layer.transform.colorTransform = _loc4_.tint;
            }
            _loc4_.mask = new Shape();
            _loc4_.mask.graphics.beginFill(0,0);
            _loc4_.mask.graphics.drawRect(-100000,-100000,1,1);
            _loc4_.mask.graphics.endFill();
            _loc4_.layer.addChild(_loc4_.mask);
            _loc9_ = new Loader();
            _loc9_.mouseEnabled = false;
            _loc9_.mouseChildren = false;
            _loc9_.visible = false;
            _loc4_.loader = _loc9_;
            _loc4_.url = _loc6_.iconPath;
            _loc4_.layer.addChild(_loc9_);
            param1.addChild(_loc4_.layer);
            _loc9_.contentLoaderInfo.addEventListener(Event.COMPLETE,this.cmfOnArtLoaded,false,0,true);
            _loc9_.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,this.cmfOnArtFailed,false,0,true);
            _loc9_.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.cmfOnArtFailed,false,0,true);
            try
            {
               _loc9_.load(new URLRequest(_loc6_.iconPath));
            }
            catch(e:Error)
            {
               this.cmfDropArt(_loc4_);
            }
         }
         return _loc4_;
      }

      private function cmfRecordOfLoader(param1:Object) : Object
      {
         var _loc2_:Object = null;
         for each(_loc2_ in this.cmfPins)
         {
            if(Boolean(_loc2_) && Boolean(_loc2_.loader) && _loc2_.loader.contentLoaderInfo == param1)
            {
               return _loc2_;
            }
         }
         return null;
      }

      private function cmfOnArtLoaded(param1:Event) : void
      {
         var _loc2_:Object = this.cmfRecordOfLoader(param1.target);
         var _loc3_:Loader = null;
         var _loc4_:Rectangle = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         if(!_loc2_ || !_loc2_.icon)
         {
            return;
         }
         _loc3_ = _loc2_.loader;
         if(_loc3_.content is Bitmap)
         {
            Bitmap(_loc3_.content).smoothing = true;
         }
         _loc4_ = _loc2_.bounds;
         _loc5_ = Math.max(_loc4_.width,_loc4_.height);
         _loc6_ = Math.max(_loc3_.contentLoaderInfo.width,_loc3_.content ? _loc3_.content.width : 0);
         _loc7_ = Math.max(_loc3_.contentLoaderInfo.height,_loc3_.content ? _loc3_.content.height : 0);
         if(_loc5_ <= 0)
         {
            _loc5_ = 32;
         }
         if(_loc6_ <= 0 || _loc7_ <= 0)
         {
            this.cmfDropArt(_loc2_);
            return;
         }
         _loc3_.scaleX = _loc3_.scaleY = _loc5_ / Math.max(_loc6_,_loc7_);
         _loc3_.x = _loc4_.x + (_loc4_.width - _loc6_ * _loc3_.scaleX) / 2;
         _loc3_.y = _loc4_.y + (_loc4_.height - _loc7_ * _loc3_.scaleY) / 2;
         if(_loc2_.icon.mask == null)
         {
            _loc2_.icon.mask = _loc2_.mask;
            _loc2_.masked = true;
         }
         _loc3_.visible = true;
      }

      private function cmfOnArtFailed(param1:Event) : void
      {
         var _loc2_:Object = this.cmfRecordOfLoader(param1.target);
         if(_loc2_)
         {
            dispatchEvent(new GameEvent(GameEvent.CALL,"OnCMFMinimapArtFailed",[String(_loc2_.url)]));
            this.cmfDropArt(_loc2_);
         }
      }

      private function cmfDropArt(param1:Object) : void
      {
         var _loc2_:Loader = param1.loader;
         param1.loader = null;
         if(Boolean(param1.masked) && Boolean(param1.icon) && param1.icon.mask == param1.mask)
         {
            param1.icon.mask = null;
         }
         param1.masked = false;
         if(_loc2_)
         {
            _loc2_.contentLoaderInfo.removeEventListener(Event.COMPLETE,this.cmfOnArtLoaded);
            _loc2_.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,this.cmfOnArtFailed);
            _loc2_.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,this.cmfOnArtFailed);
            try
            {
               _loc2_.close();
            }
            catch(e:Error)
            {
               _loc2_.visible = false;
            }
         }
         if(Boolean(param1.layer) && Boolean(param1.layer.parent))
         {
            param1.layer.parent.removeChild(param1.layer);
         }
         param1.layer = null;
      }

      private function cmfResetPin(param1:MovieClip, param2:Object) : void
      {
         var _loc3_:ColorTransform = null;
         if(!param2)
         {
            return;
         }
         this.cmfDropArt(param2);
         if(Boolean(param2.base) && Boolean(param2.icon))
         {
            _loc3_ = param2.icon.transform.colorTransform;
            _loc3_.redMultiplier = param2.base[0];
            _loc3_.greenMultiplier = param2.base[1];
            _loc3_.blueMultiplier = param2.base[2];
            _loc3_.redOffset = param2.base[3];
            _loc3_.greenOffset = param2.base[4];
            _loc3_.blueOffset = param2.base[5];
            param2.icon.transform.colorTransform = _loc3_;
         }
         param2.base = null;
      }

      internal function frame1() : *
      {
         stop();
      }
   }
}
