(proclaim '(optimize (speed 3) (safety 0) (debug 0) (compilation-speed 0)))
(ql-util:without-prompting (ql:update-all-dists))
(ql:quickload '(#:{{cookiecutter.project_slug}} #:deploy))
{% if cookiecutter.backend == "SDL2" %}
#+darwin (progn
           (deploy:define-library cl-glut::glut :dont-deploy t)
           (deploy:define-library cl-opengl-bindings::opengl :dont-deploy t))
{% endif %}
(asdf:make :{{cookiecutter.project_slug}})
