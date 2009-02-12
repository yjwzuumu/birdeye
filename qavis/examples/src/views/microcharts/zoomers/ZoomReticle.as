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
 
package views.microcharts.zoomers
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	
	 /**
	 * <p>This component zooms on specific DisplayObject target. 
	 * Here's an example of how to use it:
	 * <zoomers:ZoomReticle target="{nav}" id="zoomReticle" zoom="4" 
	 * 	eventType="roll-over" shape="rectangle" width="150" height="100" 
	 * 	draggable="true" followMouse="false" 
	 * 	backgroundColor="0xffffff" borderColor="0x000000"/> 
	 * 	
	*/
	public class ZoomReticle extends UIComponent
	{ 
	    private var _target:DisplayObject;

		private var targetCopy:BitmapData;
		private var targetCopyCont:Bitmap;
	    private var maskWidth:Number = NaN, maskHeight:Number = NaN;
		
		private var _zoom:Number = 5;
		
		public static const CLICK:String = "click";
		public static const DOUBLE_CLICK:String = "double-click";
		public static const ROLL_OVER:String = "roll-over";
		public static const CIRCLE:String = "circle";
		public static const RECTANGLE:String = "rectangle";
		
		private var _shape:String = CIRCLE; 
		private var _xOffsetFromMouse:Number = 10;
		private var _yOffsetFromMouse:Number = 10;
		private var _eventType:String = CLICK;
		private var _followMouse:Boolean = false;
		private var _backgroundColor:Number = HawkUtils.BLACK;
		private var _borderColor:Number = HawkUtils.RED;
		private var _backgroundAlpha:Number = 0.5;
		private var _borderAlpha:Number = 0.5;
		
		// Offset positions used when moving the toolbar on dragging/dropping
	    private var offsetX:Number, offsetY:Number;
	    // Keep the starting point position when dragging, if mouse goes out of the parents' view
	    // than the toolbar will be repositioned to this point
	    private var startDraggingPoint:Point;

		private var _draggable:Boolean = false;
		
		public function set target(val:DisplayObject):void
		{
			_target = val;
		    init();
		}

		[Inspectable(enumeration="true,false")]
		public function set draggable(val:Boolean):void
		{
			_draggable = val;
		}

		[Inspectable(enumeration="circle,rectangle")]
		public function set shape(val:String):void
		{
			_shape = val;
		}

		public function set xOffsetFromMouse(val:Number):void
		{
			_xOffsetFromMouse = val;
		}
		
		public function set yOffsetFromMouse(val:Number):void
		{
			_yOffsetFromMouse = val;
		}
		
		[Inspectable(enumeration="click,roll-over,double-click")]
		public function set eventType(val:String):void
		{
			_eventType = val;
		}
		
		[Inspectable(enumeration="true,false")]
		public function set followMouse(val:Boolean):void
		{
			_followMouse = val;
		}

		public function set zoom(val:Number):void
		{
			_zoom = val;
		}
		
		public function set backgroundColor(val:Number):void
		{
			_backgroundColor = val;
		}
		
		public function set borderColor(val:Number):void
		{
			_borderColor = val;
		}
				
		public function set backgroundAlpha(val:Number):void
		{
			if (val <= 1 && val >= 0)
				_backgroundAlpha = val;
		}

		public function set borderAlpha(val:Number):void
		{
			if (val <= 1 && val >= 0)
				_borderAlpha = val;
		}

		/**
		 * Set the scale value. The final size of this controller will be based on the target size
		 * reduced by this value  
		 */
		public function set scale(val:Number):void
		{
			if (val >= 0)
				_zoom = val;
		}

		public function ZoomReticle()
		{
			super(); 
		}
		
		/**
		 * @Private
		 * Register the target object and calculate this.sizes  
		 */
		private function init():void
		{
			// Add the resizing event handler.

			switch (_eventType)
			{
				case ROLL_OVER:
					_target.removeEventListener(MouseEvent.CLICK, drawAll, true);
					_target.removeEventListener(MouseEvent.DOUBLE_CLICK, drawAll, true);
					_target.addEventListener(MouseEvent.MOUSE_MOVE, drawAll, true);
				break;
				case DOUBLE_CLICK:
					_target.removeEventListener(MouseEvent.CLICK, drawAll, true);
					_target.removeEventListener(MouseEvent.MOUSE_MOVE, drawAll, true);
					_target.addEventListener(MouseEvent.DOUBLE_CLICK, drawAll, true);
				break;
				case CLICK:
					_target.removeEventListener(MouseEvent.DOUBLE_CLICK, drawAll, true);
					_target.removeEventListener(MouseEvent.MOUSE_MOVE, drawAll, true);
					_target.addEventListener(MouseEvent.CLICK, drawAll, true);
			}
			
			if (_draggable)
				addEventListener(MouseEvent.MOUSE_DOWN, moveToolbar);
		}
	
		// Resize panel event handler.
		public  function moveToolbar(event:MouseEvent):void
		{
	  		startMovingToolBar(event);
	  		stage.addEventListener(MouseEvent.MOUSE_UP, stopMovingToolBar);
		}
		
		// Start moving the toolbar
	    private function startMovingToolBar(e:MouseEvent):void
	    {
	    	startDraggingPoint = new Point(this.x, this.y);
	    	offsetX = e.stageX - this.x;
	    	offsetY = e.stageY - this.y;
	    	stage.addEventListener(MouseEvent.MOUSE_MOVE, dragToolBar);
	    }
	    
	    // Reset the toolbar position to the starting point
	    private function resetToolBarPosition(e:MouseEvent):void
	    {
	    	stopMovingToolBar(e);
	    	this.x = startDraggingPoint.x;
	    	this.y = startDraggingPoint.y;
	    	this.parent.removeEventListener(MouseEvent.ROLL_OUT, resetToolBarPosition);
	    }
	    
	    // Stop moving the toolbar 
	    private function stopMovingToolBar(e:MouseEvent):void
	    {
	    	stage.removeEventListener(MouseEvent.MOUSE_MOVE, dragToolBar)
	  		stage.removeEventListener(MouseEvent.MOUSE_UP, stopMovingToolBar);
	    	this.parent.removeEventListener(MouseEvent.ROLL_OUT, resetToolBarPosition);
	    }
	    
	    // Moving the toolbar while MOUSE_MOVE event is on
	    private function dragToolBar(e:MouseEvent):void
	    {
	    	this.x = e.stageX - offsetX;
	    	this.y = e.stageY - offsetY;
	    	e.updateAfterEvent();
	    	// dispatch moved toolbar event
	    }
	    
		/**
		 * @Private
		 * Create draggableRect and its mask 
		 */
 		override protected function createChildren():void
		{
			super.createChildren();
			
		}
		
		/**
		 * @Private
		 * Draw all graphics 
		 */
		private function drawAll(e:MouseEvent):void
		{
			clearAll();
			
			if (_followMouse && !_draggable)
			{
				var localPoint:Point = localToContent(new Point(_target.parent.mouseX, _target.parent.mouseY))
	   			x = localPoint.x - width/2 + _xOffsetFromMouse;
				y = localPoint.y - height/2 + _yOffsetFromMouse;
trace("hkView", x,y, _target.mouseX, _target.mouseY)
			}

			var msk:Shape = new Shape();
 			switch (_shape)
 			{
 				case CIRCLE:
 					// radius size is width
 					height = width;
 					with (msk.graphics)
 					{
						moveTo(x,y);
		 				beginFill(_backgroundColor, _backgroundAlpha);
		 				drawCircle(width/2,height/2,width/2);
		 				endFill();
 					}
					// draws rectangle border
					with (graphics)
					{
						moveTo(x,y);
		 				beginFill(_backgroundColor, _backgroundAlpha);
		 				drawCircle(width/2,height/2,width/2);
		 				endFill();
					}  
 				break;
 				case RECTANGLE:
 					with (msk.graphics)
 					{
		  				moveTo(0,0);
		 				beginFill(_backgroundColor, _backgroundAlpha);
		 				drawRect(0,0,width,height);
		 				endFill();
 					}
					// draws rectangle border  
		  			with (graphics)
		  			{
		  				moveTo(0,0);
		 				beginFill(_backgroundColor, _backgroundAlpha);
		 				drawRect(0,0,width,height);
		 				endFill();
						moveTo(0,0);
						lineStyle(2,_borderColor,_borderAlpha);
						lineTo(width,0);
						lineTo(width,height);
						lineTo(0,height);
						lineTo(0,0);
		  			}
 				break;
 			}
 			addChild(msk);

		    var moveX:int = _target.mouseX;
		    var moveY:int = _target.mouseY;
		    
			// create the bitmap of the target and scale using the scale property value 
			var sourceRect:Rectangle = new Rectangle(0,0,width,height);
			if (targetCopy != null)
				targetCopy.dispose();
			targetCopy = new BitmapData(sourceRect.width, sourceRect.height,true,0x000000);
			var matr:Matrix = new Matrix();
 			matr.translate(-moveX, -moveY);
 			matr.scale(_zoom, _zoom);
 			matr.translate(width/2, height/2);
 			targetCopy.draw(_target,matr,null,null,sourceRect,true);
			targetCopyCont = new Bitmap(targetCopy);
			targetCopyCont.mask = msk;
			addChild(targetCopyCont);
  		}
 		
		/**
		 * @Private
		 * Remove and clear everything
		 */
 		private function clearAll():void
 		{
			for (var childIndex:Number = 0; childIndex <= numChildren-1; childIndex++)
				removeChildAt(childIndex);
			
			graphics.clear();
			if (targetCopy != null)
				targetCopy.dispose();
 		}
	}
}

class HawkUtils 
{
	public static const GREY:Number = 0x777777;
	public static const WHITE:Number = 0xffffff;
	public static const YELLOW:Number = 0xffd800;
	public static const RED:Number = 0xff0000;
	public static const BLUE:Number = 0x009cff;
	public static const GREEN:Number = 0x00ff54;
	public static const BLACK:Number = 0x000000;
	
	public static const size:Number = 40;
	public static const thick:Number = 2;
}
