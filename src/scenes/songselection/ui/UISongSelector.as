package scenes.songselection.ui
{
    import classes.ui.UIComponent;
    import flash.geom.Rectangle;
    import flash.display.DisplayObjectContainer;
    import classes.engine.EngineLevel;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    import classes.ui.VScrollBar;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import classes.engine.EngineCore;
    import classes.ui.UIAnchor;
    import classes.ui.FormItems;
    import classes.ui.FormManager;

    public class UISongSelector extends UIComponent
    {
		public static const LIST_SONG:String = "song-list";

		private var core:EngineCore;

		private var _formItems:FormItems;
		private var _pane:Sprite;
		private var _vscroll:VScrollBar;

		private var songButtons:Vector.<SongButton> = new Vector.<SongButton>();
        private var renderElements:Vector.<EngineLevel>;
        private var renderCount:int = 0;

        private var _scrollY:Number = 0;
		private var _calcHeight:int = 0;

		public var selectedSongData:EngineLevel;

        public function UISongSelector(core:EngineCore, parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			this.core = core;
			super(parent, xpos, ypos);
		}

		/**
		 * Initializes the component.
		 */
		override protected function init():void
		{
			_formItems = FormManager.registerGroup(core.ui.scene, LIST_SONG, UIAnchor.WRAP_VERTICAL, FormItems.NONE);
			_formItems.setHandleAction(_handleFormAction);

			setSize(150, 100, false);
			super.init();
		}

		/**
		 * TODO: Fix this or really fix scrollChildVertical, which makes this needed?
		 * Override FormManger handler. Currently broken.
		 * @param action 
		 * @param index 
		 * @return 
		 */
		public function _handleFormAction(action:String, index:Number = 0):Array
		{
			trace("_handleFormAction:", action, index);
			if(action != "up" && action != "down")
				return [false, null];

			return [true, null];
		}
		
		/**
		 *  Creates the Content Pane and Scrollbar for this components.
		 */
		override protected function addChildren():void
		{
			_pane = new Sprite();
			_pane.addEventListener(MouseEvent.MOUSE_WHEEL, e_scrollWheel);
			addChild(_pane);
			
			_vscroll = new VScrollBar();
			_vscroll.addEventListener(Event.CHANGE, e_scrollVerticalUpdate);
			addChild(_vscroll);
		}
		
		/**
		 * Sets the size of the component.
		 * @param w The width of the component.
		 * @param h The height of the component.
		 */
		override public function setSize(w:Number, h:Number, redraw:Boolean = true):void
		{
            scrollRect = new Rectangle(0, 0, w + 1, h);
			super.setSize(w, h, redraw);
		}

		/**
		 * Redraws the component, moving the scroll bar and updating the
		 * interactive background plane.
		 */
		override public function draw():void
		{
			_vscroll.setSize(15, _height);
			_vscroll.move(_width - 15, 0);

			_pane.graphics.clear();
			_pane.graphics.beginFill(0x000000, 0);
			_pane.graphics.drawRect(0, 0, width, height);
			_pane.graphics.endFill();
		}

		/**
		 * Update the width of all child elements to the pane width.
		 */
		public function updateWidths():void
		{
			for(var i:int = _pane.numChildren - 1; i >= 0; i--)
				_pane.getChildAt(i).width = paneWidth;
		}

		/**
		 * Sets the data for the Song Selector to use as a reference for drawing.
		 * @param list Array on EngineLevel Items to use.
		 */
        public function setRenderList(list:Array):void
        {
			clearButtons(true);

            var i:int;

			renderCount = list.length;

			_scrollY = 0;
			_calcHeight = (renderCount * (5 + SongButton.FIXED_HEIGHT));
			_vscroll.scrollFactor = scrollFactorVertical;
			_vscroll.showDragger = doScroll;

            renderElements = new Vector.<EngineLevel>(renderCount, true);
            for (i = 0; i < list.length; i++)
                renderElements[i] = list[i];
			
			updateChildrenVisibility();
        }

		/**
		 * Creates and Removes Song Buttons from the stage, depending on the scroll position.
		 * This method uses Pooling on Song Buttons to minimize the amount of SongButtons
		 * created on screen.
		 */
		public function updateChildrenVisibility():void
		{
			if(renderElements == null || renderElements.length == 0)
				return;

			var i:int;
			
			var songButton:SongButton;
			var _y:Number;
			var _inBounds:Boolean;
			var songObject:EngineLevel;

			var GAP:int = (SongButton.FIXED_HEIGHT + 5);
			var startingIndex:int = Math.max(0, Math.floor((_scrollY * -1) / GAP) - 1);
			var lastIndex:int = Math.min(renderCount, (startingIndex + (height / GAP) + 3));
			var START_POINT:int = _scrollY;

			// Update Existing
			var len:int = songButtons.length - 1;
			for (i = len; i >= 0; i--)
			{
				songButton = songButtons[i];
				songButton.garbageSweep = 0;

				_y = START_POINT + songButton.index * GAP;
				_inBounds = (_y > -GAP && _y < height);

				// Unlink SongButton no longer on stage.
				if (!_inBounds)
					removeSongButton(songButton);

				// Update Position
				else
					moveSongButton(_y, songButton);
			}

			// Add New Song Buttons
			for (i = startingIndex; i < lastIndex; i++)
			{
				songObject = renderElements[i];

				// Check for Existing Button
				if(findSongButton(songObject) != null)
					continue;
				
				// Create Song Button
				_y = START_POINT + i * GAP;
				_inBounds = (_y > -GAP && _y < height);

				if (_inBounds)
				{
					songButton = getSongButton();
					songButton.index = i;
					songButton.setData(core, songObject);
					songButton.width = paneWidth;
					songButton.highlight = (songObject == selectedSongData);
					_pane.addChild(songButton);
					moveSongButton(_y, songButton);
					songButtons[songButtons.length] = songButton;
				}
			}

			// Remove Old Song Buttons
			len = songButtons.length - 1;
			for (i = len; i >= 0; i--)
			{
				songButton = songButtons[i];
				if(songButton.garbageSweep == 0)
					removeSongButton(songButton);
			}
		}

		/**
		 * Moves the SongButton to the y value. Also marks the song button 
		 * as in use for the removal sweep.
		 * @param _y 
		 * @param btn 
		 */
		public function moveSongButton(_y:int, btn:SongButton):void
		{
			btn.y = _y;
			btn.garbageSweep = 1;
		}

		/**
		 * Finds the on stage SongButton for the given EngineLevel.
		 * @param level EngineLevel to look for.
		 * @return If a SongButton exist already for this level.
		 */
		public function findSongButton(level:EngineLevel):SongButton
		{
			if(songButtons.length == 0)
				return null;

			var len:int = songButtons.length - 1;
			for(;len >= 0; len--)
			{
				if(songButtons[len].songData === level)
					return songButtons[len];
			}
			return null;
		}

		/**
		 * Removes the SongButton from stage, along with moving it 
		 * back into the object pool.
		 * @param btn SongButton to remove.
		 */
		public function removeSongButton(btn:SongButton):void
		{
			var idx:int = songButtons.indexOf(btn);
			if(idx >= 0) songButtons.splice(idx, 1);

			btn.parent.removeChild(btn);
			putSongButton(btn);
		}

		/**
		 * Clears the component of old data.
		 */
		public function clear():void
		{
			clearButtons();

			renderCount = 0;
			renderElements = null;
			_calcHeight = 0;
			_vscroll.showDragger = false;
			_vscroll.scroll = 0;
		}

		/**
		 * Removes all SongButtons from the stage.
		 * @param force Force Remove, regardless of sweep value.
		 */
		public function clearButtons(force:Boolean = false):void
		{
			var songButton:SongButton;

			// Remove Old Song Buttons
			var len:int = songButtons.length - 1;
			for (; len >= 0; len--)
			{
				songButton = songButtons[len];
				if(songButton.garbageSweep == 0 || force)
					removeSongButton(songButton);
			}
		}
		
		/**
		 * Resets the scroll back to 0;
		 */
		public function scrollReset():void 
		{
			_vscroll.scroll = 0;
		}

		///////////////////////////////////
		// components get / set
		///////////////////////////////////
		
		/**
		 * Overall size of the scroll pane, excluding the scrollbar width.
		 * @return Pane Width
		 */
		public function get paneWidth():Number
		{
			return width - 25;
		}

		/**
		 * Check the requirement if scrolling should happen.
		 * @return 
		 */
		public function get doScroll():Boolean
		{
			return _calcHeight > _height;
		}

		/**
		 * Gets the current vertical scroll factor.
		 * Scroll factor is the percent of the height the scrollpane is compared to the overall content height.
		 */
		public function get scrollFactorVertical():Number
		{
			return Math.max(Math.min(height / _calcHeight, 1), 0) || 0;
		}

		public function set scrollVertical(val:Number):void
		{
			_scrollY = -((_calcHeight - this.height) * Math.max(Math.min(val, 1), 0));
			updateChildrenVisibility();
		}

		/**
		 * Scrolls the child into view. If it exist.
		 * @param child 
		 */
		public function scrollChild(child:DisplayObject):void
		{
			_vscroll.scroll = scrollChildVertical(child);
		}

		/**
		 * TODO: Extremely Broken due to use of non-existent pool objects.
		 * 
		 * Gets the vertical scroll value required to display a specified child.
		 * @param	child Child to show.
		 * @return	Scroll Value required to show child in center of scroll pane.
		 */
		public function scrollChildVertical(child:DisplayObject):Number
		{
			// Checks
			if (child == null || !_pane.contains(child) || !doScroll)
				return 0;
			
			// Child is to tall, Scroll to top.
			if(child.height > height)
				return Math.max(Math.min((_scrollY + child.y) / (_calcHeight - this.height), 1), 0);
			
			return Math.max(Math.min((((_scrollY + child.y) + (child.height / 2)) - (this.height / 2)) / (_calcHeight - this.height), 1), 0);
		}

		///////////////////////////////////
		// event handlers
		///////////////////////////////////
		
		private function e_scrollWheel(e:MouseEvent):void
		{
			if (doScroll)
				_vscroll.scroll += (scrollFactorVertical / 2) * (e.delta > 1 ? -1 : 1);
		}
		
		private function e_scrollVerticalUpdate(e:Event):void
		{
			scrollVertical = _vscroll.scroll;
		}


		////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/** SongButton Pool Vector */
        private static var __vectorSongButton:Vector.<SongButton> = new Vector.<SongButton>();

        /** Retrieves a SongButton instance from the pool. */
        public static function getSongButton():SongButton
        {
            if (__vectorSongButton.length == 0) return new SongButton();
            else return __vectorSongButton.pop();
        }

        /** Stores a SongButton instance in the pool.
         *  Don't keep any references to the object after moving it to the pool! */
        public static function putSongButton(songbutton:SongButton):void
        {
            if (songbutton) 
			{
				songbutton.highlight = false;
				__vectorSongButton[__vectorSongButton.length] = songbutton;
			}
        }

    }
}