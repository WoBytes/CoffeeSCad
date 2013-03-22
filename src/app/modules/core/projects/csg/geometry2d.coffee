define (require)->
  globals = require './globals'
  
  base = require './csgBase'
  CAGBase = base.CAGBase
  
  maths = require './maths'
  Vertex = maths.Vertex
  Vertex2D = maths.Vertex
  Vector2D = maths.Vector2D
  Side = maths.Side
  
  globals = require './globals'
  defaultResolution2D = globals.defaultResolution2D
  
  utils = require './utils'
  parseOptionAsLocations = utils.parseOptionAsLocations
  parseOptionAs2DVector = utils.parseOptionAs2DVector
  parseOptionAsFloat = utils.parseOptionAsFloat
  parseOptionAsInt = utils.parseOptionAsInt
  
  extras = require './extras'
  
  ###2D shapes###
  class Circle extends CAGBase
    # Construct a circle
    #   options:
    #     center: a 2D center point
    #     radius: a scalar
    #     resolution: number of sides per 360 degree rotation
    #   returns a CAG object
    #
    constructor: (options) ->
      options = options or {}
      if "r" of options then hasRadius = true
      defaults = {r:1,d:2,center:[0,0],$fn:globals.defaultResolution2D}
      options = utils.parseOptions(options,defaults)
      super options
      
      diameter = parseOptionAsFloat(options, "d",defaults["d"])
      radius = diameter/2 
      if hasRadius
        radius = parseOptionAsFloat(options, "r", radius)
      center= parseOptionAs2DVector(options, "center", defaults["center"], radius)
      resolution = parseOptionAsInt(options, "$fn", defaults["$fn"])
      sides = []
      prevvertex = undefined
      i = 0
    
      while i <= resolution
        radians = 2 * Math.PI * i / resolution
        point = Vector2D.fromAngleRadians(radians).times(radius).plus(center)
        vertex = new Vertex2D(point)
        sides.push new Side(prevvertex, vertex)  if i > 0
        prevvertex = vertex
        i++
      @sides = sides
  
  class Rectangle extends CAGBase
    # Construct a rectangle
    #   options:
    #     center: a 2D center point
    #     size: a 2D vector with width and height
    #   returns a CAGBase object
    #
    constructor: (options) ->
      options = options or {}
      defaults = {size:[1,1],center:[0,0],cr:0,$fn:0,corners:["all"]}
      options = utils.parseOptions(options,defaults)
      super options
      
      size = parseOptionAs2DVector(options, "size", defaults["size"])
      center= parseOptionAs2DVector(options,"center",size.negated().dividedBy(2), defaults["center"])
      #rounding
      corners = parseOptionAsLocations(options, "corners",defaults["corners"])
      cornerRadius = parseOptionAsFloat(options,"cr",defaults["cr"])
      cornerResolution = parseOptionAsInt(options,"$fn",defaults["$fn"])
      
      if cornerRadius is 0 or cornerResolution is 0
        points = [center.plus(size), center.plus(new Vector2D(size.x, 0)), center, center.minus(new Vector2D(0, -size.y))]
        result = CAGBase.fromPoints points
        @sides = result.sides
      else if cornerRadius > 0 and cornerResolution > 0
        #2D so we only care about left/right, front/back
        
        chosenIndices = []
        
        console.log corners.toString(2)
        validCorners = parseInt(corners,2) & (parseInt("001111",2))
        console.log validCorners.toString(2)
        backFlag = 0x1#hex vs bin compare?
        frontFlag = 0x2
        rightFlag = 0x3#parseInt("100",2)#
        leftFlag = 0x4#parseInt("1000",2)#0x4
        console.log "front: #{frontFlag} left: #{parseInt(leftFlag,16)} right: #{parseInt(rightFlag,16)}"
        #FIXME: god awfull hack
        if (validCorners & frontFlag)
          if (validCorners & leftFlag)
            chosenIndices.push(3)
          if (validCorners & rightFlag)
            chosenIndices.push(1)
        if (validCorners & backFlag)  
          if (validCorners & leftFlag)
            chosenIndices.push(2)
          if (validCorners & rightFlag)
            chosenIndices.push(0)      
        
        
        subShapes = []
        rCornerPositions = []
        for i in [-1,1]
          for j in [-1,1]
            subCenter = new Vector2D(i*size.x/2,j*size.y/2).plus(center)
            rCornerPositions.push(subCenter)
        
        for i in [0...rCornerPositions.length]
          r =  new Rectangle({size:cornerRadius,center:true})
          corner = rCornerPositions[i]
          bX = corner.x/Math.abs(corner.x)
          bY = corner.y/Math.abs(corner.y)
          insetVector = corner.minus(new Vector2D(bX,bY).times(cornerRadius/2))
          r.translate(insetVector)
          console.log "corner: #{corner.x} #{corner.y}"
          console.log "cornerElement position: #{insetVector.x} #{insetVector.y}"
          subShapes.push(r)
          
        for index in chosenIndices
          corner = rCornerPositions[index]
          bX = corner.x/Math.abs(corner.x)
          bY = corner.y/Math.abs(corner.y)
          insetVector = corner.minus(new Vector2D(bX,bY).times(cornerRadius))
          #console.log "Rounded cornerElement position: #{insetVector.x} #{insetVector.y}"
          c = new Circle({r:cornerRadius,$fn:cornerResolution,center:true})
          c.translate(insetVector)
          subShapes[index] = c  
        
        result = extras.hull(subShapes)
        @sides = result.sides

  return {
    "Rectangle": Rectangle
    "Circle": Circle
    }    
  