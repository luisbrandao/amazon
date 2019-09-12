#!/bin/bash
# ---------------------------------------------------------------------------------------------------------------------
# ------------------------------------------------------[ Configuração ]-----------------------------------------------
temp=$(mktemp -t dnfInstall.XXXX)                                       # Arquivo temporário
devel="yes"                                                              # Instala coisas do pseudogrupo "devel"
update_kernel="yes"                                                     # Deixa o dnf atualizar o kernel
mate="no"                                                               # Instala coisas supondo que o ambiente gráfico é o mate
kde="no"                                                               # Kde vai ser instalado
jogos="no"                                                             # Instala os jogos básicos
steam="no"                                                              # Instala a steam
repos=""                                                                # Inicia a variável
pacotes=""                                                              # Inicia a variável
# ------------------------------------------------------[ Configuração ]-----------------------------------------------
# ---------------------------------------------------------------------------------------------------------------------
# Checa SELINUX ========================================================================================================================
if [ -f $(cat /etc/selinux/config | grep 'SELINUX=disabled') ] ; then
	echo "SELINUX Ativado!"
	echo "Deactive and reboot"
	echo "vim /etc/selinux/config"

	exit 1
fi

# Desabilita Programas inuteis no boot =====================================================================================================
systemctl mask dm-event.service
systemctl mask dm-event.socket
systemctl mask mdmonitor.service
systemctl mask mdmonitor-takeover.service
systemctl mask firewalld.service
systemctl mask pcscd.service
systemctl mask ModemManager.service
systemctl disable bolt.service

# Preparação do dnf ========================================================================================================================
if [ -f $(cat /etc/dnf/dnf.conf | grep clean_requirements_on_remove) ] ; then
  echo "Configurando dnf"
  echo "clean_requirements_on_remove=true" >> /etc/dnf/dnf.conf
	echo "deltarpm=0" >> /etc/dnf/dnf.conf
fi

# Seta o timezone ===========================================================================================================
ln -sf ../usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Gambi do vim =============================================================================================================================
rpm -ev --nodeps vim-minimal
dnf install -y vim

# Instalação dos repositorios: =============================================================================================================
fedoraVersion=29

repos=""
repos="${repos} http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedoraVersion}.noarch.rpm"
repos="${repos} http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedoraVersion}.noarch.rpm"
repos="${repos} http://rpms.famillecollet.com/fedora/remi-release-${fedoraVersion}.rpm"
repos="${repos} http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm"
repos="${repos} http://mirror.yandex.ru/fedora/russianfedora/russianfedora/free/fedora/russianfedora-free-release-stable.noarch.rpm"
repos="${repos} http://mirror.yandex.ru/fedora/russianfedora/russianfedora/nonfree/fedora/russianfedora-nonfree-release-stable.noarch.rpm"
dnf -y install --nogpgcheck ${repos}

dnf config-manager --add-repo=https://download.docker.com/linux/fedora/docker-ce.repo
dnf config-manager --add-repo=https://techmago.sytes.net/rpm/google-chrome.repo
dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
dnf config-manager --add-repo=http://negativo17.org/repos/fedora-negativo17.repo
dnf config-manager --set-enabled remi
dnf config-manager --disable fedora-bitcoin fedora-cdrtools fedora-flash-plugin fedora-games fedora-multimedia fedora-nvidia fedora-rar fedora-spotify fedora-steam fedora-uld

dnf -y install --nogpgcheck ${repos}
dnf -y update

# Fazer o cache do dnf =====================================================================================================================
dnf clean all
dnf makecache

# Remove porcarias: ========================================================================================================================
dnf -y remove abrt dracut-config-rescue irqbalance mcelog open-vm-tools sendmail spice-vdagent iscsi-initiator-utils libvirt-client tigervl vinagre selinux-policy audit httpd tigervnc firstboot hexchat claws-mail exaile parole orca

# Reinstala o que nao devia ter saido
dnf -y install dracut binutils dmidecode isomd5sum nfs-utils

# Instala o necessário:
# Atualiza =================================================================================================================================
if [ "${update_kernel}" = yes ]; then
        dnf -y update
fi

