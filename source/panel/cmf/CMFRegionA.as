// CMF-owned S03e-A readable projection; raw ABC oracle is authoritative.
// MapMenu
public function CMFRegionStage(param1:*, param2:*) : void
      {
         while(true)
         {
            if(param1 !== 1)
            {
               var _loc3_:* = this.CMFRegionState;
               if(!_loc3_)
               {
                  break;
               }
               if(_loc3_.next !== param1)
               {
                  break;
               }
            }
            else
            {
               _loc3_ = this.CMFRegionState;
               if(_loc3_)
               {
                  if(_loc3_.next !== 5)
                  {
                     this.CMFRegionDiagnostics += 1;
                  }
               }
               this.CMFRegionGeneration += 1;
               _loc3_ = new Object();
               var _loc4_:* = new Object();
               this.CMFRegionState = _loc3_;
               _loc3_.tuple = _loc4_;
               _loc3_.generation = this.CMFRegionGeneration;
               _loc3_.next = 1;
               _loc3_.ready = false;
               _loc3_.nativeTuple = null;
            }
            _loc4_ = _loc3_.tuple;
            if(param1 !== 1)
            {
               if(param1 !== 2)
               {
                  if(param1 !== 3)
                  {
                     if(param1 !== 4)
                     {
                        break;
                     }
                     if(!(param2 is Array))
                     {
                        break;
                     }
                     if(param2.length !== 8)
                     {
                        break;
                     }
                     var _loc5_:* = param2.concat();
                     _loc4_.mapSize = _loc5_.shift();
                     _loc4_.tileCount = _loc5_.shift();
                     _loc4_.textureSize = _loc5_.shift();
                     _loc4_.minLod = _loc5_.shift();
                     _loc4_.maxLod = _loc5_.shift();
                     _loc4_.imageRoot = _loc5_.shift();
                     _loc4_.previewAvailable = _loc5_.shift();
                     _loc4_.previewMode = _loc5_.shift();
                     _loc3_.next = 5;
                     if(!this.mcHubMap.CMFRegionValid(_loc4_))
                     {
                        break;
                     }
                     _loc3_.nativeTuple = _loc4_;
                     _loc3_.ready = true;
                  }
                  else
                  {
                     if(!(param2 is Array))
                     {
                        break;
                     }
                     if(param2.length !== 4)
                     {
                        break;
                     }
                     _loc5_ = param2.concat();
                     _loc4_.scrollMinX = _loc5_.shift();
                     _loc4_.scrollMaxX = _loc5_.shift();
                     _loc4_.scrollMinY = _loc5_.shift();
                     _loc4_.scrollMaxY = _loc5_.shift();
                     _loc3_.next = 4;
                  }
               }
               else
               {
                  if(!(param2 is Array))
                  {
                     break;
                  }
                  if(param2.length !== 5)
                  {
                     break;
                  }
                  _loc5_ = param2.concat();
                  _loc4_.visMinX = _loc5_.shift();
                  _loc4_.visMaxX = _loc5_.shift();
                  _loc4_.visMinY = _loc5_.shift();
                  _loc4_.visMaxY = _loc5_.shift();
                  _loc4_.gradient = _loc5_.shift();
                  _loc3_.next = 3;
               }
            }
            else
            {
               if(!(param2 is Array))
               {
                  break;
               }
               if(param2.length !== 5)
               {
                  break;
               }
               _loc5_ = param2.concat();
               _loc4_.minZoom = _loc5_.shift();
               _loc4_.maxZoom = _loc5_.shift();
               _loc4_.zoom12 = _loc5_.shift();
               _loc4_.zoom23 = _loc5_.shift();
               _loc4_.zoom34 = _loc5_.shift();
               _loc3_.next = 2;
            }
            §§goto(addr02a1);
         }
         this.CMFRegionDiagnostics += 1;
         if(this.CMFRegionState)
         {
            this.CMFRegionState.next = -1;
            this.CMFRegionState.ready = false;
            this.CMFRegionState.nativeTuple = null;
         }
         addr02a1:
      }

