package net.flashpunk.graphics 
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display3D.textures.RectangleTexture;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import net.flashpunk.Graphic;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.utils.Draw;
	/**
	 * works like SpritemapTexturedHardware but with native AS3 routines that are VERY SLOW
	 * @author rostok
	 */
	public class SpritemapTexturedSoftware extends Spritemap 
	{
		public var texture:Image;
		
		public var indices:Vector.<int> = new Vector.<int>();
		public var uvData:Vector.<Number> = new Vector.<Number>();
		public var vertices:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;
		
		public var container:Sprite = null;
		
		public function SpritemapTexturedSoftware(source:*, frameWidth:uint=0, frameHeight:uint=0, callback:Function=null) 
		{
			texture = new Image(source);
			super(new BitmapData(frameWidth, frameHeight, true, 0x80FFFF00), frameWidth, frameHeight, callback);

			container = new Sprite();
			vertices.length = 0;
			indices.length = 0;
			uvData.length = 0;
		}

		public function initialize():void 
		{
			if (vertices.length == 0) throw("SpritemapTexturedSoftware::initialize() no geometry, vertices are not initialized");
			if (indices.length == 0) throw("SpritemapTexturedSoftware::initialize() no geometry, indices are not initialized");
			if (uvData.length == 0) throw("SpritemapTexturedSoftware::initialize() uvData not avaiable");
			_frameCount = vertices.length;

			var vn:uint = uvData.length / 2;
			for (var i:int = 0; i < vertices.length; i++)
			{
				for (var j:int = 0; j < vertices[i].length; j+=2)
				{
					vertices[i][j + 0] *= _frameWidth;
					vertices[i][j + 1] *= _frameHeight;
				}
			}
			container = new Sprite();
		}
		
		override public function updateBuffer(clearBefore:Boolean = false):void 
		{
			if ( !container ) return;
			
			_source.fillRect(_source.rect, 0x00FFFFF);
			container.graphics.clear();
			container.graphics.beginBitmapFill(texture.getBuffer(),null,true,true);
			container.graphics.drawTriangles(vertices[_frame], indices, uvData); 
			container.graphics.endFill();
			var m:Matrix = null;
			if (_flipped) { 
				m = new Matrix();
				m.translate(-_frameWidth, 0);
				m.scale( -1, 1);
			}
			_source.draw(container, m);

			//trace(_frame, _sourceRect);
			// get position of the current frame
			//_rect.x = _frameWidth * (_frame % _columns);
			//_rect.y = _frameHeight * uint(_frame / _columns) + _clipRect.y;
			if (_flipped) _rect.x = (_width - _frameWidth) - _rect.x + _clipRect.x;
			else _rect.x += _clipRect.x;
			
			_rect.width = _clipRect.width;
			_rect.height = _clipRect.height;
			
			if (_clipRect.x + _clipRect.width > _frameWidth) _rect.width -= _clipRect.x + _clipRect.width - _frameWidth;
			if (_clipRect.y + _clipRect.height > _frameHeight) _rect.height -= _clipRect.y + _clipRect.height - _frameHeight;
			
			if (locked)
			{
				_needsUpdate = true;
				if (clearBefore) _needsClear = true;
				return;
			}
			if (!_source) return;
			if (clearBefore) _buffer.fillRect(_bufferRect, 0);
			_buffer.copyPixels(_source, _sourceRect, FP.zero, _drawMask, FP.zero);
			if (_tint) _buffer.colorTransform(_bufferRect, _tint);			
		}
	}

}