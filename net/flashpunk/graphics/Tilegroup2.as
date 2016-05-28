package net.flashpunk.graphics 
{
	import flash.automation.MouseAutomationAction;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import net.flashpunk.FP;
	import net.flashpunk.Graphic;
	import net.flashpunk.utils.Input;
	/**
	 * Used to render tiles. Uses less data than the tilemap if you have large maps
	 * @author Noel Berry
	 * map array stores pointers to BitmapData only
	 * @author Rostok
	 */
	public class Tilegroup2 extends Graphic
	{
		// map information
		public var map:Vector.<Vector.<BitmapData>>;
		public var width:int;
		public var height:int;
		
		// tileset information
		public var tileWidth:int;
		public var tileHeight:int;
		
		// rendering
		public var size:Rectangle;
		public var to:Point = new Point(0, 0);
		
		public function Tilegroup2(width:int, height:int, tileWidth:int, tileHeight:int) 
		{
			if (width == 0) width = 1;
			if (height == 0) height = 1;
			
			// size of the map
			this.width = width;
			this.height = height;
			
			// grid
			this.tileWidth = tileWidth;
			this.tileHeight = tileHeight;
			
			// size rectangle (re-usable)
			size = new Rectangle(0, 0, tileWidth, tileHeight);
			
			// create the array/map
			map = new Vector.<Vector.<BitmapData>>(width + 1, true)
			for (var i:int = 0; i < width + 1; i ++)
			{
				map[i] = new Vector.<BitmapData>(height + 1, true);
				for (var j:int = 0; j < height + 1; j ++)
				{
					map[i][j] = null;
				}
			}
		}
		
		/**
		 * Places a new tile at the given position
		 * @param	x		the column to render at
		 * @param	y		the row to render at
		 * @param	tx		the tile x position
		 * @param	ty		the tile y position
		 */
		public function setTile(x:int, y:int, t:BitmapData):void
		{
			map[x][y] = t;
		}
		
		override public function render(target:BitmapData, point:Point, camera:Point):void 
		{
/*
 			// determine drawing location
			_point.x = point.x + x - originX - camera.x * scrollX;
			_point.y = point.y + y - originY - camera.y * scrollY;
*/
			var renderLeft:int = 	Math.max(0, (camera.x * scrollX - x - point.x) / tileWidth - 1);
			var renderTop:int = 	Math.max(0, (camera.y * scrollY - y - point.y) / tileHeight - 1);
			var renderWidth:int = 	Math.min(width, ((camera.x * scrollX - x - point.x) / tileWidth) + (target.width / tileWidth) + 1);
			var renderHeight:int = 	Math.min(height, ((camera.y * scrollY - y - point.y) / tileHeight) + (target.height / tileHeight) + 1);
			
			// draw tiles on screen
			for (var i:int = renderLeft; i < renderWidth; i ++)
			{
				for (var j:int = renderTop; j < renderHeight; j ++)
				{
					// where do we render to
					to.x = point.x + int((i * tileWidth)) - camera.x * scrollX + x;
					to.y = point.y + int((j * tileHeight)) - camera.y * scrollY + y;
					
					// render tiles
					if (map[i][j]) drawTile(target, to, map[i][j]);
				}
			}
		}
		
		/**
		 * Draws a tile (tile) at position (position) on the screen
		 * @param	position	the position to render to
		 * @param	tile		the tile id to render
		 */
		public function drawTile(target:BitmapData, position:Point, tile:BitmapData):void
		{
			if (!target) target = FP.buffer;
			// render to buffer
			if (tile) target.copyPixels(tile, size, position);
		}
	}
}