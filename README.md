
# elm-space-arena

- Live demo: <https://www.danneu.com/elm-space-arena>

A sloppy 2D spaceship shooter built with Elm to explore game development.

It's a work-in-progress with shameful code.

## Clone

    $ git clone https://github.com/danneu/elm-space-arena.git
    $ cd elm-space-arena
    $ npm install
    $ elm make
    $ npm start
    Dev server running on <http://localhost:8080>

## Technical Notes

- `(x, y)` starts at the top-left.
  `x` increases going right, `y` increases going down.
- `position` is always the center of an entity.
-  Deploys to gh-pages branch done with https://github.com/X1011/git-directory-deploy

## Optimization Notes

- `obj.visible = false` means container and all of its children's matrices
  won't be updated.
- `obj.renderable = false` means that the container will be updated but
  not rendered (use for culling).
- `texture = Texture.EMPTY` has no special cases. Sprite is rendered anyway.
