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
 
package birdeye.vis.scales
{
	import birdeye.vis.interfaces.INumerableScale;
	import birdeye.vis.interfaces.IScaleUI;
	
	import com.degrafa.geometry.Line;
	import com.degrafa.geometry.RasterTextPlus;
	import com.degrafa.paint.SolidFill;
	import com.degrafa.paint.SolidStroke;
	import com.degrafa.transform.RotateTransform;
	
	import flash.text.TextFieldAutoSize;

	public class Numeric extends XYZ implements INumerableScale, IScaleUI
	{
 		/** Define the min max data values for numeric scales [100, 200] where the values refer to data values, number of
 		 * inhabitants, rain falls, etc.*/
		override public function set dataValues(val:Array):void
		{
			_dataValues = val;
			_dataValues.sort(Array.NUMERIC);
			_min = dataValues[0];
			_max = dataValues[1];
		}
		
		/** @Private
		 * Decide whether to format or not, the min and max values of the scale.*/
		private var _format:Boolean = true;
		[Inspectable(enumeration="true,false")]
		public function set format(val:Boolean):void
		{
			_format = val;
		}

		/** @Private
		 * The minimum data value of the axis, after that the min is formatted 
		 * by the formatMin methods.*/
		private var minFormatted:Boolean = false;

		protected var _totalPositiveValue:Number = NaN;
		/** The total sum of positive values of the axis.*/
		public function set totalPositiveValue(val:Number):void
		{
			_totalPositiveValue = val;
		}
		public function get totalPositiveValue():Number
		{
			return _totalPositiveValue;
		}
		
		protected var _min:Number = NaN;
		/** The minimum value of the axis (if the axis is shared among more series, than
		 * this is the minimun value among all series.*/
		public function set min(val:Number):void
		{
			_min = val;
			minFormatted = !_format;
			formatMin();
			invalidateSize();
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get min():Number
		{
			return _min;
		}
		
		/** @Private
		 * The maximum data value of the axis, after that max is formatted 
		 * by the formatMax methods.*/
		private var maxFormatted:Boolean = false;

		protected var _max:Number = NaN;
		/** The maximum value of the axis (if the axis is shared among more series, than
		 * this is the maximum value among all series. */
		public function set max(val:Number):void
		{
			_max = val;
			maxFormatted = !_format;
			formatMax();
			invalidateSize();
			invalidateProperties();
			invalidateDisplayList();
		}
		public function get max():Number
		{
			return _max;
		}
		
		private var _baseAtZero:Boolean = false;
		/** Set the base of the axis at zero. If all values of the axis are positive (negative), 
		 * than the lowest base will be zero, even if the minimum value is higher (lower). */
		public function set baseAtZero(val:Boolean):void
		{
			_baseAtZero = val;
			invalidateProperties()
			invalidateDisplayList();
		}
		public function get baseAtZero():Boolean
		{
			return _baseAtZero;
		}
		
		// UIComponent flow
		
		public function Numeric()
		{
			super();
			scaleType = BaseScale.LINEAR;
		}
		
		override protected function commitProperties():void
		{
			super.commitProperties();

			if (isNaN(_min) && _dataValues)
				_min = _dataValues[0];
			if (isNaN(_max) && _dataValues) 
				_max = _dataValues[1];

			// if no interval is specified by the user, than divide the axis in 5 parts
			if (!isNaN(max) && !isNaN(min) && !isGivenInterval)
			{
				if (baseAtZero)
				{
					if (max > 0)
						_dataInterval = max / 5;
					else
						_dataInterval = -min / 5;
				} else {
					dataInterval = Math.abs((max - min) / 5)
					isGivenInterval = false;
				}
			}
			
			// if the placement is set, and max, min and interval calculated
			// than the axis is ready to be drawn
			if (placement && !isNaN(max) && !isNaN(min) && !isNaN(dataInterval))
			{
				if (showAxis)
					readyForLayout = true;
			}
			else 
				readyForLayout = false;
		}
		
		override protected function measure():void
		{
			super.measure();
 
 			if (!isNaN(min) && !isNaN(max) && placement)
				maxLabelSize();
 		}
		
		// other methods
		
		/** @Private
		 * Calculate the maximum label size, necessary to define the needed 
		 * width (for y axes) or height (for x axes) of the CategoryAxis.*/
		override protected function maxLabelSize():void
		{
			if (showAxis)
			{
				var text:String = String(String(min).length < String(max).length ?
										max : min);
	
				switch (placement)
				{
					case TOP:
					case BOTTOM:
					case HORIZONTAL_CENTER:
						maxLblSize = sizeLabel /* pixels for 1 char height */ + thickWidth + 10;
						height = maxLblSize;
						break;
					case LEFT:
					case RIGHT:
					case VERTICAL_CENTER:
						maxLblSize = text.length * sizeLabel/2 /* pixels for 1 char width */ + thickWidth + 10;
						width = maxLblSize;
				}
				// calculate the maximum label size according to the 
				// styles defined for the axis 
				super.calculateMaxLabelStyled();
			} else
				maxLblSize = 0;
		}

		/** @Private
		 * Draw axes depending on their orientation:
		 * xMin == xMax means that the orientation is vertical; 
		 * yMin == yMax means that the orientation is horizontal.
		 */
		override protected function drawAxes(xMin:Number, xMax:Number, yMin:Number, yMax:Number, sign:Number):void
		{
			var snap:Number;
			
			if (isNaN(maxLblSize) && !isNaN(min) && !isNaN(max) && placement)
				maxLabelSize();

			if (size > 0 && !isNaN(dataInterval) && showLabels && invalidated)
			{	
				invalidated = false;
				// vertical orientation
				if (xMin == xMax)
				{
					for (snap = min; snap<=max; snap += dataInterval)
					{
						// create thick line
			 			thick = new Line(xMin + thickWidth * sign, getPosition(snap), xMax, getPosition(snap));
						thick.stroke = new SolidStroke(colorStroke, alphaStroke, weightStroke);
						gg.geometryCollection.addItem(thick);
			
						// create label 
	 					label = new RasterTextPlus();
	 					label.fontFamily = fontLabel;
	 					label.fontSize = sizeLabel;
						label.text = String(Math.round(snap));
	 					label.visible = true;
						label.autoSize = TextFieldAutoSize.LEFT;
						label.autoSizeField = true;
						if (!isNaN(_rotateLabels) || _rotateLabels != 0)
						{
							var rot:RotateTransform = new RotateTransform();
							rot = new RotateTransform();
							switch (placement)
							{
								case RIGHT:
									_rotateLabelsOn = "centerLeft";
									break;
								case LEFT:
									_rotateLabelsOn = "centerRight";
									break;
							}
							rot.registrationPoint = _rotateLabelsOn;
							rot.angle = _rotateLabels;
							label.transform = rot;
						}
						
						label.y = getPosition(snap)-label.displayObject.height/2;
						label.x = thickWidth * sign; 
						label.fill = new SolidFill(colorLabel);
						gg.geometryCollection.addItem(label);
					}
				} else {
				// horizontal orientation
					for (snap = min; snap<=max; snap += dataInterval)
					{
						// create thick line
			 			thick = new Line(getPosition(snap), yMin + thickWidth * sign, getPosition(snap), yMax);
						thick.stroke = new SolidStroke(colorStroke, alphaStroke, weightStroke);
						gg.geometryCollection.addItem(thick);
	
						// create label 
	 					label = new RasterTextPlus();
						label.text = String(Math.round(snap));
	 					label.fontFamily = fontLabel;
	 					label.fontSize = sizeLabel;
	 					label.visible = true;
						label.autoSize = TextFieldAutoSize.LEFT;
						label.autoSizeField = true;
						label.y = thickWidth;
						if (!isNaN(_rotateLabels) && _rotateLabels != 0)
						{
							rot = new RotateTransform();
							switch (placement)
							{
								case TOP:
									_rotateLabelsOn = "centerLeft";
									label.x = getPosition(snap); 
									break;
								case BOTTOM:
									_rotateLabelsOn = "centerRight";
									label.x = getPosition(snap)-label.displayObject.width; 
									break;
							}
							rot.registrationPoint = _rotateLabelsOn;
							rot.angle = _rotateLabels;
							label.transform = rot;
						} else
							label.x = getPosition(snap)-label.displayObject.width/2; 
						label.fill = new SolidFill(colorLabel);
						gg.geometryCollection.addItem(label);
					}
				}
			}
		}
		
		/** @Private
		 * Calculate the format of the axis values, in order to have 
		 * the more rounded values possible.*/ 
		private function formatMax():void
		{
			if (!maxFormatted && !isNaN(max))
			{
				var sign:Number = 1;
				var tempMax:Number = Math.ceil(max);
				if (max<0)
					sign = -1;
				var maxLenght:Number = String(Math.abs(tempMax)).length;
				tempMax /= Math.pow(10, maxLenght-1);
				tempMax = Math.ceil(tempMax);
				tempMax *= Math.pow(10, maxLenght-1);
				_max = tempMax * sign;
				maxFormatted = true; 
			}
		}

		/** @Private
		 * Calculate the format of the axis values, in order to have 
		 * the more rounded values possible.*/ 
		private function formatMin():void
		{
			if (!minFormatted && !isNaN(min))
			{
				var tempMin:Number;
				var minLenght:Number;
				tempMin = Math.floor(Math.abs(min));
				 
				if (min<0)
				{
					minLenght = String(tempMin).length;
					tempMin /= Math.pow(10, minLenght-1);
					tempMin = Math.ceil(tempMin);
					tempMin *= Math.pow(10, minLenght-1);
					_min = - tempMin;
					maxFormatted = true;
				} else {
					minLenght = String(tempMin).length;
					tempMin /= Math.pow(10, minLenght);
					tempMin = Math.floor(tempMin);
					tempMin *= Math.pow(10, minLenght);
					_min = tempMin;
					maxFormatted = true;
				} 
			}
		}

		/** @Private
		 * Override the XYZAxis getPostion method with a generic numeric function.
		 * This allows to define any type of scaling for a numeric axis.*/
		override public function getPosition(dataValue:*):*
		{
			if (_function == null)
			{
				if (scaleType == BaseScale.CONSTANT)
					return _size;
				else
					return _size * (Number(dataValue) - min)/(max - min);
			}
			else 
				return _function(dataValue, min, max, _size);
		}
		
		override public function resetValues():void
		{
			super.resetValues();
			min = max = totalPositiveValue = NaN;
			invalidated = true;
		} 
	}
}