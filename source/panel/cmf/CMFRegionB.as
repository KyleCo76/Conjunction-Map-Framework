// CMF S03e-B owned projection. Decompiler pseudocode; raw oracle is authoritative.

// MapMenu
public function CMFRegionSigned(param1:*) : *
      {
         if(param1 is String)
         {
            if(param1.length > 0)
            {
               if(param1.length <= 11)
               {
                  var _loc2_:* = 0;
                  var _loc3_:* = 0;
                  var _loc4_:int = 1;
                  if(param1.charAt(0) !== "-")
                  {
                     addr0057:
                     var _loc6_:* = param1.charAt(_loc2_);
                     if(_loc6_ !== "0")
                     {
                        while(true)
                        {
                           if(_loc2_ >= param1.length)
                           {
                              return _loc3_ * _loc4_;
                           }
                           var _loc5_:* = param1.charCodeAt(_loc2_);
                           if(_loc5_ < 48)
                           {
                              break;
                           }
                           if(_loc5_ > 57)
                           {
                              break;
                           }
                           _loc3_ = _loc3_ * 10 + (_loc5_ - 48);
                           if(_loc3_ > 2147483647)
                           {
                              break;
                           }
                           _loc2_ += 1;
                        }
                     }
                     else if(param1 === "0")
                     {
                        return 0;
                     }
                  }
                  else
                  {
                     _loc2_ = 1;
                     _loc4_ = -1;
                     if(param1.length > 1)
                     {
                        §§goto(addr0057);
                     }
                  }
               }
            }
         }
         return null;
      }

