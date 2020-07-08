(in-package :spg)

(defvar modified-forest) ; used as special so that we can draw
                         ; cross-edges between primitive nodes.

(defun graph-plan-tree (plan-forest &key (tree-processor 'identity)
                                    (attributes nil)
                                         (graph-object (make-instance 'plan-tree-graph)))
  "Takes a SHOP plan forest (PLAN-FOREST) as input, and returns a CL-DOT graph object."
  (let ((modified-forest (mapcar #'(lambda (tree) (funcall tree-processor tree))
                               plan-forest)))
    (cl-dot:generate-graph-from-roots graph-object modified-forest attributes)))

(defmethod cl-dot:graph-object-node ((g plan-tree-graph) (obj cons))
  (declare (ignorable g))
  (make-instance 'cl-dot:node
    :attributes `(:label ,(format nil "~A" (tree-node-task obj))
                         :shape ,(if (primitive-node-p obj) :box
                                    :ellipse))))
                         

(defmethod cl-dot:graph-object-points-to ((g plan-tree-graph)(obj cons))
  (declare (ignorable g))
  (cond ((complex-node-p obj)
         (reverse
          (complex-node-children obj)))
        ((primitive-node-p obj)
         (let ((next-node (find-next-node (primitive-node-position obj) modified-forest)))
           (when next-node
             (list 
              (make-instance 'cl-dot:attributed
                            :object next-node
                            :attributes `(:constraint nil :color :blue))))))
        (t (error 'type-error :type-error-datum obj
                              :type-error-expected-type '(or primitive-node complex-node)))))

(defun find-next-node (index forest)
  (let (next-node
        (next-node-index most-positive-fixnum))
    (labels ((find-next (tree)
               (cond ((complex-node-p tree)
                      (mapc #'find-next (complex-node-children tree)))
                     ((primitive-node-p tree)
                      (let ((pos (primitive-node-position tree)))
                        (when (and (> pos index)
                                   (< pos next-node-index))
                          (setf next-node tree
                                next-node-index pos))))
                     (t (error 'type-error :type-error-datum tree
                                           :type-error-expected-type '(or primitive-node complex-node))))))
      (dolist (tree forest)
        (find-next tree)
        (when (and next-node
                   (= next-node-index (1+ index)))
          (return-from find-next-node next-node)))
      next-node)))
         
(defvar *label-depends*)
(defvar *show-depends*)

(defun graph-enhanced-plan-tree (plan-tree &key 
                                         (graph-object (make-instance 'enhanced-plan-tree-graph))
                                         attributes
                                         label-dependencies
                                         (show-dependencies t))
  "Takes an enhanced SHOP plan tree \(PLAN-TREE\) as input, and returns a CL-DOT graph object."
  (let ((*label-depends* label-dependencies)
        (*show-depends* show-dependencies))
    (cl-dot:generate-graph-from-roots graph-object `(,plan-tree ,@(when show-dependencies '(:init)))
                                      attributes)))


(defmethod cl-dot:graph-object-points-to ((g enhanced-plan-tree-graph)(obj plan-tree:complex-tree-node))
  ;; ugh, cl-dot emits these in reverse order, reversing the left-to-right order of the tree.
  ;; actually, it's even worse than that -- cl-dot emits them in a somewhat random order.
  (plan-tree:complex-tree-node-children obj))

(defmethod cl-dot:graph-object-points-to ((g enhanced-plan-tree-graph)(obj plan-tree:primitive-tree-node))
  nil)

(defmethod cl-dot:graph-object-pointed-to-by ((g enhanced-plan-tree-graph)(obj plan-tree:tree-node))
  (when *show-depends*
   (mapcar #'(lambda (x)
               (let ((est (plan-tree:establisher x)))
                 (assert (typep est '(or (eql :init) plan-tree:primitive-tree-node)))
                 (make-instance 'cl-dot:attributed
                                :object est
                                :attributes `(,(if *label-depends* :label :edgetooltip)
                                              ,(format nil "~a" (plan-tree:prop x))
                                              ,@(when *label-depends* (list :labelfontcolor :blue))
                                              :penwidth 2.0
                                              :style :dashed
                                              ;; don't increase the depth -- cross edge
                                              :constraint nil
                                              :color :blue))))
           (plan-tree:tree-node-dependencies obj))))

(defmethod cl-dot:graph-object-node ((g enhanced-plan-tree-graph) (obj plan-tree:complex-tree-node))
  (declare (ignorable g))
  (make-instance 'cl-dot:node
    :attributes `(:label ,(format nil "~A" (plan-tree:tree-node-task obj))
                         :shape :ellipse)))



(defmethod cl-dot:graph-object-node ((g enhanced-plan-tree-graph) (obj (eql :init)))
  (declare (ignorable g))
  (make-instance 'cl-dot:node
    :attributes `(:label "INIT"
                         :shape :diamond)))

(defmethod cl-dot:graph-object-node ((g enhanced-plan-tree-graph) (obj plan-tree:primitive-tree-node))
  (declare (ignorable g))
  (make-instance 'cl-dot:node
    :attributes `(:label ,(format nil "~A" (plan-tree:tree-node-task obj))
                         :id ,(string (gensym "NODE"))
                         :shape :box)))

(defmethod cl-dot:graph-object-node ((g enhanced-plan-tree-graph) (obj plan-tree:ordered-tree-node))
  (declare (ignorable g))
  (make-instance 'cl-dot:node
    :attributes `(:label "ord" ;;  ,(format nil "~A" (tree-node-task obj))
                         :id ,(string (gensym "NODE"))
                         :shape :rarrow)))

(defmethod cl-dot:graph-object-node ((g enhanced-plan-tree-graph) (obj plan-tree:unordered-tree-node))
  (declare (ignorable g))
  (make-instance 'cl-dot:node
    :attributes `(:label "unord" ;,(format nil "~A" (tree-node-task obj))
                         :shape :diamond)))

