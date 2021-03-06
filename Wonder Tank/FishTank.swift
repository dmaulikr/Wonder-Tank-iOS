//
//  FishTank.swift
//  Wonder Tank
//
//  Created by Murtuza Kainan on 1/17/15.
//  Copyright (c) 2015 Zach Perry. All rights reserved.
//

import Foundation
import SpriteKit

struct PhysicsCategory {
    static let None      : UInt32 = 0
    static let All       : UInt32 = UInt32.max
    static let Bound     : UInt32 = 0b100
    static let Fish      : UInt32 = 0b1       // 1
    static let Food      : UInt32 = 0b10      // 2
}

class FishTank: SKScene, SKPhysicsContactDelegate {
    
    var fishes: [fish] = []
    var foodInTank: [food] = []
    var foodCount = 0
    
    var fishTexture1: SKTexture!
    var fishTexture2: SKTexture!
    var fishTexture3: SKTexture!
    var fishTexture4o1: SKTexture!
    var fishTexture4o2: SKTexture!
    
    var water: SKSpriteNode!
    var lights: SKLightNode!
    
    var initialTime = CFTimeInterval(0)
    var simulationTime = CFTimeInterval(0)
    
    var addFood = false
    var addFish = false
    
    var posScale = CGFloat(-1.0)
    var negScale = CGFloat(1.0)
    
    var fishShape: SKShapeNode!
    
