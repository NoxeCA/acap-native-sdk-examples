# Application Name
TARGET := capture_app

# Determine the base path
BASE := $(abspath $(patsubst %/,%,$(dir $(firstword $(MAKEFILE_LIST)))))

# Find cpp files
OBJECTS := $(patsubst %.cpp, %.o, $(wildcard $(BASE)/src/*.cpp))

CXXFLAGS += -I/usr/include -I/axis/opencv/usr/include
CPPFLAGS = -Os -pipe -std=c++17

LDLIBS += -L /axis/opencv/usr/lib -L /axis/openblas/usr/lib -L /axis/tesseract/usr/lib -L /axis/tesseract/usr/lib/aarch64-linux-gnu #-L /axis/tesseract/usr/lib/arm-linux-gnueabihf
LDLIBS += -lm -lstdc++ -lopencv_core -lopencv_imgproc -lopencv_imgcodecs -lopencv_videoio
LDLIBS += -lvdostream -lfido -lcapaxis -lstatuscache -lopenblas -ltesseract -ljpeg -lpng -ltiff -ljbig -llept -ljbig -ldeflate -lgif -lopenjp2 -lwebp -lwebpmux
LDLIBS += $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) pkg-config --libs $(PKGS))

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $< $(CPPFLAGS) $(LDLIBS) -o $@ && $(STRIP) --strip-unneeded $@

clean:
	$(RM) *.o $(TARGET)
