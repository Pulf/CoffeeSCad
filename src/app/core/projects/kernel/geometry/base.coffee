define (require) ->
  require 'three'
  require 'ThreeCSG'
  
  #TODO: where to do canonicalization and normalization?
  
  
  class ObjectBase extends THREE.Mesh
    #base class regrouping feature of THREE.Mesh and THREE.CSG
    
    constructor:( geometry, material )->
      super(geometry, material)
      THREE.Mesh.call( @, geometry, material )
      
      #FIXME: see THREE.jS constructors thingamajig
      #@geometry = geometry or null
      #@material = 
      #console.log @prototype
      #Object.create(@prototype)
      @bsp = new ThreeBSP(@)
    
    union:(object)=>
      @bsp = @bsp.union( object.bsp )
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
      
    subtract:(object)=>
      @bsp = @bsp.subtract( object.bsp )
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
      
      @geometry.computeBoundingBox()
      @geometry.computeCentroids()
      @geometry.computeFaceNormals();
      @geometry.computeBoundingSphere()
      
    intersect:=>
      @bsp = @bsp.intersect( object.bsp )
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
      
    inverse:=>
      @bsp = @bsp.invert()
      #TODO : only generate geometry on final pass ie make use of csg tree or processing tree/ast
      @geometry = @bsp.toGeometry()
      @geometry.computeVertexNormals()
  
  #ObjectBase.prototype = Object.create( THREE.Mesh.prototype )
  
  return ObjectBase