(in-package :common-lisp-user)

(asdf:load-system "shop3")

(load (asdf:system-relative-pathname "shop3" "examples/IPC-2002/solution-converter.lisp"))
(load (asdf:system-relative-pathname "shop3" "examples/IPC-2002/ZenoTravel/SimpleTime/zenotravelSimpleTime.lisp"))

(in-package :shop-user)
(defparameter *thisfile*
  (or *compile-file-truename* *load-truename*
      (error "This file must be loaded in a context where *load-truename* or *compile-file-truename* is defined.")))


(defun solve-domain (pname)
  (let ((probfile (merge-pathnames (concatenate 'string pname ".lisp") *thisfile*)))
    (unless (probe-file probfile)
      (error "No SHOP3-translated version of the PDDL problem in ~a: have you run the problem-converter?" pname))
    (load probfile))
  (multiple-value-bind (sol soltime) (find-plans (intern (string-upcase pname) :shop-user))
    (if sol
      (progn
        (format t "~%*** Plan found in ~A seconds ***~%" soltime)
        (solution-converter sol soltime (merge-pathnames "../zenoSimpleTime.pddl" *thisfile*)
                            (concatenate 'string pname ".soln") t)
      )
      (format t "~%*** No Plan ***~%"))
  )
)

(solve-domain "pfile1")
(solve-domain "pfile2")
(solve-domain "pfile3")
(solve-domain "pfile4")
(solve-domain "pfile5")
(solve-domain "pfile6")
(solve-domain "pfile7")
(solve-domain "pfile8")
(solve-domain "pfile9")
(solve-domain "pfile10")
(solve-domain "pfile11")
(solve-domain "pfile12")
(solve-domain "pfile13")
(solve-domain "pfile14")
(solve-domain "pfile15")
(solve-domain "pfile16")
(solve-domain "pfile17")
(solve-domain "pfile18")
(solve-domain "pfile19")
(solve-domain "pfile20")

