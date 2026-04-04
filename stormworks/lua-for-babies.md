# Notes
A highly reccomended site to use for lua scripting is https://lua.flaffipony.rocks/ in stormworks build and rescue.

# Stormworks Lua Scripting Documentation

## LUA SCRIPTING OVERVIEW
Lua scripting gives you the tools to create advanced logic components using the Lua scripting language. Stormworks provides a number of functions to allow your script to interface with your vehicle's logic system, as well as drawing to in-game monitors.

This guide outlines the functions that are available for use in your scripts but it is not a comprehensive tutorial on using the Lua language.

---

## SCRIPT BASICS
The tick function will be called once every logic tick and should be used for reading composite data and any required processing. Screen functions will have no effect if called within `onTick`.

```lua
function onTick()
    -- Example that adds two composite channels together and outputs the result
    in1 = input.getNumber(1)
    in2 = input.getNumber(2)
    output.setNumber(1, in1 + in2)
end
```

The draw function will be called any time this script is drawn by a monitor. Note that it can be called multiple times if this microcontroller is connected to multiple monitors whereas `onTick` is only called once. Composite input/output functions will have no effect if called within `onDraw`.

```lua
function onDraw()
    -- Example that draws a red circle in the center of the screen with a radius of 20 pixels
    width = screen.getWidth()
    height = screen.getHeight()
    screen.setColor(255, 0, 0)
    screen.drawCircleF(width / 2, height / 2, 20)
end
```

---

## COMPOSITE INPUT/OUTPUT
Read values from the composite input. Index ranges from 1 - 32.
* `input.getBool(index)`
* `input.getNumber(index)`

Set values on the composite output. Index ranges from 1 - 32.
* `output.setBool(index, value)`
* `output.setNumber(index, value)`

---

## PROPERTIES
Read the values of property components within this microcontroller directly. The label passed to each function should match the label that has been set for the property you're trying to access (case-sensitive).
* `property.getNumber(label)`
* `property.getBool(label)`
* `property.getText(label)`

---

## DRAWING
Set the current draw color. Values range from 0 - 255.
* `screen.setColor(r, g, b)`
* `screen.setColor(r, g, b, a)`

Clear the screen with the current color.
* `screen.drawClear()`

Draw shapes and lines:
* `screen.drawLine(x1, y1, x2, y2)`
* `screen.drawCircle(x, y, radius)`
* `screen.drawCircleF(x, y, radius)`
* `screen.drawRect(x, y, width, height)`
* `screen.drawRectF(x, y, width, height)`
* `screen.drawTriangle(x1, y1, x2, y2, x3, y3)`

Text functions:
* `screen.drawText(x, y, text)` — Each character is 4 pixels wide and 5 pixels tall.
* `screen.drawTextBox(x, y, w, h, text, h_align, v_align)` — Text alignment ranges from -1 to 1. Text wraps automatically.

Map functions:
* `screen.drawMap(x, y, zoom)` — Zoom level ranges from 0.1 to 50.
* `screen.setMapColorOcean(r, g, b, a)`
* `screen.setMapColorShallows(r, g, b, a)`
* `screen.setMapColorLand(r, g, b, a)`
* `screen.setMapColorGrass(r, g, b, a)`
* `screen.setMapColorSand(r, g, b, a)`
* `screen.setMapColorSnow(r, g, b, a)`
* `screen.setMapColorRock(r, g, b, a)`
* `screen.setMapColorGravel(r, g, b, a)`

Get screen dimensions:
* `screen.getWidth()`
* `screen.getHeight()`

---

## MAP CONVERSION
Convert pixel coordinates into world coordinates.
* `worldX, worldY = map.screenToMap(mapX, mapY, zoom, screenW, screenH, pixelX, pixelY)`

Convert world coordinates into pixel coordinates.
* `pixelX, pixelY = map.mapToScreen(mapX, mapY, zoom, screenW, screenH, worldX, worldY)`

---

## TOUCHSCREEN DATA
The composite output from the monitors contains data that can be interpreted to create touchscreens.

**Number Channels:**
1. monitorResolutionX
2. monitorResolutionY
3. input1X
4. input1Y
5. input2X
6. input2Y

**On/Off Channels:**
1. isInput1Pressed
2. isInput2Pressed

**Example Touchscript:**
```lua
function onTick()
    -- Read the touchscreen data from the script's composite input
    inputX = input.getNumber(3)
    inputY = input.getNumber(4)
    isPressed = input.getBool(1)

    -- Check if the player is pressing the rectangle at (10, 10) with width and height of 20px
    isPressingRectangle = isPressed and isPointInRectangle(inputX, inputY, 10, 10, 20, 20)

    -- Set the composite output on/off channel 1
    output.setBool(1, isPressingRectangle)
end

function isPointInRectangle(x, y, rectX, rectY, rectW, rectH)
    return x > rectX and y > rectY and x < rectX+rectW and y < rectY+rectH
end

function onDraw()
    if isPressingRectangle then
        screen.drawRectF(10, 10, 20, 20)
    else
        screen.drawRect(10, 10, 20, 20)
    end
end
```

---

## LUA FUNCTIONS
The following global lua functions are available:
* `pairs`
* `ipairs`
* `next`
* `tostring`
* `tonumber`

Additional functions are available through the following libraries:
* `math`
* `table`
* `string`

*For full documentation visit [https://www.lua.org/manual/](https://www.lua.org/manual/).*

---

## TELEMETRY FUNCTIONS
The following global async functions are available:
* `httpGet`

HTTP requests are sent to the localhost on the specified port. Responses are caught with the `httpReply(port, request_body, response_body)` callback function.

`async.httpGet(port, request_body)`

**Example:**
```lua
-- Send a simple http request to port 80
async.httpGet(80, "/set_light_mode?index=1&mode=3")

-- This callback function automatically triggers when a reply is received
function httpReply(port, request_body, response_body)
    -- handle response here
end
```
