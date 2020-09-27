(cl:defpackage #:gir-test-web
  (:use #:cl ;; #:trivial-main-thread
        ))
(in-package #:gir-test-web)

(defvar *gtk* (gir:ffi "Gtk"))
(defvar *gdk* (gir:ffi "Gdk"))
(defvar *webkit* (gir:require-namespace "WebKit2"))

(cffi:defcallback hello :void ((btn-ptr :pointer))
  (let ((button (gir::build-object-ptr (gir:nget *gtk* "Button") btn-ptr)))
    (setf (gir:property button 'label) "OK"))
  (format t "Hello, pressed~%"))

(defun event->key (ev)
  (let ((k (gir:field ev "keyval"))
        (state (gir:field ev "state"))
        (modifiers (list)))
    (dolist (mdef '((#b1    :shift)
                    (#b100  :ctrl)
                    (#b1000 :alt)))
      (destructuring-bind (int modifier)
          mdef
        (unless (zerop (logand int state))
          (push modifier modifiers))))
    (values (case k
              (65361 :left-arrow)
              (65362 :up-arrow)
              (65363 :right-arrow)
              (65364 :down-arrow)
              (otherwise k))
            modifiers)))

(defun main ()
  (gir:invoke (*gtk* 'init) nil)
  (let ((window (gir:invoke (*gtk* "Window" 'new)
                            (gir:nget *gtk* "WindowType" :toplevel)))
        (view (gir:invoke (*webkit* "WebView" 'new)))
        (button (gir:invoke (*gtk* "Button" 'new-with-label) "Hello, world!"))
        (button2 (gir:invoke (*gtk* "Button" 'new-with-label) "Dummy!"))
        (box (gir:invoke (*gtk* "Box" 'new) (gir:nget *gtk* "Orientation" :vertical) 0)))
    (gir:invoke (window 'set_default_size) 800 600)
    (gir::g-signal-connect-data (gir::this-of window)
                                "destroy"
                                (cffi:foreign-symbol-pointer "gtk_main_quit")
                                (cffi:null-pointer)
                                (cffi:null-pointer)
                                0)
    (gir:connect window :key-press-event
                 (lambda (widget event)
                   (declare (ignore widget))
                   (let ((event-object
                          (gir::build-struct-ptr (gir:nget *gdk* "EventKey")
                                                 event)))
                     (print  (event->key event-object)))))
    (gir:connect button :clicked
                 (lambda (button)
                   (setf (gir:property button 'label) "OK")))
    (gir:invoke (view 'load_uri) "https://www.w3schools.com/jsref/tryit.asp?filename=tryjsref_print")
    (gir:invoke (box 'add) button)
    (gir:invoke (box 'pack-start) view t t 100)
    (gir:invoke (box 'add) button2)
    (gir:invoke (window 'add) box)
    (gir:invoke (window 'show-all))

    (gir:invoke (*gtk* 'main))))

;; (trivial-main-thread:call-in-main-thread #'main)
