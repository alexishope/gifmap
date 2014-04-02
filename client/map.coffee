@getRandomFromArray = (arr) -> arr[Math.floor(arr.length * Math.random())]
@emotions = ["amusement", "anger", "contempt", "disgust", "embarrassment", "excitement", "fear", "happiness", "pleasure", "relief", "sadness", "satisfaction", "shame", "surprise", "pride", "guilt", "contentment"]
@countriesOverThreshold = ['AU', 'DE', 'GB', 'SE', 'FR', 'US', 'PL', 'CA', 'BR', 'CH', 'ES', 'RU', 'HU', 'NO', 'NL', 'PT', 'DK', 'MX', 'AT', 'IT', 'BE']

Handlebars.registerHelper "dataReady", -> (Session.get("resultsDataReady") and Session.get("countDataReady"))

Meteor.startup ->
  Session.setDefault("hover", false)
  throttledResize = _.throttle(->
    if Session.get("mobile") or window.outerWidth > 1024
      console.log "RESIZING"
      Session.set "resize", new Date()
  , 50)
  $(window).resize throttledResize
  Session.set "emotion", getRandomFromArray(emotions)

Template.emotions.metrics = -> Questions.find()

Template.map.resize = -> if Session.get "resize" then return

Template.map_info_box.helpers
  hover: -> Session.get "hover"
  countryName: -> Session.get "countryName"
  numVotes: -> VoteCounts.findOne().count
  emotion: -> Session.get "emotion"
  topGifs: -> Results.find()

Template.metric.selected = -> if Session.equals("emotion", @metric) then " selected"

Template.metric.events =
  # TODO: Handle selection in a smarter, more Meteoric way 
  "click li.metric": (d) ->
    srcE = if d.srcElement then d.srcElement else d.target
    $("li.metric").removeClass("selected")
    $(srcE).addClass("selected")
    emotion = $(srcE).data "emotion"
    Session.set "emotion", emotion
    Session.set "skip", 0

mouseover = (d) ->
  countryCode3 = d.id
  countryCursor = Countries.findOne(countryCode3: countryCode3)
  countryName = countryCursor.countryName
  countryCode2 = countryCursor.countryCode
  if countryCode2 in countriesOverThreshold
    Session.set "hover", true
    Session.set "countryName", countryName
    Session.set "countryCode", countryCode2
  
    # change outline of selected country on mouseover
    d3.select(@parentNode.appendChild(this)).transition().duration(200).style
      "fill": "#00bfff"
      "stroke-opacity": 1
      "stroke-width":1.5
      stroke: "#222"

mouseout = (d) ->
  # Session.set "hover", false
  countryCode = Countries.findOne(countryCode3: d.id)?.countryCode
  color = if countryCode and countryCode in countriesOverThreshold then "#FFF" else "#222"

  # remove the outline on mouseout
  d3.select(@parentNode.appendChild(this)).transition().duration(200).style
    "fill": color
    "stroke-opacity": 0.4
    stroke: "#eee"
    "stroke-width": 0.5

# TODO optional: un-highlight country
get_range_log = (data, num_buckets) ->
  min = d3.min(data, (c) ->
    c.count
  )
  max = d3.max(data, (c) ->
    c.count
  )
  base = max / min
  range = [min]
  i = 1

  while i < num_buckets
    range.push min * Math.pow(base, i / num_buckets)
    i++
  range.push max
  range

Template.map.dataReady = ->
  Session.get "dataReady"

mapProps =
  width: 700
  height: 560
  margin:
    top: 100
    right: 10
    bottom: 10
    left: 10

Template.map_svg.properties = mapProps
color_gradient = ["#f2ecb4", "#f2e671", "#f6d626", "#f9b344", "#eb8c30", "#e84d24"]

Template.map_svg.rendered = ->
  vars =
    svg_height : $("body").height()
    svg_width : $("body").width()

  mobile = Session.get("mobile")
  background = d3.select(@firstNode)
      .attr("width", vars.svg_width)
      .attr("height", vars.svg_height)
    .append("svg:g")
      .attr("id", "background")
    .append("rect")
      .attr("width", vars.svg_width)
      .attr("height", vars.svg_height)
      .attr("fill", "#000000")
      .attr("fill-opacity", 1.0)

  svg = d3.select(@firstNode)
      .attr("width", vars.svg_width)
      .attr("height", vars.svg_height)
    .append("svg:g")
      .attr("id", "countries")
  map_projection = d3.geo.equirectangular()
      .scale(vars.svg_width * 0.14)
      .translate([vars.svg_width / 2, vars.svg_height / 2])

  svg.selectAll("path").data(d3.values(mapData.features)).enter().append("path").attr("id", (d, i) -> d.id)
  .attr("stroke", (d) ->
    countryCode = Countries.findOne(countryCode3: d.id)?.countryCode
    if countryCode and countryCode in countriesOverThreshold then "#222" else "#FFF")
  .attr("stroke-width", 0.5).attr "d", d3.geo.path().projection(map_projection)

  scalewidth = $(".page-middle").width()
  colorScale = d3.select(@find("svg.color-scale")).attr("width", scalewidth).attr("height", "30px").append("g")

  svg.selectAll("path").attr("fill", (d) -> 
    countryCode = Countries.findOne(countryCode3: d.id)?.countryCode
    if countryCode and countryCode in countriesOverThreshold then "#FFF" else "#222"
  ).on("mouseover", mouseover)
  .on("mouseout", mouseout)
  .on("touchstart", "mouseover")
  .on("touchend", "mouseout")
  d3.select(".key").selectAll("text").text (d, i) ->
    value_range_big[i].toFixed 0
  # make the treemap zoomable using d3.behavior.zoom()
  zoom = d3.behavior.zoom()
  .scaleExtent([1, 5])
  .on("zoom", ->
      svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")")
    )
  svg.call(zoom)

mouseoverCell = null
