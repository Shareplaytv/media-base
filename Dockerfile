FROM public.ecr.aws/lambda/provided:al2 as builder

RUN yum update -y

RUN yum makecache &&\
yum -y install \
  wget tar xz gzip golang awscli cargo \
  ldconfig pkg-config llvm clang openssl-devel bc \
  glib2-devel \
  expat-devel \
  librsvg2-devel \
  libpng-devel \
  libjpeg-devel \
  libtiff-devel \
  libexif-devel \
  giflib-devel \
  lcms2-devel \
  libxml2-devel \
  libgsf-devel \
  fftw-devel &&\
yum -y group install "Development Tools"

ENV SRC_DIR=/usr/var/ffmpeg_sources
ENV BUILD_DIR=/usr/var/ffmpeg_build

RUN mkdir -p $BUILD_DIR
RUN mkdir $SRC_DIR

ENV HOME=/root
ENV LD_LIBRARY_PATH+=":/usr/local/lib"
ENV PKG_CONFIG_PATH+=":/usr/local/lib/pkgconfig:/usr/local/lib64/pkgconfig"

RUN cd $SRC_DIRs &&\
curl -O -L https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2 &&\
tar xjvf nasm-2.15.05.tar.bz2 && cd nasm-2.15.05 && ./autogen.sh &&\
./configure --prefix="$BUILD_DIR" --bindir="/bin" &&\
make -j $(nproc) && make install

RUN cd $SRC_DIRs &&\
curl -O -L https://www.tortall.net/projects/yasm/releases/yasm-1.3.0.tar.gz &&\
tar xzvf yasm-1.3.0.tar.gz && cd yasm-1.3.0 &&\
./configure --prefix="$BUILD_DIR" --bindir="/bin" &&\
make -j $(nproc) && make install

RUN cd $SRC_DIRs && \
git clone --branch stable --depth 1 https://code.videolan.org/videolan/x264.git && cd x264 && \
PKG_CONFIG_PATH+=":$BUILD_DIR/lib/pkgconfig" ./configure --prefix="$BUILD_DIR" --bindir="/bin" --enable-static &&\
make -j $(nproc) && make install

RUN cd $SRC_DIRs &&\
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git && cd libvpx &&\
./configure --prefix="$BUILD_DIR" --disable-examples --disable-unit-tests --enable-vp9-highbitdepth --as=yasm &&\
make -j $(nproc) && make install

RUN wget https://cmake.org/files/v3.6/cmake-3.6.2.tar.gz && tar -zxvf cmake-3.6.2.tar.gz && cd cmake-3.6.2 &&\
./bootstrap --prefix=/usr/local && make -j $(nproc) && make install

RUN cd $SRC_DIRs &&\
git clone https://github.com/OpenVisualCloud/SVT-VP9.git && cd SVT-VP9/Build/linux &&\
./build.sh release static && ls -R && cd ./Release && make -j $(nproc) && make install

RUN cp /usr/local/lib64/pkgconfig/SvtVp9Enc.pc /usr/lib64/pkgconfig/SvtVp9Enc.pc

RUN cd $SRC_DIRs &&\
curl -O -L https://ftp.osuosl.org/pub/xiph/releases/opus/opus-1.4.tar.gz &&\
tar xzvf opus-1.4.tar.gz && cd opus-1.4 &&\
./configure --prefix="$BUILD_DIR" --disable-shared &&\
make -j $(nproc) && make install

RUN cd $SRC_DIRs &&\
curl -O -L https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2 && tar xjvf ffmpeg-snapshot.tar.bz2 && cd ffmpeg &&\
PATH="/bin:$PATH" PKG_CONFIG_PATH+=":$BUILD_DIR/lib/pkgconfig" ./configure \
  --prefix="$BUILD_DIR" \
  --pkg-config-flags="--static" \
  --extra-cflags="-I$BUILD_DIR/include" \
  --extra-ldflags="-L$BUILD_DIR/lib" \
  --extra-libs=-lpthread \
  --extra-libs=-lm \
  --bindir="/bin" \
  --enable-gpl \
  --enable-libopus \
  --enable-libvpx \
  --enable-libx264 \
  --enable-nonfree \
  --enable-libvpx \
  --enable-openssl &&\
make -j $(nproc) && make install

RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm &&\
  yum -y install yum-utils &&\
  yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm &&\
  yum-config-manager --enable remi --enable epel &&\
  yum -y install vips vips-devel vips-tools pngquant

RUN ffmpeg -buildconf

RUN cd $SRC_DIRs && cd opus-1.4 &&\
./configure && make clean &&\
make -j $(nproc) && make install

RUN yum -y install \
  https://github.com/bbc/audiowaveform/releases/download/1.8.0/audiowaveform-1.8.0-1.amzn2.x86_64.rpm

RUN /sbin/ldconfig /usr/local/lib

RUN yum clean all && rm -rf /var/cache/yum
