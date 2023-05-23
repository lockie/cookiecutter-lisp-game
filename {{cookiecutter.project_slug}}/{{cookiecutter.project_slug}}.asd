(defsystem "{{cookiecutter.project_slug}}"
  :version "{{cookiecutter.version}}"
  :author "{{cookiecutter.full_name}}"
  :license "MIT"
  :depends-on (#:alexandria
               {% if cookiecutter.backend == "liballegro" %}
               #:cl-liballegro
               #:cl-liballegro-nuklear
               {% elif cookiecutter.backend == "raylib" %}
               #:cl-raylib
               {% elif cookiecutter.backend == "SDL2" %}
               #:sdl2
               #:sdl2-image
               #:sdl2-mixer
               #:sdl2-ttf
               {% endif %}
               #:livesupport)
  :serial t
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "main"))))
  :description "{{cookiecutter.project_short_description}}"
  :defsystem-depends-on (#:deploy)
  :build-operation "deploy-op"
  :build-pathname #P"{{cookiecutter.project_slug}}"
  :entry-point "{{cookiecutter.project_slug}}:main")
