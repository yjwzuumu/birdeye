package org.un.cava.birdeye.geo.views.maps.world
{
	import org.un.cava.birdeye.geo.dictionary.WorldRegionTypes;
	import org.un.cava.birdeye.geo.core.GeoFrame;
	
	public class AsiaMap extends GeoFrame
	{
		public var region:String;
		public function AsiaMap()
		{
			super(WorldRegionTypes.REGION_ASIA);
			region=WorldRegionTypes.REGION_ASIA;
		}
		
	}
}