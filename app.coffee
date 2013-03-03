port = process.env.PORT || 3000
host = process.env.HOST || "0.0.0.0"
request = require 'request'

require('zappajs') host, port, ->
  manifest = require './package.json'
  fs = require 'fs'
  mongoose = require 'mongoose'

  Sample = require('./models').sample

  @configure =>
    @use 'cookieParser',
      'bodyParser',
      'methodOverride',
      'session': secret: 'shhhhhhhhhhhhhh!',
      @app.router,
      'static'
    @set 'view engine', 'jade'

  @configure
    development: =>
      mongoose.connect "mongodb://#{host}/#{manifest.name}-dev"
      @use errorHandler: {dumpExceptions: on, showStack: on}
    production: =>
      mongoose.connect process.env.MONGOHQ_URL || "mongodb://#{host}/#{manifest.name}"
      @use 'errorHandler'

  @helper
    add_sample: (sample) ->
      Sample.findByIdAndUpdate sample.id, sample, upsert: true, (err, sample) ->
        request sample.location.standard, (err, res, points) ->
          # We need to chop the first 5 and last 3 characters
          points = JSON.parse points.substring(5, points.length-3)
          points = points.map (p) -> [parseInt(p[0]), parseFloat(p[1])]
          points.sort (a, b) ->
            a[0] - b[0]
          sample.num_point = points.length
          sample.x = {min: points[0][0], max: points[points.length-1][0]}
          sample.y =
            min: Math.min.apply(null, points.map (p) -> p[1])
            max: Math.max.apply(null, points.map (p) -> p[1])
          console.log sample
          sample.points = points
          sample.save (err, sample) ->
            console.log err if err?
            console.log "Done! Imported #{points.length} points for sampleId #{sample.id}" unless err?

  @get '/': ->
    @response.redirect '/home'

  @get '/home': ->
    md = require('node-markdown').Markdown
    fs.readFile 'README.md', 'utf-8', (err, data) =>
      @render 'markdown.jade', {md: md, markdownContent: data, title: manifest.name, id: 'home', brand: manifest.name}

  @get '/source': ->
    @response.redirect manifest.source

  @post '/import/samples': ->
    request @body.url, (err, res, samples) =>
      samples = JSON.parse samples
      for sample in samples
        Sample.findByIdAndUpdate sample.id, sample, upsert: true, (err, sample) =>
          console.log "Added sample id #{sample.id}"
          @response.json err if err?
          @response.json samples unless err?

  @get '/samples': ->
    Sample.find {}, {id:true}, (err, samples) =>
      @response.write console.log "Error retrieving sample ids:", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json samples.map (s) -> s._id unless err?

  @get '/samples/:id': ->
    Sample.findById @params.id, {points: false}, (err, sample) =>
      @response.write console.log "Error retrieving sample id #{@params.id}", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json sample unless err?

  @get '/points/:id/:start/:end': ->
    Sample.findById @params.id, 'points', (err, sample) =>
      @response.write console.log "Error retrieving points for sample id #{@params.id}", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json sample.points.slice(@params.start, @params.end) unless err?

  @get '/points/:id': ->
    Sample.findById @params.id, 'points', (err, sample) =>
      @response.write console.log "Error retrieving points for sample id #{@params.id}", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json sample.points unless err?
