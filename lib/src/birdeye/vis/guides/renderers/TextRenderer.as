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
 
package birdeye.vis.guides.renderers
{
	import com.degrafa.core.IGraphicsFill;
	import com.degrafa.geometry.RasterTextPlus;
	
	import flash.geom.Rectangle;
	import flash.text.TextFieldAutoSize;

	public class TextRenderer extends RasterTextPlus
	{
		public function TextRenderer (bounds:Rectangle = null)
		{
		}
		
		public static function createTextLabel(xPos:Number, yPos:Number, text:String, fill:IGraphicsFill,
											   centerHorizontally:Boolean = true, centerVertically:Boolean = true):TextRenderer {
			const label:TextRenderer = new TextRenderer();
			label.text = text;
			label.fill = fill;
			label.alpha = 1.0;
			label.autoSize = TextFieldAutoSize.LEFT;
			label.autoSizeField = true;
			if (centerHorizontally)
				label.x = xPos - label.displayObject.width/2;
			else
				label.x = xPos;
			if (centerVertically)
				label.y = yPos - label.displayObject.height/2;
			else
				label.y = yPos;
			return label;
		}
		
	}
}