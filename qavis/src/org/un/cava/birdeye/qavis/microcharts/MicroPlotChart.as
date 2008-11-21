/*  
 * The MIT License
 *
 * Copyright (c) 2008
 * United Nations Office at Geneva
 * Center for Advanced Visual Analytics
 * http://cava.unog.ch
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
 
 package org.un.cava.birdeye.qavis.microcharts
{
	import com.degrafa.GeometryGroup;
	import com.degrafa.Surface;
	import com.degrafa.geometry.Circle;
	import com.degrafa.geometry.Line;
	import com.degrafa.paint.SolidFill;
	import com.degrafa.paint.SolidStroke;
	
	[Inspectable("negative")]
	 /**
	 * <p>This component is used to create plot microcharts. 
	 * The basic simple syntax to use it and create an plot microchart with mxml is:</p>
	 * <p>&lt;MicroPlotChart dataProvider="{myArray}" width="20" height="70"/></p>
	 * 
	 * <p>The dataProvider property can only accept Array at the moment, but will be soon extended with ArrayCollection
	 * and XML.
	 * It's also possible to change the colors by defining the following properties in the mxml declaration:</p>
	 * <p>- color: to change the default shape color;</p>
	 * <p>- negativeColor: to set or change the reference line which delimites negative values;</p>
	 * 
	 * <p>The following public properties can also be used to:</p> 
	 * <p>- radius: to modify the plots size;</p>
	 * <p>- negative: this Boolean if set to true shows the negative reference line colored with the same color of plots.</p>
	*/
	public class MicroPlotChart extends Surface
	{
		private var geomGroup:GeometryGroup;
		private var red:SolidStroke = new SolidStroke("0xff0000",1);
		private var black:SolidFill = new SolidFill("0x000000",1);
		
		private var _negative:Boolean = true;
		private var _colors:Array = null;
		private var _negativeColor:Number = NaN;
		private var _dataProvider:Array = new Array();
		private var _radius:Number = 2;
		
		private var min:Number, max:Number, space:Number = 0;
		private var tot:Number = NaN;

		[Inspectable(enumeration="true,false")]
		public function set negative(val:Boolean):void
		{
			_negative = val;
		}
		
		/**
		* Indicate whether the negative reference line has to be drawn or not. 
		*/
		public function get negative():Boolean
		{
			return _negative;
		}
		
		public function set colors(val:Array):void
		{
			_colors = val;
			invalidateDisplayList();
		}
		
		/**
		* Changes the default colors of the plots. 
		*/		
		public function get colors():Array
		{
			return _colors;
		}
		
		public function set negativeColor(val:Number):void
		{
			_negativeColor = val;
			invalidateDisplayList();
		}
		
		/**
		* Changes the default color of the negative line. 
		*/		
		public function get negativeColor():Number
		{
			return _negativeColor;
		}
		
		public function set radius(val:Number):void
		{
			_radius = val;
			invalidateDisplayList();
		}
		
		/**
		* Set the radius of plots for the chart. 
		*/		
		public function get radius():Number
		{
			return _radius;
		}

		public function set dataProvider(val:Array):void
		{
			_dataProvider = val;
			invalidateProperties();
			invalidateDisplayList();
		}
		
		/**
		* Set the dataProvider that will feed the chart. 
		*/		
		public function get dataProvider():Array
		{
			return _dataProvider;
		}

		/**
		* @private
		 * Used to recalculate min, max and tot each time properties have to ba revalidated 
		*/
		override protected function commitProperties():void
		{
			super.commitProperties();
			minMaxTot();
		}
		
		/**
		* @private
		 * Calculate min, max and tot  
		*/
		private function minMaxTot():void
		{
			min = max = _dataProvider[0];

			tot = 0;
			for (var i:Number = 0; i < _dataProvider.length; i++)
			{
				if (min > _dataProvider[i])
					min = _dataProvider[i];
				if (max < _dataProvider[i])
					max = _dataProvider[i];
			}
			tot = Math.abs(Math.max(max,0) - Math.min(min,0));
		}

		/**
		* @private
		 * Calculate the height size of the plot for the current dataProvider value   
		*/
		private function sizeY(indexIteration:Number):Number
		{
			var _sizeY:Number = _dataProvider[indexIteration] / tot * height;
			return _sizeY;
		}

		/**
		* @private
		 * It sets the color for the current line
		*/
		private function useColor(indexIteration:Number):int
		{
			return _colors[indexIteration];
		}
		
		public function MicroPlotChart()
		{
			super();
		}
		
		/**
		* @private 
		 * Used to create and refresh the chart.
		*/
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			for(var i:int=this.numChildren-1; i>=0; i--)
				if(getChildAt(i) is GeometryGroup)
						removeChildAt(i);

			geomGroup = new GeometryGroup();
			geomGroup.target = this;
			createPlots();
			this.graphicsCollection.addItem(geomGroup);
		}
		
		/**
		* @private 
		 * Create the plots of the chart.
		*/
		private function createPlots():void
		{
			var columnWidth:Number = width/dataProvider.length;
			var startY:Number = height + Math.min(min,0)/tot * height;
			var startX:Number = 0;

			// create negative reference line
			if (negative)
			{
				var negLine:Line = new Line(space+startX, space+startY, space+width, space+startY);
				if (!isNaN(_negativeColor))
					negLine.stroke = new SolidStroke(_negativeColor);
				else
					negLine.stroke = red;
				geomGroup.geometryCollection.addItem(negLine);
			}
			
			// create columns
			for (var i:Number=0; i<_dataProvider.length; i++)
			{
				var plot:Circle = 
					new Circle(space+startX+columnWidth/2, space+ startY-sizeY(i), radius);
				
				startX += columnWidth;

				if (_colors != null)
					plot.fill = new SolidFill(useColor(i));
				else
					plot.fill = new SolidFill(black);
					
				geomGroup.geometryCollection.addItem(plot);
			}

		}
		
		/**
		* @private 
		 * Set the minHeight and minWidth in case width and height are not set in the creation of the chart.
		*/
		override protected function measure():void
		{
			super.measure();
			minHeight = 5;
			minWidth = 10;
		}
	}
}