// MapMenu
public function CMFRegionDecode(param1:*) : *
      {
         if(param1 is String)
         {
            if(param1.length <= 1024)
            {
               var _loc2_:* = param1.split("|");
               if(_loc2_.length === 26)
               {
                  if(_loc2_.shift() === "CMFG1")
                  {
                     var _loc3_:Object = new Object();
                     var _loc4_:Object = new Object();
                     _loc3_.tuple = _loc4_;
                     var _loc5_:* = this.CMFRegionSigned(_loc2_.shift());
                     if(_loc5_ is Number)
                     {
                        if(_loc5_ > 0)
                        {
                           if(_loc5_ <= 9999)
                           {
                              _loc3_.revision = _loc5_;
                              _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                              if(_loc5_ is Number)
                              {
                                 if(_loc5_ > 0)
                                 {
                                    if(_loc5_ <= 64)
                                    {
                                       _loc3_.row = _loc5_;
                                       _loc5_ = _loc2_.shift();
                                       if(this.CMFRoleText(_loc5_,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_",64))
                                       {
                                          _loc3_.provider = _loc5_;
                                          _loc5_ = _loc2_.shift();
                                          if(this.CMFRoleText(_loc5_,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_",64))
                                          {
                                             _loc3_.region = _loc5_;
                                             _loc5_ = _loc2_.shift();
                                             if(this.CMFRoleText(_loc5_,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_",64))
                                             {
                                                _loc3_.root = _loc5_;
                                                if(_loc3_.provider.indexOf("mod") === 0)
                                                {
                                                   if(_loc3_.provider.length > 3)
                                                   {
                                                      _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                      if(_loc5_ is Number)
                                                      {
                                                         if(_loc5_ >= 0)
                                                         {
                                                            if(_loc5_ <= 22)
                                                            {
                                                               _loc3_.failureUse = _loc5_;
                                                               _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                               if(_loc5_ is Number)
                                                               {
                                                                  _loc4_.minZoom = _loc5_ / 1000;
                                                                  _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                  if(_loc5_ is Number)
                                                                  {
                                                                     _loc4_.maxZoom = _loc5_ / 1000;
                                                                     _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                     if(_loc5_ is Number)
                                                                     {
                                                                        _loc4_.zoom12 = _loc5_ / 1000;
                                                                        _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                        if(_loc5_ is Number)
                                                                        {
                                                                           _loc4_.zoom23 = _loc5_ / 1000;
                                                                           _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                           if(_loc5_ is Number)
                                                                           {
                                                                              _loc4_.zoom34 = _loc5_ / 1000;
                                                                              _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                              if(_loc5_ is Number)
                                                                              {
                                                                                 _loc4_.visMinX = _loc5_ / 1000;
                                                                                 _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                 if(_loc5_ is Number)
                                                                                 {
                                                                                    _loc4_.visMaxX = _loc5_ / 1000;
                                                                                    _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                    if(_loc5_ is Number)
                                                                                    {
                                                                                       _loc4_.visMinY = _loc5_ / 1000;
                                                                                       _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                       if(_loc5_ is Number)
                                                                                       {
                                                                                          _loc4_.visMaxY = _loc5_ / 1000;
                                                                                          _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                          if(_loc5_ is Number)
                                                                                          {
                                                                                             _loc4_.gradient = _loc5_ / 1000;
                                                                                             _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                             if(_loc5_ is Number)
                                                                                             {
                                                                                                _loc4_.scrollMinX = _loc5_ / 1000;
                                                                                                _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                if(_loc5_ is Number)
                                                                                                {
                                                                                                   _loc4_.scrollMaxX = _loc5_ / 1000;
                                                                                                   _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                   if(_loc5_ is Number)
                                                                                                   {
                                                                                                      _loc4_.scrollMinY = _loc5_ / 1000;
                                                                                                      _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                      if(_loc5_ is Number)
                                                                                                      {
                                                                                                         _loc4_.scrollMaxY = _loc5_ / 1000;
                                                                                                         _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                         if(_loc5_ is Number)
                                                                                                         {
                                                                                                            _loc4_.mapSize = _loc5_ / 1000;
                                                                                                            _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                            if(_loc5_ is Number)
                                                                                                            {
                                                                                                               _loc4_.tileCount = _loc5_ / 1000;
                                                                                                               _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                               if(_loc5_ is Number)
                                                                                                               {
                                                                                                                  _loc4_.textureSize = _loc5_ / 1000;
                                                                                                                  _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                                  if(_loc5_ is Number)
                                                                                                                  {
                                                                                                                     _loc4_.minLod = _loc5_ / 1000;
                                                                                                                     _loc5_ = this.CMFRegionSigned(_loc2_.shift());
                                                                                                                     if(_loc5_ is Number)
                                                                                                                     {
                                                                                                                        _loc4_.maxLod = _loc5_ / 1000;
                                                                                                                        _loc4_.imageRoot = _loc3_.root;
                                                                                                                        _loc4_.previewAvailable = true;
                                                                                                                        _loc4_.previewMode = 1;
                                                                                                                        if(this.mcHubMap.CMFRegionValid(_loc4_))
                                                                                                                        {
                                                                                                                           if(_loc4_.minLod === 1)
                                                                                                                           {
                                                                                                                              if(_loc4_.maxLod === 2)
                                                                                                                              {
                                                                                                                                 if(_loc4_.zoom12 > _loc4_.minZoom)
                                                                                                                                 {
                                                                                                                                    if(_loc4_.zoom12 < _loc4_.maxZoom)
                                                                                                                                    {
                                                                                                                                       if(_loc4_.textureSize !== 1024)
                                                                                                                                       {
                                                                                                                                          if(_loc4_.textureSize !== 2048)
                                                                                                                                          {
                                                                                                                                             §§goto(addr043a);
                                                                                                                                          }
                                                                                                                                       }
                                                                                                                                       return _loc3_;
                                                                                                                                    }
                                                                                                                                 }
                                                                                                                              }
                                                                                                                           }
                                                                                                                        }
                                                                                                                     }
                                                                                                                  }
                                                                                                               }
                                                                                                            }
                                                                                                         }
                                                                                                      }
                                                                                                   }
                                                                                                }
                                                                                             }
                                                                                          }
                                                                                       }
                                                                                    }
                                                                                 }
                                                                              }
                                                                           }
                                                                        }
                                                                     }
                                                                  }
                                                               }
                                                            }
                                                         }
                                                      }
                                                   }
                                                }
                                             }
                                          }
                                       }
                                    }
                                 }
                              }
                           }
                        }
                     }
                  }
               }
            }
         }
         addr043a:
         return null;
      }

// HubMap
public function CMFRegionIdle() : *
      {
         if(!this.CMFRegionGuard)
         {
            if(!this._snapTween1)
            {
               if(!this._snapTween2)
               {
                  if(!this._transitionTween)
                  {
                     return true;
                  }
               }
            }
         }
         return false;
      }

// HubMap
public function CMFRegionBlock(param1:*) : void
      {
         this.CMFRegionBlocked = param1;
         if(!param1)
         {
            return;
         }
         this.ResetKeyboardInput();
         this.mcHubMapPreview.mouseDragInProgress = false;
      }

// HubMap
public function CMFRegionView() : *
      {
         return [this.MapXToWorldX(-this.mcHubMapZoomContainer.mcHubMapContainer.x),this.MapYToWorldY(-this.mcHubMapZoomContainer.mcHubMapContainer.y),this.mcHubMapZoomContainer.actualScaleX];
      }

// HubMap
public function CMFRegionRestoreView(param1:*) : void
      {
         param1 = param1.concat();
         var _loc2_:* = param1.shift();
         var _loc3_:* = param1.shift();
         var _loc4_:* = param1.shift();
         if(_loc4_ >= this._minZoom)
         {
            if(_loc4_ > this._maxZoom)
            {
               _loc4_ = this._maxZoom;
            }
         }
         else
         {
            _loc4_ = this._minZoom;
         }
         this.mcHubMapZoomContainer.setActualScale(_loc4_,_loc4_);
         this.mcHubMapZoomContainer.mcHubMapContainer.setImmediatePosition(-this.WorldXToMapX(_loc2_),-this.WorldYToMapY(_loc3_));
         this.mcHubMapPinContainer.x = this.mcHubMapZoomContainer.mcHubMapContainer.x * this.GetScale();
         this.mcHubMapPinContainer.y = this.mcHubMapZoomContainer.mcHubMapContainer.y * this.GetScale();
         this.UpdateVisibilityAndPinPositions(true);
         this.UpdateSizeForAreaMapPins(this.GetComponentScale());
         this.UpdateLod(true);
      }

// MapMenu
public function CMFRegionInputAllowed(param1:*) : *
      {
         if(this.m_currentLayer === this.LAYER_HUB)
         {
            if(!this.mcHubMap.CMFRegionBlocked)
            {
               return true;
            }
            if(param1.details.code !== KeyCode.ESCAPE)
            {
               if(param1.details.code !== KeyCode.PAD_B_CIRCLE)
               {
                  if(param1.details.code !== KeyCode.SPACE)
                  {
                     if(param1.details.code !== KeyCode.PAD_Y_TRIANGLE)
                     {
                        if(param1.details.code !== KeyCode.PAD_X_SQUARE)
                        {
                           return false;
                        }
                     }
                  }
               }
            }
         }
         return true;
      }

// MapMenu
public function CMFRegionFaultLayer() : void
      {
         if(this.CMFRegionLoading)
         {
            var _loc1_:* = this.CMFRegionLoading.active;
            if(_loc1_)
            {
               if(_loc1_.message)
               {
                  if(_loc1_.phase === "fault")
                  {
                     _loc1_.message.visible = this.mcHubMap.IsEnabled();
                  }
               }
            }
         }
      }

// LodContainer
public function CMFRegionAttach() : void
      {
         this.addChild(this._backgroundContainer);
         var _loc1_:* = this._minLod;
         while(_loc1_ <= this._maxLod)
         {
            this.addChild(this.GetContainer(_loc1_));
            _loc1_ += 1;
         }
         this.SetCurrentLod(this._currentLod,true);
      }

// LodContainer
public function CMFRegionSwap(param1:*, param2:*, param3:*) : void
      {
         var _loc4_:* = this._backgroundContainer;
         this._backgroundContainer = param1._backgroundContainer;
         param1._backgroundContainer = _loc4_;
         _loc4_ = this._imageContainer;
         this._imageContainer = param1._imageContainer;
         param1._imageContainer = _loc4_;
         _loc4_ = this._currentLod;
         this._currentLod = param1._currentLod;
         param1._currentLod = _loc4_;
         _loc4_ = this._minLod;
         this._minLod = param1._minLod;
         param1._minLod = _loc4_;
         _loc4_ = this._maxLod;
         this._maxLod = param1._maxLod;
         param1._maxLod = _loc4_;
         param2.swapped = param3;
         this.CMFRegionAttach();
         param1.CMFRegionAttach();
      }

// LodContainer
public function CMFRegionRelease() : void
      {
         this.DeleteLods();
      }

// HubMapPreviewZoomContainer
public function CMFRegionLoader() : *
      {
         return this._loader;
      }

// HubMapPreviewZoomContainer
public function CMFRegionAdopt(param1:*) : *
      {
         var _loc2_:HubMapTileLoader = this._loader;
         if(_loc2_)
         {
            if(_loc2_.parent === this)
            {
               this.removeChild(_loc2_);
            }
         }
         this._loader = param1;
         if(param1)
         {
            this.addChild(param1);
         }
         return _loc2_;
      }

// HubMapPreviewZoomContainer
public function CMFRegionOverviewComplete(param1:*) : void
      {
         var _loc2_:* = param1.currentTarget;
         while(true)
         {
            if(_loc2_ !== this._loader)
            {
               if(!this.CMFRegionOwner)
               {
                  break;
               }
               if(_loc2_ !== this.CMFRegionOwner.nativeOverview)
               {
                  break;
               }
               if(!this.CMFRegionOwner.coordinator.CMFRegionLive(this.CMFRegionOwner))
               {
                  break;
               }
            }
            var _loc3_:* = _loc2_.content;
            if(_loc3_ is Bitmap)
            {
               _loc3_.smoothing = true;
               _loc2_.x = _loc3_.width / -2;
               _loc2_.y = _loc3_.height / -2;
            }
            break;
         }
      }

// HubMapPreviewZoomContainer
public function CMFRegionClearOverview() : void
      {
         var _loc1_:HubMapTileLoader = this._loader;
         if(_loc1_)
         {
            this._loader = null;
            _loc1_.removeEventListener("complete",this.handleImageLoaded);
            _loc1_.removeEventListener("ioError",this.handleImageFailed);
            if(_loc1_.parent === this)
            {
               this.removeChild(_loc1_);
            }
            try
            {
               _loc1_.unload();
            }
            catch(CMFRegionErrorValue:*)
            {
            }
         }
      }

// HubMapTile
public function CMFRegionShow(param1:*) : *
      {
         var _loc2_:* = this._container.CMFRegionOwner;
         if(!_loc2_)
         {
            return false;
         }
         _loc2_.coordinator.CMFRegionShowUse(_loc2_,this,param1);
         return true;
      }

// HubMapTile
public function CMFRegionTileInfo() : *
      {
         return [this._loader,this._filename,this._container,this._container.CMFRegionNativeRow(this._tileX,this._tileY)];
      }

// HubMapTile
public function CMFRegionPaint(param1:*) : void
      {
         this.handleImageLoaded(param1);
      }

// HubMapTile
public function CMFRegionUnlisten() : void
      {
         this._loader.removeEventListener("complete",this.handleImageLoaded);
         this._loader.removeEventListener("ioError",this.handleImageFailed);
      }

// ImageContainer
public function CMFRegionNativeRow(param1:*, param2:*) : *
      {
         var _loc3_:int = this._currentLod;
         if(_loc3_ !== 0)
         {
            if(_loc3_ !== 1)
            {
               if(_loc3_ !== 2)
               {
                  if(_loc3_ !== 3)
                  {
                     if(_loc3_ !== 4)
                     {
                        return 0;
                     }
                     if(param1 === int(param1))
                     {
                        if(param1 >= 0)
                        {
                           if(param1 < 16)
                           {
                              if(param2 === int(param2))
                              {
                                 if(param2 >= 0)
                                 {
                                    if(param2 < 16)
                                    {
                                       return 86 + param2 * 16 + param1;
                                    }
                                 }
                              }
                           }
                        }
                     }
                  }
                  else if(param1 === int(param1))
                  {
                     if(param1 >= 0)
                     {
                        if(param1 < 8)
                        {
                           if(param2 === int(param2))
                           {
                              if(param2 >= 0)
                              {
                                 if(param2 < 8)
                                 {
                                    return 22 + param2 * 8 + param1;
                                 }
                              }
                           }
                        }
                     }
                  }
               }
               else if(param1 === int(param1))
               {
                  if(param1 >= 0)
                  {
                     if(param1 < 4)
                     {
                        if(param2 === int(param2))
                        {
                           if(param2 >= 0)
                           {
                              if(param2 < 4)
                              {
                                 return 6 + param2 * 4 + param1;
                              }
                           }
                        }
                     }
                  }
               }
            }
            else if(param1 === int(param1))
            {
               if(param1 >= 0)
               {
                  if(param1 < 2)
                  {
                     if(param2 === int(param2))
                     {
                        if(param2 >= 0)
                        {
                           if(param2 < 2)
                           {
                              return 2 + param2 * 2 + param1;
                           }
                        }
                     }
                  }
               }
            }
         }
         else if(param1 === int(param1))
         {
            if(param1 >= 0)
            {
               if(param1 < 1)
               {
                  if(param2 === int(param2))
                  {
                     if(param2 >= 0)
                     {
                        if(param2 < 1)
                        {
                           return 1 + param2 * 1 + param1;
                        }
                     }
                  }
               }
            }
         }
         return 0;
      }

// ImageContainer
public function CMFRegionWatchNative(param1:*) : void
      {
         var _loc2_:Vector$object = this._tiles.concat();
         while(_loc2_.length)
         {
            var _loc3_:* = _loc2_.shift().concat();
            while(_loc3_.length)
            {
               var _loc5_:* = _loc3_.shift().CMFRegionTileInfo();
               var _loc4_:* = _loc5_.shift();
               _loc5_.shift();
               _loc5_.shift();
               _loc4_.CMFRegionNativeRow = _loc5_.shift();
               _loc4_.CMFRegionNativeOwner = param1;
               param1.coordinator.CMFRegionNativeBind(param1,_loc4_);
            }
         }
      }

// LodContainer
public function CMFRegionWatchNative(param1:*) : void
      {
         this._backgroundContainer.CMFRegionWatchNative(param1);
         var _loc2_:* = this._minLod;
         while(_loc2_ <= this._maxLod)
         {
            this.GetContainer(_loc2_).CMFRegionWatchNative(param1);
            _loc2_ += 1;
         }
      }

// MapMenu
public function CMFRegionInstall(param1:*) : void
      {
         this.CMFRegionClose();
         var _loc2_:Object = new Object();
         this.CMFRegionLoading = _loc2_;
         _loc2_.declarations = [];
         if(this.CMFRegionPending)
         {
            _loc2_.declarations = this.CMFRegionPending;
            this.CMFRegionPending = null;
         }
         _loc2_.locked = false;
         _loc2_.active = null;
         _loc2_.faultText = param1;
      }

// MapMenu
public function CMFRegionRegister(param1:*) : void
      {
         var _loc2_:* = this.CMFRegionDecode(param1);
         if(_loc2_)
         {
            loop2:
            while(true)
            {
               if(this.CMFRegionLoading)
               {
                  if(!this.CMFRegionLoading.locked)
                  {
                     if(this.CMFRegionLoading.declarations.length < 8)
                     {
                        var _loc3_:* = this.CMFRegionLoading.declarations.concat();
                        while(true)
                        {
                           if(!_loc3_.length)
                           {
                              this.CMFRegionLoading.declarations.push(_loc2_);
                              break loop2;
                           }
                           var _loc4_:* = _loc3_.shift();
                           if(_loc4_.region === _loc2_.region)
                           {
                              break loop2;
                           }
                        }
                     }
                     break;
                  }
               }
               var _loc5_:Array = [];
               if(this.CMFRegionPending)
               {
                  _loc3_ = this.CMFRegionPending.concat();
                  while(_loc3_.length)
                  {
                     _loc4_ = _loc3_.shift();
                     if(_loc4_.region !== _loc2_.region)
                     {
                        _loc5_.push(_loc4_);
                     }
                  }
               }
               if(_loc5_.length < 8)
               {
                  _loc5_.push(_loc2_);
                  this.CMFRegionPending = _loc5_;
               }
               break;
            }
         }
      }

// MapMenu
public function CMFRegionLive(param1:*) : *
      {
         if(this.CMFRegionLoading)
         {
            if(param1)
            {
               if(this.CMFRegionLoading.active === param1)
               {
                  if(this.CMFRegionState === param1.capture)
                  {
                     if(!param1.closed)
                     {
                        return true;
                     }
                  }
               }
            }
         }
         return false;
      }

// MapMenu
public function CMFRegionObserve() : void
      {
         if(this.CMFRegionLoading)
         {
            this.CMFRegionLoading.locked = true;
            if(this.CMFRegionState)
            {
               if(this.CMFRegionState.ready)
               {
                  if(this.CMFRegionState.generation > 500)
                  {
                     this.CMFRegionBoundary();
                     this.callGameEvent("OnDebugEvent",[1599999998]);
                  }
                  else if(!this.CMFRegionLoading.active)
                  {
                     addr007b:
                     var _loc1_:* = this.CMFRegionLoading.declarations.concat();
                     while(_loc1_.length)
                     {
                        var _loc2_:* = _loc1_.shift();
                        if(_loc2_.region !== this.CMFRegionState.nativeTuple.imageRoot)
                        {
                           continue;
                        }
                        var _loc3_:Object = new Object();
                        this.CMFRegionLoading.active = _loc3_;
                        _loc3_.capture = this.CMFRegionState;
                        _loc3_.nativeTuple = this.CMFRegionState.nativeTuple;
                        _loc3_.generation = this.CMFRegionState.generation;
                        _loc3_.coordinator = this;
                        _loc3_.declaration = _loc2_;
                        _loc3_.phase = "loading";
                        _loc3_.failed = false;
                        _loc3_.closed = false;
                        _loc3_.swapped = false;
                        _loc3_.uses = [];
                        _loc3_.nativeUses = [];
                        _loc3_.nativeWrappers = [];
                        _loc3_.ready = 0;
                        _loc3_.issued = false;
                        _loc3_.started = getTimer();
                        _loc3_.timer = new Timer(100);
                        _loc3_.timer.addEventListener("timer",this.CMFRegionTick);
                        _loc3_.timer.start();
                        try
                        {
                           this.CMFRegionPrepare(_loc3_);
                           break;
                        }
                        catch(CMFRegionErrorValue:*)
                        {
                           this.CMFRegionFail(_loc3_,5);
                           break;
                        }
                     }
                  }
                  else if(this.CMFRegionLoading.active.capture !== this.CMFRegionState)
                  {
                     this.CMFRegionBoundary();
                     §§goto(addr007b);
                  }
               }
            }
         }
      }

// MapMenu
public function CMFRegionLate(param1:*, param2:*) : *
      {
         if(this.CMFRegionLoading)
         {
            var _loc3_:* = this.CMFRegionLoading.active;
            if(_loc3_)
            {
               if(_loc3_.capture === this.CMFRegionState)
               {
                  this.CMFRegionStage(param1,param2);
                  this.CMFRegionFail(_loc3_,1);
                  return true;
               }
            }
         }
         return false;
      }

// MapMenu
public function CMFRegionPrepare(param1:*) : void
      {
         var _loc2_:* = param1.declaration.tuple;
         _loc2_.previewAvailable = param1.nativeTuple.previewAvailable;
         _loc2_.previewMode = param1.nativeTuple.previewMode;
         param1.nativeOverview = this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionLoader();
         this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionManaged = true;
         this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionOwner = param1;
         this.mcHubMap.mcHubMapZoomContainer.mcHubMapContainer.mcLodContainer.CMFRegionWatchNative(param1);
         if(param1.nativeOverview)
         {
            param1.nativeOverview.CMFRegionNativeOwner = param1;
            param1.nativeOverview.CMFRegionNativeRow = 342;
            this.CMFRegionNativeBind(param1,param1.nativeOverview);
         }
         var _loc3_:red.game.witcher3.menus.worldmap.LodContainer = new red.game.witcher3.menus.worldmap.LodContainer();
         param1.staged = _loc3_;
         _loc3_.CMFRegionOwner = param1;
         _loc3_.CreateLods(_loc2_.textureSize,_loc2_.minLod,_loc2_.maxLod,_loc2_.imageRoot,_loc2_.visMinX,_loc2_.visMaxX,_loc2_.visMinY,_loc2_.visMaxY);
         _loc3_.GetContainer(1).ShowAllTiles();
         _loc3_.GetContainer(1).HideTiles();
         _loc3_.GetContainer(2).ShowAllTiles();
         _loc3_.GetContainer(2).HideTiles();
         var _loc4_:HubMapTileLoader = new HubMapTileLoader();
         param1.overview = _loc4_;
         this.CMFRegionStartUse(param1,_loc4_,"img://maps/" + _loc2_.imageRoot + "/level0/tile0x0.jpg",null);
         param1.issued = true;
      }

// MapMenu
public function CMFRegionShowUse(param1:*, param2:*, param3:*) : void
      {
         if(this.CMFRegionLive(param1))
         {
            if(!param1.failed)
            {
               var _loc4_:* = param2.CMFRegionTileInfo();
               var _loc5_:* = _loc4_.shift();
               var _loc6_:* = _loc4_.shift();
               while(true)
               {
                  if(!_loc5_.CMFRegionUse)
                  {
                     this.CMFRegionStartUse(param1,_loc5_,_loc6_,param2);
                     if(param1.failed)
                     {
                        break;
                     }
                     _loc4_.shift().addChild(_loc5_);
                  }
                  _loc5_.visible = param3;
                  break;
               }
            }
         }
      }

// MapMenu
public function CMFRegionStartUse(param1:*, param2:*, param3:*, param4:*) : void
      {
         if(!param1.failed)
         {
            var _loc5_:Object = new Object();
            _loc5_.state = param1;
            _loc5_.wrapper = param2;
            _loc5_.key = param3;
            _loc5_.tile = param4;
            _loc5_.row = param1.uses.length + 1;
            _loc5_.ready = false;
            _loc5_.closed = false;
            _loc5_.raw = new Loader();
            _loc5_.info = _loc5_.raw.contentLoaderInfo;
            param2.CMFRegionUse = _loc5_;
            param2.loader = _loc5_.raw;
            param2.autoSize = false;
            param2.addChild(_loc5_.raw);
            param1.uses.push(_loc5_);
            _loc5_.info.addEventListener("complete",this.CMFRegionComplete);
            _loc5_.info.addEventListener("ioError",this.CMFRegionError);
            _loc5_.info.addEventListener("securityError",this.CMFRegionError);
            this.callGameEvent("OnDebugEvent",[int(1600000000 + param1.generation * 1000000 + param1.declaration.row * 10000 + 500 + _loc5_.row)]);
            try
            {
               _loc5_.raw.load(new URLRequest(param3));
            }
            catch(CMFRegionErrorValue:*)
            {
               this.callGameEvent("OnDebugEvent",[int(1600000000 + param1.generation * 1000000 + param1.declaration.row * 10000 + 1500 + _loc5_.row)]);
               this.CMFRegionFail(param1,5);
            }
         }
      }

// MapMenu
public function CMFRegionFindUse(param1:*) : *
      {
         if(this.CMFRegionLoading)
         {
            var _loc2_:* = this.CMFRegionLoading.active;
            if(this.CMFRegionLive(_loc2_))
            {
               if(!_loc2_.failed)
               {
                  var _loc3_:* = _loc2_.uses.concat();
                  while(_loc3_.length)
                  {
                     var _loc4_:* = _loc3_.shift();
                     if(_loc4_.info === param1.currentTarget)
                     {
                        if(!_loc4_.closed)
                        {
                           return _loc4_;
                        }
                        break;
                     }
                  }
               }
            }
         }
         return null;
      }

// MapMenu
public function CMFRegionComplete(param1:*) : void
      {
         var _loc2_:* = this.CMFRegionFindUse(param1);
         if(_loc2_)
         {
            if(!_loc2_.ready)
            {
               var _loc4_:int = 3;
               try
               {
                  var _loc3_:* = _loc2_.info.content;
                  while(true)
                  {
                     if(_loc3_ is Bitmap)
                     {
                        _loc4_ = 4;
                        if(_loc3_.bitmapData.width === _loc2_.state.declaration.tuple.textureSize)
                        {
                           if(_loc3_.bitmapData.height === _loc2_.state.declaration.tuple.textureSize)
                           {
                              _loc4_ = 8;
                              if(!_loc2_.tile)
                              {
                                 _loc3_.smoothing = true;
                                 _loc2_.wrapper.x = _loc3_.width / -2;
                                 _loc2_.wrapper.y = _loc3_.height / -2;
                              }
                              else
                              {
                                 _loc2_.tile.CMFRegionPaint(param1);
                              }
                              _loc2_.ready = true;
                              _loc2_.state.ready += 1;
                              this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.state.generation * 1000000 + _loc2_.state.declaration.row * 10000 + 1000 + _loc2_.row)]);
                              break;
                           }
                        }
                     }
                     addr0113:
                     this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.state.generation * 1000000 + _loc2_.state.declaration.row * 10000 + 1500 + _loc2_.row)]);
                     this.CMFRegionFail(_loc2_.state,_loc4_);
                     break;
                  }
               }
               catch(CMFRegionErrorValue:*)
               {
                  _loc4_ = 8;
                  §§goto(addr0113);
               }
            }
         }
      }

