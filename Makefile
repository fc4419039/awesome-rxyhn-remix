# AwesomeWM Remix - Makefile Portable
# Uso: make install          # Detecta distro e instala deps + config
#      make deps             # Solo instala dependencias
#      make deploy           # Solo despliega config (sin deps)
#      make update-modules   # Actualiza bling, rubato, layout-machi
#      make check            # Valida sintaxis Lua/Shell/Python
#      make test             # Test runtime de la config
#      make clean            # Limpia cache y state files

# ==================== DETECCIÓN DE DISTRO ====================
DISTRO_ID := $(shell . /etc/os-release 2>/dev/null && echo $$ID)
DISTRO_LIKE := $(shell . /etc/os-release 2>/dev/null && echo $$ID_LIKE)
DISTRO_NAME := $(shell . /etc/os-release 2>/dev/null && echo $$NAME)
SUDO := $(if $(filter root,$(shell id -un 2>/dev/null)),,sudo)

# Mapeo de distro -> archivo de deps
ifeq ($(DISTRO_ID),arch)
    DEPS_FILE := docs/deps-arch.txt
    PKG_INSTALL := pacman -S --needed --noconfirm
    AUR_HELPER := $(shell command -v paru 2>/dev/null || command -v yay 2>/dev/null || echo "")
endif
ifeq ($(DISTRO_ID),manjaro)
    DEPS_FILE := docs/deps-arch.txt
    PKG_INSTALL := pacman -S --needed --noconfirm
    AUR_HELPER := $(shell command -v pamac 2>/dev/null || command -v paru 2>/dev/null || command -v yay 2>/dev/null || echo "")
endif
ifeq ($(DISTRO_ID),endeavouros)
    DEPS_FILE := docs/deps-arch.txt
    PKG_INSTALL := pacman -S --needed --noconfirm
    AUR_HELPER := $(shell command -v paru 2>/dev/null || command -v yay 2>/dev/null || echo "")
endif
ifeq ($(DISTRO_ID),ubuntu)
    DEPS_FILE := docs/deps-debian.txt
    PKG_INSTALL := apt-get update && apt-get install -y
endif
ifeq ($(DISTRO_ID),debian)
    DEPS_FILE := docs/deps-debian.txt
    PKG_INSTALL := apt-get update && apt-get install -y
endif
ifeq ($(DISTRO_ID),linuxmint)
    DEPS_FILE := docs/deps-debian.txt
    PKG_INSTALL := apt-get update && apt-get install -y
endif
ifeq ($(DISTRO_ID),pop)
    DEPS_FILE := docs/deps-debian.txt
    PKG_INSTALL := apt-get update && apt-get install -y
endif
ifeq ($(DISTRO_ID),fedora)
    DEPS_FILE := docs/deps-fedora.txt
    PKG_INSTALL := dnf install -y
endif
ifeq ($(DISTRO_ID),rhel)
    DEPS_FILE := docs/deps-fedora.txt
    PKG_INSTALL := dnf install -y
endif
ifeq ($(DISTRO_ID),centos)
    DEPS_FILE := docs/deps-fedora.txt
    PKG_INSTALL := dnf install -y
endif
ifeq ($(DISTRO_ID),opensuse-tumbleweed)
    DEPS_FILE := docs/deps-opensuse.txt
    PKG_INSTALL := zypper install -y
endif
ifeq ($(DISTRO_ID),opensuse-leap)
    DEPS_FILE := docs/deps-opensuse.txt
    PKG_INSTALL := zypper install -y
endif
ifeq ($(DISTRO_ID),nixos)
    DEPS_FILE := docs/deps-nixos.txt
    PKG_INSTALL := echo "NixOS: usa home-manager / configuration.nix (ver docs/deps-nixos.txt)"
endif

