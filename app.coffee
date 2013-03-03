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
      Sample.findOneAndUpdate id: sample.id, sample, upsert: true, (err, sample) ->
        console.log sample
        request sample.location.standard, (err, res, points) ->
          # We need to chop the first 5 and last 3 characters
          points = JSON.parse points.substring(5, points.length-3)
          points = [[parseInt(p[0]), parseFloat(p[1])] for p in points]
          points.sort (a, b) ->
            a[0] - b[0]
          console.log points
          sample.points = points
          sample.save (err) ->
            console.log "Done! id=#{sample.id}"

  @get '/': ->
    @response.redirect '/home'

  @get '/home': ->
    md = require('node-markdown').Markdown
    fs.readFile 'README.md', 'utf-8', (err, data) =>
      @render 'markdown.jade', {md: md, markdownContent: data, title: manifest.name, id: 'home', brand: manifest.name}

  @get '/source': ->
    @response.redirect manifest.source

  @post '/import': ->
    request @body.url, (err, res, samples) =>
      samples = JSON.parse samples
      for sample in samples
        @add_sample sample
      @response.json samples

  @get '/samples': ->
    Sample.find {}, {id:true, _id:false}, (err, samples) =>
      @response.write console.log "Error retrieving sample ids:", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json samples unless err?

  @get '/sample/:id': ->
    Sample.findOne {id: @params.id}, {points: false}, (err, sample) =>
      @response.write console.log "Error retrieving sample id #{@params.id}", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json sample unless err?

  @get '/points/:id/:start/:end': ->
    Sample.findOne {id: @params.id}, 'points', (err, sample) =>
      @response.write console.log "Error retrieving points for sample id #{@params.id}", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json sample.points.slice(@params.start, @params.end) unless err?

  @get '/points/:id': ->
    Sample.findOne {id: @params.id}, 'points', (err, sample) =>
      @response.write console.log "Error retrieving points for sample id #{@params.id}", err if err?
      @response.header "Access-Control-Allow-Origin", "*"
      @response.json sample.points unless err?