// MapMenu
public function CMFRegionError(param1:*) : void
      {
         var _loc2_:* = this.CMFRegionFindUse(param1);
         if(_loc2_)
         {
            this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.state.generation * 1000000 + _loc2_.state.declaration.row * 10000 + 1500 + _loc2_.row)]);
            if(param1.type !== "securityError")
            {
               this.CMFRegionFail(_loc2_.state,2);
            }
            else
            {
               this.CMFRegionFail(_loc2_.state,7);
            }
         }
      }

// MapMenu
public function CMFRegionNativeBind(param1:*, param2:*) : void
      {
         if(this.CMFRegionLive(param1))
         {
            loop1:
            while(true)
            {
               if(param1.nativeWrappers.indexOf(param2) < 0)
               {
                  if(param1.nativeWrappers.length >= 400)
                  {
                     break;
                  }
                  param1.nativeWrappers.push(param2);
               }
               if(param2.CMFRegionNativeRow >= 1)
               {
                  if(param2.CMFRegionNativeRow <= 342)
                  {
                     if(param2.loader)
                     {
                        var _loc3_:* = param1.nativeUses.concat();
                        while(true)
                        {
                           if(_loc3_.length)
                           {
                              var _loc4_:* = _loc3_.shift();
                              if(_loc4_.wrapper !== param2)
                              {
                                 continue;
                              }
                           }
                           else
                           {
                              if(param1.nativeUses.length >= 400)
                              {
                                 break loop1;
                              }
                              _loc4_ = new Object();
                              _loc4_.wrapper = param2;
                              _loc4_.row = param2.CMFRegionNativeRow;
                              _loc4_.info = param2.loader.contentLoaderInfo;
                              param1.nativeUses.push(_loc4_);
                              _loc4_.info.addEventListener("ioError",this.CMFRegionNativeError,false,100);
                              _loc4_.info.addEventListener("securityError",this.CMFRegionNativeError,false,100);
                              _loc4_.info.addEventListener("complete",this.CMFRegionNativeComplete,false,100);
                           }
                           _loc4_.key = param2.source;
                           this.callGameEvent("OnDebugEvent",[int(1600000000 + param1.generation * 1000000 + param1.declaration.row * 10000 + 6000 + _loc4_.row)]);
                           break loop1;
                        }
                     }
                     break;
                  }
               }
               this.callGameEvent("OnDebugEvent",[int(1600000000 + param1.generation * 1000000 + param1.declaration.row * 10000 + 6500)]);
               break;
            }
         }
      }

