dataSub = null
Meteor.subscribe "metricPub"
Meteor.subscribe "countriesPub"
onResultsDataReady = -> Session.set "resultsDataReady", true
onCountDataReady = -> Session.set "countDataReady", true

Deps.autorun ->
    dataSub?.stop()
    Session.set "resultsDataReady", false
    Session.set "countDataReady", false
    
    emotion = Session.get "emotion"
    countryCode = Session.get "countryCode"
    if countryCode in countriesOverThreshold
        console.log "SUB", emotion, countryCode
        Meteor.subscribe "resultsPub", countryCode, emotion, onResultsDataReady
        Meteor.subscribe "voteCountsPub", countryCode, emotion, onCountDataReady
