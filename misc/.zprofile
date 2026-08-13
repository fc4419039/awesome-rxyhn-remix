# SDDM ejecuta la sesión como zsh --login, y con zsh NO se lee ~/.profile
# (solo ~/.zprofile). Aquí va el PATH para que la sesión (y Awesome) vean
# los scripts de ~/.local/bin.
export PATH="$HOME/.local/bin:$PATH"