// MapMenu
public function CMFRegionNativeBegin(param1:*, param2:*) : void
      {
         this.CMFRegionNativeBind(param1,param2);
         if(this.CMFRegionLive(param1))
         {
            if(param2.CMFRegionNativeRow >= 1)
            {
               if(param2.CMFRegionNativeRow <= 342)
               {
                  param1.nativePending = param2;
               }
            }
         }
      }

// MapMenu
public function CMFRegionNativeEnd(param1:*, param2:*) : void
      {
         if(param1.nativePending !== param2)
         {
            return;
         }
         param1.nativePending = null;
      }

// MapMenu
public function CMFRegionNativeComplete(param1:*) : void
      {
         if(this.CMFRegionLoading)
         {
            var _loc2_:* = this.CMFRegionLoading.active;
            if(this.CMFRegionLive(_loc2_))
            {
               try
               {
                  var _loc3_:* = param1.currentTarget.content;
                  while(true)
                  {
                     if(_loc3_ is Bitmap)
                     {
                        if(_loc3_.bitmapData)
                        {
                           if(_loc3_.bitmapData.width === _loc2_.nativeTuple.textureSize)
                           {
                              if(_loc3_.bitmapData.height === _loc2_.nativeTuple.textureSize)
                              {
                                 break;
                              }
                           }
                        }
                     }
                     addr0078:
                     this.CMFRegionNativeError(param1);
                     break;
                  }
               }
               catch(CMFRegionErrorValue:*)
               {
                  §§goto(addr0078);
               }
            }
         }
      }

