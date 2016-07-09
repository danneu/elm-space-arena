
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

## Development

Start the hot-reloading webpack dev server:

    npm start

Navigate to <http://localhost:8080>.

Any changes you make to your files (.elm, .js, .css, etc.) will trigger
a hot reload.

## Production

When you're ready to deploy:

    npm run build

This will create a `dist` folder:

    .
    ├── dist
    │   ├── index.html 
    │   ├── 5df766af1ced8ff1fe0a.css
    │   └── 5df766af1ced8ff1fe0a.js

