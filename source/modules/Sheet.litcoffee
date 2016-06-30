#  SHEET  #
Sprite-sheet managing

- - -

##  Introduction  ##

>   *To come.*

##  Implementation  ##

    "use strict";

    ###
    SHEET
    Sprite-sheet managing
    ---------------------
    ###

The `Sheet` constructor generates sprite-sheets and manages their rendering on a `CanvasRenderingContext2D`.
It is packaged with `Sprite`, which describes a single sprite on the sheet.

###  General functions:  ###

The function `drawSprite()` is called by `Sprite`s and `Sheet`s in order to draw their images.
It is not exposed to the window.

    drawSprite = (sheet, start_index, context, x, y, frame = 1) ->

…That's a lot of arguments. Let's go through them:

- `sheet` is the `Sheet` from which to draw the sprite
- `start_index` gives us the index of the sprite within the sheet
- `context` is the `CanvasRenderingContext2D` on which to draw the sprite
- `x` is the x-coordinate of the top-left corner of the sprite
- `y` is the y-coordinate of the top-left corner of the sprite
- `frame` is merely there as a convenience: It increments `start_index` by its value

The first thing we do is make sure everything is typed correctly.
The `sheet` and `context`, clearly, need to be of a certain type in order for this to work.
If any of the other provided arguments aren't numbers, however, we can go ahead and reset them to zero.

        return unless sheet instanceof Sheet and start_index < sheet.size and context instanceof CanvasRenderingContext2D
        start_index = 0 if isNaN(start_index = Number(start_index))
        x = 0 if isNaN(x = Math.round(x))
        y = 0 if isNaN(y = Math.round(y))
        frame = 0 if isNaN(frame = Number(frame))

Now we can increment `start_index` by `frame`'s value:

        start_index += frame

Next, we need to find the horizontal (`i`) and vertical (`j`) position of the sprite on the sheet.
We can get this information from `start_index` with a little math:

        i = start_index % sheet.width
        j = Math.floor(start_index / sheet.width)

These two lines just make the image a little easier to access:

        source = sheet.source
        image = sheet.image

Now we have all we need to draw the sprite!
There is a HUGE `if`-statement associated with the draw function, because we want to make sure that what we're drawing is actually there.
If it isn't, then obviously we can't draw anything.

Remember also that `image` is preferenced if defined.

        context.drawImage((if createImageBitmap? and image instanceof ImageBitmap then image else source), i * width, j * height, width, height, x, y, width, height) if (source instanceof HTMLImageElement and source.complete or source instanceof SVGImageElement or source instanceof HTMLCanvasElement or createImageBitmap? and (image instanceof ImageBitmap or source instanceof ImageBitmap)) and not isNaN(i) and not isNaN(j) and (width = Number(sheet.sprite_width)) and (height = Number(sheet.sprite_height))

Let's go through what that `if`-statement actually did.
First, we make sure that the `Sheet` actually has an image associated with it:

-   `source instanceof HTMLImageElement and source.complete`—
    If the image source is an `<img>` element, then it needs to have finished loading.

-   `source instanceof SVGImageElement or source instanceof HTMLCanvasElement`—
    The source doesn't have to be an `<img>` element though! It can also be an `<svg>` or a `<canvas>`.

-   `createImageBitmap? and (image instanceof ImageBitmap or source instanceof ImageBitmap)`—
    Finally, the source can be an `ImageBitmap`.
    This isn't supported in all browsers, so we check to make sure `createImageBitmap` exists first.
    However, if `createImageBitmap` *is* supported, then `Sheet`s have a special property, `Sheet.image`, which might contain one, and this should be given preference.

We also need to make sure that the sprite exists on the sheet:

-   `not isNaN(i) and not isNaN(j)`—
    This makes sure that our indices are actually, y'know, numbers.

-   `(width = Number(sheet.sprite_width)) and (height = Number(sheet.sprite_height))`—
    This makes sure that the sprites in the sheet have a non-zero width and height.
    It also sets the variables `width` and `height` to those values, for convenient access later.

###  Sprite:  ###

`Sprite` creates a reference to a sprite on a sheet.
For efficiency's sake, it does *not* actually contain any of the image data associated with that sprite.

####  The constructor  ####

The constructor takes three arguments: `sheet`, which gives the sheet; `index`, which is the index of the sprite on the sheet; and `length`, which for animated sprites gives the length of the animation.

    Sprite = (sheet, index, length = 1) ->

If `index` or `length` aren't numbers, then we go ahead and set them to `0` and `1`, respectively.
If `sheet` isn't a `Sheet`, then we set it to be null.

        sheet = null unless sheet instanceof Sheet
        index = 0 if isNaN(index = Number(index))
        length = 1 if isNaN(length = Number(length)) or length <= 0

Now we can set the properties.
Note that `draw` simply binds `drawSprite` to the given `Sheet` and `index`.

        @draw = drawSprite.bind(null, sheet, index)
        @height = if sheet then sheet.sprite_height else 0
        @index = index
        @frames = length
        @sheet = sheet
        @width = if sheet then sheet.sprite_width else 0

Since `Sprite`s are just static references, they should be immutable:

        Object.freeze this

And we're done!

####  The prototype  ####

