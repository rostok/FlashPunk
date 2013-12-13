package net.flashpunk.graphics 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import net.flashpunk.FP;

	/**
	 * Atlas-optimized Spritemap. 
	 * 
	 * To use this class:
	 * 1. init the variable: 
	 * var s:SpritemapAtlas = new SpritemapAtlas(SOURCE, frameWidth, frameHeight, ...);
	 * 2. add all the frames (note: order is important and you must add all the frames): 
	 * s.addFrameInfo(left, top, width, height, xOffset, yOffset); 
	 * 3. add your anims just as you would do with normal Spritemap: s.add("animName", [0,1,2], ...);
	 *
	 * @author rostok
	 */
	public class SpritemapAtlas extends Spritemap
	{
		public var frameInfo:Vector.<Vector.<Number>>;
		
		public function SpritemapAtlas(source:*, frameWidth:uint = 0, frameHeight:uint = 0, callback:Function = null) 
		{
			frameInfo = new Vector.<Vector.<Number>>;
			addFrameInfo(0, 0, 0, 0, 0, 0);
			super(source, frameWidth, frameHeight, callback);
			_frameCount = 0;
		}
		
		/**
		 * in order SpritemapAtlas to work you need to add every frame it has
		 */
		public function addFrameInfo(x:Number, y:Number, width:Number, height:Number, xOffset:Number, yOffset:Number):void 
		{
			frameInfo[_frameCount++] = new <Number>[x,y,width,height,xOffset,yOffset];
		}
		
		/**
		 * Updates the spritemap's buffer.
		 */
		override public function updateBuffer(clearBefore:Boolean = false):void 
		{
			// get position of the current frame
			_rect.x = frameInfo[_frame][0];
			_rect.y = frameInfo[_frame][1];
			_rect.width = frameInfo[_frame][2];
			_rect.height = frameInfo[_frame][3];
			if (_flipped) _rect.x = (_width - _rect.width) - _rect.x;
			
			// changed from the image
			if (locked)
			{
				_needsUpdate = true;
				_needsClear = true;
				return;
			}
			if (!_source) return;
			_buffer.fillRect(_bufferRect, 0);
			_buffer.copyPixels(_source, _sourceRect, new Point(frameInfo[_frame][4],frameInfo[_frame][5]), _drawMask, FP.zero);
			if (_tint) _buffer.colorTransform(_bufferRect, _tint);
		}
	}
}
