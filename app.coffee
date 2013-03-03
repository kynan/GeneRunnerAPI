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
      request sample.location.standard, (err, res, points) =>
        # We need to chop the first 5 and last 3 characters
        points = JSON.parse points.substring(5, points.length-3)
        @add_points sample, points
    add_points: (sample, points) ->
      points = points.map (p) -> [parseInt(p[0]), parseFloat(p[1])]
      points.sort (a, b) ->
        a[0] - b[0]
      sample.num_point = points.length
      sample.x = {min: points[0][0], max: points[points.length-1][0]}
      sample.y =
        min: Math.min.apply(null, points.map (p) -> p[1])
        max: Math.max.apply(null, points.map (p) -> p[1])
      yrange = sample.y.max - sample.y.min
      sample.points = points.map (p) -> [p[0], (p[1] - sample.y.min)/yrange]
      sample.save (err, newsample) ->
        if err
          console.log "Importing points for sample #{sample.id} failed:", err
          Sample.findByIdAndRemove sample.id, (err) ->
            console.log "Removing sample #{sample.id} failed:", err if err?
            console.log "Removed sample #{sample.id}" unless err?
        console.log "Done! Imported #{points.length} points for sampleId #{newsample.id}" unless err?

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

  @post '/import/points': ->
    if @body.id
      Sample.findById @body.id, (err, sample) =>
        @response.json err if err?
        @response.json "No location found for sample id #{sample.id}" unless sample.location?.standard?
        @add_sample sample
        @response.json "Importing points for sample id #{sample.id}"
    else if @body?.length > 0
      Sample.create {}, (err, sample) =>
        @add_points sample, @body
        @response.json "Importing points for sample id #{sample.id}"
    else
      Sample.find {}, {points: false}, (err, samples) =>
        @response.json err if err?
        @add_sample sample for sample in samples when sample.location?.standard?
        @response.json "Importing points for sample ids #{s.id for s in samples when s.location?.standard?}"

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
