﻿package net.flashpunk.graphics 
{
	import flash.geom.Rectangle;

	import net.flashpunk.FP;

	/**
	 * Performance-optimized animated Image. Can have multiple animations,
	 * which draw frames from the provided source image to the screen.
	 */
	public class Spritemap extends Image
	{
		/**
		 * If the animation has stopped.
		 */
		public var complete:Boolean = true;
		
		/**
		 * Optional callback function for animation end.
		 */
		public var callback:Function;
		
		/**
		 * Animation speed factor, alter this to speed up/slow down all animations.
		 */
		public var rate:Number = 1;
		
		/**
		 * Constructor.
		 * @param	source			Source image.
		 * @param	frameWidth		Frame width.
		 * @param	frameHeight		Frame height.
		 * @param	callback		Optional callback function for animation end.
		 */
		public function Spritemap(source:*, frameWidth:uint = 0, frameHeight:uint = 0, callback:Function = null) 
		{
			_rect = new Rectangle(0, 0, frameWidth, frameHeight);
			_clipRect = new Rectangle(0, 0, frameWidth, frameHeight);
			_frameWidth = frameWidth;
			_frameHeight = frameHeight;
			super(source, _rect);
			if (!frameWidth)
			{
				_rect.width = this.source.width;
				_clipRect.width = this.source.width;
				_frameWidth = this.source.width;
			}
			if (!frameHeight)
			{
				_rect.height = this.source.height;
				_clipRect.height = this.source.height;
				_frameHeight = this.source.height;
			}
			_width = this.source.width;
			_height = this.source.height;
			_columns = Math.ceil(_width / _rect.width);
			_rows = Math.ceil(_height / _rect.height);
			_frameCount = _columns * _rows;
			this.callback = callback;
			updateBuffer();
			active = true;
		}
		
		/**
		 * Updates the spritemap's buffer.
		 */
		override public function updateBuffer(clearBefore:Boolean = false):void 
		{
			// get position of the current frame
			_rect.x = _frameWidth * (_frame % _columns);
			_rect.y = _frameHeight * uint(_frame / _columns) + _clipRect.y;
			if (_flipped) _rect.x = (_width - _frameWidth) - _rect.x + _clipRect.x;
			else _rect.x += _clipRect.x;
			
			_rect.width = _clipRect.width;
			_rect.height = _clipRect.height;
			
			if (_clipRect.x + _clipRect.width > _frameWidth) _rect.width -= _clipRect.x + _clipRect.width - _frameWidth;
			if (_clipRect.y + _clipRect.height > _frameHeight) _rect.height -= _clipRect.y + _clipRect.height - _frameHeight;
			
			// update the buffer
			super.updateBuffer(clearBefore);
		}
		
		/** @private Updates the animation. */
		override public function update():void 
		{
			if (_anim && !complete)
			{
				var timeAdd:Number = _anim._frameRate * rate;
				if (! FP.timeInFrames) timeAdd *= FP.elapsed;
				_timer += timeAdd;
				if (_timer >= 1)
				{
					while (_timer >= 1)
					{
						_timer --;
						_index ++;
						if (_index == _anim._frameCount)
						{
							if (_anim._loop)
							{
								_index = 0;
								if (callback != null) callback();
							}
							else
							{
								_index = _anim._frameCount - 1;
								complete = true;
								if (callback != null) callback();
								break;
							}
						}
					}
					if (_anim) _frame = uint(_anim._frames[_index]);
					updateBuffer();
				}
			}
		}
		
		/**
		 * Add an Animation.
		 * @param	name		Name of the animation.
		 * @param	frames		Array of frame indices to animate through.
		 * @param	frameRate	Animation speed (with variable framerate: in frames per second, with fixed framerate: in frames per frame).
		 * @param	loop		If the animation should loop.
		 * @return	A new Anim object for the animation.
		 */
		public function add(name:String, frames:Array, frameRate:Number = 0, loop:Boolean = true):Anim
		{
			for (var i:int = 0; i < frames.length; i++) {
				frames[i] %= _frameCount;
				if (frames[i] < 0) frames[i] += _frameCount;
			}
			(_anims[name] = new Anim(name, frames, frameRate, loop))._parent = this;
			return _anims[name];
		}
		
		/**
		 * Plays an animation.
		 * @param	name		Name of the animation to play.
		 * @param	reset		If the animation should force-restart if it is already playing.
		 * @param	frame		Frame of the animation to start from, if restarted.
		 * @return	Anim object representing the played animation.
		 */
		public function play(name:String = "", reset:Boolean = false, frame:int = 0):Anim
		{
			if (!reset && _anim && _anim._name == name) return _anim;
			_anim = _anims[name];
			if (!_anim)
			{
				_frame = _index = 0;
				complete = true;
				updateBuffer();
				return null;
			}
			_index = 0;
			_timer = 0;
			_frame = uint(_anim._frames[frame % _anim._frameCount]);
			complete = false;
			updateBuffer();
			return _anim;
		}
		
		/**
		 * Gets the frame index based on the column and row of the source image.
		 * @param	column		Frame column.
		 * @param	row			Frame row.
		 * @return	Frame index.
		 */
		public function getFrame(column:uint = 0, row:uint = 0):uint
		{
			return (row % _rows) * _columns + (column % _columns);
		}
		
		/**
		 * Sets the current display frame based on the column and row of the source image.
		 * When you set the frame, any animations playing will be stopped to force the frame.
		 * @param	column		Frame column.
		 * @param	row			Frame row.
		 */
		public function setFrame(column:uint = 0, row:uint = 0):void
		{
			_anim = null;
			var frame:uint = (row % _rows) * _columns + (column % _columns);
			if (_frame == frame) return;
			_frame = frame;
			_timer = 0;
			updateBuffer();
		}
		
		/**
		 * Assigns the Spritemap to a random frame.
		 */
		public function randFrame():void
		{
			frame = FP.rand(_frameCount);
		}
		
		/**
		 * Sets the frame to the frame index of an animation.
		 * @param	name	Animation to draw the frame frame.
		 * @param	index	Index of the frame of the animation to set to.
		 */
		public function setAnimFrame(name:String, index:int):void
		{
			var frames:Array = _anims[name]._frames;
			index %= frames.length;
			if (index < 0) index += frames.length;
			frame = frames[index];
		}
		
		/**
		 * Sets the current frame index. When you set this, any
		 * animations playing will be stopped to force the frame.
		 */
		public function get frame():int { return _frame; }
		public function set frame(value:int):void
		{
			_anim = null;
			value %= _frameCount;
			if (value < 0) value = _frameCount + value;
			if (_frame == value) return;
			_frame = value;
			_timer = 0;
			updateBuffer();
		}
		
		// rostok
		// returns current anim framecount
		public function getCurrentAnimFrameCount():int
		{
			return _anim ? _anim._frameCount : 0;
		}

		// rostok 
		// returns current animation
		public function getCurrentAnim():Anim
		{
			return _anim;
		}
		
		// rostok
		// returns all anims
		public function getAnims():Object
		{
			return _anims;
		}

		// rostok
		// adds new anim that is reversed source anim
		public function addReversed(newName:String, sourceName:String):Anim
		{
			return add( newName, _anims[sourceName].frames.concat().reverse(), _anims[sourceName]._frameRate, _anims[sourceName]._loop );
		}

		// rostok
		// changes chosen anim by adding reversed frames for example from [0,1,2] to [0,1,2,1,0]
		public function pingPongify(animName:String):void 
		{
			var a:Array = _anims[animName].frames.concat().reverse();
			a.shift();
			//_anims[animName].frames = _anims[animName].frames.concat( a );
			for each(var i:int in a) _anims[animName].frames.push(a);
		}
		
		// rostok
		// adds new anim than is subanim of source
		public function addSubAnim(newName:String, sourceName:String, startIndex:int, length:int):Anim 
		{
			return add(newName, _anims[sourceName].frames.concat().splice(startIndex, length), _anims[sourceName]._frameRate, _anims[sourceName]._loop );
		}
		
		// rostok
		// returns Anim object by name
		public function getAnim(animName:String):Anim
		{
			return _anims[animName];
		}

		// rostok
		/**
		 * changes animations speeed
		 * @param	animName the name
		 * @param	frameRate the new framerate or multiplication factor
		 * @param	multiply set to true if you want to multiply instead of setting
		 */
		public function changeSpeed(animName:String, frameRate:Number, multiply:Boolean = false):void
		{
			var a : Anim = getAnim(animName);
			if (!a) return;
			if (multiply) 
				a.frameRate *= frameRate;
			else 
				a.frameRate = frameRate;
		}
		
		/**
		 * Current index of the playing animation.
		 */
		public function get index():uint { return _anim ? _index : 0; }
		public function set index(value:uint):void
		{
			if (!_anim) return;
			value %= _anim._frameCount;
			if (_index == value) return;
			_index = value;
			_frame = uint(_anim._frames[_index]);
			_timer = 0;
			updateBuffer();
		}
		
		/**
		 * The amount of frames in the Spritemap.
		 */
		public function get frameCount():uint { return _frameCount; }
		
		/**
		 * Columns in the Spritemap.
		 */
		public function get columns():uint { return _columns; }
		
		/**
		 * Rows in the Spritemap.
		 */
		public function get rows():uint { return _rows; }
		
		/**
		 * The currently playing animation.
		 */
		public function get currentAnim():String { return _anim ? _anim._name : ""; }
		
		/**
		 * Clipping rectangle for the spritemap.
		 */
		override public function get clipRect():Rectangle 
		{
			return _clipRect;
		}
		
		// Spritemap information.
		/** @private */ protected var _rect:Rectangle;
		/** @private */ protected var _clipRect:Rectangle;
		/** @private */ protected var _width:uint;
		/** @private */ protected var _height:uint;
		/** @private */ protected var _frameWidth:uint = 0;
		/** @private */ protected var _frameHeight:uint = 0;
		/** @private */ private var _columns:uint;
		/** @private */ private var _rows:uint;
		/** @private */ private var _frameCount:uint;
		/** @private */ private var _anims:Object = { };
		/** @private */ private var _anim:Anim;
		/** @private */ private var _index:uint;
		/** @private */ protected var _frame:uint;
		/** @private */ private var _timer:Number = 0;
	}
}