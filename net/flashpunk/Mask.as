﻿package net.flashpunk
{
	import flash.display.Graphics;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;

	import net.flashpunk.masks.Masklist;

	/**
	 * Base class for Entity collision masks.
	 */
	public class Mask 
	{
		/**
		 * The parent Entity of this mask.
		 */
		public var parent:Entity;
		
		/**
		 * The parent Masklist of the mask.
		 */
		public var list:Masklist;
		
		/**
		 * Constructor.
		 */
		public function Mask() 
		{
			_class = Class(getDefinitionByName(getQualifiedClassName(this)));
			_check[Mask] = collideMask;
			_check[Masklist] = collideMasklist;
		}
		
		/**
		 * Checks for collision with another Mask.
		 * @param	mask	The other Mask to check against.
		 * @return	If the Masks overlap.
		 */
		public function collide(mask:Mask):Boolean
		{
			if (_check[mask._class] != null) return _check[mask._class](mask);
			if (mask._check[_class] != null) return mask._check[_class](this);
			return false;
		}
		
		/** @private Collide against an Entity. */
		protected function collideMask(other:Mask):Boolean
		{
			return parent.x - parent.originX + parent.width > other.parent.x - other.parent.originX
				&& parent.y - parent.originY + parent.height > other.parent.y - other.parent.originY
				&& parent.x - parent.originX < other.parent.x - other.parent.originX + other.parent.width
				&& parent.y - parent.originY < other.parent.y - other.parent.originY + other.parent.height;
		}
		
		/** @private Collide against a Masklist. */
		protected function collideMasklist(other:Masklist):Boolean
		{
			return other.collide(this);
		}
		
		/** @private Assigns the mask to the parent. */
		public function assignTo(parent:Entity):void
		{
			this.parent = parent;
			if (!list && parent) update();
		}
		
		/** @public Updates the parent's bounds for this mask. */
		public function update():void
		{
			
		}
		
		/** Used to render debug information in console. */
		public function renderDebug(g:Graphics):void
		{
			
		}
		
		/** @private Projects this mask points on axis and returns min and max values in projection object. */
		public function project(axis:Point, projection:Object):void
		{
			var cur:Number,
				max:Number = Number.NEGATIVE_INFINITY,
				min:Number = Number.POSITIVE_INFINITY;

			cur = -parent.originX * axis.x - parent.originY * axis.y;
			if (cur < min) min = cur;
			if (cur > max) max = cur;

			cur = (-parent.originX + parent.width) * axis.x - parent.originY * axis.y;
			if (cur < min) min = cur;
			if (cur > max) max = cur;

			cur = -parent.originX * axis.x + (-parent.originY + parent.height) * axis.y;
			if (cur < min) min = cur;
			if (cur > max) max = cur;

			cur = (-parent.originX + parent.width) * axis.x + (-parent.originY + parent.height)* axis.y;
			if (cur < min) min = cur;
			if (cur > max) max = cur;

			projection.min = min;
			projection.max = max;
		}
	
		// Mask information.
		/** @private */ private var _class:Class;
		/** @private */ protected var _check:Dictionary = new Dictionary;
	}
}
