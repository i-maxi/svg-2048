(require 'esxml)

(defvar svg-animation-demo-interval (/ 1.0 50))

(defvar svg-animation-demo-state
  `((:x 0 :y 0 :type static :layer foreground
        :frames 10.0 :frame 0 :msecs 500
        :beg-x 0 :beg-y 0
        :end-x 240 :end-y 0)
    (:type board :layer background)
    ,@(cl-loop for i from 0 to 3 collect
               `(:x ,i :y 0 :type background :layer background))))

(defun svg-animation-demo-render-state (plist)
  (let ((board-color "#aaaaaa")
        (tile-color "#cccccc")
        (tile-size 64)
        (padding 16)
        (offset 12)
        (roundness 8))
    (sxml-to-xml
     (cond
      ((eq (plist-get plist :type) 'board)
       `(rect
         (@ (width ,(number-to-string (+ (* 4 tile-size) (* 5 padding))))
            (height ,(number-to-string (+ (* 1 tile-size) (* 2 padding))))
            (x ,(number-to-string offset))
            (y ,(number-to-string offset))
            (rx ,(number-to-string roundness))
            (fill ,board-color))))
      ((eq (plist-get plist :type) 'background)
       `(rect
         (@ (width ,(number-to-string tile-size))
            (height ,(number-to-string tile-size))
            (x ,(number-to-string
                 (+ (* (plist-get plist :x) tile-size)
                    (* (1+ (plist-get plist :x)) padding) offset)))
            (y ,(number-to-string
                 (+ (* (plist-get plist :y) tile-size)
                    (* (1+ (plist-get plist :y)) padding) offset)))
            (rx ,(number-to-string (/ roundness 2)))
            (fill ,tile-color))))
      ((eq (plist-get plist :type) 'static)
       `(rect
         (@ (width ,(number-to-string tile-size))
            (height ,(number-to-string tile-size))
            (x ,(number-to-string (+ padding offset (plist-get plist :x))))
            (y ,(number-to-string (+ padding offset (plist-get plist :y))))
            (rx ,(number-to-string (/ roundness 2)))
            (fill "#0000aa"))))
      ((eq (plist-get plist :type) 'moving)
       `(rect
         (@ (width ,(number-to-string tile-size))
            (height ,(number-to-string tile-size))
            (x ,(number-to-string
                 (+ padding offset
                    (* (/ (plist-get plist :frame)
                          (plist-get plist :frames))
                       (- (plist-get plist :end-x)
                          (plist-get plist :beg-x))))))
            (y ,(number-to-string
                 (+ padding offset
                    (* (/ (plist-get plist :frame)
                          (plist-get plist :frames))
                       (- (plist-get plist :end-y)
                          (plist-get plist :beg-y))))))
            (rx ,(number-to-string (/ roundness 2)))
            (fill "#aa0000"))))
      (t nil)))))

(defun svg-animation-demo-create-svg ()
  (sxml-to-xml
   `(svg
     (@ (xmlns "http://www.w3.org/2000/svg") (width "360") (height "120"))
     (g ,@(cl-loop for plist in svg-animation-demo-state
                   when (eq (plist-get plist :layer) 'background)
                   collect
                   (svg-animation-demo-render-state plist)))
     (g ,@(cl-loop for plist in svg-animation-demo-state
                   when (eq (plist-get plist :layer) 'foreground)
                   collect
                   (svg-animation-demo-render-state plist))))))

(defun svg-animation-demo-init ()
  (interactive)
  (setcar svg-animation-demo-state
          (plist-put (car svg-animation-demo-state) :type 'static))
  (svg-animation-demo-redraw))

(defun svg-animation-demo-redraw ()
  (interactive)
  (setq buffer-read-only nil)
  (erase-buffer)
  (insert-image (create-image (svg-animation-demo-create-svg) 'svg t))
  (insert "\n")
  (setq buffer-read-only t))

(defun svg-animation-demo-begin ()
  (interactive)
  (svg-animation-demo-init)
  (svg-animation-demo-redraw))

(define-derived-mode svg-animation-demo-mode special-mode "SVG Animation Demo"
  "A SVG animation demo."
  (with-current-buffer (get-buffer "*svg animation demo*")
    (buffer-disable-undo)
    (svg-animation-demo-begin)))

(defun svg-animation-demo ()
  "Start the animation demo"
  (interactive)
  (switch-to-buffer "*svg animation demo*")
  (svg-animation-demo-mode)
  (goto-char (point-max)))

(defun svg-animation-demo-move ()
  (interactive)
  (setcar svg-animation-demo-state
          (plist-put (car svg-animation-demo-state) :type 'moving))
  (setcar svg-animation-demo-state
          (plist-put (car svg-animation-demo-state) :frame 0))
  (while (< (plist-get (car svg-animation-demo-state) :frame)
            (plist-get (car svg-animation-demo-state) :frames))
    (svg-animation-demo-redraw)
    (sit-for svg-animation-demo-interval)
    (setcar svg-animation-demo-state
            (plist-put (car svg-animation-demo-state) :frame
                       (1+ (plist-get (car svg-animation-demo-state) :frame)))))
  (svg-animation-demo-redraw)
  (setcar svg-animation-demo-state
          (plist-put (car svg-animation-demo-state) :frame 0)))

(define-key svg-animation-demo-mode-map (kbd "g") 'svg-animation-demo-redraw)
(define-key svg-animation-demo-mode-map (kbd "i") 'svg-animation-demo-init)
(define-key svg-animation-demo-mode-map (kbd "m") 'svg-animation-demo-move)