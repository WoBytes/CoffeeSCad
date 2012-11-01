define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
  #project is a top level element
  #a project contains files
  #a project can reference another project (includes?)
  #a library contains multiple projects
  
  
  #TODO: add support for multiple types of storage, settable per project
  #syncType = Backbone.LocalStorage
  
  class ProjectFile extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "mainPart"
      ext:      "coscad"
      content:  ""

    constructor:(options)->
      super options
      @rendered = false
      @dirty    = false
      @bind("change", ()=> @dirty=true)
      @bind("sync",   ()=> @dirty=false)#when save is sucessfull
    
      
  class ProjectFiles extends Backbone.Collection
    model: ProjectFile
  
  class Project extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "TestProject"
    
    constructor:(options)->
      super options
      @new    = true
      @bind("reset", @onReset)
      @bind("sync",  @onSync)
      
      @files = []
      @pfiles = new ProjectFiles()
      locStorName = @get("name")+"-parts"
      @pfiles.localStorage= new Backbone.LocalStorage(locStorName)
      
      
    onReset:()->
      console.log "Project model reset" 
      console.log @
      console.log "_____________"
    
    onSync:()->
      @new = false
      console.log "Project sync" 
      console.log @
      console.log "_____________"
      #locStorName = "Library-"+@id+"-parts"
      #@pfiles.localStorage= new Backbone.LocalStorage(locStorName)
      #@collection.bli()
      
    isNew2:()->
      return @new 
      
    add:(pFile)=>
      @pfiles.add pFile
      @files.push pFile.get("name")
    
    remove:(pFile)=>
      index = @files.indexOf(pFile.get("name"))
      @files.splice(index, 1) 
      @pfiles.remove(pFile)
    
    fetch_file:(options)=>
      id = options.id
      console.log "id specified: #{id}"
      if @pfiles.get(id)
        pFile = @pfiles.get(id)
      else
        pFile = new ProjectFile({name:id})
        pFile.collection = @pfiles
        pFile.fetch()
      return pFile
      
    export:(format)->
      

      
  class Library extends Backbone.Collection   
    model: Project
    localStorage: new Backbone.LocalStorage("Library")
    defaults:
      recentProjects: []
    
    constructor:(options)->
      super options
      @bind("reset", @onReset)
      
      @namesFetch = false
    
    bli:()=>
      console.log("calling bli")
    
    save:()=>
      @each (model)-> 
        model.save()
    
    fetch:(options)=>
      console.log "collection"
      console.log @
      if options?
        console.log "options" 
        console.log options
        if options.id?
          id = options.id
          #console.log "id specified"
          proj=null
          if @get(id)
            console.log("found")
            proj = @get(id)
          #else
          #  proj = new Project({name:id})
          #  proj.collection = @
          #  proj.fetch()
          return proj
        else
          #console.log "NO id specified"
          res= Library.__super__.fetch.apply(this, options)
          return res
      else
          #console.log "NO id specified2"
          res = super(options)
          return res
        
    parse: (response)=>
      #console.log("in lib parse")
      for i, v of response
        response[i].pfiles = new ProjectFiles(response[i].pfiles)
      return response
      
    getLatest:()->
      @namesFetch = true
      
    onReset:()->
      #if @models.length == 0
      #  @save()
      
      console.log "Library collection reset" 
      console.log @
      console.log "_____________"
      
  return {ProjectFile,Project,Library}
