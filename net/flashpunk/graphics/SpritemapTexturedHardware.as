package net.flashpunk.graphics 
{
	import com.adobe.utils.AGALMiniAssembler;
	import flash.display.BitmapData;
	import flash.display3D.*;
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.utils.Draw;
	
	/**
	 * this is a Spritemap that utilizes Stage3D/Context3D features and renders texture mapped sprites
	 * to use follow these steps:
	 * 		1) create sprite map with sprites dimensions and texture 
	 * 		2) setup indices, UV data and vertices
	 * 		3) call initialize()
	 * 		4) add normal Spritemap's anims
	 * 
	 * example of an rotating :
	 * 		sprite = new SpritemapTextured(TextureInBitmapDataFormat, 256, 256); 
  	 * 		sprite.indices.push(0,1,2,3,4,5);
	 * 		sprite.uvData.push(0.000,0.000,0.000,1.000,1.000,1.000,1.000,1.000,1.000,0.000,0.000,0.000);
	 * 		sprite.vertices.push(new <Number>[0.415,0.757,0.390,0.835,0.535,0.242,0.535,0.242,0.526,0.302,0.415,0.757]);
	 * 		sprite.vertices.push(new <Number>[0.460,0.576,0.376,0.905,0.477,0.471,0.477,0.471,0.553,0.183,0.460,0.576]);
	 * 		sprite.vertices.push(new <Number>[0.506,0.386,0.397,0.830,0.413,0.738,0.413,0.738,0.551,0.182,0.506,0.386]);
	 * 		sprite.vertices.push(new <Number>[0.543,0.231,0.437,0.671,0.378,0.891,0.378,0.891,0.509,0.342,0.543,0.231]);
	 * 		sprite.vertices.push(new <Number>[0.557,0.164,0.484,0.480,0.383,0.882,0.383,0.882,0.443,0.611,0.557,0.164]);
	 * 		sprite.vertices.push(new <Number>[0.535,0.242,0.526,0.302,0.415,0.757,0.415,0.757,0.390,0.835,0.535,0.242]);
	 * 		sprite.vertices.push(new <Number>[0.477,0.471,0.553,0.183,0.460,0.576,0.460,0.576,0.376,0.905,0.477,0.471]);
	 * 		sprite.vertices.push(new <Number>[0.413,0.738,0.551,0.182,0.506,0.386,0.506,0.386,0.397,0.830,0.413,0.738]);
	 * 		sprite.vertices.push(new <Number>[0.378,0.891,0.509,0.342,0.543,0.231,0.543,0.231,0.437,0.671,0.378,0.891]);
	 * 		sprite.vertices.push(new <Number>[0.383,0.882,0.443,0.611,0.557,0.164,0.557,0.164,0.484,0.480,0.383,0.882]);
	 * 		sprite.initialize();
	 * 		sprite.add("spin" , [0,1,2,4,5,6,7,8,9], 30, false);
	 * 
	 * other:
	 * 		- triangles are rendered in order defined by indices (back to front)
	 * 		- indices and therefore order of triangles is defined once for all of the frames
	 * 		- context (and sprite) initialization is asynchronous, there's an event handler that handles this 
	 *		- current matrix transforma assumes triangles are in 1st quadrant (0..1 x 0..1 area) with y=0 being top, y=1 being bottom, x=0 being left
	 * 	 	  if one uses identity matrix, this should be in -1..1x-1..1 area
	 * 
	 * ver 2016-07-31 00:45
	 * @author rostok
	 */
	public class SpritemapTexturedHardware extends Spritemap 
	{
		public var texture:Image;
		public var indices:Vector.<uint> = new Vector.<uint>();
		public var uvData:Vector.<Number> = new Vector.<Number>();
		public var vertices:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;
		
		protected var context3D:Context3D = null;
		protected var indexbuffer:IndexBuffer3D = null;
		protected var vertexbuffers:Vector.<VertexBuffer3D> = null;
		protected var uvbuffer:VertexBuffer3D = null;
		protected var program:Program3D = null;
		protected var ctxtexture:Texture = null;
		public static var stage3Dindex:uint = 0;
		private var thisStage3Dindex:uint = 0;
		private var transform:Matrix3D = null;
		
		public function SpritemapTexturedHardware(source:*, frameWidth:uint=0, frameHeight:uint=0, callback:Function=null) 
		{
			texture = new Image(source);
			super(new BitmapData(frameWidth, frameHeight, true, 0x80FFFF00), frameWidth, frameHeight, callback);
		}
		
		public function initialize():void 
		{
			if (!FP.stage) {
				throw("SpritemapTexturedHardware::initialize() no Stage object");
				return;
			}

			if (FP.stage.stage3Ds.length == 0) throw("SpritemapTexturedHardware::initialize() no Stage3D objects are avaiable for rendering");
			if (vertices.length == 0) throw("SpritemapTexturedHardware::initialize() no geometry, vertices are not initialized");
			if (indices.length == 0) throw("SpritemapTexturedHardware::initialize() no geometry, indices are not initialized");
			if (uvData.length == 0) throw("SpritemapTexturedHardware::initialize() uvData not avaiable");
			_frameCount = vertices.length;
			
			thisStage3Dindex = stage3Dindex;
			//stage3Dindex++; // use as many possible
			if (stage3Dindex >= FP.stage.stage3Ds.length) stage3Dindex = 0;
			
			FP.stage.stage3Ds[thisStage3Dindex].addEventListener( Event.CONTEXT3D_CREATE, contextCreated);
			FP.stage.stage3Ds[thisStage3Dindex].requestContext3D();		
			//trace("contextCreated() start time:", FP.elapsed);
		}
		
		protected function contextCreated(e:Event):void
		{
			//trace("contextCreated() end time:", FP.elapsed);
			context3D = FP.stage.stage3Ds[thisStage3Dindex].context3D;			
			
			if (!context3D) throw("SpritemapTexturedHardware::contextCreated() unable to initialize context3D");
			trace("contextCreated() [", thisStage3Dindex, "/", FP.stage.stage3Ds.length, "]", context3D.driverInfo, context3D.profile, "max BB WxH:", context3D.maxBackBufferWidth, context3D.maxBackBufferHeight);
			//FP.console.log("contextCreated() [", thisStage3Dindex, "/", FP.stage.stage3Ds.length, "]", context3D.driverInfo, context3D.profile, "max BB WxH:", maxBackBufferWidth, maxBackBufferHeight);
			
			//context3D.configureBackBuffer(width, height, 0, false, true, true);
			context3D.configureBackBuffer(
											Math.max(_source.width, context3D.backBufferWidth), 
											Math.max(_source.height, context3D.backBufferHeight),
											0, false, true, true);
			
			context3D.enableErrorChecking = false;
			context3D.setDepthTest(!true, Context3DCompareMode.NEVER);
			context3D.setSamplerStateAt(0, Context3DWrapMode.REPEAT, Context3DTextureFilter.LINEAR, Context3DMipFilter.MIPLINEAR);
			//context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.NEAREST, Context3DMipFilter.MIPNONE);
			var vn:uint = uvData.length / 2;
			// indices
			indexbuffer = context3D.createIndexBuffer(indices.length);			
			indexbuffer.uploadFromVector(indices, 0, indices.length);			
			// UV
			uvbuffer = context3D.createVertexBuffer(vn, 2);
			uvbuffer.uploadFromVector(uvData, 0, vn);				
			// vertices for every frame
			vertexbuffers = new Vector.<VertexBuffer3D>;
			for (var i:int = 0; i < _frameCount; i++)
			{
				vertexbuffers[i] = context3D.createVertexBuffer(vn, 3);
				var tmpvert:Vector.<Number> = new Vector.<Number>;
				for (var j:int = 0; j < vn; j++)
				{
					tmpvert.push(
									vertices[i][j * 2 + 0], 
									vertices[i][j * 2 + 1], 
									0
								); 
				}
				vertexbuffers[i].uploadFromVector(tmpvert, 0, vn);				
			}

			// first vectorBuffer is 3 number XYZ frame geometry
			// second vectorBuffer is 2 number UV data
			var vertexShaderAssembler : AGALMiniAssembler = new AGALMiniAssembler();
			vertexShaderAssembler.assemble( Context3DProgramType.VERTEX,
				"m44 op, va0, vc0\n" + // pos to clipspace
				"mov v0, va1" // copy UV
			);			
			
			var fragmentShaderAssembler : AGALMiniAssembler= new AGALMiniAssembler();
			fragmentShaderAssembler.assemble( Context3DProgramType.FRAGMENT,
				"tex ft1, v0, fs0 <2d>\n" +
				"mov oc, ft1"
			);

			// setup vertext and fragment shaders
			program = context3D.createProgram();
			program.upload( vertexShaderAssembler.agalcode, fragmentShaderAssembler.agalcode);
			
			// setup texture
			ctxtexture = context3D.createTexture(texture.getSource().width, texture.getSource().height, Context3DTextureFormat.BGRA, true);
			ctxtexture.uploadFromBitmapData(texture.getSource());
			
			context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			context3D.setRenderToBackBuffer();
			
			// init complete
			
			// set common stuff
			// assign shader program
			context3D.setProgram(program);
			transform = new Matrix3D();
		}

		override public function updateBuffer(clearBefore:Boolean = false):void 
		{
			if ( !context3D ) return;
			context3D.clear(0,0,0,0);
			
			// transform
			var s2bw:Number = _source.width / context3D.backBufferWidth;
			var s2bh:Number = _source.height / context3D.backBufferHeight;
			transform.identity();
			transform.appendTranslation( -0.5, -0.5, 0);
			transform.appendScale((flipped ? -2 : 2)*s2bw, -2*s2bh, 2);
			transform.appendTranslation( s2bw - 1, 1 - s2bh, 0);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, transform, true);
			
			// vertex position to attribute register 0
			context3D.setVertexBufferAt (0, vertexbuffers[_frame], 0, Context3DVertexBufferFormat.FLOAT_3);
			// UV to attribute register 1
			context3D.setVertexBufferAt(1, uvbuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			// assign texture to texture sampler 0
			context3D.setTextureAt(0, ctxtexture);				

			context3D.drawTriangles(indexbuffer);
			
			context3D.drawToBitmapData(_source);

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