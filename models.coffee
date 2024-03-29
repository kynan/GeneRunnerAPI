mongoose = require 'mongoose'

InteractionSchema = new mongoose.Schema
  sampleId: mongoose.Schema.Types.ObjectId
  c:
    x: Number
    y: Number
  e:
    x: Number
    y: Number

# Sample:
#{
#    "activated_at": "2013-02-19T04:14:32Z",
#    "classification_count": 0,
#    "created_at": "2013-02-19T04:10:25Z",
#    "id": "5122fb31390c050da1000025",
#    "location": {
#        "standard": "http://www.generunner.net.s3.amazonaws.com/data/MB-0022_rawData_section_14.jsonp"
#    },
#    "metadata": {
#        "origName": "MB-0022"
#    },
#    "project_id": "5122f90e390c050da1000001",
#    "random": 0.30619183313240217,
#    "state": "active",
#    "updated_at": "2013-02-19T04:10:25Z",
#    "workflow_ids": [
#        "5122f96f390c050da1000002"
#    ],
#    "zooniverse_id": "ACG000000f"
#}

SampleSchema = new mongoose.Schema
  activated_at: { type: Date, default: Date.now }
  created_at: { type: Date, default: Date.now }
  updated_at: { type: Date, default: Date.now }
  classification_count: Number
  location:
    standard: String
  metadata:
    origName: String
  project_id: String
  random: Number
  state: String
  workflow_ids: [String]
  zooniverse_id: String
  points: []
  num_points: Number
  x:
    min: Number
    max: Number
  y:
    min: Number
    max: Number

module.exports.sample = mongoose.model 'Sample', SampleSchema
module.exports.interaction = mongoose.model 'Interaction', InteractionSchema