# Fallback genérico por ID_LIKE
ifndef DEPS_FILE
    ifneq (,$(findstring arch,$(DISTRO_LIKE)))
        DEPS_FILE := docs/deps-arch.txt
        PKG_INSTALL := pacman -S --needed --noconfirm
        AUR_HELPER := $(shell command -v paru 2>/dev/null || command -v yay 2>/dev/null || echo "")
    endif
    ifneq (,$(findstring debian,$(DISTRO_LIKE)))
        DEPS_FILE := docs/deps-debian.txt
        PKG_INSTALL := apt-get update && apt-get install -y
    endif
    ifneq (,$(findstring fedora,$(DISTRO_LIKE)))
        DEPS_FILE := docs/deps-fedora.txt
        PKG_INSTALL := dnf install -y
    endif
    ifneq (,$(findstring opensuse,$(DISTRO_LIKE)))
        DEPS_FILE := docs/deps-opensuse.txt
        PKG_INSTALL := zypper install -y
    endif
endif

# Si no se detectó nada
ifndef DEPS_FILE
    DEPS_FILE := docs/deps-arch.txt
    PKG_INSTALL := echo "Distro no detectada. Instala manualmente desde $(DEPS_FILE)"
    UNSUPPORTED := 1
endif

# ==================== VARIABLES ====================
CONFIG_SRC := config/awesome
CONFIG_DST := $(HOME)/.config/awesome
SCRIPTS_SRC := config/awesome/scripts
BIN_SRC := bin
BIN_DST := $(HOME)/.local/bin
FONDOS_SRC := fondos
FONDOS_DST := $(HOME)/fondos
FONTS_SRC := fonts
FONTS_DST_USER := $(HOME)/.local/share/fonts
FONTS_DST_SYSTEM := /usr/share/fonts
MISC_SRC := misc
SDDM_SRC := sddm
SUDO := sudo

# ==================== TARGETS ====================
.PHONY: all install deps deploy update-modules check test clean help fonts sddm zsh mscdown fondos dirs

all: install

help:
	@echo "AwesomeWM Remix - Makefile Portable"
	@echo ""
	@echo "Distro detectada: $(DISTRO_NAME) ($(DISTRO_ID))"
	@echo "Archivo de deps:  $(DEPS_FILE)"
	@echo ""
	@echo "Targets:"
	@echo "  make install          # Instala deps + despliega config completa"
	@echo "  make deps             # Solo instala dependencias del sistema"
	@echo "  make deploy           # Solo despliega config (rsync + permisos)"
	@echo "  make update-modules   # Actualiza bling, rubato, layout-machi desde upstream"
	@echo "  make check            # Valida sintaxis (luac, bash -n, python3 -m py_compile)"
	@echo "  make test             # Test runtime: awesome -c rc.lua"
	@echo "  make clean            # Limpia cache, state files, backups"
	@echo "  make fonts            # Instala fuentes (usuario + sistema)"
	@echo "  make sddm             # Configura tema SDDM (requiere sudo)"
	@echo "  make zsh              # Instala .zshrc + powerlevel10k"
	@echo "  make mscdown          # Instala MSCDown (music downloader)"
	@echo ""

# ==================== INSTALACIÓN COMPLETA ====================
install: deps deploy fonts sddm zsh mscdown
	@echo ""
	@echo "═══════════════════════════════════════════"
	@echo "  ¡Instalación completada!"
	@echo "  Distro: $(DISTRO_NAME)"
	@echo "  Config: $(CONFIG_DST)"
	@echo "═══════════════════════════════════════════"
	@echo ""
	@echo "Próximos pasos:"
	@echo "  1. source ~/.zshrc"
	@echo "  2. Reinicia sesión o: awesome -c ~/.config/awesome/rc.lua"
	@echo "  3. Super+Ctrl+R para recargar AwesomeWM"

