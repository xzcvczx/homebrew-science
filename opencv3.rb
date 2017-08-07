require File.expand_path("../Requirements/cuda_requirement", __FILE__)

class Opencv3 < Formula
  desc "Open source computer vision library, version 3"
  homepage "http://opencv.org/"

  stable do
    url "https://github.com/opencv/opencv/archive/3.3.0.tar.gz"
    sha256 "95029eb5578af3b20b8c7f8f6f59db1b827c2d5aaaa74b6becb1de647cbdda5a"

    resource "contrib" do
      url "https://github.com/opencv/opencv_contrib/archive/3.3.0.tar.gz"
      sha256 "e94acf39cd4854c3ef905e06516e5f74f26dddfa6477af89558fb40a57aeb444"
    end
  end

  bottle do
    sha256 "57424663b5b7636bff5bbd99b789bebfe9cf17471fb59badb0fe7bb4938b2eda" => :sierra
    sha256 "2c561cba408449d9381a1bb355eac0a7e1c7b671e5e20e5ba1b7edd9f44a1941" => :el_capitan
    sha256 "97abd7941d559771293d9b002c752443413a2cf07c9813985ee7c8639a0d17eb" => :yosemite
    sha256 "656e25a9f09a1da8c53a7fa9ceabff054c3a6d854d085c7596bacaf45df11035" => :x86_64_linux
  end

  head do
    url "https://github.com/opencv/opencv.git"

    resource "contrib" do
      url "https://github.com/opencv/opencv_contrib.git"
    end
  end

  keg_only "opencv3 and opencv install many of the same files"

  deprecated_option "without-tests" => "without-test"
  deprecated_option "32-bit" => "with-32-bit"
  deprecated_option "with-qt5" => "with-qt"

  option "with-contrib", 'Build "extra" contributed modules'
  option "with-cuda", "Build with CUDA v7.0+ support"
  option "with-examples", "Install C and python examples (sources)"
  option "with-java", "Build with Java support"
  option "with-jpeg-turbo", "Build with libjpeg-turbo instead of libjpeg"
  option "with-nonfree", "Enable non-free algorithms"
  option "with-opengl", "Build with OpenGL support (must use --with-qt)"
  option "with-qt", "Build the Qt backend to HighGUI"
  option "with-static", "Build static libraries"
  option "with-tbb", "Enable parallel code in OpenCV using Intel TBB"
  option "without-numpy", "Use a numpy you've installed yourself instead of a Homebrew-packaged numpy"
  option "without-opencl", "Disable GPU code in OpenCV using OpenCL"
  option "without-python", "Build without Python support"
  option "without-test", "Build without accuracy & performance tests"

  if OS.mac? && DevelopmentTools.clang_build_version < 800
    # Quicktime option was replaced with AVFoundation for newer development tools
    option "with-quicktime", "Use QuickTime for Video I/O instead of QTKit"
  end

  option :cxx11

  depends_on :ant => :build if build.with? "java"
  depends_on "cmake" => :build
  depends_on CudaRequirement => :optional
  depends_on "pkg-config" => :build

  depends_on "eigen" => :recommended
  depends_on "ffmpeg" => :optional
  depends_on "gphoto2" => :optional
  depends_on "gstreamer" => :optional
  depends_on "gst-plugins-good" if build.with? "gstreamer"
  depends_on "jasper" => :optional
  depends_on :java => :optional
  depends_on "jpeg" => :recommended
  depends_on "jpeg-turbo" => :optional
  depends_on "libdc1394" => :optional
  depends_on "libpng" => :recommended
  depends_on "libtiff" => :recommended
  depends_on "openexr" => :recommended
  depends_on "openni" => :optional
  depends_on "openni2" => :optional
  depends_on :python => :recommended unless OS.mac? && MacOS.version > :snow_leopard
  depends_on :python3 => :optional
  depends_on "qt" => :optional
  depends_on "tbb" => :optional
  depends_on "vtk" => :optional
  depends_on "openblas" unless OS.mac?

  with_python = build.with?("python") || build.with?("python3")
  pythons = build.with?("python3") ? ["with-python3"] : []
  depends_on "numpy" => [:recommended] + pythons if with_python

  # dependencies use fortran, which leads to spurious messages about gcc
  cxxstdlib_check :skip

  resource "icv-macosx" do
    url "https://raw.githubusercontent.com/opencv/opencv_3rdparty/81a676001ca8075ada498583e4166079e5744668/ippicv/ippicv_macosx_20151201.tgz", :using => :nounzip
    sha256 "8a067e3e026195ea3ee5cda836f25231abb95b82b7aa25f0d585dc27b06c3630"
  end

  resource "icv-linux" do
    url "https://raw.githubusercontent.com/opencv/opencv_3rdparty/81a676001ca8075ada498583e4166079e5744668/ippicv/ippicv_linux_20151201.tgz", :using => :nounzip
    sha256 "4333833e40afaa22c804169e44f9a63e357e21476b765a5683bcb3760107f0da"
  end

  def arg_switch(opt)
    build.with?(opt) ? "ON" : "OFF"
  end

  def neg_arg_switch(opt)
    build.with?(opt) ? "OFF" : "ON"
  end

  def install
    ENV.cxx11 if build.cxx11?
    dylib = "a"
    dylib = OS.mac? ? "dylib" : "so" if build.without?("static")
    with_qt = build.with?("qt")

    args = std_cmake_args + %w[
      -DBUILD_JASPER=OFF
      -DBUILD_ZLIB=OFF
      -DCMAKE_OSX_DEPLOYMENT_TARGET=
    ]

    # cf https://github.com/Homebrew/homebrew-science/pull/5185
    args << "-DBUILD_OPENEXR=" + (OS.linux? ? "ON" : "OFF")
    args << "-DBUILD_opencv_java=" + arg_switch("java")
    args << "-DBUILD_opencv_python2=" + arg_switch("python")
    args << "-DBUILD_opencv_python3=" + arg_switch("python3")
    args << "-DBUILD_TESTS=OFF" << "-DBUILD_PERF_TESTS=OFF" if build.without? "tests"
    args << "-DWITH_1394=" + arg_switch("libdc1394")
    args << "-DWITH_EIGEN=" + arg_switch("eigen")
    args << "-DWITH_FFMPEG=" + arg_switch("ffmpeg")
    args << "-DWITH_GPHOTO2=" + arg_switch("gphoto2")
    args << "-DWITH_GSTREAMER=" + arg_switch("gstreamer")
    args << "-DWITH_JASPER=" + arg_switch("jasper")
    args << "-DWITH_OPENEXR=" + arg_switch("openexr")
    args << "-DWITH_OPENGL=" + arg_switch("opengl")
    args << "-DWITH_QT=" + (with_qt ? "ON" : "OFF")
    args << "-DWITH_TBB=" + arg_switch("tbb")
    args << "-DWITH_VTK=" + arg_switch("vtk")
    args << "-DBUILD_TIFF=" + neg_arg_switch("libtiff")
    args << "-DBUILD_PNG=" + neg_arg_switch("libpng")

    if OS.mac? && DevelopmentTools.clang_build_version < 800
      args << "-DWITH_QUICKTIME=" + arg_switch("quicktime")
    end

    if build.with?("jpeg") && build.with?("jpeg-turbo")
      odie "Options --with-jpeg and --with-jpeg-turbo are mutually exclusive."
    elsif build.without?("jpeg") && build.without?("jpeg-turbo")
      args << "-DBUILD_JPEG=ON"
    else
      jpeg = Formula[build.with?("jpeg-turbo") ? "jpeg-turbo" : "jpeg"]
      args << "-DBUILD_JPEG=OFF"
      args << "-DJPEG_INCLUDE_DIR=#{jpeg.opt_include}"
      args << "-DJPEG_LIBRARY=#{jpeg.opt_lib}/libjpeg.#{dylib}"
    end

    if build.include? "32-bit"
      args << "-DCMAKE_OSX_ARCHITECTURES=i386"
      args << "-DOPENCV_EXTRA_C_FLAGS='-arch i386 -m32'"
      args << "-DOPENCV_EXTRA_CXX_FLAGS='-arch i386 -m32'"
    end

    if build.with? "cuda"
      args << "-DWITH_CUDA=ON"
      args << "-DCUDA_GENERATION=Auto"
    else
      args << "-DWITH_CUDA=OFF"
    end

    if build.with? "contrib"
      resource("contrib").stage buildpath/"opencv_contrib"
      args << "-DOPENCV_EXTRA_MODULES_PATH=#{buildpath}/opencv_contrib/modules"
    end

    if build.with? "examples"
      args << "-DINSTALL_C_EXAMPLES=ON"
      args << "-DINSTALL_PYTHON_EXAMPLES=ON"
    end

    if build.with? "nonfree"
      resource("contrib").stage buildpath/"opencv_contrib"
      args << "-DOPENCV_EXTRA_MODULES_PATH=#{buildpath}/opencv_contrib/modules"
      args << "-DOPENCV_ENABLE_NONFREE=ON"
    end

    # OpenCL 1.1 is required, but Snow Leopard and older come with 1.0
    args << "-DWITH_OPENCL=OFF" if build.without?("opencl") || MacOS.version < :lion

    if build.with? "openni"
      args << "-DWITH_OPENNI=ON"
      # Set proper path for Homebrew's openni
      inreplace "cmake/OpenCVFindOpenNI.cmake" do |s|
        s.gsub! "/usr/include/ni", "#{Formula["openni"].opt_include}/ni"
        s.gsub! "/usr/lib", Formula["openni"].opt_lib
      end
    end

    if build.with? "openni2"
      args << "-DWITH_OPENNI2=ON"
      ENV["OPENNI2_INCLUDE"] ||= "#{Formula["openni2"].opt_include}/ni2"
      ENV["OPENNI2_REDIST"] ||= "#{Formula["openni2"].opt_lib}/ni2"
    end

    if build.with?("python3") && build.with?("python")
      # Opencv3 Does not support building both Python 2 and 3 versions
      odie "opencv3: Does not support building both Python 2 and 3 wrappers"
    end

    if build.with? "python"
      py_prefix = `python-config --prefix`.chomp
      py_lib = "#{py_prefix}/lib"
      args << "-DPYTHON2_EXECUTABLE=#{which "python"}"
      args << "-DPYTHON2_LIBRARY=#{py_lib}/libpython2.7.#{dylib}"
      args << "-DPYTHON2_INCLUDE_DIR=#{py_prefix}/include/python2.7"
    end

    if build.with? "python3"
      # Reset PYTHONPATH, workaround for https://github.com/Homebrew/homebrew-science/pull/4885
      ENV["PYTHONPATH"] = ""
      py3_config = `python3-config --configdir`.chomp
      py3_include = `python3 -c "import distutils.sysconfig as s; print(s.get_python_inc())"`.chomp
      py3_version = Language::Python.major_minor_version "python3"
      args << "-DPYTHON3_EXECUTABLE=#{which "python3"}"
      args << "-DPYTHON3_LIBRARY=#{py3_config}/libpython#{py3_version}.#{dylib}"
      args << "-DPYTHON3_INCLUDE_DIR=#{py3_include}"
    end

    args << "-DBUILD_SHARED_LIBS=OFF" if build.with?("static")

    # avoid error: '_mm_cvtps_ph' was not declared in this scope; cf https://github.com/RoboSherlock/robosherlock/issues/78#issuecomment-274469830
    # https://github.com/Homebrew/homebrew-science/issues/5336
    args << "-DCMAKE_CXX_FLAGS='-march=core2'" if OS.linux? && build.bottle?

    mkdir "macbuild" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"
    end
  end

  test do
    (testpath/"test.cpp").write <<-EOS.undent
      #include <opencv/cv.h>
      #include <iostream>
      int main()
      {
        std::cout << CV_VERSION << std::endl;
        return 0;
      }
    EOS
    system ENV.cxx, "test.cpp", "-I#{include}", "-L#{lib}", "-o", "test"
    assert_equal `./test`.strip, version.to_s

    ENV["PYTHONPATH"] = lib/"python2.7/site-packages"
    assert_match version.to_s, shell_output("python -c 'import cv2; print(cv2.__version__)'")
  end
end