# Utilidades ===============================================================================================================================
pacotes="${pacotes} zlib unrar bzip2 freetype-freeworld xz-lzma-compat xz p7zip p7zip-plugins lzip cabextract"
pacotes="${pacotes} htop iotop iftop pydf bmon pydf inxi nload"
pacotes="${pacotes} ntpdate fortune-mod gnome-disk-utility terminator"
pacotes="${pacotes} pigz pxz pbzip2"


if [ "${kde}" = yes ]; then
	pacotes="${pacotes} kde-plasma-akonadi-calendars kde-plasma-translatoid kde-plasma-ktorrent kde-plasma-yawp"
	pacotes="${pacotes} kde-plasma-alsa-volume kde-plasma-daisy kde-plasma-yawp kde-plasma-nm kde-plasma-activitymanager"
	pacotes="${pacotes} kde-plasma-folderview kde-plasma-ktorrent kde-plasma-nm kde-plasma-publictransport"
	pacotes="${pacotes} kde-plasma-qstardict kde-plasma-quickaccess kmymoney"
	pacotes="${pacotes} gnome-system-monitor"
fi
if [ "${devel}" = yes ]; then
	pacotes="${pacotes} unison sshfs byobu nfs-utils "
fi
if [ "${mate}" = yes ]; then
	pacotes="${pacotes} mate-applets mate-screensaver mate-themes mate-menu-editor mate-sensors-applet"
fi
if [$(rpm -q gnome-session > /dev/null) $? -eq 0 ]; then
	pacotes="${pacotes} nautilus-dropbox nautilus-open-terminal evince-nautilus easytag-nautilus nextcloud-client-nautilus"
	pacotes="${pacotes} gnome-tweak-tool chrome-gnome-shell"
fi

# Internet =================================================================================================================================
pacotes="${pacotes} transmission filezilla"
pacotes="${pacotes} flash-plugin firefox google-chrome-stable"
pacotes="${pacotes} mirall pidgin youtube-dl purple-plugin_pack-pidgin"
pacotes="${pacotes} thunderbird thunderbird-lightning"

# Multimidia ===============================================================================================================================
pacotes="${pacotes} mplayer smplayer"
pacotes="${pacotes} gstreamer-plugins-bad gstreamer-plugins-ugly gstreamer-ffmpeg"
pacotes="${pacotes} gstreamer1-plugins-ugly gstreamer1-libav"
pacotes="${pacotes} rhythmbox pitivi cheese"
pacotes="${pacotes} brasero"

# Jogos ====================================================================================================================================
if [ "${jogos}" = yes ]; then
	pacotes="${pacotes} five-or-more four-in-a-row gnome-klotski gnome-mahjongg gnome-nibbles gnome-robots aisleriot"
	pacotes="${pacotes} gnome-tetravex lightsoff quadrapassel tali  gnome-mines gnome-sudoku iagno swell-foop"
fi
if [ "${steam}" = yes ]; then
	pacotes="${pacotes} steam"
fi

# Escritorio ===============================================================================================================================
pacotes="${pacotes} calibre meld shutter"
pacotes="${pacotes} gimp kolourpaint geany"
pacotes="${pacotes} texmaker texlive-scheme-small texlive-collection-langportuguese texlive-supertabular texlive-tocloft texlive-hyphenat texlive-moderncv"
pacotes="${pacotes} libreoffice-langpack-pt-BR"
pacotes="${pacotes} ubuntu-family-fonts ubuntu-title-fonts"

# Devel e bibliotecas ======================================================================================================================
pacotes="${pacotes} mesa-libGLU.i686 mesa-libGLU.x86_64"
pacotes="${pacotes} libpng libpng.i686 cups-libs cups-libs.i686 nss-mdns nss-mdns.i686 lcms-libs lcms-libs.i686 lcms2.i686 lcms2"
pacotes="${pacotes} kernel-tools kernel-tools-libs kernel-headers kernel-devel kernel-modules kernel-modules-extra"
if [ "${devel}" = yes ]; then
  pacotes="${pacotes} audit-libs-devel binutils-devel bison elfutils-devel hmaccalc newt-devel pciutils-devel python-devel"
  pacotes="${pacotes} rpm-build rpmdevtools perl-ExtUtils-Embed"
  pacotes="${pacotes} libunwind-devel numactl-devel asciidoc pesign xmlto"
  pacotes="${pacotes} gcc gcc-c++ curl make patch glib2-devel glib-devel"
  pacotes="${pacotes} sqliteman sqlite sqlite-devel sqlite2-devel"
  pacotes="${pacotes} opencv-devel-docs opencv opencv-devel chrpath libtiff-devel OpenEXR-devel numpy python-sphinx"
  pacotes="${pacotes} v8-devel zlib-devel nodejs"
  pacotes="${pacotes} cmake-gui openssl-libs git-core readline readline-devel zlib-devel libyaml-devel"
  pacotes="${pacotes} libffi-devel libxslt-devel openssl openssl-devel"
  pacotes="${pacotes} bison-devel bison-devel.i686 flex-devel flex-devel.i686 glibc-devel glibc-devel.i686"
  pacotes="${pacotes} python-pep8 pyflakes pygame PyYAML"
  pacotes="${pacotes} docker-ce rsyslog hub"
