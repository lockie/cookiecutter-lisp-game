(in-package #:{{cookiecutter.project_slug}})

(define-constant +window-width+ 800)
(define-constant +window-height+ 600)

(define-constant +repl-update-interval+ 0.3d0)

(defvar *resources-path*
  (asdf:system-relative-pathname :{{cookiecutter.project_slug}} #P"Resources/"))

(deploy:define-hook (:boot set-resources-path) ()
  (setf *resources-path*
        (merge-pathnames #P"Resources/"
                         (uiop:pathname-parent-directory-pathname
                          (deploy:runtime-directory)))))

(define-constant +font-path+ "inconsolata.ttf" :test #'string=)
(define-constant +font-size+ 24)
{% if cookiecutter.backend == "liballegro" %}
(define-constant +config-path+ "../config.cfg" :test #'string=)
{% elif cookiecutter.backend == "SDL2" %}
(defun %render-text (renderer font x y text)
  (let* ((surface (sdl2-ttf:render-text-blended font text 255 255 255 0))
         (texture (sdl2:create-texture-from-surface renderer surface)))
    (sdl2:with-rects ((dest-rect x y
                                 (sdl2:texture-width texture)
                                 (sdl2:texture-height texture)))
      (sdl2:render-copy renderer texture :source-rect (cffi:null-pointer)
                                         :dest-rect dest-rect)
      (sdl2:destroy-texture texture)))
  t)
{% endif %}
(defun init ()
  ;; TODO : put your initialization logic here
  )

(declaim (type fixnum *fps*))
(defvar *fps* 0)

(defun update (dt)
  (unless (zerop dt)
    (setf *fps* (round 1 dt)))

  ;; TODO : put your game logic here
  )

(defvar *font*)

(defun render ({%- if cookiecutter.backend == "SDL2" -%}renderer{%- endif -%})
{% if cookiecutter.backend == "liballegro" %}
  (al:draw-text *font* (al:map-rgba 255 255 255 0) 0 0 0
                (format nil "~d FPS" *fps*))
{% elif cookiecutter.backend == "raylib" %}
  (raylib:draw-text-ex *font* (format nil "~d FPS" *fps*) (3d-vectors:vec2 0 0)
                       (float +font-size+) 1.0 :raywhite)
{% elif cookiecutter.backend == "SDL2" %}
  (%render-text renderer *font* 0 0 (format nil "~d FPS" *fps*))
{% endif %}
  ;; TODO : put your drawing code here
  )
{% if cookiecutter.backend == "liballegro" %}
(cffi:defcallback %main :int ((argc :int) (argv :pointer))
  (declare (ignore argc argv))
  (handler-bind
      ((error #'(lambda (e) (unless *debugger-hook*
                         (al:show-native-message-box
                          (cffi:null-pointer) "Hey guys"
                          "We got a big error here :("
                          (with-output-to-string (s)
                            (uiop:print-condition-backtrace e :stream s))
                          (cffi:null-pointer) :error)))))
    (uiop:chdir (setf *default-pathname-defaults* *resources-path*))
    (al:set-app-name "{{cookiecutter.project_slug}}")
    (unless (al:init)
      (error "Initializing liballegro failed"))
    (let ((config (al:load-config-file +config-path+)))
      (unless (cffi:null-pointer-p config)
        (al:merge-config-into (al:get-system-config) config)))
    (unless (al:init-primitives-addon)
      (error "Initializing primitives addon failed"))
    (unless (al:init-image-addon)
      (error "Initializing image addon failed"))
    (unless (al:init-font-addon)
      (error "Initializing liballegro font addon failed"))
    (unless (al:init-ttf-addon)
      (error "Initializing liballegro TTF addon failed"))
    (unless (al:install-audio)
      (error "Intializing audio addon failed"))
    (unless (al:init-acodec-addon)
      (error "Initializing audio codec addon failed"))
    (unless (al:restore-default-mixer)
      (error "Initializing default audio mixer failed"))
    (al:set-new-display-flags '(:opengl))
    (al:set-new-display-option :alpha-size 8 :require)
    (let ((display (al:create-display +window-width+ +window-height+))
          (event-queue (al:create-event-queue)))
      (when (cffi:null-pointer-p display)
        (error "Initializing display failed"))
      (al:inhibit-screensaver t)
      (al:set-window-title display "{{cookiecutter.project_name}}")
      (al:register-event-source event-queue
                                (al:get-display-event-source display))
      (al:install-keyboard)
      (al:register-event-source event-queue
                                (al:get-keyboard-event-source))
      (al:install-mouse)
      (al:register-event-source event-queue
                                (al:get-mouse-event-source))
      (unwind-protect
           (cffi:with-foreign-object (event '(:union al:event))
             (init)
             (#+darwin trivial-main-thread:call-in-main-thread #-darwin funcall
              #'livesupport:setup-lisp-repl)
             (loop
               :named main-game-loop
               :with *font* := (al:ensure-loaded #'al:load-ttf-font
                                                 +font-path+
                                                 (- +font-size+) 0)
               :with ticks :of-type double-float := (al:get-time)
               :with last-repl-update :of-type double-float := ticks
               :with dt :of-type double-float := 0d0
               :while (loop
                        :named event-loop
                        :while (al:get-next-event event-queue event)
                        :for type := (cffi:foreign-slot-value
                                      event '(:union al:event) 'al::type)
                        :always (not (eq type :display-close)))
               :do (let ((new-ticks (al:get-time)))
                     (setf dt (- new-ticks ticks)
                           ticks new-ticks))
                   (when (> (- ticks last-repl-update)
                            +repl-update-interval+)
                     (livesupport:update-repl-link)
                     (setf last-repl-update ticks))
                   (al:clear-to-color (al:map-rgb 0 0 0))
                   (livesupport:continuable
                     (update dt)
                     (render))
                   (al:flip-display)
               :finally (al:destroy-font *font*)))
        (al:inhibit-screensaver nil)
        (al:destroy-event-queue event-queue)
        (al:destroy-display display)
        (al:stop-samples)
        (al:uninstall-system)
        (al:uninstall-audio)
        (al:shutdown-ttf-addon)
        (al:shutdown-font-addon)
        (al:shutdown-image-addon))))
  0)

(defun main ()
  (#+darwin trivial-main-thread:with-body-in-main-thread #-darwin progn nil
    (float-features:with-float-traps-masked
        (:divide-by-zero :invalid :inexact :overflow :underflow)
      (al:run-main 0 (cffi:null-pointer) (cffi:callback %main)))))
{% elif cookiecutter.backend == "raylib" %}
(defun main ()
  (uiop:chdir *resources-path*)
  (raylib:with-window (+window-width+ +window-height+
                       "{{cookiecutter.project_name}}")
    (raylib:set-exit-key 0)
    (init)
    (livesupport:setup-lisp-repl)
    (let ((*font* (raylib:load-font-ex +font-path+ +font-size+
                                       (cffi:null-pointer) 0)))
      (loop :named main-game-loop
            :with last-repl-update :of-type double-float := 0d0
            :until (raylib:window-should-close)
            :for dt :of-type single-float := (raylib:get-frame-time)
            :for ticks :of-type double-float := (raylib:get-time)
            :do (raylib:with-drawing
                  (when (> (- ticks last-repl-update)
                           +repl-update-interval+)
                    (livesupport:update-repl-link)
                    (setf last-repl-update ticks))
                  (raylib:clear-background :black)
                  (livesupport:continuable
                    (update dt)
                    (render))
                  (raylib::wait-time 0.001d0))))))
{% elif cookiecutter.backend == "SDL2" %}
(defun main ()
  (uiop:chdir *resources-path*)
  (sdl2:make-this-thread-main
   #'(lambda ()
       (sdl2:with-init (:everything)
         (handler-bind
             ((error #'(lambda (e)
                         (unless *debugger-hook*
                           (sdl2-ffi.functions::sdl-show-simple-message-box
                            sdl2-ffi:+sdl-messagebox-error+
                            "Hey guys"
                            (with-output-to-string (s)
                              (format s "We got a big error here :(~%~%")
                              (uiop:print-condition-backtrace e :stream s))
                            (cffi:null-pointer))
                           (sdl2:quit)
                           (uiop:quit)))))
           (sdl2-image:init '(:png :jpg))
           (sdl2-mixer:init)
           (sdl2-ttf:init)
           (sdl2:with-window (win :w +window-width+ :h +window-height+
                                  :title "{{cookiecutter.project_name}}"
                                  :flags '(:shown))
             (sdl2:with-renderer (ren win)
               (init)
               (let ((*font* (sdl2-ttf:open-font +font-path+ +font-size+))
                     (ticks (sdl2:get-ticks))
                     (dt 0.0))
                 (declare (type fixnum ticks)
                          (type single-float dt))
                 (sdl2:with-event-loop (:method :poll)
                   (:idle
                    ()
                    (let ((new-ticks (sdl2:get-ticks)))
                      (setf dt (* (- new-ticks ticks) 0.001)
                            ticks new-ticks))
                    (sdl2:render-clear ren)
                    (update dt)
                    (render ren)
                    (sdl2:render-present ren)
                    (sdl2:delay 1))
                   (:quit
                    ()
                    (sdl2-ttf:close-font *font*)
                    (sdl2-ttf:quit)
                    t))))))))))
{% endif %}
