global = exports ? this
global.bgraph = (options) ->
  chartTypes  =     ["c", "l"]
  data        =     []
  dataL       =     []
  maxArray    =     []
  minArray    =     []
  dates       =     []
  range       =     0
  type        =     "l"
  xtext       =     ""
  ytext       =     ""
  columnWidth =     0
  dataRange   =     0
  currPos     =     0
  X           =     0
  Y           =     0
  prefWidth   =     36
  validColor  =     /^#{1}(([a-fA-F0-9]){3}){1,2}$/
  color       =     "#000"

  {width, height, holder, leftgutter, topgutter, bottomgutter, gridColor} = options

  ### the following validation will work only when the value is a positive number.
    +undefined = NaN, +"hello" = NaN
    also NaN >= 0 is false and NaN < 0 is false too :)
    probably NaN is in 4th dimention...
  ###
  if not (+leftgutter >= 0) then leftgutter = 30
  if not (+topgutter >= 0) then topgutter = 20
  if not (+bottomgutter >= 0) then bottomgutter = 50
  if not validColor.test gridColor then gridColor = "#DFDFDF"

  if not width? then width = do ($ "#" + holder).width

  r = Raphael holder, width, height
  candelabra     =  do r.set
  yLabels        =  do r.set
  xlabels        =  []
  activeXLabels  = do r.set
  dots           = do r.set
  linepath = do r.path
  toString = ->
    "You are using Bgraph version 0.2."

  drawGrid = (x, y, w, h, wv, hv) ->
    gridPath = []
    rowHeight = h / hv
    columnWidth = w / wv

    xRound = Math.round x

    gridPath = gridPath.concat ["M", xRound + .5, Math.round(y + i * rowHeight) + .5, "H", Math.round(x + w) + .5] for i in [0..hv]
    gridPath = gridPath.concat ["M", Math.round(x + i * columnWidth) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5] for i in [0..wv]

    (r.path gridPath.join ",").attr stroke: gridColor

  drawLabels = (x, y, h, hv, yValues) ->
    txt2           =
      font         : '11px Helvetica, Arial'
      fill         : "#666"
      "text-anchor": "start"

    xRound = Math.round x
    rowHeight = h / hv

    for i in [0..hv]
      yStep = (yValues.endPoint - (i * yValues.step)).toFixed 2
      yLabel = r.text xRound, Math.round(y + i * rowHeight) + .5, yStep
      yLabels.push yLabel
      yWidth = yWidth || yLabel.getBBox().width
      txt2.x || txt2.x = xRound - yWidth - 8
      yLabel.attr(txt2).toBack()

  getYRange = (steps = 8, minOrig, maxOrig) ->
    dataYRange = maxOrig - minOrig
    tempStep = dataYRange / (steps - 2)
    if 0.1 < tempStep <= 1
      base = 0.1
    else if 1 < tempStep < 10
      base = 1
    else if  tempStep >= 10
      base = 10
    else
      return

    base = base / 2 while tempStep % base <= base / 2
    step = tempStep + base - tempStep % base
    stepRange = step * steps
    rangeGutter = stepRange - dataYRange - step
    startPoint = minOrig - rangeGutter + base - (minOrig - rangeGutter) % base
    endPoint = startPoint + stepRange

    {startPoint, endPoint,  step}

  getAnchors = (p1x, p1y, p2x, p2y, p3x, p3y) ->
    l1 = (p2x - p1x) / 2
    l2 = (p3x - p2x) / 2
    a = Math.atan((p2x - p1x) / Math.abs(p2y - p1y))
    b = Math.atan((p3x - p2x) / Math.abs(p2y - p3y))
    a = if p1y < p2y then Math.PI - a else a
    b = if p3y < p2y then Math.PI - b else b
    alpha = Math.PI / 2 - ((a + b) % (Math.PI * 2)) / 2
    dx1 = l1 * Math.sin alpha + a
    dy1 = l1 * Math.cos alpha + a
    dx2 = l2 * Math.sin alpha + b
    dy2 = l2 * Math.cos alpha + b

    x1: p2x - dx1
    y1: p2y + dy1
    x2: p2x + dx2
    y2: p2y + dy2

  drawCandlestick =  (dataItem, Y, x, y, color = "#000") ->
    o = +dataItem.o || 0
    h = +dataItem.h || 0
    l = +dataItem.l || 0
    c = +dataItem.c || 0
    if c > o then candleType = 1 else candleType = 0

    candleWidth = Math.round columnWidth / 2 - 4
    candleHeight = Math.round Y * (Math.abs c - o)
    if candleHeight is 0 then candleHeight = 1
    candle = r.set()

    stickPath = []
    stickPath = ["M", (Math.round x) + .5, (Math.round y) + .5, "V", Math.round y + (h - l) * Y]
    candle.push (r.path stickPath.join ",").attr stroke: color, "stroke-width": 1, "stroke-linejoin": "round"
    candleX = Math.round x - candleWidth / 2
    if candleType is 1
      candleY = Math.round y + (h-c) * Y
      candle.push (r.rect candleX + .5, candleY + .5, candleWidth, candleHeight).attr stroke: color, fill: "0-#ddd-#f9f9f9:50-#ddd", "stroke-linejoin": "round"
    else
      candleY = Math.round y + (h-o) * Y
      candle.push (r.rect candleX + .5, candleY + .5, candleWidth, candleHeight).attr stroke: color, fill: "0-#222-#555:50-#222", "stroke-linejoin": "round"
    candleMid: Math.round candleY + candleHeight / 2
    candle: candle

  redraw = ->
    label          =     do r.set
    label_visible  =     false
    leave_timer    =     0
    blanket        =     do r.set
    p              =     []
    txt            =
      font         : '12px Helvetica, Arial', "font-weight": "bold"
      fill         : color
    txt1           =
      font         : '10px Helvetica, Arial'
      fill         : "#666"
    txt2           =
      font         : '11px Helvetica, Arial'
      fill         : "#666"

    if typeof data[0] is "object"
      if type is "c"
        max = Math.max maxArray[currPos...currPos + range]...
        min = Math.min minArray[currPos...currPos + range]...
      else
        max = Math.max dataL[currPos...currPos + range]...
        min = Math.min dataL[currPos...currPos + range]...
    else if typeof data[0] is "number"
      # line chart uses dataL as a source. not data.
      dataL = data
      if currPos is 0
        max = Math.max dataL...
        min = Math.min dataL...
      else
        max = Math.max dataL[currPos...currPos + range]...
        min = Math.min dataL[currPos...currPos + range]...

    yRange = getYRange 8, min, max
    if yRange?
      max = yRange.endPoint
      min = yRange.startPoint
    else
      return

    Y = (height - bottomgutter - topgutter) / (max - min)
    # Before redraw, clear previous drawing
    do yLabels.remove
    do activeXLabels.remove
    if type is "c" then do candelabra.remove
    if type is "l"
      do linepath.remove
      do dots.remove
      linepath = do r.path
    drawLabels leftgutter + X * .5, topgutter + .5, height - topgutter - bottomgutter, 8, yRange

    if type is "l"
      linepath.attr stroke: color, "stroke-width": 3, "stroke-linejoin": "round"
      label.push (r.text 60, 12, max + " " + ytext).attr txt
      label.push (r.text 60, 27, xtext).attr(txt1)
      label.hide()
      frame = (r.popup 100, 100, label, "right").attr(fill: "#fff", stroke: color, "stroke-width": 1, "fill-opacity": 1).hide()

      for i in [currPos...currPos + range]
        y = height - bottomgutter - Y * (dataL[i] - min)
        x = Math.round leftgutter + X * (i - currPos + .5)

        p = ["M", x, y, "C", x, y] if i is currPos
        if i isnt currPos and i < currPos + range - 1
          Y0 = height - bottomgutter - Y * (dataL[i - 1] - min)
          X0 = Math.round leftgutter + X * (i - currPos - .5)
          Y2 = height - bottomgutter - Y * (dataL[i + 1] - min)
          X2 = Math.round leftgutter + X * (i - currPos + 1.5)
          a = getAnchors X0, Y0, x, y, X2, Y2
          p = p.concat [a.x1, a.y1, x, y, a.x2, a.y2]
        dot = r.circle(x, y, 4).attr fill: "#fff", stroke: color, "stroke-width": 2
        dots.push dot
        activeXLabels.push (r.text x, height - 25, xlabels[i]).attr(txt2).toBack().rotate 90
        blanket.push (r.rect leftgutter + X * (i - currPos), 0, X, height - bottomgutter).attr stroke: "none", fill: "#fff", opacity: 0
        rect = blanket[blanket.length - 1]
        ((x, y, data, lbl, dot) =>
          rect.hover =>
            clearTimeout leave_timer
            label[0].attr(text: data + " " + ytext)
            label[1].attr(text: lbl)
            side = "right"
            side = "left"  if x + frame.getBBox().width > width
            ppp = r.popup x, y, label, side, 1
            frame.show().stop().animate {path: ppp.path}, 200 * label_visible
            label.show().stop().animateWith frame, {translation: [ppp.dx, ppp.dy]}, 200 * label_visible

            dot.attr "r", 6
            label_visible = true
          ,=>
            dot.attr "r", 4
            leave_timer = setTimeout ->
                        frame.hide()
                        label.hide()
                        label_visible = false
                    ,   1
        ) x, y, dataL[i], xlabels[i], dot

      p = p.concat [x, y, x, y]
      linepath.attr path: p
      frame.toFront()
      label.toFront()
      blanket.toFront()
    else
      label.push (r.text 60, 12, max + " " + ytext).attr txt
      label.push (r.text 60, 27, xtext).attr(txt1)
      label.hide()
      frame = (r.popup 100, 100, label, "right").attr(fill: "#fff", stroke: "#000", "stroke-width": 1, "fill-opacity": 1).hide()

      for i in [currPos + 1...currPos + range + 1]
        y = height - bottomgutter - Y * (data[i - 1].h - min)
        x = Math.round leftgutter + X * (i - currPos + .5)
        activeXLabels.push (r.text x, height - 25, xlabels[i - 1]).attr(txt2).toBack().rotate 90
        candlestick = drawCandlestick data[i - 1], Y, x, y, color
        candleMid = candlestick.candleMid
        candelabra.push candlestick.candle
        blanket.push (r.rect leftgutter + X * (i - currPos), 0, X, height - bottomgutter).attr stroke: "none", fill: "#fff", opacity: 0
        candle = blanket[blanket.length - 1]
        ((x, y, data, lbl) =>
          candle.hover =>
            clearTimeout leave_timer
            label[0].attr(text: data.c + " " + ytext)
            label[1].attr(text: lbl)
            side = "right"
            side = "left"  if x + frame.getBBox().width > width - leftgutter
            ppp = r.popup x, y, label, side, 1
            frame.show().stop().animate {path: ppp.path}, 200 * label_visible
            label.show().stop().animateWith frame, {translation: [ppp.dx, ppp.dy]}, 200 * label_visible
            label_visible = true
          ,=>
            leave_timer = setTimeout ->
                        frame.hide()
                        label.hide()
                        label_visible = false
                    ,   1
        ) x, candleMid, data[i - 1], xlabels[i - 1]
      frame.toFront()
      label.toFront()
      blanket.toFront()
    true
  draw = (options) ->
    {color, data, xtext, ytext, type} = options
    rawDates = options.dates
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    if (_.indexOf chartTypes, type) is -1 then type = "l"

    if typeof data[0] is "object"
      if type is "c"
        maxArray = _.map data, (dataItem) -> +dataItem.h || 0
        minArray = _.map data, (dataItem) -> +dataItem.l || 0
      else
        # line chart uses dataL as a source. not data.
        dataL = _.map data, (dataItem) -> +dataItem.c || 0

    if not validColor.test color then color = "#000"
    # Accept dates as string and create date objects from it.
    dates = _.map rawDates, (rawDate) -> new Date(rawDate)
    dataRange = data.length
    # prefWidth is the width of column so that candles look good.
    range = Math.round (width - leftgutter)/prefWidth
    if range >= dataRange
      range = dataRange
    else
      currPos = dataRange - range

    gridRange = range
    # Create X-Axis labels from date array
    xlabels = _.map dates, (date) -> do date.getDate + "-" + months[do date.getMonth]

    # data can be plain numbers OR OHLC values.
    if typeof data[0] is "number" then type = "l"
    if type is "c" then gridRange = range + 2

    # Clear the canvas for drawing
    #do r.clear
    X = (width - leftgutter) / gridRange
    drawGrid leftgutter + X * .5, topgutter + .5, width - leftgutter - X, height - topgutter - bottomgutter, gridRange - 1, 8
    do redraw
  prev = (dx) ->
    if currPos is 0 then return
    if not (+dx >= 0) then dx = 1
    currPos = currPos - 1
    do redraw

  next = (dx) ->
    if currPos + range is data.length then return
    if not (+dx >= 0) then dx = 1
    currPos = currPos + 1
    do redraw

  {draw, prev, next, toString}

