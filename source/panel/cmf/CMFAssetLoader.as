// CMF-owned diagnostic reference projection from the independently exported
// typed instruction plan in tools/cmf_asset_probe.py. Not a standalone class
// or supported public API. Built methods live on existing MapMenu; provider
// artwork is external. No original vanilla method is replaced.

	public function CMFAssetReport(param1:*, param2:*, param3:*) : void
	{
		while(true)
		{
			if(param3 >= 0)
			{
				if(param3 < 9999)
				{
					break;
				}
			}
			param3 = 9999;
			break;
		}
		param3 = int(param3);
		this.callGameEvent("OnDebugEvent",[int(1300000000 + param1 * 1000000 + param2 * 10000 + param3)]);
	}

	public function CMFAssetStart() : void
	{
		this.CMFAssetCleanup();
		this.callGameEvent("OnDebugEvent",[1300000000]);
		var _loc1_:MovieClip = new MovieClip();
		_loc1_.name = "CMFAssetProbe";
		_loc1_.mouseEnabled = false;
		_loc1_.mouseChildren = false;
		this.addChild(_loc1_);
		this.CMFAssetRequest(1,"swf/cmf_s03/icon.swf",64,240,240);
		this.CMFAssetRequest(2,"swf/cmf_s03/grid.swf",1024,380,240);
		this.CMFAssetRequest(3,"img://icons/cmf_s03/icon.png",64,520,240);
		this.CMFAssetRequest(4,"img://maps/cmf_s03/level0/tile0x0.jpg",1024,660,240);
		this.CMFAssetRequest(5,"img://icons/cloud/cloud_cross.png",64,240,400);
		this.CMFAssetRequest(6,"swf/cmf_s03/absent.swf",64,380,400);
		this.CMFAssetRequest(7,"swf/cmf_s03/absent.png",64,520,400);
		this.CMFAssetRequest(8,"img://icons/cmf_s03/absent.png",64,660,400);
	}

	public function CMFAssetRequest(param1:*, param2:*, param3:*, param4:*, param5:*) : void
	{
		var _loc8_:MovieClip = this.getChildByName("CMFAssetProbe");
		var _loc6_:MovieClip = new MovieClip();
		_loc6_.cmfCase = param1;
		_loc6_.cmfURL = param2;
		_loc6_.cmfDisplaySize = param3;
		_loc6_.x = param4;
		_loc6_.y = param5;
		_loc6_.cmfState = 0;
		_loc8_.addChild(_loc6_);
		var _loc7_:Loader = new Loader();
		_loc6_.addChild(_loc7_);
		_loc7_.contentLoaderInfo.addEventListener("complete",this.CMFAssetComplete);
		_loc7_.contentLoaderInfo.addEventListener("ioError",this.CMFAssetError);
		_loc7_.contentLoaderInfo.addEventListener("securityError",this.CMFAssetError);
		this.CMFAssetReport(_loc6_.cmfCase,1,0);
		try
		{
			_loc7_.load(new URLRequest(param2));
			return;
		}
		catch(CMFAssetErrorValue:*)
		{
			_loc7_.contentLoaderInfo.removeEventListener("complete",this.CMFAssetComplete);
			_loc7_.contentLoaderInfo.removeEventListener("ioError",this.CMFAssetError);
			_loc7_.contentLoaderInfo.removeEventListener("securityError",this.CMFAssetError);
			_loc6_.cmfState = 3;
			this.CMFAssetReport(_loc6_.cmfCase,9,0);
		}
	}

	public function CMFAssetComplete(param1:*) : void
	{
		var _loc2_:* = param1.currentTarget.loader;
		var _loc3_:* = _loc2_.parent;
		if(_loc3_)
		{
			if(_loc3_.parent)
			{
				if(!_loc3_.cmfState)
				{
					_loc2_.contentLoaderInfo.removeEventListener("complete",this.CMFAssetComplete);
					_loc2_.contentLoaderInfo.removeEventListener("ioError",this.CMFAssetError);
					_loc2_.contentLoaderInfo.removeEventListener("securityError",this.CMFAssetError);
					_loc3_.cmfState = 2;
					this.CMFAssetReport(_loc3_.cmfCase,4,param1.currentTarget.width);
					this.CMFAssetReport(_loc3_.cmfCase,5,param1.currentTarget.height);
					this.CMFAssetReport(_loc3_.cmfCase,10,_loc2_.content.width);
					this.CMFAssetReport(_loc3_.cmfCase,11,_loc2_.content.height);
					this.CMFAssetReport(_loc3_.cmfCase,12,_loc2_.width);
					this.CMFAssetReport(_loc3_.cmfCase,13,_loc2_.height);
					if(_loc2_.content is Bitmap)
					{
						this.CMFAssetReport(_loc3_.cmfCase,6,1);
					}
					else if(_loc2_.content is MovieClip)
					{
						this.CMFAssetReport(_loc3_.cmfCase,6,2);
					}
					else
					{
						this.CMFAssetReport(_loc3_.cmfCase,6,0);
					}
					_loc2_.scaleX = 128 / _loc3_.cmfDisplaySize;
					_loc2_.scaleY = 128 / _loc3_.cmfDisplaySize;
					this.CMFAssetReport(_loc3_.cmfCase,2,0);
				}
			}
		}
	}

	public function CMFAssetError(param1:*) : void
	{
		var _loc2_:* = param1.currentTarget.loader;
		var _loc3_:* = _loc2_.parent;
		if(_loc3_)
		{
			if(_loc3_.parent)
			{
				if(!_loc3_.cmfState)
				{
					_loc2_.contentLoaderInfo.removeEventListener("complete",this.CMFAssetComplete);
					_loc2_.contentLoaderInfo.removeEventListener("ioError",this.CMFAssetError);
					_loc2_.contentLoaderInfo.removeEventListener("securityError",this.CMFAssetError);
					_loc3_.cmfState = 3;
					this.CMFAssetReport(_loc3_.cmfCase,3,0);
				}
			}
		}
	}

	public function CMFAssetCleanup() : void
	{
		var _loc1_:MovieClip = this.getChildByName("CMFAssetProbe");
		if(_loc1_)
		{
			while(_loc1_.numChildren)
			{
				var _loc2_:DisplayObject = _loc1_.getChildAt(0);
				var _loc3_:* = _loc2_.getChildAt(0);
				_loc3_.contentLoaderInfo.removeEventListener("complete",this.CMFAssetComplete);
				_loc3_.contentLoaderInfo.removeEventListener("ioError",this.CMFAssetError);
				_loc3_.contentLoaderInfo.removeEventListener("securityError",this.CMFAssetError);
				if(!_loc2_.cmfState)
				{
					this.CMFAssetReport(_loc2_.cmfCase,7,0);
				}
				this.CMFAssetStop(_loc3_);
				this.CMFAssetReport(_loc2_.cmfCase,8,0);
				_loc1_.removeChild(_loc2_);
			}
			this.removeChild(_loc1_);
		}
	}

	public function CMFAssetStop(param1:*) : void
	{
		try
		{
			param1.close();
		}
		catch(CMFAssetErrorValue:*)
		{
		}
		param1.unloadAndStop(true);
	}