fi

dnf -y --skip-broken --allowerasing install ${pacotes}

# Instalar crossover =======================================================================================================================
#wget --no-check-certificate http://techmago.sytes.net/rpm/crossover-15.1.0.rpm
#wget --no-check-certificate http://techmago.sytes.net/rpm/winewrapper.exe.so
#dnf -y install --nogpgcheck crossover-15.1.0.rpm
#mv -f winewrapper.exe.so /opt/cxoffice/lib/wine/winewrapper.exe.so
#chown root.root /opt/cxoffice/lib/wine/winewrapper.exe.so
#chmod 755 /opt/cxoffice/lib/wine/winewrapper.exe.so
#rm -f crossover-15.1.0.rpm

# Melhora as fontes ========================================================================================================================
echo '<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <match target="font">
    <edit name="hintstyle" mode="assign">
      <const>hintslight</const>
    </edit>
    <edit name="rgba" mode="assign">
      <const>rgb</const>
    </edit>
    <edit name="lcdfilter" mode="assign">
      <const>lcddefault</const>
    </edit>
  </match>
</fontconfig>' > /etc/fonts/local.conf

# Nemo =====================================================================================================================================
dnf install -y nextcloud-client-nemo nemo-extensions  nemo-dropbox

echo '[Desktop Entry]
Type=Application
Name=Nemo
Comment=Start Nemo desktop at log in
Exec=nemo-desktop
OnlyShowIn=GNOME;
AutostartCondition=GSettings org.nemo.desktop show-desktop-icons
X-GNOME-AutoRestart=true
NoDisplay=true' > /etc/xdg/autostart/nemo-autostart-with-gnome.desktop

# Ftpython =================================================================================================================================
wget --no-check-certificate https://techmago.sytes.net/rpm/ftpython
chmod +x ftpython
mv ftpython /usr/local/bin

# Atom =====================================================================================================================================
wget https://atom.io/download/rpm -O atom.rpm
dnf -y install atom.rpm
rm -f atom.rpm

# Hack para deletar arquivos
echo '#!/usr/bin/env bash
# GVFS updated and dropped gvfs-trash to gio, but Atom didnt update.
# https://github.com/atom/tree-view/issues/1237
/usr/bin/gio trash "$@"
' | tee /usr/local/bin/gvfs-trash && chmod +x /usr/local/bin/gvfs-trash

# Instala um pacote de senhas do windows ====================================================================================
wget --no-check-certificate http://techmago.sytes.net/rpm/fontesWindows.txz
tar -xJf fontesWindows.txz
mv fontesWindows /usr/share/fonts/
rm -f fontesWindows.txz

# Virtual Box ==============================================================================================================================
if [ "${devel}" = yes ]; then
	dnf -y install VirtualBox kmod-VirtualBox
fi

# Da um boost no terminal ==================================================================================================================
wget --no-check-certificate http://techmago.sytes.net/rpm/techmago.sh
mv techmago.sh /etc/profile.d/

# Instala o pacote de linguas ==============================================================================================================
if [ "${kde}" = yes ]; then
	dnf -y install kde-i18n-Brazil kde-l10n-Brazil
fi

# ACABOU ===================================================================================================================================
echo "All done. Now reboot"
echo "reboot"

echo "rhythmbox fix:"
echo "wget https://github.com/mendhak/rhythmbox-tray-icon/raw/master/rhythmbox-tray-icon.zip"
echo "unzip -u rhythmbox-tray-icon.zip -d ~/.local/share/rhythmbox/plugins"
echo "Nemo stuff:"
echo "gsettings set org.nemo.desktop use-desktop-grid false