// HubMap
public function CMFRegionValid(param1:*) : *
      {
         if(param1)
         {
            if(param1.minZoom is Number)
            {
               if(param1.minZoom >= -2147483647)
               {
                  if(param1.minZoom <= 2147483647)
                  {
                     if(param1.maxZoom is Number)
                     {
                        if(param1.maxZoom >= -2147483647)
                        {
                           if(param1.maxZoom <= 2147483647)
                           {
                              if(param1.zoom12 is Number)
                              {
                                 if(param1.zoom12 >= -2147483647)
                                 {
                                    if(param1.zoom12 <= 2147483647)
                                    {
                                       if(param1.zoom23 is Number)
                                       {
                                          if(param1.zoom23 >= -2147483647)
                                          {
                                             if(param1.zoom23 <= 2147483647)
                                             {
                                                if(param1.zoom34 is Number)
                                                {
                                                   if(param1.zoom34 >= -2147483647)
                                                   {
                                                      if(param1.zoom34 <= 2147483647)
                                                      {
                                                         if(param1.visMinX is Number)
                                                         {
                                                            if(param1.visMinX >= -2147483647)
                                                            {
                                                               if(param1.visMinX <= 2147483647)
                                                               {
                                                                  if(param1.visMaxX is Number)
                                                                  {
                                                                     if(param1.visMaxX >= -2147483647)
                                                                     {
                                                                        if(param1.visMaxX <= 2147483647)
                                                                        {
                                                                           if(param1.visMinY is Number)
                                                                           {
                                                                              if(param1.visMinY >= -2147483647)
                                                                              {
                                                                                 if(param1.visMinY <= 2147483647)
                                                                                 {
                                                                                    if(param1.visMaxY is Number)
                                                                                    {
                                                                                       if(param1.visMaxY >= -2147483647)
                                                                                       {
                                                                                          if(param1.visMaxY <= 2147483647)
                                                                                          {
                                                                                             if(param1.gradient is Number)
                                                                                             {
                                                                                                if(param1.gradient >= -2147483647)
                                                                                                {
                                                                                                   if(param1.gradient <= 2147483647)
                                                                                                   {
                                                                                                      if(param1.scrollMinX is Number)
                                                                                                      {
                                                                                                         if(param1.scrollMinX >= -2147483647)
                                                                                                         {
                                                                                                            if(param1.scrollMinX <= 2147483647)
                                                                                                            {
                                                                                                               if(param1.scrollMaxX is Number)
                                                                                                               {
                                                                                                                  if(param1.scrollMaxX >= -2147483647)
                                                                                                                  {
                                                                                                                     if(param1.scrollMaxX <= 2147483647)
                                                                                                                     {
                                                                                                                        if(param1.scrollMinY is Number)
                                                                                                                        {
                                                                                                                           if(param1.scrollMinY >= -2147483647)
                                                                                                                           {
                                                                                                                              if(param1.scrollMinY <= 2147483647)
                                                                                                                              {
                                                                                                                                 if(param1.scrollMaxY is Number)
                                                                                                                                 {
                                                                                                                                    if(param1.scrollMaxY >= -2147483647)
                                                                                                                                    {
                                                                                                                                       if(param1.scrollMaxY <= 2147483647)
                                                                                                                                       {
                                                                                                                                          if(param1.mapSize is Number)
                                                                                                                                          {
                                                                                                                                             if(param1.mapSize >= -2147483647)
                                                                                                                                             {
                                                                                                                                                if(param1.mapSize <= 2147483647)
                                                                                                                                                {
                                                                                                                                                   if(param1.tileCount is Number)
                                                                                                                                                   {
                                                                                                                                                      if(param1.tileCount >= -2147483647)
                                                                                                                                                      {
                                                                                                                                                         if(param1.tileCount <= 2147483647)
                                                                                                                                                         {
                                                                                                                                                            if(param1.textureSize is Number)
                                                                                                                                                            {
                                                                                                                                                               if(param1.textureSize >= -2147483647)
                                                                                                                                                               {
                                                                                                                                                                  if(param1.textureSize <= 2147483647)
                                                                                                                                                                  {
                                                                                                                                                                     if(param1.minLod is Number)
                                                                                                                                                                     {
                                                                                                                                                                        if(param1.minLod >= -2147483647)
                                                                                                                                                                        {
                                                                                                                                                                           if(param1.minLod <= 2147483647)
                                                                                                                                                                           {
                                                                                                                                                                              if(param1.maxLod is Number)
                                                                                                                                                                              {
                                                                                                                                                                                 if(param1.maxLod >= -2147483647)
                                                                                                                                                                                 {
                                                                                                                                                                                    if(param1.maxLod <= 2147483647)
                                                                                                                                                                                    {
                                                                                                                                                                                       if(param1.previewMode is Number)
                                                                                                                                                                                       {
                                                                                                                                                                                          if(param1.previewMode >= -2147483647)
                                                                                                                                                                                          {
                                                                                                                                                                                             if(param1.previewMode <= 2147483647)
                                                                                                                                                                                             {
                                                                                                                                                                                                if(param1.tileCount === int(param1.tileCount))
                                                                                                                                                                                                {
                                                                                                                                                                                                   if(param1.textureSize === int(param1.textureSize))
                                                                                                                                                                                                   {
                                                                                                                                                                                                      if(param1.minLod === int(param1.minLod))
                                                                                                                                                                                                      {
                                                                                                                                                                                                         if(param1.maxLod === int(param1.maxLod))
                                                                                                                                                                                                         {
                                                                                                                                                                                                            if(param1.previewMode === int(param1.previewMode))
                                                                                                                                                                                                            {
                                                                                                                                                                                                               if(param1.visMinX === int(param1.visMinX))
                                                                                                                                                                                                               {
                                                                                                                                                                                                                  if(param1.visMaxX === int(param1.visMaxX))
                                                                                                                                                                                                                  {
                                                                                                                                                                                                                     if(param1.visMinY === int(param1.visMinY))
                                                                                                                                                                                                                     {
                                                                                                                                                                                                                        if(param1.visMaxY === int(param1.visMaxY))
                                                                                                                                                                                                                        {
                                                                                                                                                                                                                           if(param1.scrollMinX === int(param1.scrollMinX))
                                                                                                                                                                                                                           {
                                                                                                                                                                                                                              if(param1.scrollMaxX === int(param1.scrollMaxX))
                                                                                                                                                                                                                              {
                                                                                                                                                                                                                                 if(param1.scrollMinY === int(param1.scrollMinY))
                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                    if(param1.scrollMaxY === int(param1.scrollMaxY))
                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                       if(param1.mapSize > 0)
                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                          if(param1.tileCount > 0)
                                                                                                                                                                                                                                          {
                                                                                                                                                                                                                                             if(param1.textureSize > 0)
                                                                                                                                                                                                                                             {
                                                                                                                                                                                                                                                if(param1.minZoom > 0)
                                                                                                                                                                                                                                                {
                                                                                                                                                                                                                                                   if(param1.gradient > 0)
                                                                                                                                                                                                                                                   {
                                                                                                                                                                                                                                                      if(param1.minZoom < param1.maxZoom)
                                                                                                                                                                                                                                                      {
                                                                                                                                                                                                                                                         if(param1.visMinX < param1.visMaxX)
                                                                                                                                                                                                                                                         {
                                                                                                                                                                                                                                                            if(param1.visMinY < param1.visMaxY)
                                                                                                                                                                                                                                                            {
                                                                                                                                                                                                                                                               if(param1.scrollMinX < param1.scrollMaxX)
                                                                                                                                                                                                                                                               {
                                                                                                                                                                                                                                                                  if(param1.scrollMinY < param1.scrollMaxY)
                                                                                                                                                                                                                                                                  {
                                                                                                                                                                                                                                                                     if(param1.minLod >= 1)
                                                                                                                                                                                                                                                                     {
                                                                                                                                                                                                                                                                        if(param1.maxLod <= 4)
                                                                                                                                                                                                                                                                        {
                                                                                                                                                                                                                                                                           if(param1.minLod <= param1.maxLod)
                                                                                                                                                                                                                                                                           {
                                                                                                                                                                                                                                                                              loop0:
                                                                                                                                                                                                                                                                              while(true)
                                                                                                                                                                                                                                                                              {
                                                                                                                                                                                                                                                                                 if(param1.zoom12 !== -1)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.zoom12 < param1.minZoom)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    if(param1.zoom12 > param1.maxZoom)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 if(param1.zoom23 !== -1)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.zoom23 < param1.minZoom)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    if(param1.zoom23 > param1.maxZoom)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 if(param1.zoom34 !== -1)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.zoom34 < param1.minZoom)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    if(param1.zoom34 > param1.maxZoom)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 while(true)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.minLod <= 1)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       if(param1.maxLod > 1)
                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                          if(param1.zoom12 > 0)
                                                                                                                                                                                                                                                                                          {
                                                                                                                                                                                                                                                                                             break;
                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                          break loop0;
                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    if(param1.zoom12 === -1)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    break loop0;
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 while(true)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.minLod <= 2)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       if(param1.maxLod > 2)
                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                          if(param1.zoom23 > 0)
                                                                                                                                                                                                                                                                                          {
                                                                                                                                                                                                                                                                                             break;
                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                          break loop0;
                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    if(param1.zoom23 === -1)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    break loop0;
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 while(true)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.minLod <= 3)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       if(param1.maxLod > 3)
                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                          if(param1.zoom34 > 0)
                                                                                                                                                                                                                                                                                          {
                                                                                                                                                                                                                                                                                             break;
                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                          break loop0;
                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    if(param1.zoom34 === -1)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       break;
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                    break loop0;
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 if(param1.zoom12 !== -1)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.zoom23 !== -1)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       if(param1.zoom12 >= param1.zoom23)
                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                          break;
                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 if(param1.zoom23 !== -1)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.zoom34 !== -1)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       if(param1.zoom23 >= param1.zoom34)
                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                          break;
                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 if(param1.imageRoot is String)
                                                                                                                                                                                                                                                                                 {
                                                                                                                                                                                                                                                                                    if(param1.imageRoot.length > 0)
                                                                                                                                                                                                                                                                                    {
                                                                                                                                                                                                                                                                                       if(param1.previewAvailable is Boolean)
                                                                                                                                                                                                                                                                                       {
                                                                                                                                                                                                                                                                                          if(param1.previewMode >= 0)
                                                                                                                                                                                                                                                                                          {
                                                                                                                                                                                                                                                                                             if(param1.previewMode <= 2)
                                                                                                                                                                                                                                                                                             {
                                                                                                                                                                                                                                                                                                return true;
                                                                                                                                                                                                                                                                                             }
                                                                                                                                                                                                                                                                                          }
                                                                                                                                                                                                                                                                                       }
                                                                                                                                                                                                                                                                                    }
                                                                                                                                                                                                                                                                                 }
                                                                                                                                                                                                                                                                                 break;
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
                  }
               }
            }
         }
         return false;
      }

// HubMapPreview
public function CMFRegionPreviewPolicy() : *
      {
         return [this._previewAvailable,this._previewMode];
      }

// HubMap
public function CMFRegionReapply(param1:*, param2:*) : *
      {
         if(!this.CMFRegionGuard)
         {
            if(!this._snapTween1)
            {
               if(!this._snapTween2)
               {
                  if(!this._transitionTween)
                  {
                     if(this.CMFRegionValid(param1))
                     {
                        var _loc3_:Boolean = this.mouseEnabled;
                        var _loc4_:Boolean = this.mouseChildren;
                        var _loc5_:* = this.mcHubMapZoomContainer.actualScaleX;
                        var _loc6_:Number = this.MapXToWorldX(-this.mcHubMapZoomContainer.mcHubMapContainer.x);
                        var _loc7_:Number = this.MapYToWorldY(-this.mcHubMapZoomContainer.mcHubMapContainer.y);
                        var _loc8_:* = this.mcHubMapPreview.CMFRegionPreviewPolicy();
                        this.CMFRegionGuard = true;
                        this.mouseEnabled = false;
                        this.mouseChildren = false;
                        try
                        {
                           this.SetMapZooms(param1.minZoom,param1.maxZoom,param1.zoom12,param1.zoom23,param1.zoom34);
                           this.SetMapVisibilityBoundaries(param1.visMinX,param1.visMaxX,param1.visMinY,param1.visMaxY,param1.gradient);
                           this.SetMapScrollingBoundaries(param1.scrollMinX,param1.scrollMaxX,param1.scrollMinY,param1.scrollMaxY);
                           this.SetMapSettings(param1.mapSize,param1.tileCount,param1.textureSize,param1.minLod,param1.maxLod,param1.imageRoot,param2,_loc8_.shift(),_loc8_.shift());
                           if(_loc5_ >= param1.minZoom)
                           {
                              if(_loc5_ > param1.maxZoom)
                              {
                                 _loc5_ = param1.maxZoom;
                              }
                           }
                           else
                           {
                              _loc5_ = param1.minZoom;
                           }
                           this.mcHubMapZoomContainer.setActualScale(_loc5_,_loc5_);
                           this.mcHubMapZoomContainer.mcHubMapContainer.setImmediatePosition(-this.WorldXToMapX(_loc6_),-this.WorldYToMapY(_loc7_));
                           this.mcHubMapPinContainer.x = this.mcHubMapZoomContainer.mcHubMapContainer.x * this.GetScale();
                           this.mcHubMapPinContainer.y = this.mcHubMapZoomContainer.mcHubMapContainer.y * this.GetScale();
                           this.UpdateVisibilityAndPinPositions(true);
                           this.UpdateSizeForAreaMapPins(this.GetComponentScale());
                           this.UpdateLod(true);
                        }
                        catch(CMFRegionErrorValue:*)
                        {
                           var _loc10_:* = §§dup(CMFRegionErrorValue);
                           this.CMFRegionGuard = false;
                           this.mouseEnabled = _loc3_;
                           this.mouseChildren = _loc4_;
                           throw CMFRegionErrorValue;
                        }
                        this.CMFRegionGuard = false;
                        this.mouseEnabled = _loc3_;
                        this.mouseChildren = _loc4_;
                        return true;
                     }
                  }
               }
            }
         }
         return false;
      }
