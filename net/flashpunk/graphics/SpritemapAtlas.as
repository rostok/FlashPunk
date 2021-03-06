﻿package net.flashpunk.graphics 
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	import net.flashpunk.FP;

	/**
	 * Atlas-optimized Spritemap, ver. 1.2 2016-08-15
	 * 
	 * To use this class:
	 * 0. Spritemap::_frameCount must be protected, not private
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
		public var frameInfo:Vector.<Vector.<Number>> = null;
		
		public function SpritemapAtlas(source:*, frameWidth:uint = 0, frameHeight:uint = 0, callback:Function = null) 
		{
			super(source, frameWidth, frameHeight, callback);
		}
		
		/**
		 * in order SpritemapAtlas to work you need to add every frame it has
		 */
		public function addFrameInfo(x:Number, y:Number, width:Number, height:Number, xOffset:Number, yOffset:Number):void 
		{
			// unless addFrameInfo() is called this acts as a normal Spritemap class
			if (!frameInfo)
			{
				// otherwise init everything
				frameInfo = new Vector.<Vector.<Number>>;
				//addFrameInfo(0, 0, 0, 0, 0, 0);
				_frameCount = 0;
			}

			frameInfo[_frameCount++] = new <Number>[x, y, width, height, xOffset, yOffset];
		}

		// this optimizes memory by not creating cached flipped buffer, instead slower matrix transform is used to draw sprite
		// for more see Image.flipped setter
		override public function get flipped():Boolean { return scaleX ==-1; }
		override public function set flipped(value:Boolean):void { scaleX = value ? -1 : 1; }
		
		override public function render(target:BitmapData, point:Point, camera:Point):void 
		{
			var originX_real:Number = originX;
			
			if (scaleX == -1) originX = width - originX;
			
			super.render(target, point, camera);
			
			originX = originX_real;
		}
		
		/**
		 * Updates the spritemap's buffer.
		 */
		override public function updateBuffer(clearBefore:Boolean = false):void 
		{
		    // act like normal SpriteMap
			if (!frameInfo)
			{
				super.updateBuffer(clearBefore);
				return;
			}

			// get position of the current frame
			_rect.x = frameInfo[_frame][0];
			_rect.y = frameInfo[_frame][1];
			_rect.width = frameInfo[_frame][2];
			_rect.height = frameInfo[_frame][3];
			var ofsX:Number = frameInfo[_frame][4];
			if (_flipped) {
				// for flipped spritemaps, second flipped source is created
				// in order to copyPixels() rather than transform
				// in such case source rect.x must be flipped
				// however offset is calculated from the end of the sprite
				// note that Y ofset remains unchanged
				_rect.x = (_width - _rect.width) - _rect.x;
				ofsX = _frameWidth - frameInfo[_frame][2] - ofsX;
			}
			
			// changed from the image
			if (locked)
			{
				_needsUpdate = true;
				_needsClear = true;
				return;
			}
			if (!_source) return;
			_buffer.fillRect(_bufferRect, 0);
			_buffer.copyPixels(_source, _sourceRect, new Point(ofsX, frameInfo[_frame][5]), _drawMask, FP.zero);
			if (_tint) _buffer.colorTransform(_bufferRect, _tint);
		}
	}
}
