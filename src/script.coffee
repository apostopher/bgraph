jQuery ->
  scrips = []
  getScrips = (defaultScrip) ->
    $.ajax
      type: "GET"
      url: "/serverscripts/getScrips.php"
      dataType: "json"
      success: (response) ->
        scrips = response.scrips
        scripList = ($ "#searchterm").autocomplete
          minLength: 3
          delay: 100
          source: (req, res) ->
            srchExp = new RegExp "^" + req.term + ".*", "i"
            matches = []
            for scrip in scrips
              if (scrip.value.search srchExp) >= 0 or (scrip.label.search srchExp) >= 0
                matches.push scrip
            res matches

          focus: (event, ui) ->
            ($ "#searchterm").val ui.item.value
            false
          select: (event, ui) ->
            ($ "#searchterm").val ui.item.value
            false
        scripList.data("autocomplete")._renderItem = ( ul, item ) ->
          ($ "<li></li>").data("item.autocomplete", item).append("<a>" + item.label + "<br><span class=\"ui-item-symbol\">" + item.value + "</span></a>").appendTo ul

        if defaultScrip? then getCandles defaultScrip

  getCandles = (scrip) ->
    configfiidii = holder: "chartholder", height: 550
    fiidiigraph = bgraph configfiidii
    $.ajax
      type: "GET"
      url: "/serverscripts/candles.php"
      data: {scrip: scrip}
      dataType: "json"
      beforeSend: ->
        fiidiigraph.setMessage "Loading " + scrip
      success: (response) ->
        dates   =   []
        data    =   []
        for own key, val of response.data
          dates.unshift val.date
          data.unshift  o: +val.o, h: +val.h, l: +val.l, c: +val.c

        fiidiioptions =
          data      :  data
          dates     :  dates
          xtext     :  "dates"
          ytext     :  "Rs."
          type      :  "c"
          color     :  "#db2129"

        if fiidiigraph.draw fiidiioptions
          scripName = ""
          for scripObj in scrips
            if scripObj.value is do scrip.toUpperCase
              scripName = scripObj.label

          ($ "#scripname").html scripName
          ($ document).keydown (e) ->
            if e.keyCode is 37
              do fiidiigraph.prev
              return false

            if e.keyCode is 39
              do fiidiigraph.next
              return false
            return true

          ($ window).resize ->
            do fiidiigraph.reSize
        else
          ($ "#scripname").html ""

        true
      failure: (response) ->
    true
  submitFrm = ->
    scripSymbol = do ($ "#searchterm").val
    if scripSymbol
      getCandles scripSymbol
    true

  ($ "#searchbtn").click submitFrm
  ($ '#searchterm').keydown (event) ->
    if event.keyCode is 13
      do submitFrm

  getScrips "NIFTY"

