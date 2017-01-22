package net.flashpunk.graphics 
{
	/**
	 * proxy
	 * @author rostok
	 */
	public class SpritemapTextured extends SpritemapTexturedSoftware
	//public class SpritemapTextured extends SpritemapTexturedHardware
	{
		
		public function SpritemapTextured(source:*, frameWidth:uint=0, frameHeight:uint=0, callback:Function=null) 
		{
			super(source, frameWidth, frameHeight, callback);
		}
	}
}