    override func didMoveToView(view: SKView) {
        backgroundColor = SKColor.whiteColor()
        self.physicsWorld.gravity = CGVectorMake(0.0, 0.0)
        self.physicsWorld.contactDelegate = self
        
        fishTexture1 = SKTexture(imageNamed: "fish.png")
        fishTexture2 = SKTexture(imageNamed: "fish2.png")
        fishTexture3 = SKTexture(imageNamed: "fish3.png")
        fishTexture4o1 = SKTexture(imageNamed: "fish4compress.png")
        fishTexture4o2 = SKTexture(imageNamed: "fish4expand.png")
        
        let bottomBoundSprite = SKSpriteNode(color: UIColor.blackColor(), size: CGSize(width: self.size.width*2, height: 10))
        bottomBoundSprite.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: self.size.width*2, height: 10))
        bottomBoundSprite.physicsBody?.dynamic = false
        
        let leftBoundSprite = SKSpriteNode(color: UIColor.blackColor(), size: CGSize(width: 10, height: self.size.height*2))
        leftBoundSprite.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 10, height: self.size.height*2))
        leftBoundSprite.physicsBody?.dynamic = false
        leftBoundSprite.position = CGPoint(x: 0, y: 0)
        
        let rightBoundSprite = SKSpriteNode(color: UIColor.blackColor(), size: CGSize(width: 10, height: self.size.height*2))
        rightBoundSprite.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 10, height: self.size.height*2))
        rightBoundSprite.physicsBody?.dynamic = false
        rightBoundSprite.position = CGPoint(x: self.size.width, y: self.size.height)
        
        water = SKSpriteNode(color: UIColor.cyanColor(), size: CGSize(width: self.size.width, height: self.size.height - 25))
        water.position = CGPoint(x: self.size.width/2.0, y: water.size.height/2.0)
        water.alpha = 0.5
        
        lights = SKLightNode()
        lights.position = CGPoint(x: self.size.width/2, y: self.size.height)
        
        self.addChild(bottomBoundSprite)
        self.addChild(leftBoundSprite)
        self.addChild(rightBoundSprite)
        self.addChild(water)
        self.addChild(lights)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            
            if addFood == true {
                let location = touch.locationInNode(self)

                let spriteObject = food(texture: SKTexture(imageNamed: "fishfood.png"))
                
                spriteObject.position = location
                spriteObject.physicsBody = SKPhysicsBody(circleOfRadius: spriteObject.size.height / 2.75)
                spriteObject.physicsBody?.dynamic = true
                spriteObject.physicsBody?.categoryBitMask = PhysicsCategory.Food
                spriteObject.physicsBody?.contactTestBitMask = PhysicsCategory.Fish
                spriteObject.physicsBody?.collisionBitMask = PhysicsCategory.Bound
                self.foodCount++
                swimToFood(fdlocation: location)
                self.addChild(spriteObject)
            }
            else if addFish == true {
                let location = touch.locationInNode(self)
                let spriteObject = fish(texture: SKTexture(imageNamed: "fish.png"))
                
                let randVar = randVal(min: 0, max: 4)
                
                if randVar <= 1 {
                    spriteObject.texture = fishTexture1
                }
                else if randVar <= 2 {
                    spriteObject.texture = fishTexture2
                }
                else if randVar <= 3 {
                    spriteObject.texture = fishTexture3
                }
                else if randVar <= 4 {
                    spriteObject.texture = fishTexture4o2
                }
                
                
                spriteObject.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: 100, height: 50))
                spriteObject.physicsBody?.dynamic = true
                spriteObject.physicsBody?.categoryBitMask = PhysicsCategory.Fish
                spriteObject.physicsBody?.contactTestBitMask = PhysicsCategory.Food
                spriteObject.physicsBody?.collisionBitMask = PhysicsCategory.Bound
                spriteObject.position = location
                spriteObject.xScale = posScale
                self.fishes.append(spriteObject)
                
                self.addChild(spriteObject)
            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        driveBehaviour()
        self.simulationTime = currentTime - self.initialTime
        
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody

        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if secondBody.categoryBitMask == PhysicsCategory.Food {
            fishDidCollideWithFood(secondBody.node as SKSpriteNode)
        }
    }
    
    func fishDidCollideWithFood(foodsp:SKSpriteNode) {
        foodsp.removeFromParent()
        self.foodCount--
    }
    
    func driveBehaviour() {
        for fishObj: fish in self.fishes {
            
            if fishObj.moved > fishObj.movementBound {
                fishObj.moved = CGFloat(0.0)
                
                if randVal(min: 0.0, max: 10.0) > 5.0 {
                    fishObj.movementRateX = -fishObj.movementRateX
                    fishObj.xScale = fishObj.xScale * -1
                }
                else {
                    
                }
                
                if randVal(min: 0.0, max: 10.0) > 5.0 {
                    fishObj.movementRateY = CGFloat(1.8)
                    
                }
                else {
                    fishObj.movementRateY = CGFloat(-0.8)
                }
            }
            
            if fishObj.position.x >= self.size.width - 10 {
                fishObj.movementRateX = CGFloat(-1.0)
                fishObj.xScale = negScale
            }
            else if fishObj.position.x <= 0 + 10{
                fishObj.movementRateX = CGFloat(1.0)
                fishObj.xScale = posScale
            }
            
            if fishObj.position.y >= self.size.height - 10{
                fishObj.movementRateY = CGFloat(-0.9)
            }
            else if fishObj.position.y <= 0 + 10{
                fishObj.movementRateY = CGFloat(1.8)
            }
            
            fishObj.position.x += fishObj.movementRateX
            fishObj.position.y += fishObj.movementRateY
            fishObj.moved++
        }
    }
    
    func swimToFood(#fdlocation: CGPoint) {
        for fishObj: fish in self.fishes {
            
            if fishObj.position.x > fdlocation.x {
                fishObj.movementRateX = CGFloat(-2.0)
                fishObj.xScale = negScale
            }
            else {
                fishObj.movementRateX = CGFloat(2.0)
                fishObj.xScale = posScale
            }
            
            if fishObj.position.y > fdlocation.y {
                fishObj.movementRateY = CGFloat(-2.0)
            }
            else {
                fishObj.movementRateY = CGFloat(2.0)
            }
        }
    }
    
    func flipPufferFish() {
        for fishObj: fish in self.fishes {
            if fishObj.texture == fishTexture4o1 {
                fishObj.texture = fishTexture4o2
            }
            else if fishObj.texture == fishTexture4o2 {
                fishObj.texture == fishTexture4o1
            }
        }
    }
    
    func rand() -> CGFloat {
        return CGFloat(Float(arc4random())/0xFFFFFFFF)
    }
    
    func randVal(#min: CGFloat, max: CGFloat) -> CGFloat {
        return rand() * (max - min) + min
    }
    
    func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func setFoodToTrue() {
        self.addFish = false
        self.addFood = true
    }
    
    func setFishToTrue() {
        self.addFood = false
        self.addFish = true
    }
}

class fish: SKSpriteNode {
    var movementRateX = CGFloat(1.0)
    var movementRateY = CGFloat(1.8)
    let movementBound = CGFloat(100.0)
    var moved = CGFloat(0.0)
    //var namestr = ""
    //var agression = 0
    //var appetite = 10
    //var currentlyConsumed = 0
}

class food: SKSpriteNode {
    var movementRateX = CGFloat(0.2)
    var movementRateY = CGFloat(0.2)
    var status = true
}

class environment {
    var upperBound = CGFloat(1.0)
}