// MapMenu
public function CMFRegionNativeError(param1:*) : void
      {
         if(this.CMFRegionLoading)
         {
            var _loc2_:* = this.CMFRegionLoading.active;
            if(this.CMFRegionLive(_loc2_))
            {
               var _loc3_:* = _loc2_.nativeUses.concat();
               while(_loc3_.length)
               {
                  var _loc4_:* = _loc3_.shift();
                  if(_loc4_.info === param1.currentTarget)
                  {
                     if(_loc4_.key === _loc4_.wrapper.source)
                     {
                        this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.generation * 1000000 + _loc2_.declaration.row * 10000 + 5500 + _loc4_.row)]);
                     }
                     break;
                  }
               }
            }
         }
      }

// MapMenu
public function CMFRegionUnwatchNative(param1:*) : void
      {
         var _loc2_:* = param1.nativeUses.concat();
         while(_loc2_.length)
         {
            var _loc3_:* = _loc2_.shift();
            _loc3_.info.removeEventListener("ioError",this.CMFRegionNativeError);
            _loc3_.info.removeEventListener("securityError",this.CMFRegionNativeError);
            _loc3_.info.removeEventListener("complete",this.CMFRegionNativeComplete);
         }
         param1.nativeUses = [];
         _loc2_ = param1.nativeWrappers.concat();
         while(_loc2_.length)
         {
            _loc3_ = _loc2_.shift();
            _loc3_.CMFRegionNativeOwner = null;
         }
         param1.nativeWrappers = [];
         param1.nativePending = null;
      }

