#!/bin/bash

# CONFIG
JULIA_MAJOR_VERSION=1.1
JULIA_MINOR_VERSION=1
JULIA_VERSION=$JULIA_MAJOR_VERSION.$JULIA_MINOR_VERSION
ANACONDA_VERSION=2019.03
CHILI_VERSION=0.5.5

JULIA_DOWNLOAD_URL="https://julialang-s3.julialang.org/bin/linux/x64/$JULIA_MAJOR_VERSION/julia-$JULIA_VERSION-linux-x86_64.tar.gz"
ANACONDA_DOWNLOAD_URL=https://repo.anaconda.com/archive/Anaconda3-$ANACONDA_VERSION-Linux-x86_64.sh
ATOM_URL=https://atom.io/download/deb
STEAM_URL=https://steamcdn-a.akamaihd.net/client/installer/steam.deb
OOMOX_URL=https://github.com/themix-project/oomox/releases/download/1.11/oomox_1.11-3-gde075379_18.10+.deb
CHILI_URL=https://github.com/MarianArlt/kde-plasma-chili/archive/$CHILI_VERSION.tar.gz
CHROME_URL=https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
LIBINPUTGESTURES_URL=http://github.com/bulletmark/libinput-gestures
VLC_ARC_URL=https://github.com/varlesh/VLC-Arc-Dark.git

# Initial
sudo add-apt-repository -y ppa:paulo-miguel-dias/pkppa
sudo add-apt-repository -y ppa:papirus/papirus
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90
echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list

sudo apt update -y
sudo apt upgrade -y
sudo apt dist-upgrade -y
mkdir install_script_files
mkdir install_script_logs

# Anaconda + Julia
sudo apt install -y git curl wget vim zsh ffmpeg gfortran perl m4 cmake pkg-config

wget $ANACONDA_DOWNLOAD_URL -O install_script_files/anaconda3.sh
chmod +x install_script_files/anaconda3.sh
echo -n "Installing Anaconda... "
./install_script_files/anaconda3.sh -b -p $HOME/.local/opt/anaconda3 > install_script_logs/anaconda.log
echo "Done"
echo -e "\n# CUSTOM\n" >> $HOME/.profile
echo "PATH=\"$HOME/.local/opt/anaconda3/bin:\$PATH\"" >> $HOME/.profile
source $HOME/.profile

# Julia
wget $JULIA_DOWNLOAD_URL -O install_script_files/julia.tar.gz
tar xvzf install_script_files/julia.tar.gz -C install_script_files
sudo mv install_script_files/julia-$JULIA_VERSION /opt/julia-$JULIA_VERSION
sudo ln -s /opt/julia-$JULIA_VERSION/bin/julia /usr/local/bin/julia
echo "Precompiling Julia packages (in background)"
julia -e "
  using Pkg;
  pkg\"up; add Plots IJulia GLM PackageCompiler DifferentialEquations SafeTestsets VisualRegressionTests DiffEqProblemLibrary UnicodePlots LaTeXStrings Images RDatasets\";
  using Plots, IJulia, PackageCompiler, DifferentialEquations;

  cp(joinpath(dirname(Pkg.Types.find_project_file()), \"Manifest.toml\"),
    PackageCompiler.sysimg_folder(\"Manifest.toml\"), force = true
  );
  PackageCompiler.compile_incremental(:Plots, force = true);

  # Make sure system image actually got replaced!
  x = PackageCompiler.sysimg_folder(\"sys.so\");
  y = unsafe_string(Base.JLOptions().image_file);

  # for some reason, compile_incremental(force = true) doesn't always work
  # but also doesn't throw any error... Filesystem problems?!
  if read(x) != read(y)
    cp(x, y, force = true);
  end
  @assert read(x) == read(y);
  " &> install_script_logs/julia.log &
JULIA_PID=$!

# Misc
sudo apt install -y texlive-latex-extra chktex latexmk texlive-lang-spanish texlive-luatex spotify-client libreoffice-style-papirus arc-theme bzr libgdk-pixbuf2.0-dev parallel sassc libsass1 imagemagick optipng librsvg2-bin inkscape python3-pystache virtualbox xdotool wmctrl libinput-tools mesa-vulkan-drivers mesa-vulkan-drivers:i386

# Themes
sudo apt install --install-recommends -y arc-kde
wget $OOMOX_URL -O install_script_files/oomox.deb
sudo dpkg -i ./install_script_files/oomox.deb
sudo apt install -f -y
mkdir $HOME/.config/oomox
sudo oomoxify-cli /opt/oomox/colors/Modern/arc-dark
wget $CHILI_URL -O install_script_files/chili.tar.gz
tar -xzvf install_script_files/chili.tar.gz
sudo mv kde-plasma-chili-$CHILI_VERSION /usr/share/sddm/themes/chili
kwriteconfig5 --group Icons --key Theme Papirus-Dark
kwriteconfig5 --file /etc/sddm.conf --group Theme --key Current chili
kvantummanager --set ArcDark
git clone $VLC_ARC_URL install_script_files/VLC-Arc-Dark
sudo make -C install_script_files/VLC-Arc-Dark install
kwriteconfig5 --file $HOME/.config/vlc/vlcrc --group skins2 --key skins2-last /usr/share/vlc/skins2/Arc-Dark.vlt

# Trackpad gestures
sudo gpasswd -a $USER input
git clone $LIBINPUTGESTURES_URL install_script_files/libinput-gestures
sudo make -C install_script_files/libinput-gestures/ install
echo "
gesture swipe up	3 _internal ws_up
gesture swipe down	3 _internal ws_down
gesture swipe up 	4 xdotool key control+F9
gesture swipe down 	4 xdotool key control+F8
gesture swipe right xdotool key control+Tab
gesture swipe left xdotool key control+shift+Tab
gesture pinch in	xdotool key ctrl+minus
gesture pinch out	xdotool key ctrl+plus
" > $HOME/.config/libinput-gestures.conf
libinput-gestures-setup autostart
libinput-gestures-setup start


# Atom
wget $ATOM_URL -O install_script_files/atom.deb
sudo apt install -y ./install_script_files/atom.deb
apm install autocomplete-paths file-icons highlight-selected language-julia language-markdown language-latex latex latex-autocomplete linter linter-ui-default linter-chktex markdown-preview-plus minimap multi-cursor-plus pdf-view uber-juno intentions busy-signal

# Steam
wget $STEAM_URL -O install_script_files/steam.deb
sudo apt install -y ./install_script_files/steam.deb

# Chrome
wget $CHROME_URL -O install_script_files/chrome.deb
sudo apt install -y ./install_script_files/chrome.deb

wait $JULIA_PID
echo "Julia package precompilation done"

echo "

Don't forget to
  Set Plasma/GTK theme to Arc-Dark
  Set Konsole theme to Arc-Dark
  Set Firefox theme to https://color.firefox.com/?theme=XQAAAAIUAQAAAAAAAABBqYhm849SCia2CaaEGccwS-xNKliFvYTiriGIWtvzG8yVBhZMc4tznNRAY1XP53yuRU1rEkCfk82_rToimNHl84iQW5gSoTeeK12J1Z4WVeLT6sRNchfzW2W4Z_l4KX9wHqY8Zf9wpiZlBohC65XxdZEOXAKucJQZbpcQSLdCnLHPivNDQdS-V8WlWmEHGRvbI6QBAouZzvgOe895MFjtBMw28vImDNDLcgGq1HCg0ggX6xTt2NY5E568_vY1YA
  Install and enable Sticky Window Snapping https://store.kde.org/p/1112552/
  Configure zsh and run zsh_config.sh
"
rm -rf install_script_files
