# SDDM ejecuta la sesión como zsh --login. Con SHELL=zsh, Xsession NO lee
# ~/.profile (solo ~/.zprofile), así que el PATH de ~/.local/bin va aquí
# para que Awesome y todo lo que spawna encuentre los scripts de bin/.
export PATH="$HOME/.local/bin:$PATH"
