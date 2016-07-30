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
	import net.flashpunk.FP;
	import net.flashpunk.graphics.Image;
	import net.flashpunk.graphics.Spritemap;
	import net.flashpunk.utils.Draw;
	
	/**
	 * this is a Spritemap that utilizes Stage3D/Context3D features and renders texture mapped sprites
	 * to use follow these steps:
	 * 1) create sprite map with sprites dimensions and texture 
	 * 2) setup indices, UV data and vertices
	 * 3) call initialize()
	 * 4) add normal Spritemap's anims
	 * 
	 * example:
	 * 
 	 * sprite = new SpritemapTextured(TextureInBitmapDataFormat, 256, 256); 
	 * sprite.indices.push(0,1,2,3,...);
	 * sprite.uvData.push(0.252,0.430,....);
	 * sprite.vertices.push(new <Number>[0.596,0.380,....]);
	 * sprite.vertices.push(new <Number>[0.596,0.380,....]);
	 * sprite.vertices.push(new <Number>[0.596,0.380,....]);
	 * sprite.initialize();
	 * sprite.add("anim" , [0,1,2], 30, false);
	 * 
	 * ver 2016-07-31 00:45
	 * @author rostok
	 */
	public class SpritemapTextured extends Spritemap 
	{
		public var texture:Image;
		public var indices:Vector.<uint> = new Vector.<uint>();
		public var uvData:Vector.<Number> = new Vector.<Number>();
		public var vertices:Vector.<Vector.<Number>> = new Vector.<Vector.<Number>>;
		
		protected var context3D:Context3D= null;
		protected var indexbuffer:IndexBuffer3D= null;
		protected var vertexbuffers:Vector.<VertexBuffer3D> = null;
		protected var uvbuffer:VertexBuffer3D = null;
		protected var program:Program3D = null;
		protected var ctxtexture:Texture = null;
		public static var stage3Dindex:uint = 0;
		public var thisStage3Dindex:uint = 0;
		
		public function SpritemapTextured(source:*, frameWidth:uint=0, frameHeight:uint=0, callback:Function=null) 
		{
			texture = new Image(source);
			super(new BitmapData(frameWidth, frameHeight, true, 0x80FFFF00), frameWidth, frameHeight, callback);
		}
		
		public function initialize():void 
		{
			if (!FP.stage) {
				throw("SpritemapTextured::initialize() no Stage object");
				return;
			}
			
			if (FP.stage.stage3Ds.length == 0) throw("SpritemapTextured::initialize() no Stage3D objects are avaiable for rendering");
			if (vertices.length == 0) throw("SpritemapTextured::initialize() no geometry, vertices are not initialized");
			if (indices.length == 0) throw("SpritemapTextured::initialize() no geometry, indices are not initialized");
			if (uvData.length == 0) throw("SpritemapTextured::initialize() uvData not avaiable");
			_frameCount = vertices.length;
			
			thisStage3Dindex = stage3Dindex;
			stage3Dindex++; // use as many possible
			if (stage3Dindex >= FP.stage.stage3Ds.length) stage3Dindex = 0;
			
			FP.stage.stage3Ds[thisStage3Dindex].addEventListener( Event.CONTEXT3D_CREATE, contextCreated);
			FP.stage.stage3Ds[thisStage3Dindex].requestContext3D();		
			trace("contextCreated() start time:", FP.elapsed);
		}
		
		protected function contextCreated(e:Event):void
		{
			trace("contextCreated() end time:", FP.elapsed);
			context3D = FP.stage.stage3Ds[thisStage3Dindex].context3D;			
			if (!context3D) throw("SpritemapTextured::contextCreated() unable to initialize context3D");
			trace("contextCreated() [", thisStage3Dindex, "/", FP.stage.stage3Ds.length, "]", context3D.driverInfo, context3D.profile);
			FP.console.log("contextCreated() [", thisStage3Dindex, "/", FP.stage.stage3Ds.length, "]", context3D.driverInfo, context3D.profile);
			context3D.configureBackBuffer(width, height, 0, false, true, true);
			context3D.enableErrorChecking = false;
			context3D.setDepthTest(!true, Context3DCompareMode.NEVER);
			context3D.setSamplerStateAt(0, Context3DWrapMode.CLAMP, Context3DTextureFilter.LINEAR, Context3DMipFilter.MIPNONE);
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
			// transform
		}
		
		override public function updateBuffer(clearBefore:Boolean = false):void 
		{
			//trace(_frame, _sourceRect);
			///*
			if ( !context3D ) return;
			
			var m:Matrix3D = new Matrix3D();
			m.appendTranslation( -0.5, -0.5, 0);
			m.appendScale(flipped ? -2 : 2, -2, 2);
			context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
			
			context3D.clear(0,0,0,0);
			
			// vertex position to attribute register 0
			context3D.setVertexBufferAt (0, vertexbuffers[_frame], 0, Context3DVertexBufferFormat.FLOAT_3);
			// UV to attribute register 1
			context3D.setVertexBufferAt(1, uvbuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
			// assign texture to texture sampler 0
			context3D.setTextureAt(0, ctxtexture);				

			context3D.drawTriangles(indexbuffer);
			context3D.drawToBitmapData(_source);

			//_source.noise(_frame);
			//Draw.setTarget(_source);
			//Draw.circle(200, 200, FP.rand(200), 0xFF0000);
			//Draw.resetTarget();
			
			//*/
			//super.updateBuffer(clearBefore);
			
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