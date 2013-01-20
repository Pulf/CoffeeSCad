define (require)->
  $ = require 'jquery'
  _ = require 'underscore'
  Backbone = require 'backbone'
  LocalStorage = require 'localstorage'
 
  CsgProcessor = require "./csg/csg.processor"
  debug  = false
  #TODO: add support for multiple types of storage, settable per project
  #syncType = Backbone.LocalStorage
  
  class ProjectFile extends Backbone.Model
    idAttribute: 'name'
    defaults:
      name:     "mainFile"
      ext:      "coscad"
      content:  ""
           
    constructor:(options)->
      super options
      @rendered = false
      @dirty    = false
      @storedContent = @get("content") #This is used for "dirtyness compare" , might be optimisable (storage vs time , hash vs direct compare)
      @bind("change", @onChanged)
      @bind("sync",   @onSynched)
    
    onChanged:()=>
      if @storedContent == @get("content")
          @dirty = false
      else
          @dirty = true
      if @dirty
        @trigger "dirtied"
      else
        @trigger "cleaned"
    
    onSynched:()=>
      #when save is sucessfull
      console.log "synching"
      @storedContent = @get("content")
      @dirty=false
      @trigger "saved"
      
  class ProjectFiles extends Backbone.Collection
    model: ProjectFile
    #localStorage: new Backbone.LocalStorage("_")
    ###
    parse: (response)=>
      console.log("in projFiles parse")
      for i, v of response
        response[i] = new ProjectFile(v)
        response[i].collection = @
        
      console.log response      
      return response  
    ###
   
  class Project extends Backbone.Model
    """Main aspect of coffeescad : contains all the files
    * project is a top level element ("folder"+metadata)
    * a project contains files 
    * a project can reference another project (includes)
    """
    
    idAttribute: 'name'
    defaults:
      name:     "TestProject"
      lastModificationDate: null
    
    constructor:(options)->
      super options
      @dirty    = false #based on propagation from project files : if a project file is changed, the project is tagged as "dirty" aswell
      @new      = true
      @bind("reset", @onReset)
      @bind("sync",  @onSync)
      @bind("change",@onChanged)
      @files = []
      @pfiles = new ProjectFiles()
      
      classRegistry={}
      @bom = new Backbone.Collection()
      @rootAssembly = {}
      
      locStorName = @get("name")+"-files"
      @pfiles.localStorage= new Backbone.LocalStorage(locStorName)
      storageType = "localStorage"#can be localStorage, dropbox, github
      
    compile:()=>
      #experimental
      @csgProcessor = new CsgProcessor()
      console.log "compiling project"
      #for now just limit to one file
      script = @pfiles.at(0).get("content")
      #console.log "current script : #{script}"
      res = @csgProcessor.processScript2(script,true)
      #@set({"partRegistry":window.classRegistry}, {silent: true})
      partRegistry = window.classRegistry
        
      @bom = new Backbone.Collection()
      for name,params of partRegistry
        for param, quantity of params
          variantName = "Default"
          if param != ""
            variantName=""
          @bom.add { name: name,variant:variantName, params: param,quantity: quantity, included:true } 
      
      @rootAssembly = res
           
      res
      
    onReset:()->
      if debug
        console.log "Project model reset" 
        console.log @
        console.log "_____________"
    
    onSync:()->
      @new = false
      if debug
        console.log "Project sync" 
        console.log @
        console.log "_____________"
      
    onChanged:(settings, value)->
      @dirty=true
      for key, val of @changedAttributes()
        switch key
          when "name"
            locStorName = val+"-files"
            @pfiles.localStorage= new Backbone.LocalStorage(locStorName)
            
    onFileSaved:(fileName)=>
      @set("lastModificationDate",new Date())
      for file of @pfiles
        if file.dirty
          return
      @trigger "allSaved"
      
    onFileChanged:(fileName)=>
      @trigger "change"
      
    isNew2:()->
      return @new 
      
    add:(pFile)=>
      @pfiles.add pFile
      @files.push pFile.get("name")
      pFile.bind("change", ()=> @onFileChanged(pFile.get("id")))
      pFile.bind("saved" , ()=> @onFileSaved(pFile.get("id")))
      pFile.bind("dirtied", ()=> @trigger "dirtied")
      pFile.bind("cleaned", ()=> @onFileSaved(pFile.get("id")))
    
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
      
    createFile:(options)->
      file = new ProjectFile
        name: options.name ? "a File"
        content: options.content ? " \n\n"    
      @add file      
    ###
    parse: (response)=>
      console.log("in proj parse")
      console.log response
      return response
    ###
      
  return Project
