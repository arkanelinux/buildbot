FROM archlinux:latest

RUN useradd -m arkane && \
passwd -d arkane && \
pacman -Sy --noconfirm base-devel git && \
echo 'arkane ALL=(ALL:ALL) NOPASSWD: SETENV: ALL' >> /etc/sudoers
