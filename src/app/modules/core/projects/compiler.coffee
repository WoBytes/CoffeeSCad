define (require)->
  utils = require 'modules/core/utils/utils'
  merge = utils.merge
  
  PreProcessor = require "./preprocessor"
  CsgProcessor = require "./csg/processor"
  
  class Compiler
    
    constructor:(options)->
      defaults = {project:null, backgroundProcessing:false}
      options = merge defaults, options
      {@project, @backgroundProcessing} = options
      
      @preProcessor = new PreProcessor()
      @csgProcessor = new CsgProcessor()
      
      #this data structure is filled with log & error data 
      @compileResultData = {}
      @compileResultData["logEntries"] = null
      @compileResultData["errors"] = null
    
    compile:(options)=>
      defaults = {backgroundProcessing:false}
      options = merge defaults, options
      {@backgroundProcessing} = options
      
      @compileResultData["logEntries"] = []
      @compileResultData["errors"] = []
      
      console.log "compiling"
      @_compileStartTime = new Date().getTime()
      
      return @preProcessor.process(@project,false).pipe(@_processScript)
        .done () =>
          @project.trigger("compiled",@compileResultData)
          #TODO : should this be merged into the event above?
          #@project.trigger(log:messages
          #@project.trigger("log:messages",logEntries)
          return
        .fail (errors) =>
          @compileResultData["errors"] = errors
          @project.trigger("compile:error",@compileResultData)
      
    _processScript:(source)=>
      deferred = $.Deferred()
      
      if @project is null
        error = new Error("No project given to the compiler")
        deferred.reject(error)
      
      @csgProcessor.processScript source,@backgroundProcessing, (rootAssembly, partRegistry, logEntries, error)=>
        @compileResultData["logEntries"] = logEntries or []
        if error?
          deferred.reject([error])
        else          
          console.log "here"  
          #@_parseLogEntries(logEntries)
          
          @_generateBomEntries(rootAssembly, partRegistry)
          @project.rootAssembly = rootAssembly
          
          @_compileEndTime = new Date().getTime()
          console.log "Csg computation time: #{@_compileEndTime-@_compileStartTime}"
          deferred.resolve()
      return deferred
    
    _parseLogEntries:(logEntries)=>
      result = []
      return result
      
    _generateBomEntries:(rootAssembly, partRegistry)=>
      availableParts = new Backbone.Collection()
      for name,params of partRegistry
          for param, quantity of params
            variantName = "Default"
            if param != ""
              variantName=""
            @project.bom.add { name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true } 
      
      partInstances = new Backbone.Collection()
      
      parts = {}
      
      getChildrenData=(assembly) =>
        for index, part of assembly.children
          partClassName = part.__proto__.constructor.name
          if partClassName of partRegistry
            params = Object.keys(partRegistry[partClassName])[0]
            #params = partRegistry[partClassName][index]
            variantName = "Default"
            if params != ""
              variantName=""
            
            if not (partClassName of parts)
              parts[partClassName] = {}
              parts[partClassName][params] = 0
            parts[partClassName][params] += 1
          getChildrenData(part)
          
      getChildrenData(rootAssembly)
        
      for name,params of parts
        for param, quantity of params
          partInstances.add({ name: name,variant:variantName, params: param,quantity: quantity, manufactured:true, included:true })
        
      @project.bom = partInstances
      
      
  return  Compiler