# ==================== SOLO DEPENDENCIAS ====================
deps:
	@echo "=== Instalando dependencias para $(DISTRO_NAME) ==="
	@echo "Archivo: $(DEPS_FILE)"
	@if [ "$(UNSUPPORTED)" = "1" ]; then \
		echo "⚠ Distro no soportada automáticamente."; \
		echo "Instala manualmente los paquetes listados en $(DEPS_FILE)"; \
		exit 1; \
	fi
	@if [ "$(DISTRO_ID)" = "nixos" ]; then \
		echo "NixOS detectado: usa Home Manager / flake.nix"; \
		echo "Ver $(DEPS_FILE) para configuración declarativa"; \
		exit 0; \
	fi
	@if [ -n "$(AUR_HELPER)" ]; then \
		echo "AUR Helper: $(AUR_HELPER)"; \
		$(AUR_HELPER) -S --needed --noconfirm $$(grep -v '^#' $(DEPS_FILE) | grep -v '^$$' | sed 's/#.*//' | tr '\n' ' '); \
	else \
		$(SUDO) sh -c "$(PKG_INSTALL) $$(grep -v '^#' $(DEPS_FILE) | grep -v '^$$' | sed 's/#.*//' | tr '\n' ' ')"; \
	fi
	@echo "✓ Dependencias instaladas"