// MapMenu
public function CMFRegionStopTimer(param1:*) : void
      {
         if(param1.timer)
         {
            param1.timer.stop();
            param1.timer.removeEventListener("timer",this.CMFRegionTick);
            param1.timer = null;
         }
      }

// MapMenu
public function CMFRegionDisposeUses(param1:*) : void
      {
         var _loc2_:* = param1.uses.concat();
         while(_loc2_.length)
         {
            var _loc3_:* = _loc2_.shift();
            if(!_loc3_.closed)
            {
               _loc3_.closed = true;
               _loc3_.info.removeEventListener("complete",this.CMFRegionComplete);
               _loc3_.info.removeEventListener("ioError",this.CMFRegionError);
               _loc3_.info.removeEventListener("securityError",this.CMFRegionError);
               if(_loc3_.tile)
               {
                  _loc3_.tile.CMFRegionUnlisten();
               }
               try
               {
                  _loc3_.raw.close();
               }
               catch(CMFRegionErrorValue:*)
               {
               }
               try
               {
                  _loc3_.raw.unloadAndStop(false);
               }
               catch(CMFRegionErrorValue:*)
               {
               }
               if(_loc3_.wrapper.parent)
               {
                  _loc3_.wrapper.parent.removeChild(_loc3_.wrapper);
               }
            }
         }
      }

