(proclaim '(optimize (speed 3) (safety 0) (debug 0) (compilation-speed 0)))
(pushnew (uiop:getcwd) asdf:*central-registry*)
(ql:quickload '(#:{{cookiecutter.project_slug}} #:deploy))
(asdf:make :{{cookiecutter.project_slug}})
