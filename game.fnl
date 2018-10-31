(local sti (require "lib.sti"))
(local bump (require "lib.bump"))
(local view (require "lib.fennelview"))
(local moonshine (require "lib.moonshine"))
(local gamera (require "lib.gamera"))
(local anim8 (require "lib.anim8"))
(var map nil)
(var world nil)
(var canvas nil)
(var camera nil)
(local scale 1)
(var enemy-list [])

(local player {:x 8 :y 8 :width 7 :height 16 :speed 40 :aim 0 :type "player" :live true :grid nil :animation nil})
(local bullet {:x 0 :y 0 :width 8 :height 4 :speed 180 :aim 0 :type  "bullet" :direction "right" :exists nil})
(local enemy {:x 0 :y 0 :width 8 :height 8 :speed 1 :aim 0 :health 5 :type "enemy" :flipped nil :id 0  :grid nil :left-animation nil :right-animation nil :up-animation nil :down-animation nil })

(var enemy-spawner [
                    {:roomi 2 :roomj 1 :x 260 :y 60}
                    {:roomi 1 :roomj 2 :x 80 :y 180 }
                    {:roomi 1 :roomj 3 :x 62 :y 321 }
                    {:roomi 2 :roomj 3 :x 186 :y 321 }
                     {:roomi 1 :roomj 4 :x 53 :y 423 }
                     {:roomi 2 :roomj 5 :x 276 :y 492 }
                     {:roomi 4 :roomj 4 :x 502 :y 419 }

                    ])

(var can-shoot true)
(global p player)

(var last-camera-x nil)
(var last-camera-y nil)
(var camera-offset nil)
(var camera-dy 0)
(var camera-dx 0)
(var chain nil)
(var music nil)
(var shoot-sound nil)
(var boom-sound nil)
(var hit-sound nil)
(var roomi 1)
(var roomj 1)

(var room-w  160)
(var room-h 120)
(var player-win nil)
(var id 0)

(defn  get-id []
  (set id (+ id 1))
  id)

;; 4,3
(defn love.load []
  (set camera (gamera.new 0 0 2000 2000))
  (: camera :setWorld 0 0 2000 2000)
  (: camera :setWindow 0 0 1024 768)
  (: camera :setScale 5)
  (: camera :setPosition 0 0)
  (set camera.l 0)
  (set camera.t 0)
  (set last-camera-x camera.x)
  (set last-camera-y camera.y)
  
  (set chain (moonshine.chain 800 600 moonshine.effects.crt))
  
  (set chain.crt.scaleFactor 1 )
  (set chain.crt.distortionFactor [1.02 1.02])
  (set chain.crt.feather 0.15 )

  (chain.chain moonshine.effects.chromasep)
  (set chain.chromasep.radius 3 )

  (set map (sti "level.lua" ["bump"]))
  (set world (bump.newWorld))
  (: world :add player player.x player.y player.width player.height)
  (: map :bump_init world)
  (let [layer (: map :addCustomLayer "player")]
    (set layer.sprites [player]))

  (set player.image (love.graphics.newImage "assets/player.png"))  
  (: player.image :setFilter "nearest" "nearest")

  (set bullet.image (love.graphics.newImage "assets/bullet.png"))  
  (: bullet.image :setFilter "nearest" "nearest")

  (set enemy.image (love.graphics.newImage "assets/slime.png"))  
  (: enemy.image :setFilter "nearest" "nearest")
  (set enemy.grid (anim8.newGrid 8 8 (: enemy.image :getWidth)  (: enemy.image :getHeight)  ))
  (set enemy.animation (anim8.newAnimation (: enemy.grid :getFrames '1-5' 1) 0.1))

  
  (set player.grid (anim8.newGrid 7 16 (: player.image :getWidth) (: player.image :getHeight)))
  (set player.right-animation (anim8.newAnimation (: player.grid :getFrames '1-3' 1) 0.1 ))
  (set player.left-animation  (: (: player.right-animation :clone) :flipH ))
  (set player.up-animation  (anim8.newAnimation (: player.grid :getFrames '1-3' 2) 0.1 ))
  (set player.down-animation  (anim8.newAnimation (: player.grid :getFrames '1-3' 3) 0.1 ))

  
  (set  music  (love.audio.newSource "assets/music.wav" "static"))
  (: music :setLooping true)
  (: music :play)

  (set  shoot-sound  (love.audio.newSource "assets/shoot.wav" "static"))
  (set  boom-sound  (love.audio.newSource "assets/boom.wav" "static"))
  (set hit-sound  (love.audio.newSource "assets/hit.wav" "static"))
  

             )

