extends Control
## BootScreen.gd
## Purely presentational. All real boot logic (loading the save file,
## deciding the first state) lives in GameManager, which is an autoload and
## therefore already running before this scene's _ready() fires.
