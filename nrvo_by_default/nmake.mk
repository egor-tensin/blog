CXXFLAGS = /nologo /W4 /EHsc /MT /DNDEBUG

all: rvo.cl.Od.exe rvo.cl.O1.exe rvo.cl.O2.exe rvo.cl.Ox.exe

rvo.cl.Od.exe: rvo.cpp
	$(CXX) $(CXXFLAGS) /Od /Fe:$@ $**

rvo.cl.O1.exe: rvo.cpp
	$(CXX) $(CXXFLAGS) /O1 /Fe:$@ $**

rvo.cl.O2.exe: rvo.cpp
	$(CXX) $(CXXFLAGS) /O2 /Fe:$@ $**

rvo.cl.Ox.exe: rvo.cpp
	$(CXX) $(CXXFLAGS) /Ox /Fe:$@ $**

clean:
	del rvo.obj

clean-all: clean
	del rvo.cl.*.exe
