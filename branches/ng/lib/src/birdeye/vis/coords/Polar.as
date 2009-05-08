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
 
package birdeye.vis.coords
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Point;
	
	import mx.collections.CursorBookmark;
	
	import birdeye.vis.VisScene;
	import birdeye.vis.coords.Polar;
	import birdeye.vis.scales.*;
	import birdeye.vis.data.DataItemLayout;
	import birdeye.vis.interfaces.IScale;
	import birdeye.vis.interfaces.IScaleUI;
	import birdeye.vis.interfaces.IEnumerableScale;
	import birdeye.vis.interfaces.INumerableScale;
	import birdeye.vis.interfaces.IPolarElement;
	import birdeye.vis.interfaces.IElement;
	import birdeye.vis.interfaces.IStack;
	import birdeye.vis.elements.geometry.PolarElement;
	import birdeye.vis.elements.collision.PolarStackElement;
	
	/** 
	 * The PolarChart is the base chart that is extended by all charts that are
	 * based on polar coordinates (PieChart, RadarChart, CoxCombo, etc). 
	 * The PolarChart serves as container for all axes and elements and coordinates the different
	 * data loading and creation of each component.
	 * 
	 * If a PolarChart is provided with an axis, this axis will be shared by all elements that have 
	 * not that same axis (angle, and/or radius). 
	 * In the same way, the PolarChart provides a dataProvider property 
	 * that can be shared with elements that have not a dataProvider. In case the PolarChart dataProvider 
	 * is used along with some elements dataProvider, than the relevant values defined be the elements fields
	 * of all these dataProviders will define the axes.
	 * 
	 * A PolarChart may have multiple and different type of elements, multiple axes and 
	 * multiple dataProvider(s).
	 * */ 
	[DefaultProperty("dataProvider")]
	public class Polar extends VisScene
	{
        [Inspectable(category="General", arrayType="birdeye.vis.interfaces.IPolarElement")]
        [ArrayElementType("birdeye.vis.interfaces.IPolarElement")]
		override public function set elements(val:Array):void
		{
			_elements = val;
			var stackableElements:Array = [];

			for (var i:Number = 0; i<_elements.length; i++)
			{
				// if the elements doesn't have an own angle axis, than
				// it's necessary to create a default angle axis inside the
				// polar chart. This axis will be shared by all elements that
				// have no own angle axis
				if (! IPolarElement(_elements[i]).angleAxis)
					needDefaultAngleAxis = true;

				// if the elements doesn't have an own radius axis, than
				// it's necessary to create a default radius axis inside the
				// polar chart. This axis will be shared by all elements that
				// have no own radius axis
				if (! IPolarElement(_elements[i]).radiusAxis)
					needDefaultRadiusAxis = true;
					
				// set the chart target inside the elements to 'this'
				// in the future the elements target could be an external chart 
				if (! IPolarElement(_elements[i]).polarChart)
					IPolarElement(_elements[i]).polarChart = this;
				
				// count all stackable elements according their type (overlaid, stacked100...)
				// and store their position. This allows to have a general PolarChart 
				// elements that are stackable, where the type of stack used is defined internally
				// the elements itself. In case of RadarChart, is used, than
				// the elements stack type is defined directly by the chart.
				// however the following allows keeping the possibility of using stackable elements inside
				// a general polar chart
				if (_elements[i] is IStack)
				{
					if (isNaN(stackableElements[IStack(_elements[i]).elementType]) || stackableElements[IStack(_elements[i]).elementType] == undefined) 
						stackableElements[IStack(_elements[i]).elementType] = 1;
					else 
						stackableElements[IStack(_elements[i]).elementType] += 1;
					
					IStack(_elements[i]).stackPosition = stackableElements[IStack(_elements[i]).elementType]; 
				} 
			}

			// if a element is stackable, than its total property 
			// represents the number of all stackable elements with the same type inside the
			// same chart. This allows having multiple elements type inside the same chart 
			for (i = 0; i<_elements.length; i++)
				if (_elements[i] is IStack)
					IStack(_elements[i]).total = stackableElements[IStack(_elements[i]).elementType]; 
		}

		protected var _type:String = PolarStackElement.STACKED100;
		/** Set the type of stack, overlaid if the element are shown on top of the other, 
		 * or stacked if they appear staked one after the other (horizontally), or 
		 * stacked100 if the columns are stacked one after the other (vertically).*/
		[Inspectable(enumeration="overlaid,stacked,stacked100")]
		public function set type(val:String):void
		{
			_type = val;
			invalidateProperties();
			invalidateDisplayList();
		}

		protected var _radarAxis:RadarAxis;
		public function set radarAxis(val:RadarAxis):void
		{
			_radarAxis = val;
			_radarAxis.polarChart = this;
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get radarAxis():RadarAxis
		{
			return _radarAxis;
		}
		
		protected var needDefaultAngleAxis:Boolean;
		protected var needDefaultRadiusAxis:Boolean;
		protected var _angleAxis:IScale;
		/** Set the angle axis. Set its placement to NONE*/ 
		public function set angleAxis(val:IScale):void
		{
			_angleAxis = val;

			invalidateProperties();
			invalidateDisplayList();
		}
		public function get angleAxis():IScale
		{
			return _angleAxis;
		}

		protected var _radiusAxis:IScale;
		/** Define the radius axis. If it has not defined its placement, than set it to 
		 * horizontal-center*/ 
		public function set radiusAxis(val:IScale):void
		{
			_radiusAxis = val;
			if (val is IScaleUI 	&& IScaleUI(_radiusAxis).placement != BaseScale.HORIZONTAL_CENTER 
								&& IScaleUI(_radiusAxis).placement != BaseScale.VERTICAL_CENTER)
				IScaleUI(_radiusAxis).placement = BaseScale.HORIZONTAL_CENTER;

			invalidateProperties();
			invalidateDisplayList();
		}
		public function get radiusAxis():IScale
		{
			return _radiusAxis;
		}
		
		private var _origin:Point;
		public function set origin(val:Point):void
		{
			_origin = val;
			invalidateDisplayList();
		}
		public function get origin():Point
		{
			return _origin;
		}

		private var _columnWidthRate:Number = 3/5;
		public function set columnWidthRate(val:Number):void
		{
			_columnWidthRate = val;
			invalidateDisplayList();
		}
		public function get columnWidthRate():Number
		{
			return _columnWidthRate;
		}
		
		protected var _fontSize:Number = 10;
		public function set fontSize(val:Number):void
		{
			_fontSize = val;
			invalidateDisplayList();
		}
		
		public function Polar()
		{
			super();
		}

		protected var nCursors:Number;
		/** @Private 
		 * When properties are committed, first remove all current children, second check for elements owned axes 
		 * and put them on the corresponding container (left, top, right, bottom). If no axes are defined for one 
		 * or more elements, than create the default axes and add them to the related container.
		 * Once all axes are identified (including the default ones), than we can feed them with the 
		 * corresponding data.*/
		override protected function commitProperties():void
		{
			super.commitProperties();
			needDefaultAngleAxis = needDefaultRadiusAxis = false;
			
			removeAllElements();
			
			nCursors = 0;
			
			if (elements)
			{
				var _stackedElements:Array = [];

 				for (var i:int = 0; i<elements.length; i++)
				{
					// if elements dataprovider doesn' exist or it refers to the
					// chart dataProvider, than set its cursor to this chart cursor (this.cursor)
					if (cursor && (! IElement(_elements[i]).dataProvider 
									|| IElement(_elements[i]).dataProvider == this.dataProvider))
						IElement(_elements[i]).cursor = cursor;

					// nCursors is used in feedAxes to check that all elements cursors are ready
					// and therefore check that axes can be properly feeded
					if (cursor || IElement(_elements[i]).cursor)
						nCursors += 1;

					addChild(DisplayObject(elements[i]));
					if (IPolarElement(elements[i]).radiusAxis)
						addChild(DisplayObject(IPolarElement(elements[i]).radiusAxis));
					else 
						needDefaultRadiusAxis = true;

					if (! IPolarElement(elements[i]).angleAxis)
						needDefaultAngleAxis = true;

					if (_elements[i] is IStack)
					{
						IStack(_elements[i]).stackType = _type;
						_stackedElements.push(_elements[i]);
					}
				}

				for (i = 0; i<_stackedElements.length; i++)
				{
					IStack(_stackedElements[i]).stackPosition = i;
					IStack(_stackedElements[i]).total = _stackedElements.length;
				}
			}

			// if some elements have no own radius axis, than create a default one for the chart
			// that will be used by all elements without a radius axis
			if (needDefaultRadiusAxis && !_radarAxis)
			{
				if (!_radiusAxis)
					createRadiusAxis();

				if (_radiusAxis is IScaleUI)
					addChild(DisplayObject(_radiusAxis));
			}

			// if some elements have no own angle axis, than create a default one for the chart
			// that will be used by all elements without a angle axis
			if (needDefaultAngleAxis && !_radarAxis)
			{
				if (!_angleAxis)
					createAngleAxis();
			}
			
			// init all axes, default and elements owned 
			if (! axesFeeded)
				feedAxes();
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			setActualSize(unscaledWidth, unscaledHeight);
			
			if (showAllDataTips)
				removeDataItems();
			
			_origin = new Point(unscaledWidth/2, unscaledHeight/2);
			
			if (radarAxis)
			{
				radarAxis.radiusSize = DisplayObject(radarAxis).width  
					= Math.min(unscaledWidth, unscaledHeight)/2;
			} 
			
			if (radiusAxis)
			{
				if (radiusAxis is IScale)
				{
					radiusAxis.size = Math.min(unscaledWidth, unscaledHeight)/2;
				}
				
				if (radiusAxis is IScaleUI)
				{
					switch (IScaleUI(radiusAxis).placement)
					{
						case BaseScale.HORIZONTAL_CENTER:
							DisplayObject(radiusAxis).x = _origin.x;
							DisplayObject(radiusAxis).y = _origin.y;
							break;
						case BaseScale.VERTICAL_CENTER:
							DisplayObject(radiusAxis).x = _origin.x;
							DisplayObject(radiusAxis).y = _origin.y;
							break;
					}
				}
			} 
			
			for (var i:int = 0; i<_elements.length; i++)
			{
				DisplayObject(_elements[i]).width = unscaledWidth;
				DisplayObject(_elements[i]).height = unscaledHeight;
			}
			
			if (_showAllDataTips)
			{
				for (i = 0; i<numChildren; i++)
				{
					if (getChildAt(i) is DataItemLayout)
						DataItemLayout(getChildAt(i)).showToolTip();
				}
			}

			// listeners like legends will listen to this event
			dispatchEvent(new Event("ProviderReady"));
		}

		protected var currentElement:IPolarElement;
		/** @Private
		 * Feed the axes with either elements (for ex. CategoryAxis) or max and min (for numeric axis).*/
		protected function feedAxes():void
		{
			if (nCursors == elements.length)
			{
				var catElements:Array = [];
				var j:Number = 0;
				
				var maxMin:Array;
				
				// check if a default y axis exists
				if (angleAxis)
				{
					if (angleAxis is IEnumerableScale)
					{
						for (i = 0; i<nCursors; i++)
						{
							currentElement = PolarElement(_elements[i]);
							// if the series has its own data provider but has not its own
							// angleAxis, than load their elements and add them to the elements
							// loaded by the chart data provider
							if (currentElement.dataProvider 
								&& currentElement.dataProvider != dataProvider
								&& ! currentElement.angleAxis)
							{
								currentElement.cursor.seek(CursorBookmark.FIRST);
								while (!currentElement.cursor.afterLast)
								{
									if (catElements.indexOf(
										currentElement.cursor.current[IEnumerableScale(angleAxis).categoryField]) 
										== -1)
										catElements[j++] = 
											currentElement.cursor.current[IEnumerableScale(angleAxis).categoryField];
									currentElement.cursor.moveNext();
								}
							}
						}
						
						if (cursor)
						{
							cursor.seek(CursorBookmark.FIRST);
							while (!cursor.afterLast)
							{
								// if the category value already exists in the axis, than skip it
								if (catElements.indexOf(cursor.current[IEnumerableScale(angleAxis).categoryField]) == -1)
									catElements[j++] = 
										cursor.current[IEnumerableScale(angleAxis).categoryField];
								cursor.moveNext();
							}
						}

						// set the elements property of the CategoryAxis
						if (catElements.length > 0)
							IEnumerableScale(angleAxis).dataProvider = catElements;
					} else if (angleAxis is INumerableScale){
						
						if (INumerableScale(angleAxis).scaleType != BaseScale.PERCENT)
						{
							// if the default x axis is numeric, than calculate its min max values
							maxMin = getMaxMinAngleValueFromSeriesWithoutAngleAxis();
							INumerableScale(angleAxis).max = maxMin[0];
							INumerableScale(angleAxis).min = maxMin[1];
						} else {
							setPositiveTotalAngleValueInSeries();
						}
					}
				} 
				
				catElements = [];
				j = 0;

				// check if a default y axis exists
				if (radiusAxis)
				{
					if (radiusAxis is IEnumerableScale)
					{
						for (i = 0; i<nCursors; i++)
						{
							currentElement = IPolarElement(_elements[i]);
							// if the elements have their own data provider but have not their own
							// xAxis, than load their elements and add them to the elements
							// loaded by the chart data provider
							if (currentElement.dataProvider 
								&& currentElement.dataProvider != dataProvider
								&& ! currentElement.radiusAxis)
							{
								currentElement.cursor.seek(CursorBookmark.FIRST);
								while (!currentElement.cursor.afterLast)
								{
									if (catElements.indexOf(
										currentElement.cursor.current[IEnumerableScale(radiusAxis).categoryField]) 
										== -1)
										catElements[j++] = 
											currentElement.cursor.current[IEnumerableScale(radiusAxis).categoryField];
									currentElement.cursor.moveNext();
								}
							}
						}
						if (cursor)
						{
							cursor.seek(CursorBookmark.FIRST);
							while (!cursor.afterLast)
							{
								// if the category value already exists in the axis, than skip it
								if (catElements.indexOf(cursor.current[IEnumerableScale(radiusAxis).categoryField]) == -1)
									catElements[j++] = 
										cursor.current[IEnumerableScale(radiusAxis).categoryField];
								cursor.moveNext();
							}
						}
						
						// set the elements property of the CategoryAxis
						if (catElements.length > 0)
							IEnumerableScale(radiusAxis).dataProvider = catElements;
					} else if (radiusAxis is INumerableScale){
						
						if (INumerableScale(radiusAxis).scaleType != BaseScale.CONSTANT)
						{
							// if the default x axis is numeric, than calculate its min max values
							maxMin = getMaxMinRadiusValueFromSeriesWithoutRadiusAxis();
						} else {
							maxMin = [1,1];
							INumerableScale(radiusAxis).size = Math.min(width, height)/2;
						}
						INumerableScale(radiusAxis).max = maxMin[0];
						INumerableScale(radiusAxis).min = maxMin[1];
					}
				} 

				// check if a default color axis exists
				if (colorAxis)
				{
						// if the default color axis is numeric, than calculate its min max values
						maxMin = getMaxMinColorValueFromSeriesWithoutColorAxis();
						colorAxis.max = maxMin[0];
						colorAxis.min = maxMin[1];
				} 

				// init axes of all elements that have their own axes
				// since these are children of each elements, they are 
				// for sure ready for feeding and it won't affect the axesFeeded status
				for (var i:Number = 0; i<elements.length; i++)
					initSeriesAxes(elements[i]);
					
				axesFeeded = true;
			}
		}

		
		/** @Private
		 * Calculate the min max values for the default vertical (y) axis. Return an array of 2 values, the 1st (0) 
		 * for the max value, and the 2nd for the min value.*/
		private function getMaxMinRadiusValueFromSeriesWithoutRadiusAxis():Array
		{
			var max:Number = NaN, min:Number = NaN;
			for (var i:Number = 0; i<elements.length; i++)
			{
				currentElement = PolarElement(elements[i]);
				// check if the elements has its own y axis and if its max value exists and 
				// is higher than the current max
				if (!currentElement.radiusAxis && (isNaN(max) || max < currentElement.maxRadiusValue))
					max = currentElement.maxRadiusValue;
				// check if the elements has its own y axis and if its min value exists and 
				// is lower than the current min
				if (!currentElement.radiusAxis && (isNaN(min) || min > currentElement.minRadiusValue))
					min = currentElement.minRadiusValue;
			}
					
			return [max,min];
		}

		/** @Private
		 * Calculate the min max values for the default vertical (y) axis. Return an array of 2 values, the 1st (0) 
		 * for the max value, and the 2nd for the min value.*/
		private function getMaxMinAngleValueFromSeriesWithoutAngleAxis():Array
		{
			var max:Number = NaN, min:Number = NaN;
			for (var i:Number = 0; i<elements.length; i++)
			{
				currentElement = PolarElement(elements[i]);
				// check if the elements has its own y axis and if its max value exists and 
				// is higher than the current max
				if (!currentElement.angleAxis && (isNaN(max) || max < currentElement.maxAngleValue))
					max = currentElement.maxAngleValue;
				// check if the elements has its own y axis and if its min value exists and 
				// is lower than the current min
				if (!currentElement.angleAxis && (isNaN(min) || min > currentElement.minAngleValue))
					min = currentElement.minAngleValue;
			}
					
			return [max,min];
		}

		/** @Private
		 * Calculate the total of positive values to set in the percent axis and set it for each elements.*/
		private function setPositiveTotalAngleValueInSeries():void
		{
			INumerableScale(angleAxis).totalPositiveValue = NaN;
			var tot:Number = NaN;
			for (var i:Number = 0; i<elements.length; i++)
			{
				currentElement = PolarElement(elements[i]);
				// check if the elements has its own y axis and if its max value exists and 
				// is higher than the current max
				if (!isNaN(currentElement.totalAnglePositiveValue))
				{
					if (isNaN(INumerableScale(angleAxis).totalPositiveValue))
						INumerableScale(angleAxis).totalPositiveValue = currentElement.totalAnglePositiveValue;
					else
						INumerableScale(angleAxis).totalPositiveValue = 
							Math.max(INumerableScale(angleAxis).totalPositiveValue, 
									currentElement.totalAnglePositiveValue);
				}
			}
		}

		/** @Private
		 * Calculate the min max values for the default color axis. Return an array of 2 values, the 1st (0) 
		 * for the max value, and the 2nd for the min value.*/
		private function getMaxMinColorValueFromSeriesWithoutColorAxis():Array
		{
			var max:Number = NaN, min:Number = NaN;
			for (var i:Number = 0; i<elements.length; i++)
			{
				currentElement = elements[i];
				if (currentElement.colorField)
				{
					// check if the elements has its own color axis and if its max value exists and 
					// is higher than the current max
					if (!currentElement.colorAxis && (isNaN(max) || max < currentElement.maxColorValue))
						max = currentElement.maxColorValue;
					// check if the element has its own color axis and if its min value exists and 
					// is lower than the current min
					if (!currentElement.colorAxis && (isNaN(min) || min > currentElement.minColorValue))
						min = currentElement.minColorValue;
				}
			}
					
			return [max,min];
		}

		/** @Private
		 * Init the axes owned by the element passed to this method.*/
		private function initSeriesAxes(element:IPolarElement):void
		{
			if (element.cursor)
			{
				var elements:Array = [];
				var j:Number = 0;

				element.cursor.seek(CursorBookmark.FIRST);
				
				if (element.angleAxis is IEnumerableScale)
				{
					while (!element.cursor.afterLast)
					{
						// if the category value already exists in the axis, than skip it
						if (elements.indexOf(element.cursor.current[IEnumerableScale(element.angleAxis).categoryField]) == -1)
							elements[j++] = 
								element.cursor.current[IEnumerableScale(element.angleAxis).categoryField];
						element.cursor.moveNext();
					}
					
					// set the elements propery of the CategoryAxis owned by the current element
					if (elements.length > 0)
						IEnumerableScale(element.angleAxis).dataProvider = elements;
	
				} else if (element.angleAxis is INumerableScale)
				{
					if (INumerableScale(element.angleAxis).scaleType != BaseScale.PERCENT)
					{
						// if the element angle axis is just numeric, than calculate get its min max data values
						INumerableScale(element.angleAxis).max =
							element.maxAngleValue;
						INumerableScale(element.angleAxis).min =
							element.minAngleValue;
					} else {
						// if the element angle axis is percent numeric, than get the sum
						// of total positive data values from the element
						if (!isNaN(element.totalAnglePositiveValue))
							INumerableScale(element.angleAxis).totalPositiveValue = element.totalAnglePositiveValue;
					}
				}
	
				elements = [];
				j = 0;
				element.cursor.seek(CursorBookmark.FIRST);
				
				if (element.radiusAxis is IEnumerableScale)
				{
					while (!element.cursor.afterLast)
					{
						// if the category value already exists in the axis, than skip it
						if (elements.indexOf(element.cursor.current[IEnumerableScale(element.radiusAxis).categoryField]) == -1)
							elements[j++] = 
								element.cursor.current[IEnumerableScale(element.radiusAxis).categoryField];
						element.cursor.moveNext();
					}
							
					// set the elements propery of the CategoryAxis owned by the current element
					if (elements.length > 0)
						IEnumerableScale(element.radiusAxis).dataProvider = elements;
	
				} else if (element.radiusAxis is INumerableScale)
				{
					INumerableScale(element.radiusAxis).max =
						element.maxRadiusValue;
					INumerableScale(element.radiusAxis).min =
						element.minRadiusValue;
				}
	
			}
		}

		/** @Private
		 * The creation of default axes can be overrided so that it's possible to 
		 * select a specific default setup.*/
		protected function createAngleAxis():void
		{
			angleAxis = new PercentAngleAxis();

			// and/or to be overridden
		}
		/** @Private */
		protected function createRadiusAxis():void
		{
			radiusAxis = new NumericAxis();
			NumericAxis(radiusAxis).showAxis = false;

			// and/or to be overridden
		}

		private function removeAllElements():void
		{
			var i:int; 
			var child:*;
			
			for (i = 0; i<numChildren; i++)
			{
				child = getChildAt(0); 
				if (child is IScaleUI)
					IScaleUI(child).removeAllElements();
				if (child is DataItemLayout)
				{
					DataItemLayout(child).removeAllElements();
					DataItemLayout(child).geometryCollection.items = [];
					DataItemLayout(child).geometry = [];
				}

				removeChildAt(0);
			}
		}
	}
}