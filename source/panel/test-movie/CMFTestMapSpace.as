package
{
	import flash.display.MovieClip;
	import flash.display.Sprite;

	// CMF's own map-space test movie (TEST ONLY, shipped only in modCMFTestMapSpace). It is the root class of
	// swf/cmftestmapspace/cmftestmapspace.swf and shows what a "movie" drawing's author writes: one public
	// function, cmfMapSpace(data, map), which CMF's map calls after loading the movie and again on every map
	// build. The movie's origin is world (0,0) and one unit is one map pixel, so a point of x, y metres sits at
	// x * map.scale, -y * map.scale. It draws a square at data.number.x/y, small crosses at the pairs of
	// data.list.marks and, when CMF hands it the corner overview (map.preview), a dot there. No art, no images.
	public class CMFTestMapSpace extends MovieClip
	{
		private var cmfCalls:int = 0;

		public function CMFTestMapSpace()
		{
			super();
		}

		public function cmfMapSpace(data:Object, map:Object) : Boolean
		{
			var scale:Number = Number(map.scale);
			var x:Number = Number(data.number.x) * scale;
			var y:Number = -Number(data.number.y) * scale;
			var size:Number = data.number.size > 0 ? Number(data.number.size) : 60;
			var color:uint = uint(data.number.color);
			var marks:Array = data.list.marks as Array;
			var dot:Sprite = map.preview as Sprite;
			var k:int = 0;
			var r:Number = 0;
			if(isNaN(x) || isNaN(y) || isNaN(scale) || scale <= 0)
			{
				return false;
			}
			this.cmfCalls++;
			graphics.clear();
			graphics.lineStyle(2,16777215,0.9,false,"none");
			graphics.beginFill(color,0.55);
			graphics.drawRect(x - size / 2,y - size / 2,size,size);
			graphics.endFill();
			k = 0;
			while(marks != null && k + 1 < marks.length)
			{
				graphics.moveTo(marks[k] * scale - 12,-marks[k + 1] * scale);
				graphics.lineTo(marks[k] * scale + 12,-marks[k + 1] * scale);
				graphics.moveTo(marks[k] * scale,-marks[k + 1] * scale - 12);
				graphics.lineTo(marks[k] * scale,-marks[k + 1] * scale + 12);
				k += 2;
			}
			if(dot != null)
			{
				r = 4;
				if(dot.transform.concatenatedMatrix.a > 0)
				{
					r = 4 / dot.transform.concatenatedMatrix.a;
				}
				dot.graphics.clear();
				dot.graphics.beginFill(color,1);
				dot.graphics.drawCircle(x,y,r);
				dot.graphics.endFill();
			}
			return true;
		}
	}
}
