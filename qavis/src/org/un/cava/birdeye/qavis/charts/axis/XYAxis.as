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
 
package org.un.cava.birdeye.qavis.charts.axis
{
	import com.degrafa.GeometryGroup;
	import com.degrafa.Surface;
	import com.degrafa.geometry.Line;
	import com.degrafa.geometry.RasterText;
	import com.degrafa.geometry.RegularRectangle;
	import com.degrafa.paint.SolidFill;
	import com.degrafa.paint.SolidStroke;
	
	import flash.text.TextFieldAutoSize;
	
	import mx.core.Container;
	import mx.core.UIComponent;
	
	import org.un.cava.birdeye.qavis.charts.interfaces.IAxisLayout;
	
	public class XYAxis extends UIComponent implements IAxisLayout
	{
		protected var surf:Surface;
		protected var gg:GeometryGroup;
		protected var fill:SolidFill = new SolidFill(0x888888,0);
		protected var stroke:SolidStroke = new SolidStroke(0x888888,1,1);
		
		protected var readyForLayout:Boolean = false;

		/** Scale type: Linear */
		public static const LINEAR:String = "linear";
		/** Scale type: Category */
		public static const CATEGORY:String = "category";
		/** Scale type: Logaritmic */
		public static const LOG:String = "log";
		/** Scale type: DateTime */
		public static const DATE_TIME:String = "date_time";
		
		protected var _scaleType:String = LINEAR;
		/** Set the scale type, LINEAR by default. */
		public function set scaleType(val:String):void
		{
			_scaleType = val;
			invalidateProperties()
			invalidateSize();
			invalidateDisplayList();
		}
		public function get scaleType():String
		{
			return _scaleType;
		}
		
		protected var isGivenInterval:Boolean = false;
		protected var _interval:Number;
		/** Set the interval between axis values. */
		public function set interval(val:Number):void
		{
			_interval = val;
			isGivenInterval = true;
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get interval():Number
		{
			return _interval;
		}
		
		/** Diagonal placement for the Z axis. */
		public static const DIAGONAL:String = "diagonal";
		/** TOP placement for the axis. */
		public static const TOP:String = "top";
		/** BOTTOM placement for the axis. */
		public static const BOTTOM:String = "bottom";
		/** LEFT placement for the axis. */
		public static const LEFT:String = "left";
		/** RIGHT placement for the axis. */
		public static const RIGHT:String = "right";
		/** VERTICAL_CENTER placement for the axis. */
		public static const VERTICAL_CENTER:String = "vertical_center";
		/** HORIZONTAL_CENTER placement for the axis. */
		public static const HORIZONTAL_CENTER:String = "horizontal_center";
		
		private var _placement:String;
		/** Set the placement for this axis. */
		[Inspectable(enumeration="top,bottom,left,right,vertical_center,horizontal_center")]
		public function set placement(val:String):void
		{
			_placement = val;
			invalidateProperties()
			invalidateSize();
			invalidateDisplayList();
		}
		public function get placement():String
		{
			return _placement;
		}
		
		private var _showTicks:Boolean = true;
		/** Show ticks on the axis */
		[Inspectable(enumeration="false,true")]
		public function set showTicks(val:Boolean):void
		{
			_showTicks = val;
		}
		public function get showTicks():Boolean
		{
			return _showTicks;
		}
		
		protected var maxLblSize:Number = 0;
		/** @Private */
		protected function maxLabelSize():void
		{
			// must be overridden 
		}

		/** @Private */
		protected function calculateMaxLabelStyled():void
		{
			// calculate according font size and style
			// consider auto-size and thick size too
		}

		// UIComponent flow
		public function XYAxis()
		{
			super();
		}
		
		private var labelCont:Container;
		/** @Private */
		override protected function createChildren():void
		{
			super.createChildren();
			surf = new Surface();
			gg = new GeometryGroup();
			gg.target = surf;
			surf.graphicsCollection.addItem(gg);
			labelCont = new Container();
			labelCont.addChild(surf);
			addChild(labelCont);
		}
		
		/** @Private */
		override protected function commitProperties():void
		{
			super.commitProperties();
		}
		
		/** @Private */
		override protected function measure():void
		{
			super.measure();
			switch (placement)
			{
				case XYAxis.LEFT:
				case XYAxis.RIGHT:
					explicitWidth = measuredWidth = minWidth = 30 + maxLblSize;
					break;
				case XYAxis.BOTTOM:
				case XYAxis.TOP:
					explicitHeight = measuredHeight = minHeight = 30 + maxLblSize;
					break;
			}
		}
		
		private var xMin:Number = NaN, yMin:Number = NaN, xMax:Number = NaN, yMax:Number = NaN;
		private var sign:Number = NaN
		protected var line:Line; 
		protected var thick:Line;
		protected var thickWidth:Number = 5;
		protected var label:RasterText;
		/** @Private */
		override protected function updateDisplayList(w:Number, h:Number):void
		{
			super.updateDisplayList(w,h);
			setActualSize(w,h);
			for (var i:Number = gg.geometryCollection.items.length; i>0; i--)
				gg.geometryCollection.removeItemAt(i-1);
			
			drawAxisLine(w,h)

			if (readyForLayout)
			{
				switch (placement)
				{
					case BOTTOM:
						xMin = 0; xMax = w;
						yMin = 0; yMax = 0;
						sign = 1;
						break;
					case TOP:
						xMin = 0; xMax = w;
						yMin = h; yMax = h;
						sign = -1;
						break;
					case LEFT:
						xMin = w; xMax = w;
						yMin = 0; yMax = h;
						sign = -1;
						break;
					case RIGHT:
						xMin = 0; xMax = 0;
						yMin = 0; yMax = h;
						sign = 1;
						break;
				}
				drawAxes(xMin, xMax, yMin, yMax, sign);
			}
		}
		
		protected function drawAxisLine(w:Number, h:Number):void
		{
			var x0:Number, x1:Number, y0:Number, y1:Number;
			
			switch (placement)
			{
				case BOTTOM:
					x0 = 0; x1 = w;
					y0 = 0; y1 = 0;
					break;
				case TOP:
					x0 = 0; x1 = w;
					y0 = h; y1 = h;
					break;
				case LEFT:
					x0 = w; x1 = w;
					y0 = 0; y1 = h;
					break;
				case RIGHT:
					x0 = 0; x1 = 0;
					y0 = 0; y1 = h;
					break;
			}

			line = new Line(x0,y0,x1,y1);
			line.fill = fill;
			line.stroke = stroke;
			gg.geometryCollection.addItem(line);

		}
		protected function drawAxes(xMin:Number, xMax:Number, yMin:Number, yMax:Number, sign:Number):void
		{
			// to be overridden
		}

		protected var size:Number;
		protected function getSize():Number
		{
			switch (placement)
			{
				case BOTTOM:
				case TOP:
					size = width;
					break;
				case LEFT:
				case RIGHT:
					size = height;
					break;
			}
			return size;
		}
		
		public function getPosition(dataValue:*):*
		{
			// to be overridden by implementing axis class (Category, Numeric, DateTime..)
			return null;
		}
	}
}