(local dirs {:up [0 -1] :down [0 1] :left [-1 0] :right [1 0]})

(local states [ "cameraL"   "cameraR"  "cameraU"  "cameraD"  "cameraInTrans" "cameraStopTrans" "cameraIDLE" ])
(var game-state "cameraIDLE")

(var spawned 0)
(var spawn-target 0)

(var spawned-roomi 1)
(var spawned-roomj 1)
;; ------------ Enemy control ------------------------------------------
(defn remove-enemies []
  (when (> (# enemy-list) 0)
    (let [len (# enemy-list)]
      (for [i 1 len] (let [en (. enemy-list i)]
                       (when (: world :hasItem en)
                         (: world :remove en))) ))
    (print "removing"  "enemy" )
    (set enemy-list []))
  )

(defn spawn [en]
 (let [layer (: map :addCustomLayer "enemy")]
    (set layer.sprites [en]))
 (if (not (: world :hasItem en))
       (: world :add en en.x en.y en.width en.height)
  (set [en.x en.y] [(: world :move en x y)]))
  (table.insert enemy-list en))

(defn spawn-enemies []
;  (print "BEFORE: roomi: " roomi  "sroomi: " spawned-roomi  "roomj: " roomj "spawned-roomj: " spawned-roomj)

  (when (or (~= roomi spawned-roomi) (~= roomj spawned-roomj))    
    (remove-enemies)
  (set [spawned-roomi spawned-roomj] [roomi  roomj  ])
  (let [len (# enemy-spawner)]
    (for [i 1  len]
      (let [en (. enemy-spawner i)]
 ;       (print "roomi" roomi "en.roomi" en.roomi "roomj" roomj "en.roomj" en.roomj)
        (when (and (= roomi en.roomi) (= roomj en.roomj))
          (let [slime enemy]
            (set [slime.x slime.y slime.id slime.health] [en.x en.y (get-id) 6])
            ;(pp slime)
            (spawn slime)
            ))))
   )
    ;(pp enemy-list)
  ;(print "AFTER: roomi: " roomi  "sroomi: " spawned-roomi  "roomj: " roomj "spawned-roomj: " spawned-roomj)
  ))

(defn draw-enemies []
  (when (> (# enemy-list) 0)
    (let [len (# enemy-list)]
      (for [i 1 len]
        (let [e (. enemy-list i)]
          (if (> e.health 0)
          (: e.animation :draw e.image   e.x e.y)))))))

(var ecols nil)
(var elen nil)

(defn update-enemies [dt]
    (when (> (# enemy-list) 0)
    (let [len (# enemy-list)]
      (for [i 1 len]
        (let [e (. enemy-list i)]
          (if (and (<= e.health 0) (: world :hasItem e) )
              (: world :remove e))
          (let [
                deltaX   (- player.x e.x)
                deltaY   (-  player.y e.y)
                [dx dy]  [deltaX deltaY] 
                x (+ e.x (* (* dx e.speed) dt))
                y (+ e.y (* (* dy e.speed) dt))]
            (when (: world :hasItem e)
              (: e.animation :update dt )
            (set [e.x e.y ecols elen] [(: world :move e x y)])
            (for [i 1 elen]
              (let [col (. ecols i)]
                (if (~= col.other nil)
                    (when (and (~= col.other.type nil) (= col.other.type "player") player.live )
                    (: hit-sound :play)    
                    (set player.live nil))))))
            ))))))

;;------------ BULLET CONTROL  ------------------------------------------

(defn shoot []

  (set bullet.shotting true)
  (: shoot-sound :play)

  (if  (= bullet.direction "right")
    (set [bullet.x bullet.y bullet.shotting bullet.direction] [(+ player.x  player.width)  (+ player.y  (/ player.height 2) ) true player.direction])

   (= bullet.direction "left")
    (set [bullet.x bullet.y bullet.shotting bullet.direction] [ (- player.x bullet.width)  (+ player.y  (/ player.height 2) ) true player.direction])

   (= bullet.direction "down" )
     (set [bullet.x bullet.y bullet.shotting bullet.direction] [ player.x   (+ player.y player.height)   true player.direction])
 
   (or (= bullet.direction "up")  )
       (set [bullet.x bullet.y bullet.shotting bullet.direction] [ player.x  (- player.y bullet.height)  true player.direction]))

  (if (not (: world :hasItem bullet))
       (: world :add bullet bullet.x bullet.y bullet.width bullet.height)  
  (let [layer (: map :addCustomLayer "bullet")]
    (set layer.sprites [bullet]))
  (set [bullet.x bullet.y] [(: world :move bullet x y)])
  (set can-shoot nil)))
  

(defn damage-enemy [en]
;  (print "enemy damaged")
;  (pp en)
  (when (and (= en.type "enemy") (~= en.health nil) )
  (let [len (# enemy-list)]
    (for [i 1 len]
      (let [e (. enemy-list i)]
      (when (= e.id en.id)
         (set e.health (- e.health 1))
         ;(pp e)
         ))))))

(defn update-bullet[dt]
 ;  (pp bullet)
  (var cols nil)
  (var len 0)
  (if (: world :hasItem bullet)
      (each [key delta (pairs dirs)]
        (when (= bullet.direction key)
        (let [[dx dy] delta
            x (+ bullet.x (* (* dx bullet.speed) dt))
            y (+ bullet.y (* (* dy bullet.speed) dt))]
          (set [bullet.x bullet.y cols len] [(: world :move bullet x y)])
          (for [i 0 len]
            (let [collision (. cols i)]
              (if (and (~= collision nil)  (~= collision.other nil))
              (damage-enemy collision.other))
              (when (and (> len 0) (: world :hasItem bullet))
                (: world :remove bullet)
                (set can-shoot true)
                (set bullet.shotting nil)
                (set [bullet.x bullet.y] [player.x player.y])
                (: boom-sound :play)
                ))
          ))))))
;;------------------- Room update ------------------
(var key-pressed nil)
(defn update-level [dt]
 (set key-pressed nil)
 (local cons nil)
 (local len nil) 
 (when  (and (love.keyboard.isDown "space") (not bullet.shotting) player.live )
   (shoot))
  (each [key delta (pairs dirs)]
    (when (and (love.keyboard.isDown key) )
      (set key-pressed true)
      (set player.direction key)
      (let [[dx dy] delta
            x  (+ player.x (* (* dx player.speed) dt))
            y (+ player.y (* (* dy player.speed) dt))]
        (set [player.x player.y] [(: world :move player x y)]))))

  (when key-pressed
  (: player.down-animation :update dt)
  (: player.up-animation :update dt)
  (: player.left-animation :update dt)
  (: player.right-animation :update dt))
  (update-bullet dt)
  (update-enemies dt)
   (: map :update dt))
 
;;----------------CAMERA CONTROL----------------------------------------
(var deltax 160)
(var deltay 120)
(var camera-speed 10)
 
(defn move-camera-right [dt]
  (: camera :setPosition   (+ camera.x room-w ) camera.y)
  (set roomi (+ roomi 1))
  (set game-state "cameraIDLE"))

(defn move-camera-left [dt]
  (: camera :setPosition   (- camera.x room-w) camera.y)
  (set roomi (- roomi 1))
  (set game-state "cameraIDLE"))

(defn move-camera-up [dt]
  (: camera :setPosition    camera.x (- camera.y room-h))
  (set roomj (- roomj 1))
  (set game-state "cameraIDLE"))

(defn move-camera-down [dt]
  (set roomj (+ roomj 1))
  (: camera :setPosition    camera.x (+ camera.y  room-h))
  (set game-state "cameraIDLE"))

(defn update-dy []
  (when  (~=  camera.y  last-camera-y)
          (set camera-dy (* (- roomj 1)  (- (- camera.y last-camera-y))))
          (when (> camera-dy  0)   (set camera-dy (- camera-dy)))
          (set last-camera-y camera.y )
          (when (= roomj 1)
            (set camera-dy 0))
            (spawn-enemies)))

(defn update-dx []
  (when  (~=  camera.x  last-camera-x)
          (set camera-dx (* (- roomi 1)  (- (- camera.x last-camera-x))))
          (when (> camera-dx  0)   (set camera-dx (- camera-dx)))
          (set last-camera-x camera.x )
          (when (= roomi 1)
            (set camera-dx 0))
            (spawn-enemies)))
;;-----------------------------------------------------------------  

(defn love.update [dt]
;  (print player.x player.y)
  (update-dy)
  (update-dx)
  (if (= game-state "cameraIDLE")
      (update-level dt))

  (when (and (> player.x (* roomi room-w)) (= game-state "cameraIDLE"))
      (set game-state "cameraR")
      (move-camera-right dt))

  (when (and  (> roomi 1) (< player.x (- (* roomi room-w) room-w) ) (= game-state "cameraIDLE"))
      (set game-state "cameraL")
      (move-camera-left dt))

  (when (and (< player.y   (* roomj room-h)) (> roomj 1)  (= game-state "cameraIDLE"))
      (set game-state "cameraUP")
      (move-camera-up dt))

  (when (and   (> player.y   (* roomj room-h)  )  (= game-state "cameraIDLE"))
      (set game-state "cameraDown")
      (move-camera-down dt))

  
  )
;; -----------------------------

(defn love.draw []
  (var rotation 0)
  (chain.draw (fn []
                (: camera :draw
                (fn [l t w h]
                  (love.graphics.clear)

  (when player.live
  (love.graphics.scale scale scale)
  (love.graphics.setColor 1 1 1)
  (love.graphics.print  (.. "ROOM: " roomi "-" roomj ) (- camera.x 90 )  (- camera.y 70)  0 0.5)
  (: map :draw    camera-dx camera-dy  camera.scale camera.scale)
  
  ;(love.graphics.draw player.image   player.x player.y)
  (if (= player.direction "left")
      (: player.left-animation :draw player.image player.x player.y)
      (= player.direction "right")
      (: player.right-animation :draw player.image player.x player.y) 

      (= player.direction "down")
      (: player.down-animation :draw player.image player.x player.y)

      (= player.direction "up")
      (: player.up-animation :draw player.image player.x player.y))
  
  (if (= bullet.direction "up")
    (set rotation  (/ math.pi -2) )
    (= bullet.direction "down")
    (set rotation  (/ math.pi -2) ))
  (draw-enemies)  
  (if bullet.shotting (love.graphics.draw bullet.image bullet.x bullet.y rotation)))

  (when  (and (= player.live nil) (not player-win))
    (love.graphics.print  "Game over"  (- camera.x 40 )  (- camera.y 40)  0 0.5))

  (when (and (= roomi 4) (= roomj 2))
    (set player-win true)
    (set player.live nil)
        (love.graphics.print  "You WIN!"  (- camera.x 40 )  (- camera.y 40)  0 0.5))
    
  
  (love.graphics.setColor 1 1 1))))))

(defn love.keypressed [key] (when (= key "escape") (love.event.quit)))