// MapMenu
public function CMFRegionCover(param1:*, param2:*) : void
      {
         if(!param2)
         {
            if(!param1.mask)
            {
               return;
            }
            this.mcHubMap.mask = param1.oldMask;
            this.removeChild(param1.mask);
            param1.mask = null;
            if(param1.message)
            {
               this.removeChild(param1.message);
               param1.message = null;
            }
            this.mcHubMap.CMFRegionBlock(false);
            return;
         }
         if(!param1.mask)
         {
            param1.oldMask = this.mcHubMap.mask;
            var _loc3_:Sprite = new Sprite();
            param1.mask = _loc3_;
            this.addChild(_loc3_);
            this.mcHubMap.mask = _loc3_;
            this.mcHubMap.CMFRegionBlocked = true;
            var _loc4_:TextField = new TextField();
            param1.message = _loc4_;
            _loc4_.text = this.CMFRegionLoading.faultText;
            _loc4_.wordWrap = true;
            _loc4_.textColor = 16777215;
            _loc4_.background = true;
            _loc4_.backgroundColor = 0;
            _loc4_.width = this.mcVisibleArea.width;
            _loc4_.height = 80;
            _loc4_.x = this.mcVisibleArea.x - this.mcVisibleArea.width / 2;
            _loc4_.y = this.mcVisibleArea.y;
            _loc4_.visible = false;
            _loc4_.mouseEnabled = false;
            this.addChild(_loc4_);
         }
      }

// MapMenu
public function CMFRegionSwapTo(param1:*, param2:*) : void
      {
         if(param1.swapped !== param2)
         {
            this.mcHubMap.mcHubMapZoomContainer.mcHubMapContainer.mcLodContainer.CMFRegionSwap(param1.staged,param1,param2);
         }
         if(!param2)
         {
            this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionAdopt(param1.nativeOverview);
         }
         else
         {
            this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionAdopt(param1.overview);
         }
      }

// MapMenu
public function CMFRegionTryApply(param1:*, param2:*) : *
      {
         if(this.mcHubMap.CMFRegionIdle())
         {
            param1.nativePending = null;
            try
            {
               if(!param1.view)
               {
                  param1.view = this.mcHubMap.CMFRegionView();
               }
               this.CMFRegionCover(param1,true);
               this.mcHubMap.mcHubMapZoomContainer.mcHubMapContainer.mcLodContainer.CMFRegionHold = true;
               this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionHold = true;
               this.CMFRegionSwapTo(param1,param2);
               if(!param2)
               {
                  var _loc3_:* = param1.nativeTuple;
               }
               else
               {
                  _loc3_ = param1.declaration.tuple;
               }
               var _loc4_:* = this.mcHubMap.CMFRegionReapply(_loc3_,this.mcVisibleArea);
               if(!_loc4_)
               {
                  if(param2)
                  {
                     this.CMFRegionSwapTo(param1,false);
                     param1.view = null;
                     this.CMFRegionCover(param1,false);
                  }
               }
               else if(!param2)
               {
                  this.mcHubMap.CMFRegionRestoreView(param1.view);
               }
            }
            catch(CMFRegionErrorValue:*)
            {
               if(param1.nativePending)
               {
                  this.callGameEvent("OnDebugEvent",[int(1600000000 + param1.generation * 1000000 + param1.declaration.row * 10000 + 5500 + param1.nativePending.CMFRegionNativeRow)]);
                  param1.nativePending = null;
               }
               this.mcHubMap.mcHubMapZoomContainer.mcHubMapContainer.mcLodContainer.CMFRegionHold = false;
               this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionHold = false;
               return -1;
            }
            this.mcHubMap.mcHubMapZoomContainer.mcHubMapContainer.mcLodContainer.CMFRegionHold = false;
            this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionHold = false;
            if(!_loc4_)
            {
               return 0;
            }
            param1.view = null;
            this.CMFRegionCover(param1,false);
            return 1;
         }
         return 0;
      }

