Bgraph = (options) ->
  data        =     []
  xlabels     =     []
  range       =     0
  type        =     "l"
  columnWidth =     0
  validColor  =     /^#{1}(([a-fA-F0-9]){3}){1,2}$/

  {width, height, holder, leftgutter, topgutter, bottomgutter, gridColor} = options

  if not (+leftgutter >= 0) then leftgutter = 30
  if not (+topgutter >= 0) then topgutter = 20
  if not (+bottomgutter >= 0) then bottomgutter = 50
  if not validColor.test gridColor then gridColor = "#DFDFDF"

  r = Raphael holder, width, height

  toString = ->
    "You are using Bgraph version 0.1."

  drawGrid = (x, y, w, h, wv, hv, yValues) ->
    path = []
    rowHeight = h / hv
    columnWidth = w / wv

    xRound = Math.round x
    txt2           =
      font         : '11px Helvetica, Arial'
      fill         : "#666"
      "text-anchor": "start"

    for i in [0..hv]
      yStep = (yValues.endPoint - (i * yValues.step)).toFixed 1
      yLabel = r.text xRound, Math.round(y + i * rowHeight) + .5, yStep
      yWidth = yWidth || yLabel.getBBox().width
      txt2.x || txt2.x = xRound - yWidth - 8
      yLabel.attr(txt2).toBack()
      path = path.concat ["M", xRound + .5, Math.round(y + i * rowHeight) + .5, "H", Math.round(x + w) + .5]

    path = path.concat ["M", Math.round(x + i * columnWidth) + .5, Math.round(y) + .5, "V", Math.round(y + h) + .5] for i in [0..wv]
    (r.path path.join ",").attr stroke: gridColor

  getYRange = (steps = 8) ->
    stepOffset = 2
    if typeof data[0] is "object"
      if type is "c"
        maxArray = _.map data, (dataItem) -> +dataItem.h || 0
        minArray = _.map data, (dataItem) -> +dataItem.l || 0
        max = Math.max maxArray...
        min = Math.min minArray...
        stepOffset = 0
      else
        closeArray = _.map data, (dataItem) -> +dataItem.c || 0
        max = Math.max closeArray...
        min = Math.min closeArray...
    else
      max = Math.max data...
      min = Math.min data...

    datarange = max - min
    tempStep = datarange / (steps - stepOffset)
    if 0.1 < tempStep <= 1
      base = 0.1
    else if 1 < tempStep < 10
      base = 1
    else if  tempStep >= 10
      base = 10
    else
      return

    step = tempStep + base - tempStep % base
    stepRange = step * steps
    rangeGutter = stepRange - datarange - step * stepOffset / 2
    startPoint = min - rangeGutter + base - (min - rangeGutter) % base
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
    candle = r.set()

    stickPath = []
    stickPath = ["M", (Math.round x) + .5, (Math.round y) + .5, "V", Math.round y + (h - l) * Y]
    candle.push (r.path stickPath.join ",").attr stroke: color, "stroke-width": 1, "stroke-linejoin": "round"
    candleX = Math.round x - candleWidth / 2
    if candleType is 1
      candleY = Math.round y + (h-c) * Y
      candle.push (r.rect candleX + .5, candleY + .5, candleWidth, candleHeight).attr stroke: color, fill: "0-#ddd-#fff:50-#ddd", "stroke-linejoin": "round"
    else
      candleY = Math.round y + (h-o) * Y
      candle.push (r.rect candleX + .5, candleY + .5, candleWidth, candleHeight).attr stroke: color, fill: "0-#222-#555:50-#222", "stroke-linejoin": "round"
    true

  draw = (options) ->
    {color, data, xlabels, xtext, ytext, type} = options
    if not validColor.test color then color = "#000"

    range = gridRange = xlabels.length
    if typeof data[0] is "object"
      if type is "c"
        gridRange = range + 2
        xStart = 1
      else
        type = "l"
        xStart = 0
        data = _.map data, (dataItem) -> +dataItem.c || 0
    else if typeof data[0] is "number"
      type = "l"
      xStart = 0

    label          =     r.set()
    label_visible  =     false
    leave_timer    =     0
    blanket        =     r.set()
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

    X = (width - leftgutter) / gridRange

    yRange = getYRange()
    if yRange?
      max = yRange.endPoint
      min = yRange.startPoint
    else
      return

    label.push (r.text 60, 12, max + " " + ytext).attr txt
    label.push (r.text 60, 27, xtext).attr(txt1)
    label.hide()

    frame = (r.popup 100, 100, label, "right").attr(fill: "#fff", stroke: color, "stroke-width": 2, "fill-opacity": 1).hide()

    Y = (height - bottomgutter - topgutter) / (max - min)

    drawGrid leftgutter + X * .5, topgutter + .5, width - leftgutter - X, height - topgutter - bottomgutter, gridRange - 1, 8, yRange

    path = r.path().attr stroke: color, "stroke-width": 3, "stroke-linejoin": "round"

    if type is "l"
      for i in [0...range]
        y = height - bottomgutter - Y * (data[i] - min)
        x = Math.round leftgutter + X * (i + .5)

        p = ["M", x, y, "C", x, y] if not i
        if i and i < range - 1
          Y0 = height - bottomgutter - Y * (data[i - 1] - min)
          X0 = Math.round leftgutter + X * (i - .5)
          Y2 = height - bottomgutter - Y * (data[i + 1] - min)
          X2 = Math.round leftgutter + X * (i + 1.5)
          a = getAnchors X0, Y0, x, y, X2, Y2
          p = p.concat [a.x1, a.y1, x, y, a.x2, a.y2]
        dot = r.circle(x, y, 4).attr fill: "#fff", stroke: color, "stroke-width": 2
        (r.text x, height - 25, xlabels[i]).attr(txt2).toBack().rotate 90
        blanket.push (r.rect leftgutter + X * i, 0, X, height - bottomgutter).attr stroke: "none", fill: "#fff", opacity: 0
        rect = blanket[blanket.length - 1]
        ((x, y, data, lbl, dot) =>
          rect.hover =>
            clearTimeout leave_timer
            side = "right"
            side = "left"  if x + frame.getBBox().width > width
            label[0].attr(text: data + " " + ytext)
            label[1].attr(text: lbl)
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
        ) x, y, data[i], xlabels[i], dot

      p = p.concat [x, y, x, y]
      path.attr path: p
      frame.toFront()
      label[0].toFront()
      label[1].toFront()
      blanket.toFront()
    else
      for i in [1...range + 1]
        y = height - bottomgutter - Y * (data[i - 1].h - min)
        x = Math.round leftgutter + X * (i + .5)
        drawCandlestick data[i - 1], Y, x, y, color
        (r.text x, height - 25, xlabels[i - 1]).attr(txt2).toBack().rotate 90
  draw: draw, toString: toString

jQuery ->
  $.ajax
    type: "GET"
    url: "/serverscripts/candleTCS.php"
    dataType: "json"
    success: (response) ->
      dates   =   []
      data    =   []
      for own key, val of response.data
        if key < 24
          dates.unshift val.date
          data.unshift  o: +val.o, h: +val.h, l: +val.l, c: +val.c
        else
          break

      configfiidii = holder: "fiidiiholder", width: 892, height: 550

      fiidiigraph = Bgraph configfiidii

      fiidiioptions =
        # color: "#586C72"
        #color     :  "#B22222"
        data      :  data
        xlabels   :  dates
        xtext     :  "dates"
        ytext     :  "Rs."
        type      :  "c"

      fiidiigraph.draw(fiidiioptions)
      true
    failure: (response) ->

