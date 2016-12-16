build: build/Release/ec.app

install: build/Release/ec.app
    cp -r $prereq /Applications/  
    
clean: build
    rm -rf build

build/Release/ec.app:
    xcodebuild -project ec.xcodeproj -target ec -configuration Release build
    