# ==================== DESPLIEGUE DE CONFIG ====================
deploy:
	@echo "=== Desplegando configuración ==="
	@mkdir -p $(HOME)/.config
	@rsync -av --exclude='.git' --exclude='.codebak' --exclude='*.log' --exclude='*.state' config/ $(HOME)/.config/
	@rm -rf $(CONFIG_DST)/.codebak
	@if [ -d "$(BIN_SRC)" ] && [ "$$(ls -A $(BIN_SRC))" ]; then \
		mkdir -p $(BIN_DST); \
		cp -r $(BIN_SRC)/* $(BIN_DST)/; \
		chmod +x $(BIN_DST)/*; \
	fi
	@chmod +x $(HOME)/.config/awesome/scripts/* 2>/dev/null || true
	@if [ -f $(HOME)/.config/awesome/configuration/autostart ]; then \
		chmod +x $(HOME)/.config/awesome/configuration/autostart; \
	fi
	@if [ -f $(HOME)/.config/cambiar_fondo.sh ]; then \
		chmod +x $(HOME)/.config/cambiar_fondo.sh; \
	fi
	@if [ -f $(HOME)/.config/limpiar_sistema.sh ]; then \
		chmod +x $(HOME)/.config/limpiar_sistema.sh; \
	fi
	@if [ -f $(CONFIG_SRC)/secrets.lua.template ] && [ ! -f $(CONFIG_DST)/secrets.lua ]; then \
		cp $(CONFIG_SRC)/secrets.lua.template $(CONFIG_DST)/secrets.lua; \
		echo "✓ secrets.lua generado desde template"; \
	fi
	@echo "✓ Configuración desplegada"

# ==================== FUENTES ====================
fonts:
	@echo "=== Instalando fuentes ==="
	@if [ -d "$(FONTS_SRC)" ] && [ "$$(ls -A $(FONTS_SRC))" ]; then \
		mkdir -p $(FONTS_DST_USER); \
		cp -r $(FONTS_SRC)/* $(FONTS_DST_USER)/; \
		echo "✓ Fuentes en $(FONTS_DST_USER)"; \
		fc-cache -fv $(FONTS_DST_USER) >/dev/null 2>&1; \
		$(SUDO) mkdir -p $(FONTS_DST_SYSTEM); \
		$(SUDO) cp -r $(FONTS_SRC)/* $(FONTS_DST_SYSTEM)/ 2>/dev/null && \
			$(SUDO) fc-cache -fv $(FONTS_DST_SYSTEM) >/dev/null 2>&1 && \
			echo "✓ Fuentes en $(FONTS_DST_SYSTEM)" || \
			echo "⚠ No se pudieron instalar en sistema (sin sudo)"; \
	else \
		echo "⚠ Carpeta fonts vacía"; \
	fi

# ==================== FONDOS ====================
fondos:
	@echo "=== Instalando fondos ==="
	@mkdir -p $(FONDOS_DST)
	@if [ -d "$(FONDOS_SRC)" ] && [ "$$(ls -A $(FONDOS_SRC))" ]; then \
		cp -rf $(FONDOS_SRC)/* $(FONDOS_DST)/; \
		echo "✓ Fondos en $(FONDOS_DST)"; \
	else \
		echo "⚠ Carpeta fondos vacía"; \
	fi

# ==================== SDDM ====================
sddm:
	@echo "=== Configurando SDDM ==="
	@bash setup-sddm-theme.sh

# ==================== ZSH ====================
zsh:
	@echo "=== Configurando Zsh ==="
	@if [ -f .zshrc ]; then \
		if [ -f $(HOME)/.zshrc ]; then \
			cp $(HOME)/.zshrc $(HOME)/.zshrc.bak.$$(date +%s); \
		fi; \
		cp .zshrc $(HOME)/; \
		echo "✓ .zshrc instalado"; \
	fi
	@if ! grep -q "TODO_PATH" $(HOME)/.zshrc 2>/dev/null; then \
		echo "" >> $(HOME)/.zshrc; \
		echo "# AwesomeWM Remix" >> $(HOME)/.zshrc; \
		echo 'export TODO_PATH="$$HOME/.config/todo"' >> $(HOME)/.zshrc; \
	fi
	@if [ -f $(MISC_SRC)/.p10k.zsh ] && [ ! -f $(HOME)/.p10k.zsh ]; then \
		cp $(MISC_SRC)/.p10k.zsh $(HOME)/.p10k.zsh; \
		echo "✓ .p10k.zsh instalado"; \
	fi
	@if [ -f $(MISC_SRC)/.Xresources ]; then \
		cp $(MISC_SRC)/.Xresources $(HOME)/.Xresources; \
		echo "✓ .Xresources instalado"; \
	fi
	@if [ -f $(MISC_SRC)/.zprofile ]; then \
		cp $(MISC_SRC)/.zprofile $(HOME)/.zprofile; \
		echo "✓ .zprofile instalado"; \
	fi

# ==================== MSCDOWN ====================
mscdown:
	@echo "=== Instalando MSCDown ==="
	@if [ -f mscdown/install.sh ]; then \
		chmod +x mscdown/install.sh; \
		cd mscdown && ./install.sh; \
		echo "✓ MSCDown instalado"; \
	else \
		echo "⚠ MSCDown no encontrado (git submodule update --init)"; \
	fi

# ==================== ACTUALIZAR MÓDULOS ====================
update-modules:
	@echo "=== Actualizando módulos externos ==="
	@bash update_modules.sh
	@echo "✓ Módulos actualizados (revisa con git diff)"

# ==================== VALIDACIÓN SINTAXIS ====================
check:
	@echo "=== Validando sintaxis ==="
	@bash $(CONFIG_DST)/scripts/check.sh --syntax

# ==================== TEST RUNTIME ====================
test:
	@echo "=== Test runtime AwesomeWM ==="
	@awesome -k -c $(CONFIG_DST)/rc.lua 2>&1 | head -20 || true
	@echo "Si no hay errores arriba, la config es válida"

# ==================== LIMPIEZA ====================
clean:
	@echo "=== Limpiando ==="
	@rm -rf $(CONFIG_DST)/.codebak
	@rm -f $(CONFIG_DST)/.datetime-widget-*
	@rm -f $(CONFIG_DST)/.desktop-music-pos-*
	@rm -f $(CONFIG_DST)/.desktop-sysmon-pos-*
	@rm -f $(CONFIG_DST)/.color_temp_prefs
	@rm -f /tmp/awesome-*.log
	@rm -f /tmp/lockscreen-*.log
	@rm -f /tmp/bt_map.* /tmp/co-map.* /tmp/wifi_*.tmp /tmp/cb_map.*
	@rm -rf ~/.cache/opencode
	@echo "✓ Limpieza completada"

# ==================== DIRECTORIOS ====================
dirs:
	@mkdir -p $(CONFIG_DST)
	@mkdir -p $(BIN_DST)
	@mkdir -p $(FONTS_DST_USER)
	@mkdir -p $(FONDOS_DST)
	@mkdir -p $(HOME)/.config/todo
	@mkdir -p $(HOME)/.config/mpd/playlists
	@mkdir -p $(HOME)/Music