// MapMenu
public function CMFRegionFail(param1:*, param2:*) : void
      {
         if(this.CMFRegionLive(param1))
         {
            if(!param1.failed)
            {
               param1.failed = true;
               this.callGameEvent("OnDebugEvent",[int(1600000000 + param1.generation * 1000000 + param1.declaration.row * 10000 + 2000 + param2)]);
               while(true)
               {
                  if(!param1.swapped)
                  {
                     if(!param1.mask)
                     {
                        this.CMFRegionDisposeUses(param1);
                        param1.phase = "native";
                        this.CMFRegionStopTimer(param1);
                        break;
                     }
                  }
                  this.CMFRegionCover(param1,true);
                  this.mcHubMap.CMFRegionBlock(true);
                  this.CMFRegionDisposeUses(param1);
                  param1.phase = "recovering";
                  param1.started = getTimer();
                  if(!param1.timer)
                  {
                     param1.timer = new Timer(100);
                     param1.timer.addEventListener("timer",this.CMFRegionTick);
                     param1.timer.start();
                  }
                  break;
               }
            }
         }
      }

// MapMenu
public function CMFRegionTick(param1:*) : void
      {
         if(this.CMFRegionLoading)
         {
            var _loc2_:* = this.CMFRegionLoading.active;
            if(this.CMFRegionLive(_loc2_))
            {
               if(param1.currentTarget === _loc2_.timer)
               {
                  if(_loc2_.phase !== "recovering")
                  {
                     if(_loc2_.phase !== "provider")
                     {
                        if(!_loc2_.failed)
                        {
                           if(uint(getTimer() - _loc2_.started) < 10000)
                           {
                              if(_loc2_.issued)
                              {
                                 if(_loc2_.ready === 22)
                                 {
                                    var _loc3_:* = this.CMFRegionTryApply(_loc2_,true);
                                    if(_loc3_ !== 1)
                                    {
                                       if(_loc3_ === -1)
                                       {
                                          this.CMFRegionFail(_loc2_,6);
                                       }
                                    }
                                    else
                                    {
                                       _loc2_.phase = "provider";
                                       this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.generation * 1000000 + _loc2_.declaration.row * 10000 + 2500)]);
                                       if(!_loc2_.declaration.failureUse)
                                       {
                                          this.CMFRegionStopTimer(_loc2_);
                                       }
                                    }
                                 }
                              }
                           }
                           else
                           {
                              this.CMFRegionFail(_loc2_,10);
                           }
                        }
                     }
                     else if(_loc2_.declaration.failureUse)
                     {
                        this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.generation * 1000000 + _loc2_.declaration.row * 10000 + 4500 + _loc2_.declaration.failureUse)]);
                        var _loc4_:* = _loc2_.uses.concat();
                        while(_loc4_.length)
                        {
                           _loc3_ = _loc4_.shift();
                           if(_loc3_.row === _loc2_.declaration.failureUse)
                           {
                              _loc4_ = new Object();
                              _loc4_.currentTarget = _loc3_.info;
                              _loc4_.type = "ioError";
                              this.CMFRegionError(_loc4_);
                              break;
                           }
                        }
                     }
                  }
                  else if(uint(getTimer() - _loc2_.started) < 10000)
                  {
                     _loc3_ = this.CMFRegionTryApply(_loc2_,false);
                     if(_loc3_ === 1)
                     {
                        _loc2_.phase = "native";
                        this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.generation * 1000000 + _loc2_.declaration.row * 10000 + 3000)]);
                        this.CMFRegionStopTimer(_loc2_);
                     }
                  }
                  else
                  {
                     _loc2_.phase = "fault";
                     this.callGameEvent("OnDebugEvent",[int(1600000000 + _loc2_.generation * 1000000 + _loc2_.declaration.row * 10000 + 3500)]);
                     this.CMFRegionStopTimer(_loc2_);
                     this.CMFRegionFaultLayer();
                  }
               }
            }
         }
      }

// MapMenu
public function CMFRegionBoundary() : void
      {
         if(this.CMFRegionLoading)
         {
            var _loc1_:* = this.CMFRegionLoading.active;
            if(_loc1_)
            {
               _loc1_.closed = true;
               this.CMFRegionStopTimer(_loc1_);
               this.CMFRegionUnwatchNative(_loc1_);
               this.CMFRegionSwapTo(_loc1_,false);
               this.CMFRegionDisposeUses(_loc1_);
               this.CMFRegionCover(_loc1_,false);
               this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionClearOverview();
               this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionOwner = null;
               this.mcHubMap.mcHubMapPreview.mcHubMapPreviewGeneralContainer.mcHubMapPreviewZoomContainer.CMFRegionManaged = false;
               if(_loc1_.staged)
               {
                  _loc1_.staged.CMFRegionRelease();
               }
               this.CMFRegionLoading.active = null;
            }
         }
      }

// MapMenu
public function CMFRegionClose() : void
      {
         this.CMFRegionBoundary();
         this.CMFRegionLoading = null;
      }
