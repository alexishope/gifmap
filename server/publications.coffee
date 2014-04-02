Scores._ensureIndex(scores: 1)

Meteor.publish "metricPub", ->
    Questions.find({}, {sort: {metric: 1}})

Meteor.publish "countriesPub", ->
    Countries.find()

Meteor.publish "voteCountsPub", (country, emotion) ->
    sub = this
    collectionName = "voteCounts"
    count = Votes.find(country: country, metric: emotion).count()
    sub.added collectionName, Random.id(), {count: count}
    sub.ready()
    return

Meteor.publish "resultsPub", (country, emotion) ->
    sub = this
    collectionName = "results"

    # With new document schema
    # Uses last element when sorting on field of embedded document (e.g. scores.amusement)
    sortingNum = -1
    sortObject = {}
    sortObject['scores.' + country + '.' + emotion] = sortingNum

    topTenScores = Scores.find({}, { fields: { image_id: 1, scores: 1}, sort: sortObject, limit: 5}).fetch()
    topTenScores = _.sortBy(topTenScores, (gif) -> sortingNum * gif.scores?[country]?[emotion])

    index = 0
    _.each(topTenScores, (s) ->
        index += 1
        if s.scores?[country]?[emotion]
            image_id = new Meteor.Collection.ObjectID(s.image_id)
            gif = Gifs.findOne({_id: image_id}, {fields: {_id: 1, file_id: 1, still_image: 1, embedLink: 1}})
            gif.score = Number((s.scores[country][emotion] / 50).toFixed(3))
            gif.resultNum = index
            sub.added collectionName, gif._id, gif
        )

    sub.ready()
    return