`Sprite`s are very simple, and because the `draw` function is bound above, they don't really have a prototype.
For purposes of inheritance, however, I've thrown this minimal one together:

    Sprite.prototype = {draw: ->}
    Object.freeze Sprite.prototype

###  Sheet:  ###

`Sheet`s associate images with data and methods to make them easily referencable as sprite-sheets.

####  The constructor  ####

The `Sheet` constructor only takes three arguments: `source`, which gives the source image for the sheet, `sprite_width`, which gives the width of the sprites, and `sprite_height`, which gives their height.
In doing so, it makes the assumption that sprites and sprite-sheets do not have any borders or padding.
(Because borders and padding result in larger download times for users, this restriction is considered acceptable, but it may be lifted at some time in the future.)

    Sheet = (source, sprite_width, sprite_height) ->

First, we need to handle the arguments.
If `source` isn't an image type that we recognize, we go ahead and set it to `null`.
And if the `sprite_width` or `sprite_height` aren't recognizable as numbers, we set them to 0.
(Note from the above that a `Sheet` with zero `sprite_width` or `sprite_height` cannot be drawn.)

        source = null unless source instanceof HTMLImageElement or source instanceof SVGImageElement or source instanceof HTMLCanvasElement or createImageBitmap? and source instanceof ImageBitmap
        sprite_width = 0 if isNaN(sprite_width = Number(sprite_width))
        sprite_height = 0 if isNaN(sprite_height = Number(sprite_height))

Recall that we need to check for `createImageBitmap` before checking to see if the source is an `ImageBitmap`.

We can get the width and height of the image from one of two sources, depending on the source type.
All of the accepted types have `width` and `height` properties, which specify their dimensions.
However, `HTMLImageElement`s also have `naturalWidth` and `naturalHeight` properties, and these should be preferred for pixel-perfect rendering.

If for some reason we can't get *either* of these properties, then the `source_width` and `source_height` are set to zero.

        source_width = 0 unless source? and not isNaN(source_width = Number(if source.naturalWidth? then source.naturalWidth else source.width))
        source_height = 0 unless source? and not isNaN(source_height = Number(if source.naturalHeight? then source.naturalHeight else source.height))

We now have everything we need to define the properties.
Note that `width` and `height` are provided in sprite-units, not pixels.
If `sprite_width` or `sprite_height` are `0`, then the corresponding `width` and `height` are obviously `NaN`.

        @height = Math.floor(source_height / sprite_height)
        @source = source
        @sprite_height = sprite_height
        @sprite_width = sprite_width
        @width = Math.floor(source_width / sprite_width)

The `size` property is just `width` times `height`.

        @size = @width * @height

The `image` property is defined using a getter in order to allow the `createImageBitmap` callback to change it.

        image = null
        Object.defineProperty(this, "image", {get: -> image})

`ImageBitmap`s are optimized for drawing to the canvas.
If they are supported, we can pre-render the sprite-sheet and store this in the `image` property.

        createImageBitmap(source).then((img) -> image = img) if createImageBitmap?

Because `Sheet`s contain static images, it doesn't make sense for them to change after creation.
We freeze them:

        Object.freeze this

####  The prototype  ####

The `Sheet` prototype is fairly minimal, consisting of only two functions.

    Sheet.prototype =

The first, `drawIndex`, draws the sprite located at the given `index`.
It is little more than a repackaging of `drawSprite`.

        drawIndex: (context, index, x, y) -> drawSprite(this, index, context, x, y)

The second, `getSprite`, creates a new `Sprite` pointing to the given `index`.
It is the most convenient way of creating `Sprite` objects.
It takes two arguments, the `index` of the sprite, and the `length` of the animation.

        getSprite: (index, length = 1) -> new Sprite(this, index, length)

We can now freeze the prototype:

    Object.freeze Sheet.prototype

####  Final touches  ####

For convenience's sake, two static methods have been defined for `Sheet` to let you draw arbitrary sprites.
These are largely intended for use with callbacks.

The first is called `draw`, and takes five arguments:

- `context`: A `CanvasRenderingContext2D`
- `sprite`: A `Sprite`
- `x`: The x-coordinate at which to draw the sprite
- `y`: The y-coordinate at which to draw the sprite
- `frame`: The frame of the animation which to draw

It maps onto `sprite.draw`:

    Sheet.draw = (context, sprite, x, y, frame = 0) -> sprite.draw(context, x, y, frame) if sprite instanceof Sprite

The second is called `drawSheetAtIndex`, and also takes five arguments:

- `context`: A `CanvasRenderingContext2D`
- `sheet`: A `Sheet`
- `index`: The index of the sprite
- `x`: The x-coordinate at which to draw the sprite
- `y`: The y-coordinate at which to draw the sprite

It maps onto `sheet.drawIndex`:

    Sheet.drawSheetAtIndex = (context, sheet, index, x, y) -> sheet.drawIndex(context, index, x, y) if sheet instanceof Sheet

With those functions defined, we can add the `Sprite` constructor to `Sheet` for later access, and then make `Sheet` available to the window.
We go ahead and freeze both to keep them safe.

    Sheet.Sprite = Object.freeze(Sprite)
    @Sheet = Object.freeze(Sheet)

…And that's the end!
